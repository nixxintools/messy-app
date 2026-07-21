import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../providers/providers.dart';

/// Name the group, pick members from contacts, send E2E invites.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selected = {};
  bool _creating = false;

  Future<void> _create(List<ContactRow> contacts) async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selected.isEmpty || _creating) return;
    setState(() => _creating = true);
    final core = await ref.read(coreProvider.future);
    final members =
        contacts.where((c) => _selected.contains(c.nodeId)).toList();
    await core.chat.createGroup(name, members);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final contacts =
        ref.watch(contactsProvider).valueOrNull ?? const <ContactRow>[];
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Members (${_selected.length} selected)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          Expanded(
            child: contacts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No contacts yet — add people first, then create '
                        'the group.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      for (final c in contacts)
                        CheckboxListTile(
                          value: _selected.contains(c.nodeId),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selected.add(c.nodeId);
                            } else {
                              _selected.remove(c.nodeId);
                            }
                          }),
                          title: Text(c.displayName),
                          subtitle:
                              Text('node ${c.nodeId.substring(0, 8)}'),
                          secondary:
                              const CircleAvatar(child: Icon(Icons.person)),
                        ),
                    ],
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _creating ? null : () => _create(contacts),
                  child: Text(
                    _creating
                        ? 'Creating…'
                        : 'Create group & send invites',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
