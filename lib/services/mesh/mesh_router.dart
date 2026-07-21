import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/bytes.dart';
import '../../core/constants.dart';
import '../../data/db/database.dart';
import '../../domain/codec/envelope_codec.dart';
import '../../domain/codec/frame_codec.dart';
import '../../domain/entities/envelope.dart';
import '../../domain/entities/message.dart' as domain;
import '../../transport/connectivity_manager.dart';
import '../crypto/identity_service.dart';
import '../crypto/session_crypto.dart';
import '../transfer/media_store.dart';

/// Store-and-forward mesh routing — docs/ARCHITECTURE.md §4.
///
/// Epidemic v1: every envelope we can't deliver locally is stored as opaque
/// ciphertext and re-offered to every peer we meet, deduped by
/// (messageId, chunkIndex), until its TTL or retention expires.
class MeshRouter {
  MeshRouter({
    required this.db,
    required this.identity,
    required this.crypto,
    required this.connectivity,
    required this.mediaStore,
  });

  static const publicRoomName = 'local';

  final MessyDatabase db;
  final LocalIdentity identity;
  final SessionCrypto crypto;
  final ConnectivityManager connectivity;
  final MediaStore mediaStore;

  final _uuid = const Uuid();

  /// Contact request/accept frames are link-level, not envelopes — the
  /// contact service registers itself here.
  void Function(AuthenticatedLink from, Map<String, Object?> body)?
      onContactRequest;
  void Function(AuthenticatedLink from, Map<String, Object?> body)?
      onContactAccept;

  /// Fired for every locally-delivered incoming message (1:1, public,
  /// completed media) — the UI layer decides whether to notify.
  void Function(String chatId, String title, String body)? onIncoming;

  void start() {
    connectivity.onLinkUp.listen((auth) {
      // setFrameHandler replays anything the peer sent before this event
      // was delivered — no frames are lost in the link-up window.
      auth.setFrameHandler((frame) => _onFrame(auth, frame));
      _syncTo(auth);
    });
  }

  // ---------------------------------------------------------------- sending

  Uint8List _newMessageId() =>
      Uint8List.fromList(Uuid.parse(_uuid.v7()));

  static String nodeIdOf(Uint8List x25519Pub) =>
      hexEncode(sha256Bytes(x25519Pub).sublist(0, 8));

  /// Encrypts and publishes a 1:1 payload. Returns the message id (hex).
  Future<String> sendDirect({
    required Uint8List recipientPub,
    required int payloadType,
    required List<int> plaintext,
    Uint8List? messageId,
    int chunkIndex = 0,
    int chunkTotal = 0,
  }) async {
    await crypto.ensureSession(
      myKeyPair: identity.x25519KeyPair,
      myPub: identity.x25519Pub,
      theirPub: recipientPub,
    );
    final id = messageId ?? _newMessageId();
    final nonce = crypto.newNonce();
    final env = Envelope(
      messageId: id,
      senderPub: identity.x25519Pub,
      recipientPub: recipientPub,
      ttl: Protocol.ttlDirect,
      hopCount: 0,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      payloadType: payloadType,
      chunkIndex: chunkIndex,
      chunkTotal: chunkTotal,
      nonce: nonce,
      ciphertext: Uint8List(0),
    );
    final box = await crypto.sealFor(
      theirPub: recipientPub,
      plaintext: plaintext,
      nonce: nonce,
      aad: EnvelopeCodec.aadOf(env),
    );
    final sealed = Envelope(
      messageId: id,
      senderPub: env.senderPub,
      recipientPub: env.recipientPub,
      ttl: env.ttl,
      hopCount: 0,
      timestampMs: env.timestampMs,
      payloadType: payloadType,
      chunkIndex: chunkIndex,
      chunkTotal: chunkTotal,
      nonce: nonce,
      ciphertext: concatBytes([box.cipherText, box.mac.bytes]),
    );
    await _publish(sealed, recipientNodeId: nodeIdOf(recipientPub));
    return sealed.messageIdHex;
  }

