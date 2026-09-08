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

    const exA = Exercise(
      id: 'A',
      name: 'Push-up Level 1',
      movementPattern: MovementPattern.pushing,
      difficultyTier: 1,
      equipmentRequirements: {},
    );

    const exB = Exercise(
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

    test(
        'logSetPerformance triggers DAG progression when maxed out and under-stimulated',
        () async {
      // 1. Initialize progression for Exercise A to max limits
      final initialProg = ExerciseProgression(
        exerciseId: 'A',
        variables: const MillerVariables(
            load: 5, bodyPosition: 5, rom: 5, height: 5, tempo: 2),
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

    test(
        'logSetPerformance triggers predecessor-traversal-and-max-out regression when at baseline and over-stimulated',
        () async {
      // 1. Initialize progression for Exercise B at minimum baseline
      final initialProg = ExerciseProgression(
        exerciseId: 'B',
        variables: const MillerVariables(
            load: 1, bodyPosition: 1, rom: 1, height: 1, tempo: 1),
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

    test(
        'generateNextWorkout filters equipment, recovery locks, and joint-pain plyometrics',
        () async {
      final now = DateTime.now();

      // Case 1: No equipment and joint pain active
      const femaleProfileWithPain = FemaleProfile(
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
      expect(workout.sets.any((s) => s.exerciseId == 'B'), isFalse,
          reason: 'ExB should be excluded as plyometric under joint pain');

      // Case 3: Both allowed when bands are available and joint pain is false
      const femaleProfileNoPain = FemaleProfile(
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
      expect(workout.sets.any((s) => s.exerciseId == 'B'), isTrue,
          reason:
              'ExB is allowed when equipment matches and plyo is not gated');
    });

    test(
        'generateNextWorkout excludes plyometrics via the general hasJointPain flag, with no FemaleProfile at all',
        () async {
      // Before this flag existed, excluding plyometrics required a
      // FemaleProfile AND age >= 45 AND hasJointPain -- a general-population
      // account had no way to ask for jumping/high-skill movements to be
      // excluded at all.
      final workoutExcluded = await engine.generateNextWorkout(
        userId: 'user_1',
        currentTime: DateTime.now(),
        availableEquipment: {Equipment.bands},
        hasJointPain: true,
      );
      expect(workoutExcluded.sets.any((s) => s.exerciseId == 'B'), isFalse,
          reason: 'General hasJointPain flag should exclude plyometrics with no profile involved');

      final workoutAllowed = await engine.generateNextWorkout(
        userId: 'user_1',
        currentTime: DateTime.now(),
        availableEquipment: {Equipment.bands},
        hasJointPain: false,
      );
      expect(workoutAllowed.sets.any((s) => s.exerciseId == 'B'), isTrue,
          reason: 'Default (false) should not exclude anything');
    });

    test(
        'generateNextWorkout uses DayType-driven rest for a general account, not a flat 90s',
        () async {
      // Before this fix, restDuration was only ever DayType-aware for
      // accounts with a FemaleProfile; everyone else always got a flat 90s
      // regardless of whether the day was a strength or conditioning focus.
      final workout = await engine.generateNextWorkout(
        userId: 'user_1',
        currentTime: DateTime.now(),
        availableEquipment: {},
      );
      final prescription = DayTypePrescription.forDayType(workout.dayType!);
      expect(workout.sets, isNotEmpty);
      for (final set in workout.sets) {
        expect(set.restDuration, equals(prescription.restInterval),
            reason: 'General accounts should get the DayType-driven rest interval by default');
      }
    });

    test(
        'generateNextWorkout falls back to a light recovery session when every movement pattern is locked',
        () async {
      final now = DateTime.now();

      // Log a near-maximal set for the only movement pattern this graph has
      // (pushing, via exA/exB) 1 hour ago -- locks pushing for 48h, which
      // means every exercise in this graph is locked at once.
      await sessionRepo.saveSession(WorkoutSession(
        id: 'heavy_session',
        startTime: now.subtract(const Duration(hours: 1)),
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 'heavy_set',
            sessionId: 'heavy_session',
            exerciseId: 'A',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 5,
            targetRpe: 9,
            reportedRpe: 9,
            variables: const MillerVariables(),
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ));

      final workout = await engine.generateNextWorkout(
        userId: 'user_1',
        currentTime: now,
        // exB (bands) stays excluded regardless; exA (bodyweight) is the
        // only candidate, and it would normally be filtered out by the lock.
        availableEquipment: {},
      );

      expect(workout.sets, isNotEmpty,
          reason:
              'Should fall back to a light session instead of generating nothing');
      expect(workout.recoveryReason,
          equals(RecoveryReason.allMovementPatternsLocked));
      expect(
          workout.sets
              .every((s) => s.targetRpe == SbeeEngine.recoveryFallbackTargetRpe),
          isTrue,
          reason: 'Every set should be capped at the recovery-fallback RPE');
      final exASets =
          workout.sets.where((s) => s.exerciseId == 'A').length;
      expect(exASets, equals(SbeeEngine.recoveryFallbackSetsCount));
      expect(workout.posturalWarningReason, equals(PosturalWarningReason.none),
          reason:
              'Postural push/pull balancing should not fire during a recovery fallback session');
    });

    test(
        'generateNextWorkout stays empty (no recovery fallback) when nothing is equipment-eligible even ignoring the lock',
        () async {
      final bandsOnlyGraph = ExerciseGraph({
        const Exercise(
          id: 'bandsOnly',
          name: 'Band Row',
          movementPattern: MovementPattern.pulling,
          difficultyTier: 1,
          equipmentRequirements: {Equipment.bands},
        ): <Exercise>{},
      });
      final bandsOnlyEngine = SbeeEngine(
        sessionRepository: sessionRepo,
        progressionRepository: progressionRepo,
        exerciseGraph: bandsOnlyGraph,
      );

      final workout = await bandsOnlyEngine.generateNextWorkout(
        userId: 'user_1',
        currentTime: DateTime.now(),
        availableEquipment: const {}, // No bands, and the only exercise needs them
      );

      expect(workout.sets, isEmpty);
      expect(workout.recoveryReason, equals(RecoveryReason.none));
    });

    test(
        'generateNextWorkout caps a fresh account to beginnerMaxDifficultyTier even with full equipment',
        () async {
      const beginnerEx = Exercise(
        id: 'beginner_squat',
        name: 'Bodyweight Squat',
        movementPattern: MovementPattern.bendAndLift,
        difficultyTier: 1,
        equipmentRequirements: {},
      );
      const specialtyEx = Exercise(
        id: 'pistol_squat',
        name: 'Pistol Squat',
        movementPattern: MovementPattern.singleLeg,
        difficultyTier: 6,
        equipmentRequirements: {},
      );
      final mixedGraph = ExerciseGraph({
        beginnerEx: <Exercise>{},
        specialtyEx: <Exercise>{},
      });
      final mixedEngine = SbeeEngine(
        sessionRepository: sessionRepo,
        progressionRepository: progressionRepo,
        exerciseGraph: mixedGraph,
      );

      final workout = await mixedEngine.generateNextWorkout(
        userId: 'user_1',
        currentTime: DateTime.now(),
        availableEquipment: Equipment.values.toSet(),
      );

      expect(workout.sets.any((s) => s.exerciseId == 'beginner_squat'), isTrue);
      expect(workout.sets.any((s) => s.exerciseId == 'pistol_squat'), isFalse,
          reason: 'A fresh account has no Intermediate status yet, so tier 6 should stay locked out');
    });

    test(
        'generateNextWorkout unlocks tier 4+ exercises once whole-account Intermediate status is achieved',
        () async {
      const beginnerEx = Exercise(
        id: 'beginner_squat',
        name: 'Bodyweight Squat',
        movementPattern: MovementPattern.bendAndLift,
        difficultyTier: 1,
        equipmentRequirements: {},
      );
      const specialtyEx = Exercise(
        id: 'pistol_squat',
        name: 'Pistol Squat',
        movementPattern: MovementPattern.singleLeg,
        difficultyTier: 6,
        equipmentRequirements: {},
      );
      final mixedGraph = ExerciseGraph({
        beginnerEx: <Exercise>{},
        specialtyEx: <Exercise>{},
      });
      final mixedEngine = SbeeEngine(
        sessionRepository: sessionRepo,
        progressionRepository: progressionRepo,
        exerciseGraph: mixedGraph,
      );

      await progressionRepo.saveStatusAchievedDate('Intermediate', DateTime.now());

      final workout = await mixedEngine.generateNextWorkout(
        userId: 'user_1',
        currentTime: DateTime.now(),
        availableEquipment: Equipment.values.toSet(),
      );

      expect(workout.sets.any((s) => s.exerciseId == 'pistol_squat'), isTrue,
          reason: 'Once Intermediate status is on record, tier 6 exercises should be eligible');
    });

    test(
        'generateNextWorkout keeps the beginner tier cap active even during the recovery fallback',
        () async {
      const beginnerEx = Exercise(
        id: 'beginner_squat',
        name: 'Bodyweight Squat',
        movementPattern: MovementPattern.bendAndLift,
        difficultyTier: 1,
        equipmentRequirements: {},
      );
      const specialtyEx = Exercise(
        id: 'pistol_squat',
        name: 'Pistol Squat',
        movementPattern: MovementPattern.singleLeg,
        difficultyTier: 6,
        equipmentRequirements: {},
      );
      final mixedGraph = ExerciseGraph({
        beginnerEx: <Exercise>{},
        specialtyEx: <Exercise>{},
      });
      final mixedEngine = SbeeEngine(
        sessionRepository: sessionRepo,
        progressionRepository: progressionRepo,
        exerciseGraph: mixedGraph,
      );

      final now = DateTime.now();
      // Lock the only pattern a beginner is actually eligible for
      // (bendAndLift, via beginner_squat) so the recovery fallback engages.
      await sessionRepo.saveSession(WorkoutSession(
        id: 'heavy_session',
        startTime: now.subtract(const Duration(hours: 1)),
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 'heavy_set',
            sessionId: 'heavy_session',
            exerciseId: 'beginner_squat',
            movementPattern: MovementPattern.bendAndLift,
            setNumber: 1,
            reps: 10,
            targetRpe: 8,
            reportedRpe: 8,
            variables: const MillerVariables(),
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ));

      final workout = await mixedEngine.generateNextWorkout(
        userId: 'user_1',
        currentTime: now,
        availableEquipment: Equipment.values.toSet(),
      );

      // The recovery fallback ignores the 48h lock (so beginner_squat still
      // shows up at reduced intensity), but it must not reach for the tier-6
      // exercise just because it's technically equipment-eligible -- a
      // fatigued beginner should get a light familiar movement, never a
      // sudden jump to an advanced one just because everything else is locked.
      expect(workout.recoveryReason, equals(RecoveryReason.allMovementPatternsLocked));
      expect(workout.sets.any((s) => s.exerciseId == 'beginner_squat'), isTrue);
      expect(workout.sets.any((s) => s.exerciseId == 'pistol_squat'), isFalse);
    });

    test(
        'generateNextWorkout prescribes DayType-driven reps/RPE instead of a hardcoded default',
        () async {
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
      // moderate's setsCount (4) unchanged from the prior flat default: 4 sets per exercise.
      expect(workout.sets.where((s) => s.exerciseId == 'A').length, equals(4));
      expect(workout.sets.where((s) => s.exerciseId == 'B').length, equals(4));
    });

    test(
        'generateNextWorkout uses DayType-driven setsCount, not a flat default',
        () async {
      final now = DateTime.now();
      // Seed one completed moderate session so the DUP rotation schedules veryHeavy next.
      await sessionRepo.saveSession(WorkoutSession(
        id: 'prior_moderate_session',
        startTime: now.subtract(const Duration(days: 2)),
        endTime: now
            .subtract(const Duration(days: 2))
            .add(const Duration(minutes: 30)),
        isCompleted: true,
        dayType: DayType.moderate,
      ));

      final workout = await engine.generateNextWorkout(
        userId: 'user_1',
        currentTime: now,
        availableEquipment: {Equipment.bands},
      );

      expect(workout.dayType, equals(DayType.veryHeavy));
      // veryHeavy prescribes 5 sets per exercise, not the old flat default of 4.
      expect(workout.sets.where((s) => s.exerciseId == 'A').length, equals(5));
      expect(workout.sets.where((s) => s.exerciseId == 'B').length, equals(5));
    });

    test('generateNextWorkout uses EMOM-structured reps on highLactic days',
        () async {
      final now = DateTime.now();
      // Seed one completed veryLight session (recent enough to avoid the 14-day
      // detraining redirect) so the DUP rotation schedules highLactic next.
      await sessionRepo.saveSession(WorkoutSession(
        id: 'prior_session',
        startTime: now.subtract(const Duration(days: 3)),
        endTime: now
            .subtract(const Duration(days: 3))
            .add(const Duration(minutes: 30)),
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
        expect(set.minReps, equals(set.maxReps),
            reason: 'EMOM prescribes a single fixed rep count, not a range');
        expect(set.reps, equals(set.minReps));
        expect(set.cues.any((c) => c.contains('EMOM Structure')), isTrue);
      }
      // Neither exercise has prior progression, so competencyLevel defaults to
      // 1 (beginner): 20s max duration / 3s per rep = 6 reps.
      expect(workout.sets.first.reps, equals(6));
      // highLactic prescribes 6 EMOM rounds per exercise.
      expect(workout.sets.where((s) => s.exerciseId == 'A').length, equals(6));
      expect(workout.sets.where((s) => s.exerciseId == 'B').length, equals(6));
    });

    test('Per-exercise competencyLevel is promoted after enough completed sets',
        () async {
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
        await engine.logSetPerformance(
            exerciseId: 'A', reps: 10, reportedRpe: 7, targetRpe: 7);
      }

      final prog = await progressionRepo.getProgression('A');
      expect(prog, isNotNull);
      expect(prog!.competencyLevel, equals(2));
    });

    test(
        'generateNextWorkout auto-detects Intermediate status once session-count and day-spread thresholds are met',
        () async {
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
          endTime: now
              .subtract(const Duration(days: 1))
              .add(const Duration(minutes: 30)),
          isCompleted: true,
          dayType: DayType.moderate,
        ));
      }

      expect(
          await progressionRepo.getStatusAchievedDate('Intermediate'), isNull);

      await engine.generateNextWorkout(
          userId: 'user_1',
          currentTime: now,
          availableEquipment: {Equipment.bands});

      expect(await progressionRepo.getStatusAchievedDate('Intermediate'),
          isNotNull);
    });

    test(
        'generateNextWorkout withholds Intermediate status below the session-count threshold',
        () async {
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

      await engine.generateNextWorkout(
          userId: 'user_1',
          currentTime: now,
          availableEquipment: {Equipment.bands});

      expect(
          await progressionRepo.getStatusAchievedDate('Intermediate'), isNull);
    });

    test(
        'resumeActiveSession recovers a workout interrupted mid-session (no finalize called)',
        () async {
      final now = DateTime.now();
      final workout = await engine.generateNextWorkout(
        userId: 'user_1',
        currentTime: now,
        availableEquipment: {Equipment.bands},
      );
      expect(workout.sets.length, greaterThan(1),
          reason: 'need at least 2 sets for a meaningful resume test');

      // Simulate starting the workout and logging only the first set, then "crashing"
      // (no finalizeSession(), no explicit saveSession() by the host app).
      final manager = engine.createWorkoutSession(session: workout);
      manager.startWorkout();
      manager.logCurrentSet(
          reps: workout.sets.first.reps,
          reportedRpe: workout.sets.first.targetRpe);
      await Future<void>.delayed(
          Duration.zero); // let the fire-and-forget persist land
      manager.dispose();

      // Nothing else in this test calls sessionRepository.saveSession directly: recovery
      // must come entirely from the manager's own incremental persistence.
      expect(await sessionRepo.getActiveIncompleteSession(), isNotNull);

      final resumed = await engine.resumeActiveSession();
      expect(resumed, isNotNull);
      expect(resumed!.currentState.session!.id, equals(workout.id));
      expect(resumed.currentState.currentSetIndex, equals(1));
      expect(resumed.currentState.state, equals(SessionState.activeSet));
      expect(resumed.currentState.session!.sets.first.reportedRpe,
          equals(workout.sets.first.targetRpe));

      resumed.dispose();
    });

    test('resumeActiveSession returns null when there is nothing to resume',
        () async {
      expect(await engine.resumeActiveSession(), isNull);
    });
  });
}
