// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
    'fat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<double> carbs = GeneratedColumn<double>(
    'carbs',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trainingExtraKcalMeta = const VerificationMeta(
    'trainingExtraKcal',
  );
  @override
  late final GeneratedColumn<double> trainingExtraKcal =
      GeneratedColumn<double>(
        'training_extra_kcal',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _trainingExtraFromMeta = const VerificationMeta(
    'trainingExtraFrom',
  );
  @override
  late final GeneratedColumn<String> trainingExtraFrom =
      GeneratedColumn<String>(
        'training_extra_from',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kcal,
    protein,
    fat,
    carbs,
    trainingExtraKcal,
    trainingExtraFrom,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinMeta);
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    } else if (isInserting) {
      context.missing(_fatMeta);
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsMeta);
    }
    if (data.containsKey('training_extra_kcal')) {
      context.handle(
        _trainingExtraKcalMeta,
        trainingExtraKcal.isAcceptableOrUnknown(
          data['training_extra_kcal']!,
          _trainingExtraKcalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trainingExtraKcalMeta);
    }
    if (data.containsKey('training_extra_from')) {
      context.handle(
        _trainingExtraFromMeta,
        trainingExtraFrom.isAcceptableOrUnknown(
          data['training_extra_from']!,
          _trainingExtraFromMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trainingExtraFromMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein'],
      )!,
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat'],
      )!,
      carbs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs'],
      )!,
      trainingExtraKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}training_extra_kcal'],
      )!,
      trainingExtraFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}training_extra_from'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class GoalsRow extends DataClass implements Insertable<GoalsRow> {
  final int id;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final double trainingExtraKcal;

  /// Klucz makro: 'p', 'f' albo 'c'.
  final String trainingExtraFrom;
  const GoalsRow({
    required this.id,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.trainingExtraKcal,
    required this.trainingExtraFrom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kcal'] = Variable<double>(kcal);
    map['protein'] = Variable<double>(protein);
    map['fat'] = Variable<double>(fat);
    map['carbs'] = Variable<double>(carbs);
    map['training_extra_kcal'] = Variable<double>(trainingExtraKcal);
    map['training_extra_from'] = Variable<String>(trainingExtraFrom);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      kcal: Value(kcal),
      protein: Value(protein),
      fat: Value(fat),
      carbs: Value(carbs),
      trainingExtraKcal: Value(trainingExtraKcal),
      trainingExtraFrom: Value(trainingExtraFrom),
    );
  }

  factory GoalsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalsRow(
      id: serializer.fromJson<int>(json['id']),
      kcal: serializer.fromJson<double>(json['kcal']),
      protein: serializer.fromJson<double>(json['protein']),
      fat: serializer.fromJson<double>(json['fat']),
      carbs: serializer.fromJson<double>(json['carbs']),
      trainingExtraKcal: serializer.fromJson<double>(json['trainingExtraKcal']),
      trainingExtraFrom: serializer.fromJson<String>(json['trainingExtraFrom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kcal': serializer.toJson<double>(kcal),
      'protein': serializer.toJson<double>(protein),
      'fat': serializer.toJson<double>(fat),
      'carbs': serializer.toJson<double>(carbs),
      'trainingExtraKcal': serializer.toJson<double>(trainingExtraKcal),
      'trainingExtraFrom': serializer.toJson<String>(trainingExtraFrom),
    };
  }

  GoalsRow copyWith({
    int? id,
    double? kcal,
    double? protein,
    double? fat,
    double? carbs,
    double? trainingExtraKcal,
    String? trainingExtraFrom,
  }) => GoalsRow(
    id: id ?? this.id,
    kcal: kcal ?? this.kcal,
    protein: protein ?? this.protein,
    fat: fat ?? this.fat,
    carbs: carbs ?? this.carbs,
    trainingExtraKcal: trainingExtraKcal ?? this.trainingExtraKcal,
    trainingExtraFrom: trainingExtraFrom ?? this.trainingExtraFrom,
  );
  GoalsRow copyWithCompanion(GoalsCompanion data) {
    return GoalsRow(
      id: data.id.present ? data.id.value : this.id,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      protein: data.protein.present ? data.protein.value : this.protein,
      fat: data.fat.present ? data.fat.value : this.fat,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      trainingExtraKcal: data.trainingExtraKcal.present
          ? data.trainingExtraKcal.value
          : this.trainingExtraKcal,
      trainingExtraFrom: data.trainingExtraFrom.present
          ? data.trainingExtraFrom.value
          : this.trainingExtraFrom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalsRow(')
          ..write('id: $id, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('fat: $fat, ')
          ..write('carbs: $carbs, ')
          ..write('trainingExtraKcal: $trainingExtraKcal, ')
          ..write('trainingExtraFrom: $trainingExtraFrom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kcal,
    protein,
    fat,
    carbs,
    trainingExtraKcal,
    trainingExtraFrom,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalsRow &&
          other.id == this.id &&
          other.kcal == this.kcal &&
          other.protein == this.protein &&
          other.fat == this.fat &&
          other.carbs == this.carbs &&
          other.trainingExtraKcal == this.trainingExtraKcal &&
          other.trainingExtraFrom == this.trainingExtraFrom);
}

class GoalsCompanion extends UpdateCompanion<GoalsRow> {
  final Value<int> id;
  final Value<double> kcal;
  final Value<double> protein;
  final Value<double> fat;
  final Value<double> carbs;
  final Value<double> trainingExtraKcal;
  final Value<String> trainingExtraFrom;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.kcal = const Value.absent(),
    this.protein = const Value.absent(),
    this.fat = const Value.absent(),
    this.carbs = const Value.absent(),
    this.trainingExtraKcal = const Value.absent(),
    this.trainingExtraFrom = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required double kcal,
    required double protein,
    required double fat,
    required double carbs,
    required double trainingExtraKcal,
    required String trainingExtraFrom,
  }) : kcal = Value(kcal),
       protein = Value(protein),
       fat = Value(fat),
       carbs = Value(carbs),
       trainingExtraKcal = Value(trainingExtraKcal),
       trainingExtraFrom = Value(trainingExtraFrom);
  static Insertable<GoalsRow> custom({
    Expression<int>? id,
    Expression<double>? kcal,
    Expression<double>? protein,
    Expression<double>? fat,
    Expression<double>? carbs,
    Expression<double>? trainingExtraKcal,
    Expression<String>? trainingExtraFrom,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kcal != null) 'kcal': kcal,
      if (protein != null) 'protein': protein,
      if (fat != null) 'fat': fat,
      if (carbs != null) 'carbs': carbs,
      if (trainingExtraKcal != null) 'training_extra_kcal': trainingExtraKcal,
      if (trainingExtraFrom != null) 'training_extra_from': trainingExtraFrom,
    });
  }

  GoalsCompanion copyWith({
    Value<int>? id,
    Value<double>? kcal,
    Value<double>? protein,
    Value<double>? fat,
    Value<double>? carbs,
    Value<double>? trainingExtraKcal,
    Value<String>? trainingExtraFrom,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      trainingExtraKcal: trainingExtraKcal ?? this.trainingExtraKcal,
      trainingExtraFrom: trainingExtraFrom ?? this.trainingExtraFrom,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<double>(carbs.value);
    }
    if (trainingExtraKcal.present) {
      map['training_extra_kcal'] = Variable<double>(trainingExtraKcal.value);
    }
    if (trainingExtraFrom.present) {
      map['training_extra_from'] = Variable<String>(trainingExtraFrom.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('fat: $fat, ')
          ..write('carbs: $carbs, ')
          ..write('trainingExtraKcal: $trainingExtraKcal, ')
          ..write('trainingExtraFrom: $trainingExtraFrom')
          ..write(')'))
        .toString();
  }
}

class $MealSlotsTable extends MealSlots
    with TableInfo<$MealSlotsTable, MealSlotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prepMeta = const VerificationMeta('prep');
  @override
  late final GeneratedColumn<bool> prep = GeneratedColumn<bool>(
    'prep',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("prep" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, position, prep];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealSlotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('prep')) {
      context.handle(
        _prepMeta,
        prep.isAcceptableOrUnknown(data['prep']!, _prepMeta),
      );
    } else if (isInserting) {
      context.missing(_prepMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealSlotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealSlotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      prep: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}prep'],
      )!,
    );
  }

  @override
  $MealSlotsTable createAlias(String alias) {
    return $MealSlotsTable(attachedDatabase, alias);
  }
}

