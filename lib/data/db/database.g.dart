// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ContactsTable extends Contacts
    with TableInfo<$ContactsTable, ContactRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x25519PubMeta = const VerificationMeta(
    'x25519Pub',
  );
  @override
  late final GeneratedColumn<Uint8List> x25519Pub = GeneratedColumn<Uint8List>(
    'x25519_pub',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ed25519PubMeta = const VerificationMeta(
    'ed25519Pub',
  );
  @override
  late final GeneratedColumn<Uint8List> ed25519Pub = GeneratedColumn<Uint8List>(
    'ed25519_pub',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verifiedMeta = const VerificationMeta(
    'verified',
  );
  @override
  late final GeneratedColumn<bool> verified = GeneratedColumn<bool>(
    'verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _addedViaMeta = const VerificationMeta(
    'addedVia',
  );
  @override
  late final GeneratedColumn<String> addedVia = GeneratedColumn<String>(
    'added_via',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    nodeId,
    x25519Pub,
    ed25519Pub,
    displayName,
    verified,
    addedVia,
    lastSeenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('x25519_pub')) {
      context.handle(
        _x25519PubMeta,
        x25519Pub.isAcceptableOrUnknown(data['x25519_pub']!, _x25519PubMeta),
      );
    } else if (isInserting) {
      context.missing(_x25519PubMeta);
    }
    if (data.containsKey('ed25519_pub')) {
      context.handle(
        _ed25519PubMeta,
        ed25519Pub.isAcceptableOrUnknown(data['ed25519_pub']!, _ed25519PubMeta),
      );
    } else if (isInserting) {
      context.missing(_ed25519PubMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('verified')) {
      context.handle(
        _verifiedMeta,
        verified.isAcceptableOrUnknown(data['verified']!, _verifiedMeta),
      );
    }
    if (data.containsKey('added_via')) {
      context.handle(
        _addedViaMeta,
        addedVia.isAcceptableOrUnknown(data['added_via']!, _addedViaMeta),
      );
    } else if (isInserting) {
      context.missing(_addedViaMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nodeId};
  @override
  ContactRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactRow(
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      x25519Pub: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}x25519_pub'],
      )!,
      ed25519Pub: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}ed25519_pub'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      verified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}verified'],
      )!,
      addedVia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_via'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at'],
      ),
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class ContactRow extends DataClass implements Insertable<ContactRow> {
  final String nodeId;
  final Uint8List x25519Pub;
  final Uint8List ed25519Pub;
  final String displayName;
  final bool verified;
  final String addedVia;
  final int? lastSeenAt;
  const ContactRow({
    required this.nodeId,
    required this.x25519Pub,
    required this.ed25519Pub,
    required this.displayName,
    required this.verified,
    required this.addedVia,
    this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['node_id'] = Variable<String>(nodeId);
    map['x25519_pub'] = Variable<Uint8List>(x25519Pub);
    map['ed25519_pub'] = Variable<Uint8List>(ed25519Pub);
    map['display_name'] = Variable<String>(displayName);
    map['verified'] = Variable<bool>(verified);
    map['added_via'] = Variable<String>(addedVia);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<int>(lastSeenAt);
    }
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      nodeId: Value(nodeId),
      x25519Pub: Value(x25519Pub),
      ed25519Pub: Value(ed25519Pub),
      displayName: Value(displayName),
      verified: Value(verified),
      addedVia: Value(addedVia),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
    );
  }

  factory ContactRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactRow(
      nodeId: serializer.fromJson<String>(json['nodeId']),
      x25519Pub: serializer.fromJson<Uint8List>(json['x25519Pub']),
      ed25519Pub: serializer.fromJson<Uint8List>(json['ed25519Pub']),
      displayName: serializer.fromJson<String>(json['displayName']),
      verified: serializer.fromJson<bool>(json['verified']),
      addedVia: serializer.fromJson<String>(json['addedVia']),
      lastSeenAt: serializer.fromJson<int?>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nodeId': serializer.toJson<String>(nodeId),
      'x25519Pub': serializer.toJson<Uint8List>(x25519Pub),
      'ed25519Pub': serializer.toJson<Uint8List>(ed25519Pub),
      'displayName': serializer.toJson<String>(displayName),
      'verified': serializer.toJson<bool>(verified),
      'addedVia': serializer.toJson<String>(addedVia),
      'lastSeenAt': serializer.toJson<int?>(lastSeenAt),
    };
  }

  ContactRow copyWith({
    String? nodeId,
    Uint8List? x25519Pub,
    Uint8List? ed25519Pub,
    String? displayName,
    bool? verified,
    String? addedVia,
    Value<int?> lastSeenAt = const Value.absent(),
  }) => ContactRow(
    nodeId: nodeId ?? this.nodeId,
    x25519Pub: x25519Pub ?? this.x25519Pub,
    ed25519Pub: ed25519Pub ?? this.ed25519Pub,
    displayName: displayName ?? this.displayName,
    verified: verified ?? this.verified,
    addedVia: addedVia ?? this.addedVia,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
  );
  ContactRow copyWithCompanion(ContactsCompanion data) {
    return ContactRow(
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      x25519Pub: data.x25519Pub.present ? data.x25519Pub.value : this.x25519Pub,
      ed25519Pub: data.ed25519Pub.present
          ? data.ed25519Pub.value
          : this.ed25519Pub,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      verified: data.verified.present ? data.verified.value : this.verified,
      addedVia: data.addedVia.present ? data.addedVia.value : this.addedVia,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactRow(')
          ..write('nodeId: $nodeId, ')
          ..write('x25519Pub: $x25519Pub, ')
          ..write('ed25519Pub: $ed25519Pub, ')
          ..write('displayName: $displayName, ')
          ..write('verified: $verified, ')
          ..write('addedVia: $addedVia, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    nodeId,
    $driftBlobEquality.hash(x25519Pub),
    $driftBlobEquality.hash(ed25519Pub),
    displayName,
    verified,
    addedVia,
    lastSeenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactRow &&
          other.nodeId == this.nodeId &&
          $driftBlobEquality.equals(other.x25519Pub, this.x25519Pub) &&
          $driftBlobEquality.equals(other.ed25519Pub, this.ed25519Pub) &&
          other.displayName == this.displayName &&
          other.verified == this.verified &&
          other.addedVia == this.addedVia &&
          other.lastSeenAt == this.lastSeenAt);
}

class ContactsCompanion extends UpdateCompanion<ContactRow> {
  final Value<String> nodeId;
  final Value<Uint8List> x25519Pub;
  final Value<Uint8List> ed25519Pub;
  final Value<String> displayName;
  final Value<bool> verified;
  final Value<String> addedVia;
  final Value<int?> lastSeenAt;
  final Value<int> rowid;
  const ContactsCompanion({
    this.nodeId = const Value.absent(),
    this.x25519Pub = const Value.absent(),
    this.ed25519Pub = const Value.absent(),
    this.displayName = const Value.absent(),
    this.verified = const Value.absent(),
    this.addedVia = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsCompanion.insert({
    required String nodeId,
    required Uint8List x25519Pub,
    required Uint8List ed25519Pub,
    required String displayName,
    this.verified = const Value.absent(),
    required String addedVia,
    this.lastSeenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : nodeId = Value(nodeId),
       x25519Pub = Value(x25519Pub),
       ed25519Pub = Value(ed25519Pub),
       displayName = Value(displayName),
       addedVia = Value(addedVia);
  static Insertable<ContactRow> custom({
    Expression<String>? nodeId,
    Expression<Uint8List>? x25519Pub,
    Expression<Uint8List>? ed25519Pub,
    Expression<String>? displayName,
    Expression<bool>? verified,
    Expression<String>? addedVia,
    Expression<int>? lastSeenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nodeId != null) 'node_id': nodeId,
      if (x25519Pub != null) 'x25519_pub': x25519Pub,
      if (ed25519Pub != null) 'ed25519_pub': ed25519Pub,
      if (displayName != null) 'display_name': displayName,
      if (verified != null) 'verified': verified,
      if (addedVia != null) 'added_via': addedVia,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith({
    Value<String>? nodeId,
    Value<Uint8List>? x25519Pub,
    Value<Uint8List>? ed25519Pub,
    Value<String>? displayName,
    Value<bool>? verified,
    Value<String>? addedVia,
    Value<int?>? lastSeenAt,
    Value<int>? rowid,
  }) {
    return ContactsCompanion(
      nodeId: nodeId ?? this.nodeId,
      x25519Pub: x25519Pub ?? this.x25519Pub,
      ed25519Pub: ed25519Pub ?? this.ed25519Pub,
      displayName: displayName ?? this.displayName,
      verified: verified ?? this.verified,
      addedVia: addedVia ?? this.addedVia,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (x25519Pub.present) {
      map['x25519_pub'] = Variable<Uint8List>(x25519Pub.value);
    }
    if (ed25519Pub.present) {
      map['ed25519_pub'] = Variable<Uint8List>(ed25519Pub.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (verified.present) {
      map['verified'] = Variable<bool>(verified.value);
    }
    if (addedVia.present) {
      map['added_via'] = Variable<String>(addedVia.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('nodeId: $nodeId, ')
          ..write('x25519Pub: $x25519Pub, ')
          ..write('ed25519Pub: $ed25519Pub, ')
          ..write('displayName: $displayName, ')
          ..write('verified: $verified, ')
          ..write('addedVia: $addedVia, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatsTable extends Chats with TableInfo<$ChatsTable, ChatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disappearAfterSecsMeta =
      const VerificationMeta('disappearAfterSecs');
  @override
  late final GeneratedColumn<int> disappearAfterSecs = GeneratedColumn<int>(
    'disappear_after_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [chatId, nodeId, disappearAfterSecs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('disappear_after_secs')) {
      context.handle(
        _disappearAfterSecsMeta,
        disappearAfterSecs.isAcceptableOrUnknown(
          data['disappear_after_secs']!,
          _disappearAfterSecsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chatId};
  @override
  ChatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatRow(
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      ),
      disappearAfterSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disappear_after_secs'],
      ),
    );
  }

  @override
  $ChatsTable createAlias(String alias) {
    return $ChatsTable(attachedDatabase, alias);
  }
}

class ChatRow extends DataClass implements Insertable<ChatRow> {
  final String chatId;
  final String? nodeId;
  final int? disappearAfterSecs;
  const ChatRow({required this.chatId, this.nodeId, this.disappearAfterSecs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<String>(chatId);
    if (!nullToAbsent || nodeId != null) {
      map['node_id'] = Variable<String>(nodeId);
    }
    if (!nullToAbsent || disappearAfterSecs != null) {
      map['disappear_after_secs'] = Variable<int>(disappearAfterSecs);
    }
    return map;
  }

  ChatsCompanion toCompanion(bool nullToAbsent) {
    return ChatsCompanion(
      chatId: Value(chatId),
      nodeId: nodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(nodeId),
      disappearAfterSecs: disappearAfterSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(disappearAfterSecs),
    );
  }

  factory ChatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatRow(
      chatId: serializer.fromJson<String>(json['chatId']),
      nodeId: serializer.fromJson<String?>(json['nodeId']),
      disappearAfterSecs: serializer.fromJson<int?>(json['disappearAfterSecs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<String>(chatId),
      'nodeId': serializer.toJson<String?>(nodeId),
      'disappearAfterSecs': serializer.toJson<int?>(disappearAfterSecs),
    };
  }

  ChatRow copyWith({
    String? chatId,
    Value<String?> nodeId = const Value.absent(),
    Value<int?> disappearAfterSecs = const Value.absent(),
  }) => ChatRow(
    chatId: chatId ?? this.chatId,
    nodeId: nodeId.present ? nodeId.value : this.nodeId,
    disappearAfterSecs: disappearAfterSecs.present
        ? disappearAfterSecs.value
        : this.disappearAfterSecs,
  );
  ChatRow copyWithCompanion(ChatsCompanion data) {
    return ChatRow(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      disappearAfterSecs: data.disappearAfterSecs.present
          ? data.disappearAfterSecs.value
          : this.disappearAfterSecs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatRow(')
          ..write('chatId: $chatId, ')
          ..write('nodeId: $nodeId, ')
          ..write('disappearAfterSecs: $disappearAfterSecs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chatId, nodeId, disappearAfterSecs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatRow &&
          other.chatId == this.chatId &&
          other.nodeId == this.nodeId &&
          other.disappearAfterSecs == this.disappearAfterSecs);
}

class ChatsCompanion extends UpdateCompanion<ChatRow> {
  final Value<String> chatId;
  final Value<String?> nodeId;
  final Value<int?> disappearAfterSecs;
  final Value<int> rowid;
  const ChatsCompanion({
    this.chatId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.disappearAfterSecs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatsCompanion.insert({
    required String chatId,
    this.nodeId = const Value.absent(),
    this.disappearAfterSecs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : chatId = Value(chatId);
  static Insertable<ChatRow> custom({
    Expression<String>? chatId,
    Expression<String>? nodeId,
    Expression<int>? disappearAfterSecs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (nodeId != null) 'node_id': nodeId,
      if (disappearAfterSecs != null)
        'disappear_after_secs': disappearAfterSecs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatsCompanion copyWith({
    Value<String>? chatId,
    Value<String?>? nodeId,
    Value<int?>? disappearAfterSecs,
    Value<int>? rowid,
  }) {
    return ChatsCompanion(
      chatId: chatId ?? this.chatId,
      nodeId: nodeId ?? this.nodeId,
      disappearAfterSecs: disappearAfterSecs ?? this.disappearAfterSecs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (disappearAfterSecs.present) {
      map['disappear_after_secs'] = Variable<int>(disappearAfterSecs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatsCompanion(')
          ..write('chatId: $chatId, ')
          ..write('nodeId: $nodeId, ')
          ..write('disappearAfterSecs: $disappearAfterSecs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<int> direction = GeneratedColumn<int>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadTypeMeta = const VerificationMeta(
    'payloadType',
  );
  @override
  late final GeneratedColumn<int> payloadType = GeneratedColumn<int>(
    'payload_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderNameMeta = const VerificationMeta(
    'senderName',
  );
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
    'sender_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _senderNodeIdMeta = const VerificationMeta(
    'senderNodeId',
  );
  @override
  late final GeneratedColumn<String> senderNodeId = GeneratedColumn<String>(
    'sender_node_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<int> sentAt = GeneratedColumn<int>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<int> receivedAt = GeneratedColumn<int>(
    'received_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    chatId,
    direction,
    payloadType,
    body,
    senderName,
    senderNodeId,
    mediaId,
    sentAt,
    receivedAt,
    expiresAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('payload_type')) {
      context.handle(
        _payloadTypeMeta,
        payloadType.isAcceptableOrUnknown(
          data['payload_type']!,
          _payloadTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadTypeMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('sender_name')) {
      context.handle(
        _senderNameMeta,
        senderName.isAcceptableOrUnknown(data['sender_name']!, _senderNameMeta),
      );
    }
    if (data.containsKey('sender_node_id')) {
      context.handle(
        _senderNodeIdMeta,
        senderNodeId.isAcceptableOrUnknown(
          data['sender_node_id']!,
          _senderNodeIdMeta,
        ),
      );
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  MessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageRow(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction'],
      )!,
      payloadType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payload_type'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      senderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_name'],
      ),
      senderNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_node_id'],
      ),
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      ),
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_at'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_at'],
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageRow extends DataClass implements Insertable<MessageRow> {
  final String messageId;
  final String chatId;
  final int direction;
  final int payloadType;
  final String body;
  final String? senderName;
  final String? senderNodeId;
  final String? mediaId;
  final int sentAt;
  final int? receivedAt;
  final int? expiresAt;
  final int status;
  const MessageRow({
    required this.messageId,
    required this.chatId,
    required this.direction,
    required this.payloadType,
    required this.body,
    this.senderName,
    this.senderNodeId,
    this.mediaId,
    required this.sentAt,
    this.receivedAt,
    this.expiresAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['chat_id'] = Variable<String>(chatId);
    map['direction'] = Variable<int>(direction);
    map['payload_type'] = Variable<int>(payloadType);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || senderName != null) {
      map['sender_name'] = Variable<String>(senderName);
    }
    if (!nullToAbsent || senderNodeId != null) {
      map['sender_node_id'] = Variable<String>(senderNodeId);
    }
    if (!nullToAbsent || mediaId != null) {
      map['media_id'] = Variable<String>(mediaId);
    }
    map['sent_at'] = Variable<int>(sentAt);
    if (!nullToAbsent || receivedAt != null) {
      map['received_at'] = Variable<int>(receivedAt);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(expiresAt);
    }
    map['status'] = Variable<int>(status);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      messageId: Value(messageId),
      chatId: Value(chatId),
      direction: Value(direction),
      payloadType: Value(payloadType),
      body: Value(body),
      senderName: senderName == null && nullToAbsent
          ? const Value.absent()
          : Value(senderName),
      senderNodeId: senderNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderNodeId),
      mediaId: mediaId == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaId),
      sentAt: Value(sentAt),
      receivedAt: receivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      status: Value(status),
    );
  }

  factory MessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageRow(
      messageId: serializer.fromJson<String>(json['messageId']),
      chatId: serializer.fromJson<String>(json['chatId']),
      direction: serializer.fromJson<int>(json['direction']),
      payloadType: serializer.fromJson<int>(json['payloadType']),
      body: serializer.fromJson<String>(json['body']),
      senderName: serializer.fromJson<String?>(json['senderName']),
      senderNodeId: serializer.fromJson<String?>(json['senderNodeId']),
      mediaId: serializer.fromJson<String?>(json['mediaId']),
      sentAt: serializer.fromJson<int>(json['sentAt']),
      receivedAt: serializer.fromJson<int?>(json['receivedAt']),
      expiresAt: serializer.fromJson<int?>(json['expiresAt']),
      status: serializer.fromJson<int>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'chatId': serializer.toJson<String>(chatId),
      'direction': serializer.toJson<int>(direction),
      'payloadType': serializer.toJson<int>(payloadType),
      'body': serializer.toJson<String>(body),
      'senderName': serializer.toJson<String?>(senderName),
      'senderNodeId': serializer.toJson<String?>(senderNodeId),
      'mediaId': serializer.toJson<String?>(mediaId),
      'sentAt': serializer.toJson<int>(sentAt),
      'receivedAt': serializer.toJson<int?>(receivedAt),
      'expiresAt': serializer.toJson<int?>(expiresAt),
      'status': serializer.toJson<int>(status),
    };
  }

  MessageRow copyWith({
    String? messageId,
    String? chatId,
    int? direction,
    int? payloadType,
    String? body,
    Value<String?> senderName = const Value.absent(),
    Value<String?> senderNodeId = const Value.absent(),
    Value<String?> mediaId = const Value.absent(),
    int? sentAt,
    Value<int?> receivedAt = const Value.absent(),
    Value<int?> expiresAt = const Value.absent(),
    int? status,
  }) => MessageRow(
    messageId: messageId ?? this.messageId,
    chatId: chatId ?? this.chatId,
    direction: direction ?? this.direction,
    payloadType: payloadType ?? this.payloadType,
    body: body ?? this.body,
    senderName: senderName.present ? senderName.value : this.senderName,
    senderNodeId: senderNodeId.present ? senderNodeId.value : this.senderNodeId,
    mediaId: mediaId.present ? mediaId.value : this.mediaId,
    sentAt: sentAt ?? this.sentAt,
    receivedAt: receivedAt.present ? receivedAt.value : this.receivedAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    status: status ?? this.status,
  );
  MessageRow copyWithCompanion(MessagesCompanion data) {
    return MessageRow(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      direction: data.direction.present ? data.direction.value : this.direction,
      payloadType: data.payloadType.present
          ? data.payloadType.value
          : this.payloadType,
      body: data.body.present ? data.body.value : this.body,
      senderName: data.senderName.present
          ? data.senderName.value
          : this.senderName,
      senderNodeId: data.senderNodeId.present
          ? data.senderNodeId.value
          : this.senderNodeId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageRow(')
          ..write('messageId: $messageId, ')
          ..write('chatId: $chatId, ')
          ..write('direction: $direction, ')
          ..write('payloadType: $payloadType, ')
          ..write('body: $body, ')
          ..write('senderName: $senderName, ')
          ..write('senderNodeId: $senderNodeId, ')
          ..write('mediaId: $mediaId, ')
          ..write('sentAt: $sentAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    chatId,
    direction,
    payloadType,
    body,
    senderName,
    senderNodeId,
    mediaId,
    sentAt,
    receivedAt,
    expiresAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageRow &&
          other.messageId == this.messageId &&
          other.chatId == this.chatId &&
          other.direction == this.direction &&
          other.payloadType == this.payloadType &&
          other.body == this.body &&
          other.senderName == this.senderName &&
          other.senderNodeId == this.senderNodeId &&
          other.mediaId == this.mediaId &&
          other.sentAt == this.sentAt &&
          other.receivedAt == this.receivedAt &&
          other.expiresAt == this.expiresAt &&
          other.status == this.status);
}

class MessagesCompanion extends UpdateCompanion<MessageRow> {
  final Value<String> messageId;
  final Value<String> chatId;
  final Value<int> direction;
  final Value<int> payloadType;
  final Value<String> body;
  final Value<String?> senderName;
  final Value<String?> senderNodeId;
  final Value<String?> mediaId;
  final Value<int> sentAt;
  final Value<int?> receivedAt;
  final Value<int?> expiresAt;
  final Value<int> status;
  final Value<int> rowid;
  const MessagesCompanion({
    this.messageId = const Value.absent(),
    this.chatId = const Value.absent(),
    this.direction = const Value.absent(),
    this.payloadType = const Value.absent(),
    this.body = const Value.absent(),
    this.senderName = const Value.absent(),
    this.senderNodeId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String messageId,
    required String chatId,
    required int direction,
    required int payloadType,
    required String body,
    this.senderName = const Value.absent(),
    this.senderNodeId = const Value.absent(),
    this.mediaId = const Value.absent(),
    required int sentAt,
    this.receivedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    required int status,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       chatId = Value(chatId),
       direction = Value(direction),
       payloadType = Value(payloadType),
       body = Value(body),
       sentAt = Value(sentAt),
       status = Value(status);
  static Insertable<MessageRow> custom({
    Expression<String>? messageId,
    Expression<String>? chatId,
    Expression<int>? direction,
    Expression<int>? payloadType,
    Expression<String>? body,
    Expression<String>? senderName,
    Expression<String>? senderNodeId,
    Expression<String>? mediaId,
    Expression<int>? sentAt,
    Expression<int>? receivedAt,
    Expression<int>? expiresAt,
    Expression<int>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (chatId != null) 'chat_id': chatId,
      if (direction != null) 'direction': direction,
      if (payloadType != null) 'payload_type': payloadType,
      if (body != null) 'body': body,
      if (senderName != null) 'sender_name': senderName,
      if (senderNodeId != null) 'sender_node_id': senderNodeId,
      if (mediaId != null) 'media_id': mediaId,
      if (sentAt != null) 'sent_at': sentAt,
      if (receivedAt != null) 'received_at': receivedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? messageId,
    Value<String>? chatId,
    Value<int>? direction,
    Value<int>? payloadType,
    Value<String>? body,
    Value<String?>? senderName,
    Value<String?>? senderNodeId,
    Value<String?>? mediaId,
    Value<int>? sentAt,
    Value<int?>? receivedAt,
    Value<int?>? expiresAt,
    Value<int>? status,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      direction: direction ?? this.direction,
      payloadType: payloadType ?? this.payloadType,
      body: body ?? this.body,
      senderName: senderName ?? this.senderName,
      senderNodeId: senderNodeId ?? this.senderNodeId,
      mediaId: mediaId ?? this.mediaId,
      sentAt: sentAt ?? this.sentAt,
      receivedAt: receivedAt ?? this.receivedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<int>(direction.value);
    }
    if (payloadType.present) {
      map['payload_type'] = Variable<int>(payloadType.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
    }
    if (senderNodeId.present) {
      map['sender_node_id'] = Variable<String>(senderNodeId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<int>(sentAt.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<int>(receivedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('chatId: $chatId, ')
          ..write('direction: $direction, ')
          ..write('payloadType: $payloadType, ')
          ..write('body: $body, ')
          ..write('senderName: $senderName, ')
          ..write('senderNodeId: $senderNodeId, ')
          ..write('mediaId: $mediaId, ')
          ..write('sentAt: $sentAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSizeMeta = const VerificationMeta(
    'totalSize',
  );
  @override
  late final GeneratedColumn<int> totalSize = GeneratedColumn<int>(
    'total_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chunkTotalMeta = const VerificationMeta(
    'chunkTotal',
  );
  @override
  late final GeneratedColumn<int> chunkTotal = GeneratedColumn<int>(
    'chunk_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<Uint8List> sha256 = GeneratedColumn<Uint8List>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completeMeta = const VerificationMeta(
    'complete',
  );
  @override
  late final GeneratedColumn<bool> complete = GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    mediaId,
    messageId,
    filePath,
    mimeType,
    totalSize,
    chunkTotal,
    sha256,
    complete,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('total_size')) {
      context.handle(
        _totalSizeMeta,
        totalSize.isAcceptableOrUnknown(data['total_size']!, _totalSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSizeMeta);
    }
    if (data.containsKey('chunk_total')) {
      context.handle(
        _chunkTotalMeta,
        chunkTotal.isAcceptableOrUnknown(data['chunk_total']!, _chunkTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkTotalMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  MediaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaRow(
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      totalSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_size'],
      )!,
      chunkTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_total'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}sha256'],
      )!,
      complete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }
}

class MediaRow extends DataClass implements Insertable<MediaRow> {
  final String mediaId;
  final String messageId;
  final String? filePath;
  final String mimeType;
  final int totalSize;
  final int chunkTotal;
  final Uint8List sha256;
  final bool complete;
  const MediaRow({
    required this.mediaId,
    required this.messageId,
    this.filePath,
    required this.mimeType,
    required this.totalSize,
    required this.chunkTotal,
    required this.sha256,
    required this.complete,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    map['message_id'] = Variable<String>(messageId);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    map['mime_type'] = Variable<String>(mimeType);
    map['total_size'] = Variable<int>(totalSize);
    map['chunk_total'] = Variable<int>(chunkTotal);
    map['sha256'] = Variable<Uint8List>(sha256);
    map['complete'] = Variable<bool>(complete);
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      mediaId: Value(mediaId),
      messageId: Value(messageId),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      mimeType: Value(mimeType),
      totalSize: Value(totalSize),
      chunkTotal: Value(chunkTotal),
      sha256: Value(sha256),
      complete: Value(complete),
    );
  }

  factory MediaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaRow(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      totalSize: serializer.fromJson<int>(json['totalSize']),
      chunkTotal: serializer.fromJson<int>(json['chunkTotal']),
      sha256: serializer.fromJson<Uint8List>(json['sha256']),
      complete: serializer.fromJson<bool>(json['complete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'messageId': serializer.toJson<String>(messageId),
      'filePath': serializer.toJson<String?>(filePath),
      'mimeType': serializer.toJson<String>(mimeType),
      'totalSize': serializer.toJson<int>(totalSize),
      'chunkTotal': serializer.toJson<int>(chunkTotal),
      'sha256': serializer.toJson<Uint8List>(sha256),
      'complete': serializer.toJson<bool>(complete),
    };
  }

  MediaRow copyWith({
    String? mediaId,
    String? messageId,
    Value<String?> filePath = const Value.absent(),
    String? mimeType,
    int? totalSize,
    int? chunkTotal,
    Uint8List? sha256,
    bool? complete,
  }) => MediaRow(
    mediaId: mediaId ?? this.mediaId,
    messageId: messageId ?? this.messageId,
    filePath: filePath.present ? filePath.value : this.filePath,
    mimeType: mimeType ?? this.mimeType,
    totalSize: totalSize ?? this.totalSize,
    chunkTotal: chunkTotal ?? this.chunkTotal,
    sha256: sha256 ?? this.sha256,
    complete: complete ?? this.complete,
  );
  MediaRow copyWithCompanion(MediaItemsCompanion data) {
    return MediaRow(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      totalSize: data.totalSize.present ? data.totalSize.value : this.totalSize,
      chunkTotal: data.chunkTotal.present
          ? data.chunkTotal.value
          : this.chunkTotal,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      complete: data.complete.present ? data.complete.value : this.complete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaRow(')
          ..write('mediaId: $mediaId, ')
          ..write('messageId: $messageId, ')
          ..write('filePath: $filePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('totalSize: $totalSize, ')
          ..write('chunkTotal: $chunkTotal, ')
          ..write('sha256: $sha256, ')
          ..write('complete: $complete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    mediaId,
    messageId,
    filePath,
    mimeType,
    totalSize,
    chunkTotal,
    $driftBlobEquality.hash(sha256),
    complete,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaRow &&
          other.mediaId == this.mediaId &&
          other.messageId == this.messageId &&
          other.filePath == this.filePath &&
          other.mimeType == this.mimeType &&
          other.totalSize == this.totalSize &&
          other.chunkTotal == this.chunkTotal &&
          $driftBlobEquality.equals(other.sha256, this.sha256) &&
          other.complete == this.complete);
}

class MediaItemsCompanion extends UpdateCompanion<MediaRow> {
  final Value<String> mediaId;
  final Value<String> messageId;
  final Value<String?> filePath;
  final Value<String> mimeType;
  final Value<int> totalSize;
  final Value<int> chunkTotal;
  final Value<Uint8List> sha256;
  final Value<bool> complete;
  final Value<int> rowid;
  const MediaItemsCompanion({
    this.mediaId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.totalSize = const Value.absent(),
    this.chunkTotal = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.complete = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    required String mediaId,
    required String messageId,
    this.filePath = const Value.absent(),
    required String mimeType,
    required int totalSize,
    required int chunkTotal,
    required Uint8List sha256,
    this.complete = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId),
       messageId = Value(messageId),
       mimeType = Value(mimeType),
       totalSize = Value(totalSize),
       chunkTotal = Value(chunkTotal),
       sha256 = Value(sha256);
  static Insertable<MediaRow> custom({
    Expression<String>? mediaId,
    Expression<String>? messageId,
    Expression<String>? filePath,
    Expression<String>? mimeType,
    Expression<int>? totalSize,
    Expression<int>? chunkTotal,
    Expression<Uint8List>? sha256,
    Expression<bool>? complete,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (messageId != null) 'message_id': messageId,
      if (filePath != null) 'file_path': filePath,
      if (mimeType != null) 'mime_type': mimeType,
      if (totalSize != null) 'total_size': totalSize,
      if (chunkTotal != null) 'chunk_total': chunkTotal,
      if (sha256 != null) 'sha256': sha256,
      if (complete != null) 'complete': complete,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaItemsCompanion copyWith({
    Value<String>? mediaId,
    Value<String>? messageId,
    Value<String?>? filePath,
    Value<String>? mimeType,
    Value<int>? totalSize,
    Value<int>? chunkTotal,
    Value<Uint8List>? sha256,
    Value<bool>? complete,
    Value<int>? rowid,
  }) {
    return MediaItemsCompanion(
      mediaId: mediaId ?? this.mediaId,
      messageId: messageId ?? this.messageId,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      totalSize: totalSize ?? this.totalSize,
      chunkTotal: chunkTotal ?? this.chunkTotal,
      sha256: sha256 ?? this.sha256,
      complete: complete ?? this.complete,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (totalSize.present) {
      map['total_size'] = Variable<int>(totalSize.value);
    }
    if (chunkTotal.present) {
      map['chunk_total'] = Variable<int>(chunkTotal.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<Uint8List>(sha256.value);
    }
    if (complete.present) {
      map['complete'] = Variable<bool>(complete.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('messageId: $messageId, ')
          ..write('filePath: $filePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('totalSize: $totalSize, ')
          ..write('chunkTotal: $chunkTotal, ')
          ..write('sha256: $sha256, ')
          ..write('complete: $complete, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaChunksTable extends MediaChunks
    with TableInfo<$MediaChunksTable, MediaChunkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaChunksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chunkIndexMeta = const VerificationMeta(
    'chunkIndex',
  );
  @override
  late final GeneratedColumn<int> chunkIndex = GeneratedColumn<int>(
    'chunk_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [mediaId, chunkIndex, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_chunks';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaChunkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('chunk_index')) {
      context.handle(
        _chunkIndexMeta,
        chunkIndex.isAcceptableOrUnknown(data['chunk_index']!, _chunkIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkIndexMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId, chunkIndex};
  @override
  MediaChunkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaChunkRow(
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      chunkIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_index'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  $MediaChunksTable createAlias(String alias) {
    return $MediaChunksTable(attachedDatabase, alias);
  }
}

class MediaChunkRow extends DataClass implements Insertable<MediaChunkRow> {
  final String mediaId;
  final int chunkIndex;
  final Uint8List data;
  const MediaChunkRow({
    required this.mediaId,
    required this.chunkIndex,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    map['chunk_index'] = Variable<int>(chunkIndex);
    map['data'] = Variable<Uint8List>(data);
    return map;
  }

  MediaChunksCompanion toCompanion(bool nullToAbsent) {
    return MediaChunksCompanion(
      mediaId: Value(mediaId),
      chunkIndex: Value(chunkIndex),
      data: Value(data),
    );
  }

  factory MediaChunkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaChunkRow(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      chunkIndex: serializer.fromJson<int>(json['chunkIndex']),
      data: serializer.fromJson<Uint8List>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'chunkIndex': serializer.toJson<int>(chunkIndex),
      'data': serializer.toJson<Uint8List>(data),
    };
  }

  MediaChunkRow copyWith({String? mediaId, int? chunkIndex, Uint8List? data}) =>
      MediaChunkRow(
        mediaId: mediaId ?? this.mediaId,
        chunkIndex: chunkIndex ?? this.chunkIndex,
        data: data ?? this.data,
      );
  MediaChunkRow copyWithCompanion(MediaChunksCompanion data) {
    return MediaChunkRow(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      chunkIndex: data.chunkIndex.present
          ? data.chunkIndex.value
          : this.chunkIndex,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaChunkRow(')
          ..write('mediaId: $mediaId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(mediaId, chunkIndex, $driftBlobEquality.hash(data));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaChunkRow &&
          other.mediaId == this.mediaId &&
          other.chunkIndex == this.chunkIndex &&
          $driftBlobEquality.equals(other.data, this.data));
}

class MediaChunksCompanion extends UpdateCompanion<MediaChunkRow> {
  final Value<String> mediaId;
  final Value<int> chunkIndex;
  final Value<Uint8List> data;
  final Value<int> rowid;
  const MediaChunksCompanion({
    this.mediaId = const Value.absent(),
    this.chunkIndex = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaChunksCompanion.insert({
    required String mediaId,
    required int chunkIndex,
    required Uint8List data,
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId),
       chunkIndex = Value(chunkIndex),
       data = Value(data);
  static Insertable<MediaChunkRow> custom({
    Expression<String>? mediaId,
    Expression<int>? chunkIndex,
    Expression<Uint8List>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (chunkIndex != null) 'chunk_index': chunkIndex,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaChunksCompanion copyWith({
    Value<String>? mediaId,
    Value<int>? chunkIndex,
    Value<Uint8List>? data,
    Value<int>? rowid,
  }) {
    return MediaChunksCompanion(
      mediaId: mediaId ?? this.mediaId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (chunkIndex.present) {
      map['chunk_index'] = Variable<int>(chunkIndex.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaChunksCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelayStoreTable extends RelayStore
    with TableInfo<$RelayStoreTable, RelayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelayStoreTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chunkIndexMeta = const VerificationMeta(
    'chunkIndex',
  );
  @override
  late final GeneratedColumn<int> chunkIndex = GeneratedColumn<int>(
    'chunk_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frameMeta = const VerificationMeta('frame');
  @override
  late final GeneratedColumn<Uint8List> frame = GeneratedColumn<Uint8List>(
    'frame',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientNodeIdMeta = const VerificationMeta(
    'recipientNodeId',
  );
  @override
  late final GeneratedColumn<String> recipientNodeId = GeneratedColumn<String>(
    'recipient_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ttlMeta = const VerificationMeta('ttl');
  @override
  late final GeneratedColumn<int> ttl = GeneratedColumn<int>(
    'ttl',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedAtMeta = const VerificationMeta(
    'storedAt',
  );
  @override
  late final GeneratedColumn<int> storedAt = GeneratedColumn<int>(
    'stored_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mineMeta = const VerificationMeta('mine');
  @override
  late final GeneratedColumn<bool> mine = GeneratedColumn<bool>(
    'mine',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mine" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    chunkIndex,
    frame,
    recipientNodeId,
    ttl,
    size,
    storedAt,
    mine,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relay_store';
  @override
  VerificationContext validateIntegrity(
    Insertable<RelayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('chunk_index')) {
      context.handle(
        _chunkIndexMeta,
        chunkIndex.isAcceptableOrUnknown(data['chunk_index']!, _chunkIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkIndexMeta);
    }
    if (data.containsKey('frame')) {
      context.handle(
        _frameMeta,
        frame.isAcceptableOrUnknown(data['frame']!, _frameMeta),
      );
    } else if (isInserting) {
      context.missing(_frameMeta);
    }
    if (data.containsKey('recipient_node_id')) {
      context.handle(
        _recipientNodeIdMeta,
        recipientNodeId.isAcceptableOrUnknown(
          data['recipient_node_id']!,
          _recipientNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientNodeIdMeta);
    }
    if (data.containsKey('ttl')) {
      context.handle(
        _ttlMeta,
        ttl.isAcceptableOrUnknown(data['ttl']!, _ttlMeta),
      );
    } else if (isInserting) {
      context.missing(_ttlMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('stored_at')) {
      context.handle(
        _storedAtMeta,
        storedAt.isAcceptableOrUnknown(data['stored_at']!, _storedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_storedAtMeta);
    }
    if (data.containsKey('mine')) {
      context.handle(
        _mineMeta,
        mine.isAcceptableOrUnknown(data['mine']!, _mineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, chunkIndex};
  @override
  RelayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RelayRow(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      chunkIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_index'],
      )!,
      frame: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}frame'],
      )!,
      recipientNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_node_id'],
      )!,
      ttl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ttl'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      storedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stored_at'],
      )!,
      mine: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mine'],
      )!,
    );
  }

  @override
  $RelayStoreTable createAlias(String alias) {
    return $RelayStoreTable(attachedDatabase, alias);
  }
}

class RelayRow extends DataClass implements Insertable<RelayRow> {
  final String messageId;
  final int chunkIndex;
  final Uint8List frame;
  final String recipientNodeId;
  final int ttl;
  final int size;
  final int storedAt;
  final bool mine;
  const RelayRow({
    required this.messageId,
    required this.chunkIndex,
    required this.frame,
    required this.recipientNodeId,
    required this.ttl,
    required this.size,
    required this.storedAt,
    required this.mine,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['chunk_index'] = Variable<int>(chunkIndex);
    map['frame'] = Variable<Uint8List>(frame);
    map['recipient_node_id'] = Variable<String>(recipientNodeId);
    map['ttl'] = Variable<int>(ttl);
    map['size'] = Variable<int>(size);
    map['stored_at'] = Variable<int>(storedAt);
    map['mine'] = Variable<bool>(mine);
    return map;
  }

  RelayStoreCompanion toCompanion(bool nullToAbsent) {
    return RelayStoreCompanion(
      messageId: Value(messageId),
      chunkIndex: Value(chunkIndex),
      frame: Value(frame),
      recipientNodeId: Value(recipientNodeId),
      ttl: Value(ttl),
      size: Value(size),
      storedAt: Value(storedAt),
      mine: Value(mine),
    );
  }

  factory RelayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RelayRow(
      messageId: serializer.fromJson<String>(json['messageId']),
      chunkIndex: serializer.fromJson<int>(json['chunkIndex']),
      frame: serializer.fromJson<Uint8List>(json['frame']),
      recipientNodeId: serializer.fromJson<String>(json['recipientNodeId']),
      ttl: serializer.fromJson<int>(json['ttl']),
      size: serializer.fromJson<int>(json['size']),
      storedAt: serializer.fromJson<int>(json['storedAt']),
      mine: serializer.fromJson<bool>(json['mine']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'chunkIndex': serializer.toJson<int>(chunkIndex),
      'frame': serializer.toJson<Uint8List>(frame),
      'recipientNodeId': serializer.toJson<String>(recipientNodeId),
      'ttl': serializer.toJson<int>(ttl),
      'size': serializer.toJson<int>(size),
      'storedAt': serializer.toJson<int>(storedAt),
      'mine': serializer.toJson<bool>(mine),
    };
  }

  RelayRow copyWith({
    String? messageId,
    int? chunkIndex,
    Uint8List? frame,
    String? recipientNodeId,
    int? ttl,
    int? size,
    int? storedAt,
    bool? mine,
  }) => RelayRow(
    messageId: messageId ?? this.messageId,
    chunkIndex: chunkIndex ?? this.chunkIndex,
    frame: frame ?? this.frame,
    recipientNodeId: recipientNodeId ?? this.recipientNodeId,
    ttl: ttl ?? this.ttl,
    size: size ?? this.size,
    storedAt: storedAt ?? this.storedAt,
    mine: mine ?? this.mine,
  );
  RelayRow copyWithCompanion(RelayStoreCompanion data) {
    return RelayRow(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      chunkIndex: data.chunkIndex.present
          ? data.chunkIndex.value
          : this.chunkIndex,
      frame: data.frame.present ? data.frame.value : this.frame,
      recipientNodeId: data.recipientNodeId.present
          ? data.recipientNodeId.value
          : this.recipientNodeId,
      ttl: data.ttl.present ? data.ttl.value : this.ttl,
      size: data.size.present ? data.size.value : this.size,
      storedAt: data.storedAt.present ? data.storedAt.value : this.storedAt,
      mine: data.mine.present ? data.mine.value : this.mine,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RelayRow(')
          ..write('messageId: $messageId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('frame: $frame, ')
          ..write('recipientNodeId: $recipientNodeId, ')
          ..write('ttl: $ttl, ')
          ..write('size: $size, ')
          ..write('storedAt: $storedAt, ')
          ..write('mine: $mine')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    chunkIndex,
    $driftBlobEquality.hash(frame),
    recipientNodeId,
    ttl,
    size,
    storedAt,
    mine,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RelayRow &&
          other.messageId == this.messageId &&
          other.chunkIndex == this.chunkIndex &&
          $driftBlobEquality.equals(other.frame, this.frame) &&
          other.recipientNodeId == this.recipientNodeId &&
          other.ttl == this.ttl &&
          other.size == this.size &&
          other.storedAt == this.storedAt &&
          other.mine == this.mine);
}

class RelayStoreCompanion extends UpdateCompanion<RelayRow> {
  final Value<String> messageId;
  final Value<int> chunkIndex;
  final Value<Uint8List> frame;
  final Value<String> recipientNodeId;
  final Value<int> ttl;
  final Value<int> size;
  final Value<int> storedAt;
  final Value<bool> mine;
  final Value<int> rowid;
  const RelayStoreCompanion({
    this.messageId = const Value.absent(),
    this.chunkIndex = const Value.absent(),
    this.frame = const Value.absent(),
    this.recipientNodeId = const Value.absent(),
    this.ttl = const Value.absent(),
    this.size = const Value.absent(),
    this.storedAt = const Value.absent(),
    this.mine = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelayStoreCompanion.insert({
    required String messageId,
    required int chunkIndex,
    required Uint8List frame,
    required String recipientNodeId,
    required int ttl,
    required int size,
    required int storedAt,
    this.mine = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       chunkIndex = Value(chunkIndex),
       frame = Value(frame),
       recipientNodeId = Value(recipientNodeId),
       ttl = Value(ttl),
       size = Value(size),
       storedAt = Value(storedAt);
  static Insertable<RelayRow> custom({
    Expression<String>? messageId,
    Expression<int>? chunkIndex,
    Expression<Uint8List>? frame,
    Expression<String>? recipientNodeId,
    Expression<int>? ttl,
    Expression<int>? size,
    Expression<int>? storedAt,
    Expression<bool>? mine,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (chunkIndex != null) 'chunk_index': chunkIndex,
      if (frame != null) 'frame': frame,
      if (recipientNodeId != null) 'recipient_node_id': recipientNodeId,
      if (ttl != null) 'ttl': ttl,
      if (size != null) 'size': size,
      if (storedAt != null) 'stored_at': storedAt,
      if (mine != null) 'mine': mine,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelayStoreCompanion copyWith({
    Value<String>? messageId,
    Value<int>? chunkIndex,
    Value<Uint8List>? frame,
    Value<String>? recipientNodeId,
    Value<int>? ttl,
    Value<int>? size,
    Value<int>? storedAt,
    Value<bool>? mine,
    Value<int>? rowid,
  }) {
    return RelayStoreCompanion(
      messageId: messageId ?? this.messageId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      frame: frame ?? this.frame,
      recipientNodeId: recipientNodeId ?? this.recipientNodeId,
      ttl: ttl ?? this.ttl,
      size: size ?? this.size,
      storedAt: storedAt ?? this.storedAt,
      mine: mine ?? this.mine,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (chunkIndex.present) {
      map['chunk_index'] = Variable<int>(chunkIndex.value);
    }
    if (frame.present) {
      map['frame'] = Variable<Uint8List>(frame.value);
    }
    if (recipientNodeId.present) {
      map['recipient_node_id'] = Variable<String>(recipientNodeId.value);
    }
    if (ttl.present) {
      map['ttl'] = Variable<int>(ttl.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (storedAt.present) {
      map['stored_at'] = Variable<int>(storedAt.value);
    }
    if (mine.present) {
      map['mine'] = Variable<bool>(mine.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelayStoreCompanion(')
          ..write('messageId: $messageId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('frame: $frame, ')
          ..write('recipientNodeId: $recipientNodeId, ')
          ..write('ttl: $ttl, ')
          ..write('size: $size, ')
          ..write('storedAt: $storedAt, ')
          ..write('mine: $mine, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeenEnvelopesTable extends SeenEnvelopes
    with TableInfo<$SeenEnvelopesTable, SeenRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeenEnvelopesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chunkIndexMeta = const VerificationMeta(
    'chunkIndex',
  );
  @override
  late final GeneratedColumn<int> chunkIndex = GeneratedColumn<int>(
    'chunk_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenAtMeta = const VerificationMeta('seenAt');
  @override
  late final GeneratedColumn<int> seenAt = GeneratedColumn<int>(
    'seen_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [messageId, chunkIndex, seenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seen_envelopes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeenRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('chunk_index')) {
      context.handle(
        _chunkIndexMeta,
        chunkIndex.isAcceptableOrUnknown(data['chunk_index']!, _chunkIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkIndexMeta);
    }
    if (data.containsKey('seen_at')) {
      context.handle(
        _seenAtMeta,
        seenAt.isAcceptableOrUnknown(data['seen_at']!, _seenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_seenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, chunkIndex};
  @override
  SeenRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeenRow(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      chunkIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_index'],
      )!,
      seenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seen_at'],
      )!,
    );
  }

  @override
  $SeenEnvelopesTable createAlias(String alias) {
    return $SeenEnvelopesTable(attachedDatabase, alias);
  }
}

class SeenRow extends DataClass implements Insertable<SeenRow> {
  final String messageId;
  final int chunkIndex;
  final int seenAt;
  const SeenRow({
    required this.messageId,
    required this.chunkIndex,
    required this.seenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['chunk_index'] = Variable<int>(chunkIndex);
    map['seen_at'] = Variable<int>(seenAt);
    return map;
  }

  SeenEnvelopesCompanion toCompanion(bool nullToAbsent) {
    return SeenEnvelopesCompanion(
      messageId: Value(messageId),
      chunkIndex: Value(chunkIndex),
      seenAt: Value(seenAt),
    );
  }

  factory SeenRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeenRow(
      messageId: serializer.fromJson<String>(json['messageId']),
      chunkIndex: serializer.fromJson<int>(json['chunkIndex']),
      seenAt: serializer.fromJson<int>(json['seenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'chunkIndex': serializer.toJson<int>(chunkIndex),
      'seenAt': serializer.toJson<int>(seenAt),
    };
  }

  SeenRow copyWith({String? messageId, int? chunkIndex, int? seenAt}) =>
      SeenRow(
        messageId: messageId ?? this.messageId,
        chunkIndex: chunkIndex ?? this.chunkIndex,
        seenAt: seenAt ?? this.seenAt,
      );
  SeenRow copyWithCompanion(SeenEnvelopesCompanion data) {
    return SeenRow(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      chunkIndex: data.chunkIndex.present
          ? data.chunkIndex.value
          : this.chunkIndex,
      seenAt: data.seenAt.present ? data.seenAt.value : this.seenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeenRow(')
          ..write('messageId: $messageId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('seenAt: $seenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, chunkIndex, seenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeenRow &&
          other.messageId == this.messageId &&
          other.chunkIndex == this.chunkIndex &&
          other.seenAt == this.seenAt);
}

class SeenEnvelopesCompanion extends UpdateCompanion<SeenRow> {
  final Value<String> messageId;
  final Value<int> chunkIndex;
  final Value<int> seenAt;
  final Value<int> rowid;
  const SeenEnvelopesCompanion({
    this.messageId = const Value.absent(),
    this.chunkIndex = const Value.absent(),
    this.seenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeenEnvelopesCompanion.insert({
    required String messageId,
    required int chunkIndex,
    required int seenAt,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       chunkIndex = Value(chunkIndex),
       seenAt = Value(seenAt);
  static Insertable<SeenRow> custom({
    Expression<String>? messageId,
    Expression<int>? chunkIndex,
    Expression<int>? seenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (chunkIndex != null) 'chunk_index': chunkIndex,
      if (seenAt != null) 'seen_at': seenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeenEnvelopesCompanion copyWith({
    Value<String>? messageId,
    Value<int>? chunkIndex,
    Value<int>? seenAt,
    Value<int>? rowid,
  }) {
    return SeenEnvelopesCompanion(
      messageId: messageId ?? this.messageId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      seenAt: seenAt ?? this.seenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (chunkIndex.present) {
      map['chunk_index'] = Variable<int>(chunkIndex.value);
    }
    if (seenAt.present) {
      map['seen_at'] = Variable<int>(seenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeenEnvelopesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('seenAt: $seenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, GroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<Uint8List> key = GeneratedColumn<Uint8List>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [groupId, name, key, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  GroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class GroupRow extends DataClass implements Insertable<GroupRow> {
  final String groupId;
  final String name;
  final Uint8List key;
  final int createdAt;
  const GroupRow({
    required this.groupId,
    required this.name,
    required this.key,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['name'] = Variable<String>(name);
    map['key'] = Variable<Uint8List>(key);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      groupId: Value(groupId),
      name: Value(name),
      key: Value(key),
      createdAt: Value(createdAt),
    );
  }

  factory GroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupRow(
      groupId: serializer.fromJson<String>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      key: serializer.fromJson<Uint8List>(json['key']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'name': serializer.toJson<String>(name),
      'key': serializer.toJson<Uint8List>(key),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  GroupRow copyWith({
    String? groupId,
    String? name,
    Uint8List? key,
    int? createdAt,
  }) => GroupRow(
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    key: key ?? this.key,
    createdAt: createdAt ?? this.createdAt,
  );
  GroupRow copyWithCompanion(GroupsCompanion data) {
    return GroupRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      key: data.key.present ? data.key.value : this.key,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupRow(')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('key: $key, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(groupId, name, $driftBlobEquality.hash(key), createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupRow &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          $driftBlobEquality.equals(other.key, this.key) &&
          other.createdAt == this.createdAt);
}

class GroupsCompanion extends UpdateCompanion<GroupRow> {
  final Value<String> groupId;
  final Value<String> name;
  final Value<Uint8List> key;
  final Value<int> createdAt;
  final Value<int> rowid;
  const GroupsCompanion({
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.key = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String groupId,
    required String name,
    required Uint8List key,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       name = Value(name),
       key = Value(key),
       createdAt = Value(createdAt);
  static Insertable<GroupRow> custom({
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<Uint8List>? key,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (key != null) 'key': key,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith({
    Value<String>? groupId,
    Value<String>? name,
    Value<Uint8List>? key,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return GroupsCompanion(
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      key: key ?? this.key,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (key.present) {
      map['key'] = Variable<Uint8List>(key.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('key: $key, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OwnPrekeysTable extends OwnPrekeys
    with TableInfo<$OwnPrekeysTable, OwnPrekeyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnPrekeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<String> keyId = GeneratedColumn<String>(
    'key_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _privMeta = const VerificationMeta('priv');
  @override
  late final GeneratedColumn<Uint8List> priv = GeneratedColumn<Uint8List>(
    'priv',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pubMeta = const VerificationMeta('pub');
  @override
  late final GeneratedColumn<Uint8List> pub = GeneratedColumn<Uint8List>(
    'pub',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuedToMeta = const VerificationMeta(
    'issuedTo',
  );
  @override
  late final GeneratedColumn<String> issuedTo = GeneratedColumn<String>(
    'issued_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [keyId, priv, pub, createdAt, issuedTo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'own_prekeys';
  @override
  VerificationContext validateIntegrity(
    Insertable<OwnPrekeyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key_id')) {
      context.handle(
        _keyIdMeta,
        keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_keyIdMeta);
    }
    if (data.containsKey('priv')) {
      context.handle(
        _privMeta,
        priv.isAcceptableOrUnknown(data['priv']!, _privMeta),
      );
    } else if (isInserting) {
      context.missing(_privMeta);
    }
    if (data.containsKey('pub')) {
      context.handle(
        _pubMeta,
        pub.isAcceptableOrUnknown(data['pub']!, _pubMeta),
      );
    } else if (isInserting) {
      context.missing(_pubMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('issued_to')) {
      context.handle(
        _issuedToMeta,
        issuedTo.isAcceptableOrUnknown(data['issued_to']!, _issuedToMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {keyId};
  @override
  OwnPrekeyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OwnPrekeyRow(
      keyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_id'],
      )!,
      priv: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}priv'],
      )!,
      pub: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}pub'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      issuedTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issued_to'],
      ),
    );
  }

  @override
  $OwnPrekeysTable createAlias(String alias) {
    return $OwnPrekeysTable(attachedDatabase, alias);
  }
}

class OwnPrekeyRow extends DataClass implements Insertable<OwnPrekeyRow> {
  final String keyId;
  final Uint8List priv;
  final Uint8List pub;
  final int createdAt;
  final String? issuedTo;
  const OwnPrekeyRow({
    required this.keyId,
    required this.priv,
    required this.pub,
    required this.createdAt,
    this.issuedTo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key_id'] = Variable<String>(keyId);
    map['priv'] = Variable<Uint8List>(priv);
    map['pub'] = Variable<Uint8List>(pub);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || issuedTo != null) {
      map['issued_to'] = Variable<String>(issuedTo);
    }
    return map;
  }

  OwnPrekeysCompanion toCompanion(bool nullToAbsent) {
    return OwnPrekeysCompanion(
      keyId: Value(keyId),
      priv: Value(priv),
      pub: Value(pub),
      createdAt: Value(createdAt),
      issuedTo: issuedTo == null && nullToAbsent
          ? const Value.absent()
          : Value(issuedTo),
    );
  }

  factory OwnPrekeyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OwnPrekeyRow(
      keyId: serializer.fromJson<String>(json['keyId']),
      priv: serializer.fromJson<Uint8List>(json['priv']),
      pub: serializer.fromJson<Uint8List>(json['pub']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      issuedTo: serializer.fromJson<String?>(json['issuedTo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'keyId': serializer.toJson<String>(keyId),
      'priv': serializer.toJson<Uint8List>(priv),
      'pub': serializer.toJson<Uint8List>(pub),
      'createdAt': serializer.toJson<int>(createdAt),
      'issuedTo': serializer.toJson<String?>(issuedTo),
    };
  }

  OwnPrekeyRow copyWith({
    String? keyId,
    Uint8List? priv,
    Uint8List? pub,
    int? createdAt,
    Value<String?> issuedTo = const Value.absent(),
  }) => OwnPrekeyRow(
    keyId: keyId ?? this.keyId,
    priv: priv ?? this.priv,
    pub: pub ?? this.pub,
    createdAt: createdAt ?? this.createdAt,
    issuedTo: issuedTo.present ? issuedTo.value : this.issuedTo,
  );
  OwnPrekeyRow copyWithCompanion(OwnPrekeysCompanion data) {
    return OwnPrekeyRow(
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      priv: data.priv.present ? data.priv.value : this.priv,
      pub: data.pub.present ? data.pub.value : this.pub,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      issuedTo: data.issuedTo.present ? data.issuedTo.value : this.issuedTo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OwnPrekeyRow(')
          ..write('keyId: $keyId, ')
          ..write('priv: $priv, ')
          ..write('pub: $pub, ')
          ..write('createdAt: $createdAt, ')
          ..write('issuedTo: $issuedTo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    keyId,
    $driftBlobEquality.hash(priv),
    $driftBlobEquality.hash(pub),
    createdAt,
    issuedTo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnPrekeyRow &&
          other.keyId == this.keyId &&
          $driftBlobEquality.equals(other.priv, this.priv) &&
          $driftBlobEquality.equals(other.pub, this.pub) &&
          other.createdAt == this.createdAt &&
          other.issuedTo == this.issuedTo);
}

class OwnPrekeysCompanion extends UpdateCompanion<OwnPrekeyRow> {
  final Value<String> keyId;
  final Value<Uint8List> priv;
  final Value<Uint8List> pub;
  final Value<int> createdAt;
  final Value<String?> issuedTo;
  final Value<int> rowid;
  const OwnPrekeysCompanion({
    this.keyId = const Value.absent(),
    this.priv = const Value.absent(),
    this.pub = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.issuedTo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OwnPrekeysCompanion.insert({
    required String keyId,
    required Uint8List priv,
    required Uint8List pub,
    required int createdAt,
    this.issuedTo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : keyId = Value(keyId),
       priv = Value(priv),
       pub = Value(pub),
       createdAt = Value(createdAt);
  static Insertable<OwnPrekeyRow> custom({
    Expression<String>? keyId,
    Expression<Uint8List>? priv,
    Expression<Uint8List>? pub,
    Expression<int>? createdAt,
    Expression<String>? issuedTo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (keyId != null) 'key_id': keyId,
      if (priv != null) 'priv': priv,
      if (pub != null) 'pub': pub,
      if (createdAt != null) 'created_at': createdAt,
      if (issuedTo != null) 'issued_to': issuedTo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OwnPrekeysCompanion copyWith({
    Value<String>? keyId,
    Value<Uint8List>? priv,
    Value<Uint8List>? pub,
    Value<int>? createdAt,
    Value<String?>? issuedTo,
    Value<int>? rowid,
  }) {
    return OwnPrekeysCompanion(
      keyId: keyId ?? this.keyId,
      priv: priv ?? this.priv,
      pub: pub ?? this.pub,
      createdAt: createdAt ?? this.createdAt,
      issuedTo: issuedTo ?? this.issuedTo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (keyId.present) {
      map['key_id'] = Variable<String>(keyId.value);
    }
    if (priv.present) {
      map['priv'] = Variable<Uint8List>(priv.value);
    }
    if (pub.present) {
      map['pub'] = Variable<Uint8List>(pub.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (issuedTo.present) {
      map['issued_to'] = Variable<String>(issuedTo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OwnPrekeysCompanion(')
          ..write('keyId: $keyId, ')
          ..write('priv: $priv, ')
          ..write('pub: $pub, ')
          ..write('createdAt: $createdAt, ')
          ..write('issuedTo: $issuedTo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeerPrekeysTable extends PeerPrekeys
    with TableInfo<$PeerPrekeysTable, PeerPrekeyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeerPrekeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<String> keyId = GeneratedColumn<String>(
    'key_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pubMeta = const VerificationMeta('pub');
  @override
  late final GeneratedColumn<Uint8List> pub = GeneratedColumn<Uint8List>(
    'pub',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<int> receivedAt = GeneratedColumn<int>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [nodeId, keyId, pub, receivedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'peer_prekeys';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeerPrekeyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('key_id')) {
      context.handle(
        _keyIdMeta,
        keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_keyIdMeta);
    }
    if (data.containsKey('pub')) {
      context.handle(
        _pubMeta,
        pub.isAcceptableOrUnknown(data['pub']!, _pubMeta),
      );
    } else if (isInserting) {
      context.missing(_pubMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nodeId, keyId};
  @override
  PeerPrekeyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeerPrekeyRow(
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      keyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_id'],
      )!,
      pub: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}pub'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_at'],
      )!,
    );
  }

  @override
  $PeerPrekeysTable createAlias(String alias) {
    return $PeerPrekeysTable(attachedDatabase, alias);
  }
}

class PeerPrekeyRow extends DataClass implements Insertable<PeerPrekeyRow> {
  final String nodeId;
  final String keyId;
  final Uint8List pub;
  final int receivedAt;
  const PeerPrekeyRow({
    required this.nodeId,
    required this.keyId,
    required this.pub,
    required this.receivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['node_id'] = Variable<String>(nodeId);
    map['key_id'] = Variable<String>(keyId);
    map['pub'] = Variable<Uint8List>(pub);
    map['received_at'] = Variable<int>(receivedAt);
    return map;
  }

  PeerPrekeysCompanion toCompanion(bool nullToAbsent) {
    return PeerPrekeysCompanion(
      nodeId: Value(nodeId),
      keyId: Value(keyId),
      pub: Value(pub),
      receivedAt: Value(receivedAt),
    );
  }

  factory PeerPrekeyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeerPrekeyRow(
      nodeId: serializer.fromJson<String>(json['nodeId']),
      keyId: serializer.fromJson<String>(json['keyId']),
      pub: serializer.fromJson<Uint8List>(json['pub']),
      receivedAt: serializer.fromJson<int>(json['receivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nodeId': serializer.toJson<String>(nodeId),
      'keyId': serializer.toJson<String>(keyId),
      'pub': serializer.toJson<Uint8List>(pub),
      'receivedAt': serializer.toJson<int>(receivedAt),
    };
  }

  PeerPrekeyRow copyWith({
    String? nodeId,
    String? keyId,
    Uint8List? pub,
    int? receivedAt,
  }) => PeerPrekeyRow(
    nodeId: nodeId ?? this.nodeId,
    keyId: keyId ?? this.keyId,
    pub: pub ?? this.pub,
    receivedAt: receivedAt ?? this.receivedAt,
  );
  PeerPrekeyRow copyWithCompanion(PeerPrekeysCompanion data) {
    return PeerPrekeyRow(
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      pub: data.pub.present ? data.pub.value : this.pub,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeerPrekeyRow(')
          ..write('nodeId: $nodeId, ')
          ..write('keyId: $keyId, ')
          ..write('pub: $pub, ')
          ..write('receivedAt: $receivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(nodeId, keyId, $driftBlobEquality.hash(pub), receivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeerPrekeyRow &&
          other.nodeId == this.nodeId &&
          other.keyId == this.keyId &&
          $driftBlobEquality.equals(other.pub, this.pub) &&
          other.receivedAt == this.receivedAt);
}

class PeerPrekeysCompanion extends UpdateCompanion<PeerPrekeyRow> {
  final Value<String> nodeId;
  final Value<String> keyId;
  final Value<Uint8List> pub;
  final Value<int> receivedAt;
  final Value<int> rowid;
  const PeerPrekeysCompanion({
    this.nodeId = const Value.absent(),
    this.keyId = const Value.absent(),
    this.pub = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeerPrekeysCompanion.insert({
    required String nodeId,
    required String keyId,
    required Uint8List pub,
    required int receivedAt,
    this.rowid = const Value.absent(),
  }) : nodeId = Value(nodeId),
       keyId = Value(keyId),
       pub = Value(pub),
       receivedAt = Value(receivedAt);
  static Insertable<PeerPrekeyRow> custom({
    Expression<String>? nodeId,
    Expression<String>? keyId,
    Expression<Uint8List>? pub,
    Expression<int>? receivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nodeId != null) 'node_id': nodeId,
      if (keyId != null) 'key_id': keyId,
      if (pub != null) 'pub': pub,
      if (receivedAt != null) 'received_at': receivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeerPrekeysCompanion copyWith({
    Value<String>? nodeId,
    Value<String>? keyId,
    Value<Uint8List>? pub,
    Value<int>? receivedAt,
    Value<int>? rowid,
  }) {
    return PeerPrekeysCompanion(
      nodeId: nodeId ?? this.nodeId,
      keyId: keyId ?? this.keyId,
      pub: pub ?? this.pub,
      receivedAt: receivedAt ?? this.receivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (keyId.present) {
      map['key_id'] = Variable<String>(keyId.value);
    }
    if (pub.present) {
      map['pub'] = Variable<Uint8List>(pub.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<int>(receivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeerPrekeysCompanion(')
          ..write('nodeId: $nodeId, ')
          ..write('keyId: $keyId, ')
          ..write('pub: $pub, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MessyDatabase extends GeneratedDatabase {
  _$MessyDatabase(QueryExecutor e) : super(e);
  $MessyDatabaseManager get managers => $MessyDatabaseManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $ChatsTable chats = $ChatsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $MediaChunksTable mediaChunks = $MediaChunksTable(this);
  late final $RelayStoreTable relayStore = $RelayStoreTable(this);
  late final $SeenEnvelopesTable seenEnvelopes = $SeenEnvelopesTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $OwnPrekeysTable ownPrekeys = $OwnPrekeysTable(this);
  late final $PeerPrekeysTable peerPrekeys = $PeerPrekeysTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    contacts,
    chats,
    messages,
    mediaItems,
    mediaChunks,
    relayStore,
    seenEnvelopes,
    groups,
    ownPrekeys,
    peerPrekeys,
    settings,
  ];
}

typedef $$ContactsTableCreateCompanionBuilder =
    ContactsCompanion Function({
      required String nodeId,
      required Uint8List x25519Pub,
      required Uint8List ed25519Pub,
      required String displayName,
      Value<bool> verified,
      required String addedVia,
      Value<int?> lastSeenAt,
      Value<int> rowid,
    });
typedef $$ContactsTableUpdateCompanionBuilder =
    ContactsCompanion Function({
      Value<String> nodeId,
      Value<Uint8List> x25519Pub,
      Value<Uint8List> ed25519Pub,
      Value<String> displayName,
      Value<bool> verified,
      Value<String> addedVia,
      Value<int?> lastSeenAt,
      Value<int> rowid,
    });

class $$ContactsTableFilterComposer
    extends Composer<_$MessyDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get x25519Pub => $composableBuilder(
    column: $table.x25519Pub,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get ed25519Pub => $composableBuilder(
    column: $table.ed25519Pub,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addedVia => $composableBuilder(
    column: $table.addedVia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactsTableOrderingComposer
    extends Composer<_$MessyDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get x25519Pub => $composableBuilder(
    column: $table.x25519Pub,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get ed25519Pub => $composableBuilder(
    column: $table.ed25519Pub,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addedVia => $composableBuilder(
    column: $table.addedVia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$MessyDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<Uint8List> get x25519Pub =>
      $composableBuilder(column: $table.x25519Pub, builder: (column) => column);

  GeneratedColumn<Uint8List> get ed25519Pub => $composableBuilder(
    column: $table.ed25519Pub,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get verified =>
      $composableBuilder(column: $table.verified, builder: (column) => column);

  GeneratedColumn<String> get addedVia =>
      $composableBuilder(column: $table.addedVia, builder: (column) => column);

  GeneratedColumn<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$MessyDatabase,
          $ContactsTable,
          ContactRow,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (
            ContactRow,
            BaseReferences<_$MessyDatabase, $ContactsTable, ContactRow>,
          ),
          ContactRow,
          PrefetchHooks Function()
        > {
  $$ContactsTableTableManager(_$MessyDatabase db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> nodeId = const Value.absent(),
                Value<Uint8List> x25519Pub = const Value.absent(),
                Value<Uint8List> ed25519Pub = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<bool> verified = const Value.absent(),
                Value<String> addedVia = const Value.absent(),
                Value<int?> lastSeenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion(
                nodeId: nodeId,
                x25519Pub: x25519Pub,
                ed25519Pub: ed25519Pub,
                displayName: displayName,
                verified: verified,
                addedVia: addedVia,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nodeId,
                required Uint8List x25519Pub,
                required Uint8List ed25519Pub,
                required String displayName,
                Value<bool> verified = const Value.absent(),
                required String addedVia,
                Value<int?> lastSeenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion.insert(
                nodeId: nodeId,
                x25519Pub: x25519Pub,
                ed25519Pub: ed25519Pub,
                displayName: displayName,
                verified: verified,
                addedVia: addedVia,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$MessyDatabase,
      $ContactsTable,
      ContactRow,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (ContactRow, BaseReferences<_$MessyDatabase, $ContactsTable, ContactRow>),
      ContactRow,
      PrefetchHooks Function()
    >;
typedef $$ChatsTableCreateCompanionBuilder =
    ChatsCompanion Function({
      required String chatId,
      Value<String?> nodeId,
      Value<int?> disappearAfterSecs,
      Value<int> rowid,
    });
typedef $$ChatsTableUpdateCompanionBuilder =
    ChatsCompanion Function({
      Value<String> chatId,
      Value<String?> nodeId,
      Value<int?> disappearAfterSecs,
      Value<int> rowid,
    });

class $$ChatsTableFilterComposer
    extends Composer<_$MessyDatabase, $ChatsTable> {
  $$ChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get disappearAfterSecs => $composableBuilder(
    column: $table.disappearAfterSecs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatsTableOrderingComposer
    extends Composer<_$MessyDatabase, $ChatsTable> {
  $$ChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get disappearAfterSecs => $composableBuilder(
    column: $table.disappearAfterSecs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatsTableAnnotationComposer
    extends Composer<_$MessyDatabase, $ChatsTable> {
  $$ChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<int> get disappearAfterSecs => $composableBuilder(
    column: $table.disappearAfterSecs,
    builder: (column) => column,
  );
}

class $$ChatsTableTableManager
    extends
        RootTableManager<
          _$MessyDatabase,
          $ChatsTable,
          ChatRow,
          $$ChatsTableFilterComposer,
          $$ChatsTableOrderingComposer,
          $$ChatsTableAnnotationComposer,
          $$ChatsTableCreateCompanionBuilder,
          $$ChatsTableUpdateCompanionBuilder,
          (ChatRow, BaseReferences<_$MessyDatabase, $ChatsTable, ChatRow>),
          ChatRow,
          PrefetchHooks Function()
        > {
  $$ChatsTableTableManager(_$MessyDatabase db, $ChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> chatId = const Value.absent(),
                Value<String?> nodeId = const Value.absent(),
                Value<int?> disappearAfterSecs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatsCompanion(
                chatId: chatId,
                nodeId: nodeId,
                disappearAfterSecs: disappearAfterSecs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chatId,
                Value<String?> nodeId = const Value.absent(),
                Value<int?> disappearAfterSecs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatsCompanion.insert(
                chatId: chatId,
                nodeId: nodeId,
                disappearAfterSecs: disappearAfterSecs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$MessyDatabase,
      $ChatsTable,
      ChatRow,
      $$ChatsTableFilterComposer,
      $$ChatsTableOrderingComposer,
      $$ChatsTableAnnotationComposer,
      $$ChatsTableCreateCompanionBuilder,
      $$ChatsTableUpdateCompanionBuilder,
      (ChatRow, BaseReferences<_$MessyDatabase, $ChatsTable, ChatRow>),
      ChatRow,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String messageId,
      required String chatId,
      required int direction,
      required int payloadType,
      required String body,
      Value<String?> senderName,
      Value<String?> senderNodeId,
      Value<String?> mediaId,
      required int sentAt,
      Value<int?> receivedAt,
      Value<int?> expiresAt,
      required int status,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> messageId,
      Value<String> chatId,
      Value<int> direction,
      Value<int> payloadType,
      Value<String> body,
      Value<String?> senderName,
      Value<String?> senderNodeId,
      Value<String?> mediaId,
      Value<int> sentAt,
      Value<int?> receivedAt,
      Value<int?> expiresAt,
      Value<int> status,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$MessyDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderNodeId => $composableBuilder(
    column: $table.senderNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$MessyDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderNodeId => $composableBuilder(
    column: $table.senderNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$MessyDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderNodeId => $composableBuilder(
    column: $table.senderNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$MessyDatabase,
          $MessagesTable,
          MessageRow,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (
            MessageRow,
            BaseReferences<_$MessyDatabase, $MessagesTable, MessageRow>,
          ),
          MessageRow,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$MessyDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> chatId = const Value.absent(),
                Value<int> direction = const Value.absent(),
                Value<int> payloadType = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> senderName = const Value.absent(),
                Value<String?> senderNodeId = const Value.absent(),
                Value<String?> mediaId = const Value.absent(),
                Value<int> sentAt = const Value.absent(),
                Value<int?> receivedAt = const Value.absent(),
                Value<int?> expiresAt = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                messageId: messageId,
                chatId: chatId,
                direction: direction,
                payloadType: payloadType,
                body: body,
                senderName: senderName,
                senderNodeId: senderNodeId,
                mediaId: mediaId,
                sentAt: sentAt,
                receivedAt: receivedAt,
                expiresAt: expiresAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String chatId,
                required int direction,
                required int payloadType,
                required String body,
                Value<String?> senderName = const Value.absent(),
                Value<String?> senderNodeId = const Value.absent(),
                Value<String?> mediaId = const Value.absent(),
                required int sentAt,
                Value<int?> receivedAt = const Value.absent(),
                Value<int?> expiresAt = const Value.absent(),
                required int status,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                messageId: messageId,
                chatId: chatId,
                direction: direction,
                payloadType: payloadType,
                body: body,
                senderName: senderName,
                senderNodeId: senderNodeId,
                mediaId: mediaId,
                sentAt: sentAt,
                receivedAt: receivedAt,
                expiresAt: expiresAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$MessyDatabase,
      $MessagesTable,
      MessageRow,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (MessageRow, BaseReferences<_$MessyDatabase, $MessagesTable, MessageRow>),
      MessageRow,
      PrefetchHooks Function()
    >;
typedef $$MediaItemsTableCreateCompanionBuilder =
    MediaItemsCompanion Function({
      required String mediaId,
      required String messageId,
      Value<String?> filePath,
      required String mimeType,
      required int totalSize,
      required int chunkTotal,
      required Uint8List sha256,
      Value<bool> complete,
      Value<int> rowid,
    });
typedef $$MediaItemsTableUpdateCompanionBuilder =
    MediaItemsCompanion Function({
      Value<String> mediaId,
      Value<String> messageId,
      Value<String?> filePath,
      Value<String> mimeType,
      Value<int> totalSize,
      Value<int> chunkTotal,
      Value<Uint8List> sha256,
      Value<bool> complete,
      Value<int> rowid,
    });

class $$MediaItemsTableFilterComposer
    extends Composer<_$MessyDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkTotal => $composableBuilder(
    column: $table.chunkTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$MessyDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkTotal => $composableBuilder(
    column: $table.chunkTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$MessyDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get totalSize =>
      $composableBuilder(column: $table.totalSize, builder: (column) => column);

  GeneratedColumn<int> get chunkTotal => $composableBuilder(
    column: $table.chunkTotal,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);
}

class $$MediaItemsTableTableManager
    extends
        RootTableManager<
          _$MessyDatabase,
          $MediaItemsTable,
          MediaRow,
          $$MediaItemsTableFilterComposer,
          $$MediaItemsTableOrderingComposer,
          $$MediaItemsTableAnnotationComposer,
          $$MediaItemsTableCreateCompanionBuilder,
          $$MediaItemsTableUpdateCompanionBuilder,
          (
            MediaRow,
            BaseReferences<_$MessyDatabase, $MediaItemsTable, MediaRow>,
          ),
          MediaRow,
          PrefetchHooks Function()
        > {
  $$MediaItemsTableTableManager(_$MessyDatabase db, $MediaItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mediaId = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> totalSize = const Value.absent(),
                Value<int> chunkTotal = const Value.absent(),
                Value<Uint8List> sha256 = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsCompanion(
                mediaId: mediaId,
                messageId: messageId,
                filePath: filePath,
                mimeType: mimeType,
                totalSize: totalSize,
                chunkTotal: chunkTotal,
                sha256: sha256,
                complete: complete,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mediaId,
                required String messageId,
                Value<String?> filePath = const Value.absent(),
                required String mimeType,
                required int totalSize,
                required int chunkTotal,
                required Uint8List sha256,
                Value<bool> complete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsCompanion.insert(
                mediaId: mediaId,
                messageId: messageId,
                filePath: filePath,
                mimeType: mimeType,
                totalSize: totalSize,
                chunkTotal: chunkTotal,
                sha256: sha256,
                complete: complete,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$MessyDatabase,
      $MediaItemsTable,
      MediaRow,
      $$MediaItemsTableFilterComposer,
      $$MediaItemsTableOrderingComposer,
      $$MediaItemsTableAnnotationComposer,
      $$MediaItemsTableCreateCompanionBuilder,
      $$MediaItemsTableUpdateCompanionBuilder,
      (MediaRow, BaseReferences<_$MessyDatabase, $MediaItemsTable, MediaRow>),
      MediaRow,
      PrefetchHooks Function()
    >;
typedef $$MediaChunksTableCreateCompanionBuilder =
    MediaChunksCompanion Function({
      required String mediaId,
      required int chunkIndex,
      required Uint8List data,
      Value<int> rowid,
    });
typedef $$MediaChunksTableUpdateCompanionBuilder =
    MediaChunksCompanion Function({
      Value<String> mediaId,
      Value<int> chunkIndex,
      Value<Uint8List> data,
      Value<int> rowid,
    });

class $$MediaChunksTableFilterComposer
    extends Composer<_$MessyDatabase, $MediaChunksTable> {
  $$MediaChunksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaChunksTableOrderingComposer
    extends Composer<_$MessyDatabase, $MediaChunksTable> {
  $$MediaChunksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaChunksTableAnnotationComposer
    extends Composer<_$MessyDatabase, $MediaChunksTable> {
  $$MediaChunksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$MediaChunksTableTableManager
    extends
        RootTableManager<
          _$MessyDatabase,
          $MediaChunksTable,
          MediaChunkRow,
          $$MediaChunksTableFilterComposer,
          $$MediaChunksTableOrderingComposer,
          $$MediaChunksTableAnnotationComposer,
          $$MediaChunksTableCreateCompanionBuilder,
          $$MediaChunksTableUpdateCompanionBuilder,
          (
            MediaChunkRow,
            BaseReferences<_$MessyDatabase, $MediaChunksTable, MediaChunkRow>,
          ),
          MediaChunkRow,
          PrefetchHooks Function()
        > {
  $$MediaChunksTableTableManager(_$MessyDatabase db, $MediaChunksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaChunksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaChunksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaChunksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mediaId = const Value.absent(),
                Value<int> chunkIndex = const Value.absent(),
                Value<Uint8List> data = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaChunksCompanion(
                mediaId: mediaId,
                chunkIndex: chunkIndex,
                data: data,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mediaId,
                required int chunkIndex,
                required Uint8List data,
                Value<int> rowid = const Value.absent(),
              }) => MediaChunksCompanion.insert(
                mediaId: mediaId,
                chunkIndex: chunkIndex,
                data: data,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaChunksTableProcessedTableManager =
    ProcessedTableManager<
      _$MessyDatabase,
      $MediaChunksTable,
      MediaChunkRow,
      $$MediaChunksTableFilterComposer,
      $$MediaChunksTableOrderingComposer,
      $$MediaChunksTableAnnotationComposer,
      $$MediaChunksTableCreateCompanionBuilder,
      $$MediaChunksTableUpdateCompanionBuilder,
      (
        MediaChunkRow,
        BaseReferences<_$MessyDatabase, $MediaChunksTable, MediaChunkRow>,
      ),
      MediaChunkRow,
      PrefetchHooks Function()
    >;
typedef $$RelayStoreTableCreateCompanionBuilder =
    RelayStoreCompanion Function({
      required String messageId,
      required int chunkIndex,
      required Uint8List frame,
      required String recipientNodeId,
      required int ttl,
      required int size,
      required int storedAt,
      Value<bool> mine,
      Value<int> rowid,
    });
typedef $$RelayStoreTableUpdateCompanionBuilder =
    RelayStoreCompanion Function({
      Value<String> messageId,
      Value<int> chunkIndex,
      Value<Uint8List> frame,
      Value<String> recipientNodeId,
      Value<int> ttl,
      Value<int> size,
      Value<int> storedAt,
      Value<bool> mine,
      Value<int> rowid,
    });

class $$RelayStoreTableFilterComposer
    extends Composer<_$MessyDatabase, $RelayStoreTable> {
  $$RelayStoreTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get frame => $composableBuilder(
    column: $table.frame,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientNodeId => $composableBuilder(
    column: $table.recipientNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ttl => $composableBuilder(
    column: $table.ttl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get storedAt => $composableBuilder(
    column: $table.storedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mine => $composableBuilder(
    column: $table.mine,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RelayStoreTableOrderingComposer
    extends Composer<_$MessyDatabase, $RelayStoreTable> {
  $$RelayStoreTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get frame => $composableBuilder(
    column: $table.frame,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientNodeId => $composableBuilder(
    column: $table.recipientNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ttl => $composableBuilder(
    column: $table.ttl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storedAt => $composableBuilder(
    column: $table.storedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mine => $composableBuilder(
    column: $table.mine,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RelayStoreTableAnnotationComposer
    extends Composer<_$MessyDatabase, $RelayStoreTable> {
  $$RelayStoreTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get frame =>
      $composableBuilder(column: $table.frame, builder: (column) => column);

  GeneratedColumn<String> get recipientNodeId => $composableBuilder(
    column: $table.recipientNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ttl =>
      $composableBuilder(column: $table.ttl, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<int> get storedAt =>
      $composableBuilder(column: $table.storedAt, builder: (column) => column);

  GeneratedColumn<bool> get mine =>
      $composableBuilder(column: $table.mine, builder: (column) => column);
}

class $$RelayStoreTableTableManager
    extends
        RootTableManager<
          _$MessyDatabase,
          $RelayStoreTable,
          RelayRow,
          $$RelayStoreTableFilterComposer,
          $$RelayStoreTableOrderingComposer,
          $$RelayStoreTableAnnotationComposer,
          $$RelayStoreTableCreateCompanionBuilder,
          $$RelayStoreTableUpdateCompanionBuilder,
          (
            RelayRow,
            BaseReferences<_$MessyDatabase, $RelayStoreTable, RelayRow>,
          ),
          RelayRow,
          PrefetchHooks Function()
        > {
  $$RelayStoreTableTableManager(_$MessyDatabase db, $RelayStoreTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelayStoreTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RelayStoreTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RelayStoreTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<int> chunkIndex = const Value.absent(),
                Value<Uint8List> frame = const Value.absent(),
                Value<String> recipientNodeId = const Value.absent(),
                Value<int> ttl = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<int> storedAt = const Value.absent(),
                Value<bool> mine = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelayStoreCompanion(
                messageId: messageId,
                chunkIndex: chunkIndex,
                frame: frame,
                recipientNodeId: recipientNodeId,
                ttl: ttl,
                size: size,
                storedAt: storedAt,
                mine: mine,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required int chunkIndex,
                required Uint8List frame,
                required String recipientNodeId,
                required int ttl,
                required int size,
                required int storedAt,
                Value<bool> mine = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelayStoreCompanion.insert(
                messageId: messageId,
                chunkIndex: chunkIndex,
                frame: frame,
                recipientNodeId: recipientNodeId,
                ttl: ttl,
                size: size,
                storedAt: storedAt,
                mine: mine,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RelayStoreTableProcessedTableManager =
    ProcessedTableManager<
      _$MessyDatabase,
      $RelayStoreTable,
      RelayRow,
      $$RelayStoreTableFilterComposer,
      $$RelayStoreTableOrderingComposer,
      $$RelayStoreTableAnnotationComposer,
      $$RelayStoreTableCreateCompanionBuilder,
      $$RelayStoreTableUpdateCompanionBuilder,
      (RelayRow, BaseReferences<_$MessyDatabase, $RelayStoreTable, RelayRow>),
      RelayRow,
      PrefetchHooks Function()
    >;
typedef $$SeenEnvelopesTableCreateCompanionBuilder =
    SeenEnvelopesCompanion Function({
      required String messageId,
      required int chunkIndex,
      required int seenAt,
      Value<int> rowid,
    });
typedef $$SeenEnvelopesTableUpdateCompanionBuilder =
    SeenEnvelopesCompanion Function({
      Value<String> messageId,
      Value<int> chunkIndex,
      Value<int> seenAt,
      Value<int> rowid,
    });

class $$SeenEnvelopesTableFilterComposer
    extends Composer<_$MessyDatabase, $SeenEnvelopesTable> {
  $$SeenEnvelopesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeenEnvelopesTableOrderingComposer
    extends Composer<_$MessyDatabase, $SeenEnvelopesTable> {
  $$SeenEnvelopesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeenEnvelopesTableAnnotationComposer
    extends Composer<_$MessyDatabase, $SeenEnvelopesTable> {
  $$SeenEnvelopesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seenAt =>
      $composableBuilder(column: $table.seenAt, builder: (column) => column);
}

class $$SeenEnvelopesTableTableManager
    extends
        RootTableManager<
          _$MessyDatabase,
          $SeenEnvelopesTable,
          SeenRow,
          $$SeenEnvelopesTableFilterComposer,
          $$SeenEnvelopesTableOrderingComposer,
          $$SeenEnvelopesTableAnnotationComposer,
          $$SeenEnvelopesTableCreateCompanionBuilder,
          $$SeenEnvelopesTableUpdateCompanionBuilder,
          (
            SeenRow,
            BaseReferences<_$MessyDatabase, $SeenEnvelopesTable, SeenRow>,
          ),
          SeenRow,
          PrefetchHooks Function()
        > {
  $$SeenEnvelopesTableTableManager(
    _$MessyDatabase db,
    $SeenEnvelopesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeenEnvelopesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeenEnvelopesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeenEnvelopesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<int> chunkIndex = const Value.absent(),
                Value<int> seenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeenEnvelopesCompanion(
                messageId: messageId,
                chunkIndex: chunkIndex,
                seenAt: seenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required int chunkIndex,
                required int seenAt,
                Value<int> rowid = const Value.absent(),
              }) => SeenEnvelopesCompanion.insert(
                messageId: messageId,
                chunkIndex: chunkIndex,
                seenAt: seenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeenEnvelopesTableProcessedTableManager =
    ProcessedTableManager<
      _$MessyDatabase,
      $SeenEnvelopesTable,
      SeenRow,
      $$SeenEnvelopesTableFilterComposer,
      $$SeenEnvelopesTableOrderingComposer,
      $$SeenEnvelopesTableAnnotationComposer,
      $$SeenEnvelopesTableCreateCompanionBuilder,
      $$SeenEnvelopesTableUpdateCompanionBuilder,
      (SeenRow, BaseReferences<_$MessyDatabase, $SeenEnvelopesTable, SeenRow>),
      SeenRow,
      PrefetchHooks Function()
    >;
typedef $$GroupsTableCreateCompanionBuilder =
    GroupsCompanion Function({
      required String groupId,
      required String name,
      required Uint8List key,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$GroupsTableUpdateCompanionBuilder =
    GroupsCompanion Function({
      Value<String> groupId,
      Value<String> name,
      Value<Uint8List> key,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$GroupsTableFilterComposer
    extends Composer<_$MessyDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupsTableOrderingComposer
    extends Composer<_$MessyDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$MessyDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<Uint8List> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$MessyDatabase,
          $GroupsTable,
          GroupRow,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (GroupRow, BaseReferences<_$MessyDatabase, $GroupsTable, GroupRow>),
          GroupRow,
          PrefetchHooks Function()
        > {
  $$GroupsTableTableManager(_$MessyDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<Uint8List> key = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion(
                groupId: groupId,
                name: name,
                key: key,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String name,
                required Uint8List key,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion.insert(
                groupId: groupId,
                name: name,
                key: key,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$MessyDatabase,
      $GroupsTable,
      GroupRow,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (GroupRow, BaseReferences<_$MessyDatabase, $GroupsTable, GroupRow>),
      GroupRow,
      PrefetchHooks Function()
    >;
typedef $$OwnPrekeysTableCreateCompanionBuilder =
    OwnPrekeysCompanion Function({
      required String keyId,
      required Uint8List priv,
      required Uint8List pub,
      required int createdAt,
      Value<String?> issuedTo,
      Value<int> rowid,
    });
typedef $$OwnPrekeysTableUpdateCompanionBuilder =
    OwnPrekeysCompanion Function({
      Value<String> keyId,
      Value<Uint8List> priv,
      Value<Uint8List> pub,
      Value<int> createdAt,
      Value<String?> issuedTo,
      Value<int> rowid,
    });

class $$OwnPrekeysTableFilterComposer
    extends Composer<_$MessyDatabase, $OwnPrekeysTable> {
  $$OwnPrekeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get keyId => $composableBuilder(
    column: $table.keyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get priv => $composableBuilder(
    column: $table.priv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get pub => $composableBuilder(
    column: $table.pub,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuedTo => $composableBuilder(
    column: $table.issuedTo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OwnPrekeysTableOrderingComposer
    extends Composer<_$MessyDatabase, $OwnPrekeysTable> {
  $$OwnPrekeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get keyId => $composableBuilder(
    column: $table.keyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get priv => $composableBuilder(
    column: $table.priv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get pub => $composableBuilder(
    column: $table.pub,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuedTo => $composableBuilder(
    column: $table.issuedTo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OwnPrekeysTableAnnotationComposer
    extends Composer<_$MessyDatabase, $OwnPrekeysTable> {
  $$OwnPrekeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get keyId =>
      $composableBuilder(column: $table.keyId, builder: (column) => column);

  GeneratedColumn<Uint8List> get priv =>
      $composableBuilder(column: $table.priv, builder: (column) => column);

  GeneratedColumn<Uint8List> get pub =>
      $composableBuilder(column: $table.pub, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get issuedTo =>
      $composableBuilder(column: $table.issuedTo, builder: (column) => column);
}

class $$OwnPrekeysTableTableManager
    extends
        RootTableManager<
          _$MessyDatabase,
          $OwnPrekeysTable,
          OwnPrekeyRow,
          $$OwnPrekeysTableFilterComposer,
          $$OwnPrekeysTableOrderingComposer,
          $$OwnPrekeysTableAnnotationComposer,
          $$OwnPrekeysTableCreateCompanionBuilder,
          $$OwnPrekeysTableUpdateCompanionBuilder,
          (
            OwnPrekeyRow,
            BaseReferences<_$MessyDatabase, $OwnPrekeysTable, OwnPrekeyRow>,
          ),
          OwnPrekeyRow,
          PrefetchHooks Function()
        > {
  $$OwnPrekeysTableTableManager(_$MessyDatabase db, $OwnPrekeysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OwnPrekeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OwnPrekeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OwnPrekeysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> keyId = const Value.absent(),
                Value<Uint8List> priv = const Value.absent(),
                Value<Uint8List> pub = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String?> issuedTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OwnPrekeysCompanion(
                keyId: keyId,
                priv: priv,
                pub: pub,
                createdAt: createdAt,
                issuedTo: issuedTo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String keyId,
                required Uint8List priv,
                required Uint8List pub,
                required int createdAt,
                Value<String?> issuedTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OwnPrekeysCompanion.insert(
                keyId: keyId,
                priv: priv,
                pub: pub,
                createdAt: createdAt,
                issuedTo: issuedTo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OwnPrekeysTableProcessedTableManager =
    ProcessedTableManager<
      _$MessyDatabase,
      $OwnPrekeysTable,
      OwnPrekeyRow,
      $$OwnPrekeysTableFilterComposer,
      $$OwnPrekeysTableOrderingComposer,
      $$OwnPrekeysTableAnnotationComposer,
      $$OwnPrekeysTableCreateCompanionBuilder,
      $$OwnPrekeysTableUpdateCompanionBuilder,
      (
        OwnPrekeyRow,
        BaseReferences<_$MessyDatabase, $OwnPrekeysTable, OwnPrekeyRow>,
      ),
      OwnPrekeyRow,
      PrefetchHooks Function()
    >;
typedef $$PeerPrekeysTableCreateCompanionBuilder =
    PeerPrekeysCompanion Function({
      required String nodeId,
      required String keyId,
      required Uint8List pub,
      required int receivedAt,
      Value<int> rowid,
    });
typedef $$PeerPrekeysTableUpdateCompanionBuilder =
    PeerPrekeysCompanion Function({
      Value<String> nodeId,
      Value<String> keyId,
      Value<Uint8List> pub,
      Value<int> receivedAt,
      Value<int> rowid,
    });

class $$PeerPrekeysTableFilterComposer
    extends Composer<_$MessyDatabase, $PeerPrekeysTable> {
  $$PeerPrekeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyId => $composableBuilder(
    column: $table.keyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get pub => $composableBuilder(
    column: $table.pub,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeerPrekeysTableOrderingComposer
    extends Composer<_$MessyDatabase, $PeerPrekeysTable> {
  $$PeerPrekeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyId => $composableBuilder(
    column: $table.keyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get pub => $composableBuilder(
    column: $table.pub,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeerPrekeysTableAnnotationComposer
    extends Composer<_$MessyDatabase, $PeerPrekeysTable> {
  $$PeerPrekeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get keyId =>
      $composableBuilder(column: $table.keyId, builder: (column) => column);

  GeneratedColumn<Uint8List> get pub =>
      $composableBuilder(column: $table.pub, builder: (column) => column);

  GeneratedColumn<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );
}

class $$PeerPrekeysTableTableManager
    extends
        RootTableManager<
          _$MessyDatabase,
          $PeerPrekeysTable,
          PeerPrekeyRow,
          $$PeerPrekeysTableFilterComposer,
          $$PeerPrekeysTableOrderingComposer,
          $$PeerPrekeysTableAnnotationComposer,
          $$PeerPrekeysTableCreateCompanionBuilder,
          $$PeerPrekeysTableUpdateCompanionBuilder,
          (
            PeerPrekeyRow,
            BaseReferences<_$MessyDatabase, $PeerPrekeysTable, PeerPrekeyRow>,
          ),
          PeerPrekeyRow,
          PrefetchHooks Function()
        > {
  $$PeerPrekeysTableTableManager(_$MessyDatabase db, $PeerPrekeysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeerPrekeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeerPrekeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeerPrekeysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> nodeId = const Value.absent(),
                Value<String> keyId = const Value.absent(),
                Value<Uint8List> pub = const Value.absent(),
                Value<int> receivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeerPrekeysCompanion(
                nodeId: nodeId,
                keyId: keyId,
                pub: pub,
                receivedAt: receivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nodeId,
                required String keyId,
                required Uint8List pub,
                required int receivedAt,
                Value<int> rowid = const Value.absent(),
              }) => PeerPrekeysCompanion.insert(
                nodeId: nodeId,
                keyId: keyId,
                pub: pub,
                receivedAt: receivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeerPrekeysTableProcessedTableManager =
    ProcessedTableManager<
      _$MessyDatabase,
      $PeerPrekeysTable,
      PeerPrekeyRow,
      $$PeerPrekeysTableFilterComposer,
      $$PeerPrekeysTableOrderingComposer,
      $$PeerPrekeysTableAnnotationComposer,
      $$PeerPrekeysTableCreateCompanionBuilder,
      $$PeerPrekeysTableUpdateCompanionBuilder,
      (
        PeerPrekeyRow,
        BaseReferences<_$MessyDatabase, $PeerPrekeysTable, PeerPrekeyRow>,
      ),
      PeerPrekeyRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$MessyDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$MessyDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$MessyDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$MessyDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$MessyDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$MessyDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$MessyDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$MessyDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $MessyDatabaseManager {
  final _$MessyDatabase _db;
  $MessyDatabaseManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$MediaChunksTableTableManager get mediaChunks =>
      $$MediaChunksTableTableManager(_db, _db.mediaChunks);
  $$RelayStoreTableTableManager get relayStore =>
      $$RelayStoreTableTableManager(_db, _db.relayStore);
  $$SeenEnvelopesTableTableManager get seenEnvelopes =>
      $$SeenEnvelopesTableTableManager(_db, _db.seenEnvelopes);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$OwnPrekeysTableTableManager get ownPrekeys =>
      $$OwnPrekeysTableTableManager(_db, _db.ownPrekeys);
  $$PeerPrekeysTableTableManager get peerPrekeys =>
      $$PeerPrekeysTableTableManager(_db, _db.peerPrekeys);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
