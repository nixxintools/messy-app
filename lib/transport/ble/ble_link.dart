import 'dart:async';
import 'dart:typed_data';

import '../../domain/codec/frame_codec.dart';
import '../link.dart';

/// A [Link] over a single full-duplex BLE GATT connection.
///
/// BLE payloads are tiny (a few hundred bytes even after MTU negotiation), so
/// each length-prefixed frame is split into fragments on send and reassembled
/// on receive by [FrameReader] — the exact same reassembly the TCP transport
/// uses, so the mesh layer above sees an identical framed byte stream.
///
/// Two concrete subclasses supply the actual write path:
///  - [BleCentralLink]  — we connected out; we `write` to the peer and receive
///    their `notify`s.
///  - [BlePeripheralLink] — a peer connected in; we `notify` them and receive
///    their `write`s.
abstract class BleLinkBase implements Link {
  BleLinkBase(this._peerLabel) {
    _stateController.add(LinkState.up);
  }

  final String _peerLabel;
  final _reader = FrameReader();
  final _framesController = StreamController<Uint8List>.broadcast();
  final _stateController = StreamController<LinkState>.broadcast();
  bool _closed = false;

  @override
  String get peerNodeId => _peerLabel;

  @override
  LinkTransport get transport => LinkTransport.bluetooth;

  @override
  int get costHint => 4; // slower than LAN(1) / Wi-Fi Direct(2)

  @override
  Stream<Uint8List> get frames => _framesController.stream;

  @override
  Stream<LinkState> get state => _stateController.stream;

  /// Feed raw inbound BLE bytes (a write request or a notification payload);
  /// complete frames are emitted on [frames].
  void feedInbound(List<int> bytes) {
    if (_closed) return;
    try {
      for (final frame in _reader.addData(bytes)) {
        _framesController.add(frame);
      }
    } on FormatException {
      close();
    }
  }

  /// Splits a framed message into MTU-sized fragments and writes each.
  @override
  Future<void> sendFrame(Uint8List frame) async {
    if (_closed) throw StateError('Link closed');
    final wire = FrameReader.withLengthPrefix(frame);
    final mtu = await maxPayload();
    final chunk = mtu > 3 ? mtu : 20;
    for (var start = 0; start < wire.length; start += chunk) {
      final end = (start + chunk) > wire.length ? wire.length : start + chunk;
      await writeFragment(Uint8List.sublistView(wire, start, end));
    }
  }

  /// Largest single BLE write/notify payload for this connection.
  Future<int> maxPayload();

  /// Transport-specific single-fragment write.
  Future<void> writeFragment(Uint8List fragment);

  /// Transport-specific teardown (disconnect / forget).
  Future<void> closeTransport();

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _stateController.add(LinkState.down);
    try {
      await closeTransport();
    } on Object {
      // Best-effort; the peer will time out regardless.
    }
    await _framesController.close();
    await _stateController.close();
  }
}
