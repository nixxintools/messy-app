import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

Uint8List concatBytes(List<List<int>> parts) {
  final total = parts.fold<int>(0, (n, p) => n + p.length);
  final out = Uint8List(total);
  var offset = 0;
  for (final p in parts) {
    out.setRange(offset, offset + p.length, p);
    offset += p.length;
  }
  return out;
}

String hexEncode(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List hexDecode(String hex) {
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

Uint8List sha256Bytes(List<int> data) =>
    Uint8List.fromList(crypto.sha256.convert(data).bytes);

String b64u(List<int> bytes) => base64UrlEncode(bytes).replaceAll('=', '');

Uint8List b64uDecode(String s) {
  final padded = s.padRight(s.length + (4 - s.length % 4) % 4, '=');
  return base64Url.decode(padded);
}

bool bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool isAllZero(List<int> bytes) => bytes.every((b) => b == 0);
