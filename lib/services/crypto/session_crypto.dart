import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/bytes.dart';
import '../../core/constants.dart';

/// E2E message crypto — docs/SECURITY.md §2.
///
/// 1:1: static-static X25519 ECDH → directional HKDF-SHA256 keys →
/// AES-256-GCM per message with a fresh random 12-byte nonce.
/// Public room: key derived from the room name — obfuscation, not secrecy
/// (docs/SECURITY.md §4).
class SessionCrypto {
  SessionCrypto();

  final _aes = AesGcm.with256bits();
  final _x25519 = X25519();
  final _rng = Random.secure();

  final Map<String, SecretKey> _sendKeys = {};
  final Map<String, SecretKey> _recvKeys = {};

  Uint8List newNonce() =>
      Uint8List.fromList(List<int>.generate(12, (_) => _rng.nextInt(256)));

  Future<SecretKey> _deriveKey(
    SecretKey shared,
    List<int> first,
    List<int> second,
  ) {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: shared,
      nonce: Protocol.hkdfSalt.codeUnits,
      info: concatBytes([first, second]),
    );
  }

  Future<void> ensureSession({
    required SimpleKeyPair myKeyPair,
    required Uint8List myPub,
    required Uint8List theirPub,
  }) async {
    final id = hexEncode(theirPub);
    if (_sendKeys.containsKey(id)) return;
    final shared = await _x25519.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: SimplePublicKey(theirPub, type: KeyPairType.x25519),
    );
    _sendKeys[id] = await _deriveKey(shared, myPub, theirPub);
    _recvKeys[id] = await _deriveKey(shared, theirPub, myPub);
  }

  /// The shared key for the public room, derivable by every Messy install.
  Future<SecretKey> publicRoomKey(String roomName) {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: SecretKey(sha256Bytes(roomName.codeUnits)),
      nonce: Protocol.hkdfSalt.codeUnits,
      info: Protocol.publicRoomInfo.codeUnits,
    );
  }

  Future<SecretBox> sealFor({
    required Uint8List theirPub,
    required List<int> plaintext,
    required Uint8List nonce,
    required List<int> aad,
  }) async {
    final key = _sendKeys[hexEncode(theirPub)];
    if (key == null) throw StateError('No session for peer');
    return _aes.encrypt(plaintext, secretKey: key, nonce: nonce, aad: aad);
  }

  Future<List<int>> openFrom({
    required Uint8List theirPub,
    required List<int> ciphertext,
    required List<int> nonce,
    required List<int> tag,
    required List<int> aad,
  }) async {
    final key = _recvKeys[hexEncode(theirPub)];
    if (key == null) throw StateError('No session for peer');
    return _aes.decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(tag)),
      secretKey: key,
      aad: aad,
    );
  }

  /// Group messages: the 32-byte group key IS the AES-256 key; whoever was
  /// invited holds it.
  Future<SecretBox> sealWithKey({
    required List<int> keyBytes,
    required List<int> plaintext,
    required Uint8List nonce,
    required List<int> aad,
  }) {
    return _aes.encrypt(
      plaintext,
      secretKey: SecretKey(keyBytes),
      nonce: nonce,
      aad: aad,
    );
  }

  Future<List<int>> openWithKey({
    required List<int> keyBytes,
    required List<int> ciphertext,
    required List<int> nonce,
    required List<int> tag,
    required List<int> aad,
  }) {
    return _aes.decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(tag)),
      secretKey: SecretKey(keyBytes),
      aad: aad,
    );
  }

  Future<SecretBox> sealPublic({
    required String roomName,
    required List<int> plaintext,
    required Uint8List nonce,
    required List<int> aad,
  }) async {
    final key = await publicRoomKey(roomName);
    return _aes.encrypt(plaintext, secretKey: key, nonce: nonce, aad: aad);
  }

  Future<List<int>> openPublic({
    required String roomName,
    required List<int> ciphertext,
    required List<int> nonce,
    required List<int> tag,
    required List<int> aad,
  }) async {
    final key = await publicRoomKey(roomName);
    return _aes.decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(tag)),
      secretKey: key,
      aad: aad,
    );
  }
}
