import 'dart:convert';
import 'dart:typed_data';

import 'bytes.dart';

/// Built-in public channels, implemented as "well-known groups": the key is
/// derived from a public constant, so every Messy install is a member.
/// Like the Local room, these are explicitly NOT private — anyone running
/// the app can read them (see docs/SECURITY.md §4).
abstract final class WellKnown {
  /// Global media channel: photos/videos broadcast to everyone nearby.
  static final Uint8List mediaRoomKey =
      sha256Bytes(utf8.encode('messy-public-room-v1:media'));

  static final String mediaRoomId = hexEncode(sha256Bytes(mediaRoomKey));

  static const String mediaRoomName = 'Media';
}
