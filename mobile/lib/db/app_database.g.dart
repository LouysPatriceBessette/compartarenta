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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $ParticipantsTable participants = $ParticipantsTable(this);
  late final $PlanLinesTable planLines = $PlanLinesTable(this);
  late final $PlanGroupsTable planGroups = $PlanGroupsTable(this);
  late final $PlanRatiosTable planRatios = $PlanRatiosTable(this);
  late final $AgreementsTable agreements = $AgreementsTable(this);
  late final $ProposalPackagesTable proposalPackages = $ProposalPackagesTable(
    this,
  );
  late final $ProposalRevisionsTable proposalRevisions =
      $ProposalRevisionsTable(this);
  late final $ProposalResponsesTable proposalResponses =
      $ProposalResponsesTable(this);
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
    agreements,
    proposalPackages,
    proposalRevisions,
    proposalResponses,
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
      Value<bool> amountUsesRange,
      Value<int?> amountMinor,
      Value<int?> minAmountMinor,
      Value<int?> maxAmountMinor,
      Value<String> description,
      Value<String> cadence,
      Value<int?> recurrenceDayOfMonth,
      Value<int> sortOrder,
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
      Value<bool> amountUsesRange,
      Value<int?> amountMinor,
      Value<int?> minAmountMinor,
      Value<int?> maxAmountMinor,
      Value<String> description,
      Value<String> cadence,
      Value<int?> recurrenceDayOfMonth,
      Value<int> sortOrder,
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
  $$AgreementsTableTableManager get agreements =>
      $$AgreementsTableTableManager(_db, _db.agreements);
  $$ProposalPackagesTableTableManager get proposalPackages =>
      $$ProposalPackagesTableTableManager(_db, _db.proposalPackages);
  $$ProposalRevisionsTableTableManager get proposalRevisions =>
      $$ProposalRevisionsTableTableManager(_db, _db.proposalRevisions);
  $$ProposalResponsesTableTableManager get proposalResponses =>
      $$ProposalResponsesTableTableManager(_db, _db.proposalResponses);
}
