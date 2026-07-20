import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/bytes.dart';
import '../../core/constants.dart';
import '../../data/db/database.dart';
import '../../domain/codec/frame_codec.dart';
import '../../transport/connectivity_manager.dart';
import '../crypto/identity_service.dart';
import '../mesh/mesh_router.dart';
import 'qr_payload.dart';

/// A nearby contact request awaiting the user's accept/decline.
class PendingRequest {
  const PendingRequest({
    required this.nodeId,
    required this.displayName,
    required this.x25519Pub,
    required this.ed25519Pub,
  });

  final String nodeId;
  final String displayName;
  final Uint8List x25519Pub;
  final Uint8List ed25519Pub;
}

/// Adding users — docs/SECURITY.md §3.
/// QR scan → verified. Nearby request/accept → unverified (fingerprint
/// phrase shown for out-of-band comparison).
class ContactService {
  ContactService({
    required this.db,
    required this.identity,
    required this.identityService,
    required this.connectivity,
    required this.router,
  }) {
    router.onContactRequest = _onRequestFrame;
    router.onContactAccept = _onAcceptFrame;
  }

  final MessyDatabase db;
  final LocalIdentity identity;
  final IdentityService identityService;
  final ConnectivityManager connectivity;
  final MeshRouter router;

  final Map<String, PendingRequest> _pending = {};
  final _pendingController =
      StreamController<List<PendingRequest>>.broadcast();

  Stream<List<PendingRequest>> get pendingRequests =>
      _pendingController.stream;
  List<PendingRequest> get currentPending => _pending.values.toList();

  String myQrPayload() => QrContact(
        x25519Pub: identity.x25519Pub,
        ed25519Pub: identity.ed25519Pub,
        displayName: identity.displayName,
      ).encode();

  /// In-person QR scan → verified contact.
  Future<bool> addFromQr(String raw) async {
    final qr = QrContact.tryDecode(raw);
    if (qr == null || qr.nodeId == identity.nodeId) return false;
    await _upsertContact(
      nodeId: qr.nodeId,
      x25519Pub: qr.x25519Pub,
      ed25519Pub: qr.ed25519Pub,
      displayName: qr.displayName,
      verified: true,
      addedVia: 'qr',
    );
    return true;
  }

  /// Sends a signed contact request over the live link to a nearby peer.
  Future<bool> sendRequest(String nodeId) async {
    final auth = connectivity.linkFor(nodeId);
    if (auth == null) return false;
    await auth.link.sendFrame(
      await _signedContactFrame(Protocol.frameContactReq, 'contact-req'),
    );
    return true;
  }

  Future<void> accept(PendingRequest req) async {
    await _upsertContact(
      nodeId: req.nodeId,
      x25519Pub: req.x25519Pub,
      ed25519Pub: req.ed25519Pub,
      displayName: req.displayName,
      verified: false,
      addedVia: 'nearby',
    );
    _pending.remove(req.nodeId);
    _pendingController.add(currentPending);

    final auth = connectivity.linkFor(req.nodeId);
    if (auth != null) {
      await auth.link.sendFrame(
        await _signedContactFrame(Protocol.frameContactAccept, 'contact-acc'),
      );
    }
  }

  void decline(PendingRequest req) {
    _pending.remove(req.nodeId);
    _pendingController.add(currentPending);
  }

  Future<void> markVerified(String nodeId) =>
      (db.update(db.contacts)..where((c) => c.nodeId.equals(nodeId)))
          .write(const ContactsCompanion(verified: Value(true)));

  // ---------------------------------------------------------------- frames

  Future<Uint8List> _signedContactFrame(int frameType, String context) async {
    final sig = await identityService.sign(
      identity,
      concatBytes([identity.x25519Pub, context.codeUnits]),
    );
    return FrameCodec.encodeJson(frameType, {
      'x': b64u(identity.x25519Pub),
      'e': b64u(identity.ed25519Pub),
      'n': identity.displayName,
      'sig': b64u(sig),
    });
  }

  Future<void> _onRequestFrame(
    AuthenticatedLink from,
    Map<String, Object?> body,
  ) async {
    final parsed = await _verifySignedContact(body, 'contact-req');
    if (parsed == null) return;
    final existing = await (db.select(db.contacts)
          ..where((c) => c.nodeId.equals(parsed.nodeId)))
        .getSingleOrNull();
    if (existing != null) {
      // Already a contact: auto-accept silently.
      await accept(parsed);
      return;
    }
    _pending[parsed.nodeId] = parsed;
    _pendingController.add(currentPending);
  }

  Future<void> _onAcceptFrame(
    AuthenticatedLink from,
    Map<String, Object?> body,
  ) async {
    final parsed = await _verifySignedContact(body, 'contact-acc');
    if (parsed == null) return;
    await _upsertContact(
      nodeId: parsed.nodeId,
      x25519Pub: parsed.x25519Pub,
      ed25519Pub: parsed.ed25519Pub,
      displayName: parsed.displayName,
      verified: false,
      addedVia: 'nearby',
    );
  }

  Future<PendingRequest?> _verifySignedContact(
    Map<String, Object?> body,
    String context,
  ) async {
    try {
      final xPub = b64uDecode(body['x'] as String);
      final ePub = b64uDecode(body['e'] as String);
      final sig = b64uDecode(body['sig'] as String);
      final ok = await IdentityService.verify(
        message: concatBytes([xPub, context.codeUnits]),
        signature: sig,
        ed25519Pub: ePub,
      );
      if (!ok) return null;
      return PendingRequest(
        nodeId: hexEncode(sha256Bytes(xPub).sublist(0, 8)),
        displayName: (body['n'] as String?) ?? 'unknown',
        x25519Pub: xPub,
        ed25519Pub: ePub,
      );
    } on Object {
      return null;
    }
  }

  Future<void> _upsertContact({
    required String nodeId,
    required Uint8List x25519Pub,
    required Uint8List ed25519Pub,
    required String displayName,
    required bool verified,
    required String addedVia,
  }) async {
    await db.into(db.contacts).insertOnConflictUpdate(
          ContactsCompanion(
            nodeId: Value(nodeId),
            x25519Pub: Value(x25519Pub),
            ed25519Pub: Value(ed25519Pub),
            displayName: Value(displayName),
            verified: Value(verified),
            addedVia: Value(addedVia),
          ),
        );
    await db.into(db.chats).insert(
          ChatsCompanion(chatId: Value(nodeId), nodeId: Value(nodeId)),
          mode: InsertMode.insertOrIgnore,
        );
  }
}
