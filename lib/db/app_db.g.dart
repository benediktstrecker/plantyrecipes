// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $MonthsTable extends Months with TableInfo<$MonthsTable, Month> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'months';
  @override
  VerificationContext validateIntegrity(Insertable<Month> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Month map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Month(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $MonthsTable createAlias(String alias) {
    return $MonthsTable(attachedDatabase, alias);
  }
}

class Month extends DataClass implements Insertable<Month> {
  final int id;
  final String name;
  const Month({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  MonthsCompanion toCompanion(bool nullToAbsent) {
    return MonthsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory Month.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Month(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Month copyWith({int? id, String? name}) => Month(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  Month copyWithCompanion(MonthsCompanion data) {
    return Month(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Month(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Month && other.id == this.id && other.name == this.name);
}

class MonthsCompanion extends UpdateCompanion<Month> {
  final Value<int> id;
  final Value<String> name;
  const MonthsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  MonthsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<Month> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  MonthsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return MonthsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, Unit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dimensionMeta =
      const VerificationMeta('dimension');
  @override
  late final GeneratedColumn<String> dimension = GeneratedColumn<String>(
      'dimension', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _baseFactorMeta =
      const VerificationMeta('baseFactor');
  @override
  late final GeneratedColumn<double> baseFactor = GeneratedColumn<double>(
      'base_factor', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, code, label, dimension, baseFactor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units';
  @override
  VerificationContext validateIntegrity(Insertable<Unit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('dimension')) {
      context.handle(_dimensionMeta,
          dimension.isAcceptableOrUnknown(data['dimension']!, _dimensionMeta));
    } else if (isInserting) {
      context.missing(_dimensionMeta);
    }
    if (data.containsKey('base_factor')) {
      context.handle(
          _baseFactorMeta,
          baseFactor.isAcceptableOrUnknown(
              data['base_factor']!, _baseFactorMeta));
    } else if (isInserting) {
      context.missing(_baseFactorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Unit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Unit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      dimension: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dimension'])!,
      baseFactor: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}base_factor'])!,
    );
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(attachedDatabase, alias);
  }
}

class Unit extends DataClass implements Insertable<Unit> {
  final int id;
  final String code;
  final String label;
  final String dimension;
  final double baseFactor;
  const Unit(
      {required this.id,
      required this.code,
      required this.label,
      required this.dimension,
      required this.baseFactor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['label'] = Variable<String>(label);
    map['dimension'] = Variable<String>(dimension);
    map['base_factor'] = Variable<double>(baseFactor);
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      code: Value(code),
      label: Value(label),
      dimension: Value(dimension),
      baseFactor: Value(baseFactor),
    );
  }

  factory Unit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Unit(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      label: serializer.fromJson<String>(json['label']),
      dimension: serializer.fromJson<String>(json['dimension']),
      baseFactor: serializer.fromJson<double>(json['baseFactor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'label': serializer.toJson<String>(label),
      'dimension': serializer.toJson<String>(dimension),
      'baseFactor': serializer.toJson<double>(baseFactor),
    };
  }

  Unit copyWith(
          {int? id,
          String? code,
          String? label,
          String? dimension,
          double? baseFactor}) =>
      Unit(
        id: id ?? this.id,
        code: code ?? this.code,
        label: label ?? this.label,
        dimension: dimension ?? this.dimension,
        baseFactor: baseFactor ?? this.baseFactor,
      );
  Unit copyWithCompanion(UnitsCompanion data) {
    return Unit(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      label: data.label.present ? data.label.value : this.label,
      dimension: data.dimension.present ? data.dimension.value : this.dimension,
      baseFactor:
          data.baseFactor.present ? data.baseFactor.value : this.baseFactor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Unit(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('label: $label, ')
          ..write('dimension: $dimension, ')
          ..write('baseFactor: $baseFactor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, label, dimension, baseFactor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Unit &&
          other.id == this.id &&
          other.code == this.code &&
          other.label == this.label &&
          other.dimension == this.dimension &&
          other.baseFactor == this.baseFactor);
}

class UnitsCompanion extends UpdateCompanion<Unit> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> label;
  final Value<String> dimension;
  final Value<double> baseFactor;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.label = const Value.absent(),
    this.dimension = const Value.absent(),
    this.baseFactor = const Value.absent(),
  });
  UnitsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String label,
    required String dimension,
    required double baseFactor,
  })  : code = Value(code),
        label = Value(label),
        dimension = Value(dimension),
        baseFactor = Value(baseFactor);
  static Insertable<Unit> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? label,
    Expression<String>? dimension,
    Expression<double>? baseFactor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (label != null) 'label': label,
      if (dimension != null) 'dimension': dimension,
      if (baseFactor != null) 'base_factor': baseFactor,
    });
  }

  UnitsCompanion copyWith(
      {Value<int>? id,
      Value<String>? code,
      Value<String>? label,
      Value<String>? dimension,
      Value<double>? baseFactor}) {
    return UnitsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      label: label ?? this.label,
      dimension: dimension ?? this.dimension,
      baseFactor: baseFactor ?? this.baseFactor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (dimension.present) {
      map['dimension'] = Variable<String>(dimension.value);
    }
    if (baseFactor.present) {
      map['base_factor'] = Variable<double>(baseFactor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('label: $label, ')
          ..write('dimension: $dimension, ')
          ..write('baseFactor: $baseFactor')
          ..write(')'))
        .toString();
  }
}

class $UnitConversionsTable extends UnitConversions
    with TableInfo<$UnitConversionsTable, UnitConversion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitConversionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fromUnitIdMeta =
      const VerificationMeta('fromUnitId');
  @override
  late final GeneratedColumn<int> fromUnitId = GeneratedColumn<int>(
      'from_unit_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES units (id)'));
  static const VerificationMeta _toUnitIdMeta =
      const VerificationMeta('toUnitId');
  @override
  late final GeneratedColumn<int> toUnitId = GeneratedColumn<int>(
      'to_unit_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES units (id)'));
  static const VerificationMeta _factorMeta = const VerificationMeta('factor');
  @override
  late final GeneratedColumn<double> factor = GeneratedColumn<double>(
      'factor', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [fromUnitId, toUnitId, factor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unit_conversions';
  @override
  VerificationContext validateIntegrity(Insertable<UnitConversion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('from_unit_id')) {
      context.handle(
          _fromUnitIdMeta,
          fromUnitId.isAcceptableOrUnknown(
              data['from_unit_id']!, _fromUnitIdMeta));
    } else if (isInserting) {
      context.missing(_fromUnitIdMeta);
    }
    if (data.containsKey('to_unit_id')) {
      context.handle(_toUnitIdMeta,
          toUnitId.isAcceptableOrUnknown(data['to_unit_id']!, _toUnitIdMeta));
    } else if (isInserting) {
      context.missing(_toUnitIdMeta);
    }
    if (data.containsKey('factor')) {
      context.handle(_factorMeta,
          factor.isAcceptableOrUnknown(data['factor']!, _factorMeta));
    } else if (isInserting) {
      context.missing(_factorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fromUnitId, toUnitId};
  @override
  UnitConversion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnitConversion(
      fromUnitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_unit_id'])!,
      toUnitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_unit_id'])!,
      factor: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}factor'])!,
    );
  }

  @override
  $UnitConversionsTable createAlias(String alias) {
    return $UnitConversionsTable(attachedDatabase, alias);
  }
}

class UnitConversion extends DataClass implements Insertable<UnitConversion> {
  final int fromUnitId;
  final int toUnitId;
  final double factor;
  const UnitConversion(
      {required this.fromUnitId, required this.toUnitId, required this.factor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['from_unit_id'] = Variable<int>(fromUnitId);
    map['to_unit_id'] = Variable<int>(toUnitId);
    map['factor'] = Variable<double>(factor);
    return map;
  }

  UnitConversionsCompanion toCompanion(bool nullToAbsent) {
    return UnitConversionsCompanion(
      fromUnitId: Value(fromUnitId),
      toUnitId: Value(toUnitId),
      factor: Value(factor),
    );
  }

  factory UnitConversion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnitConversion(
      fromUnitId: serializer.fromJson<int>(json['fromUnitId']),
      toUnitId: serializer.fromJson<int>(json['toUnitId']),
      factor: serializer.fromJson<double>(json['factor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fromUnitId': serializer.toJson<int>(fromUnitId),
      'toUnitId': serializer.toJson<int>(toUnitId),
      'factor': serializer.toJson<double>(factor),
    };
  }

  UnitConversion copyWith({int? fromUnitId, int? toUnitId, double? factor}) =>
      UnitConversion(
        fromUnitId: fromUnitId ?? this.fromUnitId,
        toUnitId: toUnitId ?? this.toUnitId,
        factor: factor ?? this.factor,
      );
  UnitConversion copyWithCompanion(UnitConversionsCompanion data) {
    return UnitConversion(
      fromUnitId:
          data.fromUnitId.present ? data.fromUnitId.value : this.fromUnitId,
      toUnitId: data.toUnitId.present ? data.toUnitId.value : this.toUnitId,
      factor: data.factor.present ? data.factor.value : this.factor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnitConversion(')
          ..write('fromUnitId: $fromUnitId, ')
          ..write('toUnitId: $toUnitId, ')
          ..write('factor: $factor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fromUnitId, toUnitId, factor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnitConversion &&
          other.fromUnitId == this.fromUnitId &&
          other.toUnitId == this.toUnitId &&
          other.factor == this.factor);
}

class UnitConversionsCompanion extends UpdateCompanion<UnitConversion> {
  final Value<int> fromUnitId;
  final Value<int> toUnitId;
  final Value<double> factor;
  final Value<int> rowid;
  const UnitConversionsCompanion({
    this.fromUnitId = const Value.absent(),
    this.toUnitId = const Value.absent(),
    this.factor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitConversionsCompanion.insert({
    required int fromUnitId,
    required int toUnitId,
    required double factor,
    this.rowid = const Value.absent(),
  })  : fromUnitId = Value(fromUnitId),
        toUnitId = Value(toUnitId),
        factor = Value(factor);
  static Insertable<UnitConversion> custom({
    Expression<int>? fromUnitId,
    Expression<int>? toUnitId,
    Expression<double>? factor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fromUnitId != null) 'from_unit_id': fromUnitId,
      if (toUnitId != null) 'to_unit_id': toUnitId,
      if (factor != null) 'factor': factor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitConversionsCompanion copyWith(
      {Value<int>? fromUnitId,
      Value<int>? toUnitId,
      Value<double>? factor,
      Value<int>? rowid}) {
    return UnitConversionsCompanion(
      fromUnitId: fromUnitId ?? this.fromUnitId,
      toUnitId: toUnitId ?? this.toUnitId,
      factor: factor ?? this.factor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fromUnitId.present) {
      map['from_unit_id'] = Variable<int>(fromUnitId.value);
    }
    if (toUnitId.present) {
      map['to_unit_id'] = Variable<int>(toUnitId.value);
    }
    if (factor.present) {
      map['factor'] = Variable<double>(factor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitConversionsCompanion(')
          ..write('fromUnitId: $fromUnitId, ')
          ..write('toUnitId: $toUnitId, ')
          ..write('factor: $factor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngredientUnitOverridesTable extends IngredientUnitOverrides
    with TableInfo<$IngredientUnitOverridesTable, IngredientUnitOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientUnitOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ingredientIdMeta =
      const VerificationMeta('ingredientId');
  @override
  late final GeneratedColumn<int> ingredientId = GeneratedColumn<int>(
      'ingredient_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<int> unitId = GeneratedColumn<int>(
      'unit_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES units (id)'));
  static const VerificationMeta _gramsPerUnitMeta =
      const VerificationMeta('gramsPerUnit');
  @override
  late final GeneratedColumn<double> gramsPerUnit = GeneratedColumn<double>(
      'grams_per_unit', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _mlPerUnitMeta =
      const VerificationMeta('mlPerUnit');
  @override
  late final GeneratedColumn<double> mlPerUnit = GeneratedColumn<double>(
      'ml_per_unit', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [ingredientId, unitId, gramsPerUnit, mlPerUnit];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_unit_overrides';
  @override
  VerificationContext validateIntegrity(
      Insertable<IngredientUnitOverride> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ingredient_id')) {
      context.handle(
          _ingredientIdMeta,
          ingredientId.isAcceptableOrUnknown(
              data['ingredient_id']!, _ingredientIdMeta));
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('grams_per_unit')) {
      context.handle(
          _gramsPerUnitMeta,
          gramsPerUnit.isAcceptableOrUnknown(
              data['grams_per_unit']!, _gramsPerUnitMeta));
    }
    if (data.containsKey('ml_per_unit')) {
      context.handle(
          _mlPerUnitMeta,
          mlPerUnit.isAcceptableOrUnknown(
              data['ml_per_unit']!, _mlPerUnitMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ingredientId, unitId};
  @override
  IngredientUnitOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientUnitOverride(
      ingredientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ingredient_id'])!,
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_id'])!,
      gramsPerUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}grams_per_unit']),
      mlPerUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ml_per_unit']),
    );
  }

  @override
  $IngredientUnitOverridesTable createAlias(String alias) {
    return $IngredientUnitOverridesTable(attachedDatabase, alias);
  }
}

class IngredientUnitOverride extends DataClass
    implements Insertable<IngredientUnitOverride> {
  final int ingredientId;
  final int unitId;
  final double? gramsPerUnit;
  final double? mlPerUnit;
  const IngredientUnitOverride(
      {required this.ingredientId,
      required this.unitId,
      this.gramsPerUnit,
      this.mlPerUnit});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ingredient_id'] = Variable<int>(ingredientId);
    map['unit_id'] = Variable<int>(unitId);
    if (!nullToAbsent || gramsPerUnit != null) {
      map['grams_per_unit'] = Variable<double>(gramsPerUnit);
    }
    if (!nullToAbsent || mlPerUnit != null) {
      map['ml_per_unit'] = Variable<double>(mlPerUnit);
    }
    return map;
  }

  IngredientUnitOverridesCompanion toCompanion(bool nullToAbsent) {
    return IngredientUnitOverridesCompanion(
      ingredientId: Value(ingredientId),
      unitId: Value(unitId),
      gramsPerUnit: gramsPerUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(gramsPerUnit),
      mlPerUnit: mlPerUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(mlPerUnit),
    );
  }

  factory IngredientUnitOverride.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientUnitOverride(
      ingredientId: serializer.fromJson<int>(json['ingredientId']),
      unitId: serializer.fromJson<int>(json['unitId']),
      gramsPerUnit: serializer.fromJson<double?>(json['gramsPerUnit']),
      mlPerUnit: serializer.fromJson<double?>(json['mlPerUnit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ingredientId': serializer.toJson<int>(ingredientId),
      'unitId': serializer.toJson<int>(unitId),
      'gramsPerUnit': serializer.toJson<double?>(gramsPerUnit),
      'mlPerUnit': serializer.toJson<double?>(mlPerUnit),
    };
  }

  IngredientUnitOverride copyWith(
          {int? ingredientId,
          int? unitId,
          Value<double?> gramsPerUnit = const Value.absent(),
          Value<double?> mlPerUnit = const Value.absent()}) =>
      IngredientUnitOverride(
        ingredientId: ingredientId ?? this.ingredientId,
        unitId: unitId ?? this.unitId,
        gramsPerUnit:
            gramsPerUnit.present ? gramsPerUnit.value : this.gramsPerUnit,
        mlPerUnit: mlPerUnit.present ? mlPerUnit.value : this.mlPerUnit,
      );
  IngredientUnitOverride copyWithCompanion(
      IngredientUnitOverridesCompanion data) {
    return IngredientUnitOverride(
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      gramsPerUnit: data.gramsPerUnit.present
          ? data.gramsPerUnit.value
          : this.gramsPerUnit,
      mlPerUnit: data.mlPerUnit.present ? data.mlPerUnit.value : this.mlPerUnit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientUnitOverride(')
          ..write('ingredientId: $ingredientId, ')
          ..write('unitId: $unitId, ')
          ..write('gramsPerUnit: $gramsPerUnit, ')
          ..write('mlPerUnit: $mlPerUnit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(ingredientId, unitId, gramsPerUnit, mlPerUnit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientUnitOverride &&
          other.ingredientId == this.ingredientId &&
          other.unitId == this.unitId &&
          other.gramsPerUnit == this.gramsPerUnit &&
          other.mlPerUnit == this.mlPerUnit);
}

class IngredientUnitOverridesCompanion
    extends UpdateCompanion<IngredientUnitOverride> {
  final Value<int> ingredientId;
  final Value<int> unitId;
  final Value<double?> gramsPerUnit;
  final Value<double?> mlPerUnit;
  final Value<int> rowid;
  const IngredientUnitOverridesCompanion({
    this.ingredientId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.gramsPerUnit = const Value.absent(),
    this.mlPerUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientUnitOverridesCompanion.insert({
    required int ingredientId,
    required int unitId,
    this.gramsPerUnit = const Value.absent(),
    this.mlPerUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : ingredientId = Value(ingredientId),
        unitId = Value(unitId);
  static Insertable<IngredientUnitOverride> custom({
    Expression<int>? ingredientId,
    Expression<int>? unitId,
    Expression<double>? gramsPerUnit,
    Expression<double>? mlPerUnit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (unitId != null) 'unit_id': unitId,
      if (gramsPerUnit != null) 'grams_per_unit': gramsPerUnit,
      if (mlPerUnit != null) 'ml_per_unit': mlPerUnit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientUnitOverridesCompanion copyWith(
      {Value<int>? ingredientId,
      Value<int>? unitId,
      Value<double?>? gramsPerUnit,
      Value<double?>? mlPerUnit,
      Value<int>? rowid}) {
    return IngredientUnitOverridesCompanion(
      ingredientId: ingredientId ?? this.ingredientId,
      unitId: unitId ?? this.unitId,
      gramsPerUnit: gramsPerUnit ?? this.gramsPerUnit,
      mlPerUnit: mlPerUnit ?? this.mlPerUnit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<int>(unitId.value);
    }
    if (gramsPerUnit.present) {
      map['grams_per_unit'] = Variable<double>(gramsPerUnit.value);
    }
    if (mlPerUnit.present) {
      map['ml_per_unit'] = Variable<double>(mlPerUnit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientUnitOverridesCompanion(')
          ..write('ingredientId: $ingredientId, ')
          ..write('unitId: $unitId, ')
          ..write('gramsPerUnit: $gramsPerUnit, ')
          ..write('mlPerUnit: $mlPerUnit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NutrientsCategorieTable extends NutrientsCategorie
    with TableInfo<$NutrientsCategorieTable, NutrientsCategorieData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutrientsCategorieTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitCodeMeta =
      const VerificationMeta('unitCode');
  @override
  late final GeneratedColumn<String> unitCode = GeneratedColumn<String>(
      'unit_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES units(code)');
  @override
  List<GeneratedColumn> get $columns => [id, name, unitCode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrients_categorie';
  @override
  VerificationContext validateIntegrity(
      Insertable<NutrientsCategorieData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit_code')) {
      context.handle(_unitCodeMeta,
          unitCode.isAcceptableOrUnknown(data['unit_code']!, _unitCodeMeta));
    } else if (isInserting) {
      context.missing(_unitCodeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NutrientsCategorieData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NutrientsCategorieData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      unitCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_code'])!,
    );
  }

  @override
  $NutrientsCategorieTable createAlias(String alias) {
    return $NutrientsCategorieTable(attachedDatabase, alias);
  }
}

class NutrientsCategorieData extends DataClass
    implements Insertable<NutrientsCategorieData> {
  final int id;
  final String name;
  final String unitCode;
  const NutrientsCategorieData(
      {required this.id, required this.name, required this.unitCode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['unit_code'] = Variable<String>(unitCode);
    return map;
  }

  NutrientsCategorieCompanion toCompanion(bool nullToAbsent) {
    return NutrientsCategorieCompanion(
      id: Value(id),
      name: Value(name),
      unitCode: Value(unitCode),
    );
  }

  factory NutrientsCategorieData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NutrientsCategorieData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      unitCode: serializer.fromJson<String>(json['unitCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'unitCode': serializer.toJson<String>(unitCode),
    };
  }

  NutrientsCategorieData copyWith({int? id, String? name, String? unitCode}) =>
      NutrientsCategorieData(
        id: id ?? this.id,
        name: name ?? this.name,
        unitCode: unitCode ?? this.unitCode,
      );
  NutrientsCategorieData copyWithCompanion(NutrientsCategorieCompanion data) {
    return NutrientsCategorieData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      unitCode: data.unitCode.present ? data.unitCode.value : this.unitCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NutrientsCategorieData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unitCode: $unitCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, unitCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutrientsCategorieData &&
          other.id == this.id &&
          other.name == this.name &&
          other.unitCode == this.unitCode);
}

class NutrientsCategorieCompanion
    extends UpdateCompanion<NutrientsCategorieData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> unitCode;
  const NutrientsCategorieCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.unitCode = const Value.absent(),
  });
  NutrientsCategorieCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String unitCode,
  })  : name = Value(name),
        unitCode = Value(unitCode);
  static Insertable<NutrientsCategorieData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? unitCode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (unitCode != null) 'unit_code': unitCode,
    });
  }

  NutrientsCategorieCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<String>? unitCode}) {
    return NutrientsCategorieCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      unitCode: unitCode ?? this.unitCode,
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
    if (unitCode.present) {
      map['unit_code'] = Variable<String>(unitCode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutrientsCategorieCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unitCode: $unitCode')
          ..write(')'))
        .toString();
  }
}

class $NutrientTable extends Nutrient
    with TableInfo<$NutrientTable, NutrientData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutrientTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nutrientsCategorieIdMeta =
      const VerificationMeta('nutrientsCategorieId');
  @override
  late final GeneratedColumn<int> nutrientsCategorieId = GeneratedColumn<int>(
      'nutrients_categorie_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES nutrients_categorie (id)'));
  static const VerificationMeta _unitCodeMeta =
      const VerificationMeta('unitCode');
  @override
  late final GeneratedColumn<String> unitCode = GeneratedColumn<String>(
      'unit_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES units(code)');
  static const VerificationMeta _pictureMeta =
      const VerificationMeta('picture');
  @override
  late final GeneratedColumn<String> picture = GeneratedColumn<String>(
      'picture', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, nutrientsCategorieId, unitCode, picture, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrient';
  @override
  VerificationContext validateIntegrity(Insertable<NutrientData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('nutrients_categorie_id')) {
      context.handle(
          _nutrientsCategorieIdMeta,
          nutrientsCategorieId.isAcceptableOrUnknown(
              data['nutrients_categorie_id']!, _nutrientsCategorieIdMeta));
    } else if (isInserting) {
      context.missing(_nutrientsCategorieIdMeta);
    }
    if (data.containsKey('unit_code')) {
      context.handle(_unitCodeMeta,
          unitCode.isAcceptableOrUnknown(data['unit_code']!, _unitCodeMeta));
    } else if (isInserting) {
      context.missing(_unitCodeMeta);
    }
    if (data.containsKey('picture')) {
      context.handle(_pictureMeta,
          picture.isAcceptableOrUnknown(data['picture']!, _pictureMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NutrientData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NutrientData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      nutrientsCategorieId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}nutrients_categorie_id'])!,
      unitCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_code'])!,
      picture: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}picture']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
    );
  }

  @override
  $NutrientTable createAlias(String alias) {
    return $NutrientTable(attachedDatabase, alias);
  }
}

class NutrientData extends DataClass implements Insertable<NutrientData> {
  final int id;
  final String name;
  final int nutrientsCategorieId;
  final String unitCode;
  final String? picture;
  final String? color;
  const NutrientData(
      {required this.id,
      required this.name,
      required this.nutrientsCategorieId,
      required this.unitCode,
      this.picture,
      this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['nutrients_categorie_id'] = Variable<int>(nutrientsCategorieId);
    map['unit_code'] = Variable<String>(unitCode);
    if (!nullToAbsent || picture != null) {
      map['picture'] = Variable<String>(picture);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    return map;
  }

  NutrientCompanion toCompanion(bool nullToAbsent) {
    return NutrientCompanion(
      id: Value(id),
      name: Value(name),
      nutrientsCategorieId: Value(nutrientsCategorieId),
      unitCode: Value(unitCode),
      picture: picture == null && nullToAbsent
          ? const Value.absent()
          : Value(picture),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
    );
  }

  factory NutrientData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NutrientData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nutrientsCategorieId:
          serializer.fromJson<int>(json['nutrientsCategorieId']),
      unitCode: serializer.fromJson<String>(json['unitCode']),
      picture: serializer.fromJson<String?>(json['picture']),
      color: serializer.fromJson<String?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'nutrientsCategorieId': serializer.toJson<int>(nutrientsCategorieId),
      'unitCode': serializer.toJson<String>(unitCode),
      'picture': serializer.toJson<String?>(picture),
      'color': serializer.toJson<String?>(color),
    };
  }

  NutrientData copyWith(
          {int? id,
          String? name,
          int? nutrientsCategorieId,
          String? unitCode,
          Value<String?> picture = const Value.absent(),
          Value<String?> color = const Value.absent()}) =>
      NutrientData(
        id: id ?? this.id,
        name: name ?? this.name,
        nutrientsCategorieId: nutrientsCategorieId ?? this.nutrientsCategorieId,
        unitCode: unitCode ?? this.unitCode,
        picture: picture.present ? picture.value : this.picture,
        color: color.present ? color.value : this.color,
      );
  NutrientData copyWithCompanion(NutrientCompanion data) {
    return NutrientData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nutrientsCategorieId: data.nutrientsCategorieId.present
          ? data.nutrientsCategorieId.value
          : this.nutrientsCategorieId,
      unitCode: data.unitCode.present ? data.unitCode.value : this.unitCode,
      picture: data.picture.present ? data.picture.value : this.picture,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NutrientData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nutrientsCategorieId: $nutrientsCategorieId, ')
          ..write('unitCode: $unitCode, ')
          ..write('picture: $picture, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, nutrientsCategorieId, unitCode, picture, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutrientData &&
          other.id == this.id &&
          other.name == this.name &&
          other.nutrientsCategorieId == this.nutrientsCategorieId &&
          other.unitCode == this.unitCode &&
          other.picture == this.picture &&
          other.color == this.color);
}

class NutrientCompanion extends UpdateCompanion<NutrientData> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> nutrientsCategorieId;
  final Value<String> unitCode;
  final Value<String?> picture;
  final Value<String?> color;
  const NutrientCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nutrientsCategorieId = const Value.absent(),
    this.unitCode = const Value.absent(),
    this.picture = const Value.absent(),
    this.color = const Value.absent(),
  });
  NutrientCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int nutrientsCategorieId,
    required String unitCode,
    this.picture = const Value.absent(),
    this.color = const Value.absent(),
  })  : name = Value(name),
        nutrientsCategorieId = Value(nutrientsCategorieId),
        unitCode = Value(unitCode);
  static Insertable<NutrientData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? nutrientsCategorieId,
    Expression<String>? unitCode,
    Expression<String>? picture,
    Expression<String>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nutrientsCategorieId != null)
        'nutrients_categorie_id': nutrientsCategorieId,
      if (unitCode != null) 'unit_code': unitCode,
      if (picture != null) 'picture': picture,
      if (color != null) 'color': color,
    });
  }

  NutrientCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? nutrientsCategorieId,
      Value<String>? unitCode,
      Value<String?>? picture,
      Value<String?>? color}) {
    return NutrientCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nutrientsCategorieId: nutrientsCategorieId ?? this.nutrientsCategorieId,
      unitCode: unitCode ?? this.unitCode,
      picture: picture ?? this.picture,
      color: color ?? this.color,
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
    if (nutrientsCategorieId.present) {
      map['nutrients_categorie_id'] = Variable<int>(nutrientsCategorieId.value);
    }
    if (unitCode.present) {
      map['unit_code'] = Variable<String>(unitCode.value);
    }
    if (picture.present) {
      map['picture'] = Variable<String>(picture.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutrientCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nutrientsCategorieId: $nutrientsCategorieId, ')
          ..write('unitCode: $unitCode, ')
          ..write('picture: $picture, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $IngredientCategoriesTable extends IngredientCategories
    with TableInfo<$IngredientCategoriesTable, IngredientCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
      'image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, title, image];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_categories';
  @override
  VerificationContext validateIntegrity(Insertable<IngredientCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('image')) {
      context.handle(
          _imageMeta, image.isAcceptableOrUnknown(data['image']!, _imageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      image: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image']),
    );
  }

  @override
  $IngredientCategoriesTable createAlias(String alias) {
    return $IngredientCategoriesTable(attachedDatabase, alias);
  }
}

class IngredientCategory extends DataClass
    implements Insertable<IngredientCategory> {
  final int id;
  final String title;
  final String? image;
  const IngredientCategory({required this.id, required this.title, this.image});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || image != null) {
      map['image'] = Variable<String>(image);
    }
    return map;
  }

  IngredientCategoriesCompanion toCompanion(bool nullToAbsent) {
    return IngredientCategoriesCompanion(
      id: Value(id),
      title: Value(title),
      image:
          image == null && nullToAbsent ? const Value.absent() : Value(image),
    );
  }

  factory IngredientCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientCategory(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      image: serializer.fromJson<String?>(json['image']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'image': serializer.toJson<String?>(image),
    };
  }

  IngredientCategory copyWith(
          {int? id,
          String? title,
          Value<String?> image = const Value.absent()}) =>
      IngredientCategory(
        id: id ?? this.id,
        title: title ?? this.title,
        image: image.present ? image.value : this.image,
      );
  IngredientCategory copyWithCompanion(IngredientCategoriesCompanion data) {
    return IngredientCategory(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      image: data.image.present ? data.image.value : this.image,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientCategory(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('image: $image')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, image);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientCategory &&
          other.id == this.id &&
          other.title == this.title &&
          other.image == this.image);
}

class IngredientCategoriesCompanion
    extends UpdateCompanion<IngredientCategory> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> image;
  const IngredientCategoriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.image = const Value.absent(),
  });
  IngredientCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.image = const Value.absent(),
  }) : title = Value(title);
  static Insertable<IngredientCategory> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? image,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (image != null) 'image': image,
    });
  }

  IngredientCategoriesCompanion copyWith(
      {Value<int>? id, Value<String>? title, Value<String?>? image}) {
    return IngredientCategoriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('image: $image')
          ..write(')'))
        .toString();
  }
}

class $IngredientPropertiesTable extends IngredientProperties
    with TableInfo<$IngredientPropertiesTable, IngredientProperty> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientPropertiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_properties';
  @override
  VerificationContext validateIntegrity(Insertable<IngredientProperty> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientProperty map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientProperty(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $IngredientPropertiesTable createAlias(String alias) {
    return $IngredientPropertiesTable(attachedDatabase, alias);
  }
}

class IngredientProperty extends DataClass
    implements Insertable<IngredientProperty> {
  final int id;
  final String name;
  const IngredientProperty({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  IngredientPropertiesCompanion toCompanion(bool nullToAbsent) {
    return IngredientPropertiesCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory IngredientProperty.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientProperty(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  IngredientProperty copyWith({int? id, String? name}) => IngredientProperty(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  IngredientProperty copyWithCompanion(IngredientPropertiesCompanion data) {
    return IngredientProperty(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientProperty(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientProperty &&
          other.id == this.id &&
          other.name == this.name);
}

class IngredientPropertiesCompanion
    extends UpdateCompanion<IngredientProperty> {
  final Value<int> id;
  final Value<String> name;
  const IngredientPropertiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  IngredientPropertiesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<IngredientProperty> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  IngredientPropertiesCompanion copyWith(
      {Value<int>? id, Value<String>? name}) {
    return IngredientPropertiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientPropertiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $IngredientsTable extends Ingredients
    with TableInfo<$IngredientsTable, Ingredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ingredientCategoryIdMeta =
      const VerificationMeta('ingredientCategoryId');
  @override
  late final GeneratedColumn<int> ingredientCategoryId = GeneratedColumn<int>(
      'ingredient_category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES ingredient_categories (id)'));
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<int> unitId = GeneratedColumn<int>(
      'unit_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES units (id)'));
  static const VerificationMeta _pictureMeta =
      const VerificationMeta('picture');
  @override
  late final GeneratedColumn<String> picture = GeneratedColumn<String>(
      'picture', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, ingredientCategoryId, unitId, picture];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredients';
  @override
  VerificationContext validateIntegrity(Insertable<Ingredient> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('ingredient_category_id')) {
      context.handle(
          _ingredientCategoryIdMeta,
          ingredientCategoryId.isAcceptableOrUnknown(
              data['ingredient_category_id']!, _ingredientCategoryIdMeta));
    } else if (isInserting) {
      context.missing(_ingredientCategoryIdMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    }
    if (data.containsKey('picture')) {
      context.handle(_pictureMeta,
          picture.isAcceptableOrUnknown(data['picture']!, _pictureMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ingredient(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      ingredientCategoryId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}ingredient_category_id'])!,
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_id']),
      picture: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}picture']),
    );
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(attachedDatabase, alias);
  }
}

class Ingredient extends DataClass implements Insertable<Ingredient> {
  final int id;
  final String name;
  final int ingredientCategoryId;
  final int? unitId;
  final String? picture;
  const Ingredient(
      {required this.id,
      required this.name,
      required this.ingredientCategoryId,
      this.unitId,
      this.picture});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['ingredient_category_id'] = Variable<int>(ingredientCategoryId);
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<int>(unitId);
    }
    if (!nullToAbsent || picture != null) {
      map['picture'] = Variable<String>(picture);
    }
    return map;
  }

  IngredientsCompanion toCompanion(bool nullToAbsent) {
    return IngredientsCompanion(
      id: Value(id),
      name: Value(name),
      ingredientCategoryId: Value(ingredientCategoryId),
      unitId:
          unitId == null && nullToAbsent ? const Value.absent() : Value(unitId),
      picture: picture == null && nullToAbsent
          ? const Value.absent()
          : Value(picture),
    );
  }

  factory Ingredient.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ingredient(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ingredientCategoryId:
          serializer.fromJson<int>(json['ingredientCategoryId']),
      unitId: serializer.fromJson<int?>(json['unitId']),
      picture: serializer.fromJson<String?>(json['picture']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'ingredientCategoryId': serializer.toJson<int>(ingredientCategoryId),
      'unitId': serializer.toJson<int?>(unitId),
      'picture': serializer.toJson<String?>(picture),
    };
  }

  Ingredient copyWith(
          {int? id,
          String? name,
          int? ingredientCategoryId,
          Value<int?> unitId = const Value.absent(),
          Value<String?> picture = const Value.absent()}) =>
      Ingredient(
        id: id ?? this.id,
        name: name ?? this.name,
        ingredientCategoryId: ingredientCategoryId ?? this.ingredientCategoryId,
        unitId: unitId.present ? unitId.value : this.unitId,
        picture: picture.present ? picture.value : this.picture,
      );
  Ingredient copyWithCompanion(IngredientsCompanion data) {
    return Ingredient(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ingredientCategoryId: data.ingredientCategoryId.present
          ? data.ingredientCategoryId.value
          : this.ingredientCategoryId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      picture: data.picture.present ? data.picture.value : this.picture,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ingredient(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ingredientCategoryId: $ingredientCategoryId, ')
          ..write('unitId: $unitId, ')
          ..write('picture: $picture')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, ingredientCategoryId, unitId, picture);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ingredient &&
          other.id == this.id &&
          other.name == this.name &&
          other.ingredientCategoryId == this.ingredientCategoryId &&
          other.unitId == this.unitId &&
          other.picture == this.picture);
}

class IngredientsCompanion extends UpdateCompanion<Ingredient> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> ingredientCategoryId;
  final Value<int?> unitId;
  final Value<String?> picture;
  const IngredientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ingredientCategoryId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.picture = const Value.absent(),
  });
  IngredientsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int ingredientCategoryId,
    this.unitId = const Value.absent(),
    this.picture = const Value.absent(),
  })  : name = Value(name),
        ingredientCategoryId = Value(ingredientCategoryId);
  static Insertable<Ingredient> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? ingredientCategoryId,
    Expression<int>? unitId,
    Expression<String>? picture,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ingredientCategoryId != null)
        'ingredient_category_id': ingredientCategoryId,
      if (unitId != null) 'unit_id': unitId,
      if (picture != null) 'picture': picture,
    });
  }

  IngredientsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? ingredientCategoryId,
      Value<int?>? unitId,
      Value<String?>? picture}) {
    return IngredientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ingredientCategoryId: ingredientCategoryId ?? this.ingredientCategoryId,
      unitId: unitId ?? this.unitId,
      picture: picture ?? this.picture,
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
    if (ingredientCategoryId.present) {
      map['ingredient_category_id'] = Variable<int>(ingredientCategoryId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<int>(unitId.value);
    }
    if (picture.present) {
      map['picture'] = Variable<String>(picture.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ingredientCategoryId: $ingredientCategoryId, ')
          ..write('unitId: $unitId, ')
          ..write('picture: $picture')
          ..write(')'))
        .toString();
  }
}

class $IngredientNutrientsTable extends IngredientNutrients
    with TableInfo<$IngredientNutrientsTable, IngredientNutrient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientNutrientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _ingredientIdMeta =
      const VerificationMeta('ingredientId');
  @override
  late final GeneratedColumn<int> ingredientId = GeneratedColumn<int>(
      'ingredient_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES ingredients (id)'));
  static const VerificationMeta _nutrientIdMeta =
      const VerificationMeta('nutrientId');
  @override
  late final GeneratedColumn<int> nutrientId = GeneratedColumn<int>(
      'nutrient_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES nutrient (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, ingredientId, nutrientId, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_nutrients';
  @override
  VerificationContext validateIntegrity(Insertable<IngredientNutrient> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
          _ingredientIdMeta,
          ingredientId.isAcceptableOrUnknown(
              data['ingredient_id']!, _ingredientIdMeta));
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('nutrient_id')) {
      context.handle(
          _nutrientIdMeta,
          nutrientId.isAcceptableOrUnknown(
              data['nutrient_id']!, _nutrientIdMeta));
    } else if (isInserting) {
      context.missing(_nutrientIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientNutrient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientNutrient(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ingredientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ingredient_id'])!,
      nutrientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}nutrient_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
    );
  }

  @override
  $IngredientNutrientsTable createAlias(String alias) {
    return $IngredientNutrientsTable(attachedDatabase, alias);
  }
}

class IngredientNutrient extends DataClass
    implements Insertable<IngredientNutrient> {
  final int id;
  final int ingredientId;
  final int nutrientId;
  final double amount;
  const IngredientNutrient(
      {required this.id,
      required this.ingredientId,
      required this.nutrientId,
      required this.amount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ingredient_id'] = Variable<int>(ingredientId);
    map['nutrient_id'] = Variable<int>(nutrientId);
    map['amount'] = Variable<double>(amount);
    return map;
  }

  IngredientNutrientsCompanion toCompanion(bool nullToAbsent) {
    return IngredientNutrientsCompanion(
      id: Value(id),
      ingredientId: Value(ingredientId),
      nutrientId: Value(nutrientId),
      amount: Value(amount),
    );
  }

  factory IngredientNutrient.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientNutrient(
      id: serializer.fromJson<int>(json['id']),
      ingredientId: serializer.fromJson<int>(json['ingredientId']),
      nutrientId: serializer.fromJson<int>(json['nutrientId']),
      amount: serializer.fromJson<double>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ingredientId': serializer.toJson<int>(ingredientId),
      'nutrientId': serializer.toJson<int>(nutrientId),
      'amount': serializer.toJson<double>(amount),
    };
  }

  IngredientNutrient copyWith(
          {int? id, int? ingredientId, int? nutrientId, double? amount}) =>
      IngredientNutrient(
        id: id ?? this.id,
        ingredientId: ingredientId ?? this.ingredientId,
        nutrientId: nutrientId ?? this.nutrientId,
        amount: amount ?? this.amount,
      );
  IngredientNutrient copyWithCompanion(IngredientNutrientsCompanion data) {
    return IngredientNutrient(
      id: data.id.present ? data.id.value : this.id,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      nutrientId:
          data.nutrientId.present ? data.nutrientId.value : this.nutrientId,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientNutrient(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('nutrientId: $nutrientId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ingredientId, nutrientId, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientNutrient &&
          other.id == this.id &&
          other.ingredientId == this.ingredientId &&
          other.nutrientId == this.nutrientId &&
          other.amount == this.amount);
}

class IngredientNutrientsCompanion extends UpdateCompanion<IngredientNutrient> {
  final Value<int> id;
  final Value<int> ingredientId;
  final Value<int> nutrientId;
  final Value<double> amount;
  const IngredientNutrientsCompanion({
    this.id = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.nutrientId = const Value.absent(),
    this.amount = const Value.absent(),
  });
  IngredientNutrientsCompanion.insert({
    this.id = const Value.absent(),
    required int ingredientId,
    required int nutrientId,
    required double amount,
  })  : ingredientId = Value(ingredientId),
        nutrientId = Value(nutrientId),
        amount = Value(amount);
  static Insertable<IngredientNutrient> custom({
    Expression<int>? id,
    Expression<int>? ingredientId,
    Expression<int>? nutrientId,
    Expression<double>? amount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (nutrientId != null) 'nutrient_id': nutrientId,
      if (amount != null) 'amount': amount,
    });
  }

  IngredientNutrientsCompanion copyWith(
      {Value<int>? id,
      Value<int>? ingredientId,
      Value<int>? nutrientId,
      Value<double>? amount}) {
    return IngredientNutrientsCompanion(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      nutrientId: nutrientId ?? this.nutrientId,
      amount: amount ?? this.amount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    if (nutrientId.present) {
      map['nutrient_id'] = Variable<int>(nutrientId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientNutrientsCompanion(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('nutrientId: $nutrientId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }
}

class $SeasonalityTable extends Seasonality
    with TableInfo<$SeasonalityTable, SeasonalityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeasonalityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seasonality';
  @override
  VerificationContext validateIntegrity(Insertable<SeasonalityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeasonalityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeasonalityData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
    );
  }

  @override
  $SeasonalityTable createAlias(String alias) {
    return $SeasonalityTable(attachedDatabase, alias);
  }
}

class SeasonalityData extends DataClass implements Insertable<SeasonalityData> {
  final int id;
  final String name;
  final String? color;
  const SeasonalityData({required this.id, required this.name, this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    return map;
  }

  SeasonalityCompanion toCompanion(bool nullToAbsent) {
    return SeasonalityCompanion(
      id: Value(id),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
    );
  }

  factory SeasonalityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeasonalityData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
    };
  }

  SeasonalityData copyWith(
          {int? id,
          String? name,
          Value<String?> color = const Value.absent()}) =>
      SeasonalityData(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
      );
  SeasonalityData copyWithCompanion(SeasonalityCompanion data) {
    return SeasonalityData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeasonalityData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeasonalityData &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color);
}

class SeasonalityCompanion extends UpdateCompanion<SeasonalityData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> color;
  const SeasonalityCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
  });
  SeasonalityCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
  }) : name = Value(name);
  static Insertable<SeasonalityData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
  }

  SeasonalityCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<String?>? color}) {
    return SeasonalityCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
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
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeasonalityCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $IngredientSeasonalityTable extends IngredientSeasonality
    with TableInfo<$IngredientSeasonalityTable, IngredientSeasonalityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientSeasonalityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ingredientsIdMeta =
      const VerificationMeta('ingredientsId');
  @override
  late final GeneratedColumn<int> ingredientsId = GeneratedColumn<int>(
      'ingredients_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES ingredients (id)'));
  static const VerificationMeta _monthsIdMeta =
      const VerificationMeta('monthsId');
  @override
  late final GeneratedColumn<int> monthsId = GeneratedColumn<int>(
      'months_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES months (id)'));
  static const VerificationMeta _seasonalityIdMeta =
      const VerificationMeta('seasonalityId');
  @override
  late final GeneratedColumn<int> seasonalityId = GeneratedColumn<int>(
      'seasonality_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES seasonality (id)'));
  @override
  List<GeneratedColumn> get $columns =>
      [ingredientsId, monthsId, seasonalityId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_seasonality';
  @override
  VerificationContext validateIntegrity(
      Insertable<IngredientSeasonalityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ingredients_id')) {
      context.handle(
          _ingredientsIdMeta,
          ingredientsId.isAcceptableOrUnknown(
              data['ingredients_id']!, _ingredientsIdMeta));
    } else if (isInserting) {
      context.missing(_ingredientsIdMeta);
    }
    if (data.containsKey('months_id')) {
      context.handle(_monthsIdMeta,
          monthsId.isAcceptableOrUnknown(data['months_id']!, _monthsIdMeta));
    } else if (isInserting) {
      context.missing(_monthsIdMeta);
    }
    if (data.containsKey('seasonality_id')) {
      context.handle(
          _seasonalityIdMeta,
          seasonalityId.isAcceptableOrUnknown(
              data['seasonality_id']!, _seasonalityIdMeta));
    } else if (isInserting) {
      context.missing(_seasonalityIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ingredientsId, monthsId};
  @override
  IngredientSeasonalityData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientSeasonalityData(
      ingredientsId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ingredients_id'])!,
      monthsId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}months_id'])!,
      seasonalityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seasonality_id'])!,
    );
  }

  @override
  $IngredientSeasonalityTable createAlias(String alias) {
    return $IngredientSeasonalityTable(attachedDatabase, alias);
  }
}

