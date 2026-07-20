import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/bytes.dart';

/// The local identity — docs/SECURITY.md §1.
///
/// One random 32-byte seed (Android Keystore via flutter_secure_storage)
/// deterministically yields:
///   - an X25519 keypair (encryption identity)
///   - an Ed25519 keypair (signing identity)
/// nodeId = hex(SHA-256(x25519Pub)[0..16]).
class LocalIdentity {
  LocalIdentity({
    required this.displayName,
    required this.x25519KeyPair,
    required this.ed25519KeyPair,
    required this.x25519Pub,
    required this.ed25519Pub,
  });

  final String displayName;
  final SimpleKeyPair x25519KeyPair;
  final SimpleKeyPair ed25519KeyPair;
  final Uint8List x25519Pub;
  final Uint8List ed25519Pub;

  String get nodeId => hexEncode(sha256Bytes(x25519Pub).sublist(0, 8));
}

class IdentityService {
  IdentityService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _seedKey = 'messy.identity.seed';
  static const _nameKey = 'messy.identity.name';

  final FlutterSecureStorage _storage;

  Future<bool> hasIdentity() async => await _storage.read(key: _seedKey) != null;

  /// Creates the identity on first run; no-op if one exists.
  Future<void> createIdentity(String displayName) async {
    if (await hasIdentity()) return;
    final rng = Random.secure();
    final seed = Uint8List.fromList(
      List<int>.generate(32, (_) => rng.nextInt(256)),
    );
    await _storage.write(key: _seedKey, value: b64u(seed));
    await _storage.write(key: _nameKey, value: displayName);
  }

  Future<LocalIdentity> load() async {
    final seedStr = await _storage.read(key: _seedKey);
    final name = await _storage.read(key: _nameKey) ?? 'anonymous';
    if (seedStr == null) {
      throw StateError('No identity — call createIdentity first');
    }
    final seed = b64uDecode(seedStr);

    // Domain-separate the two key seeds from the master seed.
    final xSeed = sha256Bytes(concatBytes([seed, 'x25519'.codeUnits]));
    final eSeed = sha256Bytes(concatBytes([seed, 'ed25519'.codeUnits]));

    final x = await X25519().newKeyPairFromSeed(xSeed);
    final e = await Ed25519().newKeyPairFromSeed(eSeed);
    final xPub = Uint8List.fromList((await x.extractPublicKey()).bytes);
    final ePub = Uint8List.fromList((await e.extractPublicKey()).bytes);

    return LocalIdentity(
      displayName: name,
      x25519KeyPair: x,
      ed25519KeyPair: e,
      x25519Pub: xPub,
      ed25519Pub: ePub,
    );
  }

  Future<void> setDisplayName(String name) =>
      _storage.write(key: _nameKey, value: name);

  Future<Uint8List> sign(LocalIdentity id, List<int> message) async {
    final sig = await Ed25519().sign(message, keyPair: id.ed25519KeyPair);
    return Uint8List.fromList(sig.bytes);
  }

  static Future<bool> verify({
    required List<int> message,
    required List<int> signature,
    required List<int> ed25519Pub,
  }) {
    return Ed25519().verify(
      message,
      signature: Signature(
        signature,
        publicKey: SimplePublicKey(ed25519Pub, type: KeyPairType.ed25519),
      ),
    );
  }
}
