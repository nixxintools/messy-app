import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/bytes.dart';
import '../../core/constants.dart';
import '../../data/db/database.dart';
import '../../domain/entities/message.dart' as domain;
import '../crypto/identity_service.dart';
import '../mesh/mesh_router.dart';
import 'media_store.dart';

/// Outgoing media: manifest + independently-encrypted 32 KiB chunks under one
/// messageId — docs/ARCHITECTURE.md §4. Incoming reassembly lives in
/// [MeshRouter]._tryAssemble.
class TransferService {
  TransferService({
    required this.db,
    required this.identity,
    required this.router,
    required this.mediaStore,
  });

  final MessyDatabase db;
  final LocalIdentity identity;
  final MeshRouter router;
  final MediaStore mediaStore;
  final _uuid = const Uuid();

  /// Sends a photo or video file to a 1:1 chat. Returns false if over the
  /// mesh media cap (25 MB).
  Future<bool> sendMedia(String chatId, File file, String mimeType) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > Protocol.relayedMediaCapBytes) return false;

    final contact = await (db.select(db.contacts)
          ..where((c) => c.nodeId.equals(chatId)))
        .getSingle();
    final chat = await (db.select(db.chats)
          ..where((c) => c.chatId.equals(chatId)))
        .getSingleOrNull();
    final disappear = chat?.disappearAfterSecs;

    final idBytes = Uint8List.fromList(Uuid.parse(_uuid.v7()));
    final idHex = hexEncode(idBytes);
    final chunkTotal =
        (bytes.length + Protocol.chunkSize - 1) ~/ Protocol.chunkSize;
    final digest = sha256Bytes(bytes);
    final name = file.uri.pathSegments.isEmpty
        ? 'media'
        : file.uri.pathSegments.last;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Keep our own copy in the media store so the bubble renders.
    final localPath = await mediaStore.write(idHex, mimeType, bytes);

    await db.into(db.mediaItems).insert(
          MediaItemsCompanion(
            mediaId: Value(idHex),
            messageId: Value(idHex),
            filePath: Value(localPath),
            mimeType: Value(mimeType),
            totalSize: Value(bytes.length),
            chunkTotal: Value(chunkTotal),
            sha256: Value(digest),
            complete: const Value(true),
          ),
        );
    await db.into(db.messages).insert(
          MessagesCompanion(
            messageId: Value(idHex),
            chatId: Value(chatId),
            direction: Value(domain.MessageDirection.outgoing.index),
            payloadType: Value(Protocol.payloadMediaManifest),
            body: Value(name),
            mediaId: Value(idHex),
            sentAt: Value(now),
            expiresAt: Value(disappear == null ? null : now + disappear * 1000),
            status: Value(domain.MessageStatus.queued.index),
          ),
        );

    final manifest = utf8.encode(jsonEncode({
      'name': name,
      'mime': mimeType,
      'size': bytes.length,
      'total': chunkTotal,
      'sha': b64u(digest),
      'sender': identity.displayName,
      'd': ?disappear,
    }));
    await router.sendDirect(
      recipientPub: contact.x25519Pub,
      payloadType: Protocol.payloadMediaManifest,
      plaintext: manifest,
      messageId: idBytes,
      chunkIndex: 0,
      chunkTotal: chunkTotal,
    );

    for (var i = 0; i < chunkTotal; i++) {
      final start = i * Protocol.chunkSize;
      final end = (start + Protocol.chunkSize).clamp(0, bytes.length);
      await router.sendDirect(
        recipientPub: contact.x25519Pub,
        payloadType: Protocol.payloadMediaChunk,
        plaintext: bytes.sublist(start, end),
        messageId: idBytes,
        // Chunk envelopes are keyed (messageId, chunkIndex); index 0 is the
        // manifest, chunks start at 1.
        chunkIndex: i + 1,
        chunkTotal: chunkTotal,
      );
    }
    return true;
  }
}
