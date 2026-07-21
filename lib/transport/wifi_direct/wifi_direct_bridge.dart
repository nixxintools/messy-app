import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/codec/frame_codec.dart';
import '../connectivity_manager.dart';
import '../link.dart';

/// Dart side of the native Wi-Fi Direct transport (WifiDirectTransport.kt).
///
/// Broadest-support no-shared-network path — works on budget handsets that
/// lack Wi-Fi Aware. The native layer forms/joins a Wi-Fi Direct group and
/// yields a TCP socket; here each connection becomes a [WifiDirectLink] fed to
/// [ConnectivityManager.ingestLink], running the identical handshake + crypto.
///
/// Fail-safe: unsupported/off ⇒ no-op; Wi-Fi + BLE + Wi-Fi Aware carry the mesh.
class WifiDirectBridge {
  WifiDirectBridge({required this.connectivity});

  static const _method = MethodChannel('messy/wifi_direct');
  static const _events = EventChannel('messy/wifi_direct/events');

  final ConnectivityManager connectivity;
  final Map<int, WifiDirectLink> _links = {};
  StreamSubscription? _sub;

  Future<bool> start() async {
    try {
      final supported =
          await _method.invokeMethod<bool>('isSupported') ?? false;
      if (!supported) return false;
      _sub = _events.receiveBroadcastStream().listen(_onEvent, onError: (_) {});
      final ok = await _method.invokeMethod<bool>('start') ?? false;
      if (!ok) {
        await _sub?.cancel();
        _sub = null;
      }
      return ok;
    } on Object {
      return false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    for (final l in _links.values.toList()) {
      await l.close();
    }
    _links.clear();
    try {
      await _method.invokeMethod('stop');
    } on Object {/* ignore */}
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    final id = event['id'];
    if (id is! int) return;
    switch (event['type']) {
      case 'connected':
        final link = WifiDirectLink(
          connId: id,
          peerNodeId: 'wifidirect:${event['peer'] ?? id}',
        );
        _links[id] = link;
        connectivity.ingestLink(link);
      case 'data':
        final data = event['data'];
        if (data is Uint8List) _links[id]?.feedInbound(data);
      case 'closed':
        _links.remove(id)?.close();
    }
  }
}

/// A [Link] over one native Wi-Fi Direct TCP socket.
class WifiDirectLink implements Link {
  WifiDirectLink({required this.connId, required this.peerNodeId}) {
    _stateController.add(LinkState.up);
  }

  final int connId;

  @override
  final String peerNodeId;

  final _reader = FrameReader();
  final _framesController = StreamController<Uint8List>.broadcast();
  final _stateController = StreamController<LinkState>.broadcast();
  bool _closed = false;

  @override
  LinkTransport get transport => LinkTransport.wifiDirect;

  @override
  int get costHint => 3; // between Wi-Fi Aware(2) and Bluetooth(4)

  @override
  Stream<Uint8List> get frames => _framesController.stream;

  @override
  Stream<LinkState> get state => _stateController.stream;

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

  @override
  Future<void> sendFrame(Uint8List frame) async {
    if (_closed) throw StateError('Link closed');
    final wire = FrameReader.withLengthPrefix(frame);
    final ok = await WifiDirectBridge._method
        .invokeMethod<bool>('send', {'id': connId, 'data': wire});
    if (ok != true) throw StateError('Wi-Fi Direct send failed');
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _stateController.add(LinkState.down);
    await _framesController.close();
    await _stateController.close();
  }
}
