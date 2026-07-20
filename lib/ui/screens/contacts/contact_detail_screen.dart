import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/crypto/fingerprint.dart';
import '../../providers/providers.dart';

/// Wireframe screen 6: trust status, fingerprint phrase, disappearing timer.
class ContactDetailScreen extends ConsumerWidget {
  const ContactDetailScreen({super.key, required this.nodeId});

  final String nodeId;

  static const _timerOptions = {
    null: 'Off',
    3600: '1 hour',
    86400: '24 hours',
    604800: '7 days',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final core = ref.watch(coreProvider).valueOrNull;
    final contacts = ref.watch(contactsProvider).valueOrNull ?? const [];
    final chats = ref.watch(chatsProvider).valueOrNull ?? const [];
    final contact = contacts.where((c) => c.nodeId == nodeId).firstOrNull;
    final chat = chats.where((c) => c.chatId == nodeId).firstOrNull;
    final scheme = Theme.of(context).colorScheme;

    if (core == null || contact == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final phrase =
        fingerprintPhrase(core.identity.x25519Pub, contact.x25519Pub);

    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
          const SizedBox(height: 12),
          Text(
            contact.displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            'node ${contact.nodeId} · added via ${contact.addedVia}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Center(
            child: Chip(
              avatar: Icon(
                contact.verified ? Icons.verified : Icons.warning_amber,
                size: 16,
                color: contact.verified ? scheme.primary : scheme.tertiary,
              ),
              label: Text(
                contact.verified
                    ? 'Verified in person'
                    : 'Unverified — compare the phrase below',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final word in phrase.split(' '))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    word,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: scheme.secondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Both phones show the same 6 words if no one is in the middle.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!contact.verified)
            TextButton(
              onPressed: () async {
                await core.contacts.markVerified(nodeId);
              },
              child: const Text('We compared them — mark verified'),
            ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Disappearing messages'),
            subtitle:
                Text(_timerOptions[chat?.disappearAfterSecs] ?? 'Custom'),
            onTap: () async {
              final picked = await showModalBottomSheet<int?>(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final e in _timerOptions.entries)
                        ListTile(
                          title: Text(e.value),
                          selected: chat?.disappearAfterSecs == e.key,
                          onTap: () => Navigator.of(context).pop(e.key ?? -1),
                        ),
                    ],
                  ),
                ),
              );
              if (picked == null) return;
              await core.chat
                  .setDisappearTimer(nodeId, picked == -1 ? null : picked);
            },
          ),
        ],
      ),
    );
  }
}
