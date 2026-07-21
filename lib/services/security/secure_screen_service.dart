import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// FLAG_SECURE control: when on, Android blocks screenshots and screen
/// recording of the app and hides its content in the recent-apps thumbnail.
/// User-controlled (Settings toggle); persisted; applied at startup.
class SecureScreenService {
  SecureScreenService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _channel = MethodChannel('messy/window');
  static const _key = 'messy.flagSecure';

  final FlutterSecureStorage _storage;

  Future<bool> isEnabled() async =>
      await _storage.read(key: _key) == '1';

  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _key, value: enabled ? '1' : '0');
    await _apply(enabled);
  }

  /// Applies the stored preference — call once at startup.
  Future<void> applyStored() async => _apply(await isEnabled());

  Future<void> _apply(bool enabled) async {
    try {
      await _channel.invokeMethod('setSecure', {'enabled': enabled});
    } on Object {/* ignore on non-Android */}
  }
}
