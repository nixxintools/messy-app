import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/radio/radio_service.dart';
import '../../widgets/web_logo.dart';

/// Startup gate: Messy needs Bluetooth + Wi-Fi on to reach nearby phones.
/// Shown before the mesh runs; clears itself once both radios are on.
class RadioGateScreen extends ConsumerStatefulWidget {
  const RadioGateScreen({super.key, required this.onReady});

  final VoidCallback onReady;

  @override
  ConsumerState<RadioGateScreen> createState() => _RadioGateScreenState();
}

class _RadioGateScreenState extends ConsumerState<RadioGateScreen>
    with WidgetsBindingObserver {
  final _radio = RadioService();
  bool _bt = false;
  bool _wifi = false;
  StreamSubscription? _btSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _btSub = _radio.bluetoothChanges.listen((_) => _check());
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _btSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final bt = await _radio.isBluetoothOn();
    final wifi = await _radio.isWifiOn();
    if (!mounted) return;
    setState(() {
      _bt = bt;
      _wifi = wifi;
    });
    if (bt && wifi) widget.onReady();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: WebLogo(size: 64)),
              const SizedBox(height: 20),
              Text(
                'Turn on both radios',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Messy reaches nearby phones over Bluetooth and Wi-Fi. Both '
                'need to be on — even without an internet connection.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              _RadioRow(
                icon: Icons.bluetooth,
                label: 'Bluetooth',
                on: _bt,
                actionLabel: 'Turn on',
                onAction: () => _radio.requestBluetooth(),
              ),
              const SizedBox(height: 12),
              _RadioRow(
                icon: Icons.wifi,
                label: 'Wi-Fi',
                subtitle: 'Just on is enough — no network needed',
                on: _wifi,
                actionLabel: 'Open Wi-Fi',
                onAction: () => _radio.openWifiPanel(),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _check,
                child: const Text("I've turned them on — re-check"),
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: no other network around? One person can turn on their '
                'phone hotspot and the rest join it.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.icon,
    required this.label,
    required this.on,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool on;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: on ? scheme.primary : scheme.outline),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null)
                  Text(subtitle!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (on)
            Icon(Icons.check_circle, color: scheme.primary)
          else
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
