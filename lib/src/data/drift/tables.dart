import 'package:drift/drift.dart';

/// Drift representation of workout sessions.
class DriftWorkoutSessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get dayType => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift representation of individual sets within workout sessions.
class DriftWorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().customConstraint('REFERENCES drift_workout_sessions(id) ON DELETE CASCADE NOT NULL')();
  TextColumn get exerciseId => text()();
  IntColumn get movementPattern => integer()(); // Enum index
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer()();
  IntColumn get targetRpe => integer()();
  IntColumn get reportedRpe => integer().nullable()();
  
  // Kenneth Miller's 5-variable progression variables
  IntColumn get loadVal => integer()();
  IntColumn get bodyPosition => integer()();
  IntColumn get rom => integer()();
  IntColumn get height => integer()();
  IntColumn get tempo => integer()();

  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift representation of the user's progression status on specific exercises.
class DriftExerciseProgressions extends Table {
  TextColumn get exerciseId => text()();
  
  // Kenneth Miller's 5-variable progression parameters
  IntColumn get loadVal => integer()();
  IntColumn get bodyPosition => integer()();
  IntColumn get rom => integer()();
  IntColumn get height => integer()();
  IntColumn get tempo => integer()();
  
  IntColumn get competencyLevel => integer()(); // E.g., 1=Beginner, 2=Intermediate, 3=Advanced
  DateTimeColumn get lastPerformed => dateTime()();

  @override
  Set<Column> get primaryKey => {exerciseId};
}

/// Drift representation of overall user milestones or status achievement dates (e.g. 'Intermediate').
class DriftStatusAchieved extends Table {
  TextColumn get status => text()();
  DateTimeColumn get achievedDate => dateTime()();

  @override
  Set<Column> get primaryKey => {status};
}
