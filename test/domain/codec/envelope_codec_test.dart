import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:messy/core/constants.dart';
import 'package:messy/domain/codec/envelope_codec.dart';
import 'package:messy/domain/codec/frame_codec.dart';
import 'package:messy/domain/entities/envelope.dart';

Envelope _sample({int ttl = 8}) => Envelope(
      messageId: Uint8List.fromList(List.generate(16, (i) => i)),
      senderPub: Uint8List.fromList(List.generate(32, (i) => 100 + i)),
      recipientPub: Uint8List.fromList(List.generate(32, (i) => 200 - i)),
      ttl: ttl,
      hopCount: 2,
      timestampMs: 1752969600000,
      payloadType: Protocol.payloadText,
      chunkIndex: 3,
      chunkTotal: 7,
      nonce: Uint8List.fromList(List.generate(12, (i) => 50 + i)),
      ciphertext: Uint8List.fromList(List.generate(40, (i) => i * 3 % 256)),
    );

void main() {
  test('envelope round-trips through encode/decode', () {
    final env = _sample();
    final decoded = EnvelopeCodec.decode(EnvelopeCodec.encode(env));
    expect(decoded.messageId, env.messageId);
    expect(decoded.senderPub, env.senderPub);
    expect(decoded.recipientPub, env.recipientPub);
    expect(decoded.ttl, env.ttl);
    expect(decoded.hopCount, env.hopCount);
    expect(decoded.timestampMs, env.timestampMs);
    expect(decoded.payloadType, env.payloadType);
    expect(decoded.chunkIndex, env.chunkIndex);
    expect(decoded.chunkTotal, env.chunkTotal);
    expect(decoded.nonce, env.nonce);
    expect(decoded.ciphertext, env.ciphertext);
  });

  test('AAD is stable across ttl/hop mutation (relays cannot break auth)',
      () {
    final aad1 = EnvelopeCodec.aadOf(_sample(ttl: 8));
    final mutated = EnvelopeCodec.decode(
      EnvelopeCodec.reencodeMutable(EnvelopeCodec.encode(_sample()), 3, 5),
    );
    expect(mutated.ttl, 3);
    expect(mutated.hopCount, 5);
    expect(EnvelopeCodec.aadOf(mutated), aad1);
  });

  test('all-zero recipient means public broadcast', () {
    final env = _sample();
    expect(env.isPublic, isFalse);
    final public = Envelope(
      messageId: env.messageId,
      senderPub: env.senderPub,
      recipientPub: Uint8List(32),
      ttl: 5,
      hopCount: 0,
      timestampMs: env.timestampMs,
      payloadType: Protocol.payloadPublicText,
      chunkIndex: 0,
      chunkTotal: 0,
      nonce: env.nonce,
      ciphertext: env.ciphertext,
    );
    expect(public.isPublic, isTrue);
  });

  test('frame reader reassembles split and coalesced frames', () {
    final a = Uint8List.fromList([1, 2, 3]);
    final b = Uint8List.fromList(List.generate(100, (i) => i));
    final stream = <int>[
      ...FrameReader.withLengthPrefix(a),
      ...FrameReader.withLengthPrefix(b),
    ];
    final reader = FrameReader();
    final out = <Uint8List>[];
    // Feed one byte at a time — worst-case TCP fragmentation.
    for (final byte in stream) {
      out.addAll(reader.addData([byte]));
    }
    expect(out, hasLength(2));
    expect(out[0], a);
    expect(out[1], b);
  });
}
