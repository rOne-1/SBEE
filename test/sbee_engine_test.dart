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

    test('generateNextWorkout prescribes DayType-driven reps/RPE instead of a hardcoded default', () async {
      final now = DateTime.now();
      final workout = await engine.generateNextWorkout(
        userId: 'user_1',
        currentTime: now,
        availableEquipment: {Equipment.bands},
      );

      // First-ever workout has no history, so PeriodizationScheduler defaults to moderate.
      expect(workout.dayType, equals(DayType.moderate));
      expect(workout.sets, isNotEmpty);
      for (final set in workout.sets) {
        expect(set.reps, equals(10));
        expect(set.minReps, equals(8));
        expect(set.maxReps, equals(12));
        expect(set.targetRpe, equals(8));
      }
    });

    test('generateNextWorkout uses EMOM-structured reps on highLactic days', () async {
      final now = DateTime.now();
      // Seed one completed veryLight session (recent enough to avoid the 14-day
      // detraining redirect) so the DUP rotation schedules highLactic next.
      await sessionRepo.saveSession(WorkoutSession(
        id: 'prior_session',
        startTime: now.subtract(const Duration(days: 3)),
        endTime: now.subtract(const Duration(days: 3)).add(const Duration(minutes: 30)),
        isCompleted: true,
        dayType: DayType.veryLight,
      ));

      final workout = await engine.generateNextWorkout(
        userId: 'user_1',
        currentTime: now,
        availableEquipment: {Equipment.bands},
      );

      expect(workout.dayType, equals(DayType.highLactic));
      expect(workout.sets, isNotEmpty);
      for (final set in workout.sets) {
        expect(set.minReps, equals(set.maxReps), reason: 'EMOM prescribes a single fixed rep count, not a range');
        expect(set.reps, equals(set.minReps));
        expect(set.cues.any((c) => c.contains('EMOM Structure')), isTrue);
      }
      // Neither exercise has prior progression, so competencyLevel defaults to
      // 1 (beginner): 20s max duration / 3s per rep = 6 reps.
      expect(workout.sets.first.reps, equals(6));
    });

    test('Per-exercise competencyLevel is promoted after enough completed sets', () async {
      for (var i = 0; i < 8; i++) {
        await sessionRepo.saveSession(WorkoutSession(
          id: 'sess_$i',
          startTime: DateTime.now(),
          isCompleted: true,
          sets: [
            WorkoutSet(
              id: 'set_$i',
              sessionId: 'sess_$i',
              exerciseId: 'A',
              movementPattern: MovementPattern.pushing,
              setNumber: 1,
              reps: 10,
              targetRpe: 7,
              reportedRpe: 7,
              variables: const MillerVariables(),
              timestamp: DateTime.now(),
            ),
          ],
        ));
        await engine.logSetPerformance(exerciseId: 'A', reps: 10, reportedRpe: 7, targetRpe: 7);
      }

      final prog = await progressionRepo.getProgression('A');
      expect(prog, isNotNull);
      expect(prog!.competencyLevel, equals(2));
    });

    test('generateNextWorkout auto-detects Intermediate status once session-count and day-spread thresholds are met', () async {
      final now = DateTime.now();
      final earliest = now.subtract(const Duration(days: 20));

      await sessionRepo.saveSession(WorkoutSession(
        id: 'seed_first',
        startTime: earliest,
        endTime: earliest.add(const Duration(minutes: 30)),
        isCompleted: true,
        dayType: DayType.moderate,
      ));
      for (var i = 0; i < 11; i++) {
        await sessionRepo.saveSession(WorkoutSession(
          id: 'seed_$i',
          startTime: now.subtract(const Duration(days: 1)),
          endTime: now.subtract(const Duration(days: 1)).add(const Duration(minutes: 30)),
          isCompleted: true,
          dayType: DayType.moderate,
        ));
      }

      expect(await progressionRepo.getStatusAchievedDate('Intermediate'), isNull);

      await engine.generateNextWorkout(userId: 'user_1', currentTime: now, availableEquipment: {Equipment.bands});

      expect(await progressionRepo.getStatusAchievedDate('Intermediate'), isNotNull);
    });

    test('generateNextWorkout withholds Intermediate status below the session-count threshold', () async {
      final now = DateTime.now();
      final earliest = now.subtract(const Duration(days: 20));
      for (var i = 0; i < 5; i++) {
        await sessionRepo.saveSession(WorkoutSession(
          id: 'seed_few_$i',
          startTime: earliest.add(Duration(days: i)),
          isCompleted: true,
          dayType: DayType.moderate,
        ));
      }

      await engine.generateNextWorkout(userId: 'user_1', currentTime: now, availableEquipment: {Equipment.bands});

      expect(await progressionRepo.getStatusAchievedDate('Intermediate'), isNull);
    });
  });
}
