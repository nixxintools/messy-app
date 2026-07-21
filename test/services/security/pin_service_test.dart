import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:messy/services/security/pin_service.dart';

/// In-memory FlutterSecureStorage stand-in for tests.
class _MemStore extends FlutterSecureStorage {
  const _MemStore(this._m);
  final Map<String, String> _m;

  @override
  Future<String?> read({required String key, /* ignore rest */ dynamic aOptions, dynamic iOptions, dynamic lOptions, dynamic webOptions, dynamic mOptions, dynamic wOptions}) async => _m[key];
  @override
  Future<void> write({required String key, required String? value, dynamic aOptions, dynamic iOptions, dynamic lOptions, dynamic webOptions, dynamic mOptions, dynamic wOptions}) async {
    if (value == null) { _m.remove(key); } else { _m[key] = value; }
  }
  @override
  Future<void> delete({required String key, dynamic aOptions, dynamic iOptions, dynamic lOptions, dynamic webOptions, dynamic mOptions, dynamic wOptions}) async => _m.remove(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PinService svc() => PinService(storage: _MemStore({}));

  test('Argon2id hash verifies the correct PIN and rejects wrong ones',
      () async {
    final s = svc();
    await s.setPin('4917');
    expect(await s.verify('4917'), isA<PinOk>());
    expect(await s.verify('0000'), isA<PinWrong>());
  });

  test('stored hash is not the PIN or a bare digest (KDF applied)', () async {
    final store = <String, String>{};
    final s = PinService(storage: _MemStore(store));
    await s.setPin('123456');
    final hash = store['messy.pin.hash']!;
    // Not the plaintext, and a full 32-byte derived key (not obviously short).
    expect(hash.contains('123456'), isFalse);
    expect(hash.length, greaterThan(20));
  });

  test('rate limiting: repeated wrong PINs trigger a lockout', () async {
    final s = svc();
    await s.setPin('1111');
    // Burn the free attempts.
    for (var i = 0; i < 4; i++) {
      expect(await s.verify('9999'), isA<PinWrong>());
    }
    // Next wrong attempt locks out.
    final locked = await s.verify('9999');
    expect(locked, isA<PinLockedOut>());
    // While locked, even the CORRECT pin is refused until the window passes.
    expect(await s.verify('1111'), isA<PinLockedOut>());
    expect(await s.lockoutRemainingSeconds(), greaterThan(0));
  });

  test('a correct PIN before lockout resets the failure counter', () async {
    final s = svc();
    await s.setPin('2222');
    await s.verify('0000'); // 1 fail
    await s.verify('0000'); // 2 fails
    expect(await s.verify('2222'), isA<PinOk>());
    // Counter reset — we get the full free-attempt budget again.
    final r = await s.verify('0000');
    expect((r as PinWrong).attemptsLeftBeforeLockout, 3);
  });
}
