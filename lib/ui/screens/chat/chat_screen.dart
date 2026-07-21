import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/well_known.dart';
import '../../../data/db/database.dart';
import '../../../domain/entities/message.dart' as domain;
import '../../../services/mesh/mesh_router.dart';
import '../../providers/providers.dart';
import '../contacts/contact_detail_screen.dart';

/// Public room + 1:1 chat — wireframe screens 3 & 4.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId, required this.title});

  final String chatId;
  final String title;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _picker = ImagePicker();
  bool _sending = false;

  bool get _isPublic => widget.chatId == MeshRouter.publicRoomName;

  bool get _isMediaRoom => widget.chatId == WellKnown.mediaRoomId;

  bool get _isGroup {
    if (_isMediaRoom) return false; // styled as a public channel instead
    final groups = ref.read(groupsProvider).valueOrNull ?? const [];
    return groups.any((g) => g.groupId == widget.chatId);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      final core = await ref.read(coreProvider.future);
      await core.chat.sendText(widget.chatId, text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendMedia({required bool video}) async {
    final XFile? file = video
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1600,
            imageQuality: 80,
          );
    if (file == null || !mounted) return;
    final core = await ref.read(coreProvider.future);
    final mime = file.mimeType ??
        (video ? 'video/mp4' : 'image/jpeg');
    if (video && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compressing video to 720p…')),
      );
    }
    final ok = await core.transfer
        .sendMedia(widget.chatId, File(file.path), mime);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Still over the 25 MB mesh cap after compression — '
            'try a shorter clip.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages =
        ref.watch(messagesProvider(widget.chatId)).valueOrNull ??
            const <MessageRow>[];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_isPublic && !_isGroup && !_isMediaRoom)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContactDetailScreen(nodeId: widget.chatId),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: _isPublic
                ? scheme.tertiaryContainer
                : scheme.primaryContainer.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Text(
              _isPublic
                  ? '⚠ Readable by anyone nearby · messages vanish '
                      'after 24 h'
                  : _isMediaRoom
                      ? '⚠ Public media channel · visible to anyone '
                          'nearby · vanishes after 24 h'
                      : _isGroup
                          ? '\u{1F512} Encrypted group · only invited '
                              'members can read'
                          : '\u{1F512} End-to-end encrypted',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) =>
                  _MessageBubble(row: messages[messages.length - 1 - i]),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                // Media: 1:1 chats and the public Media channel. Private
                // groups stay text-only to limit mesh traffic.
                if ((!_isPublic && !_isGroup) || _isMediaRoom) ...[
                  IconButton(
                    icon: const Icon(Icons.photo_outlined),
                    onPressed: () => _sendMedia(video: false),
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam_outlined),
                    onPressed: () => _sendMedia(video: true),
                  ),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: _input,
                      decoration: InputDecoration(
                        hintText: _isPublic
                            ? 'Message everyone nearby…'
                            : 'Message…',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _sending ? null : _send,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.row});

  final MessageRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final mine = row.direction == domain.MessageDirection.outgoing.index;
    final status = domain.MessageStatus.values[row.status];

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          // Dark gold for own bubbles (white text stays readable); the
          // bright brand yellow is reserved for buttons and highlights.
          color: mine ? const Color(0xFF4A3F0D) : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14).copyWith(
            bottomRight: mine ? const Radius.circular(3) : null,
            bottomLeft: mine ? null : const Radius.circular(3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!mine && row.senderName != null)
              Text(
                '${row.senderName} · ${row.senderNodeId?.substring(0, 4) ?? ''}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.primary),
              ),
            if (row.mediaId != null)
              _MediaContent(mediaId: row.mediaId!)
            else
              Text(row.body),
            const SizedBox(height: 2),
            Text(
              _statusLine(status, mine, row.sentAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLine(domain.MessageStatus s, bool mine, int sentAtMs) {
    final t = DateTime.fromMillisecondsSinceEpoch(sentAtMs);
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    if (!mine) return '$hh:$mm';
    return switch (s) {
      domain.MessageStatus.queued => '$hh:$mm · queued',
      domain.MessageStatus.sentToMesh => '$hh:$mm · sent to mesh ⛓',
      domain.MessageStatus.delivered => '$hh:$mm · ✓✓ delivered',
      _ => '$hh:$mm',
    };
  }
}

class _MediaContent extends ConsumerWidget {
  const _MediaContent({required this.mediaId});

  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(mediaProvider(mediaId)).valueOrNull;
    if (media == null || !media.complete || media.filePath == null) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('receiving…'),
          ],
        ),
      );
    }
    if (media.mimeType.startsWith('image/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(media.filePath!),
          width: 220,
          fit: BoxFit.cover,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.movie_outlined),
        const SizedBox(width: 6),
        Text('video · ${(media.totalSize / (1024 * 1024)).toStringAsFixed(1)} MB'),
      ],
    );
  }
}
