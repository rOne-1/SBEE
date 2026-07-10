// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DriftWorkoutSessionsTable extends DriftWorkoutSessions
    with TableInfo<$DriftWorkoutSessionsTable, DriftWorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftWorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dayTypeMeta =
      const VerificationMeta('dayType');
  @override
  late final GeneratedColumn<int> dayType = GeneratedColumn<int>(
      'day_type', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _posturalWarningMeta =
      const VerificationMeta('posturalWarning');
  @override
  late final GeneratedColumn<String> posturalWarning = GeneratedColumn<String>(
      'postural_warning', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _posturalWarningReasonMeta =
      const VerificationMeta('posturalWarningReason');
  @override
  late final GeneratedColumn<String> posturalWarningReason =
      GeneratedColumn<String>('postural_warning_reason', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        startTime,
        endTime,
        isCompleted,
        dayType,
        posturalWarning,
        posturalWarningReason
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_workout_sessions';
  @override
  VerificationContext validateIntegrity(
      Insertable<DriftWorkoutSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('day_type')) {
      context.handle(_dayTypeMeta,
          dayType.isAcceptableOrUnknown(data['day_type']!, _dayTypeMeta));
    }
    if (data.containsKey('postural_warning')) {
      context.handle(
          _posturalWarningMeta,
          posturalWarning.isAcceptableOrUnknown(
              data['postural_warning']!, _posturalWarningMeta));
    }
    if (data.containsKey('postural_warning_reason')) {
      context.handle(
          _posturalWarningReasonMeta,
          posturalWarningReason.isAcceptableOrUnknown(
              data['postural_warning_reason']!, _posturalWarningReasonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftWorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftWorkoutSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      dayType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_type']),
      posturalWarning: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}postural_warning']),
      posturalWarningReason: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}postural_warning_reason']),
    );
  }

  @override
  $DriftWorkoutSessionsTable createAlias(String alias) {
    return $DriftWorkoutSessionsTable(attachedDatabase, alias);
  }
}

class DriftWorkoutSession extends DataClass
    implements Insertable<DriftWorkoutSession> {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final int? dayType;
  final String? posturalWarning;
  final String? posturalWarningReason;
  const DriftWorkoutSession(
      {required this.id,
      required this.startTime,
      this.endTime,
      required this.isCompleted,
      this.dayType,
      this.posturalWarning,
      this.posturalWarningReason});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || dayType != null) {
      map['day_type'] = Variable<int>(dayType);
    }
    if (!nullToAbsent || posturalWarning != null) {
      map['postural_warning'] = Variable<String>(posturalWarning);
    }
    if (!nullToAbsent || posturalWarningReason != null) {
      map['postural_warning_reason'] = Variable<String>(posturalWarningReason);
    }
    return map;
  }

  DriftWorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return DriftWorkoutSessionsCompanion(
      id: Value(id),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      isCompleted: Value(isCompleted),
      dayType: dayType == null && nullToAbsent
          ? const Value.absent()
          : Value(dayType),
      posturalWarning: posturalWarning == null && nullToAbsent
          ? const Value.absent()
          : Value(posturalWarning),
      posturalWarningReason: posturalWarningReason == null && nullToAbsent
          ? const Value.absent()
          : Value(posturalWarningReason),
    );
  }

  factory DriftWorkoutSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftWorkoutSession(
      id: serializer.fromJson<String>(json['id']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      dayType: serializer.fromJson<int?>(json['dayType']),
      posturalWarning: serializer.fromJson<String?>(json['posturalWarning']),
      posturalWarningReason:
          serializer.fromJson<String?>(json['posturalWarningReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'dayType': serializer.toJson<int?>(dayType),
      'posturalWarning': serializer.toJson<String?>(posturalWarning),
      'posturalWarningReason':
          serializer.toJson<String?>(posturalWarningReason),
    };
  }

  DriftWorkoutSession copyWith(
          {String? id,
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          bool? isCompleted,
          Value<int?> dayType = const Value.absent(),
          Value<String?> posturalWarning = const Value.absent(),
          Value<String?> posturalWarningReason = const Value.absent()}) =>
      DriftWorkoutSession(
        id: id ?? this.id,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        isCompleted: isCompleted ?? this.isCompleted,
        dayType: dayType.present ? dayType.value : this.dayType,
        posturalWarning: posturalWarning.present
            ? posturalWarning.value
            : this.posturalWarning,
        posturalWarningReason: posturalWarningReason.present
            ? posturalWarningReason.value
            : this.posturalWarningReason,
      );
  DriftWorkoutSession copyWithCompanion(DriftWorkoutSessionsCompanion data) {
    return DriftWorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      dayType: data.dayType.present ? data.dayType.value : this.dayType,
      posturalWarning: data.posturalWarning.present
          ? data.posturalWarning.value
          : this.posturalWarning,
      posturalWarningReason: data.posturalWarningReason.present
          ? data.posturalWarningReason.value
          : this.posturalWarningReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftWorkoutSession(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('dayType: $dayType, ')
          ..write('posturalWarning: $posturalWarning, ')
          ..write('posturalWarningReason: $posturalWarningReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startTime, endTime, isCompleted, dayType,
      posturalWarning, posturalWarningReason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftWorkoutSession &&
          other.id == this.id &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.isCompleted == this.isCompleted &&
          other.dayType == this.dayType &&
          other.posturalWarning == this.posturalWarning &&
          other.posturalWarningReason == this.posturalWarningReason);
}

class DriftWorkoutSessionsCompanion
    extends UpdateCompanion<DriftWorkoutSession> {
  final Value<String> id;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<bool> isCompleted;
  final Value<int?> dayType;
  final Value<String?> posturalWarning;
  final Value<String?> posturalWarningReason;
  final Value<int> rowid;
  const DriftWorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.dayType = const Value.absent(),
    this.posturalWarning = const Value.absent(),
    this.posturalWarningReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DriftWorkoutSessionsCompanion.insert({
    required String id,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.dayType = const Value.absent(),
    this.posturalWarning = const Value.absent(),
    this.posturalWarningReason = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        startTime = Value(startTime);
  static Insertable<DriftWorkoutSession> custom({
    Expression<String>? id,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<bool>? isCompleted,
    Expression<int>? dayType,
    Expression<String>? posturalWarning,
    Expression<String>? posturalWarningReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (dayType != null) 'day_type': dayType,
      if (posturalWarning != null) 'postural_warning': posturalWarning,
      if (posturalWarningReason != null)
        'postural_warning_reason': posturalWarningReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DriftWorkoutSessionsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<bool>? isCompleted,
      Value<int?>? dayType,
      Value<String?>? posturalWarning,
      Value<String?>? posturalWarningReason,
      Value<int>? rowid}) {
    return DriftWorkoutSessionsCompanion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      dayType: dayType ?? this.dayType,
      posturalWarning: posturalWarning ?? this.posturalWarning,
      posturalWarningReason:
          posturalWarningReason ?? this.posturalWarningReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (dayType.present) {
      map['day_type'] = Variable<int>(dayType.value);
    }
    if (posturalWarning.present) {
      map['postural_warning'] = Variable<String>(posturalWarning.value);
    }
    if (posturalWarningReason.present) {
      map['postural_warning_reason'] =
          Variable<String>(posturalWarningReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftWorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('dayType: $dayType, ')
          ..write('posturalWarning: $posturalWarning, ')
          ..write('posturalWarningReason: $posturalWarningReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DriftWorkoutSetsTable extends DriftWorkoutSets
    with TableInfo<$DriftWorkoutSetsTable, DriftWorkoutSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftWorkoutSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints:
          'REFERENCES drift_workout_sessions(id) ON DELETE CASCADE NOT NULL');
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _movementPatternMeta =
      const VerificationMeta('movementPattern');
  @override
  late final GeneratedColumn<int> movementPattern = GeneratedColumn<int>(
      'movement_pattern', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _setNumberMeta =
      const VerificationMeta('setNumber');
  @override
  late final GeneratedColumn<int> setNumber = GeneratedColumn<int>(
      'set_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetRpeMeta =
      const VerificationMeta('targetRpe');
  @override
  late final GeneratedColumn<int> targetRpe = GeneratedColumn<int>(
      'target_rpe', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reportedRpeMeta =
      const VerificationMeta('reportedRpe');
  @override
  late final GeneratedColumn<int> reportedRpe = GeneratedColumn<int>(
      'reported_rpe', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _loadValMeta =
      const VerificationMeta('loadVal');
  @override
  late final GeneratedColumn<int> loadVal = GeneratedColumn<int>(
      'load_val', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bodyPositionMeta =
      const VerificationMeta('bodyPosition');
  @override
  late final GeneratedColumn<int> bodyPosition = GeneratedColumn<int>(
      'body_position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _romMeta = const VerificationMeta('rom');
  @override
  late final GeneratedColumn<int> rom = GeneratedColumn<int>(
      'rom', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tempoMeta = const VerificationMeta('tempo');
  @override
  late final GeneratedColumn<int> tempo = GeneratedColumn<int>(
      'tempo', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _restDurationSecondsMeta =
      const VerificationMeta('restDurationSeconds');
  @override
  late final GeneratedColumn<int> restDurationSeconds = GeneratedColumn<int>(
      'rest_duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cuesJsonMeta =
      const VerificationMeta('cuesJson');
  @override
  late final GeneratedColumn<String> cuesJson = GeneratedColumn<String>(
      'cues_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionId,
        exerciseId,
        movementPattern,
        setNumber,
        reps,
        targetRpe,
        reportedRpe,
        loadVal,
        bodyPosition,
        rom,
        height,
        tempo,
        timestamp,
        restDurationSeconds,
        cuesJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_workout_sets';
  @override
  VerificationContext validateIntegrity(Insertable<DriftWorkoutSet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('movement_pattern')) {
      context.handle(
          _movementPatternMeta,
          movementPattern.isAcceptableOrUnknown(
              data['movement_pattern']!, _movementPatternMeta));
    } else if (isInserting) {
      context.missing(_movementPatternMeta);
    }
    if (data.containsKey('set_number')) {
      context.handle(_setNumberMeta,
          setNumber.isAcceptableOrUnknown(data['set_number']!, _setNumberMeta));
    } else if (isInserting) {
      context.missing(_setNumberMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('target_rpe')) {
      context.handle(_targetRpeMeta,
          targetRpe.isAcceptableOrUnknown(data['target_rpe']!, _targetRpeMeta));
    } else if (isInserting) {
      context.missing(_targetRpeMeta);
    }
    if (data.containsKey('reported_rpe')) {
      context.handle(
          _reportedRpeMeta,
          reportedRpe.isAcceptableOrUnknown(
              data['reported_rpe']!, _reportedRpeMeta));
    }
    if (data.containsKey('load_val')) {
      context.handle(_loadValMeta,
          loadVal.isAcceptableOrUnknown(data['load_val']!, _loadValMeta));
    } else if (isInserting) {
      context.missing(_loadValMeta);
    }
    if (data.containsKey('body_position')) {
      context.handle(
          _bodyPositionMeta,
          bodyPosition.isAcceptableOrUnknown(
              data['body_position']!, _bodyPositionMeta));
    } else if (isInserting) {
      context.missing(_bodyPositionMeta);
    }
    if (data.containsKey('rom')) {
      context.handle(
          _romMeta, rom.isAcceptableOrUnknown(data['rom']!, _romMeta));
    } else if (isInserting) {
      context.missing(_romMeta);
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('tempo')) {
      context.handle(
          _tempoMeta, tempo.isAcceptableOrUnknown(data['tempo']!, _tempoMeta));
    } else if (isInserting) {
      context.missing(_tempoMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('rest_duration_seconds')) {
      context.handle(
          _restDurationSecondsMeta,
          restDurationSeconds.isAcceptableOrUnknown(
              data['rest_duration_seconds']!, _restDurationSecondsMeta));
    }
    if (data.containsKey('cues_json')) {
      context.handle(_cuesJsonMeta,
          cuesJson.isAcceptableOrUnknown(data['cues_json']!, _cuesJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftWorkoutSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftWorkoutSet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      movementPattern: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}movement_pattern'])!,
      setNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}set_number'])!,
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      targetRpe: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_rpe'])!,
      reportedRpe: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reported_rpe']),
      loadVal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}load_val'])!,
      bodyPosition: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}body_position'])!,
      rom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rom'])!,
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height'])!,
      tempo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tempo'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      restDurationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}rest_duration_seconds']),
      cuesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cues_json']),
    );
  }

  @override
  $DriftWorkoutSetsTable createAlias(String alias) {
    return $DriftWorkoutSetsTable(attachedDatabase, alias);
  }
}

class DriftWorkoutSet extends DataClass implements Insertable<DriftWorkoutSet> {
  final String id;
  final String sessionId;
  final String exerciseId;
  final int movementPattern;
  final int setNumber;
  final int reps;
  final int targetRpe;
  final int? reportedRpe;
  final int loadVal;
  final int bodyPosition;
  final int rom;
  final int height;
  final int tempo;
  final DateTime timestamp;
  final int? restDurationSeconds;
  final String? cuesJson;
  const DriftWorkoutSet(
      {required this.id,
      required this.sessionId,
      required this.exerciseId,
      required this.movementPattern,
      required this.setNumber,
      required this.reps,
      required this.targetRpe,
      this.reportedRpe,
      required this.loadVal,
      required this.bodyPosition,
      required this.rom,
      required this.height,
      required this.tempo,
      required this.timestamp,
      this.restDurationSeconds,
      this.cuesJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['movement_pattern'] = Variable<int>(movementPattern);
    map['set_number'] = Variable<int>(setNumber);
    map['reps'] = Variable<int>(reps);
    map['target_rpe'] = Variable<int>(targetRpe);
    if (!nullToAbsent || reportedRpe != null) {
      map['reported_rpe'] = Variable<int>(reportedRpe);
    }
    map['load_val'] = Variable<int>(loadVal);
    map['body_position'] = Variable<int>(bodyPosition);
    map['rom'] = Variable<int>(rom);
    map['height'] = Variable<int>(height);
    map['tempo'] = Variable<int>(tempo);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || restDurationSeconds != null) {
      map['rest_duration_seconds'] = Variable<int>(restDurationSeconds);
    }
    if (!nullToAbsent || cuesJson != null) {
      map['cues_json'] = Variable<String>(cuesJson);
    }
    return map;
  }

  DriftWorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return DriftWorkoutSetsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      movementPattern: Value(movementPattern),
      setNumber: Value(setNumber),
      reps: Value(reps),
      targetRpe: Value(targetRpe),
      reportedRpe: reportedRpe == null && nullToAbsent
          ? const Value.absent()
          : Value(reportedRpe),
      loadVal: Value(loadVal),
      bodyPosition: Value(bodyPosition),
      rom: Value(rom),
      height: Value(height),
      tempo: Value(tempo),
      timestamp: Value(timestamp),
      restDurationSeconds: restDurationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(restDurationSeconds),
      cuesJson: cuesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(cuesJson),
    );
  }

  factory DriftWorkoutSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftWorkoutSet(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      movementPattern: serializer.fromJson<int>(json['movementPattern']),
      setNumber: serializer.fromJson<int>(json['setNumber']),
      reps: serializer.fromJson<int>(json['reps']),
      targetRpe: serializer.fromJson<int>(json['targetRpe']),
      reportedRpe: serializer.fromJson<int?>(json['reportedRpe']),
      loadVal: serializer.fromJson<int>(json['loadVal']),
      bodyPosition: serializer.fromJson<int>(json['bodyPosition']),
      rom: serializer.fromJson<int>(json['rom']),
      height: serializer.fromJson<int>(json['height']),
      tempo: serializer.fromJson<int>(json['tempo']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      restDurationSeconds:
          serializer.fromJson<int?>(json['restDurationSeconds']),
      cuesJson: serializer.fromJson<String?>(json['cuesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'movementPattern': serializer.toJson<int>(movementPattern),
      'setNumber': serializer.toJson<int>(setNumber),
      'reps': serializer.toJson<int>(reps),
      'targetRpe': serializer.toJson<int>(targetRpe),
      'reportedRpe': serializer.toJson<int?>(reportedRpe),
      'loadVal': serializer.toJson<int>(loadVal),
      'bodyPosition': serializer.toJson<int>(bodyPosition),
      'rom': serializer.toJson<int>(rom),
      'height': serializer.toJson<int>(height),
      'tempo': serializer.toJson<int>(tempo),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'restDurationSeconds': serializer.toJson<int?>(restDurationSeconds),
      'cuesJson': serializer.toJson<String?>(cuesJson),
    };
  }

  DriftWorkoutSet copyWith(
          {String? id,
          String? sessionId,
          String? exerciseId,
          int? movementPattern,
          int? setNumber,
          int? reps,
          int? targetRpe,
          Value<int?> reportedRpe = const Value.absent(),
          int? loadVal,
          int? bodyPosition,
          int? rom,
          int? height,
          int? tempo,
          DateTime? timestamp,
          Value<int?> restDurationSeconds = const Value.absent(),
          Value<String?> cuesJson = const Value.absent()}) =>
      DriftWorkoutSet(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        exerciseId: exerciseId ?? this.exerciseId,
        movementPattern: movementPattern ?? this.movementPattern,
        setNumber: setNumber ?? this.setNumber,
        reps: reps ?? this.reps,
        targetRpe: targetRpe ?? this.targetRpe,
        reportedRpe: reportedRpe.present ? reportedRpe.value : this.reportedRpe,
        loadVal: loadVal ?? this.loadVal,
        bodyPosition: bodyPosition ?? this.bodyPosition,
        rom: rom ?? this.rom,
        height: height ?? this.height,
        tempo: tempo ?? this.tempo,
        timestamp: timestamp ?? this.timestamp,
        restDurationSeconds: restDurationSeconds.present
            ? restDurationSeconds.value
            : this.restDurationSeconds,
        cuesJson: cuesJson.present ? cuesJson.value : this.cuesJson,
      );
  DriftWorkoutSet copyWithCompanion(DriftWorkoutSetsCompanion data) {
    return DriftWorkoutSet(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      movementPattern: data.movementPattern.present
          ? data.movementPattern.value
          : this.movementPattern,
      setNumber: data.setNumber.present ? data.setNumber.value : this.setNumber,
      reps: data.reps.present ? data.reps.value : this.reps,
      targetRpe: data.targetRpe.present ? data.targetRpe.value : this.targetRpe,
      reportedRpe:
          data.reportedRpe.present ? data.reportedRpe.value : this.reportedRpe,
      loadVal: data.loadVal.present ? data.loadVal.value : this.loadVal,
      bodyPosition: data.bodyPosition.present
          ? data.bodyPosition.value
          : this.bodyPosition,
      rom: data.rom.present ? data.rom.value : this.rom,
      height: data.height.present ? data.height.value : this.height,
      tempo: data.tempo.present ? data.tempo.value : this.tempo,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      restDurationSeconds: data.restDurationSeconds.present
          ? data.restDurationSeconds.value
          : this.restDurationSeconds,
      cuesJson: data.cuesJson.present ? data.cuesJson.value : this.cuesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftWorkoutSet(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('movementPattern: $movementPattern, ')
          ..write('setNumber: $setNumber, ')
          ..write('reps: $reps, ')
          ..write('targetRpe: $targetRpe, ')
          ..write('reportedRpe: $reportedRpe, ')
          ..write('loadVal: $loadVal, ')
          ..write('bodyPosition: $bodyPosition, ')
          ..write('rom: $rom, ')
          ..write('height: $height, ')
          ..write('tempo: $tempo, ')
          ..write('timestamp: $timestamp, ')
          ..write('restDurationSeconds: $restDurationSeconds, ')
          ..write('cuesJson: $cuesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sessionId,
      exerciseId,
      movementPattern,
      setNumber,
      reps,
      targetRpe,
      reportedRpe,
      loadVal,
      bodyPosition,
      rom,
      height,
      tempo,
      timestamp,
      restDurationSeconds,
      cuesJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftWorkoutSet &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.movementPattern == this.movementPattern &&
          other.setNumber == this.setNumber &&
          other.reps == this.reps &&
          other.targetRpe == this.targetRpe &&
          other.reportedRpe == this.reportedRpe &&
          other.loadVal == this.loadVal &&
          other.bodyPosition == this.bodyPosition &&
          other.rom == this.rom &&
          other.height == this.height &&
          other.tempo == this.tempo &&
          other.timestamp == this.timestamp &&
          other.restDurationSeconds == this.restDurationSeconds &&
          other.cuesJson == this.cuesJson);
}

class DriftWorkoutSetsCompanion extends UpdateCompanion<DriftWorkoutSet> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> exerciseId;
  final Value<int> movementPattern;
  final Value<int> setNumber;
  final Value<int> reps;
  final Value<int> targetRpe;
  final Value<int?> reportedRpe;
  final Value<int> loadVal;
  final Value<int> bodyPosition;
  final Value<int> rom;
  final Value<int> height;
  final Value<int> tempo;
  final Value<DateTime> timestamp;
  final Value<int?> restDurationSeconds;
  final Value<String?> cuesJson;
  final Value<int> rowid;
  const DriftWorkoutSetsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.movementPattern = const Value.absent(),
    this.setNumber = const Value.absent(),
    this.reps = const Value.absent(),
    this.targetRpe = const Value.absent(),
    this.reportedRpe = const Value.absent(),
    this.loadVal = const Value.absent(),
    this.bodyPosition = const Value.absent(),
    this.rom = const Value.absent(),
    this.height = const Value.absent(),
    this.tempo = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.restDurationSeconds = const Value.absent(),
    this.cuesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DriftWorkoutSetsCompanion.insert({
    required String id,
    required String sessionId,
    required String exerciseId,
    required int movementPattern,
    required int setNumber,
    required int reps,
    required int targetRpe,
    this.reportedRpe = const Value.absent(),
    required int loadVal,
    required int bodyPosition,
    required int rom,
    required int height,
    required int tempo,
    required DateTime timestamp,
    this.restDurationSeconds = const Value.absent(),
    this.cuesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sessionId = Value(sessionId),
        exerciseId = Value(exerciseId),
        movementPattern = Value(movementPattern),
        setNumber = Value(setNumber),
        reps = Value(reps),
        targetRpe = Value(targetRpe),
        loadVal = Value(loadVal),
        bodyPosition = Value(bodyPosition),
        rom = Value(rom),
        height = Value(height),
        tempo = Value(tempo),
        timestamp = Value(timestamp);
  static Insertable<DriftWorkoutSet> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? exerciseId,
    Expression<int>? movementPattern,
    Expression<int>? setNumber,
    Expression<int>? reps,
    Expression<int>? targetRpe,
    Expression<int>? reportedRpe,
    Expression<int>? loadVal,
    Expression<int>? bodyPosition,
    Expression<int>? rom,
    Expression<int>? height,
    Expression<int>? tempo,
    Expression<DateTime>? timestamp,
    Expression<int>? restDurationSeconds,
    Expression<String>? cuesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (movementPattern != null) 'movement_pattern': movementPattern,
      if (setNumber != null) 'set_number': setNumber,
      if (reps != null) 'reps': reps,
      if (targetRpe != null) 'target_rpe': targetRpe,
      if (reportedRpe != null) 'reported_rpe': reportedRpe,
      if (loadVal != null) 'load_val': loadVal,
      if (bodyPosition != null) 'body_position': bodyPosition,
      if (rom != null) 'rom': rom,
      if (height != null) 'height': height,
      if (tempo != null) 'tempo': tempo,
      if (timestamp != null) 'timestamp': timestamp,
      if (restDurationSeconds != null)
        'rest_duration_seconds': restDurationSeconds,
      if (cuesJson != null) 'cues_json': cuesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DriftWorkoutSetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<String>? exerciseId,
      Value<int>? movementPattern,
      Value<int>? setNumber,
      Value<int>? reps,
      Value<int>? targetRpe,
      Value<int?>? reportedRpe,
      Value<int>? loadVal,
      Value<int>? bodyPosition,
      Value<int>? rom,
      Value<int>? height,
      Value<int>? tempo,
      Value<DateTime>? timestamp,
      Value<int?>? restDurationSeconds,
      Value<String?>? cuesJson,
      Value<int>? rowid}) {
    return DriftWorkoutSetsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      movementPattern: movementPattern ?? this.movementPattern,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      targetRpe: targetRpe ?? this.targetRpe,
      reportedRpe: reportedRpe ?? this.reportedRpe,
      loadVal: loadVal ?? this.loadVal,
      bodyPosition: bodyPosition ?? this.bodyPosition,
      rom: rom ?? this.rom,
      height: height ?? this.height,
      tempo: tempo ?? this.tempo,
      timestamp: timestamp ?? this.timestamp,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      cuesJson: cuesJson ?? this.cuesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (movementPattern.present) {
      map['movement_pattern'] = Variable<int>(movementPattern.value);
    }
    if (setNumber.present) {
      map['set_number'] = Variable<int>(setNumber.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (targetRpe.present) {
      map['target_rpe'] = Variable<int>(targetRpe.value);
    }
    if (reportedRpe.present) {
      map['reported_rpe'] = Variable<int>(reportedRpe.value);
    }
    if (loadVal.present) {
      map['load_val'] = Variable<int>(loadVal.value);
    }
    if (bodyPosition.present) {
      map['body_position'] = Variable<int>(bodyPosition.value);
    }
    if (rom.present) {
      map['rom'] = Variable<int>(rom.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (tempo.present) {
      map['tempo'] = Variable<int>(tempo.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (restDurationSeconds.present) {
      map['rest_duration_seconds'] = Variable<int>(restDurationSeconds.value);
    }
    if (cuesJson.present) {
      map['cues_json'] = Variable<String>(cuesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftWorkoutSetsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('movementPattern: $movementPattern, ')
          ..write('setNumber: $setNumber, ')
          ..write('reps: $reps, ')
          ..write('targetRpe: $targetRpe, ')
          ..write('reportedRpe: $reportedRpe, ')
          ..write('loadVal: $loadVal, ')
          ..write('bodyPosition: $bodyPosition, ')
          ..write('rom: $rom, ')
          ..write('height: $height, ')
          ..write('tempo: $tempo, ')
          ..write('timestamp: $timestamp, ')
          ..write('restDurationSeconds: $restDurationSeconds, ')
          ..write('cuesJson: $cuesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DriftExerciseProgressionsTable extends DriftExerciseProgressions
    with TableInfo<$DriftExerciseProgressionsTable, DriftExerciseProgression> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftExerciseProgressionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _loadValMeta =
      const VerificationMeta('loadVal');
  @override
  late final GeneratedColumn<int> loadVal = GeneratedColumn<int>(
      'load_val', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bodyPositionMeta =
      const VerificationMeta('bodyPosition');
  @override
  late final GeneratedColumn<int> bodyPosition = GeneratedColumn<int>(
      'body_position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _romMeta = const VerificationMeta('rom');
  @override
  late final GeneratedColumn<int> rom = GeneratedColumn<int>(
      'rom', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tempoMeta = const VerificationMeta('tempo');
  @override
  late final GeneratedColumn<int> tempo = GeneratedColumn<int>(
      'tempo', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _competencyLevelMeta =
      const VerificationMeta('competencyLevel');
  @override
  late final GeneratedColumn<int> competencyLevel = GeneratedColumn<int>(
      'competency_level', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastPerformedMeta =
      const VerificationMeta('lastPerformed');
  @override
  late final GeneratedColumn<DateTime> lastPerformed =
      GeneratedColumn<DateTime>('last_performed', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        exerciseId,
        loadVal,
        bodyPosition,
        rom,
        height,
        tempo,
        competencyLevel,
        lastPerformed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_exercise_progressions';
  @override
  VerificationContext validateIntegrity(
      Insertable<DriftExerciseProgression> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('load_val')) {
      context.handle(_loadValMeta,
          loadVal.isAcceptableOrUnknown(data['load_val']!, _loadValMeta));
    } else if (isInserting) {
      context.missing(_loadValMeta);
    }
    if (data.containsKey('body_position')) {
      context.handle(
          _bodyPositionMeta,
          bodyPosition.isAcceptableOrUnknown(
              data['body_position']!, _bodyPositionMeta));
    } else if (isInserting) {
      context.missing(_bodyPositionMeta);
    }
    if (data.containsKey('rom')) {
      context.handle(
          _romMeta, rom.isAcceptableOrUnknown(data['rom']!, _romMeta));
    } else if (isInserting) {
      context.missing(_romMeta);
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('tempo')) {
      context.handle(
          _tempoMeta, tempo.isAcceptableOrUnknown(data['tempo']!, _tempoMeta));
    } else if (isInserting) {
      context.missing(_tempoMeta);
    }
    if (data.containsKey('competency_level')) {
      context.handle(
          _competencyLevelMeta,
          competencyLevel.isAcceptableOrUnknown(
              data['competency_level']!, _competencyLevelMeta));
    } else if (isInserting) {
      context.missing(_competencyLevelMeta);
    }
    if (data.containsKey('last_performed')) {
      context.handle(
          _lastPerformedMeta,
          lastPerformed.isAcceptableOrUnknown(
              data['last_performed']!, _lastPerformedMeta));
    } else if (isInserting) {
      context.missing(_lastPerformedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId};
  @override
  DriftExerciseProgression map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftExerciseProgression(
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      loadVal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}load_val'])!,
      bodyPosition: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}body_position'])!,
      rom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rom'])!,
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height'])!,
      tempo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tempo'])!,
      competencyLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}competency_level'])!,
      lastPerformed: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_performed'])!,
    );
  }

  @override
  $DriftExerciseProgressionsTable createAlias(String alias) {
    return $DriftExerciseProgressionsTable(attachedDatabase, alias);
  }
}

class DriftExerciseProgression extends DataClass
    implements Insertable<DriftExerciseProgression> {
  final String exerciseId;
  final int loadVal;
  final int bodyPosition;
  final int rom;
  final int height;
  final int tempo;
  final int competencyLevel;
  final DateTime lastPerformed;
  const DriftExerciseProgression(
      {required this.exerciseId,
      required this.loadVal,
      required this.bodyPosition,
      required this.rom,
      required this.height,
      required this.tempo,
      required this.competencyLevel,
      required this.lastPerformed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<String>(exerciseId);
    map['load_val'] = Variable<int>(loadVal);
    map['body_position'] = Variable<int>(bodyPosition);
    map['rom'] = Variable<int>(rom);
    map['height'] = Variable<int>(height);
    map['tempo'] = Variable<int>(tempo);
    map['competency_level'] = Variable<int>(competencyLevel);
    map['last_performed'] = Variable<DateTime>(lastPerformed);
    return map;
  }

  DriftExerciseProgressionsCompanion toCompanion(bool nullToAbsent) {
    return DriftExerciseProgressionsCompanion(
      exerciseId: Value(exerciseId),
      loadVal: Value(loadVal),
      bodyPosition: Value(bodyPosition),
      rom: Value(rom),
      height: Value(height),
      tempo: Value(tempo),
      competencyLevel: Value(competencyLevel),
      lastPerformed: Value(lastPerformed),
    );
  }

  factory DriftExerciseProgression.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftExerciseProgression(
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      loadVal: serializer.fromJson<int>(json['loadVal']),
      bodyPosition: serializer.fromJson<int>(json['bodyPosition']),
      rom: serializer.fromJson<int>(json['rom']),
      height: serializer.fromJson<int>(json['height']),
      tempo: serializer.fromJson<int>(json['tempo']),
      competencyLevel: serializer.fromJson<int>(json['competencyLevel']),
      lastPerformed: serializer.fromJson<DateTime>(json['lastPerformed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<String>(exerciseId),
      'loadVal': serializer.toJson<int>(loadVal),
      'bodyPosition': serializer.toJson<int>(bodyPosition),
      'rom': serializer.toJson<int>(rom),
      'height': serializer.toJson<int>(height),
      'tempo': serializer.toJson<int>(tempo),
      'competencyLevel': serializer.toJson<int>(competencyLevel),
      'lastPerformed': serializer.toJson<DateTime>(lastPerformed),
    };
  }

  DriftExerciseProgression copyWith(
          {String? exerciseId,
          int? loadVal,
          int? bodyPosition,
          int? rom,
          int? height,
          int? tempo,
          int? competencyLevel,
          DateTime? lastPerformed}) =>
      DriftExerciseProgression(
        exerciseId: exerciseId ?? this.exerciseId,
        loadVal: loadVal ?? this.loadVal,
        bodyPosition: bodyPosition ?? this.bodyPosition,
        rom: rom ?? this.rom,
        height: height ?? this.height,
        tempo: tempo ?? this.tempo,
        competencyLevel: competencyLevel ?? this.competencyLevel,
        lastPerformed: lastPerformed ?? this.lastPerformed,
      );
  DriftExerciseProgression copyWithCompanion(
      DriftExerciseProgressionsCompanion data) {
    return DriftExerciseProgression(
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      loadVal: data.loadVal.present ? data.loadVal.value : this.loadVal,
      bodyPosition: data.bodyPosition.present
          ? data.bodyPosition.value
          : this.bodyPosition,
      rom: data.rom.present ? data.rom.value : this.rom,
      height: data.height.present ? data.height.value : this.height,
      tempo: data.tempo.present ? data.tempo.value : this.tempo,
      competencyLevel: data.competencyLevel.present
          ? data.competencyLevel.value
          : this.competencyLevel,
      lastPerformed: data.lastPerformed.present
          ? data.lastPerformed.value
          : this.lastPerformed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftExerciseProgression(')
          ..write('exerciseId: $exerciseId, ')
          ..write('loadVal: $loadVal, ')
          ..write('bodyPosition: $bodyPosition, ')
          ..write('rom: $rom, ')
          ..write('height: $height, ')
          ..write('tempo: $tempo, ')
          ..write('competencyLevel: $competencyLevel, ')
          ..write('lastPerformed: $lastPerformed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseId, loadVal, bodyPosition, rom,
      height, tempo, competencyLevel, lastPerformed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftExerciseProgression &&
          other.exerciseId == this.exerciseId &&
          other.loadVal == this.loadVal &&
          other.bodyPosition == this.bodyPosition &&
          other.rom == this.rom &&
          other.height == this.height &&
          other.tempo == this.tempo &&
          other.competencyLevel == this.competencyLevel &&
          other.lastPerformed == this.lastPerformed);
}

class DriftExerciseProgressionsCompanion
    extends UpdateCompanion<DriftExerciseProgression> {
  final Value<String> exerciseId;
  final Value<int> loadVal;
  final Value<int> bodyPosition;
  final Value<int> rom;
  final Value<int> height;
  final Value<int> tempo;
  final Value<int> competencyLevel;
  final Value<DateTime> lastPerformed;
  final Value<int> rowid;
  const DriftExerciseProgressionsCompanion({
    this.exerciseId = const Value.absent(),
    this.loadVal = const Value.absent(),
    this.bodyPosition = const Value.absent(),
    this.rom = const Value.absent(),
    this.height = const Value.absent(),
    this.tempo = const Value.absent(),
    this.competencyLevel = const Value.absent(),
    this.lastPerformed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DriftExerciseProgressionsCompanion.insert({
    required String exerciseId,
    required int loadVal,
    required int bodyPosition,
    required int rom,
    required int height,
    required int tempo,
    required int competencyLevel,
    required DateTime lastPerformed,
    this.rowid = const Value.absent(),
  })  : exerciseId = Value(exerciseId),
        loadVal = Value(loadVal),
        bodyPosition = Value(bodyPosition),
        rom = Value(rom),
        height = Value(height),
        tempo = Value(tempo),
        competencyLevel = Value(competencyLevel),
        lastPerformed = Value(lastPerformed);
  static Insertable<DriftExerciseProgression> custom({
    Expression<String>? exerciseId,
    Expression<int>? loadVal,
    Expression<int>? bodyPosition,
    Expression<int>? rom,
    Expression<int>? height,
    Expression<int>? tempo,
    Expression<int>? competencyLevel,
    Expression<DateTime>? lastPerformed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (loadVal != null) 'load_val': loadVal,
      if (bodyPosition != null) 'body_position': bodyPosition,
      if (rom != null) 'rom': rom,
      if (height != null) 'height': height,
      if (tempo != null) 'tempo': tempo,
      if (competencyLevel != null) 'competency_level': competencyLevel,
      if (lastPerformed != null) 'last_performed': lastPerformed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DriftExerciseProgressionsCompanion copyWith(
      {Value<String>? exerciseId,
      Value<int>? loadVal,
      Value<int>? bodyPosition,
      Value<int>? rom,
      Value<int>? height,
      Value<int>? tempo,
      Value<int>? competencyLevel,
      Value<DateTime>? lastPerformed,
      Value<int>? rowid}) {
    return DriftExerciseProgressionsCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      loadVal: loadVal ?? this.loadVal,
      bodyPosition: bodyPosition ?? this.bodyPosition,
      rom: rom ?? this.rom,
      height: height ?? this.height,
      tempo: tempo ?? this.tempo,
      competencyLevel: competencyLevel ?? this.competencyLevel,
      lastPerformed: lastPerformed ?? this.lastPerformed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (loadVal.present) {
      map['load_val'] = Variable<int>(loadVal.value);
    }
    if (bodyPosition.present) {
      map['body_position'] = Variable<int>(bodyPosition.value);
    }
    if (rom.present) {
      map['rom'] = Variable<int>(rom.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (tempo.present) {
      map['tempo'] = Variable<int>(tempo.value);
    }
    if (competencyLevel.present) {
      map['competency_level'] = Variable<int>(competencyLevel.value);
    }
    if (lastPerformed.present) {
      map['last_performed'] = Variable<DateTime>(lastPerformed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftExerciseProgressionsCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('loadVal: $loadVal, ')
          ..write('bodyPosition: $bodyPosition, ')
          ..write('rom: $rom, ')
          ..write('height: $height, ')
          ..write('tempo: $tempo, ')
          ..write('competencyLevel: $competencyLevel, ')
          ..write('lastPerformed: $lastPerformed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DriftStatusAchievedTable extends DriftStatusAchieved
    with TableInfo<$DriftStatusAchievedTable, DriftStatusAchievedData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftStatusAchievedTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _achievedDateMeta =
      const VerificationMeta('achievedDate');
  @override
  late final GeneratedColumn<DateTime> achievedDate = GeneratedColumn<DateTime>(
      'achieved_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [status, achievedDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_status_achieved';
  @override
  VerificationContext validateIntegrity(
      Insertable<DriftStatusAchievedData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('achieved_date')) {
      context.handle(
          _achievedDateMeta,
          achievedDate.isAcceptableOrUnknown(
              data['achieved_date']!, _achievedDateMeta));
    } else if (isInserting) {
      context.missing(_achievedDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {status};
  @override
  DriftStatusAchievedData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftStatusAchievedData(
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      achievedDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}achieved_date'])!,
    );
  }

  @override
  $DriftStatusAchievedTable createAlias(String alias) {
    return $DriftStatusAchievedTable(attachedDatabase, alias);
  }
}

class DriftStatusAchievedData extends DataClass
    implements Insertable<DriftStatusAchievedData> {
  final String status;
  final DateTime achievedDate;
  const DriftStatusAchievedData(
      {required this.status, required this.achievedDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['status'] = Variable<String>(status);
    map['achieved_date'] = Variable<DateTime>(achievedDate);
    return map;
  }

  DriftStatusAchievedCompanion toCompanion(bool nullToAbsent) {
    return DriftStatusAchievedCompanion(
      status: Value(status),
      achievedDate: Value(achievedDate),
    );
  }

  factory DriftStatusAchievedData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftStatusAchievedData(
      status: serializer.fromJson<String>(json['status']),
      achievedDate: serializer.fromJson<DateTime>(json['achievedDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'status': serializer.toJson<String>(status),
      'achievedDate': serializer.toJson<DateTime>(achievedDate),
    };
  }

  DriftStatusAchievedData copyWith({String? status, DateTime? achievedDate}) =>
      DriftStatusAchievedData(
        status: status ?? this.status,
        achievedDate: achievedDate ?? this.achievedDate,
      );
  DriftStatusAchievedData copyWithCompanion(DriftStatusAchievedCompanion data) {
    return DriftStatusAchievedData(
      status: data.status.present ? data.status.value : this.status,
      achievedDate: data.achievedDate.present
          ? data.achievedDate.value
          : this.achievedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftStatusAchievedData(')
          ..write('status: $status, ')
          ..write('achievedDate: $achievedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(status, achievedDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftStatusAchievedData &&
          other.status == this.status &&
          other.achievedDate == this.achievedDate);
}

class DriftStatusAchievedCompanion
    extends UpdateCompanion<DriftStatusAchievedData> {
  final Value<String> status;
  final Value<DateTime> achievedDate;
  final Value<int> rowid;
  const DriftStatusAchievedCompanion({
    this.status = const Value.absent(),
    this.achievedDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DriftStatusAchievedCompanion.insert({
    required String status,
    required DateTime achievedDate,
    this.rowid = const Value.absent(),
  })  : status = Value(status),
        achievedDate = Value(achievedDate);
  static Insertable<DriftStatusAchievedData> custom({
    Expression<String>? status,
    Expression<DateTime>? achievedDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (status != null) 'status': status,
      if (achievedDate != null) 'achieved_date': achievedDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DriftStatusAchievedCompanion copyWith(
      {Value<String>? status,
      Value<DateTime>? achievedDate,
      Value<int>? rowid}) {
    return DriftStatusAchievedCompanion(
      status: status ?? this.status,
      achievedDate: achievedDate ?? this.achievedDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (achievedDate.present) {
      map['achieved_date'] = Variable<DateTime>(achievedDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftStatusAchievedCompanion(')
          ..write('status: $status, ')
          ..write('achievedDate: $achievedDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SbeeDatabase extends GeneratedDatabase {
  _$SbeeDatabase(QueryExecutor e) : super(e);
  $SbeeDatabaseManager get managers => $SbeeDatabaseManager(this);
  late final $DriftWorkoutSessionsTable driftWorkoutSessions =
      $DriftWorkoutSessionsTable(this);
  late final $DriftWorkoutSetsTable driftWorkoutSets =
      $DriftWorkoutSetsTable(this);
  late final $DriftExerciseProgressionsTable driftExerciseProgressions =
      $DriftExerciseProgressionsTable(this);
  late final $DriftStatusAchievedTable driftStatusAchieved =
      $DriftStatusAchievedTable(this);
  late final Index idxWorkoutSessionsTime = Index('idx_workout_sessions_time',
      'CREATE INDEX idx_workout_sessions_time ON drift_workout_sessions (start_time, end_time)');
  late final Index idxWorkoutSetsPatternTime = Index(
      'idx_workout_sets_pattern_time',
      'CREATE INDEX idx_workout_sets_pattern_time ON drift_workout_sets (movement_pattern, timestamp)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        driftWorkoutSessions,
        driftWorkoutSets,
        driftExerciseProgressions,
        driftStatusAchieved,
        idxWorkoutSessionsTime,
        idxWorkoutSetsPatternTime
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('drift_workout_sessions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('drift_workout_sets', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$DriftWorkoutSessionsTableCreateCompanionBuilder
    = DriftWorkoutSessionsCompanion Function({
  required String id,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<bool> isCompleted,
  Value<int?> dayType,
  Value<String?> posturalWarning,
  Value<String?> posturalWarningReason,
  Value<int> rowid,
});
typedef $$DriftWorkoutSessionsTableUpdateCompanionBuilder
    = DriftWorkoutSessionsCompanion Function({
  Value<String> id,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<bool> isCompleted,
  Value<int?> dayType,
  Value<String?> posturalWarning,
  Value<String?> posturalWarningReason,
  Value<int> rowid,
});

final class $$DriftWorkoutSessionsTableReferences extends BaseReferences<
    _$SbeeDatabase, $DriftWorkoutSessionsTable, DriftWorkoutSession> {
  $$DriftWorkoutSessionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DriftWorkoutSetsTable, List<DriftWorkoutSet>>
      _driftWorkoutSetsRefsTable(_$SbeeDatabase db) =>
          MultiTypedResultKey.fromTable(db.driftWorkoutSets,
              aliasName:
                  'drift_workout_sessions__id__drift_workout_sets__session_id');

  $$DriftWorkoutSetsTableProcessedTableManager get driftWorkoutSetsRefs {
    final manager = $$DriftWorkoutSetsTableTableManager(
            $_db, $_db.driftWorkoutSets)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_driftWorkoutSetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DriftWorkoutSessionsTableFilterComposer
    extends Composer<_$SbeeDatabase, $DriftWorkoutSessionsTable> {
  $$DriftWorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayType => $composableBuilder(
      column: $table.dayType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posturalWarning => $composableBuilder(
      column: $table.posturalWarning,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posturalWarningReason => $composableBuilder(
      column: $table.posturalWarningReason,
      builder: (column) => ColumnFilters(column));

  Expression<bool> driftWorkoutSetsRefs(
      Expression<bool> Function($$DriftWorkoutSetsTableFilterComposer f) f) {
    final $$DriftWorkoutSetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.driftWorkoutSets,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DriftWorkoutSetsTableFilterComposer(
              $db: $db,
              $table: $db.driftWorkoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DriftWorkoutSessionsTableOrderingComposer
    extends Composer<_$SbeeDatabase, $DriftWorkoutSessionsTable> {
  $$DriftWorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayType => $composableBuilder(
      column: $table.dayType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posturalWarning => $composableBuilder(
      column: $table.posturalWarning,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posturalWarningReason => $composableBuilder(
      column: $table.posturalWarningReason,
      builder: (column) => ColumnOrderings(column));
}

class $$DriftWorkoutSessionsTableAnnotationComposer
    extends Composer<_$SbeeDatabase, $DriftWorkoutSessionsTable> {
  $$DriftWorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<int> get dayType =>
      $composableBuilder(column: $table.dayType, builder: (column) => column);

  GeneratedColumn<String> get posturalWarning => $composableBuilder(
      column: $table.posturalWarning, builder: (column) => column);

  GeneratedColumn<String> get posturalWarningReason => $composableBuilder(
      column: $table.posturalWarningReason, builder: (column) => column);

  Expression<T> driftWorkoutSetsRefs<T extends Object>(
      Expression<T> Function($$DriftWorkoutSetsTableAnnotationComposer a) f) {
    final $$DriftWorkoutSetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.driftWorkoutSets,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DriftWorkoutSetsTableAnnotationComposer(
              $db: $db,
              $table: $db.driftWorkoutSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DriftWorkoutSessionsTableTableManager extends RootTableManager<
    _$SbeeDatabase,
    $DriftWorkoutSessionsTable,
    DriftWorkoutSession,
    $$DriftWorkoutSessionsTableFilterComposer,
    $$DriftWorkoutSessionsTableOrderingComposer,
    $$DriftWorkoutSessionsTableAnnotationComposer,
    $$DriftWorkoutSessionsTableCreateCompanionBuilder,
    $$DriftWorkoutSessionsTableUpdateCompanionBuilder,
    (DriftWorkoutSession, $$DriftWorkoutSessionsTableReferences),
    DriftWorkoutSession,
    PrefetchHooks Function({bool driftWorkoutSetsRefs})> {
  $$DriftWorkoutSessionsTableTableManager(
      _$SbeeDatabase db, $DriftWorkoutSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DriftWorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DriftWorkoutSessionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DriftWorkoutSessionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<int?> dayType = const Value.absent(),
            Value<String?> posturalWarning = const Value.absent(),
            Value<String?> posturalWarningReason = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DriftWorkoutSessionsCompanion(
            id: id,
            startTime: startTime,
            endTime: endTime,
            isCompleted: isCompleted,
            dayType: dayType,
            posturalWarning: posturalWarning,
            posturalWarningReason: posturalWarningReason,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<int?> dayType = const Value.absent(),
            Value<String?> posturalWarning = const Value.absent(),
            Value<String?> posturalWarningReason = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DriftWorkoutSessionsCompanion.insert(
            id: id,
            startTime: startTime,
            endTime: endTime,
            isCompleted: isCompleted,
            dayType: dayType,
            posturalWarning: posturalWarning,
            posturalWarningReason: posturalWarningReason,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DriftWorkoutSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({driftWorkoutSetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (driftWorkoutSetsRefs) db.driftWorkoutSets
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (driftWorkoutSetsRefs)
                    await $_getPrefetchedData<DriftWorkoutSession,
                            $DriftWorkoutSessionsTable, DriftWorkoutSet>(
                        currentTable: table,
                        referencedTable: $$DriftWorkoutSessionsTableReferences
                            ._driftWorkoutSetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DriftWorkoutSessionsTableReferences(db, table, p0)
                                .driftWorkoutSetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DriftWorkoutSessionsTableProcessedTableManager
    = ProcessedTableManager<
        _$SbeeDatabase,
        $DriftWorkoutSessionsTable,
        DriftWorkoutSession,
        $$DriftWorkoutSessionsTableFilterComposer,
        $$DriftWorkoutSessionsTableOrderingComposer,
        $$DriftWorkoutSessionsTableAnnotationComposer,
        $$DriftWorkoutSessionsTableCreateCompanionBuilder,
        $$DriftWorkoutSessionsTableUpdateCompanionBuilder,
        (DriftWorkoutSession, $$DriftWorkoutSessionsTableReferences),
        DriftWorkoutSession,
        PrefetchHooks Function({bool driftWorkoutSetsRefs})>;
typedef $$DriftWorkoutSetsTableCreateCompanionBuilder
    = DriftWorkoutSetsCompanion Function({
  required String id,
  required String sessionId,
  required String exerciseId,
  required int movementPattern,
  required int setNumber,
  required int reps,
  required int targetRpe,
  Value<int?> reportedRpe,
  required int loadVal,
  required int bodyPosition,
  required int rom,
  required int height,
  required int tempo,
  required DateTime timestamp,
  Value<int?> restDurationSeconds,
  Value<String?> cuesJson,
  Value<int> rowid,
});
typedef $$DriftWorkoutSetsTableUpdateCompanionBuilder
    = DriftWorkoutSetsCompanion Function({
  Value<String> id,
  Value<String> sessionId,
  Value<String> exerciseId,
  Value<int> movementPattern,
  Value<int> setNumber,
  Value<int> reps,
  Value<int> targetRpe,
  Value<int?> reportedRpe,
  Value<int> loadVal,
  Value<int> bodyPosition,
  Value<int> rom,
  Value<int> height,
  Value<int> tempo,
  Value<DateTime> timestamp,
  Value<int?> restDurationSeconds,
  Value<String?> cuesJson,
  Value<int> rowid,
});

final class $$DriftWorkoutSetsTableReferences extends BaseReferences<
    _$SbeeDatabase, $DriftWorkoutSetsTable, DriftWorkoutSet> {
  $$DriftWorkoutSetsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DriftWorkoutSessionsTable _sessionIdTable(_$SbeeDatabase db) =>
      db.driftWorkoutSessions.createAlias(
          'drift_workout_sets__session_id__drift_workout_sessions__id');

  $$DriftWorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager =
        $$DriftWorkoutSessionsTableTableManager($_db, $_db.driftWorkoutSessions)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DriftWorkoutSetsTableFilterComposer
    extends Composer<_$SbeeDatabase, $DriftWorkoutSetsTable> {
  $$DriftWorkoutSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get movementPattern => $composableBuilder(
      column: $table.movementPattern,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get setNumber => $composableBuilder(
      column: $table.setNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetRpe => $composableBuilder(
      column: $table.targetRpe, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reportedRpe => $composableBuilder(
      column: $table.reportedRpe, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get loadVal => $composableBuilder(
      column: $table.loadVal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bodyPosition => $composableBuilder(
      column: $table.bodyPosition, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rom => $composableBuilder(
      column: $table.rom, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tempo => $composableBuilder(
      column: $table.tempo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restDurationSeconds => $composableBuilder(
      column: $table.restDurationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cuesJson => $composableBuilder(
      column: $table.cuesJson, builder: (column) => ColumnFilters(column));

  $$DriftWorkoutSessionsTableFilterComposer get sessionId {
    final $$DriftWorkoutSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.driftWorkoutSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DriftWorkoutSessionsTableFilterComposer(
              $db: $db,
              $table: $db.driftWorkoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DriftWorkoutSetsTableOrderingComposer
    extends Composer<_$SbeeDatabase, $DriftWorkoutSetsTable> {
  $$DriftWorkoutSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get movementPattern => $composableBuilder(
      column: $table.movementPattern,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get setNumber => $composableBuilder(
      column: $table.setNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetRpe => $composableBuilder(
      column: $table.targetRpe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reportedRpe => $composableBuilder(
      column: $table.reportedRpe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get loadVal => $composableBuilder(
      column: $table.loadVal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bodyPosition => $composableBuilder(
      column: $table.bodyPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rom => $composableBuilder(
      column: $table.rom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tempo => $composableBuilder(
      column: $table.tempo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restDurationSeconds => $composableBuilder(
      column: $table.restDurationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cuesJson => $composableBuilder(
      column: $table.cuesJson, builder: (column) => ColumnOrderings(column));

  $$DriftWorkoutSessionsTableOrderingComposer get sessionId {
    final $$DriftWorkoutSessionsTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.sessionId,
            referencedTable: $db.driftWorkoutSessions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DriftWorkoutSessionsTableOrderingComposer(
                  $db: $db,
                  $table: $db.driftWorkoutSessions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$DriftWorkoutSetsTableAnnotationComposer
    extends Composer<_$SbeeDatabase, $DriftWorkoutSetsTable> {
  $$DriftWorkoutSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => column);

  GeneratedColumn<int> get movementPattern => $composableBuilder(
      column: $table.movementPattern, builder: (column) => column);

  GeneratedColumn<int> get setNumber =>
      $composableBuilder(column: $table.setNumber, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get targetRpe =>
      $composableBuilder(column: $table.targetRpe, builder: (column) => column);

  GeneratedColumn<int> get reportedRpe => $composableBuilder(
      column: $table.reportedRpe, builder: (column) => column);

  GeneratedColumn<int> get loadVal =>
      $composableBuilder(column: $table.loadVal, builder: (column) => column);

  GeneratedColumn<int> get bodyPosition => $composableBuilder(
      column: $table.bodyPosition, builder: (column) => column);

  GeneratedColumn<int> get rom =>
      $composableBuilder(column: $table.rom, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get tempo =>
      $composableBuilder(column: $table.tempo, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get restDurationSeconds => $composableBuilder(
      column: $table.restDurationSeconds, builder: (column) => column);

  GeneratedColumn<String> get cuesJson =>
      $composableBuilder(column: $table.cuesJson, builder: (column) => column);

  $$DriftWorkoutSessionsTableAnnotationComposer get sessionId {
    final $$DriftWorkoutSessionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.sessionId,
            referencedTable: $db.driftWorkoutSessions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DriftWorkoutSessionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.driftWorkoutSessions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$DriftWorkoutSetsTableTableManager extends RootTableManager<
    _$SbeeDatabase,
    $DriftWorkoutSetsTable,
    DriftWorkoutSet,
    $$DriftWorkoutSetsTableFilterComposer,
    $$DriftWorkoutSetsTableOrderingComposer,
    $$DriftWorkoutSetsTableAnnotationComposer,
    $$DriftWorkoutSetsTableCreateCompanionBuilder,
    $$DriftWorkoutSetsTableUpdateCompanionBuilder,
    (DriftWorkoutSet, $$DriftWorkoutSetsTableReferences),
    DriftWorkoutSet,
    PrefetchHooks Function({bool sessionId})> {
  $$DriftWorkoutSetsTableTableManager(
      _$SbeeDatabase db, $DriftWorkoutSetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DriftWorkoutSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DriftWorkoutSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DriftWorkoutSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<int> movementPattern = const Value.absent(),
            Value<int> setNumber = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<int> targetRpe = const Value.absent(),
            Value<int?> reportedRpe = const Value.absent(),
            Value<int> loadVal = const Value.absent(),
            Value<int> bodyPosition = const Value.absent(),
            Value<int> rom = const Value.absent(),
            Value<int> height = const Value.absent(),
            Value<int> tempo = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<int?> restDurationSeconds = const Value.absent(),
            Value<String?> cuesJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DriftWorkoutSetsCompanion(
            id: id,
            sessionId: sessionId,
            exerciseId: exerciseId,
            movementPattern: movementPattern,
            setNumber: setNumber,
            reps: reps,
            targetRpe: targetRpe,
            reportedRpe: reportedRpe,
            loadVal: loadVal,
            bodyPosition: bodyPosition,
            rom: rom,
            height: height,
            tempo: tempo,
            timestamp: timestamp,
            restDurationSeconds: restDurationSeconds,
            cuesJson: cuesJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sessionId,
            required String exerciseId,
            required int movementPattern,
            required int setNumber,
            required int reps,
            required int targetRpe,
            Value<int?> reportedRpe = const Value.absent(),
            required int loadVal,
            required int bodyPosition,
            required int rom,
            required int height,
            required int tempo,
            required DateTime timestamp,
            Value<int?> restDurationSeconds = const Value.absent(),
            Value<String?> cuesJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DriftWorkoutSetsCompanion.insert(
            id: id,
            sessionId: sessionId,
            exerciseId: exerciseId,
            movementPattern: movementPattern,
            setNumber: setNumber,
            reps: reps,
            targetRpe: targetRpe,
            reportedRpe: reportedRpe,
            loadVal: loadVal,
            bodyPosition: bodyPosition,
            rom: rom,
            height: height,
            tempo: tempo,
            timestamp: timestamp,
            restDurationSeconds: restDurationSeconds,
            cuesJson: cuesJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DriftWorkoutSetsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$DriftWorkoutSetsTableReferences._sessionIdTable(db),
                    referencedColumn: $$DriftWorkoutSetsTableReferences
                        ._sessionIdTable(db)
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

typedef $$DriftWorkoutSetsTableProcessedTableManager = ProcessedTableManager<
    _$SbeeDatabase,
    $DriftWorkoutSetsTable,
    DriftWorkoutSet,
    $$DriftWorkoutSetsTableFilterComposer,
    $$DriftWorkoutSetsTableOrderingComposer,
    $$DriftWorkoutSetsTableAnnotationComposer,
    $$DriftWorkoutSetsTableCreateCompanionBuilder,
    $$DriftWorkoutSetsTableUpdateCompanionBuilder,
    (DriftWorkoutSet, $$DriftWorkoutSetsTableReferences),
    DriftWorkoutSet,
    PrefetchHooks Function({bool sessionId})>;
typedef $$DriftExerciseProgressionsTableCreateCompanionBuilder
    = DriftExerciseProgressionsCompanion Function({
  required String exerciseId,
  required int loadVal,
  required int bodyPosition,
  required int rom,
  required int height,
  required int tempo,
  required int competencyLevel,
  required DateTime lastPerformed,
  Value<int> rowid,
});
typedef $$DriftExerciseProgressionsTableUpdateCompanionBuilder
    = DriftExerciseProgressionsCompanion Function({
  Value<String> exerciseId,
  Value<int> loadVal,
  Value<int> bodyPosition,
  Value<int> rom,
  Value<int> height,
  Value<int> tempo,
  Value<int> competencyLevel,
  Value<DateTime> lastPerformed,
  Value<int> rowid,
});

class $$DriftExerciseProgressionsTableFilterComposer
    extends Composer<_$SbeeDatabase, $DriftExerciseProgressionsTable> {
  $$DriftExerciseProgressionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get loadVal => $composableBuilder(
      column: $table.loadVal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bodyPosition => $composableBuilder(
      column: $table.bodyPosition, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rom => $composableBuilder(
      column: $table.rom, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tempo => $composableBuilder(
      column: $table.tempo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get competencyLevel => $composableBuilder(
      column: $table.competencyLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPerformed => $composableBuilder(
      column: $table.lastPerformed, builder: (column) => ColumnFilters(column));
}

class $$DriftExerciseProgressionsTableOrderingComposer
    extends Composer<_$SbeeDatabase, $DriftExerciseProgressionsTable> {
  $$DriftExerciseProgressionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get loadVal => $composableBuilder(
      column: $table.loadVal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bodyPosition => $composableBuilder(
      column: $table.bodyPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rom => $composableBuilder(
      column: $table.rom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tempo => $composableBuilder(
      column: $table.tempo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get competencyLevel => $composableBuilder(
      column: $table.competencyLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPerformed => $composableBuilder(
      column: $table.lastPerformed,
      builder: (column) => ColumnOrderings(column));
}

class $$DriftExerciseProgressionsTableAnnotationComposer
    extends Composer<_$SbeeDatabase, $DriftExerciseProgressionsTable> {
  $$DriftExerciseProgressionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => column);

  GeneratedColumn<int> get loadVal =>
      $composableBuilder(column: $table.loadVal, builder: (column) => column);

  GeneratedColumn<int> get bodyPosition => $composableBuilder(
      column: $table.bodyPosition, builder: (column) => column);

  GeneratedColumn<int> get rom =>
      $composableBuilder(column: $table.rom, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get tempo =>
      $composableBuilder(column: $table.tempo, builder: (column) => column);

  GeneratedColumn<int> get competencyLevel => $composableBuilder(
      column: $table.competencyLevel, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPerformed => $composableBuilder(
      column: $table.lastPerformed, builder: (column) => column);
}

class $$DriftExerciseProgressionsTableTableManager extends RootTableManager<
    _$SbeeDatabase,
    $DriftExerciseProgressionsTable,
    DriftExerciseProgression,
    $$DriftExerciseProgressionsTableFilterComposer,
    $$DriftExerciseProgressionsTableOrderingComposer,
    $$DriftExerciseProgressionsTableAnnotationComposer,
    $$DriftExerciseProgressionsTableCreateCompanionBuilder,
    $$DriftExerciseProgressionsTableUpdateCompanionBuilder,
    (
      DriftExerciseProgression,
      BaseReferences<_$SbeeDatabase, $DriftExerciseProgressionsTable,
          DriftExerciseProgression>
    ),
    DriftExerciseProgression,
    PrefetchHooks Function()> {
  $$DriftExerciseProgressionsTableTableManager(
      _$SbeeDatabase db, $DriftExerciseProgressionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DriftExerciseProgressionsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$DriftExerciseProgressionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DriftExerciseProgressionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> exerciseId = const Value.absent(),
            Value<int> loadVal = const Value.absent(),
            Value<int> bodyPosition = const Value.absent(),
            Value<int> rom = const Value.absent(),
            Value<int> height = const Value.absent(),
            Value<int> tempo = const Value.absent(),
            Value<int> competencyLevel = const Value.absent(),
            Value<DateTime> lastPerformed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DriftExerciseProgressionsCompanion(
            exerciseId: exerciseId,
            loadVal: loadVal,
            bodyPosition: bodyPosition,
            rom: rom,
            height: height,
            tempo: tempo,
            competencyLevel: competencyLevel,
            lastPerformed: lastPerformed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String exerciseId,
            required int loadVal,
            required int bodyPosition,
            required int rom,
            required int height,
            required int tempo,
            required int competencyLevel,
            required DateTime lastPerformed,
            Value<int> rowid = const Value.absent(),
          }) =>
              DriftExerciseProgressionsCompanion.insert(
            exerciseId: exerciseId,
            loadVal: loadVal,
            bodyPosition: bodyPosition,
            rom: rom,
            height: height,
            tempo: tempo,
            competencyLevel: competencyLevel,
            lastPerformed: lastPerformed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DriftExerciseProgressionsTableProcessedTableManager
    = ProcessedTableManager<
        _$SbeeDatabase,
        $DriftExerciseProgressionsTable,
        DriftExerciseProgression,
        $$DriftExerciseProgressionsTableFilterComposer,
        $$DriftExerciseProgressionsTableOrderingComposer,
        $$DriftExerciseProgressionsTableAnnotationComposer,
        $$DriftExerciseProgressionsTableCreateCompanionBuilder,
        $$DriftExerciseProgressionsTableUpdateCompanionBuilder,
        (
          DriftExerciseProgression,
          BaseReferences<_$SbeeDatabase, $DriftExerciseProgressionsTable,
              DriftExerciseProgression>
        ),
        DriftExerciseProgression,
        PrefetchHooks Function()>;
typedef $$DriftStatusAchievedTableCreateCompanionBuilder
    = DriftStatusAchievedCompanion Function({
  required String status,
  required DateTime achievedDate,
  Value<int> rowid,
});
typedef $$DriftStatusAchievedTableUpdateCompanionBuilder
    = DriftStatusAchievedCompanion Function({
  Value<String> status,
  Value<DateTime> achievedDate,
  Value<int> rowid,
});

class $$DriftStatusAchievedTableFilterComposer
    extends Composer<_$SbeeDatabase, $DriftStatusAchievedTable> {
  $$DriftStatusAchievedTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get achievedDate => $composableBuilder(
      column: $table.achievedDate, builder: (column) => ColumnFilters(column));
}

class $$DriftStatusAchievedTableOrderingComposer
    extends Composer<_$SbeeDatabase, $DriftStatusAchievedTable> {
  $$DriftStatusAchievedTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get achievedDate => $composableBuilder(
      column: $table.achievedDate,
      builder: (column) => ColumnOrderings(column));
}

class $$DriftStatusAchievedTableAnnotationComposer
    extends Composer<_$SbeeDatabase, $DriftStatusAchievedTable> {
  $$DriftStatusAchievedTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get achievedDate => $composableBuilder(
      column: $table.achievedDate, builder: (column) => column);
}

class $$DriftStatusAchievedTableTableManager extends RootTableManager<
    _$SbeeDatabase,
    $DriftStatusAchievedTable,
    DriftStatusAchievedData,
    $$DriftStatusAchievedTableFilterComposer,
    $$DriftStatusAchievedTableOrderingComposer,
    $$DriftStatusAchievedTableAnnotationComposer,
    $$DriftStatusAchievedTableCreateCompanionBuilder,
    $$DriftStatusAchievedTableUpdateCompanionBuilder,
    (
      DriftStatusAchievedData,
      BaseReferences<_$SbeeDatabase, $DriftStatusAchievedTable,
          DriftStatusAchievedData>
    ),
    DriftStatusAchievedData,
    PrefetchHooks Function()> {
  $$DriftStatusAchievedTableTableManager(
      _$SbeeDatabase db, $DriftStatusAchievedTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DriftStatusAchievedTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DriftStatusAchievedTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DriftStatusAchievedTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> status = const Value.absent(),
            Value<DateTime> achievedDate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DriftStatusAchievedCompanion(
            status: status,
            achievedDate: achievedDate,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String status,
            required DateTime achievedDate,
            Value<int> rowid = const Value.absent(),
          }) =>
              DriftStatusAchievedCompanion.insert(
            status: status,
            achievedDate: achievedDate,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DriftStatusAchievedTableProcessedTableManager = ProcessedTableManager<
    _$SbeeDatabase,
    $DriftStatusAchievedTable,
    DriftStatusAchievedData,
    $$DriftStatusAchievedTableFilterComposer,
    $$DriftStatusAchievedTableOrderingComposer,
    $$DriftStatusAchievedTableAnnotationComposer,
    $$DriftStatusAchievedTableCreateCompanionBuilder,
    $$DriftStatusAchievedTableUpdateCompanionBuilder,
    (
      DriftStatusAchievedData,
      BaseReferences<_$SbeeDatabase, $DriftStatusAchievedTable,
          DriftStatusAchievedData>
    ),
    DriftStatusAchievedData,
    PrefetchHooks Function()>;

class $SbeeDatabaseManager {
  final _$SbeeDatabase _db;
  $SbeeDatabaseManager(this._db);
  $$DriftWorkoutSessionsTableTableManager get driftWorkoutSessions =>
      $$DriftWorkoutSessionsTableTableManager(_db, _db.driftWorkoutSessions);
  $$DriftWorkoutSetsTableTableManager get driftWorkoutSets =>
      $$DriftWorkoutSetsTableTableManager(_db, _db.driftWorkoutSets);
  $$DriftExerciseProgressionsTableTableManager get driftExerciseProgressions =>
      $$DriftExerciseProgressionsTableTableManager(
          _db, _db.driftExerciseProgressions);
  $$DriftStatusAchievedTableTableManager get driftStatusAchieved =>
      $$DriftStatusAchievedTableTableManager(_db, _db.driftStatusAchieved);
}
