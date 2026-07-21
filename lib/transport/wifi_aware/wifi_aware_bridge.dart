import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/codec/frame_codec.dart';
import '../connectivity_manager.dart';
import '../link.dart';

/// Dart side of the native Wi-Fi Aware transport (see
/// android/.../WifiAwareTransport.kt).
///
/// The native layer performs the NAN discovery + data-path dance and yields a
/// plain TCP socket per peer, then streams that socket's bytes over the
/// platform channels. Here we wrap each connection as a [WifiAwareLink] and
/// hand it to [ConnectivityManager.ingestLink] — from there it runs the exact
/// same signed handshake, crypto, and routing as a Wi-Fi socket.
///
/// Entirely fail-safe: if Wi-Fi Aware is unsupported or errors, this no-ops
/// and the Wi-Fi/BLE transports carry the mesh.
class WifiAwareBridge {
  WifiAwareBridge({required this.connectivity});

  static const _method = MethodChannel('messy/wifi_aware');
  static const _events = EventChannel('messy/wifi_aware/events');

  final ConnectivityManager connectivity;
  final Map<int, WifiAwareLink> _links = {};
  StreamSubscription? _sub;

  Future<bool> start(String nodeId) async {
    try {
      final supported =
          await _method.invokeMethod<bool>('isSupported') ?? false;
      if (!supported) return false;
      _sub = _events.receiveBroadcastStream().listen(
            _onEvent,
            onError: (_) {},
          );
      final ok = await _method
          .invokeMethod<bool>('start', {'nodeId': nodeId}) ??
          false;
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
    final type = event['type'];
    final id = event['id'];
    if (id is! int) return;
    switch (type) {
      case 'connected':
        final link = WifiAwareLink(
          connId: id,
          peerNodeId: 'wifiaware:${event['peer'] ?? id}',
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

/// A [Link] over one native Wi-Fi Aware TCP socket. Frames are length-prefixed
/// and reassembled by [FrameReader] exactly like the LAN transport; the native
/// socket handles arbitrary byte boundaries, so no MTU fragmentation is needed.
class WifiAwareLink implements Link {
  WifiAwareLink({required this.connId, required this.peerNodeId}) {
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
  LinkTransport get transport => LinkTransport.wifiAware;

  @override
  int get costHint => 2; // fast; between LAN(1) and Wi-Fi Direct/BLE

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
    final ok = await WifiAwareBridge._method
        .invokeMethod<bool>('send', {'id': connId, 'data': wire});
    if (ok != true) throw StateError('Wi-Fi Aware send failed');
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
