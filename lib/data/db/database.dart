import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/well_known.dart';

part 'database.g.dart';

/// Local-only SQLite -- docs/ARCHITECTURE.md section 8. No cloud, no sync.
/// secure_delete is enabled so wiped rows are overwritten, not unlinked.

@DataClassName('ContactRow')
class Contacts extends Table {
  TextColumn get nodeId => text()();
  BlobColumn get x25519Pub => blob()();
  BlobColumn get ed25519Pub => blob()();
  TextColumn get displayName => text()();
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  TextColumn get addedVia => text()(); // 'qr' | 'nearby'
  IntColumn get lastSeenAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {nodeId};
}

@DataClassName('ChatRow')
class Chats extends Table {
  TextColumn get chatId => text()(); // contact nodeId, or 'local' public room
  TextColumn get nodeId => text().nullable()(); // null = public room
  IntColumn get disappearAfterSecs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {chatId};
}

@DataClassName('MessageRow')
class Messages extends Table {
  TextColumn get messageId => text()(); // UUIDv7
  TextColumn get chatId => text()();
  IntColumn get direction => integer()(); // 0 out, 1 in
  IntColumn get payloadType => integer()();
  TextColumn get body => text()();
  TextColumn get senderName => text().nullable()(); // public-room display
  TextColumn get senderNodeId => text().nullable()();
  TextColumn get mediaId => text().nullable()();
  IntColumn get sentAt => integer()();
  IntColumn get receivedAt => integer().nullable()();
  IntColumn get expiresAt => integer().nullable()();
  IntColumn get status => integer()(); // MessageStatus.index

  @override
  Set<Column> get primaryKey => {messageId};
}

@DataClassName('MediaRow')
class MediaItems extends Table {
  TextColumn get mediaId => text()();
  TextColumn get messageId => text()();
  TextColumn get filePath => text().nullable()();
  TextColumn get mimeType => text()();
  IntColumn get totalSize => integer()();
  IntColumn get chunkTotal => integer()();
  BlobColumn get sha256 => blob()();
  BoolColumn get complete => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {mediaId};
}

@DataClassName('MediaChunkRow')
class MediaChunks extends Table {
  TextColumn get mediaId => text()();
  IntColumn get chunkIndex => integer()();
  BlobColumn get data => blob()();

  @override
  Set<Column> get primaryKey => {mediaId, chunkIndex};
}

/// Opaque ciphertext frames we carry for others (and our own outbox).
@DataClassName('RelayRow')
class RelayStore extends Table {
  TextColumn get messageId => text()();
  IntColumn get chunkIndex => integer()();
  BlobColumn get frame => blob()();
  TextColumn get recipientNodeId => text()(); // 'public' for broadcasts
  IntColumn get ttl => integer()();
  IntColumn get size => integer()();
  IntColumn get storedAt => integer()();
  BoolColumn get mine => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {messageId, chunkIndex};
}

@DataClassName('SeenRow')
class SeenEnvelopes extends Table {
  TextColumn get messageId => text()();
  IntColumn get chunkIndex => integer()();
  IntColumn get seenAt => integer()();

  @override
  Set<Column> get primaryKey => {messageId, chunkIndex};
}

/// Encrypted group chats: whoever holds `key` is a member. groupId is
/// derived from SHA-256(key), so it can be used as an opaque routing tag.
@DataClassName('GroupRow')
class Groups extends Table {
  TextColumn get groupId => text()();
  TextColumn get name => text()();
  BlobColumn get key => blob()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {groupId};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Contacts,
    Chats,
    Messages,
    MediaItems,
    MediaChunks,
    RelayStore,
    SeenEnvelopes,
    Groups,
    Settings,
  ],
)
class MessyDatabase extends _$MessyDatabase {
  MessyDatabase() : super(_open());

  MessyDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(groups);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA secure_delete = ON');
          // The public rooms always exist.
          await into(chats).insertOnConflictUpdate(
            const ChatsCompanion(
              chatId: Value('local'),
              nodeId: Value(null),
            ),
          );
          // Global media channel — a well-known group every install joins.
          await into(groups).insert(
            GroupsCompanion(
              groupId: Value(WellKnown.mediaRoomId),
              name: const Value(WellKnown.mediaRoomName),
              key: Value(WellKnown.mediaRoomKey),
              createdAt: const Value(0),
            ),
            mode: InsertMode.insertOrIgnore,
          );
          await into(chats).insert(
            ChatsCompanion(
              chatId: Value(WellKnown.mediaRoomId),
              nodeId: const Value(null),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        },
      );

  static QueryExecutor _open() => driftDatabase(name: 'messy');

  Future<String?> getSetting(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(key: Value(key), value: Value(value)),
      );
}

