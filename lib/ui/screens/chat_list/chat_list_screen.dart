import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../services/mesh/mesh_router.dart';
import '../../providers/providers.dart';
import '../chat/chat_screen.dart';
import '../group/create_group_screen.dart';
import '../home_shell.dart';

/// Home: pinned "Local" public room + 1:1 chats — wireframe screen 2.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatsProvider).valueOrNull ?? const <ChatRow>[];
    final contacts =
        ref.watch(contactsProvider).valueOrNull ?? const <ContactRow>[];
    final groups = ref.watch(groupsProvider).valueOrNull ?? const <GroupRow>[];
    final messages =
        ref.watch(allMessagesProvider).valueOrNull ?? const <MessageRow>[];

    final contactById = {for (final c in contacts) c.nodeId: c};
    final groupById = {for (final g in groups) g.groupId: g};
    MessageRow? lastOf(String chatId) {
      MessageRow? last;
      for (final m in messages) {
        if (m.chatId != chatId) continue;
        if (last == null || m.messageId.compareTo(last.messageId) > 0) {
          last = m;
        }
      }
      return last;
    }

    int bySorted(ChatRow a, ChatRow b) => (lastOf(b.chatId)?.messageId ?? '')
        .compareTo(lastOf(a.chatId)?.messageId ?? '');
    final direct = chats.where((c) => c.nodeId != null).toList()
      ..sort(bySorted);
    final groupChats = chats
        .where((c) =>
            c.nodeId == null && c.chatId != MeshRouter.publicRoomName)
        .toList()
      ..sort(bySorted);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'New group',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: MeshStatusChip(),
          ),
        ],
      ),
      body: ListView(
        children: [
          _ChatTile(
            title: 'Local',
            subtitle: lastOf(MeshRouter.publicRoomName) == null
                ? 'Public room — anyone nearby'
                : _preview(lastOf(MeshRouter.publicRoomName)!),
            isPublic: true,
            onTap: () => _open(context, MeshRouter.publicRoomName, 'Local'),
          ),
          for (final chat in groupChats)
            _ChatTile(
              title: groupById[chat.chatId]?.name ??
                  chat.chatId.substring(0, 8),
              subtitle: lastOf(chat.chatId) == null
                  ? 'Encrypted group'
                  : _preview(lastOf(chat.chatId)!),
              isGroup: true,
              disappearing: chat.disappearAfterSecs != null,
              onTap: () => _open(
                context,
                chat.chatId,
                groupById[chat.chatId]?.name ?? 'Group',
              ),
            ),
          for (final chat in direct)
            _ChatTile(
              title: contactById[chat.chatId]?.displayName ?? chat.chatId,
              subtitle: lastOf(chat.chatId) == null
                  ? 'No messages yet'
                  : _preview(lastOf(chat.chatId)!),
              verified: contactById[chat.chatId]?.verified ?? false,
              disappearing: chat.disappearAfterSecs != null,
              onTap: () => _open(
                context,
                chat.chatId,
                contactById[chat.chatId]?.displayName ?? chat.chatId,
              ),
            ),
          if (direct.isEmpty && groupChats.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No chats yet.\nAdd a contact with the + button — by QR '
                'in person, or from the nearby list.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  static String _preview(MessageRow m) {
    final prefix = m.direction == 0 ? 'you: ' : '';
    if (m.mediaId != null) return '$prefix\u{1F4CE} ${m.body}';
    return '$prefix${m.body}';
  }

  void _open(BuildContext context, String chatId, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, title: title)),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPublic = false,
    this.isGroup = false,
    this.verified = false,
    this.disappearing = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPublic;
  final bool isGroup;
  final bool verified;
  final bool disappearing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isPublic ? scheme.primaryContainer : null,
        foregroundColor: isPublic ? scheme.onPrimaryContainer : null,
        child: Icon(
          isPublic
              ? Icons.campaign
              : isGroup
                  ? Icons.groups
                  : Icons.person,
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          if (isPublic) ...[
            const SizedBox(width: 6),
            _tag(context, 'public'),
          ],
          if (isGroup) ...[
            const SizedBox(width: 6),
            _tag(context, 'group'),
          ],
          if (verified) ...[
            const SizedBox(width: 6),
            Icon(Icons.verified, size: 14, color: scheme.primary),
          ],
          if (disappearing) ...[
            const SizedBox(width: 6),
            Icon(Icons.timer_outlined, size: 14, color: scheme.outline),
          ],
        ],
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _tag(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: scheme.onPrimaryContainer),
      ),
    );
  }
}