  /// Publishes to the public room. Payload is readable by any Messy install.
  Future<String> sendPublic(List<int> plaintext) async {
    final id = _newMessageId();
    final nonce = crypto.newNonce();
    final env = Envelope(
      messageId: id,
      senderPub: identity.x25519Pub,
      recipientPub: Uint8List(32),
      ttl: Protocol.ttlPublic,
      hopCount: 0,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      payloadType: Protocol.payloadPublicText,
      chunkIndex: 0,
      chunkTotal: 0,
      nonce: nonce,
      ciphertext: Uint8List(0),
    );
    final box = await crypto.sealPublic(
      roomName: publicRoomName,
      plaintext: plaintext,
      nonce: nonce,
      aad: EnvelopeCodec.aadOf(env),
    );
    final sealed = Envelope(
      messageId: id,
      senderPub: env.senderPub,
      recipientPub: env.recipientPub,
      ttl: env.ttl,
      hopCount: 0,
      timestampMs: env.timestampMs,
      payloadType: env.payloadType,
      chunkIndex: 0,
      chunkTotal: 0,
      nonce: nonce,
      ciphertext: concatBytes([box.cipherText, box.mac.bytes]),
    );
    await _publish(sealed, recipientNodeId: 'public');
    return sealed.messageIdHex;
  }

  /// Publishes to a group: floods like a public post (every phone relays)
  /// but only holders of the group key can decrypt.
  Future<String> sendGroup({
    required GroupRow group,
    required List<int> plaintext,
    Uint8List? messageId,
  }) async {
    final id = messageId ?? _newMessageId();
    final nonce = crypto.newNonce();
    final tag = sha256Bytes(group.key); // routing tag, one-way from the key
    final env = Envelope(
      messageId: id,
      senderPub: identity.x25519Pub,
      recipientPub: tag,
      ttl: Protocol.ttlDirect,
      hopCount: 0,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      payloadType: Protocol.payloadGroupText,
      chunkIndex: 0,
      chunkTotal: 0,
      nonce: nonce,
      ciphertext: Uint8List(0),
    );
    final box = await crypto.sealWithKey(
      keyBytes: group.key,
      plaintext: plaintext,
      nonce: nonce,
      aad: EnvelopeCodec.aadOf(env),
    );
    final sealed = Envelope(
      messageId: id,
      senderPub: env.senderPub,
      recipientPub: tag,
      ttl: env.ttl,
      hopCount: 0,
      timestampMs: env.timestampMs,
      payloadType: env.payloadType,
      chunkIndex: 0,
      chunkTotal: 0,
      nonce: nonce,
      ciphertext: concatBytes([box.cipherText, box.mac.bytes]),
    );
    await _publish(sealed, recipientNodeId: 'group');
    return sealed.messageIdHex;
  }

  Future<void> _publish(Envelope env, {required String recipientNodeId}) async {
    final frame = EnvelopeCodec.encode(env);
    await _markSeen(env);
    await db.into(db.relayStore).insertOnConflictUpdate(
          RelayStoreCompanion(
            messageId: Value(env.messageIdHex),
            chunkIndex: Value(env.chunkIndex),
            frame: Value(frame),
            recipientNodeId: Value(recipientNodeId),
            ttl: Value(env.ttl),
            size: Value(frame.length),
            storedAt: Value(DateTime.now().millisecondsSinceEpoch),
            mine: const Value(true),
          ),
        );
    final sent = await _forward(frame, exceptNodeId: null);
    if (sent > 0 && env.chunkIndex == 0) {
      await _setStatus(env.messageIdHex, domain.MessageStatus.sentToMesh);
    }
  }

  /// Sends a frame to every live link except [exceptNodeId]; returns how many
  /// peers took it.
  Future<int> _forward(Uint8List frame, {String? exceptNodeId}) async {
    var sent = 0;
    for (final auth in connectivity.liveLinks) {
      if (auth.nodeId == exceptNodeId) continue;
      try {
        await auth.link.sendFrame(frame);
        sent++;
      } on Object {
        // Dead link; connectivity will reap it.
      }
    }
    return sent;
  }

