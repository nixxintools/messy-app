import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/well_known.dart';
import '../../../data/db/database.dart';
import '../../providers/providers.dart';
import '../chat/chat_screen.dart';
import '../home_shell.dart';
import 'create_group_screen.dart';

/// Groups tab: every group you're in, plus creation.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = (ref.watch(groupsProvider).valueOrNull ?? const <GroupRow>[])
        .where((g) => g.groupId != WellKnown.mediaRoomId)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 12), child: MeshStatusChip()),
        ],
      ),
      body: groups.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No groups yet.\nCreate one and invite your contacts — '
                  'messages are encrypted so only members can read them.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              children: [
                for (final g in groups)
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.groups)),
                    title: Text(g.name),
                    subtitle: const Text('Encrypted group'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(chatId: g.groupId, title: g.name),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
        ),
        child: const Icon(Icons.group_add),
      ),
    );
  }
}
