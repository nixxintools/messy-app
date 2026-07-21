import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'add_contact/add_contact_screen.dart';
import 'chat_list/chat_list_screen.dart';
import 'contacts/contacts_screen.dart';
import 'group/groups_screen.dart';
import 'media/media_gallery_screen.dart';
import 'settings/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final core = ref.watch(coreProvider);
    return core.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Failed to start mesh: $e'))),
      data: (_) => Scaffold(
        body: switch (_tab) {
          0 => const ChatListScreen(),
          1 => const GroupsScreen(),
          2 => const MediaGalleryScreen(),
          3 => const ContactsScreen(),
          _ => const SettingsScreen(),
        },
        floatingActionButton: (_tab == 0 || _tab == 3)
            ? FloatingActionButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddContactScreen(),
                  ),
                ),
                child: const Icon(Icons.person_add),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          height: 52,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Groups',
            ),
            NavigationDestination(
              icon: Icon(Icons.photo_library_outlined),
              selectedIcon: Icon(Icons.photo_library),
              label: 'Media',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Contacts',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// Mesh-status chip shown in app bars — tells the truth about connectivity.
class MeshStatusChip extends ConsumerWidget {
  const MeshStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peers = ref.watch(peerCountProvider).valueOrNull ?? 0;
    final scheme = Theme.of(context).colorScheme;
    // Compact so it fits alongside the app-bar actions; the full wording
    // lives in the tooltip.
    return Tooltip(
      message: peers > 0
          ? 'Mesh active · $peers peer${peers == 1 ? '' : 's'} connected'
          : 'No peers nearby yet',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              peers > 0 ? Icons.hub : Icons.wifi_off,
              size: 18,
              color: peers > 0 ? scheme.primary : scheme.outline,
            ),
            if (peers > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$peers',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: scheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
