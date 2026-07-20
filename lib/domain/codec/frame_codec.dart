import 'dart:convert';
import 'dart:typed_data';

import '../../core/constants.dart';

/// Non-envelope frames (hello, contact request/accept, sync) carry a JSON
/// body after the 2-byte header — they are link-local control messages, not
/// store-and-forward payloads, so compactness matters less than flexibility.
abstract final class FrameCodec {
  static Uint8List encodeJson(int frameType, Map<String, Object?> body) {
    final json = utf8.encode(jsonEncode(body));
    final out = Uint8List(2 + json.length);
    out[0] = Protocol.version;
    out[1] = frameType;
    out.setRange(2, out.length, json);
    return out;
  }

  static int frameTypeOf(Uint8List frame) {
    if (frame.length < 2) throw const FormatException('Frame too short');
    return frame[1];
  }

  static Map<String, Object?> decodeJson(Uint8List frame) {
    return jsonDecode(utf8.decode(frame.sublist(2))) as Map<String, Object?>;
  }
}

/// Splits a TCP byte stream into `uint32 length | frame` messages.
class FrameReader {
  final _buffer = BytesBuilder(copy: true);

  /// Feed raw socket bytes; returns any complete frames.
  List<Uint8List> addData(List<int> data) {
    _buffer.add(data);
    final frames = <Uint8List>[];
    var bytes = _buffer.toBytes();
    var offset = 0;
    while (bytes.length - offset >= 4) {
      final len = ByteData.sublistView(bytes, offset, offset + 4).getUint32(0);
      if (len > 64 * 1024 * 1024) {
        throw const FormatException('Frame too large');
      }
      if (bytes.length - offset - 4 < len) break;
      frames.add(Uint8List.sublistView(bytes, offset + 4, offset + 4 + len));
      offset += 4 + len;
    }
    if (offset > 0) {
      final rest = Uint8List.sublistView(bytes, offset);
      _buffer.clear();
      _buffer.add(rest);
    }
    return frames;
  }

  static Uint8List withLengthPrefix(Uint8List frame) {
    final out = Uint8List(4 + frame.length);
    ByteData.view(out.buffer).setUint32(0, frame.length);
    out.setRange(4, out.length, frame);
    return out;
  }
}
