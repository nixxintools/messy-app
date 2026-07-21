import 'dart:typed_data';

import '../../core/constants.dart';
import '../entities/envelope.dart';

/// Binary envelope encode/decode — docs/ARCHITECTURE.md §4.
///
/// v2 layout (version byte 0x02; encoding always emits v2):
///   0  version(1) 1 frameType(1)
///   2  messageId(16) 18 senderPub(32) 50 recipientPub(32)
///   82 ttl(1) 83 hopCount(1) 84 timestampMs(8) 92 payloadType(1)
///   93 chunkIndex(2) 95 chunkTotal(2) 97 nonce(12)
///   109 fsMode(1) 110 ephPub(32) 142 otkKeyId(8) 150 ciphertext(..)
///
/// v1 (version byte 0x01) had no fs fields (header = 109 bytes); decoding
/// still accepts it so old frames relay/parse, though cross-version
/// decryption fails by design (AAD differs).
///
/// [aadOf] returns the immutable header fed to AES-GCM as associated data —
/// everything except ttl/hopCount, which relays legitimately mutate. The fs
/// fields ARE in the AAD: a relay swapping the ephemeral key or key id
/// breaks authentication.
abstract final class EnvelopeCodec {
  static const headerLengthV1 = 109;
  static const headerLength = 150;
  static const _ttlOffset = 82;

  static Uint8List encode(Envelope e) {
    assert(e.messageId.length == 16);
    assert(e.senderPub.length == 32);
    assert(e.recipientPub.length == 32);
    assert(e.nonce.length == 12);
    assert(e.ephPub.length == 32);
    assert(e.otkKeyId.length == 8);
    final out = Uint8List(headerLength + e.ciphertext.length);
    final bd = ByteData.view(out.buffer);
    out[0] = Protocol.envelopeVersion;
    out[1] = Protocol.frameEnvelope;
    out.setRange(2, 18, e.messageId);
    out.setRange(18, 50, e.senderPub);
    out.setRange(50, 82, e.recipientPub);
    out[82] = e.ttl;
    out[83] = e.hopCount;
    bd.setUint64(84, e.timestampMs);
    out[92] = e.payloadType;
    bd.setUint16(93, e.chunkIndex);
    bd.setUint16(95, e.chunkTotal);
    out.setRange(97, 109, e.nonce);
    out[109] = e.fsMode;
    out.setRange(110, 142, e.ephPub);
    out.setRange(142, 150, e.otkKeyId);
    out.setRange(headerLength, out.length, e.ciphertext);
    return out;
  }

  static Envelope decode(Uint8List frame) {
    if (frame.length < 2 || frame[1] != Protocol.frameEnvelope) {
      throw const FormatException('Not an envelope frame');
    }
    final version = frame[0];
    final header = switch (version) {
      0x01 => headerLengthV1,
      Protocol.envelopeVersion => headerLength,
      _ => throw const FormatException('Unknown envelope version'),
    };
    if (frame.length < header) {
      throw const FormatException('Envelope frame too short');
    }
    final bd = ByteData.sublistView(frame);
    return Envelope(
      messageId: Uint8List.sublistView(frame, 2, 18),
      senderPub: Uint8List.sublistView(frame, 18, 50),
      recipientPub: Uint8List.sublistView(frame, 50, 82),
      ttl: frame[82],
      hopCount: frame[83],
      timestampMs: bd.getUint64(84),
      payloadType: frame[92],
      chunkIndex: bd.getUint16(93),
      chunkTotal: bd.getUint16(95),
      nonce: Uint8List.sublistView(frame, 97, 109),
      fsMode: version == 0x01 ? Envelope.fsStatic : frame[109],
      ephPub: version == 0x01
          ? null
          : Uint8List.sublistView(frame, 110, 142),
      otkKeyId: version == 0x01
          ? null
          : Uint8List.sublistView(frame, 142, 150),
      ciphertext: Uint8List.sublistView(frame, header),
    );
  }

  /// Associated data for AES-GCM: the immutable v2 header with ttl/hopCount
  /// zeroed so relay mutation of them doesn't break authentication, while
  /// tampering with anything else (including the fs fields) does.
  static Uint8List aadOf(Envelope e) {
    return encode(
      Envelope(
        messageId: e.messageId,
        senderPub: e.senderPub,
        recipientPub: e.recipientPub,
        ttl: 0,
        hopCount: 0,
        timestampMs: e.timestampMs,
        payloadType: e.payloadType,
        chunkIndex: e.chunkIndex,
        chunkTotal: e.chunkTotal,
        nonce: e.nonce,
        fsMode: e.fsMode,
        ephPub: e.ephPub,
        otkKeyId: e.otkKeyId,
        ciphertext: Uint8List(0),
      ),
    );
  }

  /// Re-encode after a relay mutated ttl/hopCount (cheap: fixed offsets,
  /// identical in v1 and v2).
  static Uint8List reencodeMutable(Uint8List frame, int ttl, int hopCount) {
    final copy = Uint8List.fromList(frame);
    copy[_ttlOffset] = ttl;
    copy[_ttlOffset + 1] = hopCount;
    return copy;
  }
}
