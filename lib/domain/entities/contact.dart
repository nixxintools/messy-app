import 'dart:typed_data';

enum ContactSource { qr, nearby }

/// A known peer. `verified` is true only for in-person QR exchanges.
/// See docs/SECURITY.md §3.
class Contact {
  const Contact({
    required this.nodeId,
    required this.x25519Pub,
    required this.ed25519Pub,
    required this.displayName,
    required this.verified,
    required this.addedVia,
    this.lastSeenAt,
  });

  final String nodeId;
  final Uint8List x25519Pub;
  final Uint8List ed25519Pub;
  final String displayName;
  final bool verified;
  final ContactSource addedVia;
  final DateTime? lastSeenAt;
}
