import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/share/apk_share_service.dart';
import '../../widgets/web_logo.dart';
import '../../widgets/messy_title.dart';

/// Pass Messy on to the people around you — including with no internet.
class ShareAppScreen extends ConsumerStatefulWidget {
  const ShareAppScreen({super.key});

  @override
  ConsumerState<ShareAppScreen> createState() => _ShareAppScreenState();
}

class _ShareAppScreenState extends ConsumerState<ShareAppScreen> {
  final _svc = ApkShareService();
  String? _url;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _svc.stopServing();
    super.dispose();
  }

  Future<void> _shareViaApps() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final apk = await _svc.prepareApk();
    if (!mounted) return;
    setState(() => _busy = false);
    if (apk == null) {
      setState(() => _error = "Couldn't prepare the app file.");
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(apk.path)],
        text: 'Messy — offline mesh messenger. Install this APK to chat '
            'with no internet.',
      ),
    );
  }

  Future<void> _toggleHotspotServing() async {
    if (_url != null) {
      await _svc.stopServing();
      if (mounted) setState(() => _url = null);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final url = await _svc.startServing();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _url = url;
      if (url == null) {
        _error = 'Could not start sharing. Make sure Wi-Fi or your hotspot '
            'is on.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const MessyTitle('Share Messy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: WebLogo(size: 56)),
          const SizedBox(height: 14),
          Text(
            'Give Messy to people near you',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'The mesh gets better with every person on it.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          Card(
            child: ListTile(
              leading: const Icon(Icons.wifi_tethering),
              title: const Text('Share over hotspot / Wi-Fi'),
              subtitle: const Text(
                'No internet needed — they scan the code or open the link '
                'while on the same hotspot',
              ),
              trailing: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: _url != null,
                      onChanged: (_) => _toggleHotspotServing(),
                    ),
              onTap: _busy ? null : _toggleHotspotServing,
            ),
          ),
          if (_url != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: QrImageView(data: _url!, size: 190),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    _url!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'They must be on your hotspot (or the same Wi-Fi). '
                    'Keep this screen open while they download.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.ios_share),
              title: const Text('Send the app file'),
              subtitle: const Text(
                'WhatsApp, Bluetooth, Quick Share, Files…',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy ? null : _shareViaApps,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Tip: some chat apps block .apk files. If WhatsApp refuses, use '
            'the hotspot link above or Bluetooth/Quick Share.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
