import 'dart:typed_data';

/// Which pipe a [Link] runs over. Cost order: lan < wifiDirect < internet.
enum LinkTransport { lan, wifiDirect, internet }

enum LinkState { connecting, up, down }

/// A framed, bidirectional byte stream to one peer.
///
/// Every transport (LAN TCP, Wi-Fi Direct TCP, WebRTC data channel) reduces
/// to this interface: one codec, one router, three pipes.
/// See docs/ARCHITECTURE.md §3.
abstract interface class Link {
  /// Remote node id — known once the hello handshake completes.
  String get peerNodeId;

  LinkTransport get transport;

  /// lan=1, wifiDirect=2, internet=3; ConnectivityManager picks the cheapest
  /// live link per peer.
  int get costHint;

  /// Incoming frames (length prefix already stripped).
  Stream<Uint8List> get frames;

  Future<void> sendFrame(Uint8List frame);

  Stream<LinkState> get state;

  Future<void> close();
}

/// Advertises the local identity and surfaces nearby peers for one transport.
abstract interface class Discovery {
  Stream<PeerAdvert> get peers;

  Future<void> startAdvertising({
    required String nodeId,
    required String displayName,
  });

  Future<void> startBrowsing();

  Future<void> stop();
}

/// A peer seen by a [Discovery] implementation.
class PeerAdvert {
  const PeerAdvert({
    required this.nodeId,
    required this.displayName,
    required this.transport,
    this.endpointHint,
  });

  final String nodeId;
  final String displayName;
  final LinkTransport transport;

  /// Transport-specific dial info (e.g. "192.168.1.7:47474").
  final String? endpointHint;
}
