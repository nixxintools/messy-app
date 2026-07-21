import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../link.dart';

/// Peer discovery via UDP broadcast beacons on the local subnet.
///
/// Works on home Wi-Fi and on phone hotspots (a hotspot IS a LAN). Beacons
/// are sent both to the limited broadcast address (255.255.255.255) and to
/// each interface's subnet-directed broadcast (e.g. 192.168.43.255): many
/// Android hotspot APs drop limited broadcasts between the host and its
/// clients but pass directed ones. Identity is proven by the signed hello
/// handshake, never by the beacon.
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

  /// Local IPv4 addresses (used by ConnectivityManager for gateway probing).
  static Future<List<InternetAddress>> localAddresses() async {
    final out = <InternetAddress>[];
    for (final iface in await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    )) {
      out.addAll(iface.addresses.where((a) => !a.isLoopback));
    }
    return out;
  }

  /// Directed /24 broadcast for an interface address (192.168.43.7 →
  /// 192.168.43.255). Android gives no prefix length; /24 covers virtually
  /// every hotspot and home network.
  static InternetAddress directedBroadcast(InternetAddress addr) {
    final parts = addr.address.split('.');
    return InternetAddress('${parts[0]}.${parts[1]}.${parts[2]}.255');
  }

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

  Future<void> _sendBeacon() async {
    final id = _nodeId;
    final socket = _socket;
    if (id == null || socket == null) return;
    final beacon = utf8.encode(jsonEncode({
      'app': 'messy',
      'v': 1,
      'id': id,
      'n': _displayName,
      'p': tcpPort,
    }));

    final targets = <InternetAddress>{InternetAddress('255.255.255.255')};
    try {
      for (final addr in await localAddresses()) {
        targets.add(directedBroadcast(addr));
      }
    } on Object {
      // Interface enumeration can fail transiently; limited broadcast
      // remains as the fallback target.
    }
    for (final target in targets) {
      try {
        socket.send(beacon, target, discoveryPort);
      } on SocketException {
        // No route on this interface right now — next tick retries.
      }
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
