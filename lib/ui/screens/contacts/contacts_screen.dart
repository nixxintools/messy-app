import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../services/contacts/contact_service.dart';
import '../../providers/providers.dart';
import '../home_shell.dart';
import 'contact_detail_screen.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts =
        ref.watch(contactsProvider).valueOrNull ?? const <ContactRow>[];
    final pending = ref.watch(pendingRequestsProvider).valueOrNull ??
        const <PendingRequest>[];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 12), child: MeshStatusChip()),
        ],
      ),
      body: ListView(
        children: [
          for (final req in pending)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.tertiaryContainer,
                child: const Icon(Icons.person_add),
              ),
              title: Text(req.displayName),
              subtitle: const Text('wants to connect'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check_circle, color: scheme.primary),
                    onPressed: () async {
                      final core = await ref.read(coreProvider.future);
                      await core.contacts.accept(req);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: () async {
                      final core = await ref.read(coreProvider.future);
                      core.contacts.decline(req);
                    },
                  ),
                ],
              ),
            ),
          for (final c in contacts)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Row(
                children: [
                  Flexible(
                    child:
                        Text(c.displayName, overflow: TextOverflow.ellipsis),
                  ),
                  if (c.verified) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.verified, size: 14, color: scheme.primary),
                  ],
                ],
              ),
              subtitle: Text('node ${c.nodeId.substring(0, 8)} · '
                  '${c.verified ? "verified" : "unverified"}'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContactDetailScreen(nodeId: c.nodeId),
                ),
              ),
            ),
          if (contacts.isEmpty && pending.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No contacts yet. Use the + button to add one by QR '
                'or from nearby devices.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
