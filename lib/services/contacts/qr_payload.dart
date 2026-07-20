import 'dart:typed_data';

import '../../core/bytes.dart';

/// QR contact payload: `messy://contact?v=1&x=<x25519>&e=<ed25519>&n=<name>`
/// Scanned in person → verified contact. docs/SECURITY.md §3.
class QrContact {
  const QrContact({
    required this.x25519Pub,
    required this.ed25519Pub,
    required this.displayName,
  });

  final Uint8List x25519Pub;
  final Uint8List ed25519Pub;
  final String displayName;

  String get nodeId => hexEncode(sha256Bytes(x25519Pub).sublist(0, 8));

  String encode() {
    return Uri(
      scheme: 'messy',
      host: 'contact',
      queryParameters: {
        'v': '1',
        'x': b64u(x25519Pub),
        'e': b64u(ed25519Pub),
        'n': displayName,
      },
    ).toString();
  }

  static QrContact? tryDecode(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'messy' || uri.host != 'contact') {
      return null;
    }
    final x = uri.queryParameters['x'];
    final e = uri.queryParameters['e'];
    if (x == null || e == null) return null;
    final xPub = b64uDecode(x);
    final ePub = b64uDecode(e);
    if (xPub.length != 32 || ePub.length != 32) return null;
    return QrContact(
      x25519Pub: xPub,
      ed25519Pub: ePub,
      displayName: uri.queryParameters['n'] ?? 'unknown',
    );
  }
}
