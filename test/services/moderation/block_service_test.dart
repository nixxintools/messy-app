import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messy/data/db/database.dart';
import 'package:messy/services/moderation/block_service.dart';

void main() {
  late MessyDatabase db;
  late BlockService blocks;

  setUp(() {
    db = MessyDatabase.forTesting(NativeDatabase.memory());
    blocks = BlockService(db: db);
  });

  tearDown(() => db.close());

  test('block hides and purges a sender', () async {
    await db.into(db.messages).insert(MessagesCompanion.insert(
          messageId: 'm1',
          chatId: 'local',
          direction: 1,
          payloadType: 5,
          body: 'spam',
          sentAt: 1,
          status: 3,
          senderNodeId: const Value('badnode'),
        ));
    expect(await blocks.isBlocked('badnode'), isFalse);

    await blocks.block('badnode', displayName: 'spammer');
    expect(await blocks.isBlocked('badnode'), isTrue);

    // Their stored message is purged.
    final left = await (db.select(db.messages)
          ..where((m) => m.senderNodeId.equals('badnode')))
        .get();
    expect(left, isEmpty);

    await blocks.unblock('badnode');
    expect(await blocks.isBlocked('badnode'), isFalse);
  });

  test('web-of-trust auto-blocks after enough verified votes', () async {
    // One vote: not enough.
    await blocks.recordVote(
      targetNodeId: 'target',
      voterNodeId: 'friendA',
      voterVerified: true,
    );
    expect(await blocks.isBlocked('target'), isFalse);

    // Second verified vote crosses the threshold → auto-mute.
    await blocks.recordVote(
      targetNodeId: 'target',
      voterNodeId: 'friendB',
      voterVerified: true,
    );
    expect(await blocks.isBlocked('target'), isTrue);
  });

  test('unverified contacts get no vote (sybil resistance)', () async {
    await blocks.recordVote(
      targetNodeId: 'target',
      voterNodeId: 'stranger1',
      voterVerified: false,
    );
    await blocks.recordVote(
      targetNodeId: 'target',
      voterNodeId: 'stranger2',
      voterVerified: false,
    );
    expect(await blocks.isBlocked('target'), isFalse);
  });
}
