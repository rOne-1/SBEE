import 'package:glados/glados.dart';
import 'package:drift/native.dart';
import 'package:sbee/sbee.dart';

void main() {
  // Use any.int to drive fuzzed history and exercise pool scenarios
  Glados(any.int, ExploreConfig(numRuns: 1000)).test(
    'Postural Balance Generation Enforcement Invariant',
    (seed) async {
      final database = SbeeDatabase(NativeDatabase.memory());
      final sessionRepo = DriftSessionRepository(database);
      final progressionRepo = DriftProgressionRepository(database);

      // Define exercise candidates
      const push1 = Exercise(
          id: 'push1',
          name: 'Push Ex 1',
          movementPattern: MovementPattern.pushing,
          difficultyTier: 1,
          equipmentRequirements: {});
      const push2 = Exercise(
          id: 'push2',
          name: 'Push Ex 2',
          movementPattern: MovementPattern.pushing,
          difficultyTier: 1,
          equipmentRequirements: {});
      const pull1 = Exercise(
          id: 'pull1',
          name: 'Pull Ex 1',
          movementPattern: MovementPattern.pulling,
          difficultyTier: 1,
          equipmentRequirements: {});
      const pull2 = Exercise(
          id: 'pull2',
          name: 'Pull Ex 2',
          movementPattern: MovementPattern.pulling,
          difficultyTier: 1,
          equipmentRequirements: {});
      const other1 = Exercise(
          id: 'other1',
          name: 'Other Ex 1',
          movementPattern: MovementPattern.bendAndLift,
          difficultyTier: 1,
          equipmentRequirements: {});
      const other2 = Exercise(
          id: 'other2',
          name: 'Other Ex 2',
          movementPattern: MovementPattern.rotation,
          difficultyTier: 1,
          equipmentRequirements: {});

      // Randomize which exercises are in the pool
      final exerciseMap = <Exercise, Set<Exercise>>{};

      final includePulls = (seed & 1) == 1; // 50% chance of pulls in pool
      final includePush = (seed & 2) == 2; // 50% chance of pushes in pool
      final includeOthers =
          (seed & 4) == 4; // 50% chance of other exercises in pool

      final pool = <Exercise>[];
      if (includePulls) {
        pool.add(pull1);
        pool.add(pull2);
      }
      if (includePush) {
        pool.add(push1);
        pool.add(push2);
      }
      if (includeOthers) {
        pool.add(other1);
        pool.add(other2);
      }

      // If pool is empty, add at least one pushing and other to make it interesting
      if (pool.isEmpty) {
        pool.add(push1);
        pool.add(other1);
      }

      for (final ex in pool) {
        exerciseMap[ex] = {};
      }

      final graph = ExerciseGraph(exerciseMap);
      final engine = SbeeEngine(
        sessionRepository: sessionRepo,
        progressionRepository: progressionRepo,
        exerciseGraph: graph,
      );

      final currentTime = DateTime(2026, 7, 10, 12, 0);

      // Add a randomized completed workout session history in the 14-day window
      final historyDaysAgo = (seed.abs() % 10) + 1;
      final historyTime = currentTime.subtract(Duration(days: historyDaysAgo));

      final historySets = <WorkoutSet>[];
      final pullHistoryCount = (seed.abs() % 6); // 0 to 5 sets
      final pushHistoryCount = (seed.abs() % 4); // 0 to 3 sets

      for (var i = 0; i < pullHistoryCount; i++) {
        historySets.add(WorkoutSet(
          id: 'hist_pull_$i',
          sessionId: 'hist_session',
          exerciseId: 'pull1',
          movementPattern: MovementPattern.pulling,
          setNumber: i + 1,
          reps: 10,
          targetRpe: 8,
          reportedRpe: 7,
          variables: const MillerVariables(),
          timestamp: historyTime,
        ));
      }

      for (var i = 0; i < pushHistoryCount; i++) {
        historySets.add(WorkoutSet(
          id: 'hist_push_$i',
          sessionId: 'hist_session',
          exerciseId: 'push1',
          movementPattern: MovementPattern.pushing,
          setNumber: i + 1,
          reps: 10,
          targetRpe: 8,
          reportedRpe: 7,
          variables: const MillerVariables(),
          timestamp: historyTime,
        ));
      }

      if (historySets.isNotEmpty) {
        final historySession = WorkoutSession(
          id: 'hist_session',
          startTime: historyTime,
          endTime: historyTime.add(const Duration(minutes: 45)),
          isCompleted: true,
          sets: historySets,
          dayType: DayType.moderate,
        );
        await sessionRepo.saveSession(historySession);
      }

      // Generate the session
      final session = await engine.generateNextWorkout(
        userId: 'test_user',
        currentTime: currentTime,
        availableEquipment: {},
      );

      // Verify invariants

      // 1. "Other" pattern exercises are preserved unconditionally
      final generatedOtherIds = session.sets
          .where((s) =>
              s.movementPattern != MovementPattern.pushing &&
              s.movementPattern != MovementPattern.pulling)
          .map((s) => s.exerciseId)
          .toSet();
      final expectedOtherIds = pool
          .where((e) =>
              e.movementPattern != MovementPattern.pushing &&
              e.movementPattern != MovementPattern.pulling)
          .map((e) => e.id)
          .toSet();
      expect(generatedOtherIds, equals(expectedOtherIds),
          reason: 'Other pattern exercises must be unconditionally included');

      // 2. Output correctly flags warning and reason when pool cannot satisfy the ratio (no pulls available)
      final poolHasPulls =
          pool.any((e) => e.movementPattern == MovementPattern.pulling);
      final poolHasPush =
          pool.any((e) => e.movementPattern == MovementPattern.pushing);

      if (!poolHasPulls && poolHasPush) {
        expect(session.posturalWarningReason,
            equals(PosturalWarningReason.noPullingAvailable));
        expect(
            session.posturalWarning,
            contains(
                'Pushing exercises generated without sufficient pulling options'));
        // Pushing exercises are generated anyway in this fallback
        final hasPushSets = session.sets
            .any((s) => s.movementPattern == MovementPattern.pushing);
        expect(hasPushSets, isTrue);
      }

      // 3. Generator-side push-limiting correctly enforces the 2:1 ratio when pulling is available
      if (poolHasPulls) {
        final newPullCount = session.sets
            .where((s) => s.movementPattern == MovementPattern.pulling)
            .length;
        final newPushCount = session.sets
            .where((s) => s.movementPattern == MovementPattern.pushing)
            .length;

        final totalPull = pullHistoryCount + newPullCount;
        final totalPush = pushHistoryCount + newPushCount;

        // If the ratio is not satisfied, it must be because of a historical deficit that was uncorrectable,
        // which means the generator selected ZERO new pushing exercises (newPushCount == 0).
        if (totalPull < 2 * totalPush) {
          expect(newPushCount, equals(0),
              reason:
                  'If 2:1 ratio cannot be satisfied, new pushing count must be restricted to 0');
          expect(session.posturalWarningReason,
              equals(PosturalWarningReason.historicalDeficit));
          expect(
              session.posturalWarning,
              contains(
                  '2:1 pull-to-push ratio not satisfied due to historical deficit'));
        } else {
          // If the ratio is satisfied, verify it's correctly marked (no warning or historicalDeficit if it was corrected)
          if (session.posturalWarningReason ==
              PosturalWarningReason.historicalDeficit) {
            // It could be that it wasn't satisfied previously but now it is.
            // If it is satisfied, posturalWarningReason should be none.
            expect(totalPull, lessThan(2 * totalPush));
          }
        }
      }

      await database.close();
    },
  );
}
