import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/providers.dart';

/// Wireframe screen 5: My QR / Scan / Nearby tabs.
class AddContactScreen extends ConsumerWidget {
  const AddContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add contact'),
          bottom: const TabBar(tabs: [
            Tab(text: 'My QR'),
            Tab(text: 'Scan'),
            Tab(text: 'Nearby'),
          ]),
        ),
        body: const TabBarView(
          children: [_MyQrTab(), _ScanTab(), _NearbyTab()],
        ),
      ),
    );
  }
}

class _MyQrTab extends ConsumerWidget {
  const _MyQrTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final core = ref.watch(coreProvider).valueOrNull;
    if (core == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: core.contacts.myQrPayload(),
              size: 220,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            core.identity.displayName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'node ${core.identity.nodeId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Scanning each other in person marks the contact verified — '
              'the strongest trust level.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanTab extends ConsumerStatefulWidget {
  const _ScanTab();

  @override
  ConsumerState<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends ConsumerState<_ScanTab> {
  bool _handled = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final core = await ref.read(coreProvider.future);
    final ok = await core.contacts.addFromQr(raw);
    if (!ok || !mounted) return;
    _handled = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact added — verified ✓')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(onDetect: _onDetect);
  }
}

class _NearbyTab extends ConsumerWidget {
  const _NearbyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final core = ref.watch(coreProvider).valueOrNull;
    // Rebuild when peers change.
    ref.watch(peerCountProvider);
    if (core == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final peers = core.connectivity.visiblePeers;
    if (peers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No one nearby yet.\nNearby means: same Wi-Fi network or '
            'connected to the same hotspot.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      children: [
        for (final peer in peers)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(peer.displayName),
            subtitle: Text('node ${peer.nodeId.substring(0, 8)} · nearby'),
            trailing: FilledButton.tonal(
              onPressed: () async {
                final sent = await core.contacts.sendRequest(peer.nodeId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      sent
                          ? 'Request sent — waiting for them to accept'
                          : 'Not connected yet — try again in a moment',
                    ),
                  ),
                );
              },
              child: const Text('Request'),
            ),
          ),
      ],
    );
  }
}
