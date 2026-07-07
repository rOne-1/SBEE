import 'package:drift/drift.dart';
import 'tables.dart';

part 'database.g.dart';

/// Concrete modular database setup for the SBEE core.
@DriftDatabase(tables: [
  DriftWorkoutSessions,
  DriftWorkoutSets,
  DriftExerciseProgressions,
  DriftStatusAchieved,
])
class SbeeDatabase extends _$SbeeDatabase {
  SbeeDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
