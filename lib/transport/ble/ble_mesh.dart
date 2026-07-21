import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../../core/bytes.dart';
import '../../services/crypto/identity_service.dart';
import '../connectivity_manager.dart';
import 'ble_link.dart';

/// True infrastructure-free multi-hop mesh over Bluetooth LE.
///
/// Every node runs BOTH roles at once — a peripheral (advertises + hosts a
/// GATT server so neighbours can connect in) and a central (scans + connects
/// out). A single BLE connection is full-duplex: the central writes to the
/// peripheral's characteristic, the peripheral notifies back. So one
/// connection per neighbour is a complete [Link], and because a phone can hold
/// several BLE connections at once, it genuinely relays between neighbours in
/// real time — chains A↔B↔C↔D form by proximity with no shared network.
///
/// Everything above the transport (handshake, crypto, routing, store-and-
/// forward) is unchanged: BLE links are handed to [ConnectivityManager.
/// ingestLink] exactly like TCP links.
///
/// NOTE: This is entirely isolated and fail-safe — every entry point is
/// guarded so a Bluetooth problem can never disturb the Wi-Fi/hotspot mesh.
class BleMeshTransport {
  BleMeshTransport({required this.identity, required this.connectivity});

  // Fixed Messy service + characteristic UUIDs (128-bit, app-specific).
  static final serviceUuid =
      UUID.fromString('9a5d1b00-1c2d-4e3f-8a90-abcdef012345');
  static final charUuid =
      UUID.fromString('9a5d1b01-1c2d-4e3f-8a90-abcdef012345');
  static const _mfrId = 0x4d53; // "MS"

  final LocalIdentity identity;
  final ConnectivityManager connectivity;

  final CentralManager _central = CentralManager();
  final PeripheralManager _peripheral = PeripheralManager();

  GATTCharacteristic? _serverChar;
  bool _running = false;

  // Live links keyed by the transport's own address (not yet the nodeId —
  // that's learned during the handshake).
  final Map<String, BleCentralLink> _centralLinks = {};
  final Map<String, BlePeripheralLink> _peripheralLinks = {};
  final Set<String> _connecting = {};

  /// Starts both roles. Returns false (without throwing) if BLE is
  /// unavailable or unauthorized — the caller simply continues on Wi-Fi.
  Future<bool> start() async {
    if (_running) return true;
    try {
      if (_central.state == BluetoothLowEnergyState.unauthorized) {
        await _central.authorize();
      }
      if (_peripheral.state == BluetoothLowEnergyState.unauthorized) {
        await _peripheral.authorize();
      }
      _wireCentral();
      _wirePeripheral();
      await _startPeripheral();
      await _startCentral();
      _running = true;
      return true;
    } on Object {
      return false; // BLE off / denied / unsupported — Wi-Fi still works
    }
  }

  Future<void> stop() async {
    _running = false;
    try {
      await _central.stopDiscovery();
    } on Object {/* ignore */}
    try {
      await _peripheral.stopAdvertising();
    } on Object {/* ignore */}
    for (final l in [..._centralLinks.values, ..._peripheralLinks.values]) {
      await l.close();
    }
    _centralLinks.clear();
    _peripheralLinks.clear();
  }

  // ------------------------------------------------------------- peripheral

  Future<void> _startPeripheral() async {
    await _peripheral.removeAllServices();
    final characteristic = GATTCharacteristic.mutable(
      uuid: charUuid,
      properties: [
        GATTCharacteristicProperty.write,
        GATTCharacteristicProperty.writeWithoutResponse,
        GATTCharacteristicProperty.notify,
      ],
      permissions: [
        GATTCharacteristicPermission.read,
        GATTCharacteristicPermission.write,
      ],
      descriptors: [],
    );
    _serverChar = characteristic;
    await _peripheral.addService(GATTService(
      uuid: serviceUuid,
      isPrimary: true,
      includedServices: [],
      characteristics: [characteristic],
    ));
    // Advertise the service (so central scan-filters match) plus our nodeId
    // in manufacturer data for the connect tie-break.
    await _peripheral.startAdvertising(Advertisement(
      name: 'msy',
      serviceUUIDs: [serviceUuid],
      manufacturerSpecificData: [
        ManufacturerSpecificData(
          id: _mfrId,
          data: Uint8List.fromList(hexDecode(identity.nodeId)),
        ),
      ],
    ));
  }