class MealSlotRow extends DataClass implements Insertable<MealSlotRow> {
  final int id;
  final String name;
  final int position;
  final bool prep;
  const MealSlotRow({
    required this.id,
    required this.name,
    required this.position,
    required this.prep,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['prep'] = Variable<bool>(prep);
    return map;
  }

  MealSlotsCompanion toCompanion(bool nullToAbsent) {
    return MealSlotsCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
      prep: Value(prep),
    );
  }

  factory MealSlotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealSlotRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      prep: serializer.fromJson<bool>(json['prep']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'prep': serializer.toJson<bool>(prep),
    };
  }

  MealSlotRow copyWith({int? id, String? name, int? position, bool? prep}) =>
      MealSlotRow(
        id: id ?? this.id,
        name: name ?? this.name,
        position: position ?? this.position,
        prep: prep ?? this.prep,
      );
  MealSlotRow copyWithCompanion(MealSlotsCompanion data) {
    return MealSlotRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      prep: data.prep.present ? data.prep.value : this.prep,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealSlotRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('prep: $prep')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, position, prep);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealSlotRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position &&
          other.prep == this.prep);
}

class MealSlotsCompanion extends UpdateCompanion<MealSlotRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> position;
  final Value<bool> prep;
  const MealSlotsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.prep = const Value.absent(),
  });
  MealSlotsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int position,
    required bool prep,
  }) : name = Value(name),
       position = Value(position),
       prep = Value(prep);
  static Insertable<MealSlotRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<bool>? prep,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (prep != null) 'prep': prep,
    });
  }

  MealSlotsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? position,
    Value<bool>? prep,
  }) {
    return MealSlotsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      prep: prep ?? this.prep,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (prep.present) {
      map['prep'] = Variable<bool>(prep.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealSlotsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('prep: $prep')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstDayMeta = const VerificationMeta(
    'firstDay',
  );
  @override
  late final GeneratedColumn<DateTime> firstDay = GeneratedColumn<DateTime>(
    'first_day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedMsMeta = const VerificationMeta(
    'updatedMs',
  );
  @override
  late final GeneratedColumn<int> updatedMs = GeneratedColumn<int>(
    'updated_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    firstDay,
    data,
    updatedMs,
    deleted,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('first_day')) {
      context.handle(
        _firstDayMeta,
        firstDay.isAcceptableOrUnknown(data['first_day']!, _firstDayMeta),
      );
    } else if (isInserting) {
      context.missing(_firstDayMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('updated_ms')) {
      context.handle(
        _updatedMsMeta,
        updatedMs.isAcceptableOrUnknown(data['updated_ms']!, _updatedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMsMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      firstDay: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_day'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      updatedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_ms'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;
  final String uuid;
  final DateTime firstDay;
  final String data;

  /// Czas ostatniej zmiany, milisekundy UTC (do scalania przy synchronizacji).
  final int updatedMs;

  /// „Nagrobek": sesja usunięta, ale wiersz zostaje, żeby drugie urządzenie
  /// dowiedziało się o usunięciu.
  final bool deleted;

  /// Zmiana jeszcze niewysłana do Supabase.
  final bool dirty;
  const SessionRow({
    required this.id,
    required this.uuid,
    required this.firstDay,
    required this.data,
    required this.updatedMs,
    required this.deleted,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['first_day'] = Variable<DateTime>(firstDay);
    map['data'] = Variable<String>(data);
    map['updated_ms'] = Variable<int>(updatedMs);
    map['deleted'] = Variable<bool>(deleted);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      firstDay: Value(firstDay),
      data: Value(data),
      updatedMs: Value(updatedMs),
      deleted: Value(deleted),
      dirty: Value(dirty),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      firstDay: serializer.fromJson<DateTime>(json['firstDay']),
      data: serializer.fromJson<String>(json['data']),
      updatedMs: serializer.fromJson<int>(json['updatedMs']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'firstDay': serializer.toJson<DateTime>(firstDay),
      'data': serializer.toJson<String>(data),
      'updatedMs': serializer.toJson<int>(updatedMs),
      'deleted': serializer.toJson<bool>(deleted),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  SessionRow copyWith({
    int? id,
    String? uuid,
    DateTime? firstDay,
    String? data,
    int? updatedMs,
    bool? deleted,
    bool? dirty,
  }) => SessionRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    firstDay: firstDay ?? this.firstDay,
    data: data ?? this.data,
    updatedMs: updatedMs ?? this.updatedMs,
    deleted: deleted ?? this.deleted,
    dirty: dirty ?? this.dirty,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      firstDay: data.firstDay.present ? data.firstDay.value : this.firstDay,
      data: data.data.present ? data.data.value : this.data,
      updatedMs: data.updatedMs.present ? data.updatedMs.value : this.updatedMs,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('firstDay: $firstDay, ')
          ..write('data: $data, ')
          ..write('updatedMs: $updatedMs, ')
          ..write('deleted: $deleted, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uuid, firstDay, data, updatedMs, deleted, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.firstDay == this.firstDay &&
          other.data == this.data &&
          other.updatedMs == this.updatedMs &&
          other.deleted == this.deleted &&
          other.dirty == this.dirty);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<DateTime> firstDay;
  final Value<String> data;
  final Value<int> updatedMs;
  final Value<bool> deleted;
  final Value<bool> dirty;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.firstDay = const Value.absent(),
    this.data = const Value.absent(),
    this.updatedMs = const Value.absent(),
    this.deleted = const Value.absent(),
    this.dirty = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required DateTime firstDay,
    required String data,
    required int updatedMs,
    this.deleted = const Value.absent(),
    this.dirty = const Value.absent(),
  }) : uuid = Value(uuid),
       firstDay = Value(firstDay),
       data = Value(data),
       updatedMs = Value(updatedMs);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<DateTime>? firstDay,
    Expression<String>? data,
    Expression<int>? updatedMs,
    Expression<bool>? deleted,
    Expression<bool>? dirty,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (firstDay != null) 'first_day': firstDay,
      if (data != null) 'data': data,
      if (updatedMs != null) 'updated_ms': updatedMs,
      if (deleted != null) 'deleted': deleted,
      if (dirty != null) 'dirty': dirty,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<DateTime>? firstDay,
    Value<String>? data,
    Value<int>? updatedMs,
    Value<bool>? deleted,
    Value<bool>? dirty,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      firstDay: firstDay ?? this.firstDay,
      data: data ?? this.data,
      updatedMs: updatedMs ?? this.updatedMs,
      deleted: deleted ?? this.deleted,
      dirty: dirty ?? this.dirty,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (firstDay.present) {
      map['first_day'] = Variable<DateTime>(firstDay.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (updatedMs.present) {
      map['updated_ms'] = Variable<int>(updatedMs.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('firstDay: $firstDay, ')
          ..write('data: $data, ')
          ..write('updatedMs: $updatedMs, ')
          ..write('deleted: $deleted, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }
}

class $ShoppingChecksTable extends ShoppingChecks
    with TableInfo<$ShoppingChecksTable, ShoppingCheckRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingChecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkedMeta = const VerificationMeta(
    'checked',
  );
  @override
  late final GeneratedColumn<bool> checked = GeneratedColumn<bool>(
    'checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("checked" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedMsMeta = const VerificationMeta(
    'updatedMs',
  );
  @override
  late final GeneratedColumn<int> updatedMs = GeneratedColumn<int>(
    'updated_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    productId,
    checked,
    updatedMs,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_checks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingCheckRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('checked')) {
      context.handle(
        _checkedMeta,
        checked.isAcceptableOrUnknown(data['checked']!, _checkedMeta),
      );
    }
    if (data.containsKey('updated_ms')) {
      context.handle(
        _updatedMsMeta,
        updatedMs.isAcceptableOrUnknown(data['updated_ms']!, _updatedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMsMeta);
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, productId};
  @override
  ShoppingCheckRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingCheckRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      checked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}checked'],
      )!,
      updatedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_ms'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $ShoppingChecksTable createAlias(String alias) {
    return $ShoppingChecksTable(attachedDatabase, alias);
  }
}

class ShoppingCheckRow extends DataClass
    implements Insertable<ShoppingCheckRow> {
  final int sessionId;
  final String productId;
  final bool checked;
  final int updatedMs;
  final bool dirty;
  const ShoppingCheckRow({
    required this.sessionId,
    required this.productId,
    required this.checked,
    required this.updatedMs,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['product_id'] = Variable<String>(productId);
    map['checked'] = Variable<bool>(checked);
    map['updated_ms'] = Variable<int>(updatedMs);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  ShoppingChecksCompanion toCompanion(bool nullToAbsent) {
    return ShoppingChecksCompanion(
      sessionId: Value(sessionId),
      productId: Value(productId),
      checked: Value(checked),
      updatedMs: Value(updatedMs),
      dirty: Value(dirty),
    );
  }

  factory ShoppingCheckRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingCheckRow(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      productId: serializer.fromJson<String>(json['productId']),
      checked: serializer.fromJson<bool>(json['checked']),
      updatedMs: serializer.fromJson<int>(json['updatedMs']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'productId': serializer.toJson<String>(productId),
      'checked': serializer.toJson<bool>(checked),
      'updatedMs': serializer.toJson<int>(updatedMs),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  ShoppingCheckRow copyWith({
    int? sessionId,
    String? productId,
    bool? checked,
    int? updatedMs,
    bool? dirty,
  }) => ShoppingCheckRow(
    sessionId: sessionId ?? this.sessionId,
    productId: productId ?? this.productId,
    checked: checked ?? this.checked,
    updatedMs: updatedMs ?? this.updatedMs,
    dirty: dirty ?? this.dirty,
  );
  ShoppingCheckRow copyWithCompanion(ShoppingChecksCompanion data) {
    return ShoppingCheckRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      productId: data.productId.present ? data.productId.value : this.productId,
      checked: data.checked.present ? data.checked.value : this.checked,
      updatedMs: data.updatedMs.present ? data.updatedMs.value : this.updatedMs,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingCheckRow(')
          ..write('sessionId: $sessionId, ')
          ..write('productId: $productId, ')
          ..write('checked: $checked, ')
          ..write('updatedMs: $updatedMs, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sessionId, productId, checked, updatedMs, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingCheckRow &&
          other.sessionId == this.sessionId &&
          other.productId == this.productId &&
          other.checked == this.checked &&
          other.updatedMs == this.updatedMs &&
          other.dirty == this.dirty);
}

class ShoppingChecksCompanion extends UpdateCompanion<ShoppingCheckRow> {
  final Value<int> sessionId;
  final Value<String> productId;
  final Value<bool> checked;
  final Value<int> updatedMs;
  final Value<bool> dirty;
  final Value<int> rowid;
  const ShoppingChecksCompanion({
    this.sessionId = const Value.absent(),
    this.productId = const Value.absent(),
    this.checked = const Value.absent(),
    this.updatedMs = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingChecksCompanion.insert({
    required int sessionId,
    required String productId,
    this.checked = const Value.absent(),
    required int updatedMs,
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       productId = Value(productId),
       updatedMs = Value(updatedMs);
  static Insertable<ShoppingCheckRow> custom({
    Expression<int>? sessionId,
    Expression<String>? productId,
    Expression<bool>? checked,
    Expression<int>? updatedMs,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (productId != null) 'product_id': productId,
      if (checked != null) 'checked': checked,
      if (updatedMs != null) 'updated_ms': updatedMs,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingChecksCompanion copyWith({
    Value<int>? sessionId,
    Value<String>? productId,
    Value<bool>? checked,
    Value<int>? updatedMs,
    Value<bool>? dirty,
    Value<int>? rowid,
  }) {
    return ShoppingChecksCompanion(
      sessionId: sessionId ?? this.sessionId,
      productId: productId ?? this.productId,
      checked: checked ?? this.checked,
      updatedMs: updatedMs ?? this.updatedMs,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (checked.present) {
      map['checked'] = Variable<bool>(checked.value);
    }
    if (updatedMs.present) {
      map['updated_ms'] = Variable<int>(updatedMs.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingChecksCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('productId: $productId, ')
          ..write('checked: $checked, ')
          ..write('updatedMs: $updatedMs, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaRow> instance, {
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
  SyncMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaRow(
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
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaRow extends DataClass implements Insertable<SyncMetaRow> {
  final String key;
  final String value;
  const SyncMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(key: Value(key), value: Value(value));
  }

  factory SyncMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaRow(
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

  SyncMetaRow copyWith({String? key, String? value}) =>
      SyncMetaRow(key: key ?? this.key, value: value ?? this.value);
  SyncMetaRow copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaRow(')
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
      (other is SyncMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetaRow> custom({
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

  SyncMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
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
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $MealSlotsTable mealSlots = $MealSlotsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $ShoppingChecksTable shoppingChecks = $ShoppingChecksTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final Index sessionsUuid = Index(
    'sessions_uuid',
    'CREATE UNIQUE INDEX sessions_uuid ON sessions (uuid)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    goals,
    mealSlots,
    sessions,
    shoppingChecks,
    syncMeta,
    sessionsUuid,
  ];
}

typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  required double kcal,
  required double protein,
  required double fat,
  required double carbs,
  required double trainingExtraKcal,
  required String trainingExtraFrom,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  Value<double> kcal,
  Value<double> protein,
  Value<double> fat,
  Value<double> carbs,
  Value<double> trainingExtraKcal,
  Value<String> trainingExtraFrom,
});

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get trainingExtraKcal => $composableBuilder(
    column: $table.trainingExtraKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trainingExtraFrom => $composableBuilder(
    column: $table.trainingExtraFrom,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get trainingExtraKcal => $composableBuilder(
    column: $table.trainingExtraKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trainingExtraFrom => $composableBuilder(
    column: $table.trainingExtraFrom,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<double> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<double> get trainingExtraKcal => $composableBuilder(
    column: $table.trainingExtraKcal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trainingExtraFrom => $composableBuilder(
    column: $table.trainingExtraFrom,
    builder: (column) => column,
  );
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          GoalsRow,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (GoalsRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalsRow>),
          GoalsRow,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<double> carbs = const Value.absent(),
                Value<double> trainingExtraKcal = const Value.absent(),
                Value<String> trainingExtraFrom = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                kcal: kcal,
                protein: protein,
                fat: fat,
                carbs: carbs,
                trainingExtraKcal: trainingExtraKcal,
                trainingExtraFrom: trainingExtraFrom,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double kcal,
                required double protein,
                required double fat,
                required double carbs,
                required double trainingExtraKcal,
                required String trainingExtraFrom,
              }) => GoalsCompanion.insert(
                id: id,
                kcal: kcal,
                protein: protein,
                fat: fat,
                carbs: carbs,
                trainingExtraKcal: trainingExtraKcal,
                trainingExtraFrom: trainingExtraFrom,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalsTable, GoalsRow>(table),
                  BaseReferences<_$AppDatabase, $GoalsTable, GoalsRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      GoalsRow,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (GoalsRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalsRow>),
      GoalsRow,
      PrefetchHooks Function()
    >;
typedef $$MealSlotsTableCreateCompanionBuilder = MealSlotsCompanion Function({
  Value<int> id,
  required String name,
  required int position,
  required bool prep,
});
typedef $$MealSlotsTableUpdateCompanionBuilder = MealSlotsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> position,
  Value<bool> prep,
});

class $$MealSlotsTableFilterComposer
    extends Composer<_$AppDatabase, $MealSlotsTable> {
  $$MealSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get prep => $composableBuilder(
    column: $table.prep,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealSlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealSlotsTable> {
  $$MealSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get prep => $composableBuilder(
    column: $table.prep,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealSlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealSlotsTable> {
  $$MealSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get prep =>
      $composableBuilder(column: $table.prep, builder: (column) => column);
}

class $$MealSlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealSlotsTable,
          MealSlotRow,
          $$MealSlotsTableFilterComposer,
          $$MealSlotsTableOrderingComposer,
          $$MealSlotsTableAnnotationComposer,
          $$MealSlotsTableCreateCompanionBuilder,
          $$MealSlotsTableUpdateCompanionBuilder,
          (
            MealSlotRow,
            BaseReferences<_$AppDatabase, $MealSlotsTable, MealSlotRow>,
          ),
          MealSlotRow,
          PrefetchHooks Function()
        > {
  $$MealSlotsTableTableManager(_$AppDatabase db, $MealSlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> prep = const Value.absent(),
              }) => MealSlotsCompanion(
                id: id,
                name: name,
                position: position,
                prep: prep,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int position,
                required bool prep,
              }) => MealSlotsCompanion.insert(
                id: id,
                name: name,
                position: position,
                prep: prep,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealSlotsTable, MealSlotRow>(table),
                  BaseReferences<_$AppDatabase, $MealSlotsTable, MealSlotRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealSlotsTable,
      MealSlotRow,
      $$MealSlotsTableFilterComposer,
      $$MealSlotsTableOrderingComposer,
      $$MealSlotsTableAnnotationComposer,
      $$MealSlotsTableCreateCompanionBuilder,
      $$MealSlotsTableUpdateCompanionBuilder,
      (
        MealSlotRow,
        BaseReferences<_$AppDatabase, $MealSlotsTable, MealSlotRow>,
      ),
      MealSlotRow,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required String uuid,
  required DateTime firstDay,
  required String data,
  required int updatedMs,
  Value<bool> deleted,
  Value<bool> dirty,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<DateTime> firstDay,
  Value<String> data,
  Value<int> updatedMs,
  Value<bool> deleted,
  Value<bool> dirty,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstDay => $composableBuilder(
    column: $table.firstDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedMs => $composableBuilder(
    column: $table.updatedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstDay => $composableBuilder(
    column: $table.firstDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedMs => $composableBuilder(
    column: $table.updatedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<DateTime> get firstDay =>
      $composableBuilder(column: $table.firstDay, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get updatedMs =>
      $composableBuilder(column: $table.updatedMs, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (
            SessionRow,
            BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>,
          ),
          SessionRow,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<DateTime> firstDay = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> updatedMs = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                uuid: uuid,
                firstDay: firstDay,
                data: data,
                updatedMs: updatedMs,
                deleted: deleted,
                dirty: dirty,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required DateTime firstDay,
                required String data,
                required int updatedMs,
                Value<bool> deleted = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                uuid: uuid,
                firstDay: firstDay,
                data: data,
                updatedMs: updatedMs,
                deleted: deleted,
                dirty: dirty,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, SessionRow>(table),
                  BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>),
      SessionRow,
      PrefetchHooks Function()
    >;
typedef $$ShoppingChecksTableCreateCompanionBuilder =
    ShoppingChecksCompanion Function({
      required int sessionId,
      required String productId,
      Value<bool> checked,
      required int updatedMs,
      Value<bool> dirty,
      Value<int> rowid,
    });
typedef $$ShoppingChecksTableUpdateCompanionBuilder =
    ShoppingChecksCompanion Function({
      Value<int> sessionId,
      Value<String> productId,
      Value<bool> checked,
      Value<int> updatedMs,
      Value<bool> dirty,
      Value<int> rowid,
    });

class $$ShoppingChecksTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingChecksTable> {
  $$ShoppingChecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedMs => $composableBuilder(
    column: $table.updatedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShoppingChecksTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingChecksTable> {
  $$ShoppingChecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedMs => $composableBuilder(
    column: $table.updatedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingChecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingChecksTable> {
  $$ShoppingChecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<bool> get checked =>
      $composableBuilder(column: $table.checked, builder: (column) => column);

  GeneratedColumn<int> get updatedMs =>
      $composableBuilder(column: $table.updatedMs, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$ShoppingChecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingChecksTable,
          ShoppingCheckRow,
          $$ShoppingChecksTableFilterComposer,
          $$ShoppingChecksTableOrderingComposer,
          $$ShoppingChecksTableAnnotationComposer,
          $$ShoppingChecksTableCreateCompanionBuilder,
          $$ShoppingChecksTableUpdateCompanionBuilder,
          (
            ShoppingCheckRow,
            BaseReferences<
              _$AppDatabase,
              $ShoppingChecksTable,
              ShoppingCheckRow
            >,
          ),
          ShoppingCheckRow,
          PrefetchHooks Function()
        > {
  $$ShoppingChecksTableTableManager(
    _$AppDatabase db,
    $ShoppingChecksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingChecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingChecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingChecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sessionId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<bool> checked = const Value.absent(),
                Value<int> updatedMs = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingChecksCompanion(
                sessionId: sessionId,
                productId: productId,
                checked: checked,
                updatedMs: updatedMs,
                dirty: dirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sessionId,
                required String productId,
                Value<bool> checked = const Value.absent(),
                required int updatedMs,
                Value<bool> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingChecksCompanion.insert(
                sessionId: sessionId,
                productId: productId,
                checked: checked,
                updatedMs: updatedMs,
                dirty: dirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShoppingChecksTable, ShoppingCheckRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ShoppingChecksTable,
                    ShoppingCheckRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoppingChecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingChecksTable,
      ShoppingCheckRow,
      $$ShoppingChecksTableFilterComposer,
      $$ShoppingChecksTableOrderingComposer,
      $$ShoppingChecksTableAnnotationComposer,
      $$ShoppingChecksTableCreateCompanionBuilder,
      $$ShoppingChecksTableUpdateCompanionBuilder,
      (
        ShoppingCheckRow,
        BaseReferences<_$AppDatabase, $ShoppingChecksTable, ShoppingCheckRow>,
      ),
      ShoppingCheckRow,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
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

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
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

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
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

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaRow,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaRow,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>,
          ),
          SyncMetaRow,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SyncMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMetaTable, SyncMetaRow>(table),
                  BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaRow,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (SyncMetaRow, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>),
      SyncMetaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$MealSlotsTableTableManager get mealSlots =>
      $$MealSlotsTableTableManager(_db, _db.mealSlots);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$ShoppingChecksTableTableManager get shoppingChecks =>
      $$ShoppingChecksTableTableManager(_db, _db.shoppingChecks);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}
