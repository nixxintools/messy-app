import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/bytes.dart';

/// Result of a PIN verification attempt.
sealed class PinResult {
  const PinResult();
}

class PinOk extends PinResult {
  const PinOk();
}

class PinWrong extends PinResult {
  const PinWrong(this.attemptsLeftBeforeLockout);
  final int attemptsLeftBeforeLockout;
}

class PinLockedOut extends PinResult {
  const PinLockedOut(this.retryInSeconds);
  final int retryInSeconds;
}

/// App-access PIN — hardened after external review.
///
/// - Hash: **Argon2id** (memory-hard KDF), not a bare SHA-256.
/// - **Rate limiting**: failed attempts trigger escalating lockouts, so the
///   ~10^6 keyspace of a 6-digit PIN can't be brute-forced quickly. Attempt
///   state lives in Keystore-backed secure storage (survives DB wipes).
/// - Storage: salt + Argon2id hash in flutter_secure_storage (Android
///   Keystore).
///
/// This gates the UI. Data-at-rest confidentiality comes from the SQLCipher
/// encrypted database (see MessyDatabase) whose key is Keystore-held.
class PinService {
  PinService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _hashKey = 'messy.pin.hash';
  static const _saltKey = 'messy.pin.salt';
  static const _enabledKey = 'messy.pin.enabled';
  static const _lastUnlockKey = 'messy.pin.lastUnlockMs';
  static const _failCountKey = 'messy.pin.failCount';
  static const _lockUntilKey = 'messy.pin.lockUntilMs';
  static const unlockValidity = Duration(hours: 24);

  /// No lockout for the first few fumbles; then escalating delays.
  static const _freeAttempts = 4;

  final FlutterSecureStorage _storage;

  // Argon2id tuned to run on budget phones (~a few hundred ms) while staying
  // memory-hard: 19 MiB, 2 passes. OWASP minimum profile.
  final _argon = Argon2id(
    parallelism: 1,
    memory: 19 * 1024, // KiB
    iterations: 2,
    hashLength: 32,
  );

  Future<bool> hasPin() async => await _storage.read(key: _hashKey) != null;

  Future<bool> isEnabled() async =>
      await _storage.read(key: _enabledKey) != '0';

  Future<void> setEnabled(bool enabled) =>
      _storage.write(key: _enabledKey, value: enabled ? '1' : '0');

  Future<Uint8List> _hash(String pin, Uint8List salt) async {
    final key = await _argon.deriveKey(
      secretKey: SecretKey(pin.codeUnits),
      nonce: salt,
    );
    return Uint8List.fromList(await key.extractBytes());
  }

  Future<void> setPin(String pin) async {
    final rng = Random.secure();
    final salt =
        Uint8List.fromList(List<int>.generate(16, (_) => rng.nextInt(256)));
    await _storage.write(key: _saltKey, value: b64u(salt));
    await _storage.write(key: _hashKey, value: b64u(await _hash(pin, salt)));
    await _resetAttempts();
  }

  /// Seconds remaining on an active lockout, or 0 if not locked.
  Future<int> lockoutRemainingSeconds() async {
    final until =
        int.tryParse(await _storage.read(key: _lockUntilKey) ?? '') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return until > now ? ((until - now) / 1000).ceil() : 0;
  }

  Future<PinResult> verify(String pin) async {
    final locked = await lockoutRemainingSeconds();
    if (locked > 0) return PinLockedOut(locked);

    final saltStr = await _storage.read(key: _saltKey);
    final hashStr = await _storage.read(key: _hashKey);
    if (saltStr == null || hashStr == null) {
      return const PinWrong(_freeAttempts);
    }
    final ok = _constantTimeEq(
      await _hash(pin, b64uDecode(saltStr)),
      b64uDecode(hashStr),
    );
    if (ok) {
      await _resetAttempts();
      await markUnlocked();
      return const PinOk();
    }
    return _registerFailure();
  }

  Future<PinResult> _registerFailure() async {
    final fails =
        (int.tryParse(await _storage.read(key: _failCountKey) ?? '') ?? 0) + 1;
    await _storage.write(key: _failCountKey, value: '$fails');
    final over = fails - _freeAttempts;
    if (over <= 0) {
      return PinWrong(_freeAttempts - fails);
    }
    // Escalating backoff: 5s, 15s, 60s, 300s, capped at 1 h.
    final penalties = [5, 15, 60, 300, 900, 3600];
    final secs = penalties[(over - 1).clamp(0, penalties.length - 1)];
    final until = DateTime.now().millisecondsSinceEpoch + secs * 1000;
    await _storage.write(key: _lockUntilKey, value: '$until');
    return PinLockedOut(secs);
  }

  Future<void> _resetAttempts() async {
    await _storage.delete(key: _failCountKey);
    await _storage.delete(key: _lockUntilKey);
  }

  Future<void> markUnlocked() => _storage.write(
        key: _lastUnlockKey,
        value: '${DateTime.now().millisecondsSinceEpoch}',
      );

  Future<bool> needsUnlock() async {
    if (!await isEnabled()) return false;
    if (!await hasPin()) return true;
    final last =
        int.tryParse(await _storage.read(key: _lastUnlockKey) ?? '') ?? 0;
    return DateTime.now().millisecondsSinceEpoch - last >=
        unlockValidity.inMilliseconds;
  }

  static bool _constantTimeEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
