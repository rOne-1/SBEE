import 'dart:math';
import 'domain/models/day_type.dart';
import 'domain/models/equipment.dart';
import 'domain/models/exercise.dart';
import 'domain/models/movement_pattern.dart';
import 'domain/models/workout_session.dart';
import 'engine/miller_variables.dart';
import 'domain/progression/exercise_graph.dart';
import 'domain/repositories/progression_repository.dart';
import 'domain/repositories/session_repository.dart';
import 'engine/female_wrapper.dart';
import 'engine/session_stream.dart';
import 'engine/scheduler.dart';
import 'engine/detraining.dart';
import 'engine/safety_rules.dart';
import 'engine/autoregulation.dart';

/// The central SBEE orchestrator facade coordinating periodization, deload,
/// safety rules, female physiology wrappers, and DAG progression traversals.
class SbeeEngine {
  final SessionRepository sessionRepository;
  final ProgressionRepository progressionRepository;
  final ExerciseGraph exerciseGraph;

  SbeeEngine({
    required this.sessionRepository,
    required this.progressionRepository,
    required this.exerciseGraph,
  });

  /// Logs a set's execution, evaluates target RPE, and adjusts MillerVariables.
  /// 
  /// **DAG Progression/Regression Traversal Logic**:
  /// - If the new variables reach max limit (`load=5, bodyPosition=5, rom=5, height=5, tempo=2`)
  ///   and RPE continues to report as under-stimulated, the engine queries the `exerciseGraph` for successors,
  ///   unlocks the next exercise tier, and resets the MillerVariables back to baseline (`1,1,1,1,1`).
  /// - If the new variables are at min baseline (`1,1,1,1,1`) and RPE evaluates as over-stimulated,
  ///   the engine queries the `exerciseGraph` for predecessors, regresses the exercise tier, and maxes out
  ///   the predecessor's variables to sustain safe stimulus.
  Future<MillerVariables> logSetPerformance({
    required String exerciseId,
    required int reps,
    required int reportedRpe,
    required int targetRpe,
    FemaleProfile? femaleProfile,
  }) async {
    final currentExercise = exerciseGraph.findById(exerciseId);
    if (currentExercise == null) {
      throw ArgumentError('Exercise $exerciseId not found in graph');
    }

    // 1. Fetch current progression state.
    var prog = await progressionRepository.getProgression(exerciseId);
    if (prog == null) {
      prog = ExerciseProgression(
        exerciseId: exerciseId,
        variables: const MillerVariables(load: 1, bodyPosition: 1, rom: 1, height: 1, tempo: 1),
        competencyLevel: 1,
        lastPerformed: DateTime.now(),
      );
    }

    // 2. Pre-process targetRpe using FemalePhysiologyWrapper.adjustTargetRpe if femaleProfile is active.
    final adjustedTarget = femaleProfile != null
        ? FemalePhysiologyWrapper.adjustTargetRpe(originalTargetRpe: targetRpe, profile: femaleProfile)
        : targetRpe;

    // 3. Query Intermediate status date via progressionRepository. If achieved > 21 days ago, set isAdvancedTempoUnlocked = true.
    final intermediateDate = await progressionRepository.getStatusAchievedDate('Intermediate');
    final bool isAdvancedTempoUnlocked = intermediateDate != null &&
        DateTime.now().difference(intermediateDate).inDays >= 21;

    // 4. Compute next variables using AutoregulationEngine.adjustVariables.
    final nextVars = AutoregulationEngine.adjustVariables(
      currentVariables: prog.variables,
      reportedRpe: reportedRpe,
      targetRpe: adjustedTarget,
      isAdvancedTempoUnlocked: isAdvancedTempoUnlocked,
    );

    // 5. Evaluate if variables are maxed out (trigger progression) or at minimum (trigger regression) across the exerciseGraph DAG.
    final isMaxLimit = nextVars.load == 5 &&
        nextVars.bodyPosition == 5 &&
        nextVars.rom == 5 &&
        nextVars.height == 5 &&
        nextVars.tempo == 2;
    
    final isMinLimit = nextVars.load == 1 &&
        nextVars.bodyPosition == 1 &&
        nextVars.rom == 1 &&
        nextVars.height == 1 &&
        nextVars.tempo == 1;

    final action = AutoregulationEngine.evaluate(reportedRpe: reportedRpe, targetRpe: adjustedTarget);

    if (isMaxLimit && action == AutoregulationAction.increment) {
      // Trigger progression to successors
      final successors = exerciseGraph.getProgressions(currentExercise);
      if (successors.isNotEmpty) {
        final nextExercise = successors.first;
        final baseVars = const MillerVariables(load: 1, bodyPosition: 1, rom: 1, height: 1, tempo: 1);
        
        final newProg = ExerciseProgression(
          exerciseId: nextExercise.id,
          variables: baseVars,
          competencyLevel: prog.competencyLevel,
          lastPerformed: DateTime.now(),
        );
        await progressionRepository.saveProgression(newProg);
        await progressionRepository.saveProgression(prog.copyWith(variables: nextVars, lastPerformed: DateTime.now()));
        return baseVars;
      }
    }

    /// APP-SPECIFIC DESIGN DECISION: Predecessor-Traversal-and-Max-Out Regression Logic
    /// When the user evaluates as over-stimulated (RPE > target + 1) at the lowest possible
    /// baseline variables tier (1, 1, 1, 1, 1), the engine regresses to the predecessor exercise
    /// in the progression DAG. To sustain stimulus while maintaining safety and avoiding excessive
    /// training drop-off, the regressed exercise is assigned the maximum variable limits
    /// (5, 5, 5, 5, 2) rather than resetting to baseline.
    if (isMinLimit && action == AutoregulationAction.regress) {
      final predecessors = exerciseGraph.getRegressions(currentExercise);
      if (predecessors.isNotEmpty) {
        final prevExercise = predecessors.first;
        final maxVars = const MillerVariables(load: 5, bodyPosition: 5, rom: 5, height: 5, tempo: 2);

        final newProg = ExerciseProgression(
          exerciseId: prevExercise.id,
          variables: maxVars,
          competencyLevel: prog.competencyLevel,
          lastPerformed: DateTime.now(),
        );
        await progressionRepository.saveProgression(newProg);
        await progressionRepository.saveProgression(prog.copyWith(variables: nextVars, lastPerformed: DateTime.now()));
        return maxVars;
      }
    }

    // Save updated progression and variables, then return.
    final updatedProg = prog.copyWith(variables: nextVars, lastPerformed: DateTime.now());
    await progressionRepository.saveProgression(updatedProg);
    return nextVars;
  }

