import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../providers/providers.dart';
import '../../widgets/messy_title.dart';

/// View and lift blocks. "Auto" entries came from your contacts' blocklists.
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked =
        ref.watch(blockedProvider).valueOrNull ?? const <BlockedRow>[];
    return Scaffold(
      appBar: AppBar(title: const MessyTitle('Blocked')),
      body: blocked.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No one blocked.\nLong-press a message in Local or a chat '
                  'to block its sender.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              children: [
                for (final b in blocked)
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.block)),
                    title: Text(b.displayName ?? 'node ${b.nodeId.substring(0, 8)}'),
                    subtitle: Text(b.auto
                        ? 'Auto-blocked (your contacts blocked them)'
                        : 'node ${b.nodeId.substring(0, 8)}'),
                    trailing: TextButton(
                      onPressed: () async {
                        final core = await ref.read(coreProvider.future);
                        await core.blocks.unblock(b.nodeId);
                      },
                      child: const Text('Unblock'),
                    ),
                  ),
              ],
            ),
    );
  }
}
