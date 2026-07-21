import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:messy/transport/connectivity_manager.dart';
import 'package:messy/transport/link.dart';

/// A minimal fake link for testing transport selection without real sockets.
class _FakeLink implements Link {
  _FakeLink(this._transport, this._cost);
  final LinkTransport _transport;
  final int _cost;
  @override
  String get peerNodeId => 'fake';
  @override
  LinkTransport get transport => _transport;
  @override
  int get costHint => _cost;
  @override
  Stream<Uint8List> get frames => const Stream.empty();
  @override
  Future<void> sendFrame(Uint8List frame) async {}
  @override
  Stream<LinkState> get state => const Stream.empty();
  @override
  Future<void> close() async {}
}

AuthenticatedLink _auth(LinkTransport t, int cost) => AuthenticatedLink(
      link: _FakeLink(t, cost),
      nodeId: 'peer',
      displayName: 'peer',
      x25519Pub: Uint8List(32),
      ed25519Pub: Uint8List(32),
    );

void main() {
  test('pickBest prefers the lowest-cost (fastest) transport', () {
    final ble = _auth(LinkTransport.bluetooth, 4);
    final lan = _auth(LinkTransport.lan, 1);
    final aware = _auth(LinkTransport.wifiAware, 2);

    // Order shouldn't matter — LAN always wins.
    expect(ConnectivityManager.pickBest([ble, aware, lan]), same(lan));
    expect(ConnectivityManager.pickBest([lan, ble]), same(lan));
    expect(ConnectivityManager.pickBest([ble, aware]), same(aware));
    expect(ConnectivityManager.pickBest([ble]), same(ble));
    expect(ConnectivityManager.pickBest([]), isNull);
  });

  test('failover: removing the best link falls back to the next fastest', () {
    final lan = _auth(LinkTransport.lan, 1);
    final ble = _auth(LinkTransport.bluetooth, 4);
    final links = [lan, ble];

    expect(ConnectivityManager.pickBest(links), same(lan));
    // LAN drops (e.g. left the hotspot) — BLE should now be selected.
    links.remove(lan);
    expect(ConnectivityManager.pickBest(links), same(ble));
  });
}
