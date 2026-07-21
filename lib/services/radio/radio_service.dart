import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/services.dart';

/// Checks and helps enable the two radios Messy needs: Bluetooth and Wi-Fi.
///
/// Rationale (see the discussion in the README/ARCHITECTURE): Wi-Fi ON — even
/// unconnected — powers Wi-Fi Aware, Wi-Fi Direct, and joining any hotspot/AP;
/// Bluetooth ON gives the universal BLE baseline. Hotspot is NOT required at
/// startup (it can't be universal — one host, everyone else joins with Wi-Fi
/// on) so it's offered situationally, not gated.
///
/// On Android 10+ an app can't toggle radios directly, so we can only report
/// state and open the system panels for the user to flip them on.
class RadioService {
  static const _channel = MethodChannel('messy/radio');
  final _bt = CentralManager();

  Future<bool> isBluetoothOn() async {
    try {
      var st = _bt.state;
      // On a cold start the plugin may report unknown/unauthorized until it's
      // authorized — grant + re-read so a phone with BT already on isn't
      // wrongly shown as "off".
      if (st == BluetoothLowEnergyState.unknown ||
          st == BluetoothLowEnergyState.unauthorized) {
        await _bt.authorize();
        // Give the platform a moment to publish the resolved state.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        st = _bt.state;
      }
      return st == BluetoothLowEnergyState.poweredOn;
    } on Object {
      return false;
    }
  }

  Future<bool> isWifiOn() async {
    try {
      return await _channel.invokeMethod<bool>('isWifiEnabled') ?? false;
    } on Object {
      return true; // if we can't tell, don't block the user
    }
  }

  /// Prompts the OS Bluetooth-enable flow (a system dialog on most devices).
  Future<void> requestBluetooth() async {
    try {
      await _bt.authorize();
      await _bt.showAppSettings();
    } on Object {/* ignore */}
  }

  Future<void> openWifiPanel() async {
    try {
      await _channel.invokeMethod('openWifiPanel');
    } on Object {/* ignore */}
  }

  Future<void> openHotspotSettings() async {
    try {
      await _channel.invokeMethod('openHotspotSettings');
    } on Object {/* ignore */}
  }

  /// Watches for changes so the gate can re-check without polling.
  Stream<BluetoothLowEnergyState> get bluetoothChanges =>
      _bt.stateChanged.map((e) => e.state);
}
