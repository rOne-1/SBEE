import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:sbee/sbee.dart';
import 'package:sbee/src/engine/autoregulation.dart';
import 'package:sbee/src/engine/session_state_machine.dart';

void main() {
  group('ExerciseGraph Tests', () {
    const exA = Exercise(
      id: 'A',
      name: 'Push-up Tier 1',
      movementPattern: MovementPattern.pushing,
      difficultyTier: 1,
      equipmentRequirements: {},
    );
    const exB = Exercise(
      id: 'B',
      name: 'Push-up Tier 2',
      movementPattern: MovementPattern.pushing,
      difficultyTier: 2,
      equipmentRequirements: {},
    );
    const exC = Exercise(
      id: 'C',
      name: 'Push-up Tier 3',
      movementPattern: MovementPattern.pushing,
      difficultyTier: 3,
      equipmentRequirements: {},
    );

    test('Successfully builds acyclic graph and sorts topologically', () {
      final graphMap = <Exercise, Set<Exercise>>{
        exA: {exB},
        exB: {exC},
        exC: {},
      };

      final graph = ExerciseGraph(graphMap);
      expect(graph.exercises.length, equals(3));
      expect(graph.getTopologicalOrder().map((e) => e.id).toList(),
          equals(['A', 'B', 'C']));
      expect(graph.getProgressions(exA), equals([exB]));
      expect(graph.getRegressions(exC), equals([exB]));
      expect(graph.findById('B'), equals(exB));
    });

    test('Throws ArgumentError if a cycle is introduced', () {
      final graphMap = <Exercise, Set<Exercise>>{
        exA: {exB},
        exB: {exC},
        exC: {exA}, // Cycle A -> B -> C -> A
      };

      expect(() => ExerciseGraph(graphMap), throwsArgumentError);
    });
  });

  group('AutoregulationEngine Tests', () {
    test('Correctly evaluates RPE differences', () {
      // Reported RPE < Target RPE - 1 => increment
      expect(AutoregulationEngine.evaluate(reportedRpe: 5, targetRpe: 7),
          equals(AutoregulationAction.increment));
      expect(AutoregulationEngine.evaluate(reportedRpe: 5, targetRpe: 6),
          equals(AutoregulationAction.maintain));

      // Reported RPE > Target RPE + 1 => regress
      expect(AutoregulationEngine.evaluate(reportedRpe: 9, targetRpe: 7),
          equals(AutoregulationAction.regress));
      expect(AutoregulationEngine.evaluate(reportedRpe: 8, targetRpe: 7),
          equals(AutoregulationAction.maintain));

      // Reported RPE within bounds => maintain
      expect(AutoregulationEngine.evaluate(reportedRpe: 7, targetRpe: 7),
          equals(AutoregulationAction.maintain));
    });

    test(
        'Correctly adjusts Miller variables (Load > Pos > ROM > Height > Tempo)',
        () {
      var vars = const MillerVariables();
      expect(vars.load, equals(1));

      // Increment load
      vars = AutoregulationEngine.adjustVariables(
        currentVariables: vars,
        reportedRpe: 5,
        targetRpe: 7,
      );
      expect(vars.load, equals(2));
      expect(vars.bodyPosition, equals(1));

      // Max out load
      vars = const MillerVariables(load: 5);
      vars = AutoregulationEngine.adjustVariables(
        currentVariables: vars,
        reportedRpe: 4,
        targetRpe: 7,
      );
      expect(vars.load, equals(5));
      // Should now increment Body Position (next priority)
      expect(vars.bodyPosition, equals(2));

      // Regress should decrement Body Position before Load
      vars = AutoregulationEngine.adjustVariables(
        currentVariables: vars,
        reportedRpe: 9,
        targetRpe: 7,
      );
      expect(vars.bodyPosition, equals(1));
      expect(vars.load, equals(5));

      // Regress load
      vars = const MillerVariables(load: 2, bodyPosition: 1);
      vars = AutoregulationEngine.adjustVariables(
        currentVariables: vars,
        reportedRpe: 9,
        targetRpe: 7,
      );
      expect(vars.load, equals(1));
    });

    test('Locks advanced tempo (level 2) if flag is false', () {
      const vars = MillerVariables(
          load: 5, bodyPosition: 5, rom: 5, height: 5, tempo: 1);

      // Try incrementing tempo without unlock flag
      final resLocked = AutoregulationEngine.adjustVariables(
        currentVariables: vars,
        reportedRpe: 5,
        targetRpe: 7,
        isAdvancedTempoUnlocked: false,
      );
      expect(resLocked.tempo, equals(1));

      // Try incrementing tempo with unlock flag
      final resUnlocked = AutoregulationEngine.adjustVariables(
        currentVariables: vars,
        reportedRpe: 5,
        targetRpe: 7,
        isAdvancedTempoUnlocked: true,
      );
      expect(resUnlocked.tempo, equals(2));
    });
  });

  group('SessionStateMachine & Stream Tests', () {
    test('SessionStateMachine enforces correct transitions', () {
      final fsm = SessionStateMachine();
      expect(fsm.currentState, equals(SessionState.warmUp));

      fsm.startWorkout();
      expect(fsm.currentState, equals(SessionState.activeSet));

      fsm.completeSet();
      expect(fsm.currentState, equals(SessionState.rest));

      fsm.startNextSet();
      expect(fsm.currentState, equals(SessionState.activeSet));

      fsm.completeWorkout();
      expect(fsm.currentState, equals(SessionState.coolDown));

      fsm.finishSession();
      expect(fsm.currentState, equals(SessionState.completed));

      expect(() => fsm.startWorkout(), throwsStateError);
    });

    test('SessionStreamManager pipelines workout flow reactively', () async {
      final manager = SessionStreamManager();
      final session = WorkoutSession(
        id: 'session_123',
        startTime: DateTime.now(),
        sets: [
          WorkoutSet(
            id: 'set_1',
            sessionId: 'session_123',
            exerciseId: 'ex_1',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 7,
            variables: const MillerVariables(),
            timestamp: DateTime.now(),
          ),
          WorkoutSet(
            id: 'set_2',
            sessionId: 'session_123',
            exerciseId: 'ex_1',
            movementPattern: MovementPattern.pushing,
            setNumber: 2,
            reps: 10,
            targetRpe: 7,
            variables: const MillerVariables(),
            timestamp: DateTime.now(),
          ),
        ],
      );

      manager.initializeSession(session);
      expect(manager.currentState.state, equals(SessionState.warmUp));

      manager.startWorkout();
      expect(manager.currentState.state, equals(SessionState.activeSet));
      expect(manager.currentState.currentSetIndex, equals(0));

      // Log first set
      manager.logCurrentSet(reps: 10, reportedRpe: 6);
      expect(manager.currentState.state, equals(SessionState.rest));
      expect(manager.currentState.session!.sets[0].reportedRpe, equals(6));

      // Start next set
      manager.startNextSet();
      expect(manager.currentState.state, equals(SessionState.activeSet));
      expect(manager.currentState.currentSetIndex, equals(1));

      // Log second (last) set -> goes to Cool-down
      manager.logCurrentSet(reps: 12, reportedRpe: 7);
      expect(manager.currentState.state, equals(SessionState.coolDown));

      // Finalize session -> completed
      manager.finalizeSession();
      expect(manager.currentState.state, equals(SessionState.completed));
      expect(manager.currentState.session!.isCompleted, isTrue);

      manager.dispose();
    });

    test(
        'SessionStreamManager persists progress incrementally when given a repository',
        () async {
      final database = SbeeDatabase(NativeDatabase.memory());
      final sessionRepo = DriftSessionRepository(database);
      final manager = SessionStreamManager(sessionRepository: sessionRepo);

      final session = WorkoutSession(
        id: 'mid_workout_session',
        startTime: DateTime.now(),
        sets: [
          WorkoutSet(
            id: 'mw_set_1',
            sessionId: 'mid_workout_session',
            exerciseId: 'ex_1',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 7,
            variables: const MillerVariables(),
            timestamp: DateTime.now(),
          ),
          WorkoutSet(
            id: 'mw_set_2',
            sessionId: 'mid_workout_session',
            exerciseId: 'ex_1',
            movementPattern: MovementPattern.pushing,
            setNumber: 2,
            reps: 10,
            targetRpe: 7,
            variables: const MillerVariables(),
            timestamp: DateTime.now(),
          ),
        ],
      );

      manager.initializeSession(session);
      manager.startWorkout();
      manager.logCurrentSet(reps: 10, reportedRpe: 6);

      // Fire-and-forget persistence: give the microtask queue a turn to flush.
      await Future<void>.delayed(Duration.zero);

      // Crucially, this is checked WITHOUT ever calling finalizeSession() or the host
      // app's own explicit saveSession() -- this is what "mid-workout" means.
      final persisted = await sessionRepo.getActiveIncompleteSession();
      expect(persisted, isNotNull);
      expect(persisted!.id, equals('mid_workout_session'));
      expect(persisted.isCompleted, isFalse);
      expect(persisted.sets[0].reportedRpe, equals(6));
      expect(persisted.sets[1].reportedRpe, isNull);

      manager.dispose();
      await database.close();
    });

    test(
        'SessionStreamManager.resumeSession restores the FSM at the next unlogged set',
        () {
      final now = DateTime.now();
      final partiallyLoggedSession = WorkoutSession(
        id: 'resume_session',
        startTime: now,
        isCompleted: false,
        sets: [
          WorkoutSet(
            id: 'r_set_1',
            sessionId: 'resume_session',
            exerciseId: 'ex_1',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 7,
            reportedRpe: 6, // already logged
            variables: const MillerVariables(),
            timestamp: now,
          ),
          WorkoutSet(
            id: 'r_set_2',
            sessionId: 'resume_session',
            exerciseId: 'ex_1',
            movementPattern: MovementPattern.pushing,
            setNumber: 2,
            reps: 10,
            targetRpe: 7,
            reportedRpe: null, // not yet logged
            variables: const MillerVariables(),
            timestamp: now,
          ),
        ],
      );

      final manager = SessionStreamManager();
      manager.resumeSession(partiallyLoggedSession);

      expect(manager.currentState.state, equals(SessionState.activeSet));
      expect(manager.currentState.currentSetIndex, equals(1));
      expect(manager.currentState.session!.sets[0].reportedRpe, equals(6));

      // The FSM correctly resumed: logging the remaining set completes the workout.
      manager.logCurrentSet(reps: 10, reportedRpe: 7);
      expect(manager.currentState.state, equals(SessionState.coolDown));

      manager.dispose();
    });

    test(
        'SessionStreamManager.resumeSession resumes at coolDown if every set was already logged',
        () {
      final now = DateTime.now();
      final fullyLoggedSession = WorkoutSession(
        id: 'resume_all_logged',
        startTime: now,
        isCompleted: false,
        sets: [
          WorkoutSet(
            id: 'ral_set_1',
            sessionId: 'resume_all_logged',
            exerciseId: 'ex_1',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 7,
            reportedRpe: 6,
            variables: const MillerVariables(),
            timestamp: now,
          ),
        ],
      );

      final manager = SessionStreamManager();
      manager.resumeSession(fullyLoggedSession);

      expect(manager.currentState.state, equals(SessionState.coolDown));
      expect(manager.currentState.currentSetIndex, equals(0));

      manager.finalizeSession();
      expect(manager.currentState.state, equals(SessionState.completed));

      manager.dispose();
    });

    test(
        'SessionStreamManager.resumeSession rejects resuming while a session is already active',
        () {
      final now = DateTime.now();
      final session = WorkoutSession(
        id: 'active_already',
        startTime: now,
        sets: [
          WorkoutSet(
            id: 'aa_set_1',
            sessionId: 'active_already',
            exerciseId: 'ex_1',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 7,
            variables: const MillerVariables(),
            timestamp: now,
          ),
        ],
      );

      final manager = SessionStreamManager();
      manager.initializeSession(session);

      expect(() => manager.resumeSession(session), throwsStateError);

      manager.dispose();
    });
  });

  group('Drift Repositories Tests', () {
    late SbeeDatabase database;
    late DriftSessionRepository sessionRepo;
    late DriftProgressionRepository progressionRepo;

    setUp(() {
      database = SbeeDatabase(NativeDatabase.memory());
      sessionRepo = DriftSessionRepository(database);
      progressionRepo = DriftProgressionRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('DriftSessionRepository saves and retrieves sessions and sets',
        () async {
      final now = DateTime.now();
      final session = WorkoutSession(
        id: 'session_1',
        startTime: now,
        endTime: now.add(const Duration(minutes: 45)),
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 'set_1',
            sessionId: 'session_1',
            exerciseId: 'ex_push',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 8,
            targetRpe: 8,
            reportedRpe: 8,
            variables: const MillerVariables(load: 3, bodyPosition: 2),
            timestamp: now,
          ),
        ],
      );

      await sessionRepo.saveSession(session);

      final retrieved = await sessionRepo.getSession('session_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('session_1'));
      expect(retrieved.isCompleted, isTrue);
      expect(retrieved.sets.length, equals(1));
      expect(retrieved.sets[0].variables.load, equals(3));
      expect(retrieved.sets[0].variables.bodyPosition, equals(2));

      // Test querying by movement pattern
      final pushingSets = await sessionRepo.getSetsForMovementPattern(
        MovementPattern.pushing,
        now.subtract(const Duration(days: 1)),
      );
      expect(pushingSets.length, equals(1));
      expect(pushingSets[0].exerciseId, equals('ex_push'));
    });

    test(
        'DriftSessionRepository bounded-query methods replace full-history scans',
        () async {
      final base = DateTime(2026, 1, 1, 12, 0);

      // Nothing saved yet: all bounded queries should report the empty case.
      expect(await sessionRepo.getMostRecentCompletedSession(), isNull);
      expect(
          await sessionRepo.getMostRecentCompletedSession(requireDayType: true),
          isNull);
      expect(await sessionRepo.getEarliestCompletedSessionStart(), isNull);
      expect(await sessionRepo.getCompletedSessionCount(), equals(0));
      expect(
          await sessionRepo.getReportedSetCountForExercise('ex_a'), equals(0));
      expect(await sessionRepo.getActiveIncompleteSession(), isNull);

      // Earliest completed session (no dayType).
      await sessionRepo.saveSession(WorkoutSession(
        id: 'earliest',
        startTime: base,
        isCompleted: true,
      ));

      // A later completed session that does have a dayType, with 2 reported sets for ex_a.
      await sessionRepo.saveSession(WorkoutSession(
        id: 'middle',
        startTime: base.add(const Duration(days: 5)),
        isCompleted: true,
        dayType: DayType.moderate,
        sets: [
          WorkoutSet(
            id: 'set_a1',
            sessionId: 'middle',
            exerciseId: 'ex_a',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 8,
            reportedRpe: 8,
            variables: const MillerVariables(),
            timestamp: base.add(const Duration(days: 5)),
          ),
          WorkoutSet(
            id: 'set_a2',
            sessionId: 'middle',
            exerciseId: 'ex_a',
            movementPattern: MovementPattern.pushing,
            setNumber: 2,
            reps: 10,
            targetRpe: 8,
            reportedRpe: null, // not yet reported: must not count
            variables: const MillerVariables(),
            timestamp: base.add(const Duration(days: 5)),
          ),
        ],
      ));

      // The most recent session overall, which is still in progress (not completed).
      await sessionRepo.saveSession(WorkoutSession(
        id: 'in_progress',
        startTime: base.add(const Duration(days: 10)),
        isCompleted: false,
        sets: [
          WorkoutSet(
            id: 'set_a3',
            sessionId: 'in_progress',
            exerciseId: 'ex_a',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 8,
            reportedRpe: 7,
            variables: const MillerVariables(),
            timestamp: base.add(const Duration(days: 10)),
          ),
        ],
      ));

      // Most recent completed session (ignores the in-progress one): 'middle'.
      final mostRecent = await sessionRepo.getMostRecentCompletedSession();
      expect(mostRecent?.id, equals('middle'));

      // Most recent completed session WITH a dayType: still 'middle' (the only one with one).
      final mostRecentWithDayType =
          await sessionRepo.getMostRecentCompletedSession(requireDayType: true);
      expect(mostRecentWithDayType?.id, equals('middle'));

      // Earliest completed session start: 'earliest', not the later or in-progress ones.
      expect(
          await sessionRepo.getEarliestCompletedSessionStart(), equals(base));

      // Only 2 completed sessions ('earliest', 'middle') -- the in-progress one doesn't count.
      expect(await sessionRepo.getCompletedSessionCount(), equals(2));

      // Only 1 of ex_a's 3 sets has a non-null reportedRpe from a would-be-counted set in a
      // completed context... but this count intentionally covers sets from ANY session
      // (including in-progress ones) since a set is either reported or not, regardless of
      // whether its parent session has been finalized yet: 2 reported sets for ex_a total
      // (set_a1 from 'middle' and set_a3 from 'in_progress'); set_a2 is unreported.
      expect(
          await sessionRepo.getReportedSetCountForExercise('ex_a'), equals(2));
      expect(await sessionRepo.getReportedSetCountForExercise('ex_nonexistent'),
          equals(0));

      // Active incomplete session: 'in_progress'.
      final incomplete = await sessionRepo.getActiveIncompleteSession();
      expect(incomplete?.id, equals('in_progress'));
    });

    test('DriftProgressionRepository tracks competency and status date',
        () async {
      final now = DateTime.now();
      final progression = ExerciseProgression(
        exerciseId: 'ex_lunge',
        variables: const MillerVariables(load: 2, rom: 3),
        competencyLevel: 2,
        lastPerformed: now,
      );

      await progressionRepo.saveProgression(progression);

      final retrieved = await progressionRepo.getProgression('ex_lunge');
      expect(retrieved, isNotNull);
      expect(retrieved!.competencyLevel, equals(2));
      expect(retrieved.variables.load, equals(2));
      expect(retrieved.variables.rom, equals(3));

      // Test status dates
      await progressionRepo.saveStatusAchievedDate('Intermediate', now);
      final achievedDate =
          await progressionRepo.getStatusAchievedDate('Intermediate');
      expect(achievedDate, isNotNull);
      expect(achievedDate!.year, equals(now.year));
    });
  });
}
