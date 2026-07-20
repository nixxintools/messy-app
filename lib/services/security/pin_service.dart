import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/bytes.dart';

/// App-access PIN — security-first defaults.
///
/// The PIN gate is ON by default and set up mandatorily during onboarding;
/// the user may switch it off later in Settings (we start with security and
/// let the user reduce it, never the reverse). Once entered, the app stays
/// unlocked for 24 h — so the PIN is required at least once a day.
///
/// Storage: salted SHA-256 of the PIN in the Android Keystore-backed store.
/// This gates the UI; it is not disk encryption — the DB itself is protected
/// by Android's file-based encryption.
class PinService {
  PinService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _hashKey = 'messy.pin.hash';
  static const _saltKey = 'messy.pin.salt';
  static const _enabledKey = 'messy.pin.enabled';
  static const _lastUnlockKey = 'messy.pin.lastUnlockMs';
  static const unlockValidity = Duration(hours: 24);

  final FlutterSecureStorage _storage;

  Future<bool> hasPin() async => await _storage.read(key: _hashKey) != null;

  /// On by default: only an explicit '0' disables the gate.
  Future<bool> isEnabled() async =>
      await _storage.read(key: _enabledKey) != '0';

  Future<void> setEnabled(bool enabled) =>
      _storage.write(key: _enabledKey, value: enabled ? '1' : '0');

  Future<void> setPin(String pin) async {
    final rng = Random.secure();
    final salt =
        Uint8List.fromList(List<int>.generate(16, (_) => rng.nextInt(256)));
    await _storage.write(key: _saltKey, value: b64u(salt));
    await _storage.write(key: _hashKey, value: b64u(_hash(pin, salt)));
  }

  Future<bool> verifyPin(String pin) async {
    final saltStr = await _storage.read(key: _saltKey);
    final hashStr = await _storage.read(key: _hashKey);
    if (saltStr == null || hashStr == null) return false;
    final ok = bytesEqual(_hash(pin, b64uDecode(saltStr)), b64uDecode(hashStr));
    if (ok) await markUnlocked();
    return ok;
  }

  Future<void> markUnlocked() => _storage.write(
        key: _lastUnlockKey,
        value: '${DateTime.now().millisecondsSinceEpoch}',
      );

  /// True when the PIN gate must be shown before the app opens.
  Future<bool> needsUnlock() async {
    if (!await isEnabled()) return false;
    if (!await hasPin()) return true; // enabled but never set — force setup
    final last =
        int.tryParse(await _storage.read(key: _lastUnlockKey) ?? '') ?? 0;
    return DateTime.now().millisecondsSinceEpoch - last >=
        unlockValidity.inMilliseconds;
  }

  Uint8List _hash(String pin, Uint8List salt) =>
      sha256Bytes(concatBytes([salt, pin.codeUnits]));
}
