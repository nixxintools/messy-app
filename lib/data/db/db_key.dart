import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The database-encryption key for SQLCipher.
///
/// A random 256-bit key generated on first launch and stored in
/// flutter_secure_storage (Android Keystore-backed, hardware-protected on
/// most devices). The on-disk database is AES-encrypted with it, so a copied
/// database file is useless without the Keystore — this is what protects OTK
/// secrets and routing metadata at rest, not "plain SQLite".
abstract final class DbKey {
  static const _key = 'messy.db.key.v1';

  static Future<String> getOrCreateHex([FlutterSecureStorage? storage]) async {
    final s = storage ?? const FlutterSecureStorage();
    final existing = await s.read(key: _key);
    if (existing != null && existing.length == 64) return existing;
    final rng = Random.secure();
    final hex = List<int>.generate(32, (_) => rng.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    await s.write(key: _key, value: hex);
    return hex;
  }
}
