import 'package:glados/glados.dart';
import 'package:drift/native.dart';
import 'package:sbee/sbee.dart';

void main() {
  // We use any.int as input generator to fuzz and create varied sessions
  Glados(any.int, ExploreConfig(numRuns: 1000)).test(
    'Repository Validation and Exception Invariant',
    (seed) async {
      final db = SbeeDatabase(NativeDatabase.memory());
      final repo = DriftSessionRepository(db);

      final now = DateTime.now();
      final isCompleted = seed.isEven;

      // Let's create an invalid session state based on the seed
      final scenario = seed.abs() % 5;

      String sessionId = 'session_$seed';
      String setId1 = 'set_1_$seed';
      String setId2 = 'set_2_$seed';
      int reps1 = 10;
      int targetRpe1 = 8;

      if (scenario == 0) {
        // Case 1: Empty session ID
        sessionId = '';
      } else if (scenario == 1) {
        // Case 2: Empty set ID
        setId1 = '';
      } else if (scenario == 2) {
        // Case 3: Negative reps
        reps1 = -5;
      } else if (scenario == 3) {
        // Case 4: Negative target RPE
        targetRpe1 = -1;
      } else {
        // Case 5: Duplicate set IDs
        setId2 = setId1;
      }

      final session = WorkoutSession(
        id: sessionId,
        startTime: now,
        endTime: isCompleted ? now.add(const Duration(minutes: 30)) : null,
        isCompleted: isCompleted,
        dayType: DayType.moderate,
        sets: [
          WorkoutSet(
            id: setId1,
            sessionId: sessionId,
            exerciseId: 'ex_1',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: reps1,
            targetRpe: targetRpe1,
            variables: const MillerVariables(),
            timestamp: now,
          ),
          WorkoutSet(
            id: setId2,
            sessionId: sessionId,
            exerciseId: 'ex_2',
            movementPattern: MovementPattern.pulling,
            setNumber: 2,
            reps: 10,
            targetRpe: 8,
            variables: const MillerVariables(),
            timestamp: now,
          ),
        ],
      );

      // Verify that the repository saveSession call throws a SessionRepositoryException
      expect(
        () => repo.saveSession(session),
        throwsA(isA<SessionRepositoryException>()),
        reason:
            'Scenario $scenario with seed $seed must throw SessionRepositoryException',
      );

      await db.close();
    },
  );
}