  void _wirePeripheral() {
    // A neighbour subscribed to our notify characteristic → we can now send to
    // them: create the inbound link and run the handshake.
    _peripheral.characteristicNotifyStateChanged.listen((e) async {
      if (e.characteristic.uuid != charUuid) return;
      final key = e.central.uuid.toString();
      if (e.state) {
        if (_peripheralLinks.containsKey(key)) return;
        final link = BlePeripheralLink(
          peerLabel: 'ble:$key',
          central: e.central,
          manager: _peripheral,
          characteristic: _serverChar!,
        );
        _peripheralLinks[key] = link;
        try {
          await connectivity.ingestLink(link);
        } on Object {
          await link.close();
          _peripheralLinks.remove(key);
        }
      } else {
        await _peripheralLinks.remove(key)?.close();
      }
    });
    // Inbound bytes from a neighbour's writes.
    _peripheral.characteristicWriteRequested.listen((e) async {
      if (e.characteristic.uuid != charUuid) return;
      try {
        await _peripheral.respondWriteRequest(e.request);
      } on Object {/* ignore */}
      _peripheralLinks[e.central.uuid.toString()]?.feedInbound(e.request.value);
    });
  }

  // --------------------------------------------------------------- central

  Future<void> _startCentral() async {
    await _central.startDiscovery(serviceUUIDs: [serviceUuid]);
  }

  void _wireCentral() {
    _central.discovered.listen((e) => _onDiscovered(e));
    _central.connectionStateChanged.listen((e) async {
      if (e.state == ConnectionState.disconnected) {
        final key = e.peripheral.uuid.toString();
        await _centralLinks.remove(key)?.close();
        _connecting.remove(key);
      }
    });
    _central.characteristicNotified.listen((e) {
      if (e.characteristic.uuid != charUuid) return;
      _centralLinks[e.peripheral.uuid.toString()]?.feedInbound(e.value);
    });
  }

  Future<void> _onDiscovered(DiscoveredEventArgs e) async {
    final key = e.peripheral.uuid.toString();
    if (_centralLinks.containsKey(key) || _connecting.contains(key)) return;

    // Read the peer's advertised nodeId (if present) for the tie-break: the
    // lexicographically-smaller nodeId is the one that dials, so a pair never
    // forms two connections. If the hint is missing, connect anyway — the
    // handshake's one-link-per-peer rule still dedupes.
    String? peerNode;
    for (final m in e.advertisement.manufacturerSpecificData) {
      if (m.id == _mfrId && m.data.length >= 8) {
        peerNode = hexEncode(m.data.sublist(0, 8));
      }
    }
    if (peerNode != null && identity.nodeId.compareTo(peerNode) > 0) return;

    _connecting.add(key);
    try {
      await _central.connect(e.peripheral);
      final services = await _central.discoverGATT(e.peripheral);
      final svc = services.where((s) => s.uuid == serviceUuid).firstOrNull;
      final ch = svc?.characteristics
          .where((c) => c.uuid == charUuid)
          .firstOrNull;
      if (ch == null) {
        await _central.disconnect(e.peripheral);
        return;
      }
      await _central.setCharacteristicNotifyState(
        e.peripheral,
        ch,
        state: true,
      );
      final link = BleCentralLink(
        peerLabel: 'ble:$key',
        peripheral: e.peripheral,
        manager: _central,
        characteristic: ch,
      );
      _centralLinks[key] = link;
      await connectivity.ingestLink(link);
    } on Object {
      _centralLinks.remove(key);
      try {
        await _central.disconnect(e.peripheral);
      } on Object {/* ignore */}
    } finally {
      _connecting.remove(key);
    }
  }
}

/// We connected out: write to the peer, receive their notifications.
class BleCentralLink extends BleLinkBase {
  BleCentralLink({
    required String peerLabel,
    required this.peripheral,
    required this.manager,
    required this.characteristic,
  }) : super(peerLabel);

  final Peripheral peripheral;
  final CentralManager manager;
  final GATTCharacteristic characteristic;

  @override
  Future<int> maxPayload() => manager.getMaximumWriteLength(
        peripheral,
        type: GATTCharacteristicWriteType.withResponse,
      );

  @override
  Future<void> writeFragment(Uint8List fragment) => manager.writeCharacteristic(
        peripheral,
        characteristic,
        value: fragment,
        type: GATTCharacteristicWriteType.withResponse,
      );

  @override
  Future<void> closeTransport() => manager.disconnect(peripheral);
}

/// A peer connected in: notify them, receive their writes.
class BlePeripheralLink extends BleLinkBase {
  BlePeripheralLink({
    required String peerLabel,
    required this.central,
    required this.manager,
    required this.characteristic,
  }) : super(peerLabel);

  final Central central;
  final PeripheralManager manager;
  final GATTCharacteristic characteristic;

  @override
  Future<int> maxPayload() => manager.getMaximumNotifyLength(central);

  @override
  Future<void> writeFragment(Uint8List fragment) => manager.notifyCharacteristic(
        central,
        characteristic,
        value: fragment,
      );

  @override
  Future<void> closeTransport() async {
    // A peripheral can't force-disconnect a central; the connection drops when
    // the central leaves or times out. Nothing to do.
  }
}
