import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messy/services/crypto/fingerprint.dart';
import 'package:messy/services/crypto/session_crypto.dart';

Future<(SimpleKeyPair, Uint8List)> _newPair(int seedByte) async {
  final kp = await X25519()
      .newKeyPairFromSeed(Uint8List.fromList(List.filled(32, seedByte)));
  final pub = Uint8List.fromList((await kp.extractPublicKey()).bytes);
  return (kp, pub);
}

void main() {
  test('alice and bob derive matching directional keys end-to-end', () async {
    final (aliceKp, alicePub) = await _newPair(1);
    final (bobKp, bobPub) = await _newPair(2);

    final alice = SessionCrypto();
    final bob = SessionCrypto();
    await alice.ensureSession(
        myKeyPair: aliceKp, myPub: alicePub, theirPub: bobPub);
    await bob.ensureSession(myKeyPair: bobKp, myPub: bobPub, theirPub: alicePub);

    final nonce = alice.newNonce();
    const aad = [9, 9, 9];
    final box = await alice.sealFor(
      theirPub: bobPub,
      plaintext: utf8.encode('hello over the mesh'),
      nonce: nonce,
      aad: aad,
    );
    final plain = await bob.openFrom(
      theirPub: alicePub,
      ciphertext: box.cipherText,
      nonce: nonce,
      tag: box.mac.bytes,
      aad: aad,
    );
    expect(utf8.decode(plain), 'hello over the mesh');
  });

  test('tampered AAD fails authentication', () async {
    final (aliceKp, alicePub) = await _newPair(1);
    final (bobKp, bobPub) = await _newPair(2);
    final alice = SessionCrypto();
    final bob = SessionCrypto();
    await alice.ensureSession(
        myKeyPair: aliceKp, myPub: alicePub, theirPub: bobPub);
    await bob.ensureSession(myKeyPair: bobKp, myPub: bobPub, theirPub: alicePub);

    final nonce = alice.newNonce();
    final box = await alice.sealFor(
      theirPub: bobPub,
      plaintext: utf8.encode('secret'),
      nonce: nonce,
      aad: [1, 2, 3],
    );
    expect(
      () => bob.openFrom(
        theirPub: alicePub,
        ciphertext: box.cipherText,
        nonce: nonce,
        tag: box.mac.bytes,
        aad: [1, 2, 4], // recipient metadata was tampered with in transit
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('public room key is derivable by anyone and round-trips', () async {
    final a = SessionCrypto();
    final b = SessionCrypto();
    final nonce = a.newNonce();
    final box = await a.sealPublic(
      roomName: 'local',
      plaintext: utf8.encode('anyone near the north gate?'),
      nonce: nonce,
      aad: const [],
    );
    final plain = await b.openPublic(
      roomName: 'local',
      ciphertext: box.cipherText,
      nonce: nonce,
      tag: box.mac.bytes,
      aad: const [],
    );
    expect(utf8.decode(plain), 'anyone near the north gate?');
  });

  test('fingerprint phrase is symmetric and 6 words', () {
    final pubA = List.generate(32, (i) => i);
    final pubB = List.generate(32, (i) => 255 - i);
    final p1 = fingerprintPhrase(pubA, pubB);
    final p2 = fingerprintPhrase(pubB, pubA);
    expect(p1, p2);
    expect(p1.split(' '), hasLength(6));
  });
}
