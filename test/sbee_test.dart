import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:sbee/sbee.dart';
import 'package:sbee/src/engine/autoregulation.dart';
import 'package:sbee/src/engine/safety_rules.dart';
import 'package:sbee/src/engine/session_state_machine.dart';

void main() {
  group('ExerciseGraph Tests', () {
    final exA = Exercise(
      id: 'A',
      name: 'Push-up Tier 1',
      movementPattern: MovementPattern.pushing,
      difficultyTier: 1,
      equipmentRequirements: {},
    );
    final exB = Exercise(
      id: 'B',
      name: 'Push-up Tier 2',
      movementPattern: MovementPattern.pushing,
      difficultyTier: 2,
      equipmentRequirements: {},
    );
    final exC = Exercise(
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
      expect(graph.getTopologicalOrder().map((e) => e.id).toList(), equals(['A', 'B', 'C']));
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
      expect(AutoregulationEngine.evaluate(reportedRpe: 5, targetRpe: 7), equals(AutoregulationAction.increment));
      expect(AutoregulationEngine.evaluate(reportedRpe: 5, targetRpe: 6), equals(AutoregulationAction.maintain));

      // Reported RPE > Target RPE + 1 => regress
      expect(AutoregulationEngine.evaluate(reportedRpe: 9, targetRpe: 7), equals(AutoregulationAction.regress));
      expect(AutoregulationEngine.evaluate(reportedRpe: 8, targetRpe: 7), equals(AutoregulationAction.maintain));

      // Reported RPE within bounds => maintain
      expect(AutoregulationEngine.evaluate(reportedRpe: 7, targetRpe: 7), equals(AutoregulationAction.maintain));
    });

    test('Correctly adjusts Miller variables (Load > Pos > ROM > Height > Tempo)', () {
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
      vars = MillerVariables(load: 5);
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
      final vars = const MillerVariables(load: 5, bodyPosition: 5, rom: 5, height: 5, tempo: 1);

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

    test('DriftSessionRepository saves and retrieves sessions and sets', () async {
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

    test('DriftProgressionRepository tracks competency and status date', () async {
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
      final achievedDate = await progressionRepo.getStatusAchievedDate('Intermediate');
      expect(achievedDate, isNotNull);
      expect(achievedDate!.year, equals(now.year));
    });
  });
}
