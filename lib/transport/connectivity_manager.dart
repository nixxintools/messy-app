import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../core/bytes.dart';
import '../core/constants.dart';
import '../domain/codec/frame_codec.dart';
import '../services/crypto/identity_service.dart';
import 'lan/lan_link.dart';
import 'lan/udp_discovery.dart';
import 'link.dart';

/// A link whose peer has proven its identity via the signed hello.
///
/// Frames that arrive before the router attaches its handler are buffered,
/// never dropped — a peer starts syncing immediately after its handshake
/// completes, which can be before our link-up event has been delivered.
class AuthenticatedLink {
  AuthenticatedLink({
    required this.link,
    required this.nodeId,
    required this.displayName,
    required this.x25519Pub,
    required this.ed25519Pub,
  });

  final Link link;
  final String nodeId;
  final String displayName;
  final Uint8List x25519Pub;
  final Uint8List ed25519Pub;

  final List<Uint8List> _buffer = [];
  void Function(Uint8List frame)? _handler;

  void setFrameHandler(void Function(Uint8List frame) handler) {
    _handler = handler;
    final pending = List<Uint8List>.from(_buffer);
    _buffer.clear();
    pending.forEach(handler);
  }

  void pushFrame(Uint8List frame) {
    final h = _handler;
    if (h != null) {
      h(frame);
    } else {
      _buffer.add(frame);
    }
  }
}

/// Owns discovery + live links — docs/ARCHITECTURE.md §3.
///
/// v1 ships the LAN transport, which covers both requirements 1 and 5's
/// offline case: a phone hotspot is a LAN, so peers joined to the same
/// hotspot connect exactly like peers on home Wi-Fi. Wi-Fi Direct
/// (programmatic group formation) and internet WebRTC slot in later as
/// additional [Link] implementations behind the same interface.
class ConnectivityManager {
  ConnectivityManager({required this.identity, required this.identityService});

  static const helloTimeout = Duration(seconds: 10);
  static const _helloMaxSkew = Duration(minutes: 5);

  final LocalIdentity identity;
  final IdentityService identityService;

  ServerSocket? _server;
  UdpDiscovery? _discovery;
  Timer? _dialTimer;

  final Map<String, AuthenticatedLink> _links = {};
  final Set<String> _dialing = {};
  final _linkUpController = StreamController<AuthenticatedLink>.broadcast();
  final _linkDownController = StreamController<String>.broadcast();
  final _peersChangedController = StreamController<void>.broadcast();

  Stream<AuthenticatedLink> get onLinkUp => _linkUpController.stream;
  Stream<String> get onLinkDown => _linkDownController.stream;
  Stream<void> get onPeersChanged => _peersChangedController.stream;

  List<AuthenticatedLink> get liveLinks => _links.values.toList();
  List<PeerAdvert> get visiblePeers => _discovery?.livePeers ?? const [];

  AuthenticatedLink? linkFor(String nodeId) => _links[nodeId];

  /// Well-known ports tried in order so peers can be probed directly even
  /// before a discovery beacon arrives (hotspot fallback).
  static const knownPorts = [47490, 47491, 47492, 47493];

  Future<void> start() async {
    ServerSocket? server;
    for (final port in knownPorts) {
      try {
        server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
        break;
      } on SocketException {
        continue; // port taken (another app) — try the next
      }
    }
    server ??= await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    server.listen(_onInbound);

    final discovery = UdpDiscovery(tcpPort: server.port);
    _discovery = discovery;
    await discovery.startBrowsing();
    await discovery.startAdvertising(
      nodeId: identity.nodeId,
      displayName: identity.displayName,
    );
    discovery.changed.listen((_) => _peersChangedController.add(null));

    // Keep trying to hold a link to every visible peer.
    _dialTimer = Timer.periodic(const Duration(seconds: 5), (_) => _dialAll());
    _dialAll();
  }

  void _dialAll() {
    for (final peer in visiblePeers) {
      if (_links.containsKey(peer.nodeId)) continue;
      if (_dialing.contains(peer.nodeId)) continue;
      // Deterministic tie-break so two peers don't cross-dial: the smaller
      // nodeId dials.
      if (identity.nodeId.compareTo(peer.nodeId) > 0) continue;
      _dial(peer);
    }
    // Hotspot fallback: if beacons aren't getting through (some APs filter
    // broadcasts entirely), probe the gateway — on a phone hotspot the
    // host is always x.y.z.1 — on the well-known ports.
    if (_links.isEmpty && visiblePeers.isEmpty) {
      _probeGateways();
    }
  }

  bool _probing = false;

