// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PlansTable extends Plans with TableInfo<$PlansTable, Plan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    notes,
    currency,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Plan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class Plan extends DataClass implements Insertable<Plan> {
  final String id;
  final String type;
  final String title;
  final String? notes;
  final String currency;
  final DateTime createdAt;
  const Plan({
    required this.id,
    required this.type,
    required this.title,
    this.notes,
    required this.currency,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['currency'] = Variable<String>(currency);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      currency: Value(currency),
      createdAt: Value(createdAt),
    );
  }

  factory Plan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plan(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      currency: serializer.fromJson<String>(json['currency']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'currency': serializer.toJson<String>(currency),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Plan copyWith({
    String? id,
    String? type,
    String? title,
    Value<String?> notes = const Value.absent(),
    String? currency,
    DateTime? createdAt,
  }) => Plan(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    currency: currency ?? this.currency,
    createdAt: createdAt ?? this.createdAt,
  );
  Plan copyWithCompanion(PlansCompanion data) {
    return Plan(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      currency: data.currency.present ? data.currency.value : this.currency,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plan(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('currency: $currency, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, title, notes, currency, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plan &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.currency == this.currency &&
          other.createdAt == this.createdAt);
}

class PlansCompanion extends UpdateCompanion<Plan> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String?> notes;
  final Value<String> currency;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.currency = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlansCompanion.insert({
    required String id,
    required String type,
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.currency = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<Plan> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? currency,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (currency != null) 'currency': currency,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlansCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? title,
    Value<String?>? notes,
    Value<String>? currency,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlansCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('currency: $currency, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParticipantsTable extends Participants
    with TableInfo<$ParticipantsTable, Participant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParticipantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _avatarIdMeta = const VerificationMeta(
    'avatarId',
  );
  @override
  late final GeneratedColumn<String> avatarId = GeneratedColumn<String>(
    'avatar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    avatarId,
    createdAt,
    contactId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<Participant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('avatar_id')) {
      context.handle(
        _avatarIdMeta,
        avatarId.isAcceptableOrUnknown(data['avatar_id']!, _avatarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_avatarIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Participant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Participant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      avatarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      ),
    );
  }

  @override
  $ParticipantsTable createAlias(String alias) {
    return $ParticipantsTable(attachedDatabase, alias);
  }
}

class Participant extends DataClass implements Insertable<Participant> {
  final String id;
  final String displayName;
  final String avatarId;
  final DateTime createdAt;

  /// Reference to the authoritative identity in [Contacts]. Nullable for
  /// legacy rows that existed before the Contacts module shipped. The
  /// `displayName` and `avatarId` columns on this row act as the historical
  /// display snapshot if the referenced Contact is later deleted.
  final String? contactId;
  const Participant({
    required this.id,
    required this.displayName,
    required this.avatarId,
    required this.createdAt,
    this.contactId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['avatar_id'] = Variable<String>(avatarId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<String>(contactId);
    }
    return map;
  }

  ParticipantsCompanion toCompanion(bool nullToAbsent) {
    return ParticipantsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      avatarId: Value(avatarId),
      createdAt: Value(createdAt),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
    );
  }

  factory Participant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Participant(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      avatarId: serializer.fromJson<String>(json['avatarId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      contactId: serializer.fromJson<String?>(json['contactId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'avatarId': serializer.toJson<String>(avatarId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'contactId': serializer.toJson<String?>(contactId),
    };
  }

  Participant copyWith({
    String? id,
    String? displayName,
    String? avatarId,
    DateTime? createdAt,
    Value<String?> contactId = const Value.absent(),
  }) => Participant(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    avatarId: avatarId ?? this.avatarId,
    createdAt: createdAt ?? this.createdAt,
    contactId: contactId.present ? contactId.value : this.contactId,
  );
  Participant copyWithCompanion(ParticipantsCompanion data) {
    return Participant(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarId: data.avatarId.present ? data.avatarId.value : this.avatarId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Participant(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('avatarId: $avatarId, ')
          ..write('createdAt: $createdAt, ')
          ..write('contactId: $contactId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, displayName, avatarId, createdAt, contactId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Participant &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.avatarId == this.avatarId &&
          other.createdAt == this.createdAt &&
          other.contactId == this.contactId);
}

class ParticipantsCompanion extends UpdateCompanion<Participant> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> avatarId;
  final Value<DateTime> createdAt;
  final Value<String?> contactId;
  final Value<int> rowid;
  const ParticipantsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.contactId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParticipantsCompanion.insert({
    required String id,
    required String displayName,
    required String avatarId,
    required DateTime createdAt,
    this.contactId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       avatarId = Value(avatarId),
       createdAt = Value(createdAt);
  static Insertable<Participant> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? avatarId,
    Expression<DateTime>? createdAt,
    Expression<String>? contactId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (avatarId != null) 'avatar_id': avatarId,
      if (createdAt != null) 'created_at': createdAt,
      if (contactId != null) 'contact_id': contactId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParticipantsCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? avatarId,
    Value<DateTime>? createdAt,
    Value<String?>? contactId,
    Value<int>? rowid,
  }) {
    return ParticipantsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarId: avatarId ?? this.avatarId,
      createdAt: createdAt ?? this.createdAt,
      contactId: contactId ?? this.contactId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarId.present) {
      map['avatar_id'] = Variable<String>(avatarId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParticipantsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('avatarId: $avatarId, ')
          ..write('createdAt: $createdAt, ')
          ..write('contactId: $contactId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanLinesTable extends PlanLines
    with TableInfo<$PlanLinesTable, PlanLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountUsesRangeMeta = const VerificationMeta(
    'amountUsesRange',
  );
  @override
  late final GeneratedColumn<bool> amountUsesRange = GeneratedColumn<bool>(
    'amount_uses_range',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("amount_uses_range" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minAmountMinorMeta = const VerificationMeta(
    'minAmountMinor',
  );
  @override
  late final GeneratedColumn<int> minAmountMinor = GeneratedColumn<int>(
    'min_amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxAmountMinorMeta = const VerificationMeta(
    'maxAmountMinor',
  );
  @override
  late final GeneratedColumn<int> maxAmountMinor = GeneratedColumn<int>(
    'max_amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cadenceMeta = const VerificationMeta(
    'cadence',
  );
  @override
  late final GeneratedColumn<String> cadence = GeneratedColumn<String>(
    'cadence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _recurrenceDayOfMonthMeta =
      const VerificationMeta('recurrenceDayOfMonth');
  @override
  late final GeneratedColumn<int> recurrenceDayOfMonth = GeneratedColumn<int>(
    'recurrence_day_of_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountIsBudgetCapMeta = const VerificationMeta(
    'amountIsBudgetCap',
  );
  @override
  late final GeneratedColumn<bool> amountIsBudgetCap = GeneratedColumn<bool>(
    'amount_is_budget_cap',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("amount_is_budget_cap" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _paymentResponsibleParticipantIdMeta =
      const VerificationMeta('paymentResponsibleParticipantId');
  @override
  late final GeneratedColumn<String> paymentResponsibleParticipantId =
      GeneratedColumn<String>(
        'payment_responsible_participant_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recurrenceSpecJsonMeta =
      const VerificationMeta('recurrenceSpecJson');
  @override
  late final GeneratedColumn<String> recurrenceSpecJson =
      GeneratedColumn<String>(
        'recurrence_spec_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _ratioTemplateIdMeta = const VerificationMeta(
    'ratioTemplateId',
  );
  @override
  late final GeneratedColumn<String> ratioTemplateId = GeneratedColumn<String>(
    'ratio_template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    isRecurring,
    title,
    currency,
    amountUsesRange,
    amountMinor,
    minAmountMinor,
    maxAmountMinor,
    description,
    cadence,
    recurrenceDayOfMonth,
    sortOrder,
    groupId,
    amountIsBudgetCap,
    paymentResponsibleParticipantId,
    recurrenceSpecJson,
    ratioTemplateId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isRecurringMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('amount_uses_range')) {
      context.handle(
        _amountUsesRangeMeta,
        amountUsesRange.isAcceptableOrUnknown(
          data['amount_uses_range']!,
          _amountUsesRangeMeta,
        ),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    }
    if (data.containsKey('min_amount_minor')) {
      context.handle(
        _minAmountMinorMeta,
        minAmountMinor.isAcceptableOrUnknown(
          data['min_amount_minor']!,
          _minAmountMinorMeta,
        ),
      );
    }
    if (data.containsKey('max_amount_minor')) {
      context.handle(
        _maxAmountMinorMeta,
        maxAmountMinor.isAcceptableOrUnknown(
          data['max_amount_minor']!,
          _maxAmountMinorMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cadence')) {
      context.handle(
        _cadenceMeta,
        cadence.isAcceptableOrUnknown(data['cadence']!, _cadenceMeta),
      );
    }
    if (data.containsKey('recurrence_day_of_month')) {
      context.handle(
        _recurrenceDayOfMonthMeta,
        recurrenceDayOfMonth.isAcceptableOrUnknown(
          data['recurrence_day_of_month']!,
          _recurrenceDayOfMonthMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('amount_is_budget_cap')) {
      context.handle(
        _amountIsBudgetCapMeta,
        amountIsBudgetCap.isAcceptableOrUnknown(
          data['amount_is_budget_cap']!,
          _amountIsBudgetCapMeta,
        ),
      );
    }
    if (data.containsKey('payment_responsible_participant_id')) {
      context.handle(
        _paymentResponsibleParticipantIdMeta,
        paymentResponsibleParticipantId.isAcceptableOrUnknown(
          data['payment_responsible_participant_id']!,
          _paymentResponsibleParticipantIdMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_spec_json')) {
      context.handle(
        _recurrenceSpecJsonMeta,
        recurrenceSpecJson.isAcceptableOrUnknown(
          data['recurrence_spec_json']!,
          _recurrenceSpecJsonMeta,
        ),
      );
    }
    if (data.containsKey('ratio_template_id')) {
      context.handle(
        _ratioTemplateIdMeta,
        ratioTemplateId.isAcceptableOrUnknown(
          data['ratio_template_id']!,
          _ratioTemplateIdMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanLine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      amountUsesRange: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}amount_uses_range'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      ),
      minAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_amount_minor'],
      ),
      maxAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_amount_minor'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      cadence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cadence'],
      )!,
      recurrenceDayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_day_of_month'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      amountIsBudgetCap: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}amount_is_budget_cap'],
      )!,
      paymentResponsibleParticipantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_responsible_participant_id'],
      ),
      recurrenceSpecJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_spec_json'],
      )!,
      ratioTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ratio_template_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlanLinesTable createAlias(String alias) {
    return $PlanLinesTable(attachedDatabase, alias);
  }
}

class PlanLine extends DataClass implements Insertable<PlanLine> {
  final String id;
  final String planId;
  final bool isRecurring;
  final String title;
  final String currency;

  /// When false: [amountMinor] is the fixed amount (per month if recurring, total if one-off).
  /// When true: [minAmountMinor] / [maxAmountMinor] define an approximate band (both types).
  final bool amountUsesRange;
  final int? amountMinor;
  final int? minAmountMinor;
  final int? maxAmountMinor;

  /// Optional longer description for the expense.
  final String description;
  final String cadence;

  /// Day of month (1–31) when a monthly recurring charge applies.
  final int? recurrenceDayOfMonth;

  /// Display order within the plan (lower first).
  final int sortOrder;
  final String? groupId;

  /// When true, [amountMinor] is a budget ceiling (high estimate), not a fixed amount.
  final bool amountIsBudgetCap;

  /// Nullable; null means all participants (notification routing deferred).
  final String? paymentResponsibleParticipantId;

  /// JSON recurrence spec (see `ExpenseRecurrenceSpec`).
  final String recurrenceSpecJson;

  /// Optional link to a ratio template used at save (UI aid only).
  final String? ratioTemplateId;
  final DateTime createdAt;
  const PlanLine({
    required this.id,
    required this.planId,
    required this.isRecurring,
    required this.title,
    required this.currency,
    required this.amountUsesRange,
    this.amountMinor,
    this.minAmountMinor,
    this.maxAmountMinor,
    required this.description,
    required this.cadence,
    this.recurrenceDayOfMonth,
    required this.sortOrder,
    this.groupId,
    required this.amountIsBudgetCap,
    this.paymentResponsibleParticipantId,
    required this.recurrenceSpecJson,
    this.ratioTemplateId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['is_recurring'] = Variable<bool>(isRecurring);
    map['title'] = Variable<String>(title);
    map['currency'] = Variable<String>(currency);
    map['amount_uses_range'] = Variable<bool>(amountUsesRange);
    if (!nullToAbsent || amountMinor != null) {
      map['amount_minor'] = Variable<int>(amountMinor);
    }
    if (!nullToAbsent || minAmountMinor != null) {
      map['min_amount_minor'] = Variable<int>(minAmountMinor);
    }
    if (!nullToAbsent || maxAmountMinor != null) {
      map['max_amount_minor'] = Variable<int>(maxAmountMinor);
    }
    map['description'] = Variable<String>(description);
    map['cadence'] = Variable<String>(cadence);
    if (!nullToAbsent || recurrenceDayOfMonth != null) {
      map['recurrence_day_of_month'] = Variable<int>(recurrenceDayOfMonth);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['amount_is_budget_cap'] = Variable<bool>(amountIsBudgetCap);
    if (!nullToAbsent || paymentResponsibleParticipantId != null) {
      map['payment_responsible_participant_id'] = Variable<String>(
        paymentResponsibleParticipantId,
      );
    }
    map['recurrence_spec_json'] = Variable<String>(recurrenceSpecJson);
    if (!nullToAbsent || ratioTemplateId != null) {
      map['ratio_template_id'] = Variable<String>(ratioTemplateId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlanLinesCompanion toCompanion(bool nullToAbsent) {
    return PlanLinesCompanion(
      id: Value(id),
      planId: Value(planId),
      isRecurring: Value(isRecurring),
      title: Value(title),
      currency: Value(currency),
      amountUsesRange: Value(amountUsesRange),
      amountMinor: amountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinor),
      minAmountMinor: minAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(minAmountMinor),
      maxAmountMinor: maxAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(maxAmountMinor),
      description: Value(description),
      cadence: Value(cadence),
      recurrenceDayOfMonth: recurrenceDayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceDayOfMonth),
      sortOrder: Value(sortOrder),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      amountIsBudgetCap: Value(amountIsBudgetCap),
      paymentResponsibleParticipantId:
          paymentResponsibleParticipantId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentResponsibleParticipantId),
      recurrenceSpecJson: Value(recurrenceSpecJson),
      ratioTemplateId: ratioTemplateId == null && nullToAbsent
          ? const Value.absent()
          : Value(ratioTemplateId),
      createdAt: Value(createdAt),
    );
  }

  factory PlanLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanLine(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      title: serializer.fromJson<String>(json['title']),
      currency: serializer.fromJson<String>(json['currency']),
      amountUsesRange: serializer.fromJson<bool>(json['amountUsesRange']),
      amountMinor: serializer.fromJson<int?>(json['amountMinor']),
      minAmountMinor: serializer.fromJson<int?>(json['minAmountMinor']),
      maxAmountMinor: serializer.fromJson<int?>(json['maxAmountMinor']),
      description: serializer.fromJson<String>(json['description']),
      cadence: serializer.fromJson<String>(json['cadence']),
      recurrenceDayOfMonth: serializer.fromJson<int?>(
        json['recurrenceDayOfMonth'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      amountIsBudgetCap: serializer.fromJson<bool>(json['amountIsBudgetCap']),
      paymentResponsibleParticipantId: serializer.fromJson<String?>(
        json['paymentResponsibleParticipantId'],
      ),
      recurrenceSpecJson: serializer.fromJson<String>(
        json['recurrenceSpecJson'],
      ),
      ratioTemplateId: serializer.fromJson<String?>(json['ratioTemplateId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'title': serializer.toJson<String>(title),
      'currency': serializer.toJson<String>(currency),
      'amountUsesRange': serializer.toJson<bool>(amountUsesRange),
      'amountMinor': serializer.toJson<int?>(amountMinor),
      'minAmountMinor': serializer.toJson<int?>(minAmountMinor),
      'maxAmountMinor': serializer.toJson<int?>(maxAmountMinor),
      'description': serializer.toJson<String>(description),
      'cadence': serializer.toJson<String>(cadence),
      'recurrenceDayOfMonth': serializer.toJson<int?>(recurrenceDayOfMonth),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'groupId': serializer.toJson<String?>(groupId),
      'amountIsBudgetCap': serializer.toJson<bool>(amountIsBudgetCap),
      'paymentResponsibleParticipantId': serializer.toJson<String?>(
        paymentResponsibleParticipantId,
      ),
      'recurrenceSpecJson': serializer.toJson<String>(recurrenceSpecJson),
      'ratioTemplateId': serializer.toJson<String?>(ratioTemplateId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlanLine copyWith({
    String? id,
    String? planId,
    bool? isRecurring,
    String? title,
    String? currency,
    bool? amountUsesRange,
    Value<int?> amountMinor = const Value.absent(),
    Value<int?> minAmountMinor = const Value.absent(),
    Value<int?> maxAmountMinor = const Value.absent(),
    String? description,
    String? cadence,
    Value<int?> recurrenceDayOfMonth = const Value.absent(),
    int? sortOrder,
    Value<String?> groupId = const Value.absent(),
    bool? amountIsBudgetCap,
    Value<String?> paymentResponsibleParticipantId = const Value.absent(),
    String? recurrenceSpecJson,
    Value<String?> ratioTemplateId = const Value.absent(),
    DateTime? createdAt,
  }) => PlanLine(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    isRecurring: isRecurring ?? this.isRecurring,
    title: title ?? this.title,
    currency: currency ?? this.currency,
    amountUsesRange: amountUsesRange ?? this.amountUsesRange,
    amountMinor: amountMinor.present ? amountMinor.value : this.amountMinor,
    minAmountMinor: minAmountMinor.present
        ? minAmountMinor.value
        : this.minAmountMinor,
    maxAmountMinor: maxAmountMinor.present
        ? maxAmountMinor.value
        : this.maxAmountMinor,
    description: description ?? this.description,
    cadence: cadence ?? this.cadence,
    recurrenceDayOfMonth: recurrenceDayOfMonth.present
        ? recurrenceDayOfMonth.value
        : this.recurrenceDayOfMonth,
    sortOrder: sortOrder ?? this.sortOrder,
    groupId: groupId.present ? groupId.value : this.groupId,
    amountIsBudgetCap: amountIsBudgetCap ?? this.amountIsBudgetCap,
    paymentResponsibleParticipantId: paymentResponsibleParticipantId.present
        ? paymentResponsibleParticipantId.value
        : this.paymentResponsibleParticipantId,
    recurrenceSpecJson: recurrenceSpecJson ?? this.recurrenceSpecJson,
    ratioTemplateId: ratioTemplateId.present
        ? ratioTemplateId.value
        : this.ratioTemplateId,
    createdAt: createdAt ?? this.createdAt,
  );
  PlanLine copyWithCompanion(PlanLinesCompanion data) {
    return PlanLine(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      title: data.title.present ? data.title.value : this.title,
      currency: data.currency.present ? data.currency.value : this.currency,
      amountUsesRange: data.amountUsesRange.present
          ? data.amountUsesRange.value
          : this.amountUsesRange,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      minAmountMinor: data.minAmountMinor.present
          ? data.minAmountMinor.value
          : this.minAmountMinor,
      maxAmountMinor: data.maxAmountMinor.present
          ? data.maxAmountMinor.value
          : this.maxAmountMinor,
      description: data.description.present
          ? data.description.value
          : this.description,
      cadence: data.cadence.present ? data.cadence.value : this.cadence,
      recurrenceDayOfMonth: data.recurrenceDayOfMonth.present
          ? data.recurrenceDayOfMonth.value
          : this.recurrenceDayOfMonth,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      amountIsBudgetCap: data.amountIsBudgetCap.present
          ? data.amountIsBudgetCap.value
          : this.amountIsBudgetCap,
      paymentResponsibleParticipantId:
          data.paymentResponsibleParticipantId.present
          ? data.paymentResponsibleParticipantId.value
          : this.paymentResponsibleParticipantId,
      recurrenceSpecJson: data.recurrenceSpecJson.present
          ? data.recurrenceSpecJson.value
          : this.recurrenceSpecJson,
      ratioTemplateId: data.ratioTemplateId.present
          ? data.ratioTemplateId.value
          : this.ratioTemplateId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanLine(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('title: $title, ')
          ..write('currency: $currency, ')
          ..write('amountUsesRange: $amountUsesRange, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('minAmountMinor: $minAmountMinor, ')
          ..write('maxAmountMinor: $maxAmountMinor, ')
          ..write('description: $description, ')
          ..write('cadence: $cadence, ')
          ..write('recurrenceDayOfMonth: $recurrenceDayOfMonth, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('groupId: $groupId, ')
          ..write('amountIsBudgetCap: $amountIsBudgetCap, ')
          ..write(
            'paymentResponsibleParticipantId: $paymentResponsibleParticipantId, ',
          )
          ..write('recurrenceSpecJson: $recurrenceSpecJson, ')
          ..write('ratioTemplateId: $ratioTemplateId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    isRecurring,
    title,
    currency,
    amountUsesRange,
    amountMinor,
    minAmountMinor,
    maxAmountMinor,
    description,
    cadence,
    recurrenceDayOfMonth,
    sortOrder,
    groupId,
    amountIsBudgetCap,
    paymentResponsibleParticipantId,
    recurrenceSpecJson,
    ratioTemplateId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanLine &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.isRecurring == this.isRecurring &&
          other.title == this.title &&
          other.currency == this.currency &&
          other.amountUsesRange == this.amountUsesRange &&
          other.amountMinor == this.amountMinor &&
          other.minAmountMinor == this.minAmountMinor &&
          other.maxAmountMinor == this.maxAmountMinor &&
          other.description == this.description &&
          other.cadence == this.cadence &&
          other.recurrenceDayOfMonth == this.recurrenceDayOfMonth &&
          other.sortOrder == this.sortOrder &&
          other.groupId == this.groupId &&
          other.amountIsBudgetCap == this.amountIsBudgetCap &&
          other.paymentResponsibleParticipantId ==
              this.paymentResponsibleParticipantId &&
          other.recurrenceSpecJson == this.recurrenceSpecJson &&
          other.ratioTemplateId == this.ratioTemplateId &&
          other.createdAt == this.createdAt);
}

class PlanLinesCompanion extends UpdateCompanion<PlanLine> {
  final Value<String> id;
  final Value<String> planId;
  final Value<bool> isRecurring;
  final Value<String> title;
  final Value<String> currency;
  final Value<bool> amountUsesRange;
  final Value<int?> amountMinor;
  final Value<int?> minAmountMinor;
  final Value<int?> maxAmountMinor;
  final Value<String> description;
  final Value<String> cadence;
  final Value<int?> recurrenceDayOfMonth;
  final Value<int> sortOrder;
  final Value<String?> groupId;
  final Value<bool> amountIsBudgetCap;
  final Value<String?> paymentResponsibleParticipantId;
  final Value<String> recurrenceSpecJson;
  final Value<String?> ratioTemplateId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlanLinesCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.title = const Value.absent(),
    this.currency = const Value.absent(),
    this.amountUsesRange = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.minAmountMinor = const Value.absent(),
    this.maxAmountMinor = const Value.absent(),
    this.description = const Value.absent(),
    this.cadence = const Value.absent(),
    this.recurrenceDayOfMonth = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.groupId = const Value.absent(),
    this.amountIsBudgetCap = const Value.absent(),
    this.paymentResponsibleParticipantId = const Value.absent(),
    this.recurrenceSpecJson = const Value.absent(),
    this.ratioTemplateId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanLinesCompanion.insert({
    required String id,
    required String planId,
    required bool isRecurring,
    required String title,
    required String currency,
    this.amountUsesRange = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.minAmountMinor = const Value.absent(),
    this.maxAmountMinor = const Value.absent(),
    this.description = const Value.absent(),
    this.cadence = const Value.absent(),
    this.recurrenceDayOfMonth = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.groupId = const Value.absent(),
    this.amountIsBudgetCap = const Value.absent(),
    this.paymentResponsibleParticipantId = const Value.absent(),
    this.recurrenceSpecJson = const Value.absent(),
    this.ratioTemplateId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       isRecurring = Value(isRecurring),
       title = Value(title),
       currency = Value(currency),
       createdAt = Value(createdAt);
  static Insertable<PlanLine> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<bool>? isRecurring,
    Expression<String>? title,
    Expression<String>? currency,
    Expression<bool>? amountUsesRange,
    Expression<int>? amountMinor,
    Expression<int>? minAmountMinor,
    Expression<int>? maxAmountMinor,
    Expression<String>? description,
    Expression<String>? cadence,
    Expression<int>? recurrenceDayOfMonth,
    Expression<int>? sortOrder,
    Expression<String>? groupId,
    Expression<bool>? amountIsBudgetCap,
    Expression<String>? paymentResponsibleParticipantId,
    Expression<String>? recurrenceSpecJson,
    Expression<String>? ratioTemplateId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (title != null) 'title': title,
      if (currency != null) 'currency': currency,
      if (amountUsesRange != null) 'amount_uses_range': amountUsesRange,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (minAmountMinor != null) 'min_amount_minor': minAmountMinor,
      if (maxAmountMinor != null) 'max_amount_minor': maxAmountMinor,
      if (description != null) 'description': description,
      if (cadence != null) 'cadence': cadence,
      if (recurrenceDayOfMonth != null)
        'recurrence_day_of_month': recurrenceDayOfMonth,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (groupId != null) 'group_id': groupId,
      if (amountIsBudgetCap != null) 'amount_is_budget_cap': amountIsBudgetCap,
      if (paymentResponsibleParticipantId != null)
        'payment_responsible_participant_id': paymentResponsibleParticipantId,
      if (recurrenceSpecJson != null)
        'recurrence_spec_json': recurrenceSpecJson,
      if (ratioTemplateId != null) 'ratio_template_id': ratioTemplateId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<bool>? isRecurring,
    Value<String>? title,
    Value<String>? currency,
    Value<bool>? amountUsesRange,
    Value<int?>? amountMinor,
    Value<int?>? minAmountMinor,
    Value<int?>? maxAmountMinor,
    Value<String>? description,
    Value<String>? cadence,
    Value<int?>? recurrenceDayOfMonth,
    Value<int>? sortOrder,
    Value<String?>? groupId,
    Value<bool>? amountIsBudgetCap,
    Value<String?>? paymentResponsibleParticipantId,
    Value<String>? recurrenceSpecJson,
    Value<String?>? ratioTemplateId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlanLinesCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      isRecurring: isRecurring ?? this.isRecurring,
      title: title ?? this.title,
      currency: currency ?? this.currency,
      amountUsesRange: amountUsesRange ?? this.amountUsesRange,
      amountMinor: amountMinor ?? this.amountMinor,
      minAmountMinor: minAmountMinor ?? this.minAmountMinor,
      maxAmountMinor: maxAmountMinor ?? this.maxAmountMinor,
      description: description ?? this.description,
      cadence: cadence ?? this.cadence,
      recurrenceDayOfMonth: recurrenceDayOfMonth ?? this.recurrenceDayOfMonth,
      sortOrder: sortOrder ?? this.sortOrder,
      groupId: groupId ?? this.groupId,
      amountIsBudgetCap: amountIsBudgetCap ?? this.amountIsBudgetCap,
      paymentResponsibleParticipantId:
          paymentResponsibleParticipantId ??
          this.paymentResponsibleParticipantId,
      recurrenceSpecJson: recurrenceSpecJson ?? this.recurrenceSpecJson,
      ratioTemplateId: ratioTemplateId ?? this.ratioTemplateId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (amountUsesRange.present) {
      map['amount_uses_range'] = Variable<bool>(amountUsesRange.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (minAmountMinor.present) {
      map['min_amount_minor'] = Variable<int>(minAmountMinor.value);
    }
    if (maxAmountMinor.present) {
      map['max_amount_minor'] = Variable<int>(maxAmountMinor.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (cadence.present) {
      map['cadence'] = Variable<String>(cadence.value);
    }
    if (recurrenceDayOfMonth.present) {
      map['recurrence_day_of_month'] = Variable<int>(
        recurrenceDayOfMonth.value,
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (amountIsBudgetCap.present) {
      map['amount_is_budget_cap'] = Variable<bool>(amountIsBudgetCap.value);
    }
    if (paymentResponsibleParticipantId.present) {
      map['payment_responsible_participant_id'] = Variable<String>(
        paymentResponsibleParticipantId.value,
      );
    }
    if (recurrenceSpecJson.present) {
      map['recurrence_spec_json'] = Variable<String>(recurrenceSpecJson.value);
    }
    if (ratioTemplateId.present) {
      map['ratio_template_id'] = Variable<String>(ratioTemplateId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanLinesCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('title: $title, ')
          ..write('currency: $currency, ')
          ..write('amountUsesRange: $amountUsesRange, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('minAmountMinor: $minAmountMinor, ')
          ..write('maxAmountMinor: $maxAmountMinor, ')
          ..write('description: $description, ')
          ..write('cadence: $cadence, ')
          ..write('recurrenceDayOfMonth: $recurrenceDayOfMonth, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('groupId: $groupId, ')
          ..write('amountIsBudgetCap: $amountIsBudgetCap, ')
          ..write(
            'paymentResponsibleParticipantId: $paymentResponsibleParticipantId, ',
          )
          ..write('recurrenceSpecJson: $recurrenceSpecJson, ')
          ..write('ratioTemplateId: $ratioTemplateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanGroupsTable extends PlanGroups
    with TableInfo<$PlanGroupsTable, PlanGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    title,
    description,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlanGroupsTable createAlias(String alias) {
    return $PlanGroupsTable(attachedDatabase, alias);
  }
}

class PlanGroup extends DataClass implements Insertable<PlanGroup> {
  final String id;
  final String planId;
  final String title;

  /// Optional guidance for what expenses belong in this category.
  final String description;
  final DateTime createdAt;
  const PlanGroup({
    required this.id,
    required this.planId,
    required this.title,
    required this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlanGroupsCompanion toCompanion(bool nullToAbsent) {
    return PlanGroupsCompanion(
      id: Value(id),
      planId: Value(planId),
      title: Value(title),
      description: Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory PlanGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanGroup(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlanGroup copyWith({
    String? id,
    String? planId,
    String? title,
    String? description,
    DateTime? createdAt,
  }) => PlanGroup(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    title: title ?? this.title,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  PlanGroup copyWithCompanion(PlanGroupsCompanion data) {
    return PlanGroup(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanGroup(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planId, title, description, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanGroup &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.title == this.title &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class PlanGroupsCompanion extends UpdateCompanion<PlanGroup> {
  final Value<String> id;
  final Value<String> planId;
  final Value<String> title;
  final Value<String> description;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlanGroupsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanGroupsCompanion.insert({
    required String id,
    required String planId,
    required String title,
    this.description = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<PlanGroup> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<String>? title,
    Value<String>? description,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlanGroupsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanGroupsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanRatiosTable extends PlanRatios
    with TableInfo<$PlanRatiosTable, PlanRatio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanRatiosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _participantIdMeta = const VerificationMeta(
    'participantId',
  );
  @override
  late final GeneratedColumn<String> participantId = GeneratedColumn<String>(
    'participant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineIdMeta = const VerificationMeta('lineId');
  @override
  late final GeneratedColumn<String> lineId = GeneratedColumn<String>(
    'line_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<int> weight = GeneratedColumn<int>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    participantId,
    lineId,
    groupId,
    weight,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_ratios';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanRatio> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('participant_id')) {
      context.handle(
        _participantIdMeta,
        participantId.isAcceptableOrUnknown(
          data['participant_id']!,
          _participantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantIdMeta);
    }
    if (data.containsKey('line_id')) {
      context.handle(
        _lineIdMeta,
        lineId.isAcceptableOrUnknown(data['line_id']!, _lineIdMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanRatio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanRatio(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      participantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_id'],
      )!,
      lineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_id'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weight'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlanRatiosTable createAlias(String alias) {
    return $PlanRatiosTable(attachedDatabase, alias);
  }
}

class PlanRatio extends DataClass implements Insertable<PlanRatio> {
  final String id;
  final String planId;
  final String participantId;
  final String? lineId;
  final String? groupId;
  final int weight;
  final DateTime createdAt;
  const PlanRatio({
    required this.id,
    required this.planId,
    required this.participantId,
    this.lineId,
    this.groupId,
    required this.weight,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['participant_id'] = Variable<String>(participantId);
    if (!nullToAbsent || lineId != null) {
      map['line_id'] = Variable<String>(lineId);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['weight'] = Variable<int>(weight);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlanRatiosCompanion toCompanion(bool nullToAbsent) {
    return PlanRatiosCompanion(
      id: Value(id),
      planId: Value(planId),
      participantId: Value(participantId),
      lineId: lineId == null && nullToAbsent
          ? const Value.absent()
          : Value(lineId),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      weight: Value(weight),
      createdAt: Value(createdAt),
    );
  }

  factory PlanRatio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanRatio(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      participantId: serializer.fromJson<String>(json['participantId']),
      lineId: serializer.fromJson<String?>(json['lineId']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      weight: serializer.fromJson<int>(json['weight']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'participantId': serializer.toJson<String>(participantId),
      'lineId': serializer.toJson<String?>(lineId),
      'groupId': serializer.toJson<String?>(groupId),
      'weight': serializer.toJson<int>(weight),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlanRatio copyWith({
    String? id,
    String? planId,
    String? participantId,
    Value<String?> lineId = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    int? weight,
    DateTime? createdAt,
  }) => PlanRatio(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    participantId: participantId ?? this.participantId,
    lineId: lineId.present ? lineId.value : this.lineId,
    groupId: groupId.present ? groupId.value : this.groupId,
    weight: weight ?? this.weight,
    createdAt: createdAt ?? this.createdAt,
  );
  PlanRatio copyWithCompanion(PlanRatiosCompanion data) {
    return PlanRatio(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      participantId: data.participantId.present
          ? data.participantId.value
          : this.participantId,
      lineId: data.lineId.present ? data.lineId.value : this.lineId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      weight: data.weight.present ? data.weight.value : this.weight,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanRatio(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('participantId: $participantId, ')
          ..write('lineId: $lineId, ')
          ..write('groupId: $groupId, ')
          ..write('weight: $weight, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    participantId,
    lineId,
    groupId,
    weight,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRatio &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.participantId == this.participantId &&
          other.lineId == this.lineId &&
          other.groupId == this.groupId &&
          other.weight == this.weight &&
          other.createdAt == this.createdAt);
}

class PlanRatiosCompanion extends UpdateCompanion<PlanRatio> {
  final Value<String> id;
  final Value<String> planId;
  final Value<String> participantId;
  final Value<String?> lineId;
  final Value<String?> groupId;
  final Value<int> weight;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlanRatiosCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.participantId = const Value.absent(),
    this.lineId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.weight = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanRatiosCompanion.insert({
    required String id,
    required String planId,
    required String participantId,
    this.lineId = const Value.absent(),
    this.groupId = const Value.absent(),
    required int weight,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       participantId = Value(participantId),
       weight = Value(weight),
       createdAt = Value(createdAt);
  static Insertable<PlanRatio> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<String>? participantId,
    Expression<String>? lineId,
    Expression<String>? groupId,
    Expression<int>? weight,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (participantId != null) 'participant_id': participantId,
      if (lineId != null) 'line_id': lineId,
      if (groupId != null) 'group_id': groupId,
      if (weight != null) 'weight': weight,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanRatiosCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<String>? participantId,
    Value<String?>? lineId,
    Value<String?>? groupId,
    Value<int>? weight,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlanRatiosCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      participantId: participantId ?? this.participantId,
      lineId: lineId ?? this.lineId,
      groupId: groupId ?? this.groupId,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (participantId.present) {
      map['participant_id'] = Variable<String>(participantId.value);
    }
    if (lineId.present) {
      map['line_id'] = Variable<String>(lineId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (weight.present) {
      map['weight'] = Variable<int>(weight.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanRatiosCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('participantId: $participantId, ')
          ..write('lineId: $lineId, ')
          ..write('groupId: $groupId, ')
          ..write('weight: $weight, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanRatioTemplatesTable extends PlanRatioTemplates
    with TableInfo<$PlanRatioTemplatesTable, PlanRatioTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanRatioTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayTitleMeta = const VerificationMeta(
    'displayTitle',
  );
  @override
  late final GeneratedColumn<String> displayTitle = GeneratedColumn<String>(
    'display_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightsJsonMeta = const VerificationMeta(
    'weightsJson',
  );
  @override
  late final GeneratedColumn<String> weightsJson = GeneratedColumn<String>(
    'weights_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    displayTitle,
    weightsJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_ratio_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanRatioTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('display_title')) {
      context.handle(
        _displayTitleMeta,
        displayTitle.isAcceptableOrUnknown(
          data['display_title']!,
          _displayTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayTitleMeta);
    }
    if (data.containsKey('weights_json')) {
      context.handle(
        _weightsJsonMeta,
        weightsJson.isAcceptableOrUnknown(
          data['weights_json']!,
          _weightsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weightsJsonMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanRatioTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanRatioTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      displayTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_title'],
      )!,
      weightsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weights_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlanRatioTemplatesTable createAlias(String alias) {
    return $PlanRatioTemplatesTable(attachedDatabase, alias);
  }
}

class PlanRatioTemplate extends DataClass
    implements Insertable<PlanRatioTemplate> {
  final String id;
  final String planId;
  final String displayTitle;

  /// JSON map participantId -> weight basis points (sum 10000).
  final String weightsJson;
  final DateTime createdAt;
  const PlanRatioTemplate({
    required this.id,
    required this.planId,
    required this.displayTitle,
    required this.weightsJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['display_title'] = Variable<String>(displayTitle);
    map['weights_json'] = Variable<String>(weightsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlanRatioTemplatesCompanion toCompanion(bool nullToAbsent) {
    return PlanRatioTemplatesCompanion(
      id: Value(id),
      planId: Value(planId),
      displayTitle: Value(displayTitle),
      weightsJson: Value(weightsJson),
      createdAt: Value(createdAt),
    );
  }

  factory PlanRatioTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanRatioTemplate(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      displayTitle: serializer.fromJson<String>(json['displayTitle']),
      weightsJson: serializer.fromJson<String>(json['weightsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'displayTitle': serializer.toJson<String>(displayTitle),
      'weightsJson': serializer.toJson<String>(weightsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlanRatioTemplate copyWith({
    String? id,
    String? planId,
    String? displayTitle,
    String? weightsJson,
    DateTime? createdAt,
  }) => PlanRatioTemplate(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    displayTitle: displayTitle ?? this.displayTitle,
    weightsJson: weightsJson ?? this.weightsJson,
    createdAt: createdAt ?? this.createdAt,
  );
  PlanRatioTemplate copyWithCompanion(PlanRatioTemplatesCompanion data) {
    return PlanRatioTemplate(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      displayTitle: data.displayTitle.present
          ? data.displayTitle.value
          : this.displayTitle,
      weightsJson: data.weightsJson.present
          ? data.weightsJson.value
          : this.weightsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanRatioTemplate(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('displayTitle: $displayTitle, ')
          ..write('weightsJson: $weightsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, planId, displayTitle, weightsJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRatioTemplate &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.displayTitle == this.displayTitle &&
          other.weightsJson == this.weightsJson &&
          other.createdAt == this.createdAt);
}

class PlanRatioTemplatesCompanion extends UpdateCompanion<PlanRatioTemplate> {
  final Value<String> id;
  final Value<String> planId;
  final Value<String> displayTitle;
  final Value<String> weightsJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlanRatioTemplatesCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.displayTitle = const Value.absent(),
    this.weightsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanRatioTemplatesCompanion.insert({
    required String id,
    required String planId,
    required String displayTitle,
    required String weightsJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       displayTitle = Value(displayTitle),
       weightsJson = Value(weightsJson),
       createdAt = Value(createdAt);
  static Insertable<PlanRatioTemplate> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<String>? displayTitle,
    Expression<String>? weightsJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (displayTitle != null) 'display_title': displayTitle,
      if (weightsJson != null) 'weights_json': weightsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanRatioTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<String>? displayTitle,
    Value<String>? weightsJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlanRatioTemplatesCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      displayTitle: displayTitle ?? this.displayTitle,
      weightsJson: weightsJson ?? this.weightsJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (displayTitle.present) {
      map['display_title'] = Variable<String>(displayTitle.value);
    }
    if (weightsJson.present) {
      map['weights_json'] = Variable<String>(weightsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanRatioTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('displayTitle: $displayTitle, ')
          ..write('weightsJson: $weightsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgreementsTable extends Agreements
    with TableInfo<$AgreementsTable, Agreement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgreementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta(
    'periodStart',
  );
  @override
  late final GeneratedColumn<DateTime> periodStart = GeneratedColumn<DateTime>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodEndMeta = const VerificationMeta(
    'periodEnd',
  );
  @override
  late final GeneratedColumn<DateTime> periodEnd = GeneratedColumn<DateTime>(
    'period_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minNoticeDaysMeta = const VerificationMeta(
    'minNoticeDays',
  );
  @override
  late final GeneratedColumn<int> minNoticeDays = GeneratedColumn<int>(
    'min_notice_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _penaltyMinorMeta = const VerificationMeta(
    'penaltyMinor',
  );
  @override
  late final GeneratedColumn<int> penaltyMinor = GeneratedColumn<int>(
    'penalty_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _clausesMeta = const VerificationMeta(
    'clauses',
  );
  @override
  late final GeneratedColumn<String> clauses = GeneratedColumn<String>(
    'clauses',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _withdrawalSameForAllMeta =
      const VerificationMeta('withdrawalSameForAll');
  @override
  late final GeneratedColumn<String> withdrawalSameForAll =
      GeneratedColumn<String>(
        'withdrawal_same_for_all',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('true'),
      );
  static const VerificationMeta _withdrawalPerParticipantJsonMeta =
      const VerificationMeta('withdrawalPerParticipantJson');
  @override
  late final GeneratedColumn<String> withdrawalPerParticipantJson =
      GeneratedColumn<String>(
        'withdrawal_per_participant_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _agreementRulesJsonMeta =
      const VerificationMeta('agreementRulesJson');
  @override
  late final GeneratedColumn<String> agreementRulesJson =
      GeneratedColumn<String>(
        'agreement_rules_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    periodStart,
    periodEnd,
    minNoticeDays,
    penaltyMinor,
    clauses,
    withdrawalSameForAll,
    withdrawalPerParticipantJson,
    agreementRulesJson,
    version,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agreement_contracts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Agreement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
        _periodStartMeta,
        periodStart.isAcceptableOrUnknown(
          data['period_start']!,
          _periodStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_end')) {
      context.handle(
        _periodEndMeta,
        periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta),
      );
    } else if (isInserting) {
      context.missing(_periodEndMeta);
    }
    if (data.containsKey('min_notice_days')) {
      context.handle(
        _minNoticeDaysMeta,
        minNoticeDays.isAcceptableOrUnknown(
          data['min_notice_days']!,
          _minNoticeDaysMeta,
        ),
      );
    }
    if (data.containsKey('penalty_minor')) {
      context.handle(
        _penaltyMinorMeta,
        penaltyMinor.isAcceptableOrUnknown(
          data['penalty_minor']!,
          _penaltyMinorMeta,
        ),
      );
    }
    if (data.containsKey('clauses')) {
      context.handle(
        _clausesMeta,
        clauses.isAcceptableOrUnknown(data['clauses']!, _clausesMeta),
      );
    }
    if (data.containsKey('withdrawal_same_for_all')) {
      context.handle(
        _withdrawalSameForAllMeta,
        withdrawalSameForAll.isAcceptableOrUnknown(
          data['withdrawal_same_for_all']!,
          _withdrawalSameForAllMeta,
        ),
      );
    }
    if (data.containsKey('withdrawal_per_participant_json')) {
      context.handle(
        _withdrawalPerParticipantJsonMeta,
        withdrawalPerParticipantJson.isAcceptableOrUnknown(
          data['withdrawal_per_participant_json']!,
          _withdrawalPerParticipantJsonMeta,
        ),
      );
    }
    if (data.containsKey('agreement_rules_json')) {
      context.handle(
        _agreementRulesJsonMeta,
        agreementRulesJson.isAcceptableOrUnknown(
          data['agreement_rules_json']!,
          _agreementRulesJsonMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Agreement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Agreement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      periodStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}period_start'],
      )!,
      periodEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}period_end'],
      )!,
      minNoticeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_notice_days'],
      )!,
      penaltyMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}penalty_minor'],
      )!,
      clauses: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clauses'],
      )!,
      withdrawalSameForAll: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}withdrawal_same_for_all'],
      )!,
      withdrawalPerParticipantJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}withdrawal_per_participant_json'],
      )!,
      agreementRulesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agreement_rules_json'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AgreementsTable createAlias(String alias) {
    return $AgreementsTable(attachedDatabase, alias);
  }
}

class Agreement extends DataClass implements Insertable<Agreement> {
  final String id;
  final String planId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int minNoticeDays;
  final int penaltyMinor;
  final String clauses;

  /// When false: JSON map per participant id -> { minNoticeDays, penaltyMinor }.
  final String withdrawalSameForAll;
  final String withdrawalPerParticipantJson;

  /// Structured agreement rules (curfew, toggles, custom rules, dismissed suggestions).
  final String agreementRulesJson;
  final int version;
  final DateTime createdAt;
  const Agreement({
    required this.id,
    required this.planId,
    required this.periodStart,
    required this.periodEnd,
    required this.minNoticeDays,
    required this.penaltyMinor,
    required this.clauses,
    required this.withdrawalSameForAll,
    required this.withdrawalPerParticipantJson,
    required this.agreementRulesJson,
    required this.version,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['period_start'] = Variable<DateTime>(periodStart);
    map['period_end'] = Variable<DateTime>(periodEnd);
    map['min_notice_days'] = Variable<int>(minNoticeDays);
    map['penalty_minor'] = Variable<int>(penaltyMinor);
    map['clauses'] = Variable<String>(clauses);
    map['withdrawal_same_for_all'] = Variable<String>(withdrawalSameForAll);
    map['withdrawal_per_participant_json'] = Variable<String>(
      withdrawalPerParticipantJson,
    );
    map['agreement_rules_json'] = Variable<String>(agreementRulesJson);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AgreementsCompanion toCompanion(bool nullToAbsent) {
    return AgreementsCompanion(
      id: Value(id),
      planId: Value(planId),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      minNoticeDays: Value(minNoticeDays),
      penaltyMinor: Value(penaltyMinor),
      clauses: Value(clauses),
      withdrawalSameForAll: Value(withdrawalSameForAll),
      withdrawalPerParticipantJson: Value(withdrawalPerParticipantJson),
      agreementRulesJson: Value(agreementRulesJson),
      version: Value(version),
      createdAt: Value(createdAt),
    );
  }

  factory Agreement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Agreement(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      periodStart: serializer.fromJson<DateTime>(json['periodStart']),
      periodEnd: serializer.fromJson<DateTime>(json['periodEnd']),
      minNoticeDays: serializer.fromJson<int>(json['minNoticeDays']),
      penaltyMinor: serializer.fromJson<int>(json['penaltyMinor']),
      clauses: serializer.fromJson<String>(json['clauses']),
      withdrawalSameForAll: serializer.fromJson<String>(
        json['withdrawalSameForAll'],
      ),
      withdrawalPerParticipantJson: serializer.fromJson<String>(
        json['withdrawalPerParticipantJson'],
      ),
      agreementRulesJson: serializer.fromJson<String>(
        json['agreementRulesJson'],
      ),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'periodStart': serializer.toJson<DateTime>(periodStart),
      'periodEnd': serializer.toJson<DateTime>(periodEnd),
      'minNoticeDays': serializer.toJson<int>(minNoticeDays),
      'penaltyMinor': serializer.toJson<int>(penaltyMinor),
      'clauses': serializer.toJson<String>(clauses),
      'withdrawalSameForAll': serializer.toJson<String>(withdrawalSameForAll),
      'withdrawalPerParticipantJson': serializer.toJson<String>(
        withdrawalPerParticipantJson,
      ),
      'agreementRulesJson': serializer.toJson<String>(agreementRulesJson),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Agreement copyWith({
    String? id,
    String? planId,
    DateTime? periodStart,
    DateTime? periodEnd,
    int? minNoticeDays,
    int? penaltyMinor,
    String? clauses,
    String? withdrawalSameForAll,
    String? withdrawalPerParticipantJson,
    String? agreementRulesJson,
    int? version,
    DateTime? createdAt,
  }) => Agreement(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    minNoticeDays: minNoticeDays ?? this.minNoticeDays,
    penaltyMinor: penaltyMinor ?? this.penaltyMinor,
    clauses: clauses ?? this.clauses,
    withdrawalSameForAll: withdrawalSameForAll ?? this.withdrawalSameForAll,
    withdrawalPerParticipantJson:
        withdrawalPerParticipantJson ?? this.withdrawalPerParticipantJson,
    agreementRulesJson: agreementRulesJson ?? this.agreementRulesJson,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
  );
  Agreement copyWithCompanion(AgreementsCompanion data) {
    return Agreement(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      periodStart: data.periodStart.present
          ? data.periodStart.value
          : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      minNoticeDays: data.minNoticeDays.present
          ? data.minNoticeDays.value
          : this.minNoticeDays,
      penaltyMinor: data.penaltyMinor.present
          ? data.penaltyMinor.value
          : this.penaltyMinor,
      clauses: data.clauses.present ? data.clauses.value : this.clauses,
      withdrawalSameForAll: data.withdrawalSameForAll.present
          ? data.withdrawalSameForAll.value
          : this.withdrawalSameForAll,
      withdrawalPerParticipantJson: data.withdrawalPerParticipantJson.present
          ? data.withdrawalPerParticipantJson.value
          : this.withdrawalPerParticipantJson,
      agreementRulesJson: data.agreementRulesJson.present
          ? data.agreementRulesJson.value
          : this.agreementRulesJson,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Agreement(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('minNoticeDays: $minNoticeDays, ')
          ..write('penaltyMinor: $penaltyMinor, ')
          ..write('clauses: $clauses, ')
          ..write('withdrawalSameForAll: $withdrawalSameForAll, ')
          ..write(
            'withdrawalPerParticipantJson: $withdrawalPerParticipantJson, ',
          )
          ..write('agreementRulesJson: $agreementRulesJson, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    periodStart,
    periodEnd,
    minNoticeDays,
    penaltyMinor,
    clauses,
    withdrawalSameForAll,
    withdrawalPerParticipantJson,
    agreementRulesJson,
    version,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Agreement &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.minNoticeDays == this.minNoticeDays &&
          other.penaltyMinor == this.penaltyMinor &&
          other.clauses == this.clauses &&
          other.withdrawalSameForAll == this.withdrawalSameForAll &&
          other.withdrawalPerParticipantJson ==
              this.withdrawalPerParticipantJson &&
          other.agreementRulesJson == this.agreementRulesJson &&
          other.version == this.version &&
          other.createdAt == this.createdAt);
}

class AgreementsCompanion extends UpdateCompanion<Agreement> {
  final Value<String> id;
  final Value<String> planId;
  final Value<DateTime> periodStart;
  final Value<DateTime> periodEnd;
  final Value<int> minNoticeDays;
  final Value<int> penaltyMinor;
  final Value<String> clauses;
  final Value<String> withdrawalSameForAll;
  final Value<String> withdrawalPerParticipantJson;
  final Value<String> agreementRulesJson;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AgreementsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.minNoticeDays = const Value.absent(),
    this.penaltyMinor = const Value.absent(),
    this.clauses = const Value.absent(),
    this.withdrawalSameForAll = const Value.absent(),
    this.withdrawalPerParticipantJson = const Value.absent(),
    this.agreementRulesJson = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgreementsCompanion.insert({
    required String id,
    required String planId,
    required DateTime periodStart,
    required DateTime periodEnd,
    this.minNoticeDays = const Value.absent(),
    this.penaltyMinor = const Value.absent(),
    this.clauses = const Value.absent(),
    this.withdrawalSameForAll = const Value.absent(),
    this.withdrawalPerParticipantJson = const Value.absent(),
    this.agreementRulesJson = const Value.absent(),
    this.version = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       periodStart = Value(periodStart),
       periodEnd = Value(periodEnd),
       createdAt = Value(createdAt);
  static Insertable<Agreement> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<DateTime>? periodStart,
    Expression<DateTime>? periodEnd,
    Expression<int>? minNoticeDays,
    Expression<int>? penaltyMinor,
    Expression<String>? clauses,
    Expression<String>? withdrawalSameForAll,
    Expression<String>? withdrawalPerParticipantJson,
    Expression<String>? agreementRulesJson,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (minNoticeDays != null) 'min_notice_days': minNoticeDays,
      if (penaltyMinor != null) 'penalty_minor': penaltyMinor,
      if (clauses != null) 'clauses': clauses,
      if (withdrawalSameForAll != null)
        'withdrawal_same_for_all': withdrawalSameForAll,
      if (withdrawalPerParticipantJson != null)
        'withdrawal_per_participant_json': withdrawalPerParticipantJson,
      if (agreementRulesJson != null)
        'agreement_rules_json': agreementRulesJson,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgreementsCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<DateTime>? periodStart,
    Value<DateTime>? periodEnd,
    Value<int>? minNoticeDays,
    Value<int>? penaltyMinor,
    Value<String>? clauses,
    Value<String>? withdrawalSameForAll,
    Value<String>? withdrawalPerParticipantJson,
    Value<String>? agreementRulesJson,
    Value<int>? version,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AgreementsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      minNoticeDays: minNoticeDays ?? this.minNoticeDays,
      penaltyMinor: penaltyMinor ?? this.penaltyMinor,
      clauses: clauses ?? this.clauses,
      withdrawalSameForAll: withdrawalSameForAll ?? this.withdrawalSameForAll,
      withdrawalPerParticipantJson:
          withdrawalPerParticipantJson ?? this.withdrawalPerParticipantJson,
      agreementRulesJson: agreementRulesJson ?? this.agreementRulesJson,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<DateTime>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<DateTime>(periodEnd.value);
    }
    if (minNoticeDays.present) {
      map['min_notice_days'] = Variable<int>(minNoticeDays.value);
    }
    if (penaltyMinor.present) {
      map['penalty_minor'] = Variable<int>(penaltyMinor.value);
    }
    if (clauses.present) {
      map['clauses'] = Variable<String>(clauses.value);
    }
    if (withdrawalSameForAll.present) {
      map['withdrawal_same_for_all'] = Variable<String>(
        withdrawalSameForAll.value,
      );
    }
    if (withdrawalPerParticipantJson.present) {
      map['withdrawal_per_participant_json'] = Variable<String>(
        withdrawalPerParticipantJson.value,
      );
    }
    if (agreementRulesJson.present) {
      map['agreement_rules_json'] = Variable<String>(agreementRulesJson.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgreementsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('minNoticeDays: $minNoticeDays, ')
          ..write('penaltyMinor: $penaltyMinor, ')
          ..write('clauses: $clauses, ')
          ..write('withdrawalSameForAll: $withdrawalSameForAll, ')
          ..write(
            'withdrawalPerParticipantJson: $withdrawalPerParticipantJson, ',
          )
          ..write('agreementRulesJson: $agreementRulesJson, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProposalPackagesTable extends ProposalPackages
    with TableInfo<$ProposalPackagesTable, ProposalPackage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProposalPackagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeRevisionIdMeta = const VerificationMeta(
    'activeRevisionId',
  );
  @override
  late final GeneratedColumn<String> activeRevisionId = GeneratedColumn<String>(
    'active_revision_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingRevisionIdMeta = const VerificationMeta(
    'pendingRevisionId',
  );
  @override
  late final GeneratedColumn<String> pendingRevisionId =
      GeneratedColumn<String>(
        'pending_revision_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    activeRevisionId,
    pendingRevisionId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'proposal_packages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProposalPackage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('active_revision_id')) {
      context.handle(
        _activeRevisionIdMeta,
        activeRevisionId.isAcceptableOrUnknown(
          data['active_revision_id']!,
          _activeRevisionIdMeta,
        ),
      );
    }
    if (data.containsKey('pending_revision_id')) {
      context.handle(
        _pendingRevisionIdMeta,
        pendingRevisionId.isAcceptableOrUnknown(
          data['pending_revision_id']!,
          _pendingRevisionIdMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProposalPackage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProposalPackage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      activeRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_revision_id'],
      ),
      pendingRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_revision_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProposalPackagesTable createAlias(String alias) {
    return $ProposalPackagesTable(attachedDatabase, alias);
  }
}

class ProposalPackage extends DataClass implements Insertable<ProposalPackage> {
  final String id;
  final String planId;
  final String? activeRevisionId;
  final String? pendingRevisionId;
  final DateTime createdAt;
  const ProposalPackage({
    required this.id,
    required this.planId,
    this.activeRevisionId,
    this.pendingRevisionId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    if (!nullToAbsent || activeRevisionId != null) {
      map['active_revision_id'] = Variable<String>(activeRevisionId);
    }
    if (!nullToAbsent || pendingRevisionId != null) {
      map['pending_revision_id'] = Variable<String>(pendingRevisionId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProposalPackagesCompanion toCompanion(bool nullToAbsent) {
    return ProposalPackagesCompanion(
      id: Value(id),
      planId: Value(planId),
      activeRevisionId: activeRevisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeRevisionId),
      pendingRevisionId: pendingRevisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingRevisionId),
      createdAt: Value(createdAt),
    );
  }

  factory ProposalPackage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProposalPackage(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      activeRevisionId: serializer.fromJson<String?>(json['activeRevisionId']),
      pendingRevisionId: serializer.fromJson<String?>(
        json['pendingRevisionId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'activeRevisionId': serializer.toJson<String?>(activeRevisionId),
      'pendingRevisionId': serializer.toJson<String?>(pendingRevisionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProposalPackage copyWith({
    String? id,
    String? planId,
    Value<String?> activeRevisionId = const Value.absent(),
    Value<String?> pendingRevisionId = const Value.absent(),
    DateTime? createdAt,
  }) => ProposalPackage(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    activeRevisionId: activeRevisionId.present
        ? activeRevisionId.value
        : this.activeRevisionId,
    pendingRevisionId: pendingRevisionId.present
        ? pendingRevisionId.value
        : this.pendingRevisionId,
    createdAt: createdAt ?? this.createdAt,
  );
  ProposalPackage copyWithCompanion(ProposalPackagesCompanion data) {
    return ProposalPackage(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      activeRevisionId: data.activeRevisionId.present
          ? data.activeRevisionId.value
          : this.activeRevisionId,
      pendingRevisionId: data.pendingRevisionId.present
          ? data.pendingRevisionId.value
          : this.pendingRevisionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProposalPackage(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('activeRevisionId: $activeRevisionId, ')
          ..write('pendingRevisionId: $pendingRevisionId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, planId, activeRevisionId, pendingRevisionId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProposalPackage &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.activeRevisionId == this.activeRevisionId &&
          other.pendingRevisionId == this.pendingRevisionId &&
          other.createdAt == this.createdAt);
}

class ProposalPackagesCompanion extends UpdateCompanion<ProposalPackage> {
  final Value<String> id;
  final Value<String> planId;
  final Value<String?> activeRevisionId;
  final Value<String?> pendingRevisionId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProposalPackagesCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.activeRevisionId = const Value.absent(),
    this.pendingRevisionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProposalPackagesCompanion.insert({
    required String id,
    required String planId,
    this.activeRevisionId = const Value.absent(),
    this.pendingRevisionId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       createdAt = Value(createdAt);
  static Insertable<ProposalPackage> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<String>? activeRevisionId,
    Expression<String>? pendingRevisionId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (activeRevisionId != null) 'active_revision_id': activeRevisionId,
      if (pendingRevisionId != null) 'pending_revision_id': pendingRevisionId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProposalPackagesCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<String?>? activeRevisionId,
    Value<String?>? pendingRevisionId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProposalPackagesCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      activeRevisionId: activeRevisionId ?? this.activeRevisionId,
      pendingRevisionId: pendingRevisionId ?? this.pendingRevisionId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (activeRevisionId.present) {
      map['active_revision_id'] = Variable<String>(activeRevisionId.value);
    }
    if (pendingRevisionId.present) {
      map['pending_revision_id'] = Variable<String>(pendingRevisionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProposalPackagesCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('activeRevisionId: $activeRevisionId, ')
          ..write('pendingRevisionId: $pendingRevisionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProposalRevisionsTable extends ProposalRevisions
    with TableInfo<$ProposalRevisionsTable, ProposalRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProposalRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageIdMeta = const VerificationMeta(
    'packageId',
  );
  @override
  late final GeneratedColumn<String> packageId = GeneratedColumn<String>(
    'package_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proposerParticipantIdMeta =
      const VerificationMeta('proposerParticipantId');
  @override
  late final GeneratedColumn<String> proposerParticipantId =
      GeneratedColumn<String>(
        'proposer_participant_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packageId,
    contentHash,
    proposerParticipantId,
    payloadJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'proposal_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProposalRevision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('package_id')) {
      context.handle(
        _packageIdMeta,
        packageId.isAcceptableOrUnknown(data['package_id']!, _packageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packageIdMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('proposer_participant_id')) {
      context.handle(
        _proposerParticipantIdMeta,
        proposerParticipantId.isAcceptableOrUnknown(
          data['proposer_participant_id']!,
          _proposerParticipantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proposerParticipantIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProposalRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProposalRevision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      packageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_id'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      proposerParticipantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proposer_participant_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProposalRevisionsTable createAlias(String alias) {
    return $ProposalRevisionsTable(attachedDatabase, alias);
  }
}

class ProposalRevision extends DataClass
    implements Insertable<ProposalRevision> {
  final String id;
  final String packageId;
  final String contentHash;
  final String proposerParticipantId;
  final String payloadJson;
  final DateTime createdAt;
  const ProposalRevision({
    required this.id,
    required this.packageId,
    required this.contentHash,
    required this.proposerParticipantId,
    required this.payloadJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['package_id'] = Variable<String>(packageId);
    map['content_hash'] = Variable<String>(contentHash);
    map['proposer_participant_id'] = Variable<String>(proposerParticipantId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProposalRevisionsCompanion toCompanion(bool nullToAbsent) {
    return ProposalRevisionsCompanion(
      id: Value(id),
      packageId: Value(packageId),
      contentHash: Value(contentHash),
      proposerParticipantId: Value(proposerParticipantId),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
    );
  }

  factory ProposalRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProposalRevision(
      id: serializer.fromJson<String>(json['id']),
      packageId: serializer.fromJson<String>(json['packageId']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      proposerParticipantId: serializer.fromJson<String>(
        json['proposerParticipantId'],
      ),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'packageId': serializer.toJson<String>(packageId),
      'contentHash': serializer.toJson<String>(contentHash),
      'proposerParticipantId': serializer.toJson<String>(proposerParticipantId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProposalRevision copyWith({
    String? id,
    String? packageId,
    String? contentHash,
    String? proposerParticipantId,
    String? payloadJson,
    DateTime? createdAt,
  }) => ProposalRevision(
    id: id ?? this.id,
    packageId: packageId ?? this.packageId,
    contentHash: contentHash ?? this.contentHash,
    proposerParticipantId: proposerParticipantId ?? this.proposerParticipantId,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
  );
  ProposalRevision copyWithCompanion(ProposalRevisionsCompanion data) {
    return ProposalRevision(
      id: data.id.present ? data.id.value : this.id,
      packageId: data.packageId.present ? data.packageId.value : this.packageId,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      proposerParticipantId: data.proposerParticipantId.present
          ? data.proposerParticipantId.value
          : this.proposerParticipantId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProposalRevision(')
          ..write('id: $id, ')
          ..write('packageId: $packageId, ')
          ..write('contentHash: $contentHash, ')
          ..write('proposerParticipantId: $proposerParticipantId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    packageId,
    contentHash,
    proposerParticipantId,
    payloadJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProposalRevision &&
          other.id == this.id &&
          other.packageId == this.packageId &&
          other.contentHash == this.contentHash &&
          other.proposerParticipantId == this.proposerParticipantId &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt);
}

class ProposalRevisionsCompanion extends UpdateCompanion<ProposalRevision> {
  final Value<String> id;
  final Value<String> packageId;
  final Value<String> contentHash;
  final Value<String> proposerParticipantId;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProposalRevisionsCompanion({
    this.id = const Value.absent(),
    this.packageId = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.proposerParticipantId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProposalRevisionsCompanion.insert({
    required String id,
    required String packageId,
    required String contentHash,
    required String proposerParticipantId,
    required String payloadJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       packageId = Value(packageId),
       contentHash = Value(contentHash),
       proposerParticipantId = Value(proposerParticipantId),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<ProposalRevision> custom({
    Expression<String>? id,
    Expression<String>? packageId,
    Expression<String>? contentHash,
    Expression<String>? proposerParticipantId,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageId != null) 'package_id': packageId,
      if (contentHash != null) 'content_hash': contentHash,
      if (proposerParticipantId != null)
        'proposer_participant_id': proposerParticipantId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProposalRevisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? packageId,
    Value<String>? contentHash,
    Value<String>? proposerParticipantId,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProposalRevisionsCompanion(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      contentHash: contentHash ?? this.contentHash,
      proposerParticipantId:
          proposerParticipantId ?? this.proposerParticipantId,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (packageId.present) {
      map['package_id'] = Variable<String>(packageId.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (proposerParticipantId.present) {
      map['proposer_participant_id'] = Variable<String>(
        proposerParticipantId.value,
      );
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProposalRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('packageId: $packageId, ')
          ..write('contentHash: $contentHash, ')
          ..write('proposerParticipantId: $proposerParticipantId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProposalResponsesTable extends ProposalResponses
    with TableInfo<$ProposalResponsesTable, ProposalResponse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProposalResponsesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionIdMeta = const VerificationMeta(
    'revisionId',
  );
  @override
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
    'revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _participantIdMeta = const VerificationMeta(
    'participantId',
  );
  @override
  late final GeneratedColumn<String> participantId = GeneratedColumn<String>(
    'participant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _respondedAtMeta = const VerificationMeta(
    'respondedAt',
  );
  @override
  late final GeneratedColumn<DateTime> respondedAt = GeneratedColumn<DateTime>(
    'responded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    revisionId,
    participantId,
    status,
    respondedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'proposal_responses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProposalResponse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('revision_id')) {
      context.handle(
        _revisionIdMeta,
        revisionId.isAcceptableOrUnknown(data['revision_id']!, _revisionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    if (data.containsKey('participant_id')) {
      context.handle(
        _participantIdMeta,
        participantId.isAcceptableOrUnknown(
          data['participant_id']!,
          _participantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('responded_at')) {
      context.handle(
        _respondedAtMeta,
        respondedAt.isAcceptableOrUnknown(
          data['responded_at']!,
          _respondedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProposalResponse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProposalResponse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      revisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_id'],
      )!,
      participantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      respondedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}responded_at'],
      ),
    );
  }

  @override
  $ProposalResponsesTable createAlias(String alias) {
    return $ProposalResponsesTable(attachedDatabase, alias);
  }
}

class ProposalResponse extends DataClass
    implements Insertable<ProposalResponse> {
  final String id;
  final String revisionId;
  final String participantId;
  final String status;
  final DateTime? respondedAt;
  const ProposalResponse({
    required this.id,
    required this.revisionId,
    required this.participantId,
    required this.status,
    this.respondedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['revision_id'] = Variable<String>(revisionId);
    map['participant_id'] = Variable<String>(participantId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || respondedAt != null) {
      map['responded_at'] = Variable<DateTime>(respondedAt);
    }
    return map;
  }

  ProposalResponsesCompanion toCompanion(bool nullToAbsent) {
    return ProposalResponsesCompanion(
      id: Value(id),
      revisionId: Value(revisionId),
      participantId: Value(participantId),
      status: Value(status),
      respondedAt: respondedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(respondedAt),
    );
  }

  factory ProposalResponse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProposalResponse(
      id: serializer.fromJson<String>(json['id']),
      revisionId: serializer.fromJson<String>(json['revisionId']),
      participantId: serializer.fromJson<String>(json['participantId']),
      status: serializer.fromJson<String>(json['status']),
      respondedAt: serializer.fromJson<DateTime?>(json['respondedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'revisionId': serializer.toJson<String>(revisionId),
      'participantId': serializer.toJson<String>(participantId),
      'status': serializer.toJson<String>(status),
      'respondedAt': serializer.toJson<DateTime?>(respondedAt),
    };
  }

  ProposalResponse copyWith({
    String? id,
    String? revisionId,
    String? participantId,
    String? status,
    Value<DateTime?> respondedAt = const Value.absent(),
  }) => ProposalResponse(
    id: id ?? this.id,
    revisionId: revisionId ?? this.revisionId,
    participantId: participantId ?? this.participantId,
    status: status ?? this.status,
    respondedAt: respondedAt.present ? respondedAt.value : this.respondedAt,
  );
  ProposalResponse copyWithCompanion(ProposalResponsesCompanion data) {
    return ProposalResponse(
      id: data.id.present ? data.id.value : this.id,
      revisionId: data.revisionId.present
          ? data.revisionId.value
          : this.revisionId,
      participantId: data.participantId.present
          ? data.participantId.value
          : this.participantId,
      status: data.status.present ? data.status.value : this.status,
      respondedAt: data.respondedAt.present
          ? data.respondedAt.value
          : this.respondedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProposalResponse(')
          ..write('id: $id, ')
          ..write('revisionId: $revisionId, ')
          ..write('participantId: $participantId, ')
          ..write('status: $status, ')
          ..write('respondedAt: $respondedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, revisionId, participantId, status, respondedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProposalResponse &&
          other.id == this.id &&
          other.revisionId == this.revisionId &&
          other.participantId == this.participantId &&
          other.status == this.status &&
          other.respondedAt == this.respondedAt);
}

class ProposalResponsesCompanion extends UpdateCompanion<ProposalResponse> {
  final Value<String> id;
  final Value<String> revisionId;
  final Value<String> participantId;
  final Value<String> status;
  final Value<DateTime?> respondedAt;
  final Value<int> rowid;
  const ProposalResponsesCompanion({
    this.id = const Value.absent(),
    this.revisionId = const Value.absent(),
    this.participantId = const Value.absent(),
    this.status = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProposalResponsesCompanion.insert({
    required String id,
    required String revisionId,
    required String participantId,
    required String status,
    this.respondedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       revisionId = Value(revisionId),
       participantId = Value(participantId),
       status = Value(status);
  static Insertable<ProposalResponse> custom({
    Expression<String>? id,
    Expression<String>? revisionId,
    Expression<String>? participantId,
    Expression<String>? status,
    Expression<DateTime>? respondedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (revisionId != null) 'revision_id': revisionId,
      if (participantId != null) 'participant_id': participantId,
      if (status != null) 'status': status,
      if (respondedAt != null) 'responded_at': respondedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProposalResponsesCompanion copyWith({
    Value<String>? id,
    Value<String>? revisionId,
    Value<String>? participantId,
    Value<String>? status,
    Value<DateTime?>? respondedAt,
    Value<int>? rowid,
  }) {
    return ProposalResponsesCompanion(
      id: id ?? this.id,
      revisionId: revisionId ?? this.revisionId,
      participantId: participantId ?? this.participantId,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (participantId.present) {
      map['participant_id'] = Variable<String>(participantId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (respondedAt.present) {
      map['responded_at'] = Variable<DateTime>(respondedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProposalResponsesCompanion(')
          ..write('id: $id, ')
          ..write('revisionId: $revisionId, ')
          ..write('participantId: $participantId, ')
          ..write('status: $status, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelayActivityLogEntriesTable extends RelayActivityLogEntries
    with TableInfo<$RelayActivityLogEntriesTable, RelayActivityLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelayActivityLogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initiatorKindMeta = const VerificationMeta(
    'initiatorKind',
  );
  @override
  late final GeneratedColumn<String> initiatorKind = GeneratedColumn<String>(
    'initiator_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initiatorContactIdMeta =
      const VerificationMeta('initiatorContactId');
  @override
  late final GeneratedColumn<String> initiatorContactId =
      GeneratedColumn<String>(
        'initiator_contact_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _initiatorDisplayNameMeta =
      const VerificationMeta('initiatorDisplayName');
  @override
  late final GeneratedColumn<String> initiatorDisplayName =
      GeneratedColumn<String>(
        'initiator_display_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packageIdMeta = const VerificationMeta(
    'packageId',
  );
  @override
  late final GeneratedColumn<String> packageId = GeneratedColumn<String>(
    'package_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionIdMeta = const VerificationMeta(
    'revisionId',
  );
  @override
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
    'revision_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailsJsonMeta = const VerificationMeta(
    'detailsJson',
  );
  @override
  late final GeneratedColumn<String> detailsJson = GeneratedColumn<String>(
    'details_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    occurredAt,
    kind,
    initiatorKind,
    initiatorContactId,
    initiatorDisplayName,
    planId,
    packageId,
    revisionId,
    detailsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relay_activity_log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<RelayActivityLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('initiator_kind')) {
      context.handle(
        _initiatorKindMeta,
        initiatorKind.isAcceptableOrUnknown(
          data['initiator_kind']!,
          _initiatorKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initiatorKindMeta);
    }
    if (data.containsKey('initiator_contact_id')) {
      context.handle(
        _initiatorContactIdMeta,
        initiatorContactId.isAcceptableOrUnknown(
          data['initiator_contact_id']!,
          _initiatorContactIdMeta,
        ),
      );
    }
    if (data.containsKey('initiator_display_name')) {
      context.handle(
        _initiatorDisplayNameMeta,
        initiatorDisplayName.isAcceptableOrUnknown(
          data['initiator_display_name']!,
          _initiatorDisplayNameMeta,
        ),
      );
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    }
    if (data.containsKey('package_id')) {
      context.handle(
        _packageIdMeta,
        packageId.isAcceptableOrUnknown(data['package_id']!, _packageIdMeta),
      );
    }
    if (data.containsKey('revision_id')) {
      context.handle(
        _revisionIdMeta,
        revisionId.isAcceptableOrUnknown(data['revision_id']!, _revisionIdMeta),
      );
    }
    if (data.containsKey('details_json')) {
      context.handle(
        _detailsJsonMeta,
        detailsJson.isAcceptableOrUnknown(
          data['details_json']!,
          _detailsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RelayActivityLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RelayActivityLogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      initiatorKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initiator_kind'],
      )!,
      initiatorContactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initiator_contact_id'],
      ),
      initiatorDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initiator_display_name'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      ),
      packageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_id'],
      ),
      revisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_id'],
      ),
      detailsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details_json'],
      )!,
    );
  }

  @override
  $RelayActivityLogEntriesTable createAlias(String alias) {
    return $RelayActivityLogEntriesTable(attachedDatabase, alias);
  }
}

class RelayActivityLogEntry extends DataClass
    implements Insertable<RelayActivityLogEntry> {
  final String id;
  final DateTime occurredAt;
  final String kind;
  final String initiatorKind;
  final String? initiatorContactId;
  final String initiatorDisplayName;
  final String? planId;
  final String? packageId;
  final String? revisionId;
  final String detailsJson;
  const RelayActivityLogEntry({
    required this.id,
    required this.occurredAt,
    required this.kind,
    required this.initiatorKind,
    this.initiatorContactId,
    required this.initiatorDisplayName,
    this.planId,
    this.packageId,
    this.revisionId,
    required this.detailsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['kind'] = Variable<String>(kind);
    map['initiator_kind'] = Variable<String>(initiatorKind);
    if (!nullToAbsent || initiatorContactId != null) {
      map['initiator_contact_id'] = Variable<String>(initiatorContactId);
    }
    map['initiator_display_name'] = Variable<String>(initiatorDisplayName);
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<String>(planId);
    }
    if (!nullToAbsent || packageId != null) {
      map['package_id'] = Variable<String>(packageId);
    }
    if (!nullToAbsent || revisionId != null) {
      map['revision_id'] = Variable<String>(revisionId);
    }
    map['details_json'] = Variable<String>(detailsJson);
    return map;
  }

  RelayActivityLogEntriesCompanion toCompanion(bool nullToAbsent) {
    return RelayActivityLogEntriesCompanion(
      id: Value(id),
      occurredAt: Value(occurredAt),
      kind: Value(kind),
      initiatorKind: Value(initiatorKind),
      initiatorContactId: initiatorContactId == null && nullToAbsent
          ? const Value.absent()
          : Value(initiatorContactId),
      initiatorDisplayName: Value(initiatorDisplayName),
      planId: planId == null && nullToAbsent
          ? const Value.absent()
          : Value(planId),
      packageId: packageId == null && nullToAbsent
          ? const Value.absent()
          : Value(packageId),
      revisionId: revisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(revisionId),
      detailsJson: Value(detailsJson),
    );
  }

  factory RelayActivityLogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RelayActivityLogEntry(
      id: serializer.fromJson<String>(json['id']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      kind: serializer.fromJson<String>(json['kind']),
      initiatorKind: serializer.fromJson<String>(json['initiatorKind']),
      initiatorContactId: serializer.fromJson<String?>(
        json['initiatorContactId'],
      ),
      initiatorDisplayName: serializer.fromJson<String>(
        json['initiatorDisplayName'],
      ),
      planId: serializer.fromJson<String?>(json['planId']),
      packageId: serializer.fromJson<String?>(json['packageId']),
      revisionId: serializer.fromJson<String?>(json['revisionId']),
      detailsJson: serializer.fromJson<String>(json['detailsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'kind': serializer.toJson<String>(kind),
      'initiatorKind': serializer.toJson<String>(initiatorKind),
      'initiatorContactId': serializer.toJson<String?>(initiatorContactId),
      'initiatorDisplayName': serializer.toJson<String>(initiatorDisplayName),
      'planId': serializer.toJson<String?>(planId),
      'packageId': serializer.toJson<String?>(packageId),
      'revisionId': serializer.toJson<String?>(revisionId),
      'detailsJson': serializer.toJson<String>(detailsJson),
    };
  }

  RelayActivityLogEntry copyWith({
    String? id,
    DateTime? occurredAt,
    String? kind,
    String? initiatorKind,
    Value<String?> initiatorContactId = const Value.absent(),
    String? initiatorDisplayName,
    Value<String?> planId = const Value.absent(),
    Value<String?> packageId = const Value.absent(),
    Value<String?> revisionId = const Value.absent(),
    String? detailsJson,
  }) => RelayActivityLogEntry(
    id: id ?? this.id,
    occurredAt: occurredAt ?? this.occurredAt,
    kind: kind ?? this.kind,
    initiatorKind: initiatorKind ?? this.initiatorKind,
    initiatorContactId: initiatorContactId.present
        ? initiatorContactId.value
        : this.initiatorContactId,
    initiatorDisplayName: initiatorDisplayName ?? this.initiatorDisplayName,
    planId: planId.present ? planId.value : this.planId,
    packageId: packageId.present ? packageId.value : this.packageId,
    revisionId: revisionId.present ? revisionId.value : this.revisionId,
    detailsJson: detailsJson ?? this.detailsJson,
  );
  RelayActivityLogEntry copyWithCompanion(
    RelayActivityLogEntriesCompanion data,
  ) {
    return RelayActivityLogEntry(
      id: data.id.present ? data.id.value : this.id,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      initiatorKind: data.initiatorKind.present
          ? data.initiatorKind.value
          : this.initiatorKind,
      initiatorContactId: data.initiatorContactId.present
          ? data.initiatorContactId.value
          : this.initiatorContactId,
      initiatorDisplayName: data.initiatorDisplayName.present
          ? data.initiatorDisplayName.value
          : this.initiatorDisplayName,
      planId: data.planId.present ? data.planId.value : this.planId,
      packageId: data.packageId.present ? data.packageId.value : this.packageId,
      revisionId: data.revisionId.present
          ? data.revisionId.value
          : this.revisionId,
      detailsJson: data.detailsJson.present
          ? data.detailsJson.value
          : this.detailsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RelayActivityLogEntry(')
          ..write('id: $id, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('kind: $kind, ')
          ..write('initiatorKind: $initiatorKind, ')
          ..write('initiatorContactId: $initiatorContactId, ')
          ..write('initiatorDisplayName: $initiatorDisplayName, ')
          ..write('planId: $planId, ')
          ..write('packageId: $packageId, ')
          ..write('revisionId: $revisionId, ')
          ..write('detailsJson: $detailsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    occurredAt,
    kind,
    initiatorKind,
    initiatorContactId,
    initiatorDisplayName,
    planId,
    packageId,
    revisionId,
    detailsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RelayActivityLogEntry &&
          other.id == this.id &&
          other.occurredAt == this.occurredAt &&
          other.kind == this.kind &&
          other.initiatorKind == this.initiatorKind &&
          other.initiatorContactId == this.initiatorContactId &&
          other.initiatorDisplayName == this.initiatorDisplayName &&
          other.planId == this.planId &&
          other.packageId == this.packageId &&
          other.revisionId == this.revisionId &&
          other.detailsJson == this.detailsJson);
}

class RelayActivityLogEntriesCompanion
    extends UpdateCompanion<RelayActivityLogEntry> {
  final Value<String> id;
  final Value<DateTime> occurredAt;
  final Value<String> kind;
  final Value<String> initiatorKind;
  final Value<String?> initiatorContactId;
  final Value<String> initiatorDisplayName;
  final Value<String?> planId;
  final Value<String?> packageId;
  final Value<String?> revisionId;
  final Value<String> detailsJson;
  final Value<int> rowid;
  const RelayActivityLogEntriesCompanion({
    this.id = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.initiatorKind = const Value.absent(),
    this.initiatorContactId = const Value.absent(),
    this.initiatorDisplayName = const Value.absent(),
    this.planId = const Value.absent(),
    this.packageId = const Value.absent(),
    this.revisionId = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelayActivityLogEntriesCompanion.insert({
    required String id,
    required DateTime occurredAt,
    required String kind,
    required String initiatorKind,
    this.initiatorContactId = const Value.absent(),
    this.initiatorDisplayName = const Value.absent(),
    this.planId = const Value.absent(),
    this.packageId = const Value.absent(),
    this.revisionId = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       occurredAt = Value(occurredAt),
       kind = Value(kind),
       initiatorKind = Value(initiatorKind);
  static Insertable<RelayActivityLogEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? occurredAt,
    Expression<String>? kind,
    Expression<String>? initiatorKind,
    Expression<String>? initiatorContactId,
    Expression<String>? initiatorDisplayName,
    Expression<String>? planId,
    Expression<String>? packageId,
    Expression<String>? revisionId,
    Expression<String>? detailsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (kind != null) 'kind': kind,
      if (initiatorKind != null) 'initiator_kind': initiatorKind,
      if (initiatorContactId != null)
        'initiator_contact_id': initiatorContactId,
      if (initiatorDisplayName != null)
        'initiator_display_name': initiatorDisplayName,
      if (planId != null) 'plan_id': planId,
      if (packageId != null) 'package_id': packageId,
      if (revisionId != null) 'revision_id': revisionId,
      if (detailsJson != null) 'details_json': detailsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelayActivityLogEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? occurredAt,
    Value<String>? kind,
    Value<String>? initiatorKind,
    Value<String?>? initiatorContactId,
    Value<String>? initiatorDisplayName,
    Value<String?>? planId,
    Value<String?>? packageId,
    Value<String?>? revisionId,
    Value<String>? detailsJson,
    Value<int>? rowid,
  }) {
    return RelayActivityLogEntriesCompanion(
      id: id ?? this.id,
      occurredAt: occurredAt ?? this.occurredAt,
      kind: kind ?? this.kind,
      initiatorKind: initiatorKind ?? this.initiatorKind,
      initiatorContactId: initiatorContactId ?? this.initiatorContactId,
      initiatorDisplayName: initiatorDisplayName ?? this.initiatorDisplayName,
      planId: planId ?? this.planId,
      packageId: packageId ?? this.packageId,
      revisionId: revisionId ?? this.revisionId,
      detailsJson: detailsJson ?? this.detailsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (initiatorKind.present) {
      map['initiator_kind'] = Variable<String>(initiatorKind.value);
    }
    if (initiatorContactId.present) {
      map['initiator_contact_id'] = Variable<String>(initiatorContactId.value);
    }
    if (initiatorDisplayName.present) {
      map['initiator_display_name'] = Variable<String>(
        initiatorDisplayName.value,
      );
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (packageId.present) {
      map['package_id'] = Variable<String>(packageId.value);
    }
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (detailsJson.present) {
      map['details_json'] = Variable<String>(detailsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelayActivityLogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('kind: $kind, ')
          ..write('initiatorKind: $initiatorKind, ')
          ..write('initiatorContactId: $initiatorContactId, ')
          ..write('initiatorDisplayName: $initiatorDisplayName, ')
          ..write('planId: $planId, ')
          ..write('packageId: $packageId, ')
          ..write('revisionId: $revisionId, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _avatarIdMeta = const VerificationMeta(
    'avatarId',
  );
  @override
  late final GeneratedColumn<String> avatarId = GeneratedColumn<String>(
    'avatar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isBlockedMeta = const VerificationMeta(
    'isBlocked',
  );
  @override
  late final GeneratedColumn<bool> isBlocked = GeneratedColumn<bool>(
    'is_blocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_blocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _relayRoutingIdMeta = const VerificationMeta(
    'relayRoutingId',
  );
  @override
  late final GeneratedColumn<String> relayRoutingId = GeneratedColumn<String>(
    'relay_routing_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peerPublicMaterialMeta =
      const VerificationMeta('peerPublicMaterial');
  @override
  late final GeneratedColumn<String> peerPublicMaterial =
      GeneratedColumn<String>(
        'peer_public_material',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localDisplayLabelMeta = const VerificationMeta(
    'localDisplayLabel',
  );
  @override
  late final GeneratedColumn<String> localDisplayLabel =
      GeneratedColumn<String>(
        'local_display_label',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _theirLabelForMeMeta = const VerificationMeta(
    'theirLabelForMe',
  );
  @override
  late final GeneratedColumn<String> theirLabelForMe = GeneratedColumn<String>(
    'their_label_for_me',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disconnectedAtMeta = const VerificationMeta(
    'disconnectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> disconnectedAt =
      GeneratedColumn<DateTime>(
        'disconnected_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    displayName,
    avatarId,
    notes,
    isBlocked,
    relayRoutingId,
    peerPublicMaterial,
    localDisplayLabel,
    theirLabelForMe,
    disconnectedAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
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
    if (data.containsKey('avatar_id')) {
      context.handle(
        _avatarIdMeta,
        avatarId.isAcceptableOrUnknown(data['avatar_id']!, _avatarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_avatarIdMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_blocked')) {
      context.handle(
        _isBlockedMeta,
        isBlocked.isAcceptableOrUnknown(data['is_blocked']!, _isBlockedMeta),
      );
    }
    if (data.containsKey('relay_routing_id')) {
      context.handle(
        _relayRoutingIdMeta,
        relayRoutingId.isAcceptableOrUnknown(
          data['relay_routing_id']!,
          _relayRoutingIdMeta,
        ),
      );
    }
    if (data.containsKey('peer_public_material')) {
      context.handle(
        _peerPublicMaterialMeta,
        peerPublicMaterial.isAcceptableOrUnknown(
          data['peer_public_material']!,
          _peerPublicMaterialMeta,
        ),
      );
    }
    if (data.containsKey('local_display_label')) {
      context.handle(
        _localDisplayLabelMeta,
        localDisplayLabel.isAcceptableOrUnknown(
          data['local_display_label']!,
          _localDisplayLabelMeta,
        ),
      );
    }
    if (data.containsKey('their_label_for_me')) {
      context.handle(
        _theirLabelForMeMeta,
        theirLabelForMe.isAcceptableOrUnknown(
          data['their_label_for_me']!,
          _theirLabelForMeMeta,
        ),
      );
    }
    if (data.containsKey('disconnected_at')) {
      context.handle(
        _disconnectedAtMeta,
        disconnectedAt.isAcceptableOrUnknown(
          data['disconnected_at']!,
          _disconnectedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      avatarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_id'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      isBlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_blocked'],
      )!,
      relayRoutingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_routing_id'],
      ),
      peerPublicMaterial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_public_material'],
      ),
      localDisplayLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_display_label'],
      ),
      theirLabelForMe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}their_label_for_me'],
      ),
      disconnectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}disconnected_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final String id;

  /// `local-only` | `connected` | `archived`.
  final String kind;
  final String displayName;
  final String avatarId;

  /// Free-text notes the local user keeps about this contact.
  final String notes;

  /// Local-only flag. When true, inbound envelopes from this contact are
  /// dropped on receipt regardless of their kind.
  final bool isBlocked;

  /// Opaque relay routing identifier exchanged during the handshake.
  /// Populated only when kind = connected.
  final String? relayRoutingId;

  /// Peer public key material (base64 or similar) exchanged during the
  /// handshake. Populated only when kind = connected.
  final String? peerPublicMaterial;

  /// Optional label **only on this device** for how the user wants this
  /// contact to appear in lists. When null or empty, [displayName] is the
  /// effective name (peer canonical / stub name).
  final String? localDisplayLabel;

  /// How **this contact** currently labels the **local user** on their
  /// device, learned from encrypted steady-state profile updates. Null when
  /// unknown or never shared.
  final String? theirLabelForMe;

  /// Set when a previously `connected` contact was demoted after disconnect.
  /// Null for stubs that were never connected.
  final DateTime? disconnectedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// When the Contact was logically deleted by the local user.
  /// Module participant rows that referenced this contact continue to render
  /// from their stored snapshot (`Participants.displayName` / `avatarId`).
  final DateTime? deletedAt;
  const Contact({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.avatarId,
    required this.notes,
    required this.isBlocked,
    this.relayRoutingId,
    this.peerPublicMaterial,
    this.localDisplayLabel,
    this.theirLabelForMe,
    this.disconnectedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['display_name'] = Variable<String>(displayName);
    map['avatar_id'] = Variable<String>(avatarId);
    map['notes'] = Variable<String>(notes);
    map['is_blocked'] = Variable<bool>(isBlocked);
    if (!nullToAbsent || relayRoutingId != null) {
      map['relay_routing_id'] = Variable<String>(relayRoutingId);
    }
    if (!nullToAbsent || peerPublicMaterial != null) {
      map['peer_public_material'] = Variable<String>(peerPublicMaterial);
    }
    if (!nullToAbsent || localDisplayLabel != null) {
      map['local_display_label'] = Variable<String>(localDisplayLabel);
    }
    if (!nullToAbsent || theirLabelForMe != null) {
      map['their_label_for_me'] = Variable<String>(theirLabelForMe);
    }
    if (!nullToAbsent || disconnectedAt != null) {
      map['disconnected_at'] = Variable<DateTime>(disconnectedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      kind: Value(kind),
      displayName: Value(displayName),
      avatarId: Value(avatarId),
      notes: Value(notes),
      isBlocked: Value(isBlocked),
      relayRoutingId: relayRoutingId == null && nullToAbsent
          ? const Value.absent()
          : Value(relayRoutingId),
      peerPublicMaterial: peerPublicMaterial == null && nullToAbsent
          ? const Value.absent()
          : Value(peerPublicMaterial),
      localDisplayLabel: localDisplayLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(localDisplayLabel),
      theirLabelForMe: theirLabelForMe == null && nullToAbsent
          ? const Value.absent()
          : Value(theirLabelForMe),
      disconnectedAt: disconnectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(disconnectedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Contact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      displayName: serializer.fromJson<String>(json['displayName']),
      avatarId: serializer.fromJson<String>(json['avatarId']),
      notes: serializer.fromJson<String>(json['notes']),
      isBlocked: serializer.fromJson<bool>(json['isBlocked']),
      relayRoutingId: serializer.fromJson<String?>(json['relayRoutingId']),
      peerPublicMaterial: serializer.fromJson<String?>(
        json['peerPublicMaterial'],
      ),
      localDisplayLabel: serializer.fromJson<String?>(
        json['localDisplayLabel'],
      ),
      theirLabelForMe: serializer.fromJson<String?>(json['theirLabelForMe']),
      disconnectedAt: serializer.fromJson<DateTime?>(json['disconnectedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'displayName': serializer.toJson<String>(displayName),
      'avatarId': serializer.toJson<String>(avatarId),
      'notes': serializer.toJson<String>(notes),
      'isBlocked': serializer.toJson<bool>(isBlocked),
      'relayRoutingId': serializer.toJson<String?>(relayRoutingId),
      'peerPublicMaterial': serializer.toJson<String?>(peerPublicMaterial),
      'localDisplayLabel': serializer.toJson<String?>(localDisplayLabel),
      'theirLabelForMe': serializer.toJson<String?>(theirLabelForMe),
      'disconnectedAt': serializer.toJson<DateTime?>(disconnectedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Contact copyWith({
    String? id,
    String? kind,
    String? displayName,
    String? avatarId,
    String? notes,
    bool? isBlocked,
    Value<String?> relayRoutingId = const Value.absent(),
    Value<String?> peerPublicMaterial = const Value.absent(),
    Value<String?> localDisplayLabel = const Value.absent(),
    Value<String?> theirLabelForMe = const Value.absent(),
    Value<DateTime?> disconnectedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Contact(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    displayName: displayName ?? this.displayName,
    avatarId: avatarId ?? this.avatarId,
    notes: notes ?? this.notes,
    isBlocked: isBlocked ?? this.isBlocked,
    relayRoutingId: relayRoutingId.present
        ? relayRoutingId.value
        : this.relayRoutingId,
    peerPublicMaterial: peerPublicMaterial.present
        ? peerPublicMaterial.value
        : this.peerPublicMaterial,
    localDisplayLabel: localDisplayLabel.present
        ? localDisplayLabel.value
        : this.localDisplayLabel,
    theirLabelForMe: theirLabelForMe.present
        ? theirLabelForMe.value
        : this.theirLabelForMe,
    disconnectedAt: disconnectedAt.present
        ? disconnectedAt.value
        : this.disconnectedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarId: data.avatarId.present ? data.avatarId.value : this.avatarId,
      notes: data.notes.present ? data.notes.value : this.notes,
      isBlocked: data.isBlocked.present ? data.isBlocked.value : this.isBlocked,
      relayRoutingId: data.relayRoutingId.present
          ? data.relayRoutingId.value
          : this.relayRoutingId,
      peerPublicMaterial: data.peerPublicMaterial.present
          ? data.peerPublicMaterial.value
          : this.peerPublicMaterial,
      localDisplayLabel: data.localDisplayLabel.present
          ? data.localDisplayLabel.value
          : this.localDisplayLabel,
      theirLabelForMe: data.theirLabelForMe.present
          ? data.theirLabelForMe.value
          : this.theirLabelForMe,
      disconnectedAt: data.disconnectedAt.present
          ? data.disconnectedAt.value
          : this.disconnectedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('avatarId: $avatarId, ')
          ..write('notes: $notes, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('relayRoutingId: $relayRoutingId, ')
          ..write('peerPublicMaterial: $peerPublicMaterial, ')
          ..write('localDisplayLabel: $localDisplayLabel, ')
          ..write('theirLabelForMe: $theirLabelForMe, ')
          ..write('disconnectedAt: $disconnectedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    displayName,
    avatarId,
    notes,
    isBlocked,
    relayRoutingId,
    peerPublicMaterial,
    localDisplayLabel,
    theirLabelForMe,
    disconnectedAt,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.displayName == this.displayName &&
          other.avatarId == this.avatarId &&
          other.notes == this.notes &&
          other.isBlocked == this.isBlocked &&
          other.relayRoutingId == this.relayRoutingId &&
          other.peerPublicMaterial == this.peerPublicMaterial &&
          other.localDisplayLabel == this.localDisplayLabel &&
          other.theirLabelForMe == this.theirLabelForMe &&
          other.disconnectedAt == this.disconnectedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> displayName;
  final Value<String> avatarId;
  final Value<String> notes;
  final Value<bool> isBlocked;
  final Value<String?> relayRoutingId;
  final Value<String?> peerPublicMaterial;
  final Value<String?> localDisplayLabel;
  final Value<String?> theirLabelForMe;
  final Value<DateTime?> disconnectedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.relayRoutingId = const Value.absent(),
    this.peerPublicMaterial = const Value.absent(),
    this.localDisplayLabel = const Value.absent(),
    this.theirLabelForMe = const Value.absent(),
    this.disconnectedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsCompanion.insert({
    required String id,
    required String kind,
    required String displayName,
    required String avatarId,
    this.notes = const Value.absent(),
    this.isBlocked = const Value.absent(),
    this.relayRoutingId = const Value.absent(),
    this.peerPublicMaterial = const Value.absent(),
    this.localDisplayLabel = const Value.absent(),
    this.theirLabelForMe = const Value.absent(),
    this.disconnectedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       displayName = Value(displayName),
       avatarId = Value(avatarId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Contact> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? displayName,
    Expression<String>? avatarId,
    Expression<String>? notes,
    Expression<bool>? isBlocked,
    Expression<String>? relayRoutingId,
    Expression<String>? peerPublicMaterial,
    Expression<String>? localDisplayLabel,
    Expression<String>? theirLabelForMe,
    Expression<DateTime>? disconnectedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (displayName != null) 'display_name': displayName,
      if (avatarId != null) 'avatar_id': avatarId,
      if (notes != null) 'notes': notes,
      if (isBlocked != null) 'is_blocked': isBlocked,
      if (relayRoutingId != null) 'relay_routing_id': relayRoutingId,
      if (peerPublicMaterial != null)
        'peer_public_material': peerPublicMaterial,
      if (localDisplayLabel != null) 'local_display_label': localDisplayLabel,
      if (theirLabelForMe != null) 'their_label_for_me': theirLabelForMe,
      if (disconnectedAt != null) 'disconnected_at': disconnectedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? displayName,
    Value<String>? avatarId,
    Value<String>? notes,
    Value<bool>? isBlocked,
    Value<String?>? relayRoutingId,
    Value<String?>? peerPublicMaterial,
    Value<String?>? localDisplayLabel,
    Value<String?>? theirLabelForMe,
    Value<DateTime?>? disconnectedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ContactsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      displayName: displayName ?? this.displayName,
      avatarId: avatarId ?? this.avatarId,
      notes: notes ?? this.notes,
      isBlocked: isBlocked ?? this.isBlocked,
      relayRoutingId: relayRoutingId ?? this.relayRoutingId,
      peerPublicMaterial: peerPublicMaterial ?? this.peerPublicMaterial,
      localDisplayLabel: localDisplayLabel ?? this.localDisplayLabel,
      theirLabelForMe: theirLabelForMe ?? this.theirLabelForMe,
      disconnectedAt: disconnectedAt ?? this.disconnectedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarId.present) {
      map['avatar_id'] = Variable<String>(avatarId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isBlocked.present) {
      map['is_blocked'] = Variable<bool>(isBlocked.value);
    }
    if (relayRoutingId.present) {
      map['relay_routing_id'] = Variable<String>(relayRoutingId.value);
    }
    if (peerPublicMaterial.present) {
      map['peer_public_material'] = Variable<String>(peerPublicMaterial.value);
    }
    if (localDisplayLabel.present) {
      map['local_display_label'] = Variable<String>(localDisplayLabel.value);
    }
    if (theirLabelForMe.present) {
      map['their_label_for_me'] = Variable<String>(theirLabelForMe.value);
    }
    if (disconnectedAt.present) {
      map['disconnected_at'] = Variable<DateTime>(disconnectedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('avatarId: $avatarId, ')
          ..write('notes: $notes, ')
          ..write('isBlocked: $isBlocked, ')
          ..write('relayRoutingId: $relayRoutingId, ')
          ..write('peerPublicMaterial: $peerPublicMaterial, ')
          ..write('localDisplayLabel: $localDisplayLabel, ')
          ..write('theirLabelForMe: $theirLabelForMe, ')
          ..write('disconnectedAt: $disconnectedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactInvitationsTable extends ContactInvitations
    with TableInfo<$ContactInvitationsTable, ContactInvitation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactInvitationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nonceMeta = const VerificationMeta('nonce');
  @override
  late final GeneratedColumn<String> nonce = GeneratedColumn<String>(
    'nonce',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consumedAtMeta = const VerificationMeta(
    'consumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
    'consumed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactStubIdMeta = const VerificationMeta(
    'contactStubId',
  );
  @override
  late final GeneratedColumn<String> contactStubId = GeneratedColumn<String>(
    'contact_stub_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nonce,
    status,
    createdAt,
    expiresAt,
    consumedAt,
    contactStubId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_invitations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactInvitation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nonce')) {
      context.handle(
        _nonceMeta,
        nonce.isAcceptableOrUnknown(data['nonce']!, _nonceMeta),
      );
    } else if (isInserting) {
      context.missing(_nonceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
        _consumedAtMeta,
        consumedAt.isAcceptableOrUnknown(data['consumed_at']!, _consumedAtMeta),
      );
    }
    if (data.containsKey('contact_stub_id')) {
      context.handle(
        _contactStubIdMeta,
        contactStubId.isAcceptableOrUnknown(
          data['contact_stub_id']!,
          _contactStubIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContactInvitation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactInvitation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nonce: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nonce'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      consumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consumed_at'],
      ),
      contactStubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_stub_id'],
      ),
    );
  }

  @override
  $ContactInvitationsTable createAlias(String alias) {
    return $ContactInvitationsTable(attachedDatabase, alias);
  }
}

class ContactInvitation extends DataClass
    implements Insertable<ContactInvitation> {
  /// Stable identifier; not the human-readable code.
  final String id;

  /// Opaque local copy of the nonce embedded in the invitation code.
  /// Consumed when a matching `hello` envelope is validated locally.
  final String nonce;

  /// `pending` | `used` | `expired` | `revoked`.
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// Set when the invitation has been consumed (used/revoked/expired).
  final DateTime? consumedAt;

  /// When the handshake completes, points to the Contact stub on this
  /// device that should be promoted to `connected`.
  final String? contactStubId;
  const ContactInvitation({
    required this.id,
    required this.nonce,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.consumedAt,
    this.contactStubId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nonce'] = Variable<String>(nonce);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    if (!nullToAbsent || consumedAt != null) {
      map['consumed_at'] = Variable<DateTime>(consumedAt);
    }
    if (!nullToAbsent || contactStubId != null) {
      map['contact_stub_id'] = Variable<String>(contactStubId);
    }
    return map;
  }

  ContactInvitationsCompanion toCompanion(bool nullToAbsent) {
    return ContactInvitationsCompanion(
      id: Value(id),
      nonce: Value(nonce),
      status: Value(status),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
      consumedAt: consumedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(consumedAt),
      contactStubId: contactStubId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactStubId),
    );
  }

  factory ContactInvitation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactInvitation(
      id: serializer.fromJson<String>(json['id']),
      nonce: serializer.fromJson<String>(json['nonce']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      consumedAt: serializer.fromJson<DateTime?>(json['consumedAt']),
      contactStubId: serializer.fromJson<String?>(json['contactStubId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nonce': serializer.toJson<String>(nonce),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'consumedAt': serializer.toJson<DateTime?>(consumedAt),
      'contactStubId': serializer.toJson<String?>(contactStubId),
    };
  }

  ContactInvitation copyWith({
    String? id,
    String? nonce,
    String? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    Value<DateTime?> consumedAt = const Value.absent(),
    Value<String?> contactStubId = const Value.absent(),
  }) => ContactInvitation(
    id: id ?? this.id,
    nonce: nonce ?? this.nonce,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    consumedAt: consumedAt.present ? consumedAt.value : this.consumedAt,
    contactStubId: contactStubId.present
        ? contactStubId.value
        : this.contactStubId,
  );
  ContactInvitation copyWithCompanion(ContactInvitationsCompanion data) {
    return ContactInvitation(
      id: data.id.present ? data.id.value : this.id,
      nonce: data.nonce.present ? data.nonce.value : this.nonce,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      consumedAt: data.consumedAt.present
          ? data.consumedAt.value
          : this.consumedAt,
      contactStubId: data.contactStubId.present
          ? data.contactStubId.value
          : this.contactStubId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactInvitation(')
          ..write('id: $id, ')
          ..write('nonce: $nonce, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('contactStubId: $contactStubId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nonce,
    status,
    createdAt,
    expiresAt,
    consumedAt,
    contactStubId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactInvitation &&
          other.id == this.id &&
          other.nonce == this.nonce &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt &&
          other.consumedAt == this.consumedAt &&
          other.contactStubId == this.contactStubId);
}

class ContactInvitationsCompanion extends UpdateCompanion<ContactInvitation> {
  final Value<String> id;
  final Value<String> nonce;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> expiresAt;
  final Value<DateTime?> consumedAt;
  final Value<String?> contactStubId;
  final Value<int> rowid;
  const ContactInvitationsCompanion({
    this.id = const Value.absent(),
    this.nonce = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.contactStubId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactInvitationsCompanion.insert({
    required String id,
    required String nonce,
    required String status,
    required DateTime createdAt,
    required DateTime expiresAt,
    this.consumedAt = const Value.absent(),
    this.contactStubId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nonce = Value(nonce),
       status = Value(status),
       createdAt = Value(createdAt),
       expiresAt = Value(expiresAt);
  static Insertable<ContactInvitation> custom({
    Expression<String>? id,
    Expression<String>? nonce,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? consumedAt,
    Expression<String>? contactStubId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nonce != null) 'nonce': nonce,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (contactStubId != null) 'contact_stub_id': contactStubId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactInvitationsCompanion copyWith({
    Value<String>? id,
    Value<String>? nonce,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? expiresAt,
    Value<DateTime?>? consumedAt,
    Value<String?>? contactStubId,
    Value<int>? rowid,
  }) {
    return ContactInvitationsCompanion(
      id: id ?? this.id,
      nonce: nonce ?? this.nonce,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      consumedAt: consumedAt ?? this.consumedAt,
      contactStubId: contactStubId ?? this.contactStubId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nonce.present) {
      map['nonce'] = Variable<String>(nonce.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    if (contactStubId.present) {
      map['contact_stub_id'] = Variable<String>(contactStubId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactInvitationsCompanion(')
          ..write('id: $id, ')
          ..write('nonce: $nonce, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('contactStubId: $contactStubId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingHandshakesTable extends PendingHandshakes
    with TableInfo<$PendingHandshakesTable, PendingHandshake> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingHandshakesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invitationIdHexMeta = const VerificationMeta(
    'invitationIdHex',
  );
  @override
  late final GeneratedColumn<String> invitationIdHex = GeneratedColumn<String>(
    'invitation_id_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nonceHexMeta = const VerificationMeta(
    'nonceHex',
  );
  @override
  late final GeneratedColumn<String> nonceHex = GeneratedColumn<String>(
    'nonce_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactStubIdMeta = const VerificationMeta(
    'contactStubId',
  );
  @override
  late final GeneratedColumn<String> contactStubId = GeneratedColumn<String>(
    'contact_stub_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerLongTermPublicMaterialB64Meta =
      const VerificationMeta('peerLongTermPublicMaterialB64');
  @override
  late final GeneratedColumn<String> peerLongTermPublicMaterialB64 =
      GeneratedColumn<String>(
        'peer_long_term_public_material_b64',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _peerDisplayNameMeta = const VerificationMeta(
    'peerDisplayName',
  );
  @override
  late final GeneratedColumn<String> peerDisplayName = GeneratedColumn<String>(
    'peer_display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _peerAvatarIdMeta = const VerificationMeta(
    'peerAvatarId',
  );
  @override
  late final GeneratedColumn<String> peerAvatarId = GeneratedColumn<String>(
    'peer_avatar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invitationIdHex,
    nonceHex,
    role,
    state,
    contactStubId,
    peerLongTermPublicMaterialB64,
    peerDisplayName,
    peerAvatarId,
    lastErrorCode,
    createdAt,
    updatedAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_handshakes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingHandshake> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('invitation_id_hex')) {
      context.handle(
        _invitationIdHexMeta,
        invitationIdHex.isAcceptableOrUnknown(
          data['invitation_id_hex']!,
          _invitationIdHexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invitationIdHexMeta);
    }
    if (data.containsKey('nonce_hex')) {
      context.handle(
        _nonceHexMeta,
        nonceHex.isAcceptableOrUnknown(data['nonce_hex']!, _nonceHexMeta),
      );
    } else if (isInserting) {
      context.missing(_nonceHexMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('contact_stub_id')) {
      context.handle(
        _contactStubIdMeta,
        contactStubId.isAcceptableOrUnknown(
          data['contact_stub_id']!,
          _contactStubIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactStubIdMeta);
    }
    if (data.containsKey('peer_long_term_public_material_b64')) {
      context.handle(
        _peerLongTermPublicMaterialB64Meta,
        peerLongTermPublicMaterialB64.isAcceptableOrUnknown(
          data['peer_long_term_public_material_b64']!,
          _peerLongTermPublicMaterialB64Meta,
        ),
      );
    }
    if (data.containsKey('peer_display_name')) {
      context.handle(
        _peerDisplayNameMeta,
        peerDisplayName.isAcceptableOrUnknown(
          data['peer_display_name']!,
          _peerDisplayNameMeta,
        ),
      );
    }
    if (data.containsKey('peer_avatar_id')) {
      context.handle(
        _peerAvatarIdMeta,
        peerAvatarId.isAcceptableOrUnknown(
          data['peer_avatar_id']!,
          _peerAvatarIdMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingHandshake map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingHandshake(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      invitationIdHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invitation_id_hex'],
      )!,
      nonceHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nonce_hex'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      contactStubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_stub_id'],
      )!,
      peerLongTermPublicMaterialB64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_long_term_public_material_b64'],
      ),
      peerDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_display_name'],
      )!,
      peerAvatarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_avatar_id'],
      )!,
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $PendingHandshakesTable createAlias(String alias) {
    return $PendingHandshakesTable(attachedDatabase, alias);
  }
}

class PendingHandshake extends DataClass
    implements Insertable<PendingHandshake> {
  /// `${invitationIdHex}:${role}` — uniquely identifies a row even if
  /// the same user happens to generate AND receive a code with the same
  /// invitation id (collision probability ≈ 1/2^64).
  final String id;

  /// Hex of the 8-byte invitation id.
  final String invitationIdHex;

  /// Hex of the 12-byte invitation nonce. Stored on both sides so the
  /// orchestrator does not need to re-derive it from the code on every
  /// envelope decryption.
  final String nonceHex;

  /// `inviter` (we generated the code) | `invitee` (we received it).
  final String role;

  /// Lifecycle. `awaiting_hello` and `awaiting_ack` are the polling
  /// states; the rest are terminal.
  ///   * inviter: `awaiting_hello` → `accepted`|`rejected` → `completed`
  ///   * invitee: `awaiting_ack`   → `accepted`|`rejected`
  ///   * either:  `failed` on unrecoverable error (e.g., expired code).
  final String state;

  /// Local Contact id to promote on success. On the inviter side this is
  /// the stub created when the code was generated. On the invitee side
  /// it is the stub created when the hello was dispatched.
  final String contactStubId;

  /// Filled when the peer's long-term X25519 public key is known. For
  /// the inviter, after the hello is decrypted. For the invitee, after
  /// the ack is decrypted.
  final String? peerLongTermPublicMaterialB64;

  /// Self-reported display name from the peer (informational; the local
  /// Contact's displayName is the authoritative one).
  final String peerDisplayName;

  /// Self-reported avatar id from the peer.
  final String peerAvatarId;

  /// Last error code captured by the orchestrator (for diagnostics).
  /// Empty string when no error.
  final String lastErrorCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  const PendingHandshake({
    required this.id,
    required this.invitationIdHex,
    required this.nonceHex,
    required this.role,
    required this.state,
    required this.contactStubId,
    this.peerLongTermPublicMaterialB64,
    required this.peerDisplayName,
    required this.peerAvatarId,
    required this.lastErrorCode,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['invitation_id_hex'] = Variable<String>(invitationIdHex);
    map['nonce_hex'] = Variable<String>(nonceHex);
    map['role'] = Variable<String>(role);
    map['state'] = Variable<String>(state);
    map['contact_stub_id'] = Variable<String>(contactStubId);
    if (!nullToAbsent || peerLongTermPublicMaterialB64 != null) {
      map['peer_long_term_public_material_b64'] = Variable<String>(
        peerLongTermPublicMaterialB64,
      );
    }
    map['peer_display_name'] = Variable<String>(peerDisplayName);
    map['peer_avatar_id'] = Variable<String>(peerAvatarId);
    map['last_error_code'] = Variable<String>(lastErrorCode);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  PendingHandshakesCompanion toCompanion(bool nullToAbsent) {
    return PendingHandshakesCompanion(
      id: Value(id),
      invitationIdHex: Value(invitationIdHex),
      nonceHex: Value(nonceHex),
      role: Value(role),
      state: Value(state),
      contactStubId: Value(contactStubId),
      peerLongTermPublicMaterialB64:
          peerLongTermPublicMaterialB64 == null && nullToAbsent
          ? const Value.absent()
          : Value(peerLongTermPublicMaterialB64),
      peerDisplayName: Value(peerDisplayName),
      peerAvatarId: Value(peerAvatarId),
      lastErrorCode: Value(lastErrorCode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory PendingHandshake.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingHandshake(
      id: serializer.fromJson<String>(json['id']),
      invitationIdHex: serializer.fromJson<String>(json['invitationIdHex']),
      nonceHex: serializer.fromJson<String>(json['nonceHex']),
      role: serializer.fromJson<String>(json['role']),
      state: serializer.fromJson<String>(json['state']),
      contactStubId: serializer.fromJson<String>(json['contactStubId']),
      peerLongTermPublicMaterialB64: serializer.fromJson<String?>(
        json['peerLongTermPublicMaterialB64'],
      ),
      peerDisplayName: serializer.fromJson<String>(json['peerDisplayName']),
      peerAvatarId: serializer.fromJson<String>(json['peerAvatarId']),
      lastErrorCode: serializer.fromJson<String>(json['lastErrorCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'invitationIdHex': serializer.toJson<String>(invitationIdHex),
      'nonceHex': serializer.toJson<String>(nonceHex),
      'role': serializer.toJson<String>(role),
      'state': serializer.toJson<String>(state),
      'contactStubId': serializer.toJson<String>(contactStubId),
      'peerLongTermPublicMaterialB64': serializer.toJson<String?>(
        peerLongTermPublicMaterialB64,
      ),
      'peerDisplayName': serializer.toJson<String>(peerDisplayName),
      'peerAvatarId': serializer.toJson<String>(peerAvatarId),
      'lastErrorCode': serializer.toJson<String>(lastErrorCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  PendingHandshake copyWith({
    String? id,
    String? invitationIdHex,
    String? nonceHex,
    String? role,
    String? state,
    String? contactStubId,
    Value<String?> peerLongTermPublicMaterialB64 = const Value.absent(),
    String? peerDisplayName,
    String? peerAvatarId,
    String? lastErrorCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) => PendingHandshake(
    id: id ?? this.id,
    invitationIdHex: invitationIdHex ?? this.invitationIdHex,
    nonceHex: nonceHex ?? this.nonceHex,
    role: role ?? this.role,
    state: state ?? this.state,
    contactStubId: contactStubId ?? this.contactStubId,
    peerLongTermPublicMaterialB64: peerLongTermPublicMaterialB64.present
        ? peerLongTermPublicMaterialB64.value
        : this.peerLongTermPublicMaterialB64,
    peerDisplayName: peerDisplayName ?? this.peerDisplayName,
    peerAvatarId: peerAvatarId ?? this.peerAvatarId,
    lastErrorCode: lastErrorCode ?? this.lastErrorCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  PendingHandshake copyWithCompanion(PendingHandshakesCompanion data) {
    return PendingHandshake(
      id: data.id.present ? data.id.value : this.id,
      invitationIdHex: data.invitationIdHex.present
          ? data.invitationIdHex.value
          : this.invitationIdHex,
      nonceHex: data.nonceHex.present ? data.nonceHex.value : this.nonceHex,
      role: data.role.present ? data.role.value : this.role,
      state: data.state.present ? data.state.value : this.state,
      contactStubId: data.contactStubId.present
          ? data.contactStubId.value
          : this.contactStubId,
      peerLongTermPublicMaterialB64: data.peerLongTermPublicMaterialB64.present
          ? data.peerLongTermPublicMaterialB64.value
          : this.peerLongTermPublicMaterialB64,
      peerDisplayName: data.peerDisplayName.present
          ? data.peerDisplayName.value
          : this.peerDisplayName,
      peerAvatarId: data.peerAvatarId.present
          ? data.peerAvatarId.value
          : this.peerAvatarId,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingHandshake(')
          ..write('id: $id, ')
          ..write('invitationIdHex: $invitationIdHex, ')
          ..write('nonceHex: $nonceHex, ')
          ..write('role: $role, ')
          ..write('state: $state, ')
          ..write('contactStubId: $contactStubId, ')
          ..write(
            'peerLongTermPublicMaterialB64: $peerLongTermPublicMaterialB64, ',
          )
          ..write('peerDisplayName: $peerDisplayName, ')
          ..write('peerAvatarId: $peerAvatarId, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    invitationIdHex,
    nonceHex,
    role,
    state,
    contactStubId,
    peerLongTermPublicMaterialB64,
    peerDisplayName,
    peerAvatarId,
    lastErrorCode,
    createdAt,
    updatedAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingHandshake &&
          other.id == this.id &&
          other.invitationIdHex == this.invitationIdHex &&
          other.nonceHex == this.nonceHex &&
          other.role == this.role &&
          other.state == this.state &&
          other.contactStubId == this.contactStubId &&
          other.peerLongTermPublicMaterialB64 ==
              this.peerLongTermPublicMaterialB64 &&
          other.peerDisplayName == this.peerDisplayName &&
          other.peerAvatarId == this.peerAvatarId &&
          other.lastErrorCode == this.lastErrorCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.expiresAt == this.expiresAt);
}

class PendingHandshakesCompanion extends UpdateCompanion<PendingHandshake> {
  final Value<String> id;
  final Value<String> invitationIdHex;
  final Value<String> nonceHex;
  final Value<String> role;
  final Value<String> state;
  final Value<String> contactStubId;
  final Value<String?> peerLongTermPublicMaterialB64;
  final Value<String> peerDisplayName;
  final Value<String> peerAvatarId;
  final Value<String> lastErrorCode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const PendingHandshakesCompanion({
    this.id = const Value.absent(),
    this.invitationIdHex = const Value.absent(),
    this.nonceHex = const Value.absent(),
    this.role = const Value.absent(),
    this.state = const Value.absent(),
    this.contactStubId = const Value.absent(),
    this.peerLongTermPublicMaterialB64 = const Value.absent(),
    this.peerDisplayName = const Value.absent(),
    this.peerAvatarId = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingHandshakesCompanion.insert({
    required String id,
    required String invitationIdHex,
    required String nonceHex,
    required String role,
    required String state,
    required String contactStubId,
    this.peerLongTermPublicMaterialB64 = const Value.absent(),
    this.peerDisplayName = const Value.absent(),
    this.peerAvatarId = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       invitationIdHex = Value(invitationIdHex),
       nonceHex = Value(nonceHex),
       role = Value(role),
       state = Value(state),
       contactStubId = Value(contactStubId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       expiresAt = Value(expiresAt);
  static Insertable<PendingHandshake> custom({
    Expression<String>? id,
    Expression<String>? invitationIdHex,
    Expression<String>? nonceHex,
    Expression<String>? role,
    Expression<String>? state,
    Expression<String>? contactStubId,
    Expression<String>? peerLongTermPublicMaterialB64,
    Expression<String>? peerDisplayName,
    Expression<String>? peerAvatarId,
    Expression<String>? lastErrorCode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invitationIdHex != null) 'invitation_id_hex': invitationIdHex,
      if (nonceHex != null) 'nonce_hex': nonceHex,
      if (role != null) 'role': role,
      if (state != null) 'state': state,
      if (contactStubId != null) 'contact_stub_id': contactStubId,
      if (peerLongTermPublicMaterialB64 != null)
        'peer_long_term_public_material_b64': peerLongTermPublicMaterialB64,
      if (peerDisplayName != null) 'peer_display_name': peerDisplayName,
      if (peerAvatarId != null) 'peer_avatar_id': peerAvatarId,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingHandshakesCompanion copyWith({
    Value<String>? id,
    Value<String>? invitationIdHex,
    Value<String>? nonceHex,
    Value<String>? role,
    Value<String>? state,
    Value<String>? contactStubId,
    Value<String?>? peerLongTermPublicMaterialB64,
    Value<String>? peerDisplayName,
    Value<String>? peerAvatarId,
    Value<String>? lastErrorCode,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return PendingHandshakesCompanion(
      id: id ?? this.id,
      invitationIdHex: invitationIdHex ?? this.invitationIdHex,
      nonceHex: nonceHex ?? this.nonceHex,
      role: role ?? this.role,
      state: state ?? this.state,
      contactStubId: contactStubId ?? this.contactStubId,
      peerLongTermPublicMaterialB64:
          peerLongTermPublicMaterialB64 ?? this.peerLongTermPublicMaterialB64,
      peerDisplayName: peerDisplayName ?? this.peerDisplayName,
      peerAvatarId: peerAvatarId ?? this.peerAvatarId,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (invitationIdHex.present) {
      map['invitation_id_hex'] = Variable<String>(invitationIdHex.value);
    }
    if (nonceHex.present) {
      map['nonce_hex'] = Variable<String>(nonceHex.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (contactStubId.present) {
      map['contact_stub_id'] = Variable<String>(contactStubId.value);
    }
    if (peerLongTermPublicMaterialB64.present) {
      map['peer_long_term_public_material_b64'] = Variable<String>(
        peerLongTermPublicMaterialB64.value,
      );
    }
    if (peerDisplayName.present) {
      map['peer_display_name'] = Variable<String>(peerDisplayName.value);
    }
    if (peerAvatarId.present) {
      map['peer_avatar_id'] = Variable<String>(peerAvatarId.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingHandshakesCompanion(')
          ..write('id: $id, ')
          ..write('invitationIdHex: $invitationIdHex, ')
          ..write('nonceHex: $nonceHex, ')
          ..write('role: $role, ')
          ..write('state: $state, ')
          ..write('contactStubId: $contactStubId, ')
          ..write(
            'peerLongTermPublicMaterialB64: $peerLongTermPublicMaterialB64, ',
          )
          ..write('peerDisplayName: $peerDisplayName, ')
          ..write('peerAvatarId: $peerAvatarId, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $ParticipantsTable participants = $ParticipantsTable(this);
  late final $PlanLinesTable planLines = $PlanLinesTable(this);
  late final $PlanGroupsTable planGroups = $PlanGroupsTable(this);
  late final $PlanRatiosTable planRatios = $PlanRatiosTable(this);
  late final $PlanRatioTemplatesTable planRatioTemplates =
      $PlanRatioTemplatesTable(this);
  late final $AgreementsTable agreements = $AgreementsTable(this);
  late final $ProposalPackagesTable proposalPackages = $ProposalPackagesTable(
    this,
  );
  late final $ProposalRevisionsTable proposalRevisions =
      $ProposalRevisionsTable(this);
  late final $ProposalResponsesTable proposalResponses =
      $ProposalResponsesTable(this);
  late final $RelayActivityLogEntriesTable relayActivityLogEntries =
      $RelayActivityLogEntriesTable(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $ContactInvitationsTable contactInvitations =
      $ContactInvitationsTable(this);
  late final $PendingHandshakesTable pendingHandshakes =
      $PendingHandshakesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    plans,
    participants,
    planLines,
    planGroups,
    planRatios,
    planRatioTemplates,
    agreements,
    proposalPackages,
    proposalRevisions,
    proposalResponses,
    relayActivityLogEntries,
    contacts,
    contactInvitations,
    pendingHandshakes,
  ];
}

typedef $$PlansTableCreateCompanionBuilder =
    PlansCompanion Function({
      required String id,
      required String type,
      Value<String> title,
      Value<String?> notes,
      Value<String> currency,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PlansTableUpdateCompanionBuilder =
    PlansCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> title,
      Value<String?> notes,
      Value<String> currency,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlansTable,
          Plan,
          $$PlansTableFilterComposer,
          $$PlansTableOrderingComposer,
          $$PlansTableAnnotationComposer,
          $$PlansTableCreateCompanionBuilder,
          $$PlansTableUpdateCompanionBuilder,
          (Plan, BaseReferences<_$AppDatabase, $PlansTable, Plan>),
          Plan,
          PrefetchHooks Function()
        > {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion(
                id: id,
                type: type,
                title: title,
                notes: notes,
                currency: currency,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> currency = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion.insert(
                id: id,
                type: type,
                title: title,
                notes: notes,
                currency: currency,
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

typedef $$PlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlansTable,
      Plan,
      $$PlansTableFilterComposer,
      $$PlansTableOrderingComposer,
      $$PlansTableAnnotationComposer,
      $$PlansTableCreateCompanionBuilder,
      $$PlansTableUpdateCompanionBuilder,
      (Plan, BaseReferences<_$AppDatabase, $PlansTable, Plan>),
      Plan,
      PrefetchHooks Function()
    >;
typedef $$ParticipantsTableCreateCompanionBuilder =
    ParticipantsCompanion Function({
      required String id,
      required String displayName,
      required String avatarId,
      required DateTime createdAt,
      Value<String?> contactId,
      Value<int> rowid,
    });
typedef $$ParticipantsTableUpdateCompanionBuilder =
    ParticipantsCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> avatarId,
      Value<DateTime> createdAt,
      Value<String?> contactId,
      Value<int> rowid,
    });

class $$ParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $ParticipantsTable> {
  $$ParticipantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarId => $composableBuilder(
    column: $table.avatarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $ParticipantsTable> {
  $$ParticipantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarId => $composableBuilder(
    column: $table.avatarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParticipantsTable> {
  $$ParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarId =>
      $composableBuilder(column: $table.avatarId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);
}

class $$ParticipantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ParticipantsTable,
          Participant,
          $$ParticipantsTableFilterComposer,
          $$ParticipantsTableOrderingComposer,
          $$ParticipantsTableAnnotationComposer,
          $$ParticipantsTableCreateCompanionBuilder,
          $$ParticipantsTableUpdateCompanionBuilder,
          (
            Participant,
            BaseReferences<_$AppDatabase, $ParticipantsTable, Participant>,
          ),
          Participant,
          PrefetchHooks Function()
        > {
  $$ParticipantsTableTableManager(_$AppDatabase db, $ParticipantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParticipantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParticipantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParticipantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> avatarId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParticipantsCompanion(
                id: id,
                displayName: displayName,
                avatarId: avatarId,
                createdAt: createdAt,
                contactId: contactId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String avatarId,
                required DateTime createdAt,
                Value<String?> contactId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParticipantsCompanion.insert(
                id: id,
                displayName: displayName,
                avatarId: avatarId,
                createdAt: createdAt,
                contactId: contactId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ParticipantsTable,
      Participant,
      $$ParticipantsTableFilterComposer,
      $$ParticipantsTableOrderingComposer,
      $$ParticipantsTableAnnotationComposer,
      $$ParticipantsTableCreateCompanionBuilder,
      $$ParticipantsTableUpdateCompanionBuilder,
      (
        Participant,
        BaseReferences<_$AppDatabase, $ParticipantsTable, Participant>,
      ),
      Participant,
      PrefetchHooks Function()
    >;
typedef $$PlanLinesTableCreateCompanionBuilder =
    PlanLinesCompanion Function({
      required String id,
      required String planId,
      required bool isRecurring,
      required String title,
      required String currency,
      Value<bool> amountUsesRange,
      Value<int?> amountMinor,
      Value<int?> minAmountMinor,
      Value<int?> maxAmountMinor,
      Value<String> description,
      Value<String> cadence,
      Value<int?> recurrenceDayOfMonth,
      Value<int> sortOrder,
      Value<String?> groupId,
      Value<bool> amountIsBudgetCap,
      Value<String?> paymentResponsibleParticipantId,
      Value<String> recurrenceSpecJson,
      Value<String?> ratioTemplateId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PlanLinesTableUpdateCompanionBuilder =
    PlanLinesCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<bool> isRecurring,
      Value<String> title,
      Value<String> currency,
      Value<bool> amountUsesRange,
      Value<int?> amountMinor,
      Value<int?> minAmountMinor,
      Value<int?> maxAmountMinor,
      Value<String> description,
      Value<String> cadence,
      Value<int?> recurrenceDayOfMonth,
      Value<int> sortOrder,
      Value<String?> groupId,
      Value<bool> amountIsBudgetCap,
      Value<String?> paymentResponsibleParticipantId,
      Value<String> recurrenceSpecJson,
      Value<String?> ratioTemplateId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PlanLinesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanLinesTable> {
  $$PlanLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get amountUsesRange => $composableBuilder(
    column: $table.amountUsesRange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minAmountMinor => $composableBuilder(
    column: $table.minAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxAmountMinor => $composableBuilder(
    column: $table.maxAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cadence => $composableBuilder(
    column: $table.cadence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceDayOfMonth => $composableBuilder(
    column: $table.recurrenceDayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get amountIsBudgetCap => $composableBuilder(
    column: $table.amountIsBudgetCap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentResponsibleParticipantId =>
      $composableBuilder(
        column: $table.paymentResponsibleParticipantId,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<String> get recurrenceSpecJson => $composableBuilder(
    column: $table.recurrenceSpecJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ratioTemplateId => $composableBuilder(
    column: $table.ratioTemplateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanLinesTable> {
  $$PlanLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get amountUsesRange => $composableBuilder(
    column: $table.amountUsesRange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minAmountMinor => $composableBuilder(
    column: $table.minAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxAmountMinor => $composableBuilder(
    column: $table.maxAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cadence => $composableBuilder(
    column: $table.cadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceDayOfMonth => $composableBuilder(
    column: $table.recurrenceDayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get amountIsBudgetCap => $composableBuilder(
    column: $table.amountIsBudgetCap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentResponsibleParticipantId =>
      $composableBuilder(
        column: $table.paymentResponsibleParticipantId,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get recurrenceSpecJson => $composableBuilder(
    column: $table.recurrenceSpecJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ratioTemplateId => $composableBuilder(
    column: $table.ratioTemplateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanLinesTable> {
  $$PlanLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get amountUsesRange => $composableBuilder(
    column: $table.amountUsesRange,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minAmountMinor => $composableBuilder(
    column: $table.minAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxAmountMinor => $composableBuilder(
    column: $table.maxAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cadence =>
      $composableBuilder(column: $table.cadence, builder: (column) => column);

  GeneratedColumn<int> get recurrenceDayOfMonth => $composableBuilder(
    column: $table.recurrenceDayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<bool> get amountIsBudgetCap => $composableBuilder(
    column: $table.amountIsBudgetCap,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentResponsibleParticipantId =>
      $composableBuilder(
        column: $table.paymentResponsibleParticipantId,
        builder: (column) => column,
      );

  GeneratedColumn<String> get recurrenceSpecJson => $composableBuilder(
    column: $table.recurrenceSpecJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ratioTemplateId => $composableBuilder(
    column: $table.ratioTemplateId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlanLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanLinesTable,
          PlanLine,
          $$PlanLinesTableFilterComposer,
          $$PlanLinesTableOrderingComposer,
          $$PlanLinesTableAnnotationComposer,
          $$PlanLinesTableCreateCompanionBuilder,
          $$PlanLinesTableUpdateCompanionBuilder,
          (PlanLine, BaseReferences<_$AppDatabase, $PlanLinesTable, PlanLine>),
          PlanLine,
          PrefetchHooks Function()
        > {
  $$PlanLinesTableTableManager(_$AppDatabase db, $PlanLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<bool> amountUsesRange = const Value.absent(),
                Value<int?> amountMinor = const Value.absent(),
                Value<int?> minAmountMinor = const Value.absent(),
                Value<int?> maxAmountMinor = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> cadence = const Value.absent(),
                Value<int?> recurrenceDayOfMonth = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<bool> amountIsBudgetCap = const Value.absent(),
                Value<String?> paymentResponsibleParticipantId =
                    const Value.absent(),
                Value<String> recurrenceSpecJson = const Value.absent(),
                Value<String?> ratioTemplateId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanLinesCompanion(
                id: id,
                planId: planId,
                isRecurring: isRecurring,
                title: title,
                currency: currency,
                amountUsesRange: amountUsesRange,
                amountMinor: amountMinor,
                minAmountMinor: minAmountMinor,
                maxAmountMinor: maxAmountMinor,
                description: description,
                cadence: cadence,
                recurrenceDayOfMonth: recurrenceDayOfMonth,
                sortOrder: sortOrder,
                groupId: groupId,
                amountIsBudgetCap: amountIsBudgetCap,
                paymentResponsibleParticipantId:
                    paymentResponsibleParticipantId,
                recurrenceSpecJson: recurrenceSpecJson,
                ratioTemplateId: ratioTemplateId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required bool isRecurring,
                required String title,
                required String currency,
                Value<bool> amountUsesRange = const Value.absent(),
                Value<int?> amountMinor = const Value.absent(),
                Value<int?> minAmountMinor = const Value.absent(),
                Value<int?> maxAmountMinor = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> cadence = const Value.absent(),
                Value<int?> recurrenceDayOfMonth = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<bool> amountIsBudgetCap = const Value.absent(),
                Value<String?> paymentResponsibleParticipantId =
                    const Value.absent(),
                Value<String> recurrenceSpecJson = const Value.absent(),
                Value<String?> ratioTemplateId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlanLinesCompanion.insert(
                id: id,
                planId: planId,
                isRecurring: isRecurring,
                title: title,
                currency: currency,
                amountUsesRange: amountUsesRange,
                amountMinor: amountMinor,
                minAmountMinor: minAmountMinor,
                maxAmountMinor: maxAmountMinor,
                description: description,
                cadence: cadence,
                recurrenceDayOfMonth: recurrenceDayOfMonth,
                sortOrder: sortOrder,
                groupId: groupId,
                amountIsBudgetCap: amountIsBudgetCap,
                paymentResponsibleParticipantId:
                    paymentResponsibleParticipantId,
                recurrenceSpecJson: recurrenceSpecJson,
                ratioTemplateId: ratioTemplateId,
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

typedef $$PlanLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanLinesTable,
      PlanLine,
      $$PlanLinesTableFilterComposer,
      $$PlanLinesTableOrderingComposer,
      $$PlanLinesTableAnnotationComposer,
      $$PlanLinesTableCreateCompanionBuilder,
      $$PlanLinesTableUpdateCompanionBuilder,
      (PlanLine, BaseReferences<_$AppDatabase, $PlanLinesTable, PlanLine>),
      PlanLine,
      PrefetchHooks Function()
    >;
typedef $$PlanGroupsTableCreateCompanionBuilder =
    PlanGroupsCompanion Function({
      required String id,
      required String planId,
      required String title,
      Value<String> description,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PlanGroupsTableUpdateCompanionBuilder =
    PlanGroupsCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<String> title,
      Value<String> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PlanGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $PlanGroupsTable> {
  $$PlanGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanGroupsTable> {
  $$PlanGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanGroupsTable> {
  $$PlanGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlanGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanGroupsTable,
          PlanGroup,
          $$PlanGroupsTableFilterComposer,
          $$PlanGroupsTableOrderingComposer,
          $$PlanGroupsTableAnnotationComposer,
          $$PlanGroupsTableCreateCompanionBuilder,
          $$PlanGroupsTableUpdateCompanionBuilder,
          (
            PlanGroup,
            BaseReferences<_$AppDatabase, $PlanGroupsTable, PlanGroup>,
          ),
          PlanGroup,
          PrefetchHooks Function()
        > {
  $$PlanGroupsTableTableManager(_$AppDatabase db, $PlanGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanGroupsCompanion(
                id: id,
                planId: planId,
                title: title,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required String title,
                Value<String> description = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlanGroupsCompanion.insert(
                id: id,
                planId: planId,
                title: title,
                description: description,
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

typedef $$PlanGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanGroupsTable,
      PlanGroup,
      $$PlanGroupsTableFilterComposer,
      $$PlanGroupsTableOrderingComposer,
      $$PlanGroupsTableAnnotationComposer,
      $$PlanGroupsTableCreateCompanionBuilder,
      $$PlanGroupsTableUpdateCompanionBuilder,
      (PlanGroup, BaseReferences<_$AppDatabase, $PlanGroupsTable, PlanGroup>),
      PlanGroup,
      PrefetchHooks Function()
    >;
typedef $$PlanRatiosTableCreateCompanionBuilder =
    PlanRatiosCompanion Function({
      required String id,
      required String planId,
      required String participantId,
      Value<String?> lineId,
      Value<String?> groupId,
      required int weight,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PlanRatiosTableUpdateCompanionBuilder =
    PlanRatiosCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<String> participantId,
      Value<String?> lineId,
      Value<String?> groupId,
      Value<int> weight,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PlanRatiosTableFilterComposer
    extends Composer<_$AppDatabase, $PlanRatiosTable> {
  $$PlanRatiosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantId => $composableBuilder(
    column: $table.participantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineId => $composableBuilder(
    column: $table.lineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanRatiosTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanRatiosTable> {
  $$PlanRatiosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantId => $composableBuilder(
    column: $table.participantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineId => $composableBuilder(
    column: $table.lineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanRatiosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanRatiosTable> {
  $$PlanRatiosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get participantId => $composableBuilder(
    column: $table.participantId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lineId =>
      $composableBuilder(column: $table.lineId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlanRatiosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanRatiosTable,
          PlanRatio,
          $$PlanRatiosTableFilterComposer,
          $$PlanRatiosTableOrderingComposer,
          $$PlanRatiosTableAnnotationComposer,
          $$PlanRatiosTableCreateCompanionBuilder,
          $$PlanRatiosTableUpdateCompanionBuilder,
          (
            PlanRatio,
            BaseReferences<_$AppDatabase, $PlanRatiosTable, PlanRatio>,
          ),
          PlanRatio,
          PrefetchHooks Function()
        > {
  $$PlanRatiosTableTableManager(_$AppDatabase db, $PlanRatiosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanRatiosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanRatiosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanRatiosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> participantId = const Value.absent(),
                Value<String?> lineId = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> weight = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanRatiosCompanion(
                id: id,
                planId: planId,
                participantId: participantId,
                lineId: lineId,
                groupId: groupId,
                weight: weight,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required String participantId,
                Value<String?> lineId = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                required int weight,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlanRatiosCompanion.insert(
                id: id,
                planId: planId,
                participantId: participantId,
                lineId: lineId,
                groupId: groupId,
                weight: weight,
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

typedef $$PlanRatiosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanRatiosTable,
      PlanRatio,
      $$PlanRatiosTableFilterComposer,
      $$PlanRatiosTableOrderingComposer,
      $$PlanRatiosTableAnnotationComposer,
      $$PlanRatiosTableCreateCompanionBuilder,
      $$PlanRatiosTableUpdateCompanionBuilder,
      (PlanRatio, BaseReferences<_$AppDatabase, $PlanRatiosTable, PlanRatio>),
      PlanRatio,
      PrefetchHooks Function()
    >;
typedef $$PlanRatioTemplatesTableCreateCompanionBuilder =
    PlanRatioTemplatesCompanion Function({
      required String id,
      required String planId,
      required String displayTitle,
      required String weightsJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PlanRatioTemplatesTableUpdateCompanionBuilder =
    PlanRatioTemplatesCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<String> displayTitle,
      Value<String> weightsJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PlanRatioTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanRatioTemplatesTable> {
  $$PlanRatioTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayTitle => $composableBuilder(
    column: $table.displayTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weightsJson => $composableBuilder(
    column: $table.weightsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanRatioTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanRatioTemplatesTable> {
  $$PlanRatioTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayTitle => $composableBuilder(
    column: $table.displayTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weightsJson => $composableBuilder(
    column: $table.weightsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanRatioTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanRatioTemplatesTable> {
  $$PlanRatioTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get displayTitle => $composableBuilder(
    column: $table.displayTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weightsJson => $composableBuilder(
    column: $table.weightsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlanRatioTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanRatioTemplatesTable,
          PlanRatioTemplate,
          $$PlanRatioTemplatesTableFilterComposer,
          $$PlanRatioTemplatesTableOrderingComposer,
          $$PlanRatioTemplatesTableAnnotationComposer,
          $$PlanRatioTemplatesTableCreateCompanionBuilder,
          $$PlanRatioTemplatesTableUpdateCompanionBuilder,
          (
            PlanRatioTemplate,
            BaseReferences<
              _$AppDatabase,
              $PlanRatioTemplatesTable,
              PlanRatioTemplate
            >,
          ),
          PlanRatioTemplate,
          PrefetchHooks Function()
        > {
  $$PlanRatioTemplatesTableTableManager(
    _$AppDatabase db,
    $PlanRatioTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanRatioTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanRatioTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanRatioTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> displayTitle = const Value.absent(),
                Value<String> weightsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanRatioTemplatesCompanion(
                id: id,
                planId: planId,
                displayTitle: displayTitle,
                weightsJson: weightsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required String displayTitle,
                required String weightsJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlanRatioTemplatesCompanion.insert(
                id: id,
                planId: planId,
                displayTitle: displayTitle,
                weightsJson: weightsJson,
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

typedef $$PlanRatioTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanRatioTemplatesTable,
      PlanRatioTemplate,
      $$PlanRatioTemplatesTableFilterComposer,
      $$PlanRatioTemplatesTableOrderingComposer,
      $$PlanRatioTemplatesTableAnnotationComposer,
      $$PlanRatioTemplatesTableCreateCompanionBuilder,
      $$PlanRatioTemplatesTableUpdateCompanionBuilder,
      (
        PlanRatioTemplate,
        BaseReferences<
          _$AppDatabase,
          $PlanRatioTemplatesTable,
          PlanRatioTemplate
        >,
      ),
      PlanRatioTemplate,
      PrefetchHooks Function()
    >;
typedef $$AgreementsTableCreateCompanionBuilder =
    AgreementsCompanion Function({
      required String id,
      required String planId,
      required DateTime periodStart,
      required DateTime periodEnd,
      Value<int> minNoticeDays,
      Value<int> penaltyMinor,
      Value<String> clauses,
      Value<String> withdrawalSameForAll,
      Value<String> withdrawalPerParticipantJson,
      Value<String> agreementRulesJson,
      Value<int> version,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AgreementsTableUpdateCompanionBuilder =
    AgreementsCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<DateTime> periodStart,
      Value<DateTime> periodEnd,
      Value<int> minNoticeDays,
      Value<int> penaltyMinor,
      Value<String> clauses,
      Value<String> withdrawalSameForAll,
      Value<String> withdrawalPerParticipantJson,
      Value<String> agreementRulesJson,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AgreementsTableFilterComposer
    extends Composer<_$AppDatabase, $AgreementsTable> {
  $$AgreementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minNoticeDays => $composableBuilder(
    column: $table.minNoticeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get penaltyMinor => $composableBuilder(
    column: $table.penaltyMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clauses => $composableBuilder(
    column: $table.clauses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get withdrawalSameForAll => $composableBuilder(
    column: $table.withdrawalSameForAll,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get withdrawalPerParticipantJson => $composableBuilder(
    column: $table.withdrawalPerParticipantJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agreementRulesJson => $composableBuilder(
    column: $table.agreementRulesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AgreementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AgreementsTable> {
  $$AgreementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minNoticeDays => $composableBuilder(
    column: $table.minNoticeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get penaltyMinor => $composableBuilder(
    column: $table.penaltyMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clauses => $composableBuilder(
    column: $table.clauses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get withdrawalSameForAll => $composableBuilder(
    column: $table.withdrawalSameForAll,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get withdrawalPerParticipantJson =>
      $composableBuilder(
        column: $table.withdrawalPerParticipantJson,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get agreementRulesJson => $composableBuilder(
    column: $table.agreementRulesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgreementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgreementsTable> {
  $$AgreementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<int> get minNoticeDays => $composableBuilder(
    column: $table.minNoticeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get penaltyMinor => $composableBuilder(
    column: $table.penaltyMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clauses =>
      $composableBuilder(column: $table.clauses, builder: (column) => column);

  GeneratedColumn<String> get withdrawalSameForAll => $composableBuilder(
    column: $table.withdrawalSameForAll,
    builder: (column) => column,
  );

  GeneratedColumn<String> get withdrawalPerParticipantJson =>
      $composableBuilder(
        column: $table.withdrawalPerParticipantJson,
        builder: (column) => column,
      );

  GeneratedColumn<String> get agreementRulesJson => $composableBuilder(
    column: $table.agreementRulesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AgreementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgreementsTable,
          Agreement,
          $$AgreementsTableFilterComposer,
          $$AgreementsTableOrderingComposer,
          $$AgreementsTableAnnotationComposer,
          $$AgreementsTableCreateCompanionBuilder,
          $$AgreementsTableUpdateCompanionBuilder,
          (
            Agreement,
            BaseReferences<_$AppDatabase, $AgreementsTable, Agreement>,
          ),
          Agreement,
          PrefetchHooks Function()
        > {
  $$AgreementsTableTableManager(_$AppDatabase db, $AgreementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgreementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgreementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgreementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<DateTime> periodStart = const Value.absent(),
                Value<DateTime> periodEnd = const Value.absent(),
                Value<int> minNoticeDays = const Value.absent(),
                Value<int> penaltyMinor = const Value.absent(),
                Value<String> clauses = const Value.absent(),
                Value<String> withdrawalSameForAll = const Value.absent(),
                Value<String> withdrawalPerParticipantJson =
                    const Value.absent(),
                Value<String> agreementRulesJson = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgreementsCompanion(
                id: id,
                planId: planId,
                periodStart: periodStart,
                periodEnd: periodEnd,
                minNoticeDays: minNoticeDays,
                penaltyMinor: penaltyMinor,
                clauses: clauses,
                withdrawalSameForAll: withdrawalSameForAll,
                withdrawalPerParticipantJson: withdrawalPerParticipantJson,
                agreementRulesJson: agreementRulesJson,
                version: version,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required DateTime periodStart,
                required DateTime periodEnd,
                Value<int> minNoticeDays = const Value.absent(),
                Value<int> penaltyMinor = const Value.absent(),
                Value<String> clauses = const Value.absent(),
                Value<String> withdrawalSameForAll = const Value.absent(),
                Value<String> withdrawalPerParticipantJson =
                    const Value.absent(),
                Value<String> agreementRulesJson = const Value.absent(),
                Value<int> version = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AgreementsCompanion.insert(
                id: id,
                planId: planId,
                periodStart: periodStart,
                periodEnd: periodEnd,
                minNoticeDays: minNoticeDays,
                penaltyMinor: penaltyMinor,
                clauses: clauses,
                withdrawalSameForAll: withdrawalSameForAll,
                withdrawalPerParticipantJson: withdrawalPerParticipantJson,
                agreementRulesJson: agreementRulesJson,
                version: version,
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

typedef $$AgreementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgreementsTable,
      Agreement,
      $$AgreementsTableFilterComposer,
      $$AgreementsTableOrderingComposer,
      $$AgreementsTableAnnotationComposer,
      $$AgreementsTableCreateCompanionBuilder,
      $$AgreementsTableUpdateCompanionBuilder,
      (Agreement, BaseReferences<_$AppDatabase, $AgreementsTable, Agreement>),
      Agreement,
      PrefetchHooks Function()
    >;
typedef $$ProposalPackagesTableCreateCompanionBuilder =
    ProposalPackagesCompanion Function({
      required String id,
      required String planId,
      Value<String?> activeRevisionId,
      Value<String?> pendingRevisionId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ProposalPackagesTableUpdateCompanionBuilder =
    ProposalPackagesCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<String?> activeRevisionId,
      Value<String?> pendingRevisionId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ProposalPackagesTableFilterComposer
    extends Composer<_$AppDatabase, $ProposalPackagesTable> {
  $$ProposalPackagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeRevisionId => $composableBuilder(
    column: $table.activeRevisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pendingRevisionId => $composableBuilder(
    column: $table.pendingRevisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProposalPackagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProposalPackagesTable> {
  $$ProposalPackagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeRevisionId => $composableBuilder(
    column: $table.activeRevisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingRevisionId => $composableBuilder(
    column: $table.pendingRevisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProposalPackagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProposalPackagesTable> {
  $$ProposalPackagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get activeRevisionId => $composableBuilder(
    column: $table.activeRevisionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pendingRevisionId => $composableBuilder(
    column: $table.pendingRevisionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProposalPackagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProposalPackagesTable,
          ProposalPackage,
          $$ProposalPackagesTableFilterComposer,
          $$ProposalPackagesTableOrderingComposer,
          $$ProposalPackagesTableAnnotationComposer,
          $$ProposalPackagesTableCreateCompanionBuilder,
          $$ProposalPackagesTableUpdateCompanionBuilder,
          (
            ProposalPackage,
            BaseReferences<
              _$AppDatabase,
              $ProposalPackagesTable,
              ProposalPackage
            >,
          ),
          ProposalPackage,
          PrefetchHooks Function()
        > {
  $$ProposalPackagesTableTableManager(
    _$AppDatabase db,
    $ProposalPackagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProposalPackagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProposalPackagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProposalPackagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String?> activeRevisionId = const Value.absent(),
                Value<String?> pendingRevisionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProposalPackagesCompanion(
                id: id,
                planId: planId,
                activeRevisionId: activeRevisionId,
                pendingRevisionId: pendingRevisionId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                Value<String?> activeRevisionId = const Value.absent(),
                Value<String?> pendingRevisionId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ProposalPackagesCompanion.insert(
                id: id,
                planId: planId,
                activeRevisionId: activeRevisionId,
                pendingRevisionId: pendingRevisionId,
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

typedef $$ProposalPackagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProposalPackagesTable,
      ProposalPackage,
      $$ProposalPackagesTableFilterComposer,
      $$ProposalPackagesTableOrderingComposer,
      $$ProposalPackagesTableAnnotationComposer,
      $$ProposalPackagesTableCreateCompanionBuilder,
      $$ProposalPackagesTableUpdateCompanionBuilder,
      (
        ProposalPackage,
        BaseReferences<_$AppDatabase, $ProposalPackagesTable, ProposalPackage>,
      ),
      ProposalPackage,
      PrefetchHooks Function()
    >;
typedef $$ProposalRevisionsTableCreateCompanionBuilder =
    ProposalRevisionsCompanion Function({
      required String id,
      required String packageId,
      required String contentHash,
      required String proposerParticipantId,
      required String payloadJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ProposalRevisionsTableUpdateCompanionBuilder =
    ProposalRevisionsCompanion Function({
      Value<String> id,
      Value<String> packageId,
      Value<String> contentHash,
      Value<String> proposerParticipantId,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ProposalRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $ProposalRevisionsTable> {
  $$ProposalRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageId => $composableBuilder(
    column: $table.packageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proposerParticipantId => $composableBuilder(
    column: $table.proposerParticipantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProposalRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProposalRevisionsTable> {
  $$ProposalRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageId => $composableBuilder(
    column: $table.packageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proposerParticipantId => $composableBuilder(
    column: $table.proposerParticipantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProposalRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProposalRevisionsTable> {
  $$ProposalRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageId =>
      $composableBuilder(column: $table.packageId, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get proposerParticipantId => $composableBuilder(
    column: $table.proposerParticipantId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProposalRevisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProposalRevisionsTable,
          ProposalRevision,
          $$ProposalRevisionsTableFilterComposer,
          $$ProposalRevisionsTableOrderingComposer,
          $$ProposalRevisionsTableAnnotationComposer,
          $$ProposalRevisionsTableCreateCompanionBuilder,
          $$ProposalRevisionsTableUpdateCompanionBuilder,
          (
            ProposalRevision,
            BaseReferences<
              _$AppDatabase,
              $ProposalRevisionsTable,
              ProposalRevision
            >,
          ),
          ProposalRevision,
          PrefetchHooks Function()
        > {
  $$ProposalRevisionsTableTableManager(
    _$AppDatabase db,
    $ProposalRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProposalRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProposalRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProposalRevisionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> packageId = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> proposerParticipantId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProposalRevisionsCompanion(
                id: id,
                packageId: packageId,
                contentHash: contentHash,
                proposerParticipantId: proposerParticipantId,
                payloadJson: payloadJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String packageId,
                required String contentHash,
                required String proposerParticipantId,
                required String payloadJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ProposalRevisionsCompanion.insert(
                id: id,
                packageId: packageId,
                contentHash: contentHash,
                proposerParticipantId: proposerParticipantId,
                payloadJson: payloadJson,
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

typedef $$ProposalRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProposalRevisionsTable,
      ProposalRevision,
      $$ProposalRevisionsTableFilterComposer,
      $$ProposalRevisionsTableOrderingComposer,
      $$ProposalRevisionsTableAnnotationComposer,
      $$ProposalRevisionsTableCreateCompanionBuilder,
      $$ProposalRevisionsTableUpdateCompanionBuilder,
      (
        ProposalRevision,
        BaseReferences<
          _$AppDatabase,
          $ProposalRevisionsTable,
          ProposalRevision
        >,
      ),
      ProposalRevision,
      PrefetchHooks Function()
    >;
typedef $$ProposalResponsesTableCreateCompanionBuilder =
    ProposalResponsesCompanion Function({
      required String id,
      required String revisionId,
      required String participantId,
      required String status,
      Value<DateTime?> respondedAt,
      Value<int> rowid,
    });
typedef $$ProposalResponsesTableUpdateCompanionBuilder =
    ProposalResponsesCompanion Function({
      Value<String> id,
      Value<String> revisionId,
      Value<String> participantId,
      Value<String> status,
      Value<DateTime?> respondedAt,
      Value<int> rowid,
    });

class $$ProposalResponsesTableFilterComposer
    extends Composer<_$AppDatabase, $ProposalResponsesTable> {
  $$ProposalResponsesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantId => $composableBuilder(
    column: $table.participantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProposalResponsesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProposalResponsesTable> {
  $$ProposalResponsesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantId => $composableBuilder(
    column: $table.participantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProposalResponsesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProposalResponsesTable> {
  $$ProposalResponsesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get participantId => $composableBuilder(
    column: $table.participantId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => column,
  );
}

class $$ProposalResponsesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProposalResponsesTable,
          ProposalResponse,
          $$ProposalResponsesTableFilterComposer,
          $$ProposalResponsesTableOrderingComposer,
          $$ProposalResponsesTableAnnotationComposer,
          $$ProposalResponsesTableCreateCompanionBuilder,
          $$ProposalResponsesTableUpdateCompanionBuilder,
          (
            ProposalResponse,
            BaseReferences<
              _$AppDatabase,
              $ProposalResponsesTable,
              ProposalResponse
            >,
          ),
          ProposalResponse,
          PrefetchHooks Function()
        > {
  $$ProposalResponsesTableTableManager(
    _$AppDatabase db,
    $ProposalResponsesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProposalResponsesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProposalResponsesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProposalResponsesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> revisionId = const Value.absent(),
                Value<String> participantId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> respondedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProposalResponsesCompanion(
                id: id,
                revisionId: revisionId,
                participantId: participantId,
                status: status,
                respondedAt: respondedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String revisionId,
                required String participantId,
                required String status,
                Value<DateTime?> respondedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProposalResponsesCompanion.insert(
                id: id,
                revisionId: revisionId,
                participantId: participantId,
                status: status,
                respondedAt: respondedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProposalResponsesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProposalResponsesTable,
      ProposalResponse,
      $$ProposalResponsesTableFilterComposer,
      $$ProposalResponsesTableOrderingComposer,
      $$ProposalResponsesTableAnnotationComposer,
      $$ProposalResponsesTableCreateCompanionBuilder,
      $$ProposalResponsesTableUpdateCompanionBuilder,
      (
        ProposalResponse,
        BaseReferences<
          _$AppDatabase,
          $ProposalResponsesTable,
          ProposalResponse
        >,
      ),
      ProposalResponse,
      PrefetchHooks Function()
    >;
typedef $$RelayActivityLogEntriesTableCreateCompanionBuilder =
    RelayActivityLogEntriesCompanion Function({
      required String id,
      required DateTime occurredAt,
      required String kind,
      required String initiatorKind,
      Value<String?> initiatorContactId,
      Value<String> initiatorDisplayName,
      Value<String?> planId,
      Value<String?> packageId,
      Value<String?> revisionId,
      Value<String> detailsJson,
      Value<int> rowid,
    });
typedef $$RelayActivityLogEntriesTableUpdateCompanionBuilder =
    RelayActivityLogEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> occurredAt,
      Value<String> kind,
      Value<String> initiatorKind,
      Value<String?> initiatorContactId,
      Value<String> initiatorDisplayName,
      Value<String?> planId,
      Value<String?> packageId,
      Value<String?> revisionId,
      Value<String> detailsJson,
      Value<int> rowid,
    });

class $$RelayActivityLogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $RelayActivityLogEntriesTable> {
  $$RelayActivityLogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initiatorKind => $composableBuilder(
    column: $table.initiatorKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initiatorContactId => $composableBuilder(
    column: $table.initiatorContactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initiatorDisplayName => $composableBuilder(
    column: $table.initiatorDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageId => $composableBuilder(
    column: $table.packageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RelayActivityLogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $RelayActivityLogEntriesTable> {
  $$RelayActivityLogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initiatorKind => $composableBuilder(
    column: $table.initiatorKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initiatorContactId => $composableBuilder(
    column: $table.initiatorContactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initiatorDisplayName => $composableBuilder(
    column: $table.initiatorDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageId => $composableBuilder(
    column: $table.packageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RelayActivityLogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RelayActivityLogEntriesTable> {
  $$RelayActivityLogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get initiatorKind => $composableBuilder(
    column: $table.initiatorKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get initiatorContactId => $composableBuilder(
    column: $table.initiatorContactId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get initiatorDisplayName => $composableBuilder(
    column: $table.initiatorDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get packageId =>
      $composableBuilder(column: $table.packageId, builder: (column) => column);

  GeneratedColumn<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => column,
  );
}

class $$RelayActivityLogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RelayActivityLogEntriesTable,
          RelayActivityLogEntry,
          $$RelayActivityLogEntriesTableFilterComposer,
          $$RelayActivityLogEntriesTableOrderingComposer,
          $$RelayActivityLogEntriesTableAnnotationComposer,
          $$RelayActivityLogEntriesTableCreateCompanionBuilder,
          $$RelayActivityLogEntriesTableUpdateCompanionBuilder,
          (
            RelayActivityLogEntry,
            BaseReferences<
              _$AppDatabase,
              $RelayActivityLogEntriesTable,
              RelayActivityLogEntry
            >,
          ),
          RelayActivityLogEntry,
          PrefetchHooks Function()
        > {
  $$RelayActivityLogEntriesTableTableManager(
    _$AppDatabase db,
    $RelayActivityLogEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelayActivityLogEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RelayActivityLogEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RelayActivityLogEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> initiatorKind = const Value.absent(),
                Value<String?> initiatorContactId = const Value.absent(),
                Value<String> initiatorDisplayName = const Value.absent(),
                Value<String?> planId = const Value.absent(),
                Value<String?> packageId = const Value.absent(),
                Value<String?> revisionId = const Value.absent(),
                Value<String> detailsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelayActivityLogEntriesCompanion(
                id: id,
                occurredAt: occurredAt,
                kind: kind,
                initiatorKind: initiatorKind,
                initiatorContactId: initiatorContactId,
                initiatorDisplayName: initiatorDisplayName,
                planId: planId,
                packageId: packageId,
                revisionId: revisionId,
                detailsJson: detailsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime occurredAt,
                required String kind,
                required String initiatorKind,
                Value<String?> initiatorContactId = const Value.absent(),
                Value<String> initiatorDisplayName = const Value.absent(),
                Value<String?> planId = const Value.absent(),
                Value<String?> packageId = const Value.absent(),
                Value<String?> revisionId = const Value.absent(),
                Value<String> detailsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelayActivityLogEntriesCompanion.insert(
                id: id,
                occurredAt: occurredAt,
                kind: kind,
                initiatorKind: initiatorKind,
                initiatorContactId: initiatorContactId,
                initiatorDisplayName: initiatorDisplayName,
                planId: planId,
                packageId: packageId,
                revisionId: revisionId,
                detailsJson: detailsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RelayActivityLogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RelayActivityLogEntriesTable,
      RelayActivityLogEntry,
      $$RelayActivityLogEntriesTableFilterComposer,
      $$RelayActivityLogEntriesTableOrderingComposer,
      $$RelayActivityLogEntriesTableAnnotationComposer,
      $$RelayActivityLogEntriesTableCreateCompanionBuilder,
      $$RelayActivityLogEntriesTableUpdateCompanionBuilder,
      (
        RelayActivityLogEntry,
        BaseReferences<
          _$AppDatabase,
          $RelayActivityLogEntriesTable,
          RelayActivityLogEntry
        >,
      ),
      RelayActivityLogEntry,
      PrefetchHooks Function()
    >;
typedef $$ContactsTableCreateCompanionBuilder =
    ContactsCompanion Function({
      required String id,
      required String kind,
      required String displayName,
      required String avatarId,
      Value<String> notes,
      Value<bool> isBlocked,
      Value<String?> relayRoutingId,
      Value<String?> peerPublicMaterial,
      Value<String?> localDisplayLabel,
      Value<String?> theirLabelForMe,
      Value<DateTime?> disconnectedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$ContactsTableUpdateCompanionBuilder =
    ContactsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> displayName,
      Value<String> avatarId,
      Value<String> notes,
      Value<bool> isBlocked,
      Value<String?> relayRoutingId,
      Value<String?> peerPublicMaterial,
      Value<String?> localDisplayLabel,
      Value<String?> theirLabelForMe,
      Value<DateTime?> disconnectedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$ContactsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarId => $composableBuilder(
    column: $table.avatarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBlocked => $composableBuilder(
    column: $table.isBlocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relayRoutingId => $composableBuilder(
    column: $table.relayRoutingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerPublicMaterial => $composableBuilder(
    column: $table.peerPublicMaterial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDisplayLabel => $composableBuilder(
    column: $table.localDisplayLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theirLabelForMe => $composableBuilder(
    column: $table.theirLabelForMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get disconnectedAt => $composableBuilder(
    column: $table.disconnectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarId => $composableBuilder(
    column: $table.avatarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBlocked => $composableBuilder(
    column: $table.isBlocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relayRoutingId => $composableBuilder(
    column: $table.relayRoutingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerPublicMaterial => $composableBuilder(
    column: $table.peerPublicMaterial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDisplayLabel => $composableBuilder(
    column: $table.localDisplayLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theirLabelForMe => $composableBuilder(
    column: $table.theirLabelForMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get disconnectedAt => $composableBuilder(
    column: $table.disconnectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarId =>
      $composableBuilder(column: $table.avatarId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isBlocked =>
      $composableBuilder(column: $table.isBlocked, builder: (column) => column);

  GeneratedColumn<String> get relayRoutingId => $composableBuilder(
    column: $table.relayRoutingId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerPublicMaterial => $composableBuilder(
    column: $table.peerPublicMaterial,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localDisplayLabel => $composableBuilder(
    column: $table.localDisplayLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get theirLabelForMe => $composableBuilder(
    column: $table.theirLabelForMe,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get disconnectedAt => $composableBuilder(
    column: $table.disconnectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactsTable,
          Contact,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (Contact, BaseReferences<_$AppDatabase, $ContactsTable, Contact>),
          Contact,
          PrefetchHooks Function()
        > {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
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
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> avatarId = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<bool> isBlocked = const Value.absent(),
                Value<String?> relayRoutingId = const Value.absent(),
                Value<String?> peerPublicMaterial = const Value.absent(),
                Value<String?> localDisplayLabel = const Value.absent(),
                Value<String?> theirLabelForMe = const Value.absent(),
                Value<DateTime?> disconnectedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion(
                id: id,
                kind: kind,
                displayName: displayName,
                avatarId: avatarId,
                notes: notes,
                isBlocked: isBlocked,
                relayRoutingId: relayRoutingId,
                peerPublicMaterial: peerPublicMaterial,
                localDisplayLabel: localDisplayLabel,
                theirLabelForMe: theirLabelForMe,
                disconnectedAt: disconnectedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String displayName,
                required String avatarId,
                Value<String> notes = const Value.absent(),
                Value<bool> isBlocked = const Value.absent(),
                Value<String?> relayRoutingId = const Value.absent(),
                Value<String?> peerPublicMaterial = const Value.absent(),
                Value<String?> localDisplayLabel = const Value.absent(),
                Value<String?> theirLabelForMe = const Value.absent(),
                Value<DateTime?> disconnectedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion.insert(
                id: id,
                kind: kind,
                displayName: displayName,
                avatarId: avatarId,
                notes: notes,
                isBlocked: isBlocked,
                relayRoutingId: relayRoutingId,
                peerPublicMaterial: peerPublicMaterial,
                localDisplayLabel: localDisplayLabel,
                theirLabelForMe: theirLabelForMe,
                disconnectedAt: disconnectedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
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
      _$AppDatabase,
      $ContactsTable,
      Contact,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (Contact, BaseReferences<_$AppDatabase, $ContactsTable, Contact>),
      Contact,
      PrefetchHooks Function()
    >;
typedef $$ContactInvitationsTableCreateCompanionBuilder =
    ContactInvitationsCompanion Function({
      required String id,
      required String nonce,
      required String status,
      required DateTime createdAt,
      required DateTime expiresAt,
      Value<DateTime?> consumedAt,
      Value<String?> contactStubId,
      Value<int> rowid,
    });
typedef $$ContactInvitationsTableUpdateCompanionBuilder =
    ContactInvitationsCompanion Function({
      Value<String> id,
      Value<String> nonce,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> expiresAt,
      Value<DateTime?> consumedAt,
      Value<String?> contactStubId,
      Value<int> rowid,
    });

class $$ContactInvitationsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactInvitationsTable> {
  $$ContactInvitationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nonce => $composableBuilder(
    column: $table.nonce,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactStubId => $composableBuilder(
    column: $table.contactStubId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactInvitationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactInvitationsTable> {
  $$ContactInvitationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nonce => $composableBuilder(
    column: $table.nonce,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactStubId => $composableBuilder(
    column: $table.contactStubId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactInvitationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactInvitationsTable> {
  $$ContactInvitationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nonce =>
      $composableBuilder(column: $table.nonce, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactStubId => $composableBuilder(
    column: $table.contactStubId,
    builder: (column) => column,
  );
}

class $$ContactInvitationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactInvitationsTable,
          ContactInvitation,
          $$ContactInvitationsTableFilterComposer,
          $$ContactInvitationsTableOrderingComposer,
          $$ContactInvitationsTableAnnotationComposer,
          $$ContactInvitationsTableCreateCompanionBuilder,
          $$ContactInvitationsTableUpdateCompanionBuilder,
          (
            ContactInvitation,
            BaseReferences<
              _$AppDatabase,
              $ContactInvitationsTable,
              ContactInvitation
            >,
          ),
          ContactInvitation,
          PrefetchHooks Function()
        > {
  $$ContactInvitationsTableTableManager(
    _$AppDatabase db,
    $ContactInvitationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactInvitationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactInvitationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactInvitationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nonce = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime?> consumedAt = const Value.absent(),
                Value<String?> contactStubId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactInvitationsCompanion(
                id: id,
                nonce: nonce,
                status: status,
                createdAt: createdAt,
                expiresAt: expiresAt,
                consumedAt: consumedAt,
                contactStubId: contactStubId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nonce,
                required String status,
                required DateTime createdAt,
                required DateTime expiresAt,
                Value<DateTime?> consumedAt = const Value.absent(),
                Value<String?> contactStubId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactInvitationsCompanion.insert(
                id: id,
                nonce: nonce,
                status: status,
                createdAt: createdAt,
                expiresAt: expiresAt,
                consumedAt: consumedAt,
                contactStubId: contactStubId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContactInvitationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactInvitationsTable,
      ContactInvitation,
      $$ContactInvitationsTableFilterComposer,
      $$ContactInvitationsTableOrderingComposer,
      $$ContactInvitationsTableAnnotationComposer,
      $$ContactInvitationsTableCreateCompanionBuilder,
      $$ContactInvitationsTableUpdateCompanionBuilder,
      (
        ContactInvitation,
        BaseReferences<
          _$AppDatabase,
          $ContactInvitationsTable,
          ContactInvitation
        >,
      ),
      ContactInvitation,
      PrefetchHooks Function()
    >;
typedef $$PendingHandshakesTableCreateCompanionBuilder =
    PendingHandshakesCompanion Function({
      required String id,
      required String invitationIdHex,
      required String nonceHex,
      required String role,
      required String state,
      required String contactStubId,
      Value<String?> peerLongTermPublicMaterialB64,
      Value<String> peerDisplayName,
      Value<String> peerAvatarId,
      Value<String> lastErrorCode,
      required DateTime createdAt,
      required DateTime updatedAt,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$PendingHandshakesTableUpdateCompanionBuilder =
    PendingHandshakesCompanion Function({
      Value<String> id,
      Value<String> invitationIdHex,
      Value<String> nonceHex,
      Value<String> role,
      Value<String> state,
      Value<String> contactStubId,
      Value<String?> peerLongTermPublicMaterialB64,
      Value<String> peerDisplayName,
      Value<String> peerAvatarId,
      Value<String> lastErrorCode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

class $$PendingHandshakesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingHandshakesTable> {
  $$PendingHandshakesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invitationIdHex => $composableBuilder(
    column: $table.invitationIdHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nonceHex => $composableBuilder(
    column: $table.nonceHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactStubId => $composableBuilder(
    column: $table.contactStubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerLongTermPublicMaterialB64 => $composableBuilder(
    column: $table.peerLongTermPublicMaterialB64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerAvatarId => $composableBuilder(
    column: $table.peerAvatarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingHandshakesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingHandshakesTable> {
  $$PendingHandshakesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invitationIdHex => $composableBuilder(
    column: $table.invitationIdHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nonceHex => $composableBuilder(
    column: $table.nonceHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactStubId => $composableBuilder(
    column: $table.contactStubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerLongTermPublicMaterialB64 =>
      $composableBuilder(
        column: $table.peerLongTermPublicMaterialB64,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerAvatarId => $composableBuilder(
    column: $table.peerAvatarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingHandshakesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingHandshakesTable> {
  $$PendingHandshakesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get invitationIdHex => $composableBuilder(
    column: $table.invitationIdHex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nonceHex =>
      $composableBuilder(column: $table.nonceHex, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get contactStubId => $composableBuilder(
    column: $table.contactStubId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerLongTermPublicMaterialB64 =>
      $composableBuilder(
        column: $table.peerLongTermPublicMaterialB64,
        builder: (column) => column,
      );

  GeneratedColumn<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerAvatarId => $composableBuilder(
    column: $table.peerAvatarId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$PendingHandshakesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingHandshakesTable,
          PendingHandshake,
          $$PendingHandshakesTableFilterComposer,
          $$PendingHandshakesTableOrderingComposer,
          $$PendingHandshakesTableAnnotationComposer,
          $$PendingHandshakesTableCreateCompanionBuilder,
          $$PendingHandshakesTableUpdateCompanionBuilder,
          (
            PendingHandshake,
            BaseReferences<
              _$AppDatabase,
              $PendingHandshakesTable,
              PendingHandshake
            >,
          ),
          PendingHandshake,
          PrefetchHooks Function()
        > {
  $$PendingHandshakesTableTableManager(
    _$AppDatabase db,
    $PendingHandshakesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingHandshakesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingHandshakesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingHandshakesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> invitationIdHex = const Value.absent(),
                Value<String> nonceHex = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> contactStubId = const Value.absent(),
                Value<String?> peerLongTermPublicMaterialB64 =
                    const Value.absent(),
                Value<String> peerDisplayName = const Value.absent(),
                Value<String> peerAvatarId = const Value.absent(),
                Value<String> lastErrorCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingHandshakesCompanion(
                id: id,
                invitationIdHex: invitationIdHex,
                nonceHex: nonceHex,
                role: role,
                state: state,
                contactStubId: contactStubId,
                peerLongTermPublicMaterialB64: peerLongTermPublicMaterialB64,
                peerDisplayName: peerDisplayName,
                peerAvatarId: peerAvatarId,
                lastErrorCode: lastErrorCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String invitationIdHex,
                required String nonceHex,
                required String role,
                required String state,
                required String contactStubId,
                Value<String?> peerLongTermPublicMaterialB64 =
                    const Value.absent(),
                Value<String> peerDisplayName = const Value.absent(),
                Value<String> peerAvatarId = const Value.absent(),
                Value<String> lastErrorCode = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingHandshakesCompanion.insert(
                id: id,
                invitationIdHex: invitationIdHex,
                nonceHex: nonceHex,
                role: role,
                state: state,
                contactStubId: contactStubId,
                peerLongTermPublicMaterialB64: peerLongTermPublicMaterialB64,
                peerDisplayName: peerDisplayName,
                peerAvatarId: peerAvatarId,
                lastErrorCode: lastErrorCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingHandshakesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingHandshakesTable,
      PendingHandshake,
      $$PendingHandshakesTableFilterComposer,
      $$PendingHandshakesTableOrderingComposer,
      $$PendingHandshakesTableAnnotationComposer,
      $$PendingHandshakesTableCreateCompanionBuilder,
      $$PendingHandshakesTableUpdateCompanionBuilder,
      (
        PendingHandshake,
        BaseReferences<
          _$AppDatabase,
          $PendingHandshakesTable,
          PendingHandshake
        >,
      ),
      PendingHandshake,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$ParticipantsTableTableManager get participants =>
      $$ParticipantsTableTableManager(_db, _db.participants);
  $$PlanLinesTableTableManager get planLines =>
      $$PlanLinesTableTableManager(_db, _db.planLines);
  $$PlanGroupsTableTableManager get planGroups =>
      $$PlanGroupsTableTableManager(_db, _db.planGroups);
  $$PlanRatiosTableTableManager get planRatios =>
      $$PlanRatiosTableTableManager(_db, _db.planRatios);
  $$PlanRatioTemplatesTableTableManager get planRatioTemplates =>
      $$PlanRatioTemplatesTableTableManager(_db, _db.planRatioTemplates);
  $$AgreementsTableTableManager get agreements =>
      $$AgreementsTableTableManager(_db, _db.agreements);
  $$ProposalPackagesTableTableManager get proposalPackages =>
      $$ProposalPackagesTableTableManager(_db, _db.proposalPackages);
  $$ProposalRevisionsTableTableManager get proposalRevisions =>
      $$ProposalRevisionsTableTableManager(_db, _db.proposalRevisions);
  $$ProposalResponsesTableTableManager get proposalResponses =>
      $$ProposalResponsesTableTableManager(_db, _db.proposalResponses);
  $$RelayActivityLogEntriesTableTableManager get relayActivityLogEntries =>
      $$RelayActivityLogEntriesTableTableManager(
        _db,
        _db.relayActivityLogEntries,
      );
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$ContactInvitationsTableTableManager get contactInvitations =>
      $$ContactInvitationsTableTableManager(_db, _db.contactInvitations);
  $$PendingHandshakesTableTableManager get pendingHandshakes =>
      $$PendingHandshakesTableTableManager(_db, _db.pendingHandshakes);
}
