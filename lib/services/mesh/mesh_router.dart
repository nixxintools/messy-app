import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart' show SecretBox, SimpleKeyPair;
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
import '../../core/well_known.dart';
import '../crypto/identity_service.dart';
import '../crypto/prekey_service.dart';
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
    required this.identityService,
    required this.crypto,
    required this.prekeys,
    required this.connectivity,
    required this.mediaStore,
  });

  static const publicRoomName = 'local';

  final MessyDatabase db;
  final LocalIdentity identity;
  final IdentityService identityService;
  final SessionCrypto crypto;
  final PrekeyService prekeys;
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
      _sendPrekeyBundle(auth);
      _syncTo(auth);
    });
  }

  /// Issues a batch of one-time prekeys to a freshly-linked peer, signed
  /// with our Ed25519 identity so a hostile network can't inject keys.
  Future<void> _sendPrekeyBundle(AuthenticatedLink auth) async {
    try {
      final pk =
          await prekeys.issueTo(auth.nodeId, PrekeyService.issueBatch);
      if (pk.isEmpty) return;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final sig = await identityService.sign(
        identity,
        PrekeyService.bundleSignedBytes(ts, pk),
      );
      await auth.link.sendFrame(FrameCodec.encodeJson(Protocol.framePrekeys, {
        'pk': pk,
        'ts': ts,
        'sig': b64u(sig),
      }));
    } on Object {
      // Link died mid-send; the next link-up re-issues.
    }
  }

  Future<void> _onPrekeyFrame(
    AuthenticatedLink from,
    Map<String, Object?> body,
  ) async {
    try {
      final pk = (body['pk'] as List?) ?? const [];
      final ts = body['ts'] as int;
      final sig = b64uDecode(body['sig'] as String);
      final ok = await IdentityService.verify(
        message: PrekeyService.bundleSignedBytes(
          ts,
          [for (final e in pk) (e as Map).cast<String, String>()],
        ),
        signature: sig,
        ed25519Pub: from.ed25519Pub,
      );
      if (!ok) return;
      await prekeys.storePeerOtks(from.nodeId, pk);
    } on Object {
      // Malformed bundle — ignore.
    }
  }

  // ---------------------------------------------------------------- sending

  Uint8List _newMessageId() =>
      Uint8List.fromList(Uuid.parse(_uuid.v7()));

  static String nodeIdOf(Uint8List x25519Pub) =>
      hexEncode(sha256Bytes(x25519Pub).sublist(0, 8));

  /// Encrypts and publishes a 1:1 payload. Returns the message id (hex).
  ///
  /// Forward secrecy: small payloads (text, receipts, group invites) are
  /// sealed to one of the recipient's one-time prekeys when we hold an
  /// unused one, falling back to the static session when the pool is dry.
  /// Media stays on static sessions — a single video would drain hundreds
  /// of prekeys.
  Future<String> sendDirect({
    required Uint8List recipientPub,
    required int payloadType,
    required List<int> plaintext,
    Uint8List? messageId,
    int chunkIndex = 0,
    int chunkTotal = 0,
  }) async {
    final id = messageId ?? _newMessageId();
    final nonce = crypto.newNonce();
    final recipientNode = nodeIdOf(recipientPub);

    final wantsFs = payloadType == Protocol.payloadText ||
        payloadType == Protocol.payloadDeliveryReceipt ||
        payloadType == Protocol.payloadGroupInvite;
    final otk = wantsFs ? await prekeys.takePeerOtk(recipientNode) : null;

    Uint8List? ephPub;
    SimpleKeyPair? ephKeyPair;
    if (otk != null) {
      (ephKeyPair, ephPub) = await crypto.newEphemeral();
    }

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
      fsMode: otk == null ? Envelope.fsStatic : Envelope.fsOtk,
      ephPub: ephPub,
      otkKeyId: otk == null ? null : hexDecode(otk.keyId),
      ciphertext: Uint8List(0),
    );
    final aad = EnvelopeCodec.aadOf(env);

    final SecretBox box;
    if (otk != null) {
      box = await crypto.sealOtk(
        ephKeyPair: ephKeyPair!,
        ephPub: ephPub!,
        myStaticKeyPair: identity.x25519KeyPair,
        otkPub: otk.pub,
        plaintext: plaintext,
        nonce: nonce,
        aad: aad,
      );
    } else {
      await crypto.ensureSession(
        myKeyPair: identity.x25519KeyPair,
        myPub: identity.x25519Pub,
        theirPub: recipientPub,
      );
      box = await crypto.sealFor(
        theirPub: recipientPub,
        plaintext: plaintext,
        nonce: nonce,
        aad: aad,
      );
    }

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
      fsMode: env.fsMode,
      ephPub: env.ephPub,
      otkKeyId: env.otkKeyId,
      ciphertext: concatBytes([box.cipherText, box.mac.bytes]),
    );
    await _publish(sealed, recipientNodeId: recipientNode);
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
  /// but only holders of the group key can decrypt. Also used for the
  /// well-known Media channel and for group media (manifest/chunks).
  Future<String> sendGroup({
    required GroupRow group,
    required List<int> plaintext,
    Uint8List? messageId,
    int payloadType = Protocol.payloadGroupText,
    int chunkIndex = 0,
    int chunkTotal = 0,
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
      payloadType: payloadType,
      chunkIndex: chunkIndex,
      chunkTotal: chunkTotal,
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
      chunkIndex: chunkIndex,
      chunkTotal: chunkTotal,
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
        case Protocol.framePrekeys:
          await _onPrekeyFrame(from, FrameCodec.decodeJson(frame));
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
    if (bytesEqual(env.recipientPub, identity.x25519Pub)) {
      await _deliverToMe(env);
      return;
    }
    // Group / media-channel posts flood like public ones — members decrypt,
    // everyone relays. The recipient field is the group tag, not a key.
    if (env.payloadType == Protocol.payloadGroupText ||
        env.payloadType == Protocol.payloadMediaManifest ||
        env.payloadType == Protocol.payloadMediaChunk) {
      final group = await (db.select(db.groups)
            ..where((g) => g.groupId.equals(hexEncode(env.recipientPub))))
          .getSingleOrNull();
      if (group != null) {
        await _deliverGroup(env, group);
        await _relay(env, frame, from, recipientNodeId: 'group');
        return;
      }
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
    final cipher = env.ciphertext;
    final aad = EnvelopeCodec.aadOf(env);
    final List<int> plain;

    if (env.fsMode == Envelope.fsOtk) {
      final keyId = hexEncode(env.otkKeyId);
      final own = await prekeys.getOwnSecret(keyId);
      if (own == null) return; // consumed/expired — replay or stale copy
      plain = await crypto.openOtk(
        otkPriv: own.priv,
        otkPub: own.pub,
        ephPub: env.ephPub,
        senderStaticPub: env.senderPub,
        ciphertext: cipher.sublist(0, cipher.length - 16),
        nonce: env.nonce,
        tag: cipher.sublist(cipher.length - 16),
        aad: aad,
      );
      // Decrypt succeeded → burn the secret. THIS is the forward secrecy.
      await prekeys.deleteOwn(keyId);
    } else {
      await crypto.ensureSession(
        myKeyPair: identity.x25519KeyPair,
        myPub: identity.x25519Pub,
        theirPub: env.senderPub,
      );
      plain = await crypto.openFrom(
        theirPub: env.senderPub,
        ciphertext: cipher.sublist(0, cipher.length - 16),
        nonce: env.nonce,
        tag: cipher.sublist(cipher.length - 16),
        aad: aad,
      );
    }

    switch (env.payloadType) {
      case Protocol.payloadText:
        await _deliverText(env, plain);
      case Protocol.payloadDeliveryReceipt:
        await _onReceiptPayload(env, plain);
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

  /// Delivers a group (or Media-channel) envelope we hold the key for.
  /// No receipts — group posts are broadcasts, like the public room.
  Future<void> _deliverGroup(Envelope env, GroupRow group) async {
    if (bytesEqual(env.senderPub, identity.x25519Pub)) return;
    final groupId = group.groupId;
    final isMediaRoom = groupId == WellKnown.mediaRoomId;
    final cipher = env.ciphertext;
    final plain = await crypto.openWithKey(
      keyBytes: group.key,
      ciphertext: cipher.sublist(0, cipher.length - 16),
      nonce: env.nonce,
      tag: cipher.sublist(cipher.length - 16),
      aad: EnvelopeCodec.aadOf(env),
    );
    final now = DateTime.now().millisecondsSinceEpoch;

    int? expiryFor(int? disappearSecs) => isMediaRoom
        // Public channel: always 24 h, like the Local room.
        ? now + Protocol.publicRetention.inMilliseconds
        : (disappearSecs == null ? null : now + disappearSecs * 1000);

    switch (env.payloadType) {
      case Protocol.payloadGroupText:
        final body = jsonDecode(utf8.decode(plain)) as Map<String, Object?>;
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
                expiresAt: Value(expiryFor(body['d'] as int?)),
                status: Value(domain.MessageStatus.delivered.index),
              ),
            );
        onIncoming?.call(
          groupId,
          '${group.name} · ${(body['n'] as String?) ?? 'member'}',
          (body['t'] as String?) ?? '',
        );
      case Protocol.payloadMediaManifest:
        final m = jsonDecode(utf8.decode(plain)) as Map<String, Object?>;
        final mediaId = env.messageIdHex;
        await db.into(db.mediaItems).insertOnConflictUpdate(
              MediaItemsCompanion(
                mediaId: Value(mediaId),
                messageId: Value(env.messageIdHex),
                mimeType: Value(
                    (m['mime'] as String?) ?? 'application/octet-stream'),
                totalSize: Value((m['size'] as num).toInt()),
                chunkTotal: Value((m['total'] as num).toInt()),
                sha256: Value(b64uDecode(m['sha'] as String)),
              ),
            );
        await db.into(db.messages).insertOnConflictUpdate(
              MessagesCompanion(
                messageId: Value(env.messageIdHex),
                chatId: Value(groupId),
                direction: Value(domain.MessageDirection.incoming.index),
                payloadType: Value(env.payloadType),
                body: Value((m['name'] as String?) ?? 'media'),
                senderName: Value(m['sender'] as String?),
                senderNodeId: Value(nodeIdOf(env.senderPub)),
                mediaId: Value(mediaId),
                sentAt: Value(env.timestampMs),
                receivedAt: Value(now),
                expiresAt: Value(expiryFor(m['d'] as int?)),
                status: Value(domain.MessageStatus.delivered.index),
              ),
            );
        await _tryAssemble(mediaId, env, receipt: false);
        onIncoming?.call(
          groupId,
          '${group.name} · ${(m['sender'] as String?) ?? 'member'}',
          'Shared a file',
        );
      case Protocol.payloadMediaChunk:
        await db.into(db.mediaChunks).insertOnConflictUpdate(
              MediaChunksCompanion(
                mediaId: Value(env.messageIdHex),
                chunkIndex: Value(env.chunkIndex),
                data: Value(Uint8List.fromList(plain)),
              ),
            );
        await _tryAssemble(env.messageIdHex, env, receipt: false);
    }
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
    final pk = body['pk'];
    if (pk is List) {
      // In-band prekey replenishment, authenticated by the AEAD.
      await prekeys.storePeerOtks(nodeIdOf(env.senderPub), pk);
    }
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

  Future<void> _tryAssemble(String mediaId, Envelope env,
      {bool receipt = true}) async {
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
    if (!receipt) return; // group/channel media: notified at manifest time
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
    // Receipts double as prekey replenishment: each one carries a couple
    // of fresh OTK publics so long conversations keep per-message FS.
    final senderNode = nodeIdOf(original.senderPub);
    await sendDirect(
      recipientPub: original.senderPub,
      payloadType: Protocol.payloadDeliveryReceipt,
      plaintext: utf8.encode(jsonEncode({
        'm': original.messageIdHex,
        'pk': await prekeys.issueTo(
          senderNode,
          PrekeyService.replenishPerMessage,
        ),
      })),
    );
  }

  Future<void> _onReceiptPayload(Envelope env, List<int> plain) async {
    final text = utf8.decode(plain);
    try {
      final body = jsonDecode(text) as Map<String, Object?>;
      final pk = body['pk'];
      if (pk is List) {
        // Authenticated by the AEAD — only the sender could have sealed it.
        await prekeys.storePeerOtks(nodeIdOf(env.senderPub), pk);
      }
      await _onReceipt(body['m'] as String);
    } on FormatException {
      await _onReceipt(text); // legacy plain-string receipt
    }
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
