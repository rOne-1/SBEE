import 'package:test/test.dart';
import 'package:drift/native.dart';
import 'package:sbee/sbee.dart';

void main() {
  group('SbeeEngine Tests', () {
    late SbeeDatabase database;
    late DriftSessionRepository sessionRepo;
    late DriftProgressionRepository progressionRepo;
    late ExerciseGraph graph;
    late SbeeEngine engine;

    final exA = Exercise(
      id: 'A',
      name: 'Push-up Level 1',
      movementPattern: MovementPattern.pushing,
      difficultyTier: 1,
      equipmentRequirements: {},
    );

    final exB = Exercise(
      id: 'B',
      name: 'Push-up Level 2 (jumping/plyo)',
      movementPattern: MovementPattern.pushing,
      difficultyTier: 2,
      equipmentRequirements: {Equipment.bands},
    );

    setUp(() {
      database = SbeeDatabase(NativeDatabase.memory());
      sessionRepo = DriftSessionRepository(database);
      progressionRepo = DriftProgressionRepository(database);
      graph = ExerciseGraph({
        exA: {exB},
        exB: {},
      });
      engine = SbeeEngine(
        sessionRepository: sessionRepo,
        progressionRepository: progressionRepo,
        exerciseGraph: graph,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('logSetPerformance triggers DAG progression when maxed out and under-stimulated', () async {
      // 1. Initialize progression for Exercise A to max limits
      final initialProg = ExerciseProgression(
        exerciseId: 'A',
        variables: const MillerVariables(load: 5, bodyPosition: 5, rom: 5, height: 5, tempo: 2),
        competencyLevel: 1,
        lastPerformed: DateTime.now(),
      );
      await progressionRepo.saveProgression(initialProg);

      // 2. Log under-stimulated performance (reported RPE 5, target RPE 8)
      final vars = await engine.logSetPerformance(
        exerciseId: 'A',
        reps: 10,
        reportedRpe: 5,
        targetRpe: 8,
      );

      // 3. Expected to reset to baseline and progress to Exercise B
      expect(vars.load, equals(1));
      expect(vars.tempo, equals(1));

      final progB = await progressionRepo.getProgression('B');
      expect(progB, isNotNull);
      expect(progB!.variables.load, equals(1));
    });

    test('logSetPerformance triggers predecessor-traversal-and-max-out regression when at baseline and over-stimulated', () async {
      // 1. Initialize progression for Exercise B at minimum baseline
      final initialProg = ExerciseProgression(
        exerciseId: 'B',
        variables: const MillerVariables(load: 1, bodyPosition: 1, rom: 1, height: 1, tempo: 1),
        competencyLevel: 1,
        lastPerformed: DateTime.now(),
      );
      await progressionRepo.saveProgression(initialProg);

      // 2. Log over-stimulated performance (reported RPE 9, target RPE 6)
      final vars = await engine.logSetPerformance(
        exerciseId: 'B',
        reps: 5,
        reportedRpe: 9,
        targetRpe: 6,
      );

      // 3. Expected to regress to Exercise A and max out its variables to sustain stimulus
      expect(vars.load, equals(5));
      expect(vars.tempo, equals(2));

      final progA = await progressionRepo.getProgression('A');
      expect(progA, isNotNull);
      expect(progA!.variables.load, equals(5));
      expect(progA.variables.tempo, equals(2));
    });

    test('generateNextWorkout filters equipment, recovery locks, and joint-pain plyometrics', () async {
      final now = DateTime.now();

      // Case 1: No equipment and joint pain active
      final femaleProfileWithPain = const FemaleProfile(
        userStatus: 'Trained_Female',
        cycleDay: 10,
        hasKneeDiscomfort: false,
        age: 46,
        hasJointPain: true,
      );

      // Generating workout with empty equipment and joint pain
      var workout = await engine.generateNextWorkout(
        userId: 'user_1',
        currentTime: now,
        availableEquipment: {}, // Excludes bands, so exB is excluded by equipment requirement. exA is bodyweight, allowed.
        femaleProfile: femaleProfileWithPain,
      );

      // Exercise B requires bands and contains 'plyo' in name, so it is definitely excluded.
      // Exercise A is included.
      expect(workout.sets.any((s) => s.exerciseId == 'A'), isTrue);
      expect(workout.sets.any((s) => s.exerciseId == 'B'), isFalse);

      // Case 2: Exclude plyo due to name (containing 'jumping' or 'plyo') under joint pain
      // Even if bands are available, exB is excluded because it's plyo and user has joint pain!
      workout = await engine.generateNextWorkout(
        userId: 'user_1',
        currentTime: now,
        availableEquipment: {Equipment.bands},
        femaleProfile: femaleProfileWithPain,
      );
      expect(workout.sets.any((s) => s.exerciseId == 'B'), isFalse, reason: 'ExB should be excluded as plyometric under joint pain');

      // Case 3: Both allowed when bands are available and joint pain is false
      final femaleProfileNoPain = const FemaleProfile(
        userStatus: 'Trained_Female',
        cycleDay: 10,
        hasKneeDiscomfort: false,
        age: 46,
        hasJointPain: false,
      );
      workout = await engine.generateNextWorkout(
        userId: 'user_1',
        currentTime: now,
        availableEquipment: {Equipment.bands},
        femaleProfile: femaleProfileNoPain,
      );
      expect(workout.sets.any((s) => s.exerciseId == 'B'), isTrue, reason: 'ExB is allowed when equipment matches and plyo is not gated');
    });
  });
}
