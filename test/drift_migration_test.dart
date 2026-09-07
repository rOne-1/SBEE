import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:drift/native.dart';
import 'package:sbee/sbee.dart';

void main() {
  group('Drift Database Migration Tests', () {
    test('Upgrade path from schema version 1 to 4 runs successfully', () async {
      // 1. Open a raw in-memory sqlite3 database
      final rawDb = sqlite3.openInMemory();

      // 2. Setup Version 1 Schema (lacks day_type, rest_duration_seconds, cues_json, postural_warning, postural_warning_reason and indexes)
      rawDb.execute('''
        CREATE TABLE drift_workout_sessions (
          id TEXT NOT NULL PRIMARY KEY,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          is_completed INTEGER NOT NULL DEFAULT 0
        );
      ''');

      rawDb.execute('''
        CREATE TABLE drift_workout_sets (
          id TEXT NOT NULL PRIMARY KEY,
          session_id TEXT NOT NULL REFERENCES drift_workout_sessions(id) ON DELETE CASCADE,
          exercise_id TEXT NOT NULL,
          movement_pattern INTEGER NOT NULL,
          set_number INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          target_rpe INTEGER NOT NULL,
          reported_rpe INTEGER,
          load_val INTEGER NOT NULL,
          body_position INTEGER NOT NULL,
          rom INTEGER NOT NULL,
          height INTEGER NOT NULL,
          tempo INTEGER NOT NULL,
          timestamp INTEGER NOT NULL
        );
      ''');

      rawDb.execute('''
        CREATE TABLE drift_exercise_progressions (
          exercise_id TEXT NOT NULL PRIMARY KEY,
          load_val INTEGER NOT NULL,
          body_position INTEGER NOT NULL,
          rom INTEGER NOT NULL,
          height INTEGER NOT NULL,
          tempo INTEGER NOT NULL,
          competency_level INTEGER NOT NULL,
          last_performed INTEGER NOT NULL
        );
      ''');

      rawDb.execute('''
        CREATE TABLE drift_status_achieved (
          status TEXT NOT NULL PRIMARY KEY,
          achieved_date INTEGER NOT NULL
        );
      ''');

      // Set user_version to version 1
      rawDb.execute('PRAGMA user_version = 1;');

      // Verify that version 1 doesn't have the dayType column in sessions
      var columns = rawDb.select('PRAGMA table_info(drift_workout_sessions);');
      var columnNames = columns.map((row) => row['name'] as String).toList();
      expect(columnNames, isNot(contains('day_type')));
      expect(columnNames, isNot(contains('postural_warning')));
      expect(columnNames, isNot(contains('postural_warning_reason')));

      // 3. Initialize SbeeDatabase (runs onUpgrade from 1 to 3)
      final db = SbeeDatabase(NativeDatabase.opened(rawDb));
      
      // Let's force db open and migration execution by running a simple query
      await db.select(db.driftWorkoutSessions).get();

      // 4. Verify that schema version 2 columns are successfully added
      columns = rawDb.select('PRAGMA table_info(drift_workout_sessions);');
      columnNames = columns.map((row) => row['name'] as String).toList();
      expect(columnNames, contains('day_type'));
      expect(columnNames, contains('postural_warning'));
      expect(columnNames, contains('postural_warning_reason'));

      columns = rawDb.select('PRAGMA table_info(drift_workout_sets);');
      columnNames = columns.map((row) => row['name'] as String).toList();
      expect(columnNames, contains('rest_duration_seconds'));
      expect(columnNames, contains('cues_json'));
      expect(columnNames, contains('min_reps'));
      expect(columnNames, contains('max_reps'));

      // 5. Test inserts and reads into the version 3/4 columns via repositories
      final sessionRepo = DriftSessionRepository(db);
      final now = DateTime.now();
      final testSession = WorkoutSession(
        id: 'session_v3_test',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        isCompleted: true,
        dayType: DayType.veryHeavy,
        posturalWarning: 'Historical deficit warning',
        posturalWarningReason: PosturalWarningReason.historicalDeficit,
        sets: [
          WorkoutSet(
            id: 'set_v3_test',
            sessionId: 'session_v3_test',
            exerciseId: 'ex_test',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 5,
            minReps: 1,
            maxReps: 5,
            targetRpe: 9,
            variables: const MillerVariables(),
            timestamp: now,
            restDuration: const Duration(seconds: 45),
            cues: ['Test Cue 1', 'Test Cue 2'],
          ),
        ],
      );

      await sessionRepo.saveSession(testSession);

      final retrieved = await sessionRepo.getSession('session_v3_test');
      expect(retrieved, isNotNull);
      expect(retrieved!.dayType, equals(DayType.veryHeavy));
      expect(retrieved.posturalWarning, equals('Historical deficit warning'));
      expect(retrieved.posturalWarningReason, equals(PosturalWarningReason.historicalDeficit));
      expect(retrieved.sets.length, equals(1));
      expect(retrieved.sets.first.restDuration, equals(const Duration(seconds: 45)));
      expect(retrieved.sets.first.cues, contains('Test Cue 1'));
      expect(retrieved.sets.first.minReps, equals(1));
      expect(retrieved.sets.first.maxReps, equals(5));

      await db.close();
    });
  });
}