  Future<void> _probeGateways() async {
    if (_probing) return;
    _probing = true;
    try {
      for (final addr in await UdpDiscovery.localAddresses()) {
        final parts = addr.address.split('.');
        if (parts[3] == '1') continue; // we ARE the hotspot host
        final gateway = '${parts[0]}.${parts[1]}.${parts[2]}.1';
        for (final port in knownPorts) {
          if (_links.isNotEmpty) return;
          try {
            final socket = await Socket.connect(
              gateway,
              port,
              timeout: const Duration(seconds: 2),
            );
            await ingestLink(LanLink(socket, peerNodeIdValue: '?'));
            return; // one probe link at a time; beacons handle the rest
          } on Object {
            continue;
          }
        }
      }
    } on Object {
      // Interface enumeration failed — retried next dial tick.
    } finally {
      _probing = false;
    }
  }

  Future<void> _dial(PeerAdvert peer) async {
    final hint = peer.endpointHint;
    if (hint == null) return;
    _dialing.add(peer.nodeId);
    try {
      final parts = hint.split(':');
      final socket = await Socket.connect(
        parts[0],
        int.parse(parts[1]),
        timeout: const Duration(seconds: 5),
      );
      await ingestLink(LanLink(socket, peerNodeIdValue: peer.nodeId));
    } on Object {
      // Peer gone or unreachable; the next dial tick retries.
    } finally {
      _dialing.remove(peer.nodeId);
    }
  }

  void _onInbound(Socket socket) {
    ingestLink(LanLink(socket, peerNodeIdValue: '?'));
  }

  Map<String, Object?> _helloBody(Uint8List sig, int ts) => {
        'id': identity.nodeId,
        'n': identity.displayName,
        'x': b64u(identity.x25519Pub),
        'e': b64u(identity.ed25519Pub),
        'ts': ts,
        'sig': b64u(sig),
      };

  static Uint8List helloSignedPayload(Uint8List x25519Pub, int ts) =>
      concatBytes([x25519Pub, '$ts'.codeUnits]);

  /// Runs the signed hello handshake over ANY transport's [Link] (LAN TCP or
  /// BLE) and registers the peer. Both sides send a signed hello; the link is
  /// live once the peer's is verified. Signature covers (x25519Pub ||
  /// timestamp) with a ±5 min replay window.
  ///
  /// One persistent frame subscription lives for the link's lifetime: the
  /// first hello completes the handshake, everything after it is routed to
  /// the [AuthenticatedLink] (buffered until the router attaches).
  Future<void> ingestLink(Link link) async {
    final helloCompleter = Completer<Map<String, Object?>>();
    AuthenticatedLink? auth;
    link.frames.listen((frame) {
      if (!helloCompleter.isCompleted) {
        try {
          if (FrameCodec.frameTypeOf(frame) == Protocol.frameHello) {
            helloCompleter.complete(FrameCodec.decodeJson(frame));
            return;
          }
        } on FormatException {
          // Garbage before hello: ignore; the timeout will reap the link.
        }
        return;
      }
      auth?.pushFrame(frame);
    });

    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final sig = await identityService.sign(
        identity,
        helloSignedPayload(identity.x25519Pub, ts),
      );
      await link.sendFrame(
        FrameCodec.encodeJson(Protocol.frameHello, _helloBody(sig, ts)),
      );
      final hello = await helloCompleter.future.timeout(helloTimeout);

      final xPub = b64uDecode(hello['x'] as String);
      final ePub = b64uDecode(hello['e'] as String);
      final theirTs = hello['ts'] as int;
      final theirSig = b64uDecode(hello['sig'] as String);
      final claimedId = hello['id'] as String;

      final derivedId = hexEncode(sha256Bytes(xPub).sublist(0, 8));
      final skew = (DateTime.now().millisecondsSinceEpoch - theirTs).abs();
      final sigOk = await IdentityService.verify(
        message: helloSignedPayload(xPub, theirTs),
        signature: theirSig,
        ed25519Pub: ePub,
      );
      if (derivedId != claimedId ||
          !sigOk ||
          skew > _helloMaxSkew.inMilliseconds ||
          claimedId == identity.nodeId) {
        await link.close();
        return;
      }

      // One link per peer: a fresh handshake wins over a possibly-stale
      // existing link (TCP can take minutes to notice a dead peer).
      final existing = _links.remove(claimedId);
      if (existing != null) {
        await existing.link.close();
      }

      final authed = AuthenticatedLink(
        link: link,
        nodeId: claimedId,
        displayName: (hello['n'] as String?) ?? 'unknown',
        x25519Pub: xPub,
        ed25519Pub: ePub,
      );
      auth = authed;
      _links[claimedId] = authed;
      link.state.listen((s) {
        if (s == LinkState.down && identical(_links[claimedId], authed)) {
          _links.remove(claimedId);
          _linkDownController.add(claimedId);
          _peersChangedController.add(null);
        }
      });
      _linkUpController.add(authed);
      _peersChangedController.add(null);
    } on Object {
      await link.close();
    }
  }

  Future<void> stop() async {
    _dialTimer?.cancel();
    await _discovery?.stop();
    await _server?.close();
    for (final l in _links.values.toList()) {
      await l.link.close();
    }
    _links.clear();
  }
}
