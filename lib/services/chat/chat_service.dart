import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/bytes.dart';
import '../../core/constants.dart';
import '../../core/well_known.dart';
import '../../data/db/database.dart';
import '../../domain/entities/message.dart' as domain;
import '../crypto/identity_service.dart';
import '../crypto/prekey_service.dart';
import '../mesh/mesh_router.dart';

/// Sending + reactive queries for chats. Receiving lives in [MeshRouter].
class ChatService {
  ChatService({
    required this.db,
    required this.identity,
    required this.router,
    required this.prekeys,
  });

  final MessyDatabase db;
  final LocalIdentity identity;
  final MeshRouter router;
  final PrekeyService prekeys;
  final _uuid = const Uuid();

  Stream<List<MessageRow>> watchMessages(String chatId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (db.select(db.messages)
          ..where((m) =>
              m.chatId.equals(chatId) &
              (m.expiresAt.isNull() | m.expiresAt.isBiggerThanValue(now)))
          ..orderBy([(m) => OrderingTerm.asc(m.messageId)]))
        .watch();
  }

  Stream<List<ChatRow>> watchChats() => db.select(db.chats).watch();

  Stream<List<ContactRow>> watchContacts() => db.select(db.contacts).watch();

  Stream<List<MessageRow>> watchAllMessages() =>
      db.select(db.messages).watch();

  Future<ChatRow?> getChat(String chatId) => (db.select(db.chats)
        ..where((c) => c.chatId.equals(chatId)))
      .getSingleOrNull();

  Future<ContactRow?> getContact(String nodeId) => (db.select(db.contacts)
        ..where((c) => c.nodeId.equals(nodeId)))
      .getSingleOrNull();

  Stream<List<GroupRow>> watchGroups() => db.select(db.groups).watch();

  Future<GroupRow?> getGroup(String chatId) => (db.select(db.groups)
        ..where((g) => g.groupId.equals(chatId)))
      .getSingleOrNull();

  /// Creates a group and invites the given contacts over 1:1 E2E messages.
  Future<String> createGroup(String name, List<ContactRow> members) async {
    final rng = Random.secure();
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => rng.nextInt(256)),
    );
    final groupId = hexEncode(sha256Bytes(key));
    await db.into(db.groups).insert(
          GroupsCompanion(
            groupId: Value(groupId),
            name: Value(name),
            key: Value(key),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
    await db.into(db.chats).insert(
          ChatsCompanion(chatId: Value(groupId), nodeId: const Value(null)),
          mode: InsertMode.insertOrIgnore,
        );
    final invite = utf8.encode(jsonEncode({
      'g': b64u(key),
      'name': name,
      'n': identity.displayName,
    }));
    for (final member in members) {
      await router.sendDirect(
        recipientPub: member.x25519Pub,
        payloadType: Protocol.payloadGroupInvite,
        plaintext: invite,
      );
    }
    return groupId;
  }

  Future<void> setDisappearTimer(String chatId, int? seconds) =>
      (db.update(db.chats)..where((c) => c.chatId.equals(chatId)))
          .write(ChatsCompanion(disappearAfterSecs: Value(seconds)));

  Future<void> sendText(String chatId, String text) async {
    if (chatId == MeshRouter.publicRoomName) {
      return _sendPublicText(text);
    }
    final group = await getGroup(chatId);
    if (group != null) {
      return _sendGroupText(group, text);
    }
    final contact = await (db.select(db.contacts)
          ..where((c) => c.nodeId.equals(chatId)))
        .getSingle();
    final chat = await getChat(chatId);
    final disappear = chat?.disappearAfterSecs;

    final idBytes = Uint8List.fromList(Uuid.parse(_uuid.v7()));
    final idHex = hexEncode(idBytes);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Insert first so the router's status transitions find the row.
    await db.into(db.messages).insert(
          MessagesCompanion(
            messageId: Value(idHex),
            chatId: Value(chatId),
            direction: Value(domain.MessageDirection.outgoing.index),
            payloadType: Value(Protocol.payloadText),
            body: Value(text),
            sentAt: Value(now),
            expiresAt: Value(disappear == null ? null : now + disappear * 1000),
            status: Value(domain.MessageStatus.queued.index),
          ),
        );

    final payload = utf8.encode(jsonEncode({
      't': text,
      'n': identity.displayName,
      'd': ?disappear,
      // Piggyback fresh one-time prekeys so the conversation keeps
      // per-message forward secrecy without extra round trips.
      'pk': await prekeys.issueTo(chatId, PrekeyService.replenishPerMessage),
    }));
    await router.sendDirect(
      recipientPub: contact.x25519Pub,
      payloadType: Protocol.payloadText,
      plaintext: payload,
      messageId: idBytes,
    );
  }

  Future<void> _sendGroupText(GroupRow group, String text) async {
    final chat = await getChat(group.groupId);
    // The public Media channel always expires at 24 h, like Local.
    final disappear = group.groupId == WellKnown.mediaRoomId
        ? Protocol.publicRetention.inSeconds
        : chat?.disappearAfterSecs;
    final idBytes = Uint8List.fromList(Uuid.parse(_uuid.v7()));
    final idHex = hexEncode(idBytes);
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.messages).insert(
          MessagesCompanion(
            messageId: Value(idHex),
            chatId: Value(group.groupId),
            direction: Value(domain.MessageDirection.outgoing.index),
            payloadType: Value(Protocol.payloadGroupText),
            body: Value(text),
            senderName: Value(identity.displayName),
            sentAt: Value(now),
            expiresAt: Value(disappear == null ? null : now + disappear * 1000),
            status: Value(domain.MessageStatus.sentToMesh.index),
          ),
        );
    await router.sendGroup(
      group: group,
      messageId: idBytes,
      plaintext: utf8.encode(jsonEncode({
        't': text,
        'n': identity.displayName,
        'd': ?disappear,
      })),
    );
  }

  Future<void> _sendPublicText(String text) async {
    final payload = utf8.encode(jsonEncode({
      't': text,
      'n': identity.displayName,
    }));
    final now = DateTime.now().millisecondsSinceEpoch;
    final idHex = await router.sendPublic(payload);
    await db.into(db.messages).insert(
          MessagesCompanion(
            messageId: Value(idHex),
            chatId: const Value(MeshRouter.publicRoomName),
            direction: Value(domain.MessageDirection.outgoing.index),
            payloadType: Value(Protocol.payloadPublicText),
            body: Value(text),
            senderName: Value(identity.displayName),
            sentAt: Value(now),
            expiresAt: Value(now + Protocol.publicRetention.inMilliseconds),
            status: Value(domain.MessageStatus.sentToMesh.index),
          ),
        );
  }
}
