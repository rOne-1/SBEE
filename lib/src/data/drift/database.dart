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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Assume v1 lacked the dayType column in DriftWorkoutSessions table, and v2 adds it.
            // Also adds the restDurationSeconds and cuesJson to DriftWorkoutSets table.
            await m.addColumn(
                driftWorkoutSessions, driftWorkoutSessions.dayType);
            await m.addColumn(
                driftWorkoutSets, driftWorkoutSets.restDurationSeconds);
            await m.addColumn(driftWorkoutSets, driftWorkoutSets.cuesJson);

            // Create new indexes using generated Index instances
            await m.createIndex(idxWorkoutSessionsTime);
            await m.createIndex(idxWorkoutSetsPatternTime);
          }
          if (from < 3) {
            await m.addColumn(
                driftWorkoutSessions, driftWorkoutSessions.posturalWarning);
            await m.addColumn(driftWorkoutSessions,
                driftWorkoutSessions.posturalWarningReason);
          }
          if (from < 4) {
            // Adds the min/max prescribed rep-range columns to DriftWorkoutSets,
            // introduced alongside DayType-driven prescription generation.
            await m.addColumn(driftWorkoutSets, driftWorkoutSets.minReps);
            await m.addColumn(driftWorkoutSets, driftWorkoutSets.maxReps);
          }
        },
      );
}