class IngredientSeasonalityData extends DataClass
    implements Insertable<IngredientSeasonalityData> {
  final int ingredientsId;
  final int monthsId;
  final int seasonalityId;
  const IngredientSeasonalityData(
      {required this.ingredientsId,
      required this.monthsId,
      required this.seasonalityId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ingredients_id'] = Variable<int>(ingredientsId);
    map['months_id'] = Variable<int>(monthsId);
    map['seasonality_id'] = Variable<int>(seasonalityId);
    return map;
  }

  IngredientSeasonalityCompanion toCompanion(bool nullToAbsent) {
    return IngredientSeasonalityCompanion(
      ingredientsId: Value(ingredientsId),
      monthsId: Value(monthsId),
      seasonalityId: Value(seasonalityId),
    );
  }

  factory IngredientSeasonalityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientSeasonalityData(
      ingredientsId: serializer.fromJson<int>(json['ingredientsId']),
      monthsId: serializer.fromJson<int>(json['monthsId']),
      seasonalityId: serializer.fromJson<int>(json['seasonalityId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ingredientsId': serializer.toJson<int>(ingredientsId),
      'monthsId': serializer.toJson<int>(monthsId),
      'seasonalityId': serializer.toJson<int>(seasonalityId),
    };
  }

  IngredientSeasonalityData copyWith(
          {int? ingredientsId, int? monthsId, int? seasonalityId}) =>
      IngredientSeasonalityData(
        ingredientsId: ingredientsId ?? this.ingredientsId,
        monthsId: monthsId ?? this.monthsId,
        seasonalityId: seasonalityId ?? this.seasonalityId,
      );
  IngredientSeasonalityData copyWithCompanion(
      IngredientSeasonalityCompanion data) {
    return IngredientSeasonalityData(
      ingredientsId: data.ingredientsId.present
          ? data.ingredientsId.value
          : this.ingredientsId,
      monthsId: data.monthsId.present ? data.monthsId.value : this.monthsId,
      seasonalityId: data.seasonalityId.present
          ? data.seasonalityId.value
          : this.seasonalityId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientSeasonalityData(')
          ..write('ingredientsId: $ingredientsId, ')
          ..write('monthsId: $monthsId, ')
          ..write('seasonalityId: $seasonalityId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ingredientsId, monthsId, seasonalityId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientSeasonalityData &&
          other.ingredientsId == this.ingredientsId &&
          other.monthsId == this.monthsId &&
          other.seasonalityId == this.seasonalityId);
}

class IngredientSeasonalityCompanion
    extends UpdateCompanion<IngredientSeasonalityData> {
  final Value<int> ingredientsId;
  final Value<int> monthsId;
  final Value<int> seasonalityId;
  final Value<int> rowid;
  const IngredientSeasonalityCompanion({
    this.ingredientsId = const Value.absent(),
    this.monthsId = const Value.absent(),
    this.seasonalityId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientSeasonalityCompanion.insert({
    required int ingredientsId,
    required int monthsId,
    required int seasonalityId,
    this.rowid = const Value.absent(),
  })  : ingredientsId = Value(ingredientsId),
        monthsId = Value(monthsId),
        seasonalityId = Value(seasonalityId);
  static Insertable<IngredientSeasonalityData> custom({
    Expression<int>? ingredientsId,
    Expression<int>? monthsId,
    Expression<int>? seasonalityId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ingredientsId != null) 'ingredients_id': ingredientsId,
      if (monthsId != null) 'months_id': monthsId,
      if (seasonalityId != null) 'seasonality_id': seasonalityId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientSeasonalityCompanion copyWith(
      {Value<int>? ingredientsId,
      Value<int>? monthsId,
      Value<int>? seasonalityId,
      Value<int>? rowid}) {
    return IngredientSeasonalityCompanion(
      ingredientsId: ingredientsId ?? this.ingredientsId,
      monthsId: monthsId ?? this.monthsId,
      seasonalityId: seasonalityId ?? this.seasonalityId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ingredientsId.present) {
      map['ingredients_id'] = Variable<int>(ingredientsId.value);
    }
    if (monthsId.present) {
      map['months_id'] = Variable<int>(monthsId.value);
    }
    if (seasonalityId.present) {
      map['seasonality_id'] = Variable<int>(seasonalityId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientSeasonalityCompanion(')
          ..write('ingredientsId: $ingredientsId, ')
          ..write('monthsId: $monthsId, ')
          ..write('seasonalityId: $seasonalityId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $MonthsTable months = $MonthsTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $UnitConversionsTable unitConversions =
      $UnitConversionsTable(this);
  late final $IngredientUnitOverridesTable ingredientUnitOverrides =
      $IngredientUnitOverridesTable(this);
  late final $NutrientsCategorieTable nutrientsCategorie =
      $NutrientsCategorieTable(this);
  late final $NutrientTable nutrient = $NutrientTable(this);
  late final $IngredientCategoriesTable ingredientCategories =
      $IngredientCategoriesTable(this);
  late final $IngredientPropertiesTable ingredientProperties =
      $IngredientPropertiesTable(this);
  late final $IngredientsTable ingredients = $IngredientsTable(this);
  late final $IngredientNutrientsTable ingredientNutrients =
      $IngredientNutrientsTable(this);
  late final $SeasonalityTable seasonality = $SeasonalityTable(this);
  late final $IngredientSeasonalityTable ingredientSeasonality =
      $IngredientSeasonalityTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        months,
        units,
        unitConversions,
        ingredientUnitOverrides,
        nutrientsCategorie,
        nutrient,
        ingredientCategories,
        ingredientProperties,
        ingredients,
        ingredientNutrients,
        seasonality,
        ingredientSeasonality
      ];
}

typedef $$MonthsTableCreateCompanionBuilder = MonthsCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$MonthsTableUpdateCompanionBuilder = MonthsCompanion Function({
  Value<int> id,
  Value<String> name,
});

final class $$MonthsTableReferences
    extends BaseReferences<_$AppDb, $MonthsTable, Month> {
  $$MonthsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IngredientSeasonalityTable,
      List<IngredientSeasonalityData>> _ingredientSeasonalityRefsTable(
          _$AppDb db) =>
      MultiTypedResultKey.fromTable(db.ingredientSeasonality,
          aliasName: $_aliasNameGenerator(
              db.months.id, db.ingredientSeasonality.monthsId));

  $$IngredientSeasonalityTableProcessedTableManager
      get ingredientSeasonalityRefs {
    final manager = $$IngredientSeasonalityTableTableManager(
            $_db, $_db.ingredientSeasonality)
        .filter((f) => f.monthsId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientSeasonalityRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MonthsTableFilterComposer extends Composer<_$AppDb, $MonthsTable> {
  $$MonthsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> ingredientSeasonalityRefs(
      Expression<bool> Function($$IngredientSeasonalityTableFilterComposer f)
          f) {
    final $$IngredientSeasonalityTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientSeasonality,
            getReferencedColumn: (t) => t.monthsId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientSeasonalityTableFilterComposer(
                  $db: $db,
                  $table: $db.ingredientSeasonality,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$MonthsTableOrderingComposer extends Composer<_$AppDb, $MonthsTable> {
  $$MonthsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$MonthsTableAnnotationComposer extends Composer<_$AppDb, $MonthsTable> {
  $$MonthsTableAnnotationComposer({
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

  Expression<T> ingredientSeasonalityRefs<T extends Object>(
      Expression<T> Function($$IngredientSeasonalityTableAnnotationComposer a)
          f) {
    final $$IngredientSeasonalityTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientSeasonality,
            getReferencedColumn: (t) => t.monthsId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientSeasonalityTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientSeasonality,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$MonthsTableTableManager extends RootTableManager<
    _$AppDb,
    $MonthsTable,
    Month,
    $$MonthsTableFilterComposer,
    $$MonthsTableOrderingComposer,
    $$MonthsTableAnnotationComposer,
    $$MonthsTableCreateCompanionBuilder,
    $$MonthsTableUpdateCompanionBuilder,
    (Month, $$MonthsTableReferences),
    Month,
    PrefetchHooks Function({bool ingredientSeasonalityRefs})> {
  $$MonthsTableTableManager(_$AppDb db, $MonthsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              MonthsCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              MonthsCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$MonthsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({ingredientSeasonalityRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ingredientSeasonalityRefs) db.ingredientSeasonality
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientSeasonalityRefs)
                    await $_getPrefetchedData<Month, $MonthsTable,
                            IngredientSeasonalityData>(
                        currentTable: table,
                        referencedTable: $$MonthsTableReferences
                            ._ingredientSeasonalityRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MonthsTableReferences(db, table, p0)
                                .ingredientSeasonalityRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.monthsId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MonthsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $MonthsTable,
    Month,
    $$MonthsTableFilterComposer,
    $$MonthsTableOrderingComposer,
    $$MonthsTableAnnotationComposer,
    $$MonthsTableCreateCompanionBuilder,
    $$MonthsTableUpdateCompanionBuilder,
    (Month, $$MonthsTableReferences),
    Month,
    PrefetchHooks Function({bool ingredientSeasonalityRefs})>;
typedef $$UnitsTableCreateCompanionBuilder = UnitsCompanion Function({
  Value<int> id,
  required String code,
  required String label,
  required String dimension,
  required double baseFactor,
});
typedef $$UnitsTableUpdateCompanionBuilder = UnitsCompanion Function({
  Value<int> id,
  Value<String> code,
  Value<String> label,
  Value<String> dimension,
  Value<double> baseFactor,
});

final class $$UnitsTableReferences
    extends BaseReferences<_$AppDb, $UnitsTable, Unit> {
  $$UnitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IngredientUnitOverridesTable,
      List<IngredientUnitOverride>> _ingredientUnitOverridesRefsTable(
          _$AppDb db) =>
      MultiTypedResultKey.fromTable(db.ingredientUnitOverrides,
          aliasName: $_aliasNameGenerator(
              db.units.id, db.ingredientUnitOverrides.unitId));

  $$IngredientUnitOverridesTableProcessedTableManager
      get ingredientUnitOverridesRefs {
    final manager = $$IngredientUnitOverridesTableTableManager(
            $_db, $_db.ingredientUnitOverrides)
        .filter((f) => f.unitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientUnitOverridesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NutrientsCategorieTable,
      List<NutrientsCategorieData>> _nutrientsCategorieRefsTable(
          _$AppDb db) =>
      MultiTypedResultKey.fromTable(db.nutrientsCategorie,
          aliasName: $_aliasNameGenerator(
              db.units.code, db.nutrientsCategorie.unitCode));

  $$NutrientsCategorieTableProcessedTableManager get nutrientsCategorieRefs {
    final manager = $$NutrientsCategorieTableTableManager(
            $_db, $_db.nutrientsCategorie)
        .filter(
            (f) => f.unitCode.code.sqlEquals($_itemColumn<String>('code')!));

    final cache =
        $_typedResult.readTableOrNull(_nutrientsCategorieRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NutrientTable, List<NutrientData>>
      _nutrientRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
          db.nutrient,
          aliasName: $_aliasNameGenerator(db.units.code, db.nutrient.unitCode));

  $$NutrientTableProcessedTableManager get nutrientRefs {
    final manager = $$NutrientTableTableManager($_db, $_db.nutrient).filter(
        (f) => f.unitCode.code.sqlEquals($_itemColumn<String>('code')!));

    final cache = $_typedResult.readTableOrNull(_nutrientRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IngredientsTable, List<Ingredient>>
      _ingredientsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
          db.ingredients,
          aliasName: $_aliasNameGenerator(db.units.id, db.ingredients.unitId));

  $$IngredientsTableProcessedTableManager get ingredientsRefs {
    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.unitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ingredientsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UnitsTableFilterComposer extends Composer<_$AppDb, $UnitsTable> {
  $$UnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dimension => $composableBuilder(
      column: $table.dimension, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get baseFactor => $composableBuilder(
      column: $table.baseFactor, builder: (column) => ColumnFilters(column));

  Expression<bool> ingredientUnitOverridesRefs(
      Expression<bool> Function($$IngredientUnitOverridesTableFilterComposer f)
          f) {
    final $$IngredientUnitOverridesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientUnitOverrides,
            getReferencedColumn: (t) => t.unitId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientUnitOverridesTableFilterComposer(
                  $db: $db,
                  $table: $db.ingredientUnitOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> nutrientsCategorieRefs(
      Expression<bool> Function($$NutrientsCategorieTableFilterComposer f) f) {
    final $$NutrientsCategorieTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.code,
        referencedTable: $db.nutrientsCategorie,
        getReferencedColumn: (t) => t.unitCode,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutrientsCategorieTableFilterComposer(
              $db: $db,
              $table: $db.nutrientsCategorie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> nutrientRefs(
      Expression<bool> Function($$NutrientTableFilterComposer f) f) {
    final $$NutrientTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.code,
        referencedTable: $db.nutrient,
        getReferencedColumn: (t) => t.unitCode,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutrientTableFilterComposer(
              $db: $db,
              $table: $db.nutrient,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ingredientsRefs(
      Expression<bool> Function($$IngredientsTableFilterComposer f) f) {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UnitsTableOrderingComposer extends Composer<_$AppDb, $UnitsTable> {
  $$UnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dimension => $composableBuilder(
      column: $table.dimension, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get baseFactor => $composableBuilder(
      column: $table.baseFactor, builder: (column) => ColumnOrderings(column));
}

class $$UnitsTableAnnotationComposer extends Composer<_$AppDb, $UnitsTable> {
  $$UnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get dimension =>
      $composableBuilder(column: $table.dimension, builder: (column) => column);

  GeneratedColumn<double> get baseFactor => $composableBuilder(
      column: $table.baseFactor, builder: (column) => column);

  Expression<T> ingredientUnitOverridesRefs<T extends Object>(
      Expression<T> Function($$IngredientUnitOverridesTableAnnotationComposer a)
          f) {
    final $$IngredientUnitOverridesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientUnitOverrides,
            getReferencedColumn: (t) => t.unitId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientUnitOverridesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientUnitOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> nutrientsCategorieRefs<T extends Object>(
      Expression<T> Function($$NutrientsCategorieTableAnnotationComposer a) f) {
    final $$NutrientsCategorieTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.code,
            referencedTable: $db.nutrientsCategorie,
            getReferencedColumn: (t) => t.unitCode,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NutrientsCategorieTableAnnotationComposer(
                  $db: $db,
                  $table: $db.nutrientsCategorie,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> nutrientRefs<T extends Object>(
      Expression<T> Function($$NutrientTableAnnotationComposer a) f) {
    final $$NutrientTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.code,
        referencedTable: $db.nutrient,
        getReferencedColumn: (t) => t.unitCode,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutrientTableAnnotationComposer(
              $db: $db,
              $table: $db.nutrient,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ingredientsRefs<T extends Object>(
      Expression<T> Function($$IngredientsTableAnnotationComposer a) f) {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UnitsTableTableManager extends RootTableManager<
    _$AppDb,
    $UnitsTable,
    Unit,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (Unit, $$UnitsTableReferences),
    Unit,
    PrefetchHooks Function(
        {bool ingredientUnitOverridesRefs,
        bool nutrientsCategorieRefs,
        bool nutrientRefs,
        bool ingredientsRefs})> {
  $$UnitsTableTableManager(_$AppDb db, $UnitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> dimension = const Value.absent(),
            Value<double> baseFactor = const Value.absent(),
          }) =>
              UnitsCompanion(
            id: id,
            code: code,
            label: label,
            dimension: dimension,
            baseFactor: baseFactor,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String code,
            required String label,
            required String dimension,
            required double baseFactor,
          }) =>
              UnitsCompanion.insert(
            id: id,
            code: code,
            label: label,
            dimension: dimension,
            baseFactor: baseFactor,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UnitsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {ingredientUnitOverridesRefs = false,
              nutrientsCategorieRefs = false,
              nutrientRefs = false,
              ingredientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ingredientUnitOverridesRefs) db.ingredientUnitOverrides,
                if (nutrientsCategorieRefs) db.nutrientsCategorie,
                if (nutrientRefs) db.nutrient,
                if (ingredientsRefs) db.ingredients
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientUnitOverridesRefs)
                    await $_getPrefetchedData<Unit, $UnitsTable,
                            IngredientUnitOverride>(
                        currentTable: table,
                        referencedTable: $$UnitsTableReferences
                            ._ingredientUnitOverridesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsTableReferences(db, table, p0)
                                .ingredientUnitOverridesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.unitId == item.id),
                        typedResults: items),
                  if (nutrientsCategorieRefs)
                    await $_getPrefetchedData<Unit, $UnitsTable,
                            NutrientsCategorieData>(
                        currentTable: table,
                        referencedTable: $$UnitsTableReferences
                            ._nutrientsCategorieRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsTableReferences(db, table, p0)
                                .nutrientsCategorieRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.unitCode == item.code),
                        typedResults: items),
                  if (nutrientRefs)
                    await $_getPrefetchedData<Unit, $UnitsTable, NutrientData>(
                        currentTable: table,
                        referencedTable:
                            $$UnitsTableReferences._nutrientRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsTableReferences(db, table, p0).nutrientRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.unitCode == item.code),
                        typedResults: items),
                  if (ingredientsRefs)
                    await $_getPrefetchedData<Unit, $UnitsTable, Ingredient>(
                        currentTable: table,
                        referencedTable:
                            $$UnitsTableReferences._ingredientsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsTableReferences(db, table, p0)
                                .ingredientsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.unitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UnitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $UnitsTable,
    Unit,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (Unit, $$UnitsTableReferences),
    Unit,
    PrefetchHooks Function(
        {bool ingredientUnitOverridesRefs,
        bool nutrientsCategorieRefs,
        bool nutrientRefs,
        bool ingredientsRefs})>;
typedef $$UnitConversionsTableCreateCompanionBuilder = UnitConversionsCompanion
    Function({
  required int fromUnitId,
  required int toUnitId,
  required double factor,
  Value<int> rowid,
});
typedef $$UnitConversionsTableUpdateCompanionBuilder = UnitConversionsCompanion
    Function({
  Value<int> fromUnitId,
  Value<int> toUnitId,
  Value<double> factor,
  Value<int> rowid,
});

final class $$UnitConversionsTableReferences
    extends BaseReferences<_$AppDb, $UnitConversionsTable, UnitConversion> {
  $$UnitConversionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UnitsTable _fromUnitIdTable(_$AppDb db) => db.units.createAlias(
      $_aliasNameGenerator(db.unitConversions.fromUnitId, db.units.id));

  $$UnitsTableProcessedTableManager get fromUnitId {
    final $_column = $_itemColumn<int>('from_unit_id')!;

    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromUnitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UnitsTable _toUnitIdTable(_$AppDb db) => db.units.createAlias(
      $_aliasNameGenerator(db.unitConversions.toUnitId, db.units.id));

  $$UnitsTableProcessedTableManager get toUnitId {
    final $_column = $_itemColumn<int>('to_unit_id')!;

    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toUnitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UnitConversionsTableFilterComposer
    extends Composer<_$AppDb, $UnitConversionsTable> {
  $$UnitConversionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get factor => $composableBuilder(
      column: $table.factor, builder: (column) => ColumnFilters(column));

  $$UnitsTableFilterComposer get fromUnitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableFilterComposer get toUnitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UnitConversionsTableOrderingComposer
    extends Composer<_$AppDb, $UnitConversionsTable> {
  $$UnitConversionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get factor => $composableBuilder(
      column: $table.factor, builder: (column) => ColumnOrderings(column));

  $$UnitsTableOrderingComposer get fromUnitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableOrderingComposer get toUnitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UnitConversionsTableAnnotationComposer
    extends Composer<_$AppDb, $UnitConversionsTable> {
  $$UnitConversionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get factor =>
      $composableBuilder(column: $table.factor, builder: (column) => column);

  $$UnitsTableAnnotationComposer get fromUnitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableAnnotationComposer get toUnitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toUnitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UnitConversionsTableTableManager extends RootTableManager<
    _$AppDb,
    $UnitConversionsTable,
    UnitConversion,
    $$UnitConversionsTableFilterComposer,
    $$UnitConversionsTableOrderingComposer,
    $$UnitConversionsTableAnnotationComposer,
    $$UnitConversionsTableCreateCompanionBuilder,
    $$UnitConversionsTableUpdateCompanionBuilder,
    (UnitConversion, $$UnitConversionsTableReferences),
    UnitConversion,
    PrefetchHooks Function({bool fromUnitId, bool toUnitId})> {
  $$UnitConversionsTableTableManager(_$AppDb db, $UnitConversionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitConversionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitConversionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitConversionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> fromUnitId = const Value.absent(),
            Value<int> toUnitId = const Value.absent(),
            Value<double> factor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitConversionsCompanion(
            fromUnitId: fromUnitId,
            toUnitId: toUnitId,
            factor: factor,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int fromUnitId,
            required int toUnitId,
            required double factor,
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitConversionsCompanion.insert(
            fromUnitId: fromUnitId,
            toUnitId: toUnitId,
            factor: factor,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UnitConversionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({fromUnitId = false, toUnitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (fromUnitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fromUnitId,
                    referencedTable:
                        $$UnitConversionsTableReferences._fromUnitIdTable(db),
                    referencedColumn: $$UnitConversionsTableReferences
                        ._fromUnitIdTable(db)
                        .id,
                  ) as T;
                }
                if (toUnitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.toUnitId,
                    referencedTable:
                        $$UnitConversionsTableReferences._toUnitIdTable(db),
                    referencedColumn:
                        $$UnitConversionsTableReferences._toUnitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$UnitConversionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $UnitConversionsTable,
    UnitConversion,
    $$UnitConversionsTableFilterComposer,
    $$UnitConversionsTableOrderingComposer,
    $$UnitConversionsTableAnnotationComposer,
    $$UnitConversionsTableCreateCompanionBuilder,
    $$UnitConversionsTableUpdateCompanionBuilder,
    (UnitConversion, $$UnitConversionsTableReferences),
    UnitConversion,
    PrefetchHooks Function({bool fromUnitId, bool toUnitId})>;
typedef $$IngredientUnitOverridesTableCreateCompanionBuilder
    = IngredientUnitOverridesCompanion Function({
  required int ingredientId,
  required int unitId,
  Value<double?> gramsPerUnit,
  Value<double?> mlPerUnit,
  Value<int> rowid,
});
typedef $$IngredientUnitOverridesTableUpdateCompanionBuilder
    = IngredientUnitOverridesCompanion Function({
  Value<int> ingredientId,
  Value<int> unitId,
  Value<double?> gramsPerUnit,
  Value<double?> mlPerUnit,
  Value<int> rowid,
});

final class $$IngredientUnitOverridesTableReferences extends BaseReferences<
    _$AppDb, $IngredientUnitOverridesTable, IngredientUnitOverride> {
  $$IngredientUnitOverridesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UnitsTable _unitIdTable(_$AppDb db) => db.units.createAlias(
      $_aliasNameGenerator(db.ingredientUnitOverrides.unitId, db.units.id));

  $$UnitsTableProcessedTableManager get unitId {
    final $_column = $_itemColumn<int>('unit_id')!;

    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IngredientUnitOverridesTableFilterComposer
    extends Composer<_$AppDb, $IngredientUnitOverridesTable> {
  $$IngredientUnitOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ingredientId => $composableBuilder(
      column: $table.ingredientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gramsPerUnit => $composableBuilder(
      column: $table.gramsPerUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get mlPerUnit => $composableBuilder(
      column: $table.mlPerUnit, builder: (column) => ColumnFilters(column));

  $$UnitsTableFilterComposer get unitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientUnitOverridesTableOrderingComposer
    extends Composer<_$AppDb, $IngredientUnitOverridesTable> {
  $$IngredientUnitOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ingredientId => $composableBuilder(
      column: $table.ingredientId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gramsPerUnit => $composableBuilder(
      column: $table.gramsPerUnit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get mlPerUnit => $composableBuilder(
      column: $table.mlPerUnit, builder: (column) => ColumnOrderings(column));

  $$UnitsTableOrderingComposer get unitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientUnitOverridesTableAnnotationComposer
    extends Composer<_$AppDb, $IngredientUnitOverridesTable> {
  $$IngredientUnitOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ingredientId => $composableBuilder(
      column: $table.ingredientId, builder: (column) => column);

  GeneratedColumn<double> get gramsPerUnit => $composableBuilder(
      column: $table.gramsPerUnit, builder: (column) => column);

  GeneratedColumn<double> get mlPerUnit =>
      $composableBuilder(column: $table.mlPerUnit, builder: (column) => column);

  $$UnitsTableAnnotationComposer get unitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientUnitOverridesTableTableManager extends RootTableManager<
    _$AppDb,
    $IngredientUnitOverridesTable,
    IngredientUnitOverride,
    $$IngredientUnitOverridesTableFilterComposer,
    $$IngredientUnitOverridesTableOrderingComposer,
    $$IngredientUnitOverridesTableAnnotationComposer,
    $$IngredientUnitOverridesTableCreateCompanionBuilder,
    $$IngredientUnitOverridesTableUpdateCompanionBuilder,
    (IngredientUnitOverride, $$IngredientUnitOverridesTableReferences),
    IngredientUnitOverride,
    PrefetchHooks Function({bool unitId})> {
  $$IngredientUnitOverridesTableTableManager(
      _$AppDb db, $IngredientUnitOverridesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientUnitOverridesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientUnitOverridesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientUnitOverridesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> ingredientId = const Value.absent(),
            Value<int> unitId = const Value.absent(),
            Value<double?> gramsPerUnit = const Value.absent(),
            Value<double?> mlPerUnit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientUnitOverridesCompanion(
            ingredientId: ingredientId,
            unitId: unitId,
            gramsPerUnit: gramsPerUnit,
            mlPerUnit: mlPerUnit,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int ingredientId,
            required int unitId,
            Value<double?> gramsPerUnit = const Value.absent(),
            Value<double?> mlPerUnit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientUnitOverridesCompanion.insert(
            ingredientId: ingredientId,
            unitId: unitId,
            gramsPerUnit: gramsPerUnit,
            mlPerUnit: mlPerUnit,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IngredientUnitOverridesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({unitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (unitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitId,
                    referencedTable: $$IngredientUnitOverridesTableReferences
                        ._unitIdTable(db),
                    referencedColumn: $$IngredientUnitOverridesTableReferences
                        ._unitIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IngredientUnitOverridesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $IngredientUnitOverridesTable,
        IngredientUnitOverride,
        $$IngredientUnitOverridesTableFilterComposer,
        $$IngredientUnitOverridesTableOrderingComposer,
        $$IngredientUnitOverridesTableAnnotationComposer,
        $$IngredientUnitOverridesTableCreateCompanionBuilder,
        $$IngredientUnitOverridesTableUpdateCompanionBuilder,
        (IngredientUnitOverride, $$IngredientUnitOverridesTableReferences),
        IngredientUnitOverride,
        PrefetchHooks Function({bool unitId})>;
typedef $$NutrientsCategorieTableCreateCompanionBuilder
    = NutrientsCategorieCompanion Function({
  Value<int> id,
  required String name,
  required String unitCode,
});
typedef $$NutrientsCategorieTableUpdateCompanionBuilder
    = NutrientsCategorieCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> unitCode,
});

final class $$NutrientsCategorieTableReferences extends BaseReferences<_$AppDb,
    $NutrientsCategorieTable, NutrientsCategorieData> {
  $$NutrientsCategorieTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UnitsTable _unitCodeTable(_$AppDb db) => db.units.createAlias(
      $_aliasNameGenerator(db.nutrientsCategorie.unitCode, db.units.code));

  $$UnitsTableProcessedTableManager get unitCode {
    final $_column = $_itemColumn<String>('unit_code')!;

    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$NutrientTable, List<NutrientData>>
      _nutrientRefsTable(_$AppDb db) =>
          MultiTypedResultKey.fromTable(db.nutrient,
              aliasName: $_aliasNameGenerator(
                  db.nutrientsCategorie.id, db.nutrient.nutrientsCategorieId));

  $$NutrientTableProcessedTableManager get nutrientRefs {
    final manager = $$NutrientTableTableManager($_db, $_db.nutrient).filter(
        (f) => f.nutrientsCategorieId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_nutrientRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$NutrientsCategorieTableFilterComposer
    extends Composer<_$AppDb, $NutrientsCategorieTable> {
  $$NutrientsCategorieTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  $$UnitsTableFilterComposer get unitCode {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitCode,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> nutrientRefs(
      Expression<bool> Function($$NutrientTableFilterComposer f) f) {
    final $$NutrientTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.nutrient,
        getReferencedColumn: (t) => t.nutrientsCategorieId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutrientTableFilterComposer(
              $db: $db,
              $table: $db.nutrient,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$NutrientsCategorieTableOrderingComposer
    extends Composer<_$AppDb, $NutrientsCategorieTable> {
  $$NutrientsCategorieTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  $$UnitsTableOrderingComposer get unitCode {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitCode,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NutrientsCategorieTableAnnotationComposer
    extends Composer<_$AppDb, $NutrientsCategorieTable> {
  $$NutrientsCategorieTableAnnotationComposer({
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

  $$UnitsTableAnnotationComposer get unitCode {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitCode,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> nutrientRefs<T extends Object>(
      Expression<T> Function($$NutrientTableAnnotationComposer a) f) {
    final $$NutrientTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.nutrient,
        getReferencedColumn: (t) => t.nutrientsCategorieId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutrientTableAnnotationComposer(
              $db: $db,
              $table: $db.nutrient,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$NutrientsCategorieTableTableManager extends RootTableManager<
    _$AppDb,
    $NutrientsCategorieTable,
    NutrientsCategorieData,
    $$NutrientsCategorieTableFilterComposer,
    $$NutrientsCategorieTableOrderingComposer,
    $$NutrientsCategorieTableAnnotationComposer,
    $$NutrientsCategorieTableCreateCompanionBuilder,
    $$NutrientsCategorieTableUpdateCompanionBuilder,
    (NutrientsCategorieData, $$NutrientsCategorieTableReferences),
    NutrientsCategorieData,
    PrefetchHooks Function({bool unitCode, bool nutrientRefs})> {
  $$NutrientsCategorieTableTableManager(
      _$AppDb db, $NutrientsCategorieTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutrientsCategorieTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutrientsCategorieTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutrientsCategorieTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> unitCode = const Value.absent(),
          }) =>
              NutrientsCategorieCompanion(
            id: id,
            name: name,
            unitCode: unitCode,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String unitCode,
          }) =>
              NutrientsCategorieCompanion.insert(
            id: id,
            name: name,
            unitCode: unitCode,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NutrientsCategorieTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({unitCode = false, nutrientRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (nutrientRefs) db.nutrient],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (unitCode) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitCode,
                    referencedTable:
                        $$NutrientsCategorieTableReferences._unitCodeTable(db),
                    referencedColumn: $$NutrientsCategorieTableReferences
                        ._unitCodeTable(db)
                        .code,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (nutrientRefs)
                    await $_getPrefetchedData<NutrientsCategorieData,
                            $NutrientsCategorieTable, NutrientData>(
                        currentTable: table,
                        referencedTable: $$NutrientsCategorieTableReferences
                            ._nutrientRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NutrientsCategorieTableReferences(db, table, p0)
                                .nutrientRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) => e.nutrientsCategorieId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$NutrientsCategorieTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $NutrientsCategorieTable,
    NutrientsCategorieData,
    $$NutrientsCategorieTableFilterComposer,
    $$NutrientsCategorieTableOrderingComposer,
    $$NutrientsCategorieTableAnnotationComposer,
    $$NutrientsCategorieTableCreateCompanionBuilder,
    $$NutrientsCategorieTableUpdateCompanionBuilder,
    (NutrientsCategorieData, $$NutrientsCategorieTableReferences),
    NutrientsCategorieData,
    PrefetchHooks Function({bool unitCode, bool nutrientRefs})>;
typedef $$NutrientTableCreateCompanionBuilder = NutrientCompanion Function({
  Value<int> id,
  required String name,
  required int nutrientsCategorieId,
  required String unitCode,
  Value<String?> picture,
  Value<String?> color,
});
typedef $$NutrientTableUpdateCompanionBuilder = NutrientCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> nutrientsCategorieId,
  Value<String> unitCode,
  Value<String?> picture,
  Value<String?> color,
});

final class $$NutrientTableReferences
    extends BaseReferences<_$AppDb, $NutrientTable, NutrientData> {
  $$NutrientTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NutrientsCategorieTable _nutrientsCategorieIdTable(_$AppDb db) =>
      db.nutrientsCategorie.createAlias($_aliasNameGenerator(
          db.nutrient.nutrientsCategorieId, db.nutrientsCategorie.id));

  $$NutrientsCategorieTableProcessedTableManager get nutrientsCategorieId {
    final $_column = $_itemColumn<int>('nutrients_categorie_id')!;

    final manager =
        $$NutrientsCategorieTableTableManager($_db, $_db.nutrientsCategorie)
            .filter((f) => f.id.sqlEquals($_column));
    final item =
        $_typedResult.readTableOrNull(_nutrientsCategorieIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UnitsTable _unitCodeTable(_$AppDb db) => db.units
      .createAlias($_aliasNameGenerator(db.nutrient.unitCode, db.units.code));

  $$UnitsTableProcessedTableManager get unitCode {
    final $_column = $_itemColumn<String>('unit_code')!;

    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$IngredientNutrientsTable,
      List<IngredientNutrient>> _ingredientNutrientsRefsTable(
          _$AppDb db) =>
      MultiTypedResultKey.fromTable(db.ingredientNutrients,
          aliasName: $_aliasNameGenerator(
              db.nutrient.id, db.ingredientNutrients.nutrientId));

  $$IngredientNutrientsTableProcessedTableManager get ingredientNutrientsRefs {
    final manager =
        $$IngredientNutrientsTableTableManager($_db, $_db.ingredientNutrients)
            .filter((f) => f.nutrientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientNutrientsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$NutrientTableFilterComposer extends Composer<_$AppDb, $NutrientTable> {
  $$NutrientTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get picture => $composableBuilder(
      column: $table.picture, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  $$NutrientsCategorieTableFilterComposer get nutrientsCategorieId {
    final $$NutrientsCategorieTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.nutrientsCategorieId,
        referencedTable: $db.nutrientsCategorie,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutrientsCategorieTableFilterComposer(
              $db: $db,
              $table: $db.nutrientsCategorie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableFilterComposer get unitCode {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitCode,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> ingredientNutrientsRefs(
      Expression<bool> Function($$IngredientNutrientsTableFilterComposer f) f) {
    final $$IngredientNutrientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredientNutrients,
        getReferencedColumn: (t) => t.nutrientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientNutrientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredientNutrients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$NutrientTableOrderingComposer
    extends Composer<_$AppDb, $NutrientTable> {
  $$NutrientTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get picture => $composableBuilder(
      column: $table.picture, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  $$NutrientsCategorieTableOrderingComposer get nutrientsCategorieId {
    final $$NutrientsCategorieTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.nutrientsCategorieId,
        referencedTable: $db.nutrientsCategorie,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutrientsCategorieTableOrderingComposer(
              $db: $db,
              $table: $db.nutrientsCategorie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableOrderingComposer get unitCode {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitCode,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NutrientTableAnnotationComposer
    extends Composer<_$AppDb, $NutrientTable> {
  $$NutrientTableAnnotationComposer({
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

  GeneratedColumn<String> get picture =>
      $composableBuilder(column: $table.picture, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  $$NutrientsCategorieTableAnnotationComposer get nutrientsCategorieId {
    final $$NutrientsCategorieTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.nutrientsCategorieId,
            referencedTable: $db.nutrientsCategorie,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NutrientsCategorieTableAnnotationComposer(
                  $db: $db,
                  $table: $db.nutrientsCategorie,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$UnitsTableAnnotationComposer get unitCode {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitCode,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.code,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> ingredientNutrientsRefs<T extends Object>(
      Expression<T> Function($$IngredientNutrientsTableAnnotationComposer a)
          f) {
    final $$IngredientNutrientsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientNutrients,
            getReferencedColumn: (t) => t.nutrientId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientNutrientsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientNutrients,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$NutrientTableTableManager extends RootTableManager<
    _$AppDb,
    $NutrientTable,
    NutrientData,
    $$NutrientTableFilterComposer,
    $$NutrientTableOrderingComposer,
    $$NutrientTableAnnotationComposer,
    $$NutrientTableCreateCompanionBuilder,
    $$NutrientTableUpdateCompanionBuilder,
    (NutrientData, $$NutrientTableReferences),
    NutrientData,
    PrefetchHooks Function(
        {bool nutrientsCategorieId,
        bool unitCode,
        bool ingredientNutrientsRefs})> {
  $$NutrientTableTableManager(_$AppDb db, $NutrientTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutrientTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutrientTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutrientTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> nutrientsCategorieId = const Value.absent(),
            Value<String> unitCode = const Value.absent(),
            Value<String?> picture = const Value.absent(),
            Value<String?> color = const Value.absent(),
          }) =>
              NutrientCompanion(
            id: id,
            name: name,
            nutrientsCategorieId: nutrientsCategorieId,
            unitCode: unitCode,
            picture: picture,
            color: color,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int nutrientsCategorieId,
            required String unitCode,
            Value<String?> picture = const Value.absent(),
            Value<String?> color = const Value.absent(),
          }) =>
              NutrientCompanion.insert(
            id: id,
            name: name,
            nutrientsCategorieId: nutrientsCategorieId,
            unitCode: unitCode,
            picture: picture,
            color: color,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$NutrientTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {nutrientsCategorieId = false,
              unitCode = false,
              ingredientNutrientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ingredientNutrientsRefs) db.ingredientNutrients
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (nutrientsCategorieId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.nutrientsCategorieId,
                    referencedTable: $$NutrientTableReferences
                        ._nutrientsCategorieIdTable(db),
                    referencedColumn: $$NutrientTableReferences
                        ._nutrientsCategorieIdTable(db)
                        .id,
                  ) as T;
                }
                if (unitCode) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitCode,
                    referencedTable:
                        $$NutrientTableReferences._unitCodeTable(db),
                    referencedColumn:
                        $$NutrientTableReferences._unitCodeTable(db).code,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientNutrientsRefs)
                    await $_getPrefetchedData<NutrientData, $NutrientTable,
                            IngredientNutrient>(
                        currentTable: table,
                        referencedTable: $$NutrientTableReferences
                            ._ingredientNutrientsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NutrientTableReferences(db, table, p0)
                                .ingredientNutrientsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.nutrientId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$NutrientTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $NutrientTable,
    NutrientData,
    $$NutrientTableFilterComposer,
    $$NutrientTableOrderingComposer,
    $$NutrientTableAnnotationComposer,
    $$NutrientTableCreateCompanionBuilder,
    $$NutrientTableUpdateCompanionBuilder,
    (NutrientData, $$NutrientTableReferences),
    NutrientData,
    PrefetchHooks Function(
        {bool nutrientsCategorieId,
        bool unitCode,
        bool ingredientNutrientsRefs})>;
typedef $$IngredientCategoriesTableCreateCompanionBuilder
    = IngredientCategoriesCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> image,
});
typedef $$IngredientCategoriesTableUpdateCompanionBuilder
    = IngredientCategoriesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> image,
});

final class $$IngredientCategoriesTableReferences extends BaseReferences<
    _$AppDb, $IngredientCategoriesTable, IngredientCategory> {
  $$IngredientCategoriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IngredientsTable, List<Ingredient>>
      _ingredientsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
          db.ingredients,
          aliasName: $_aliasNameGenerator(
              db.ingredientCategories.id, db.ingredients.ingredientCategoryId));

  $$IngredientsTableProcessedTableManager get ingredientsRefs {
    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) =>
            f.ingredientCategoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ingredientsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$IngredientCategoriesTableFilterComposer
    extends Composer<_$AppDb, $IngredientCategoriesTable> {
  $$IngredientCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnFilters(column));

  Expression<bool> ingredientsRefs(
      Expression<bool> Function($$IngredientsTableFilterComposer f) f) {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.ingredientCategoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$IngredientCategoriesTableOrderingComposer
    extends Composer<_$AppDb, $IngredientCategoriesTable> {
  $$IngredientCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnOrderings(column));
}

class $$IngredientCategoriesTableAnnotationComposer
    extends Composer<_$AppDb, $IngredientCategoriesTable> {
  $$IngredientCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  Expression<T> ingredientsRefs<T extends Object>(
      Expression<T> Function($$IngredientsTableAnnotationComposer a) f) {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.ingredientCategoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$IngredientCategoriesTableTableManager extends RootTableManager<
    _$AppDb,
    $IngredientCategoriesTable,
    IngredientCategory,
    $$IngredientCategoriesTableFilterComposer,
    $$IngredientCategoriesTableOrderingComposer,
    $$IngredientCategoriesTableAnnotationComposer,
    $$IngredientCategoriesTableCreateCompanionBuilder,
    $$IngredientCategoriesTableUpdateCompanionBuilder,
    (IngredientCategory, $$IngredientCategoriesTableReferences),
    IngredientCategory,
    PrefetchHooks Function({bool ingredientsRefs})> {
  $$IngredientCategoriesTableTableManager(
      _$AppDb db, $IngredientCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientCategoriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientCategoriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> image = const Value.absent(),
          }) =>
              IngredientCategoriesCompanion(
            id: id,
            title: title,
            image: image,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> image = const Value.absent(),
          }) =>
              IngredientCategoriesCompanion.insert(
            id: id,
            title: title,
            image: image,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IngredientCategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({ingredientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ingredientsRefs) db.ingredients],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientsRefs)
                    await $_getPrefetchedData<IngredientCategory,
                            $IngredientCategoriesTable, Ingredient>(
                        currentTable: table,
                        referencedTable: $$IngredientCategoriesTableReferences
                            ._ingredientsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientCategoriesTableReferences(db, table, p0)
                                .ingredientsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) => e.ingredientCategoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$IngredientCategoriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $IngredientCategoriesTable,
        IngredientCategory,
        $$IngredientCategoriesTableFilterComposer,
        $$IngredientCategoriesTableOrderingComposer,
        $$IngredientCategoriesTableAnnotationComposer,
        $$IngredientCategoriesTableCreateCompanionBuilder,
        $$IngredientCategoriesTableUpdateCompanionBuilder,
        (IngredientCategory, $$IngredientCategoriesTableReferences),
        IngredientCategory,
        PrefetchHooks Function({bool ingredientsRefs})>;
typedef $$IngredientPropertiesTableCreateCompanionBuilder
    = IngredientPropertiesCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$IngredientPropertiesTableUpdateCompanionBuilder
    = IngredientPropertiesCompanion Function({
  Value<int> id,
  Value<String> name,
});

class $$IngredientPropertiesTableFilterComposer
    extends Composer<_$AppDb, $IngredientPropertiesTable> {
  $$IngredientPropertiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));
}

class $$IngredientPropertiesTableOrderingComposer
    extends Composer<_$AppDb, $IngredientPropertiesTable> {
  $$IngredientPropertiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$IngredientPropertiesTableAnnotationComposer
    extends Composer<_$AppDb, $IngredientPropertiesTable> {
  $$IngredientPropertiesTableAnnotationComposer({
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
}

class $$IngredientPropertiesTableTableManager extends RootTableManager<
    _$AppDb,
    $IngredientPropertiesTable,
    IngredientProperty,
    $$IngredientPropertiesTableFilterComposer,
    $$IngredientPropertiesTableOrderingComposer,
    $$IngredientPropertiesTableAnnotationComposer,
    $$IngredientPropertiesTableCreateCompanionBuilder,
    $$IngredientPropertiesTableUpdateCompanionBuilder,
    (
      IngredientProperty,
      BaseReferences<_$AppDb, $IngredientPropertiesTable, IngredientProperty>
    ),
    IngredientProperty,
    PrefetchHooks Function()> {
  $$IngredientPropertiesTableTableManager(
      _$AppDb db, $IngredientPropertiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientPropertiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientPropertiesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientPropertiesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              IngredientPropertiesCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              IngredientPropertiesCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IngredientPropertiesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $IngredientPropertiesTable,
        IngredientProperty,
        $$IngredientPropertiesTableFilterComposer,
        $$IngredientPropertiesTableOrderingComposer,
        $$IngredientPropertiesTableAnnotationComposer,
        $$IngredientPropertiesTableCreateCompanionBuilder,
        $$IngredientPropertiesTableUpdateCompanionBuilder,
        (
          IngredientProperty,
          BaseReferences<_$AppDb, $IngredientPropertiesTable,
              IngredientProperty>
        ),
        IngredientProperty,
        PrefetchHooks Function()>;
typedef $$IngredientsTableCreateCompanionBuilder = IngredientsCompanion
    Function({
  Value<int> id,
  required String name,
  required int ingredientCategoryId,
  Value<int?> unitId,
  Value<String?> picture,
});
typedef $$IngredientsTableUpdateCompanionBuilder = IngredientsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<int> ingredientCategoryId,
  Value<int?> unitId,
  Value<String?> picture,
});

final class $$IngredientsTableReferences
    extends BaseReferences<_$AppDb, $IngredientsTable, Ingredient> {
  $$IngredientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $IngredientCategoriesTable _ingredientCategoryIdTable(_$AppDb db) =>
      db.ingredientCategories.createAlias($_aliasNameGenerator(
          db.ingredients.ingredientCategoryId, db.ingredientCategories.id));

  $$IngredientCategoriesTableProcessedTableManager get ingredientCategoryId {
    final $_column = $_itemColumn<int>('ingredient_category_id')!;

    final manager =
        $$IngredientCategoriesTableTableManager($_db, $_db.ingredientCategories)
            .filter((f) => f.id.sqlEquals($_column));
    final item =
        $_typedResult.readTableOrNull(_ingredientCategoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UnitsTable _unitIdTable(_$AppDb db) => db.units
      .createAlias($_aliasNameGenerator(db.ingredients.unitId, db.units.id));

  $$UnitsTableProcessedTableManager? get unitId {
    final $_column = $_itemColumn<int>('unit_id');
    if ($_column == null) return null;
    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$IngredientNutrientsTable,
      List<IngredientNutrient>> _ingredientNutrientsRefsTable(
          _$AppDb db) =>
      MultiTypedResultKey.fromTable(db.ingredientNutrients,
          aliasName: $_aliasNameGenerator(
              db.ingredients.id, db.ingredientNutrients.ingredientId));

  $$IngredientNutrientsTableProcessedTableManager get ingredientNutrientsRefs {
    final manager = $$IngredientNutrientsTableTableManager(
            $_db, $_db.ingredientNutrients)
        .filter((f) => f.ingredientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientNutrientsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IngredientSeasonalityTable,
      List<IngredientSeasonalityData>> _ingredientSeasonalityRefsTable(
          _$AppDb db) =>
      MultiTypedResultKey.fromTable(db.ingredientSeasonality,
          aliasName: $_aliasNameGenerator(
              db.ingredients.id, db.ingredientSeasonality.ingredientsId));

  $$IngredientSeasonalityTableProcessedTableManager
      get ingredientSeasonalityRefs {
    final manager = $$IngredientSeasonalityTableTableManager(
            $_db, $_db.ingredientSeasonality)
        .filter((f) => f.ingredientsId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientSeasonalityRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$IngredientsTableFilterComposer
    extends Composer<_$AppDb, $IngredientsTable> {
  $$IngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get picture => $composableBuilder(
      column: $table.picture, builder: (column) => ColumnFilters(column));

  $$IngredientCategoriesTableFilterComposer get ingredientCategoryId {
    final $$IngredientCategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientCategoryId,
        referencedTable: $db.ingredientCategories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientCategoriesTableFilterComposer(
              $db: $db,
              $table: $db.ingredientCategories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableFilterComposer get unitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> ingredientNutrientsRefs(
      Expression<bool> Function($$IngredientNutrientsTableFilterComposer f) f) {
    final $$IngredientNutrientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredientNutrients,
        getReferencedColumn: (t) => t.ingredientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientNutrientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredientNutrients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ingredientSeasonalityRefs(
      Expression<bool> Function($$IngredientSeasonalityTableFilterComposer f)
          f) {
    final $$IngredientSeasonalityTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientSeasonality,
            getReferencedColumn: (t) => t.ingredientsId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientSeasonalityTableFilterComposer(
                  $db: $db,
                  $table: $db.ingredientSeasonality,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$IngredientsTableOrderingComposer
    extends Composer<_$AppDb, $IngredientsTable> {
  $$IngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get picture => $composableBuilder(
      column: $table.picture, builder: (column) => ColumnOrderings(column));

  $$IngredientCategoriesTableOrderingComposer get ingredientCategoryId {
    final $$IngredientCategoriesTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.ingredientCategoryId,
            referencedTable: $db.ingredientCategories,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientCategoriesTableOrderingComposer(
                  $db: $db,
                  $table: $db.ingredientCategories,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$UnitsTableOrderingComposer get unitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientsTableAnnotationComposer
    extends Composer<_$AppDb, $IngredientsTable> {
  $$IngredientsTableAnnotationComposer({
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

  GeneratedColumn<String> get picture =>
      $composableBuilder(column: $table.picture, builder: (column) => column);

  $$IngredientCategoriesTableAnnotationComposer get ingredientCategoryId {
    final $$IngredientCategoriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.ingredientCategoryId,
            referencedTable: $db.ingredientCategories,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientCategoriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientCategories,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$UnitsTableAnnotationComposer get unitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> ingredientNutrientsRefs<T extends Object>(
      Expression<T> Function($$IngredientNutrientsTableAnnotationComposer a)
          f) {
    final $$IngredientNutrientsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientNutrients,
            getReferencedColumn: (t) => t.ingredientId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientNutrientsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientNutrients,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> ingredientSeasonalityRefs<T extends Object>(
      Expression<T> Function($$IngredientSeasonalityTableAnnotationComposer a)
          f) {
    final $$IngredientSeasonalityTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientSeasonality,
            getReferencedColumn: (t) => t.ingredientsId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientSeasonalityTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientSeasonality,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$IngredientsTableTableManager extends RootTableManager<
    _$AppDb,
    $IngredientsTable,
    Ingredient,
    $$IngredientsTableFilterComposer,
    $$IngredientsTableOrderingComposer,
    $$IngredientsTableAnnotationComposer,
    $$IngredientsTableCreateCompanionBuilder,
    $$IngredientsTableUpdateCompanionBuilder,
    (Ingredient, $$IngredientsTableReferences),
    Ingredient,
    PrefetchHooks Function(
        {bool ingredientCategoryId,
        bool unitId,
        bool ingredientNutrientsRefs,
        bool ingredientSeasonalityRefs})> {
  $$IngredientsTableTableManager(_$AppDb db, $IngredientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> ingredientCategoryId = const Value.absent(),
            Value<int?> unitId = const Value.absent(),
            Value<String?> picture = const Value.absent(),
          }) =>
              IngredientsCompanion(
            id: id,
            name: name,
            ingredientCategoryId: ingredientCategoryId,
            unitId: unitId,
            picture: picture,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int ingredientCategoryId,
            Value<int?> unitId = const Value.absent(),
            Value<String?> picture = const Value.absent(),
          }) =>
              IngredientsCompanion.insert(
            id: id,
            name: name,
            ingredientCategoryId: ingredientCategoryId,
            unitId: unitId,
            picture: picture,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IngredientsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {ingredientCategoryId = false,
              unitId = false,
              ingredientNutrientsRefs = false,
              ingredientSeasonalityRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ingredientNutrientsRefs) db.ingredientNutrients,
                if (ingredientSeasonalityRefs) db.ingredientSeasonality
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (ingredientCategoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ingredientCategoryId,
                    referencedTable: $$IngredientsTableReferences
                        ._ingredientCategoryIdTable(db),
                    referencedColumn: $$IngredientsTableReferences
                        ._ingredientCategoryIdTable(db)
                        .id,
                  ) as T;
                }
                if (unitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitId,
                    referencedTable:
                        $$IngredientsTableReferences._unitIdTable(db),
                    referencedColumn:
                        $$IngredientsTableReferences._unitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientNutrientsRefs)
                    await $_getPrefetchedData<Ingredient, $IngredientsTable, IngredientNutrient>(
                        currentTable: table,
                        referencedTable: $$IngredientsTableReferences
                            ._ingredientNutrientsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientsTableReferences(db, table, p0)
                                .ingredientNutrientsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.ingredientId == item.id),
                        typedResults: items),
                  if (ingredientSeasonalityRefs)
                    await $_getPrefetchedData<Ingredient, $IngredientsTable,
                            IngredientSeasonalityData>(
                        currentTable: table,
                        referencedTable: $$IngredientsTableReferences
                            ._ingredientSeasonalityRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientsTableReferences(db, table, p0)
                                .ingredientSeasonalityRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.ingredientsId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$IngredientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $IngredientsTable,
    Ingredient,
    $$IngredientsTableFilterComposer,
    $$IngredientsTableOrderingComposer,
    $$IngredientsTableAnnotationComposer,
    $$IngredientsTableCreateCompanionBuilder,
    $$IngredientsTableUpdateCompanionBuilder,
    (Ingredient, $$IngredientsTableReferences),
    Ingredient,
    PrefetchHooks Function(
        {bool ingredientCategoryId,
        bool unitId,
        bool ingredientNutrientsRefs,
        bool ingredientSeasonalityRefs})>;
typedef $$IngredientNutrientsTableCreateCompanionBuilder
    = IngredientNutrientsCompanion Function({
  Value<int> id,
  required int ingredientId,
  required int nutrientId,
  required double amount,
});
typedef $$IngredientNutrientsTableUpdateCompanionBuilder
    = IngredientNutrientsCompanion Function({
  Value<int> id,
  Value<int> ingredientId,
  Value<int> nutrientId,
  Value<double> amount,
});

final class $$IngredientNutrientsTableReferences extends BaseReferences<_$AppDb,
    $IngredientNutrientsTable, IngredientNutrient> {
  $$IngredientNutrientsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $IngredientsTable _ingredientIdTable(_$AppDb db) =>
      db.ingredients.createAlias($_aliasNameGenerator(
          db.ingredientNutrients.ingredientId, db.ingredients.id));

  $$IngredientsTableProcessedTableManager get ingredientId {
    final $_column = $_itemColumn<int>('ingredient_id')!;

    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $NutrientTable _nutrientIdTable(_$AppDb db) => db.nutrient.createAlias(
      $_aliasNameGenerator(db.ingredientNutrients.nutrientId, db.nutrient.id));

  $$NutrientTableProcessedTableManager get nutrientId {
    final $_column = $_itemColumn<int>('nutrient_id')!;

    final manager = $$NutrientTableTableManager($_db, $_db.nutrient)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nutrientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IngredientNutrientsTableFilterComposer
    extends Composer<_$AppDb, $IngredientNutrientsTable> {
  $$IngredientNutrientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  $$IngredientsTableFilterComposer get ingredientId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$NutrientTableFilterComposer get nutrientId {
    final $$NutrientTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.nutrientId,
        referencedTable: $db.nutrient,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutrientTableFilterComposer(
              $db: $db,
              $table: $db.nutrient,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientNutrientsTableOrderingComposer
    extends Composer<_$AppDb, $IngredientNutrientsTable> {
  $$IngredientNutrientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  $$IngredientsTableOrderingComposer get ingredientId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableOrderingComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$NutrientTableOrderingComposer get nutrientId {
    final $$NutrientTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.nutrientId,
        referencedTable: $db.nutrient,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutrientTableOrderingComposer(
              $db: $db,
              $table: $db.nutrient,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientNutrientsTableAnnotationComposer
    extends Composer<_$AppDb, $IngredientNutrientsTable> {
  $$IngredientNutrientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  $$IngredientsTableAnnotationComposer get ingredientId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$NutrientTableAnnotationComposer get nutrientId {
    final $$NutrientTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.nutrientId,
        referencedTable: $db.nutrient,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NutrientTableAnnotationComposer(
              $db: $db,
              $table: $db.nutrient,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientNutrientsTableTableManager extends RootTableManager<
    _$AppDb,
    $IngredientNutrientsTable,
    IngredientNutrient,
    $$IngredientNutrientsTableFilterComposer,
    $$IngredientNutrientsTableOrderingComposer,
    $$IngredientNutrientsTableAnnotationComposer,
    $$IngredientNutrientsTableCreateCompanionBuilder,
    $$IngredientNutrientsTableUpdateCompanionBuilder,
    (IngredientNutrient, $$IngredientNutrientsTableReferences),
    IngredientNutrient,
    PrefetchHooks Function({bool ingredientId, bool nutrientId})> {
  $$IngredientNutrientsTableTableManager(
      _$AppDb db, $IngredientNutrientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientNutrientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientNutrientsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientNutrientsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> ingredientId = const Value.absent(),
            Value<int> nutrientId = const Value.absent(),
            Value<double> amount = const Value.absent(),
          }) =>
              IngredientNutrientsCompanion(
            id: id,
            ingredientId: ingredientId,
            nutrientId: nutrientId,
            amount: amount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int ingredientId,
            required int nutrientId,
            required double amount,
          }) =>
              IngredientNutrientsCompanion.insert(
            id: id,
            ingredientId: ingredientId,
            nutrientId: nutrientId,
            amount: amount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IngredientNutrientsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({ingredientId = false, nutrientId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (ingredientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ingredientId,
                    referencedTable: $$IngredientNutrientsTableReferences
                        ._ingredientIdTable(db),
                    referencedColumn: $$IngredientNutrientsTableReferences
                        ._ingredientIdTable(db)
                        .id,
                  ) as T;
                }
                if (nutrientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.nutrientId,
                    referencedTable: $$IngredientNutrientsTableReferences
                        ._nutrientIdTable(db),
                    referencedColumn: $$IngredientNutrientsTableReferences
                        ._nutrientIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IngredientNutrientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $IngredientNutrientsTable,
    IngredientNutrient,
    $$IngredientNutrientsTableFilterComposer,
    $$IngredientNutrientsTableOrderingComposer,
    $$IngredientNutrientsTableAnnotationComposer,
    $$IngredientNutrientsTableCreateCompanionBuilder,
    $$IngredientNutrientsTableUpdateCompanionBuilder,
    (IngredientNutrient, $$IngredientNutrientsTableReferences),
    IngredientNutrient,
    PrefetchHooks Function({bool ingredientId, bool nutrientId})>;
typedef $$SeasonalityTableCreateCompanionBuilder = SeasonalityCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String?> color,
});
typedef $$SeasonalityTableUpdateCompanionBuilder = SeasonalityCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String?> color,
});

final class $$SeasonalityTableReferences
    extends BaseReferences<_$AppDb, $SeasonalityTable, SeasonalityData> {
  $$SeasonalityTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IngredientSeasonalityTable,
      List<IngredientSeasonalityData>> _ingredientSeasonalityRefsTable(
          _$AppDb db) =>
      MultiTypedResultKey.fromTable(db.ingredientSeasonality,
          aliasName: $_aliasNameGenerator(
              db.seasonality.id, db.ingredientSeasonality.seasonalityId));

  $$IngredientSeasonalityTableProcessedTableManager
      get ingredientSeasonalityRefs {
    final manager = $$IngredientSeasonalityTableTableManager(
            $_db, $_db.ingredientSeasonality)
        .filter((f) => f.seasonalityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientSeasonalityRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SeasonalityTableFilterComposer
    extends Composer<_$AppDb, $SeasonalityTable> {
  $$SeasonalityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  Expression<bool> ingredientSeasonalityRefs(
      Expression<bool> Function($$IngredientSeasonalityTableFilterComposer f)
          f) {
    final $$IngredientSeasonalityTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientSeasonality,
            getReferencedColumn: (t) => t.seasonalityId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientSeasonalityTableFilterComposer(
                  $db: $db,
                  $table: $db.ingredientSeasonality,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SeasonalityTableOrderingComposer
    extends Composer<_$AppDb, $SeasonalityTable> {
  $$SeasonalityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));
}

class $$SeasonalityTableAnnotationComposer
    extends Composer<_$AppDb, $SeasonalityTable> {
  $$SeasonalityTableAnnotationComposer({
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

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  Expression<T> ingredientSeasonalityRefs<T extends Object>(
      Expression<T> Function($$IngredientSeasonalityTableAnnotationComposer a)
          f) {
    final $$IngredientSeasonalityTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientSeasonality,
            getReferencedColumn: (t) => t.seasonalityId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientSeasonalityTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientSeasonality,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SeasonalityTableTableManager extends RootTableManager<
    _$AppDb,
    $SeasonalityTable,
    SeasonalityData,
    $$SeasonalityTableFilterComposer,
    $$SeasonalityTableOrderingComposer,
    $$SeasonalityTableAnnotationComposer,
    $$SeasonalityTableCreateCompanionBuilder,
    $$SeasonalityTableUpdateCompanionBuilder,
    (SeasonalityData, $$SeasonalityTableReferences),
    SeasonalityData,
    PrefetchHooks Function({bool ingredientSeasonalityRefs})> {
  $$SeasonalityTableTableManager(_$AppDb db, $SeasonalityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeasonalityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeasonalityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeasonalityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> color = const Value.absent(),
          }) =>
              SeasonalityCompanion(
            id: id,
            name: name,
            color: color,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> color = const Value.absent(),
          }) =>
              SeasonalityCompanion.insert(
            id: id,
            name: name,
            color: color,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SeasonalityTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({ingredientSeasonalityRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ingredientSeasonalityRefs) db.ingredientSeasonality
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientSeasonalityRefs)
                    await $_getPrefetchedData<SeasonalityData,
                            $SeasonalityTable, IngredientSeasonalityData>(
                        currentTable: table,
                        referencedTable: $$SeasonalityTableReferences
                            ._ingredientSeasonalityRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SeasonalityTableReferences(db, table, p0)
                                .ingredientSeasonalityRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.seasonalityId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SeasonalityTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $SeasonalityTable,
    SeasonalityData,
    $$SeasonalityTableFilterComposer,
    $$SeasonalityTableOrderingComposer,
    $$SeasonalityTableAnnotationComposer,
    $$SeasonalityTableCreateCompanionBuilder,
    $$SeasonalityTableUpdateCompanionBuilder,
    (SeasonalityData, $$SeasonalityTableReferences),
    SeasonalityData,
    PrefetchHooks Function({bool ingredientSeasonalityRefs})>;
typedef $$IngredientSeasonalityTableCreateCompanionBuilder
    = IngredientSeasonalityCompanion Function({
  required int ingredientsId,
  required int monthsId,
  required int seasonalityId,
  Value<int> rowid,
});
typedef $$IngredientSeasonalityTableUpdateCompanionBuilder
    = IngredientSeasonalityCompanion Function({
  Value<int> ingredientsId,
  Value<int> monthsId,
  Value<int> seasonalityId,
  Value<int> rowid,
});

final class $$IngredientSeasonalityTableReferences extends BaseReferences<
    _$AppDb, $IngredientSeasonalityTable, IngredientSeasonalityData> {
  $$IngredientSeasonalityTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $IngredientsTable _ingredientsIdTable(_$AppDb db) =>
      db.ingredients.createAlias($_aliasNameGenerator(
          db.ingredientSeasonality.ingredientsId, db.ingredients.id));

  $$IngredientsTableProcessedTableManager get ingredientsId {
    final $_column = $_itemColumn<int>('ingredients_id')!;

    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientsIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $MonthsTable _monthsIdTable(_$AppDb db) => db.months.createAlias(
      $_aliasNameGenerator(db.ingredientSeasonality.monthsId, db.months.id));

  $$MonthsTableProcessedTableManager get monthsId {
    final $_column = $_itemColumn<int>('months_id')!;

    final manager = $$MonthsTableTableManager($_db, $_db.months)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_monthsIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SeasonalityTable _seasonalityIdTable(_$AppDb db) =>
      db.seasonality.createAlias($_aliasNameGenerator(
          db.ingredientSeasonality.seasonalityId, db.seasonality.id));

  $$SeasonalityTableProcessedTableManager get seasonalityId {
    final $_column = $_itemColumn<int>('seasonality_id')!;

    final manager = $$SeasonalityTableTableManager($_db, $_db.seasonality)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seasonalityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IngredientSeasonalityTableFilterComposer
    extends Composer<_$AppDb, $IngredientSeasonalityTable> {
  $$IngredientSeasonalityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$IngredientsTableFilterComposer get ingredientsId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientsId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MonthsTableFilterComposer get monthsId {
    final $$MonthsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.monthsId,
        referencedTable: $db.months,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MonthsTableFilterComposer(
              $db: $db,
              $table: $db.months,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SeasonalityTableFilterComposer get seasonalityId {
    final $$SeasonalityTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seasonalityId,
        referencedTable: $db.seasonality,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeasonalityTableFilterComposer(
              $db: $db,
              $table: $db.seasonality,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientSeasonalityTableOrderingComposer
    extends Composer<_$AppDb, $IngredientSeasonalityTable> {
  $$IngredientSeasonalityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$IngredientsTableOrderingComposer get ingredientsId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientsId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableOrderingComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MonthsTableOrderingComposer get monthsId {
    final $$MonthsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.monthsId,
        referencedTable: $db.months,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MonthsTableOrderingComposer(
              $db: $db,
              $table: $db.months,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SeasonalityTableOrderingComposer get seasonalityId {
    final $$SeasonalityTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seasonalityId,
        referencedTable: $db.seasonality,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeasonalityTableOrderingComposer(
              $db: $db,
              $table: $db.seasonality,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientSeasonalityTableAnnotationComposer
    extends Composer<_$AppDb, $IngredientSeasonalityTable> {
  $$IngredientSeasonalityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$IngredientsTableAnnotationComposer get ingredientsId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientsId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MonthsTableAnnotationComposer get monthsId {
    final $$MonthsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.monthsId,
        referencedTable: $db.months,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MonthsTableAnnotationComposer(
              $db: $db,
              $table: $db.months,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SeasonalityTableAnnotationComposer get seasonalityId {
    final $$SeasonalityTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seasonalityId,
        referencedTable: $db.seasonality,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeasonalityTableAnnotationComposer(
              $db: $db,
              $table: $db.seasonality,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientSeasonalityTableTableManager extends RootTableManager<
    _$AppDb,
    $IngredientSeasonalityTable,
    IngredientSeasonalityData,
    $$IngredientSeasonalityTableFilterComposer,
    $$IngredientSeasonalityTableOrderingComposer,
    $$IngredientSeasonalityTableAnnotationComposer,
    $$IngredientSeasonalityTableCreateCompanionBuilder,
    $$IngredientSeasonalityTableUpdateCompanionBuilder,
    (IngredientSeasonalityData, $$IngredientSeasonalityTableReferences),
    IngredientSeasonalityData,
    PrefetchHooks Function(
        {bool ingredientsId, bool monthsId, bool seasonalityId})> {
  $$IngredientSeasonalityTableTableManager(
      _$AppDb db, $IngredientSeasonalityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientSeasonalityTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientSeasonalityTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientSeasonalityTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> ingredientsId = const Value.absent(),
            Value<int> monthsId = const Value.absent(),
            Value<int> seasonalityId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientSeasonalityCompanion(
            ingredientsId: ingredientsId,
            monthsId: monthsId,
            seasonalityId: seasonalityId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int ingredientsId,
            required int monthsId,
            required int seasonalityId,
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientSeasonalityCompanion.insert(
            ingredientsId: ingredientsId,
            monthsId: monthsId,
            seasonalityId: seasonalityId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IngredientSeasonalityTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {ingredientsId = false,
              monthsId = false,
              seasonalityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (ingredientsId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ingredientsId,
                    referencedTable: $$IngredientSeasonalityTableReferences
                        ._ingredientsIdTable(db),
                    referencedColumn: $$IngredientSeasonalityTableReferences
                        ._ingredientsIdTable(db)
                        .id,
                  ) as T;
                }
                if (monthsId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.monthsId,
                    referencedTable: $$IngredientSeasonalityTableReferences
                        ._monthsIdTable(db),
                    referencedColumn: $$IngredientSeasonalityTableReferences
                        ._monthsIdTable(db)
                        .id,
                  ) as T;
                }
                if (seasonalityId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.seasonalityId,
                    referencedTable: $$IngredientSeasonalityTableReferences
                        ._seasonalityIdTable(db),
                    referencedColumn: $$IngredientSeasonalityTableReferences
                        ._seasonalityIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IngredientSeasonalityTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $IngredientSeasonalityTable,
        IngredientSeasonalityData,
        $$IngredientSeasonalityTableFilterComposer,
        $$IngredientSeasonalityTableOrderingComposer,
        $$IngredientSeasonalityTableAnnotationComposer,
        $$IngredientSeasonalityTableCreateCompanionBuilder,
        $$IngredientSeasonalityTableUpdateCompanionBuilder,
        (IngredientSeasonalityData, $$IngredientSeasonalityTableReferences),
        IngredientSeasonalityData,
        PrefetchHooks Function(
            {bool ingredientsId, bool monthsId, bool seasonalityId})>;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$MonthsTableTableManager get months =>
      $$MonthsTableTableManager(_db, _db.months);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db, _db.units);
  $$UnitConversionsTableTableManager get unitConversions =>
      $$UnitConversionsTableTableManager(_db, _db.unitConversions);
  $$IngredientUnitOverridesTableTableManager get ingredientUnitOverrides =>
      $$IngredientUnitOverridesTableTableManager(
          _db, _db.ingredientUnitOverrides);
  $$NutrientsCategorieTableTableManager get nutrientsCategorie =>
      $$NutrientsCategorieTableTableManager(_db, _db.nutrientsCategorie);
  $$NutrientTableTableManager get nutrient =>
      $$NutrientTableTableManager(_db, _db.nutrient);
  $$IngredientCategoriesTableTableManager get ingredientCategories =>
      $$IngredientCategoriesTableTableManager(_db, _db.ingredientCategories);
  $$IngredientPropertiesTableTableManager get ingredientProperties =>
      $$IngredientPropertiesTableTableManager(_db, _db.ingredientProperties);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db, _db.ingredients);
  $$IngredientNutrientsTableTableManager get ingredientNutrients =>
      $$IngredientNutrientsTableTableManager(_db, _db.ingredientNutrients);
  $$SeasonalityTableTableManager get seasonality =>
      $$SeasonalityTableTableManager(_db, _db.seasonality);
  $$IngredientSeasonalityTableTableManager get ingredientSeasonality =>
      $$IngredientSeasonalityTableTableManager(_db, _db.ingredientSeasonality);
}
