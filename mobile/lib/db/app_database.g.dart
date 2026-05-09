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
  @override
  List<GeneratedColumn> get $columns => [id, displayName, avatarId, createdAt];
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
  const Participant({
    required this.id,
    required this.displayName,
    required this.avatarId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['avatar_id'] = Variable<String>(avatarId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ParticipantsCompanion toCompanion(bool nullToAbsent) {
    return ParticipantsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      avatarId: Value(avatarId),
      createdAt: Value(createdAt),
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
    };
  }

  Participant copyWith({
    String? id,
    String? displayName,
    String? avatarId,
    DateTime? createdAt,
  }) => Participant(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    avatarId: avatarId ?? this.avatarId,
    createdAt: createdAt ?? this.createdAt,
  );
  Participant copyWithCompanion(ParticipantsCompanion data) {
    return Participant(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarId: data.avatarId.present ? data.avatarId.value : this.avatarId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Participant(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('avatarId: $avatarId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, avatarId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Participant &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.avatarId == this.avatarId &&
          other.createdAt == this.createdAt);
}

class ParticipantsCompanion extends UpdateCompanion<Participant> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> avatarId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ParticipantsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParticipantsCompanion.insert({
    required String id,
    required String displayName,
    required String avatarId,
    required DateTime createdAt,
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
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (avatarId != null) 'avatar_id': avatarId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParticipantsCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? avatarId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ParticipantsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarId: avatarId ?? this.avatarId,
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
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarId.present) {
      map['avatar_id'] = Variable<String>(avatarId.value);
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
    return (StringBuffer('ParticipantsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('avatarId: $avatarId, ')
          ..write('createdAt: $createdAt, ')
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
    amountMinor,
    minAmountMinor,
    maxAmountMinor,
    cadence,
    groupId,
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
    if (data.containsKey('cadence')) {
      context.handle(
        _cadenceMeta,
        cadence.isAcceptableOrUnknown(data['cadence']!, _cadenceMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
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
      cadence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cadence'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
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
  final int? amountMinor;
  final int? minAmountMinor;
  final int? maxAmountMinor;
  final String cadence;
  final String? groupId;
  final DateTime createdAt;
  const PlanLine({
    required this.id,
    required this.planId,
    required this.isRecurring,
    required this.title,
    required this.currency,
    this.amountMinor,
    this.minAmountMinor,
    this.maxAmountMinor,
    required this.cadence,
    this.groupId,
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
    if (!nullToAbsent || amountMinor != null) {
      map['amount_minor'] = Variable<int>(amountMinor);
    }
    if (!nullToAbsent || minAmountMinor != null) {
      map['min_amount_minor'] = Variable<int>(minAmountMinor);
    }
    if (!nullToAbsent || maxAmountMinor != null) {
      map['max_amount_minor'] = Variable<int>(maxAmountMinor);
    }
    map['cadence'] = Variable<String>(cadence);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
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
      amountMinor: amountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinor),
      minAmountMinor: minAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(minAmountMinor),
      maxAmountMinor: maxAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(maxAmountMinor),
      cadence: Value(cadence),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
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
      amountMinor: serializer.fromJson<int?>(json['amountMinor']),
      minAmountMinor: serializer.fromJson<int?>(json['minAmountMinor']),
      maxAmountMinor: serializer.fromJson<int?>(json['maxAmountMinor']),
      cadence: serializer.fromJson<String>(json['cadence']),
      groupId: serializer.fromJson<String?>(json['groupId']),
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
      'amountMinor': serializer.toJson<int?>(amountMinor),
      'minAmountMinor': serializer.toJson<int?>(minAmountMinor),
      'maxAmountMinor': serializer.toJson<int?>(maxAmountMinor),
      'cadence': serializer.toJson<String>(cadence),
      'groupId': serializer.toJson<String?>(groupId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlanLine copyWith({
    String? id,
    String? planId,
    bool? isRecurring,
    String? title,
    String? currency,
    Value<int?> amountMinor = const Value.absent(),
    Value<int?> minAmountMinor = const Value.absent(),
    Value<int?> maxAmountMinor = const Value.absent(),
    String? cadence,
    Value<String?> groupId = const Value.absent(),
    DateTime? createdAt,
  }) => PlanLine(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    isRecurring: isRecurring ?? this.isRecurring,
    title: title ?? this.title,
    currency: currency ?? this.currency,
    amountMinor: amountMinor.present ? amountMinor.value : this.amountMinor,
    minAmountMinor: minAmountMinor.present
        ? minAmountMinor.value
        : this.minAmountMinor,
    maxAmountMinor: maxAmountMinor.present
        ? maxAmountMinor.value
        : this.maxAmountMinor,
    cadence: cadence ?? this.cadence,
    groupId: groupId.present ? groupId.value : this.groupId,
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
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      minAmountMinor: data.minAmountMinor.present
          ? data.minAmountMinor.value
          : this.minAmountMinor,
      maxAmountMinor: data.maxAmountMinor.present
          ? data.maxAmountMinor.value
          : this.maxAmountMinor,
      cadence: data.cadence.present ? data.cadence.value : this.cadence,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
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
          ..write('amountMinor: $amountMinor, ')
          ..write('minAmountMinor: $minAmountMinor, ')
          ..write('maxAmountMinor: $maxAmountMinor, ')
          ..write('cadence: $cadence, ')
          ..write('groupId: $groupId, ')
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
    amountMinor,
    minAmountMinor,
    maxAmountMinor,
    cadence,
    groupId,
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
          other.amountMinor == this.amountMinor &&
          other.minAmountMinor == this.minAmountMinor &&
          other.maxAmountMinor == this.maxAmountMinor &&
          other.cadence == this.cadence &&
          other.groupId == this.groupId &&
          other.createdAt == this.createdAt);
}

class PlanLinesCompanion extends UpdateCompanion<PlanLine> {
  final Value<String> id;
  final Value<String> planId;
  final Value<bool> isRecurring;
  final Value<String> title;
  final Value<String> currency;
  final Value<int?> amountMinor;
  final Value<int?> minAmountMinor;
  final Value<int?> maxAmountMinor;
  final Value<String> cadence;
  final Value<String?> groupId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlanLinesCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.title = const Value.absent(),
    this.currency = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.minAmountMinor = const Value.absent(),
    this.maxAmountMinor = const Value.absent(),
    this.cadence = const Value.absent(),
    this.groupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanLinesCompanion.insert({
    required String id,
    required String planId,
    required bool isRecurring,
    required String title,
    required String currency,
    this.amountMinor = const Value.absent(),
    this.minAmountMinor = const Value.absent(),
    this.maxAmountMinor = const Value.absent(),
    this.cadence = const Value.absent(),
    this.groupId = const Value.absent(),
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
    Expression<int>? amountMinor,
    Expression<int>? minAmountMinor,
    Expression<int>? maxAmountMinor,
    Expression<String>? cadence,
    Expression<String>? groupId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (title != null) 'title': title,
      if (currency != null) 'currency': currency,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (minAmountMinor != null) 'min_amount_minor': minAmountMinor,
      if (maxAmountMinor != null) 'max_amount_minor': maxAmountMinor,
      if (cadence != null) 'cadence': cadence,
      if (groupId != null) 'group_id': groupId,
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
    Value<int?>? amountMinor,
    Value<int?>? minAmountMinor,
    Value<int?>? maxAmountMinor,
    Value<String>? cadence,
    Value<String?>? groupId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlanLinesCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      isRecurring: isRecurring ?? this.isRecurring,
      title: title ?? this.title,
      currency: currency ?? this.currency,
      amountMinor: amountMinor ?? this.amountMinor,
      minAmountMinor: minAmountMinor ?? this.minAmountMinor,
      maxAmountMinor: maxAmountMinor ?? this.maxAmountMinor,
      cadence: cadence ?? this.cadence,
      groupId: groupId ?? this.groupId,
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
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (minAmountMinor.present) {
      map['min_amount_minor'] = Variable<int>(minAmountMinor.value);
    }
    if (maxAmountMinor.present) {
      map['max_amount_minor'] = Variable<int>(maxAmountMinor.value);
    }
    if (cadence.present) {
      map['cadence'] = Variable<String>(cadence.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
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
          ..write('amountMinor: $amountMinor, ')
          ..write('minAmountMinor: $minAmountMinor, ')
          ..write('maxAmountMinor: $maxAmountMinor, ')
          ..write('cadence: $cadence, ')
          ..write('groupId: $groupId, ')
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
  List<GeneratedColumn> get $columns => [id, planId, title, createdAt];
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
  final DateTime createdAt;
  const PlanGroup({
    required this.id,
    required this.planId,
    required this.title,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlanGroupsCompanion toCompanion(bool nullToAbsent) {
    return PlanGroupsCompanion(
      id: Value(id),
      planId: Value(planId),
      title: Value(title),
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
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlanGroup copyWith({
    String? id,
    String? planId,
    String? title,
    DateTime? createdAt,
  }) => PlanGroup(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
  );
  PlanGroup copyWithCompanion(PlanGroupsCompanion data) {
    return PlanGroup(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanGroup(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planId, title, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanGroup &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.title == this.title &&
          other.createdAt == this.createdAt);
}

class PlanGroupsCompanion extends UpdateCompanion<PlanGroup> {
  final Value<String> id;
  final Value<String> planId;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlanGroupsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanGroupsCompanion.insert({
    required String id,
    required String planId,
    required String title,
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
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlanGroupsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      title: title ?? this.title,
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

class $AgreementContractsTable extends AgreementContracts
    with TableInfo<$AgreementContractsTable, AgreementContract> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgreementContractsTable(this.attachedDatabase, [this._alias]);
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
    Insertable<AgreementContract> instance, {
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
  AgreementContract map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgreementContract(
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
  $AgreementContractsTable createAlias(String alias) {
    return $AgreementContractsTable(attachedDatabase, alias);
  }
}

class AgreementContract extends DataClass
    implements Insertable<AgreementContract> {
  final String id;
  final String planId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int minNoticeDays;
  final int penaltyMinor;
  final String clauses;
  final int version;
  final DateTime createdAt;
  const AgreementContract({
    required this.id,
    required this.planId,
    required this.periodStart,
    required this.periodEnd,
    required this.minNoticeDays,
    required this.penaltyMinor,
    required this.clauses,
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
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AgreementContractsCompanion toCompanion(bool nullToAbsent) {
    return AgreementContractsCompanion(
      id: Value(id),
      planId: Value(planId),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      minNoticeDays: Value(minNoticeDays),
      penaltyMinor: Value(penaltyMinor),
      clauses: Value(clauses),
      version: Value(version),
      createdAt: Value(createdAt),
    );
  }

  factory AgreementContract.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgreementContract(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      periodStart: serializer.fromJson<DateTime>(json['periodStart']),
      periodEnd: serializer.fromJson<DateTime>(json['periodEnd']),
      minNoticeDays: serializer.fromJson<int>(json['minNoticeDays']),
      penaltyMinor: serializer.fromJson<int>(json['penaltyMinor']),
      clauses: serializer.fromJson<String>(json['clauses']),
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
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AgreementContract copyWith({
    String? id,
    String? planId,
    DateTime? periodStart,
    DateTime? periodEnd,
    int? minNoticeDays,
    int? penaltyMinor,
    String? clauses,
    int? version,
    DateTime? createdAt,
  }) => AgreementContract(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    minNoticeDays: minNoticeDays ?? this.minNoticeDays,
    penaltyMinor: penaltyMinor ?? this.penaltyMinor,
    clauses: clauses ?? this.clauses,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
  );
  AgreementContract copyWithCompanion(AgreementContractsCompanion data) {
    return AgreementContract(
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
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgreementContract(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('minNoticeDays: $minNoticeDays, ')
          ..write('penaltyMinor: $penaltyMinor, ')
          ..write('clauses: $clauses, ')
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
    version,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgreementContract &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.minNoticeDays == this.minNoticeDays &&
          other.penaltyMinor == this.penaltyMinor &&
          other.clauses == this.clauses &&
          other.version == this.version &&
          other.createdAt == this.createdAt);
}

class AgreementContractsCompanion extends UpdateCompanion<AgreementContract> {
  final Value<String> id;
  final Value<String> planId;
  final Value<DateTime> periodStart;
  final Value<DateTime> periodEnd;
  final Value<int> minNoticeDays;
  final Value<int> penaltyMinor;
  final Value<String> clauses;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AgreementContractsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.minNoticeDays = const Value.absent(),
    this.penaltyMinor = const Value.absent(),
    this.clauses = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgreementContractsCompanion.insert({
    required String id,
    required String planId,
    required DateTime periodStart,
    required DateTime periodEnd,
    this.minNoticeDays = const Value.absent(),
    this.penaltyMinor = const Value.absent(),
    this.clauses = const Value.absent(),
    this.version = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       periodStart = Value(periodStart),
       periodEnd = Value(periodEnd),
       createdAt = Value(createdAt);
  static Insertable<AgreementContract> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<DateTime>? periodStart,
    Expression<DateTime>? periodEnd,
    Expression<int>? minNoticeDays,
    Expression<int>? penaltyMinor,
    Expression<String>? clauses,
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
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgreementContractsCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<DateTime>? periodStart,
    Value<DateTime>? periodEnd,
    Value<int>? minNoticeDays,
    Value<int>? penaltyMinor,
    Value<String>? clauses,
    Value<int>? version,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AgreementContractsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      minNoticeDays: minNoticeDays ?? this.minNoticeDays,
      penaltyMinor: penaltyMinor ?? this.penaltyMinor,
      clauses: clauses ?? this.clauses,
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
    return (StringBuffer('AgreementContractsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('minNoticeDays: $minNoticeDays, ')
          ..write('penaltyMinor: $penaltyMinor, ')
          ..write('clauses: $clauses, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
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
  late final $AgreementContractsTable agreementContracts =
      $AgreementContractsTable(this);
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
    agreementContracts,
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
      Value<int> rowid,
    });
typedef $$ParticipantsTableUpdateCompanionBuilder =
    ParticipantsCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> avatarId,
      Value<DateTime> createdAt,
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
                Value<int> rowid = const Value.absent(),
              }) => ParticipantsCompanion(
                id: id,
                displayName: displayName,
                avatarId: avatarId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String avatarId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ParticipantsCompanion.insert(
                id: id,
                displayName: displayName,
                avatarId: avatarId,
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
      Value<int?> amountMinor,
      Value<int?> minAmountMinor,
      Value<int?> maxAmountMinor,
      Value<String> cadence,
      Value<String?> groupId,
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
      Value<int?> amountMinor,
      Value<int?> minAmountMinor,
      Value<int?> maxAmountMinor,
      Value<String> cadence,
      Value<String?> groupId,
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

  ColumnFilters<String> get cadence => $composableBuilder(
    column: $table.cadence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
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

  ColumnOrderings<String> get cadence => $composableBuilder(
    column: $table.cadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
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

  GeneratedColumn<String> get cadence =>
      $composableBuilder(column: $table.cadence, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

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
                Value<int?> amountMinor = const Value.absent(),
                Value<int?> minAmountMinor = const Value.absent(),
                Value<int?> maxAmountMinor = const Value.absent(),
                Value<String> cadence = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanLinesCompanion(
                id: id,
                planId: planId,
                isRecurring: isRecurring,
                title: title,
                currency: currency,
                amountMinor: amountMinor,
                minAmountMinor: minAmountMinor,
                maxAmountMinor: maxAmountMinor,
                cadence: cadence,
                groupId: groupId,
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
                Value<int?> amountMinor = const Value.absent(),
                Value<int?> minAmountMinor = const Value.absent(),
                Value<int?> maxAmountMinor = const Value.absent(),
                Value<String> cadence = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlanLinesCompanion.insert(
                id: id,
                planId: planId,
                isRecurring: isRecurring,
                title: title,
                currency: currency,
                amountMinor: amountMinor,
                minAmountMinor: minAmountMinor,
                maxAmountMinor: maxAmountMinor,
                cadence: cadence,
                groupId: groupId,
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
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PlanGroupsTableUpdateCompanionBuilder =
    PlanGroupsCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<String> title,
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
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanGroupsCompanion(
                id: id,
                planId: planId,
                title: title,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required String title,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlanGroupsCompanion.insert(
                id: id,
                planId: planId,
                title: title,
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
typedef $$AgreementContractsTableCreateCompanionBuilder =
    AgreementContractsCompanion Function({
      required String id,
      required String planId,
      required DateTime periodStart,
      required DateTime periodEnd,
      Value<int> minNoticeDays,
      Value<int> penaltyMinor,
      Value<String> clauses,
      Value<int> version,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AgreementContractsTableUpdateCompanionBuilder =
    AgreementContractsCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<DateTime> periodStart,
      Value<DateTime> periodEnd,
      Value<int> minNoticeDays,
      Value<int> penaltyMinor,
      Value<String> clauses,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AgreementContractsTableFilterComposer
    extends Composer<_$AppDatabase, $AgreementContractsTable> {
  $$AgreementContractsTableFilterComposer({
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AgreementContractsTableOrderingComposer
    extends Composer<_$AppDatabase, $AgreementContractsTable> {
  $$AgreementContractsTableOrderingComposer({
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgreementContractsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgreementContractsTable> {
  $$AgreementContractsTableAnnotationComposer({
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

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AgreementContractsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgreementContractsTable,
          AgreementContract,
          $$AgreementContractsTableFilterComposer,
          $$AgreementContractsTableOrderingComposer,
          $$AgreementContractsTableAnnotationComposer,
          $$AgreementContractsTableCreateCompanionBuilder,
          $$AgreementContractsTableUpdateCompanionBuilder,
          (
            AgreementContract,
            BaseReferences<
              _$AppDatabase,
              $AgreementContractsTable,
              AgreementContract
            >,
          ),
          AgreementContract,
          PrefetchHooks Function()
        > {
  $$AgreementContractsTableTableManager(
    _$AppDatabase db,
    $AgreementContractsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgreementContractsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgreementContractsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgreementContractsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<DateTime> periodStart = const Value.absent(),
                Value<DateTime> periodEnd = const Value.absent(),
                Value<int> minNoticeDays = const Value.absent(),
                Value<int> penaltyMinor = const Value.absent(),
                Value<String> clauses = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgreementContractsCompanion(
                id: id,
                planId: planId,
                periodStart: periodStart,
                periodEnd: periodEnd,
                minNoticeDays: minNoticeDays,
                penaltyMinor: penaltyMinor,
                clauses: clauses,
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
                Value<int> version = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AgreementContractsCompanion.insert(
                id: id,
                planId: planId,
                periodStart: periodStart,
                periodEnd: periodEnd,
                minNoticeDays: minNoticeDays,
                penaltyMinor: penaltyMinor,
                clauses: clauses,
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

typedef $$AgreementContractsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgreementContractsTable,
      AgreementContract,
      $$AgreementContractsTableFilterComposer,
      $$AgreementContractsTableOrderingComposer,
      $$AgreementContractsTableAnnotationComposer,
      $$AgreementContractsTableCreateCompanionBuilder,
      $$AgreementContractsTableUpdateCompanionBuilder,
      (
        AgreementContract,
        BaseReferences<
          _$AppDatabase,
          $AgreementContractsTable,
          AgreementContract
        >,
      ),
      AgreementContract,
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
  $$AgreementContractsTableTableManager get agreementContracts =>
      $$AgreementContractsTableTableManager(_db, _db.agreementContracts);
}