  /// Anti-entropy on link-up: offer everything we carry. The peer's dedupe
  /// set discards what it already has.
  Future<void> _syncTo(AuthenticatedLink auth) async {
    final rows = await db.select(db.relayStore).get();
    for (final row in rows) {
      try {
        await auth.link.sendFrame(row.frame);
      } on Object {
        return;
      }
    }
  }

  // -------------------------------------------------------------- receiving

  Future<void> _onFrame(AuthenticatedLink from, Uint8List frame) async {
    try {
      switch (FrameCodec.frameTypeOf(frame)) {
        case Protocol.frameEnvelope:
          await _onEnvelope(from, frame);
        case Protocol.frameContactReq:
          onContactRequest?.call(from, FrameCodec.decodeJson(frame));
        case Protocol.frameContactAccept:
          onContactAccept?.call(from, FrameCodec.decodeJson(frame));
        default:
          break; // hello handled by ConnectivityManager; rest reserved
      }
    } on Object {
      // A malformed frame from one peer must never take the router down.
    }
  }

  Future<bool> _alreadySeen(Envelope env) async {
    final row = await (db.select(db.seenEnvelopes)
          ..where((s) =>
              s.messageId.equals(env.messageIdHex) &
              s.chunkIndex.equals(env.chunkIndex)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> _markSeen(Envelope env) =>
      db.into(db.seenEnvelopes).insertOnConflictUpdate(
            SeenEnvelopesCompanion(
              messageId: Value(env.messageIdHex),
              chunkIndex: Value(env.chunkIndex),
              seenAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

  Future<void> _onEnvelope(AuthenticatedLink from, Uint8List frame) async {
    final env = EnvelopeCodec.decode(frame);
    if (await _alreadySeen(env)) return;
    await _markSeen(env);

    if (env.isPublic) {
      await _deliverPublic(env);
      await _relay(env, frame, from, recipientNodeId: 'public');
      return;
    }
    if (env.payloadType == Protocol.payloadGroupText) {
      // Group posts flood like public ones — members decrypt, everyone
      // relays. The recipient field is the group tag, not a real key.
      await _deliverGroupIfMember(env);
      await _relay(env, frame, from, recipientNodeId: 'group');
      return;
    }
    if (bytesEqual(env.recipientPub, identity.x25519Pub)) {
      await _deliverToMe(env);
      return;
    }
    await _relay(env, frame, from, recipientNodeId: nodeIdOf(env.recipientPub));
  }

  Future<void> _relay(
    Envelope env,
    Uint8List frame,
    AuthenticatedLink from, {
    required String recipientNodeId,
  }) async {
    if (env.ttl <= 1) return;
    final next = EnvelopeCodec.reencodeMutable(frame, env.ttl - 1, env.hopCount + 1);
    await db.into(db.relayStore).insertOnConflictUpdate(
          RelayStoreCompanion(
            messageId: Value(env.messageIdHex),
            chunkIndex: Value(env.chunkIndex),
            frame: Value(next),
            recipientNodeId: Value(recipientNodeId),
            ttl: Value(env.ttl - 1),
            size: Value(next.length),
            storedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
    await _forward(next, exceptNodeId: from.nodeId);
    await _enforceRelayBudget();
  }

  Future<void> _enforceRelayBudget() async {
    final rows = await (db.select(db.relayStore)
          ..where((r) => r.mine.equals(false))
          ..orderBy([(r) => OrderingTerm.asc(r.storedAt)]))
        .get();
    var total = rows.fold<int>(0, (n, r) => n + r.size);
    for (final row in rows) {
      if (total <= Protocol.relayBudgetBytes) break;
      await (db.delete(db.relayStore)
            ..where((r) =>
                r.messageId.equals(row.messageId) &
                r.chunkIndex.equals(row.chunkIndex)))
          .go();
      total -= row.size;
    }
  }

  Future<void> _deliverPublic(Envelope env) async {
    if (bytesEqual(env.senderPub, identity.x25519Pub)) return;
    final cipher = env.ciphertext;
    final plain = await crypto.openPublic(
      roomName: publicRoomName,
      ciphertext: cipher.sublist(0, cipher.length - 16),
      nonce: env.nonce,
      tag: cipher.sublist(cipher.length - 16),
      aad: EnvelopeCodec.aadOf(env),
    );
    final body = jsonDecode(utf8.decode(plain)) as Map<String, Object?>;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.messages).insertOnConflictUpdate(
          MessagesCompanion(
            messageId: Value(env.messageIdHex),
            chatId: const Value(publicRoomName),
            direction: Value(domain.MessageDirection.incoming.index),
            payloadType: Value(env.payloadType),
            body: Value((body['t'] as String?) ?? ''),
            senderName: Value(body['n'] as String?),
            senderNodeId: Value(nodeIdOf(env.senderPub)),
            sentAt: Value(env.timestampMs),
            receivedAt: Value(now),
            // Public posts always expire at 24 h — docs/SECURITY.md §4.
            expiresAt: Value(now + Protocol.publicRetention.inMilliseconds),
            status: Value(domain.MessageStatus.delivered.index),
          ),
        );
    onIncoming?.call(
      publicRoomName,
      'Local · ${(body['n'] as String?) ?? 'someone nearby'}',
      (body['t'] as String?) ?? '',
    );
  }

  Future<void> _deliverToMe(Envelope env) async {
    await crypto.ensureSession(
      myKeyPair: identity.x25519KeyPair,
      myPub: identity.x25519Pub,
      theirPub: env.senderPub,
    );
    final cipher = env.ciphertext;
    final plain = await crypto.openFrom(
      theirPub: env.senderPub,
      ciphertext: cipher.sublist(0, cipher.length - 16),
      nonce: env.nonce,
      tag: cipher.sublist(cipher.length - 16),
      aad: EnvelopeCodec.aadOf(env),
    );

    switch (env.payloadType) {
      case Protocol.payloadText:
        await _deliverText(env, plain);
      case Protocol.payloadDeliveryReceipt:
        await _onReceipt(utf8.decode(plain));
      case Protocol.payloadMediaManifest:
        await _deliverManifest(env, plain);
      case Protocol.payloadMediaChunk:
        await _deliverChunk(env, plain);
      case Protocol.payloadGroupInvite:
        await _onGroupInvite(env, plain);
    }
  }

  Future<void> _onGroupInvite(Envelope env, List<int> plain) async {
    final body = jsonDecode(utf8.decode(plain)) as Map<String, Object?>;
    final key = b64uDecode(body['g'] as String);
    if (key.length != 32) return;
    final groupId = hexEncode(sha256Bytes(key));
    final name = (body['name'] as String?) ?? 'Group';
    await db.into(db.groups).insert(
          GroupsCompanion(
            groupId: Value(groupId),
            name: Value(name),
            key: Value(key),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await db.into(db.chats).insert(
          ChatsCompanion(chatId: Value(groupId), nodeId: const Value(null)),
          mode: InsertMode.insertOrIgnore,
        );
    await _sendReceipt(env);
    onIncoming?.call(
      groupId,
      name,
      '${(body['n'] as String?) ?? 'Someone'} added you to the group',
    );
  }

  Future<void> _deliverGroupIfMember(Envelope env) async {
    final groupId = hexEncode(env.recipientPub);
    final group = await (db.select(db.groups)
          ..where((g) => g.groupId.equals(groupId)))
        .getSingleOrNull();
    if (group == null) return; // not a member — we just relay
    if (bytesEqual(env.senderPub, identity.x25519Pub)) return;
    final cipher = env.ciphertext;
    final plain = await crypto.openWithKey(
      keyBytes: group.key,
      ciphertext: cipher.sublist(0, cipher.length - 16),
      nonce: env.nonce,
      tag: cipher.sublist(cipher.length - 16),
      aad: EnvelopeCodec.aadOf(env),
    );
    final body = jsonDecode(utf8.decode(plain)) as Map<String, Object?>;
    final now = DateTime.now().millisecondsSinceEpoch;
    final disappearSecs = body['d'] as int?;
    await db.into(db.messages).insertOnConflictUpdate(
          MessagesCompanion(
            messageId: Value(env.messageIdHex),
            chatId: Value(groupId),
            direction: Value(domain.MessageDirection.incoming.index),
            payloadType: Value(env.payloadType),
            body: Value((body['t'] as String?) ?? ''),
            senderName: Value(body['n'] as String?),
            senderNodeId: Value(nodeIdOf(env.senderPub)),
            sentAt: Value(env.timestampMs),
            receivedAt: Value(now),
            expiresAt: Value(
              disappearSecs == null ? null : now + disappearSecs * 1000,
            ),
            status: Value(domain.MessageStatus.delivered.index),
          ),
        );
    onIncoming?.call(
      groupId,
      '${group.name} · ${(body['n'] as String?) ?? 'member'}',
      (body['t'] as String?) ?? '',
    );
  }

  Future<String> _ensureChatWithSender(Envelope env, String? name) async {
    final senderNode = nodeIdOf(env.senderPub);
    final contact = await (db.select(db.contacts)
          ..where((c) => c.nodeId.equals(senderNode)))
        .getSingleOrNull();
    if (contact == null) {
      // Message from someone who isn't a contact yet: create an unverified
      // entry so the chat has a name and replies can be encrypted back.
      await db.into(db.contacts).insert(
            ContactsCompanion(
              nodeId: Value(senderNode),
              x25519Pub: Value(env.senderPub),
              ed25519Pub: Value(Uint8List(0)),
              displayName: Value(name ?? senderNode.substring(0, 8)),
              verified: const Value(false),
              addedVia: const Value('nearby'),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    await db.into(db.chats).insert(
          ChatsCompanion(chatId: Value(senderNode), nodeId: Value(senderNode)),
          mode: InsertMode.insertOrIgnore,
        );
    return senderNode;
  }

  Future<void> _deliverText(Envelope env, List<int> plain) async {
    final body = jsonDecode(utf8.decode(plain)) as Map<String, Object?>;
    final chatId = await _ensureChatWithSender(env, body['n'] as String?);
    final now = DateTime.now().millisecondsSinceEpoch;
    final disappearSecs = body['d'] as int?;
    await db.into(db.messages).insertOnConflictUpdate(
          MessagesCompanion(
            messageId: Value(env.messageIdHex),
            chatId: Value(chatId),
            direction: Value(domain.MessageDirection.incoming.index),
            payloadType: Value(env.payloadType),
            body: Value((body['t'] as String?) ?? ''),
            senderNodeId: Value(chatId),
            sentAt: Value(env.timestampMs),
            receivedAt: Value(now),
            expiresAt: Value(
              disappearSecs == null ? null : now + disappearSecs * 1000,
            ),
            status: Value(domain.MessageStatus.delivered.index),
          ),
        );
    await _sendReceipt(env);
    onIncoming?.call(
      chatId,
      (body['n'] as String?) ?? chatId.substring(0, 8),
      (body['t'] as String?) ?? '',
    );
  }

  Future<void> _deliverManifest(Envelope env, List<int> plain) async {
    final m = jsonDecode(utf8.decode(plain)) as Map<String, Object?>;
    final chatId = await _ensureChatWithSender(env, m['sender'] as String?);
    final now = DateTime.now().millisecondsSinceEpoch;
    final mediaId = env.messageIdHex;
    final disappearSecs = m['d'] as int?;
    await db.into(db.mediaItems).insertOnConflictUpdate(
          MediaItemsCompanion(
            mediaId: Value(mediaId),
            messageId: Value(env.messageIdHex),
            mimeType: Value((m['mime'] as String?) ?? 'application/octet-stream'),
            totalSize: Value((m['size'] as num).toInt()),
            chunkTotal: Value((m['total'] as num).toInt()),
            sha256: Value(b64uDecode(m['sha'] as String)),
          ),
        );
    await db.into(db.messages).insertOnConflictUpdate(
          MessagesCompanion(
            messageId: Value(env.messageIdHex),
            chatId: Value(chatId),
            direction: Value(domain.MessageDirection.incoming.index),
            payloadType: Value(env.payloadType),
            body: Value((m['name'] as String?) ?? 'media'),
            senderNodeId: Value(chatId),
            mediaId: Value(mediaId),
            sentAt: Value(env.timestampMs),
            receivedAt: Value(now),
            expiresAt: Value(
              disappearSecs == null ? null : now + disappearSecs * 1000,
            ),
            status: Value(domain.MessageStatus.delivered.index),
          ),
        );
    await _tryAssemble(mediaId, env);
  }

  Future<void> _deliverChunk(Envelope env, List<int> plain) async {
    final mediaId = env.messageIdHex;
    await db.into(db.mediaChunks).insertOnConflictUpdate(
          MediaChunksCompanion(
            mediaId: Value(mediaId),
            chunkIndex: Value(env.chunkIndex),
            data: Value(Uint8List.fromList(plain)),
          ),
        );
    await _tryAssemble(mediaId, env);
  }

  Future<void> _tryAssemble(String mediaId, Envelope env) async {
    final media = await (db.select(db.mediaItems)
          ..where((m) => m.mediaId.equals(mediaId)))
        .getSingleOrNull();
    if (media == null || media.complete) return;
    final chunks = await (db.select(db.mediaChunks)
          ..where((c) => c.mediaId.equals(mediaId))
          ..orderBy([(c) => OrderingTerm.asc(c.chunkIndex)]))
        .get();
    if (chunks.length < media.chunkTotal) return;

    final bytes = concatBytes([for (final c in chunks) c.data]);
    if (!bytesEqual(sha256Bytes(bytes), media.sha256)) return;

    final path = await mediaStore.write(mediaId, media.mimeType, bytes);
    await (db.update(db.mediaItems)..where((m) => m.mediaId.equals(mediaId)))
        .write(MediaItemsCompanion(
      filePath: Value(path),
      complete: const Value(true),
    ));
    await (db.delete(db.mediaChunks)..where((c) => c.mediaId.equals(mediaId)))
        .go();
    await _sendReceipt(env);
    final msg = await (db.select(db.messages)
          ..where((m) => m.messageId.equals(media.messageId)))
        .getSingleOrNull();
    if (msg != null) {
      final contact = await (db.select(db.contacts)
            ..where((c) => c.nodeId.equals(msg.chatId)))
          .getSingleOrNull();
      final kind =
          media.mimeType.startsWith('video/') ? 'a video' : 'a photo';
      onIncoming?.call(
        msg.chatId,
        contact?.displayName ?? msg.chatId.substring(0, 8),
        'Sent you $kind',
      );
    }
  }

  Future<void> _sendReceipt(Envelope original) async {
    await sendDirect(
      recipientPub: original.senderPub,
      payloadType: Protocol.payloadDeliveryReceipt,
      plaintext: utf8.encode(original.messageIdHex),
    );
  }

  Future<void> _onReceipt(String deliveredMessageIdHex) async {
    await _setStatus(deliveredMessageIdHex, domain.MessageStatus.delivered);
    // Delivered — stop carrying it.
    await (db.delete(db.relayStore)
          ..where((r) => r.messageId.equals(deliveredMessageIdHex)))
        .go();
  }

  Future<void> _setStatus(String messageIdHex, domain.MessageStatus s) async {
    final current = await (db.select(db.messages)
          ..where((m) => m.messageId.equals(messageIdHex)))
        .getSingleOrNull();
    if (current == null) return;
    if (current.status >= s.index) return; // never downgrade
    await (db.update(db.messages)
          ..where((m) => m.messageId.equals(messageIdHex)))
        .write(MessagesCompanion(status: Value(s.index)));
  }
}
