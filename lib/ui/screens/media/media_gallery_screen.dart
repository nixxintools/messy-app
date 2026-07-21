import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../providers/providers.dart';
import '../home_shell.dart';

/// Media tab: every photo/video on this device (sent and received, from
/// chats, groups, and the public Media channel) in a gallery grid.
class MediaGalleryScreen extends ConsumerWidget {
  const MediaGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        (ref.watch(mediaGalleryProvider).valueOrNull ?? const <MediaRow>[])
            .where((m) => m.complete && m.filePath != null)
            .toList()
          ..sort((a, b) => b.mediaId.compareTo(a.mediaId)); // newest first

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 12), child: MeshStatusChip()),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No media yet.\nPhotos and videos you send or receive — '
                  'including the public Media channel — appear here.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => _MediaTile(item: items[i]),
            ),
    );
  }
}

class _MediaTile extends ConsumerWidget {
  const _MediaTile({required this.item});

  final MediaRow item;

  bool get _isImage => item.mimeType.startsWith('image/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _open(context),
      onLongPress: () => _confirmDelete(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: _isImage
            ? Image.file(File(item.filePath!), fit: BoxFit.cover)
            : Container(
                color: scheme.surfaceContainerHigh,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.movie_outlined, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      '${(item.totalSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: const Text('Delete this media'),
              subtitle: const Text('Removes it from this device'),
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final core = await ref.read(coreProvider.future);
      await core.wipe.deleteMediaById(item.mediaId);
    }
  }

  void _open(BuildContext context) {
    if (_isImage) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: InteractiveViewer(
                maxScale: 6,
                child: Image.file(File(item.filePath!)),
              ),
            ),
          ),
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Video'),
          content: Text(
            'Saved on this device:\n${item.filePath}\n\n'
            'Open it with your gallery or file manager to play '
            '(in-app playback is on the roadmap).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
