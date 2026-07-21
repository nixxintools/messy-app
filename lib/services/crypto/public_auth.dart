import 'dart:convert';
import 'dart:typed_data';

import '../../core/bytes.dart';

/// Authenticates broadcast posts (public room, Media channel, groups).
///
/// 1:1 messages are already authenticated by ECDH — only the holder of the
/// sender's static key can produce a message that decrypts. But broadcast
/// posts are sealed with a *shared* key (public-room key or group key), so
/// the `senderPub` field alone proves nothing: anyone with the shared key
/// could forge it. This wraps the content with an Ed25519 signature over
/// `messageId ‖ senderPub ‖ timestamp ‖ payloadType ‖ content`, binding the
/// content, the message identity, and the claimed sender key together.
///
/// See docs/SECURITY.md §4.
class SignedPost {
  const SignedPost({required this.content, required this.ed25519Pub});
  final Uint8List content; // the real payload bytes (e.g. {t,n,d} JSON)
  final Uint8List ed25519Pub; // the key that signed it
}

abstract final class PublicAuth {
  /// The exact bytes a broadcast post signs / verifies.
  static Uint8List signedBytes({
    required Uint8List messageId,
    required Uint8List senderPub,
    required int timestampMs,
    required int payloadType,
    required List<int> content,
  }) {
    final head = Uint8List(16 + 32 + 8 + 1);
    head.setRange(0, 16, messageId);
    head.setRange(16, 48, senderPub);
    ByteData.view(head.buffer).setUint64(48, timestampMs);
    head[56] = payloadType;
    return concatBytes([head, content]);
  }

  /// Wraps signed content into the bytes that get sealed with the shared key.
  static Uint8List wrap({
    required List<int> content,
    required Uint8List ed25519Pub,
    required Uint8List signature,
  }) {
    return utf8.encode(jsonEncode({
      'c': b64u(content),
      'e': b64u(ed25519Pub),
      's': b64u(signature),
    }));
  }

  /// Parses the sealed plaintext back into (content, ed25519Pub, signature).
  /// Returns null on any malformation — caller drops the post.
  static ({SignedPost post, Uint8List signature})? parse(List<int> sealed) {
    try {
      final map = jsonDecode(utf8.decode(sealed)) as Map<String, Object?>;
      final content = b64uDecode(map['c'] as String);
      final ed = b64uDecode(map['e'] as String);
      final sig = b64uDecode(map['s'] as String);
      if (ed.length != 32) return null;
      return (post: SignedPost(content: content, ed25519Pub: ed), signature: sig);
    } on Object {
      return null;
    }
  }
}
