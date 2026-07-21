import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messy/core/bytes.dart';
import 'package:messy/data/db/database.dart';
import 'package:messy/services/crypto/prekey_service.dart';
import 'package:messy/services/crypto/session_crypto.dart';

Future<(SimpleKeyPair, Uint8List)> _staticPair(int seed) async {
  final kp = await X25519()
      .newKeyPairFromSeed(Uint8List.fromList(List.filled(32, seed)));
  return (kp, Uint8List.fromList((await kp.extractPublicKey()).bytes));
}

void main() {
  late MessyDatabase db;
  late PrekeyService prekeys;

  setUp(() {
    db = MessyDatabase.forTesting(NativeDatabase.memory());
    prekeys = PrekeyService(db: db);
  });

  tearDown(() => db.close());

  test('pool fills, issues per peer, and never double-issues', () async {
    await prekeys.ensurePool();
    final toAlice = await prekeys.issueTo('alice', 8);
    final toBob = await prekeys.issueTo('bob', 8);
    expect(toAlice, hasLength(8));
    expect(toBob, hasLength(8));
    final aliceIds = toAlice.map((e) => e['i']).toSet();
    final bobIds = toBob.map((e) => e['i']).toSet();
    expect(aliceIds.intersection(bobIds), isEmpty);
  });

  test('full OTK seal/open round-trip burns the key', () async {
    final crypto = SessionCrypto();
    final (senderStaticKp, senderStaticPub) = await _staticPair(7);

    // "Recipient" issues an OTK; "sender" stores and consumes it.
    await prekeys.ensurePool();
    final bundle = await prekeys.issueTo('sender', 1);
    final senderSide = PrekeyService(
      db: MessyDatabase.forTesting(NativeDatabase.memory()),
    );
    await senderSide.storePeerOtks('recipient', bundle);
    final otk = await senderSide.takePeerOtk('recipient');
    expect(otk, isNotNull);
    // Consumed on the sender side: a second take finds nothing.
    expect(await senderSide.takePeerOtk('recipient'), isNull);

    final (ephKp, ephPub) = await crypto.newEphemeral();
    final nonce = crypto.newNonce();
    const aad = [1, 2, 3];
    final box = await crypto.sealOtk(
      ephKeyPair: ephKp,
      ephPub: ephPub,
      myStaticKeyPair: senderStaticKp,
      otkPub: otk!.pub,
      plaintext: 'burn after reading'.codeUnits,
      nonce: nonce,
      aad: aad,
    );

    // Recipient looks up the secret by id, decrypts, deletes.
    final own = await prekeys.getOwnSecret(otk.keyId);
    expect(own, isNotNull);
    final plain = await crypto.openOtk(
      otkPriv: own!.priv,
      otkPub: own.pub,
      ephPub: ephPub,
      senderStaticPub: senderStaticPub,
      ciphertext: box.cipherText,
      nonce: nonce,
      tag: box.mac.bytes,
      aad: aad,
    );
    expect(String.fromCharCodes(plain), 'burn after reading');

    await prekeys.deleteOwn(otk.keyId);
    // The forward-secrecy property: the secret is gone.
    expect(await prekeys.getOwnSecret(otk.keyId), isNull);
  });

  test('stored peer prekeys reject dishonest key ids', () async {
    await prekeys.storePeerOtks('mallory', [
      {'i': 'deadbeefdeadbeef', 'k': b64u(List.filled(32, 9))},
    ]);
    expect(await prekeys.takePeerOtk('mallory'), isNull);
  });
}
