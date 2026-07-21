import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/mesh/mesh_foreground.dart';
import '../../providers/providers.dart';
import '../home_shell.dart';
import 'blocked_screen.dart';

/// Wireframe screen 7.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _autoWipe;
  bool? _pinEnabled;
  bool? _meshActive;

  Future<void> _load() async {
    final core = await ref.read(coreProvider.future);
    final wipe = await core.wipe.autoWipeEnabled();
    final pin = await ref.read(pinServiceProvider).isEnabled();
    final mesh = await MeshForeground.isRunning;
    if (mounted) {
      setState(() {
        _autoWipe = wipe;
        _pinEnabled = pin;
        _meshActive = mesh;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _togglePin(bool enable) async {
    final pinService = ref.read(pinServiceProvider);
    if (enable) {
      await pinService.setEnabled(true);
      // If no PIN exists yet the gate will demand setup on next launch;
      // set one now so the user isn't surprised later.
      if (!await pinService.hasPin() && mounted) {
        ref.invalidate(appGateProvider);
      }
      setState(() => _pinEnabled = true);
      return;
    }
    // Reducing security requires proving you hold the current PIN.
    final entered = await _promptForPin();
    if (entered == null) return;
    final ok = await pinService.verifyPin(entered);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong PIN — lock stays on.')),
        );
      }
      return;
    }
    await pinService.setEnabled(false);
    if (mounted) setState(() => _pinEnabled = false);
  }

  Future<String?> _promptForPin() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter current PIN'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = ref.watch(coreProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 12), child: MeshStatusChip()),
        ],
      ),
      body: core == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.hub_outlined),
                  title: const Text('Mesh active in background'),
                  subtitle: const Text(
                    'Keeps receiving and relaying with the screen off '
                    '(shows a notification)',
                  ),
                  value: _meshActive ?? true,
                  onChanged: (v) async {
                    if (v) {
                      await MeshForeground.start();
                    } else {
                      await MeshForeground.stop();
                    }
                    setState(() => _meshActive = v);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.pin_outlined),
                  title: const Text('Require PIN'),
                  subtitle: const Text(
                    'On by default — PIN needed to open the app at least '
                    'once a day. Turning it off requires your current PIN.',
                  ),
                  value: _pinEnabled ?? true,
                  onChanged: _togglePin,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.auto_delete_outlined),
                  title: const Text('Auto-wipe every 24 h'),
                  subtitle: const Text(
                    'On by default — erases all messages & media daily; '
                    'contacts survive',
                  ),
                  value: _autoWipe ?? true,
                  onChanged: (v) async {
                    await core.wipe.setAutoWipe(v);
                    setState(() => _autoWipe = v);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Blocked people'),
                  subtitle: const Text('View and unblock muted senders'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BlockedScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Identity'),
                  subtitle: Text(
                    '${core.identity.displayName} · '
                    'node ${core.identity.nodeId}',
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Relay for others'),
                  subtitle: Text(
                    'Always on — this is what makes the mesh work. You carry '
                    'encrypted messages you can\'t read · budget 256 MB',
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Wipe everything now',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Wipe everything?'),
                        content: const Text(
                          'All messages, media, and relayed data on this '
                          'device will be permanently erased. Contacts and '
                          'your identity survive.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Wipe'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await core.wipe.wipeAllNow();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Wiped.')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
    );
  }
}
