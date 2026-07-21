import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/constants.dart';
import '../../data/db/database.dart';
import '../transfer/media_store.dart';

/// Disappearing messages + 24 h auto-wipe — docs/SECURITY.md §5.
///
/// Runs a sweep on start (nothing older than its expiry is ever shown, even
/// if the app was closed) and then every minute while the app lives.
class WipeService {
  WipeService({required this.db, required this.mediaStore});

  static const settingAutoWipe = 'auto_wipe';
  static const settingLastWipe = 'last_wipe_ms';

  final MessyDatabase db;
  final MediaStore mediaStore;
  Timer? _timer;

  void start() {
    sweep();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => sweep());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Enabled by default; the setting only exists to opt out.
  Future<bool> autoWipeEnabled() async =>
      await db.getSetting(settingAutoWipe) != '0';

  Future<void> setAutoWipe(bool enabled) async {
    await db.setSetting(settingAutoWipe, enabled ? '1' : '0');
    if (enabled) {
      await db.setSetting(
        settingLastWipe,
        '${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  Future<void> sweep() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Expired messages (disappearing timers, public-room 24 h).
    final expired = await (db.select(db.messages)
          ..where(
            (m) => m.expiresAt.isNotNull() & m.expiresAt.isSmallerThanValue(now),
          ))
        .get();
    for (final msg in expired) {
      await _deleteMessage(msg);
    }

    // 2. Relay retention: 72 h for 1:1, 24 h for public broadcasts.
    // Applies to our own outbox too — otherwise delivery receipts (which
    // never get receipts of their own) would accumulate forever.
    final relayCutoff = now - Protocol.relayRetention.inMilliseconds;
    final publicCutoff = now - Protocol.publicRetention.inMilliseconds;
    await (db.delete(db.relayStore)
          ..where((r) =>
              r.storedAt.isSmallerThanValue(relayCutoff) |
              (r.recipientNodeId.equals('public') &
                  r.storedAt.isSmallerThanValue(publicCutoff))))
        .go();

    // 3. Seen-set pruning (7 d).
    final seenCutoff = now - Protocol.seenRetention.inMilliseconds;
    await (db.delete(db.seenEnvelopes)
          ..where((s) => s.seenAt.isSmallerThanValue(seenCutoff)))
        .go();

    // 4. Global 24 h auto-wipe (on by default).
    if (await autoWipeEnabled()) {
      final lastStr = await db.getSetting(settingLastWipe);
      if (lastStr == null) {
        // First run: start the 24 h clock now instead of wiping immediately.
        await db.setSetting(settingLastWipe, '$now');
      } else if (now - (int.tryParse(lastStr) ?? now) >=
          const Duration(hours: 24).inMilliseconds) {
        await wipeAllNow();
      }
    }
  }

  /// Deletes one message (and its media, if any) by id — used by the
  /// long-press "delete message" action.
  Future<void> deleteMessageById(String messageId) async {
    final msg = await (db.select(db.messages)
          ..where((m) => m.messageId.equals(messageId)))
        .getSingleOrNull();
    if (msg != null) await _deleteMessage(msg);
  }

  /// Deletes a media item everywhere (file, chunks, and its message) — the
  /// gallery "delete" action.
  Future<void> deleteMediaById(String mediaId) async {
    final media = await (db.select(db.mediaItems)
          ..where((m) => m.mediaId.equals(mediaId)))
        .getSingleOrNull();
    await mediaStore.delete(media?.filePath);
    await (db.delete(db.mediaItems)..where((m) => m.mediaId.equals(mediaId)))
        .go();
    await (db.delete(db.mediaChunks)..where((c) => c.mediaId.equals(mediaId)))
        .go();
    await (db.delete(db.messages)..where((m) => m.mediaId.equals(mediaId)))
        .go();
  }

  Future<void> _deleteMessage(MessageRow msg) async {
    final mediaId = msg.mediaId;
    if (mediaId != null) {
      final media = await (db.select(db.mediaItems)
            ..where((m) => m.mediaId.equals(mediaId)))
          .getSingleOrNull();
      await mediaStore.delete(media?.filePath);
      await (db.delete(db.mediaItems)
            ..where((m) => m.mediaId.equals(mediaId)))
          .go();
      await (db.delete(db.mediaChunks)
            ..where((c) => c.mediaId.equals(mediaId)))
          .go();
    }
    await (db.delete(db.messages)
          ..where((m) => m.messageId.equals(msg.messageId)))
        .go();
  }

  /// Erases all messages, media, relayed ciphertext, and the seen set.
  /// Identity and contacts survive — docs/SECURITY.md §5.
  Future<void> wipeAllNow() async {
    await db.delete(db.messages).go();
    await db.delete(db.mediaItems).go();
    await db.delete(db.mediaChunks).go();
    await db.delete(db.relayStore).go();
    await db.delete(db.seenEnvelopes).go();
    await mediaStore.deleteAll();
    await db.setSetting(
      settingLastWipe,
      '${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