  /// Generates the next scheduled workout session, applying periodization,
  /// deload, detraining lockout redirection, and female physiology wrapper cues/rest adjustments.
  Future<WorkoutSession> generateNextWorkout({
    required String userId,
    required DateTime currentTime,
    required Set<Equipment> availableEquipment,
    FemaleProfile? femaleProfile,
  }) async {
    // 1. Retrieve completed sessions.
    // Querying since epoch (1970) to retrieve all historical data.
    final completedSessions = await sessionRepository
        .getSessionsInDateRange(DateTime(1970), currentTime)
        .then((list) => list.where((s) => s.isCompleted).toList());

    // 2. Determine DayType. Apply detraining lock if inactivity >= 14 days (moderate redirect).
    var dayType = PeriodizationScheduler.getNextDayType(completedSessions);
    final isDetrained = DetrainingLogic.isDetrainingActive(
      completedSessions: completedSessions,
      currentTime: currentTime,
    );
    if (isDetrained && (dayType == DayType.veryHeavy || dayType == DayType.power)) {
      dayType = DayType.moderate; // Redirect
    }

    // 3. Resolve if Deload week is active.
    final isDeload = PeriodizationScheduler.isDeloadActive(
      completedSessions: completedSessions,
      currentTime: currentTime,
    );

    // 4. Select exercises corresponding to the scheduled training focus:
    //    - Filter out exercises whose movement patterns are locked under the 48h recovery gate.
    //    - Filter out exercises requiring equipment not present in availableEquipment.
    //    - Wire isPlyometricsAllowed: if female profile has joint pain, exclude plyometric exercises.
    final excludePlyometrics = femaleProfile != null &&
        !FemalePhysiologyWrapper.isPlyometricsAllowed(profile: femaleProfile);

    final filteredExercises = <Exercise>[];
    for (final exercise in exerciseGraph.exercises) {
      // Equipment check
      final hasEquipment = exercise.equipmentRequirements.every((req) => availableEquipment.contains(req));
      if (!hasEquipment) continue;

      // 48h Recovery Lock check
      final isLocked = await isMovementLocked(
        pattern: exercise.movementPattern,
        currentTime: currentTime,
      );
      if (isLocked) continue;

      // Joint pain plyometric check
      if (excludePlyometrics) {
        final nameLower = exercise.name.toLowerCase();
        if (nameLower.contains('jumping') || nameLower.contains('plyo')) {
          continue; // Exclude plyometrics
        }
      }

      filteredExercises.add(exercise);
    }

    // 5. Calculate H_pull and H_push from the 14-day history.
    final completedSessions14d = completedSessions
        .where((s) => s.startTime.isAfter(currentTime.subtract(const Duration(days: 14))))
        .toList();
    final historySets = completedSessions14d.expand((s) => s.sets).toList();

    final H_pull = historySets.where((s) => s.movementPattern == MovementPattern.pulling).length;
    final H_push = historySets.where((s) => s.movementPattern == MovementPattern.pushing).length;

    // Helper to calculate sets count for an exercise.
    int calculateExerciseSetsCount(Exercise exercise) {
      var count = 4;
      if (isDeload) {
        count = (count / 2).ceil();
      }
      if (femaleProfile != null) {
        count = FemalePhysiologyWrapper.adjustMinSets(originalMinSets: count, profile: femaleProfile);
      }
      return count;
    }

    // Group exercises by pattern.
    final pullingExercises = <Exercise>[];
    final pushingExercises = <Exercise>[];
    final otherExercises = <Exercise>[];

    for (final ex in filteredExercises) {
      if (ex.movementPattern == MovementPattern.pulling) {
        pullingExercises.add(ex);
      } else if (ex.movementPattern == MovementPattern.pushing) {
        pushingExercises.add(ex);
      } else {
        otherExercises.add(ex);
      }
    }

    // Sum total new pulling sets N_pull.
    var N_pull = 0;
    for (final ex in pullingExercises) {
      N_pull += calculateExerciseSetsCount(ex);
    }

    // Shuffle the pushing exercises list deterministically to promote variety.
    final shuffledPushing = List<Exercise>.from(pushingExercises);
    shuffledPushing.shuffle(Random(currentTime.millisecondsSinceEpoch));

    final selectedPushing = <Exercise>[];
    var N_push = 0;

    String? posturalWarning;
    PosturalWarningReason posturalWarningReason = PosturalWarningReason.none;

    final fallbackNoPulling = pullingExercises.isEmpty && pushingExercises.isNotEmpty;

    if (fallbackNoPulling) {
      // Generate pushing exercises anyway
      selectedPushing.addAll(shuffledPushing);
      for (final ex in shuffledPushing) {
        N_push += calculateExerciseSetsCount(ex);
      }
      posturalWarning = 'Postural warning: Pushing exercises generated without sufficient pulling options (2:1 ratio not satisfied).';
      posturalWarningReason = PosturalWarningReason.noPullingAvailable;
    } else {
      // Select pushing exercises sequentially checking the 2:1 postural balance ratio
      for (final ex in shuffledPushing) {
        final setsCount = calculateExerciseSetsCount(ex);
        if (H_pull + N_pull >= 2 * (H_push + N_push + setsCount)) {
          selectedPushing.add(ex);
          N_push += setsCount;
        }
      }
    }

    // Construct final list of exercises maintaining original order where applicable.
    // SCALING CONSIDERATION: Unconditional inclusion of all pulling exercises is a known scaling consideration for future large-scale catalogs.
    // SCALING CONSIDERATION: Unconditional inclusion of all other-pattern exercises is also a scaling consideration if an exercise-per-session cap is introduced in the future.
    final finalExercises = <Exercise>[];
    for (final ex in filteredExercises) {
      if (ex.movementPattern == MovementPattern.pulling) {
        finalExercises.add(ex);
      } else if (ex.movementPattern == MovementPattern.pushing) {
        if (selectedPushing.contains(ex)) {
          finalExercises.add(ex);
        }
      } else {
        finalExercises.add(ex);
      }
    }

    // Verify 2:1 ratio (combined history + session)
    if (posturalWarningReason == PosturalWarningReason.none) {
      if ((H_pull + N_pull) < 2 * (H_push + N_push)) {
        posturalWarning = 'Postural warning: 2:1 pull-to-push ratio not satisfied due to historical deficit.';
        posturalWarningReason = PosturalWarningReason.historicalDeficit;
      }
    }

    // 6. Construct WorkoutSession.
    final sessionId = 'session_${currentTime.millisecondsSinceEpoch}';
    final sets = <WorkoutSet>[];
    var setGlobalId = 1;

    for (final exercise in finalExercises) {
      final prog = await progressionRepository.getProgression(exercise.id);
      final vars = prog?.variables ?? const MillerVariables(load: 1, bodyPosition: 1, rom: 1, height: 1, tempo: 1);

      final setsCount = calculateExerciseSetsCount(exercise);

      // Generate WorkoutSets. If deload is active, cap targetRpe at 6.
      var targetRpeForSet = 8;
      if (isDeload) {
        targetRpeForSet = 6;
      }
      if (femaleProfile != null) {
        targetRpeForSet = FemalePhysiologyWrapper.adjustTargetRpe(originalTargetRpe: targetRpeForSet, profile: femaleProfile);
      }

      final trainingFocus = (dayType == DayType.power || dayType == DayType.highLactic || dayType == DayType.veryLight)
          ? 'conditioning'
          : 'strength';

      // Apply rest duration adjustRestInterval (conditioning 45s, strength 150s, menses +30s offset)
      final restDuration = femaleProfile != null
          ? FemalePhysiologyWrapper.adjustRestInterval(
              originalRest: const Duration(seconds: 90),
              trainingFocus: trainingFocus,
              profile: femaleProfile,
            )
          : const Duration(seconds: 90);

      // Append pelvic/spine safety cues and joint check flags to set instructions.
      final cues = femaleProfile != null
          ? FemalePhysiologyWrapper.getCorrectiveCues(exerciseName: exercise.name, profile: femaleProfile)
          : exercise.defaultCues;

      for (var setNum = 1; setNum <= setsCount; setNum++) {
        sets.add(WorkoutSet(
          id: 'set_${sessionId}_${setGlobalId++}',
          sessionId: sessionId,
          exerciseId: exercise.id,
          movementPattern: exercise.movementPattern,
          setNumber: setNum,
          reps: 10,
          targetRpe: targetRpeForSet,
          variables: vars,
          timestamp: currentTime,
          restDuration: restDuration,
          cues: cues,
        ));
      }
    }

    return WorkoutSession(
      id: sessionId,
      startTime: currentTime,
      isCompleted: false,
      sets: sets,
      dayType: dayType,
      posturalWarning: posturalWarning,
      posturalWarningReason: posturalWarningReason,
    );
  }

  /// Determines if a specific movement pattern is locked under the 48-hour recovery gate.
  Future<bool> isMovementLocked({
    required MovementPattern pattern,
    required DateTime currentTime,
  }) async {
    final pastSets = await sessionRepository.getSetsForMovementPattern(
      pattern,
      currentTime.subtract(const Duration(hours: 48)),
    );
    return SafetyRules.isMovementLocked(
      pastSets: pastSets,
      pattern: pattern,
      currentTime: currentTime,
    );
  }

  /// Validates the 2:1 pull-to-push set ratio across the 14-day sliding window.
  Future<bool> validatePosturalBalance({
    required DateTime currentTime,
  }) async {
    final pastSets = await sessionRepository.getSetsInDateRange(
      currentTime.subtract(const Duration(days: 14)),
      currentTime,
    );
    return SafetyRules.validatePushPullRatio(
      pastSets: pastSets,
      currentTime: currentTime,
    );
  }

  /// Creates and initializes a session state machine pipeline for active session tracking.
  SessionStreamManager createWorkoutSession({
    required WorkoutSession session,
  }) {
    final manager = SessionStreamManager();
    manager.initializeSession(session);
    return manager;
  }
}
