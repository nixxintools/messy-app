import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/bytes.dart';
import '../../core/constants.dart';
import '../../data/db/database.dart';
import '../../domain/entities/message.dart' as domain;
import '../crypto/identity_service.dart';
import '../mesh/mesh_router.dart';

/// Sending + reactive queries for chats. Receiving lives in [MeshRouter].
class ChatService {
  ChatService({required this.db, required this.identity, required this.router});

  final MessyDatabase db;
  final LocalIdentity identity;
  final MeshRouter router;
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

  Future<void> setDisappearTimer(String chatId, int? seconds) =>
      (db.update(db.chats)..where((c) => c.chatId.equals(chatId)))
          .write(ChatsCompanion(disappearAfterSecs: Value(seconds)));

  Future<void> sendText(String chatId, String text) async {
    if (chatId == MeshRouter.publicRoomName) {
      return _sendPublicText(text);
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
    }));
    await router.sendDirect(
      recipientPub: contact.x25519Pub,
      payloadType: Protocol.payloadText,
      plaintext: payload,
      messageId: idBytes,
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
