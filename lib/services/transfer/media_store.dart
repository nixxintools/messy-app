import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Media files on disk; the DB stores paths — docs/ARCHITECTURE.md §8.
class MediaStore {
  Directory? _dir;

  Future<Directory> _mediaDir() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}media');
    await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  String _extensionFor(String mime) {
    return switch (mime) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/gif' => 'gif',
      'image/webp' => 'webp',
      'video/mp4' => 'mp4',
      'video/webm' => 'webm',
      _ => 'bin',
    };
  }

  Future<String> write(String mediaId, String mime, Uint8List bytes) async {
    final dir = await _mediaDir();
    final file = File(
      '${dir.path}${Platform.pathSeparator}$mediaId.${_extensionFor(mime)}',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> delete(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  Future<void> deleteAll() async {
    final dir = await _mediaDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      _dir = null;
    }
  }
}
