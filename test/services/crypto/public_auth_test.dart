import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messy/core/bytes.dart';
import 'package:messy/services/crypto/identity_service.dart';
import 'package:messy/services/crypto/public_auth.dart';

Future<(SimpleKeyPair, Uint8List)> _edPair(int seed) async {
  final kp = await Ed25519()
      .newKeyPairFromSeed(Uint8List.fromList(List.filled(32, seed)));
  return (kp, Uint8List.fromList((await kp.extractPublicKey()).bytes));
}

void main() {
  final messageId = Uint8List.fromList(List.generate(16, (i) => i));
  final senderPub = Uint8List.fromList(List.generate(32, (i) => 100 + i));
  const ts = 1752969600000;
  const payloadType = 5;
  final content = 'anyone near the north gate?'.codeUnits;

  test('a validly signed public post verifies', () async {
    final (kp, edPub) = await _edPair(7);
    final signed = PublicAuth.signedBytes(
      messageId: messageId,
      senderPub: senderPub,
      timestampMs: ts,
      payloadType: payloadType,
      content: content,
    );
    final sig = await Ed25519().sign(signed, keyPair: kp);
    final wrapped = PublicAuth.wrap(
      content: content,
      ed25519Pub: edPub,
      signature: Uint8List.fromList(sig.bytes),
    );

    final parsed = PublicAuth.parse(wrapped)!;
    final ok = await IdentityService.verify(
      message: PublicAuth.signedBytes(
        messageId: messageId,
        senderPub: senderPub,
        timestampMs: ts,
        payloadType: payloadType,
        content: parsed.post.content,
      ),
      signature: parsed.signature,
      ed25519Pub: parsed.post.ed25519Pub,
    );
    expect(ok, isTrue);
    expect(parsed.post.content, content);
  });

  test('a forged post (content changed after signing) is rejected', () async {
    final (kp, edPub) = await _edPair(7);
    final sig = await Ed25519().sign(
      PublicAuth.signedBytes(
        messageId: messageId,
        senderPub: senderPub,
        timestampMs: ts,
        payloadType: payloadType,
        content: content,
      ),
      keyPair: kp,
    );
    // Attacker keeps the signature but swaps the content.
    final tampered = PublicAuth.wrap(
      content: 'follow this scam link'.codeUnits,
      ed25519Pub: edPub,
      signature: Uint8List.fromList(sig.bytes),
    );
    final parsed = PublicAuth.parse(tampered)!;
    final ok = await IdentityService.verify(
      message: PublicAuth.signedBytes(
        messageId: messageId,
        senderPub: senderPub,
        timestampMs: ts,
        payloadType: payloadType,
        content: parsed.post.content,
      ),
      signature: parsed.signature,
      ed25519Pub: parsed.post.ed25519Pub,
    );
    expect(ok, isFalse);
  });

  test('impersonation: signing with a different key fails against victim key',
      () async {
    final (attackerKp, _) = await _edPair(9);
    final (_, victimEdPub) = await _edPair(1);
    final sig = await Ed25519().sign(
      PublicAuth.signedBytes(
        messageId: messageId,
        senderPub: senderPub,
        timestampMs: ts,
        payloadType: payloadType,
        content: content,
      ),
      keyPair: attackerKp,
    );
    // Attacker claims the victim's ed25519 key but signed with their own.
    final ok = await IdentityService.verify(
      message: PublicAuth.signedBytes(
        messageId: messageId,
        senderPub: senderPub,
        timestampMs: ts,
        payloadType: payloadType,
        content: content,
      ),
      signature: Uint8List.fromList(sig.bytes),
      ed25519Pub: victimEdPub,
    );
    expect(ok, isFalse);
  });

  test('parse rejects malformed wrappers', () {
    expect(PublicAuth.parse('not json'.codeUnits), isNull);
    expect(PublicAuth.parse(b64uDecode('AAAA')), isNull);
  });
}
