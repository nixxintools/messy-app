import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../domain/codec/frame_codec.dart';
import '../link.dart';

/// A [Link] over a TCP socket — used for both LAN and hotspot peers.
class LanLink implements Link {
  LanLink(this._socket, {required this.peerNodeIdValue}) {
    _socket.setOption(SocketOption.tcpNoDelay, true);
    _stateController.add(LinkState.up);
    _sub = _socket.listen(
      (data) {
        try {
          for (final frame in _reader.addData(data)) {
            _framesController.add(frame);
          }
        } on FormatException {
          close();
        }
      },
      onError: (_) => close(),
      onDone: close,
    );
  }

  final Socket _socket;
  final _reader = FrameReader();
  StreamSubscription<Uint8List>? _sub;
  bool _closed = false;

  /// Set after the hello handshake verifies the peer's signature.
  String peerNodeIdValue;

  final _framesController = StreamController<Uint8List>.broadcast();
  final _stateController = StreamController<LinkState>.broadcast();

  @override
  String get peerNodeId => peerNodeIdValue;

  @override
  LinkTransport get transport => LinkTransport.lan;

  @override
  int get costHint => 1;

  @override
  Stream<Uint8List> get frames => _framesController.stream;

  @override
  Stream<LinkState> get state => _stateController.stream;

  @override
  Future<void> sendFrame(Uint8List frame) async {
    if (_closed) throw StateError('Link closed');
    _socket.add(FrameReader.withLengthPrefix(frame));
    await _socket.flush();
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _stateController.add(LinkState.down);
    await _sub?.cancel();
    _socket.destroy();
    await _framesController.close();
    await _stateController.close();
  }
}
