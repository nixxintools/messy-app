import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../link.dart';

/// Peer discovery via a UDP broadcast beacon on the local subnet.
///
/// Chosen over mDNS/NsdManager for v1: pure Dart, no plugin, and it works
/// identically on home Wi-Fi and on phone hotspots (a hotspot IS a LAN —
/// everyone connected to it shares a subnet). Beacons carry nodeId, display
/// name, and the TCP port to dial; identity is proven later by the signed
/// hello handshake, never by the beacon.
class UdpDiscovery implements Discovery {
  UdpDiscovery({required this.tcpPort});

  static const discoveryPort = 47488;
  static const beaconInterval = Duration(seconds: 4);
  static const peerExpiry = Duration(seconds: 15);

  final int tcpPort;

  RawDatagramSocket? _socket;
  Timer? _beaconTimer;
  Timer? _expiryTimer;
  String? _nodeId;
  String? _displayName;

  final _peersController = StreamController<PeerAdvert>.broadcast();
  final _changedController = StreamController<void>.broadcast();
  final Map<String, DateTime> _lastSeen = {};
  final Map<String, PeerAdvert> _live = {};

  @override
  Stream<PeerAdvert> get peers => _peersController.stream;

  /// Fires on any change to the visible-peer set, including expiry.
  Stream<void> get changed => _changedController.stream;

  List<PeerAdvert> get livePeers => _live.values.toList();

  @override
  Future<void> startAdvertising({
    required String nodeId,
    required String displayName,
  }) async {
    _nodeId = nodeId;
    _displayName = displayName;
    await _ensureSocket();
    _beaconTimer ??= Timer.periodic(beaconInterval, (_) => _sendBeacon());
    _sendBeacon();
  }

  @override
  Future<void> startBrowsing() async {
    await _ensureSocket();
    _expiryTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      final cutoff = DateTime.now().subtract(peerExpiry);
      var removedAny = false;
      _lastSeen.removeWhere((id, seen) {
        final gone = seen.isBefore(cutoff);
        if (gone) {
          _live.remove(id);
          removedAny = true;
        }
        return gone;
      });
      if (removedAny) _changedController.add(null);
    });
  }

  Future<void> _ensureSocket() async {
    if (_socket != null) return;
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
    );
    socket.broadcastEnabled = true;
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = socket.receive();
      if (dg == null) return;
      _onBeacon(dg);
    });
    _socket = socket;
  }

  void _sendBeacon() {
    final id = _nodeId;
    if (id == null || _socket == null) return;
    final beacon = utf8.encode(jsonEncode({
      'app': 'messy',
      'v': 1,
      'id': id,
      'n': _displayName,
      'p': tcpPort,
    }));
    try {
      _socket!.send(beacon, InternetAddress('255.255.255.255'), discoveryPort);
    } on SocketException {
      // No route (e.g. Wi-Fi just dropped) — the next tick retries.
    }
  }

  void _onBeacon(Datagram dg) {
    Map<String, Object?> body;
    try {
      body = jsonDecode(utf8.decode(dg.data)) as Map<String, Object?>;
    } on FormatException {
      return;
    }
    if (body['app'] != 'messy') return;
    final id = body['id'];
    final port = body['p'];
    if (id is! String || port is! int || id == _nodeId) return;

    final advert = PeerAdvert(
      nodeId: id,
      displayName: (body['n'] as String?) ?? 'unknown',
      transport: LinkTransport.lan,
      endpointHint: '${dg.address.address}:$port',
    );
    final isNew = !_live.containsKey(id);
    _lastSeen[id] = DateTime.now();
    _live[id] = advert;
    if (isNew) {
      _peersController.add(advert);
      _changedController.add(null);
    }
  }

  @override
  Future<void> stop() async {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _socket?.close();
    _socket = null;
    _live.clear();
    _lastSeen.clear();
  }
}
