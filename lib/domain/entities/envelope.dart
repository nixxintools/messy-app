import 'dart:typed_data';

import '../../core/bytes.dart';

/// The store-and-forward unit — docs/ARCHITECTURE.md §4.
/// Relays see this header + ciphertext; only the recipient can decrypt.
class Envelope {
  Envelope({
    required this.messageId, // 16 bytes, UUIDv7
    required this.senderPub, // 32 bytes X25519
    required this.recipientPub, // 32 bytes; all-zeros = public room
    required this.ttl,
    required this.hopCount,
    required this.timestampMs,
    required this.payloadType,
    required this.chunkIndex,
    required this.chunkTotal,
    required this.nonce, // 12 bytes
    required this.ciphertext, // includes 16-byte GCM tag
  });

  final Uint8List messageId;
  final Uint8List senderPub;
  final Uint8List recipientPub;
  int ttl; // mutable: relays decrement
  int hopCount; // mutable: relays increment
  final int timestampMs;
  final int payloadType;
  final int chunkIndex;
  final int chunkTotal;
  final Uint8List nonce;
  final Uint8List ciphertext;

  bool get isPublic => isAllZero(recipientPub);

  String get messageIdHex => hexEncode(messageId);

  /// Dedupe key: messageId for whole messages, (messageId, chunkIndex) for
  /// media chunks.
  String get dedupeKey => '$messageIdHex:$chunkIndex';
}
