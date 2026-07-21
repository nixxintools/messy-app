import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../core/bytes.dart';
import '../../data/db/database.dart';

/// One-time prekeys (OTKs) for per-message forward secrecy —
/// docs/SECURITY.md §2.
///
/// Own OTKs: X25519 keypairs generated locally; the public half is issued
/// to exactly one peer (so two contacts never hold the same key); the
/// secret is **deleted the moment a message sealed to it is decrypted** —
/// that deletion is the forward secrecy.
///
/// Peer OTKs: unused prekeys peers have issued to us, consumed (deleted)
/// when we seal a message to them. When the pool for a peer runs dry we
/// fall back to the static session (no FS for that message) until fresh
/// keys arrive in-band.
class PrekeyService {
  PrekeyService({required this.db});

  static const poolFloor = 32; // unissued own keys to keep on hand
  static const issueBatch = 8; // keys issued per bundle on link-up
  static const replenishPerMessage = 2; // keys piggybacked per text/receipt
  static const maxAge = Duration(days: 14);

  final MessyDatabase db;
  final _x25519 = X25519();

  int _now() => DateTime.now().millisecondsSinceEpoch;

  /// Top up the unissued pool and prune stale keys. Called at boot and
  /// opportunistically from [issueTo].
  Future<void> ensurePool() async {
    final cutoff = _now() - maxAge.inMilliseconds;
    await (db.delete(db.ownPrekeys)
          ..where((p) => p.createdAt.isSmallerThanValue(cutoff)))
        .go();
    await (db.delete(db.peerPrekeys)
          ..where((p) => p.receivedAt.isSmallerThanValue(cutoff)))
        .go();

    final unissued = await (db.select(db.ownPrekeys)
          ..where((p) => p.issuedTo.isNull()))
        .get();
    for (var i = unissued.length; i < poolFloor; i++) {
      await _generateOne();
    }
  }

  Future<void> _generateOne() async {
    final kp = await _x25519.newKeyPair();
    final pub = Uint8List.fromList((await kp.extractPublicKey()).bytes);
    final priv = Uint8List.fromList(await kp.extractPrivateKeyBytes());
    await db.into(db.ownPrekeys).insert(
          OwnPrekeysCompanion(
            keyId: Value(hexEncode(sha256Bytes(pub).sublist(0, 8))),
            priv: Value(priv),
            pub: Value(pub),
            createdAt: Value(_now()),
          ),
        );
  }

  /// Issues up to [count] of our prekey publics to a peer, marking them so
  /// they're never handed to anyone else. Returns wire form
  /// `[{i: keyId, k: b64u(pub)}, …]`.
  Future<List<Map<String, String>>> issueTo(String nodeId, int count) async {
    await ensurePool();
    final rows = await (db.select(db.ownPrekeys)
          ..where((p) => p.issuedTo.isNull())
          ..limit(count))
        .get();
    final out = <Map<String, String>>[];
    for (final row in rows) {
      await (db.update(db.ownPrekeys)
            ..where((p) => p.keyId.equals(row.keyId)))
          .write(OwnPrekeysCompanion(issuedTo: Value(nodeId)));
      out.add({'i': row.keyId, 'k': b64u(row.pub)});
    }
    return out;
  }

  /// Wire-form bytes covered by the bundle signature: every pub, in order.
  static Uint8List bundleSignedBytes(int ts, List<Map<String, String>> pk) {
    return concatBytes([
      'messy-otk-bundle'.codeUnits,
      '$ts'.codeUnits,
      for (final entry in pk) b64uDecode(entry['k']!),
    ]);
  }

  /// Stores prekeys a peer issued to us (from a verified bundle frame or
  /// an authenticated in-band payload).
  Future<void> storePeerOtks(String nodeId, List<dynamic> bundle) async {
    for (final entry in bundle) {
      if (entry is! Map) continue;
      final id = entry['i'];
      final k = entry['k'];
      if (id is! String || k is! String) continue;
      final pub = b64uDecode(k);
      if (pub.length != 32) continue;
      // keyId must be honest — derive, don't trust.
      if (hexEncode(sha256Bytes(pub).sublist(0, 8)) != id) continue;
      await db.into(db.peerPrekeys).insert(
            PeerPrekeysCompanion(
              nodeId: Value(nodeId),
              keyId: Value(id),
              pub: Value(pub),
              receivedAt: Value(_now()),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  /// Consumes (removes) one unused prekey for a peer, oldest first.
  /// Null when the pool is dry → caller falls back to the static session.
  Future<({String keyId, Uint8List pub})?> takePeerOtk(String nodeId) async {
    final row = await (db.select(db.peerPrekeys)
          ..where((p) => p.nodeId.equals(nodeId))
          ..orderBy([(p) => OrderingTerm.asc(p.receivedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    await (db.delete(db.peerPrekeys)
          ..where((p) =>
              p.nodeId.equals(nodeId) & p.keyId.equals(row.keyId)))
        .go();
    return (keyId: row.keyId, pub: row.pub);
  }

  /// Looks up one of our own OTK secrets by id. Caller must invoke
  /// [deleteOwn] after a successful decrypt — that deletion is the FS.
  Future<({Uint8List priv, Uint8List pub})?> getOwnSecret(String keyId) async {
    final row = await (db.select(db.ownPrekeys)
          ..where((p) => p.keyId.equals(keyId)))
        .getSingleOrNull();
    if (row == null) return null;
    return (priv: row.priv, pub: row.pub);
  }

  Future<void> deleteOwn(String keyId) => (db.delete(db.ownPrekeys)
        ..where((p) => p.keyId.equals(keyId)))
      .go();
}
