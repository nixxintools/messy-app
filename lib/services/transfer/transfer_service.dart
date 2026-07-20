import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

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

  /// Sends a photo or video file to a 1:1 chat. Videos are transcoded to
  /// 720p first — raw phone video is untenable over a mesh
  /// (docs/ARCHITECTURE.md §11). Returns false only if the file is still
  /// over the 25 MB cap after compression.
  Future<bool> sendMedia(String chatId, File file, String mimeType) async {
    var sourceFile = file;
    var effectiveMime = mimeType;
    if (mimeType.startsWith('video/')) {
      final compressed = await _compressVideo(file);
      if (compressed != null) {
        sourceFile = compressed;
        effectiveMime = 'video/mp4';
      }
    }
    final bytes = await sourceFile.readAsBytes();
    if (bytes.length > Protocol.relayedMediaCapBytes) return false;
    final mime = effectiveMime;

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
    final localPath = await mediaStore.write(idHex, mime, bytes);

    await db.into(db.mediaItems).insert(
          MediaItemsCompanion(
            mediaId: Value(idHex),
            messageId: Value(idHex),
            filePath: Value(localPath),
            mimeType: Value(mime),
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
      'mime': mime,
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

  /// Transcodes to 720p/H.264 mp4. Returns null if compression failed or
  /// produced nothing smaller — the original is used as-is then.
  Future<File?> _compressVideo(File file) async {
    try {
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: true,
      );
      final path = info?.file?.path;
      if (path == null) return null;
      final out = File(path);
      if (await out.length() >= await file.length()) return null;
      return out;
    } on Object {
      return null;
    }
  }
}
