import 'package:drift/drift.dart';

import '../../data/db/database.dart';

/// Local moderation — docs/SECURITY.md §9.
///
/// On a serverless mesh "block" can only mean "block for me": we hide a
/// node's messages, purge what we stored from them, and stop relaying their
/// public/group posts (becoming a dead end that shrinks their reach). We
/// cannot stop them transmitting to others.
///
/// Web-of-trust: when several of the user's *verified* contacts have each
/// blocked the same node, we auto-mute it too.
class BlockService {
  BlockService({required this.db});

  static const autoBlockThreshold = 2; // verified contacts needed to auto-mute

  final MessyDatabase db;
  final Set<String> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final rows = await db.select(db.blockedNodes).get();
    _cache
      ..clear()
      ..addAll(rows.map((r) => r.nodeId));
    _loaded = true;
  }

  /// Fast synchronous-ish check used on the hot receive path.
  Future<bool> isBlocked(String nodeId) async {
    await _ensureLoaded();
    return _cache.contains(nodeId);
  }

  Stream<List<BlockedRow>> watchBlocked() => db.select(db.blockedNodes).watch();

  Future<void> block(String nodeId, {String? displayName}) async {
    await db.into(db.blockedNodes).insertOnConflictUpdate(
          BlockedNodesCompanion(
            nodeId: Value(nodeId),
            displayName: Value(displayName),
            blockedAt: Value(DateTime.now().millisecondsSinceEpoch),
            auto: const Value(false),
          ),
        );
    _cache.add(nodeId);
    await _purge(nodeId);
  }

  Future<void> unblock(String nodeId) async {
    await (db.delete(db.blockedNodes)..where((b) => b.nodeId.equals(nodeId)))
        .go();
    _cache.remove(nodeId);
  }

  /// Deletes stored messages and relayed frames from a blocked node.
  Future<void> _purge(String nodeId) async {
    await (db.delete(db.messages)
          ..where((m) => m.senderNodeId.equals(nodeId)))
        .go();
    await (db.delete(db.relayStore)
          ..where((r) => r.recipientNodeId.equals(nodeId)))
        .go();
  }

  /// Records a contact's block vote (from a signed gossip record). Only call
  /// with [voterVerified] true — unverified contacts don't get a vote, so a
  /// sybil can't manufacture auto-blocks.
  Future<void> recordVote({
    required String targetNodeId,
    required String voterNodeId,
    required bool voterVerified,
  }) async {
    if (!voterVerified) return;
    await db.into(db.blockVotes).insertOnConflictUpdate(
          BlockVotesCompanion(
            targetNodeId: Value(targetNodeId),
            voterNodeId: Value(voterNodeId),
            receivedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
    final votes = await (db.select(db.blockVotes)
          ..where((v) => v.targetNodeId.equals(targetNodeId)))
        .get();
    if (votes.length >= autoBlockThreshold && !_cache.contains(targetNodeId)) {
      await db.into(db.blockedNodes).insertOnConflictUpdate(
            BlockedNodesCompanion(
              nodeId: Value(targetNodeId),
              blockedAt: Value(DateTime.now().millisecondsSinceEpoch),
              auto: const Value(true),
            ),
          );
      _cache.add(targetNodeId);
      await _purge(targetNodeId);
    }
  }
}
