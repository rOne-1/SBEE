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
import 'engine/day_type_prescription.dart';
import 'engine/intensity_techniques.dart';

/// The central SBEE orchestrator facade coordinating periodization, deload,
/// safety rules, female physiology wrappers, and DAG progression traversals.
class SbeeEngine {
  final SessionRepository sessionRepository;
  final ProgressionRepository progressionRepository;
  final ExerciseGraph exerciseGraph;

  /// APP-SPECIFIC DESIGN DECISION: Competency Progression Thresholds
  /// Per-exercise `competencyLevel` (1=Beginner, 2=Intermediate, 3=Advanced) was
  /// previously a dead field: stored and copied forward on every save, but never
  /// computed or read for behavior. These thresholds give it a real, effort-based
  /// (not calendar-based) progression rule, and feed [IntensityTechniques]'s EMOM
  /// generation with a real userLevel.
  static const int competencyIntermediateSetThreshold = 8;
  static const int competencyAdvancedSetThreshold = 20;

  /// APP-SPECIFIC DESIGN DECISION: Whole-Account "Intermediate" Status Detection
  /// `saveStatusAchievedDate('Intermediate')` was previously never called by
  /// anything, meaning the documented 21-day advanced-tempo unlock gate in
  /// `logSetPerformance` could never actually trigger. "Intermediate" is now
  /// auto-detected here, requiring both a real completed-session count and a
  /// minimum elapsed-days spread (reusing the codebase's existing 14-day window
  /// convention) so a burst of sessions in a single day can't fast-track it —
  /// consistent with the "calendar-day progression is strictly forbidden"
  /// philosophy already documented on `IntensityTechniques.canProgressTabata`.
  static const int intermediateStatusSessionThreshold = 12;
  static const int intermediateStatusMinDays = 14;

  /// Default work-to-rep pacing assumed for EMOM generation on `highLactic` days.
  static const int emomSecondsPerRep = 3;

  /// SAFETY-FEATURE SCIENCE NOTE: All-Patterns-Locked Recovery Fallback
  /// `SafetyRules.isMovementLocked` locks a single movement pattern for 48h
  /// once it's been trained at RPE>=8 -- near-maximal effort, the zone
  /// associated with the greatest muscle damage and the longest
  /// neuromuscular recovery window in the RPE/RIR autoregulation literature
  /// (e.g. Zourdos et al.'s RPE-based load prescription, Helms et al.'s
  /// autoregulation guidance). That's a reasonable per-pattern rule, but
  /// nothing previously handled the case where a user trains hard across
  /// their *entire* routine in a short span and every pattern ends up
  /// locked at once: `generateNextWorkout` would return a session with zero
  /// exercises. An empty session is worse than a light one for two
  /// independent reasons: (1) adherence/habit-formation research
  /// consistently finds a broken routine -- nothing to do today -- is a
  /// bigger dropout risk than an easy session (the "never miss twice"
  /// principle: skipping a scheduled session, even a token one, is where
  /// habits actually collapse); (2) light movement on a recently-fatigued
  /// pattern ("active recovery") is associated with better perceived
  /// recovery and reduced soreness versus complete rest, provided intensity
  /// stays low enough to not add meaningful additional fatigue.
  ///
  /// This fallback is deliberately lighter than even a scheduled deload
  /// (`PeriodizationScheduler.applyDeload` caps at RPE 6 / 50% of the
  /// DayType's prescribed volume, which assumes the athlete is only
  /// moderately fresh going into a planned reduction). Here, every pattern
  /// was JUST pushed to near-failure within the last 48h, so intensity sits
  /// at the bottom of the RPE scale -- "I could do this many more times,"
  /// not a training stimulus -- and volume is cut to a flat floor rather
  /// than a percentage of an already-reduced prescription. If this ever
  /// needs to be gentler or firmer, tune these two constants together
  /// rather than reusing the deload constants, since the two scenarios
  /// (planned periodization vs. reactive whole-body fatigue) call for
  /// different floors.
  static const int recoveryFallbackTargetRpe = 4;
  static const int recoveryFallbackSetsCount = 2;

  /// SAFETY-FEATURE SCIENCE NOTE: Whole-Account Beginner Exercise-Tier Cap
  /// Exercise selection previously filtered candidates only by equipment and
  /// the 48h recovery lock -- `difficultyTier` (1-6, set on every `Exercise`)
  /// was tracked but never used to decide which exercises a session could
  /// draw from. A brand-new account choosing a Path and reasonable equipment
  /// (bands, a bench) could be handed tier-6 movements like a pistol squat
  /// or a suspension-trainer fallout in its very first session, alongside
  /// tier-1 bodyweight squats, with nothing in the selection logic aware
  /// this is someone's first time under load. For a true beginner -- no
  /// trained movement patterns, no baseline strength, no practiced landing
  /// mechanics -- unsupervised exposure to high-skill or high-eccentric-
  /// demand movements (pistols, box jumps, plyometric pushups) is a real
  /// injury vector, not just a difficulty mismatch.
  ///
  /// Every exercise in this catalog already splits cleanly on this exact
  /// line: all 15 shared-core exercises are tier 1-3, and all 80 Path
  /// specialty exercises are tier 4-6. So rather than inventing a new
  /// progression signal, this reuses the existing whole-account
  /// "Intermediate" status detection above (`intermediateStatusSessionThreshold`
  /// / `intermediateStatusMinDays`): until that status is achieved, session
  /// generation is capped to `beginnerMaxDifficultyTier` regardless of
  /// equipment or chosen Path -- so a fresh account trains the core catalog
  /// first and a Path's specialty flavor unlocks once there's a real,
  /// time-gated track record behind it, not just an equipment checklist.
  /// This is a hard cap, not a soft/occasional exposure, since the whole
  /// point is to guarantee a beginner never sees tier 4+ until the account
  /// has evidence of sustained training, not just a single lucky equipment
  /// selection.
  static const int beginnerMaxDifficultyTier = 3;

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
    prog ??= ExerciseProgression(
      exerciseId: exerciseId,
      variables: const MillerVariables(
          load: 1, bodyPosition: 1, rom: 1, height: 1, tempo: 1),
      competencyLevel: 1,
      lastPerformed: DateTime.now(),
    );

    // 2. Pre-process targetRpe using FemalePhysiologyWrapper.adjustTargetRpe if femaleProfile is active.
    final adjustedTarget = femaleProfile != null
        ? FemalePhysiologyWrapper.adjustTargetRpe(
            originalTargetRpe: targetRpe, profile: femaleProfile)
        : targetRpe;

    // 2.5. Derive this exercise's competency level from its completed-set history.
    // Monotonic: a competency level, once reached, is never lowered by this check.
    final completedSetCount =
        await sessionRepository.getReportedSetCountForExercise(exerciseId);
    var derivedCompetencyLevel = 1;
    if (completedSetCount >= competencyAdvancedSetThreshold) {
      derivedCompetencyLevel = 3;
    } else if (completedSetCount >= competencyIntermediateSetThreshold) {
      derivedCompetencyLevel = 2;
    }
    final newCompetencyLevel = derivedCompetencyLevel > prog.competencyLevel
        ? derivedCompetencyLevel
        : prog.competencyLevel;

    // 3. Query Intermediate status date via progressionRepository. If achieved > 21 days ago, set isAdvancedTempoUnlocked = true.
    final intermediateDate =
        await progressionRepository.getStatusAchievedDate('Intermediate');
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

    final action = AutoregulationEngine.evaluate(
        reportedRpe: reportedRpe, targetRpe: adjustedTarget);

    if (isMaxLimit && action == AutoregulationAction.increment) {
      // Trigger progression to successors
      final successors = exerciseGraph.getProgressions(currentExercise);
      if (successors.isNotEmpty) {
        final nextExercise = successors.first;
        const baseVars = MillerVariables(
            load: 1, bodyPosition: 1, rom: 1, height: 1, tempo: 1);

        final newProg = ExerciseProgression(
          exerciseId: nextExercise.id,
          variables: baseVars,
          competencyLevel: newCompetencyLevel,
          lastPerformed: DateTime.now(),
        );
        await progressionRepository.saveProgression(newProg);
        await progressionRepository.saveProgression(prog.copyWith(
          variables: nextVars,
          competencyLevel: newCompetencyLevel,
          lastPerformed: DateTime.now(),
        ));
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
        const maxVars = MillerVariables(
            load: 5, bodyPosition: 5, rom: 5, height: 5, tempo: 2);

        final newProg = ExerciseProgression(
          exerciseId: prevExercise.id,
          variables: maxVars,
          competencyLevel: newCompetencyLevel,
          lastPerformed: DateTime.now(),
        );
        await progressionRepository.saveProgression(newProg);
        await progressionRepository.saveProgression(prog.copyWith(
          variables: nextVars,
          competencyLevel: newCompetencyLevel,
          lastPerformed: DateTime.now(),
        ));
        return maxVars;
      }
    }

    // Save updated progression and variables, then return.
    final updatedProg = prog.copyWith(
      variables: nextVars,
      competencyLevel: newCompetencyLevel,
      lastPerformed: DateTime.now(),
    );
    await progressionRepository.saveProgression(updatedProg);
    return nextVars;
  }

  /// Generates the next scheduled workout session, applying periodization,
  /// deload, detraining lockout redirection, and female physiology wrapper cues/rest adjustments.
  ///
  /// [hasJointPain]: general, profile-independent joint-pain/limited-mobility
  /// flag -- excludes plyometric exercises the same way `femaleProfile`'s
  /// age-45+-specific claim does, but available to every account regardless
  /// of whether they have a `FemaleProfile` at all. Previously, excluding
  /// plyometrics required BOTH a `FemaleProfile` AND `age >= 45` AND
  /// `hasJointPain` (`FemalePhysiologyWrapper.isPlyometricsAllowed`) -- so a
  /// user with real joint pain or limited mobility who wasn't 45+, or who
  /// simply wasn't using the female-specific flow at all, had no way in the
  /// entire app to ask for high-skill/high-impact movements to be excluded.
  /// This parameter is that general accommodation; the narrower age+profile
  /// claim still applies on top of it for the population it was written for.
  Future<WorkoutSession> generateNextWorkout({
    required String userId,
    required DateTime currentTime,
    required Set<Equipment> availableEquipment,
    FemaleProfile? femaleProfile,
    bool hasJointPain = false,
  }) async {
    // 1. Fetch the program start date once; shared by the Intermediate-status check below
    // and the deload calculation in step 3 (both only ever need the earliest session's date).
    final programStart =
        await sessionRepository.getEarliestCompletedSessionStart();

    // 1.5. Auto-detect whole-account "Intermediate" status (idempotent: written once).
    // Feeds the 21-day advanced-tempo unlock gate checked in logSetPerformance.
    // Uses targeted count/earliest-date queries rather than fetching full history.
    final completedSessionCount =
        await sessionRepository.getCompletedSessionCount();
    if (completedSessionCount >= intermediateStatusSessionThreshold &&
        programStart != null) {
      final existingIntermediateDate =
          await progressionRepository.getStatusAchievedDate('Intermediate');
      if (existingIntermediateDate == null) {
        final daysSinceFirstSession =
            currentTime.difference(programStart).inDays;
        if (daysSinceFirstSession >= intermediateStatusMinDays) {
          await progressionRepository.saveStatusAchievedDate(
              'Intermediate', currentTime);
        }
      }
    }

    // 2. Determine DayType. Apply detraining lock if inactivity >= 14 days (moderate redirect).
    // PeriodizationScheduler/DetrainingLogic take a List<WorkoutSession> to stay decoupled from
    // any specific repository; passing a single targeted, indexed-query result (rather than the
    // full session history) into a 1-element list is behaviorally exact here: getNextDayType only
    // ever looks for the single most recent completed session with a dayType, and
    // isDetrainingActive only ever looks for the single most recent completed session overall.
    final mostRecentWithDayType = await sessionRepository
        .getMostRecentCompletedSession(requireDayType: true);
    var dayType = PeriodizationScheduler.getNextDayType(
        mostRecentWithDayType != null ? [mostRecentWithDayType] : const []);

    final mostRecentCompleted =
        await sessionRepository.getMostRecentCompletedSession();
    final isDetrained = DetrainingLogic.isDetrainingActive(
      completedSessions:
          mostRecentCompleted != null ? [mostRecentCompleted] : const [],
      currentTime: currentTime,
    );
    if (isDetrained &&
        (dayType == DayType.veryHeavy || dayType == DayType.power)) {
      dayType = DayType.moderate; // Redirect
    }

    // 3. Resolve if Deload week is active. isDeloadActive only ever reads the earliest session's
    // startTime (the program's start date, already fetched in step 1), so a minimal carrier
    // WorkoutSession (only startTime is read) avoids fetching full session history.
    final isDeload = programStart != null &&
        PeriodizationScheduler.isDeloadActive(
          completedSessions: [
            WorkoutSession(
                id: '_program_start_marker',
                startTime: programStart,
                isCompleted: true)
          ],
          currentTime: currentTime,
        );

    // 3.5. Resolve the DayType's locked reps/RPE/setsCount prescription once.
    final prescription = DayTypePrescription.forDayType(dayType);

    // 3.6. Whole-account beginner tier cap (see beginnerMaxDifficultyTier doc
    // comment for the science). Re-reads the status set in step 1.5 above --
    // cheap (same in-memory-scale lookup) and correctly lets an account that
    // crosses the threshold on this very call unlock specialty exercises the
    // same session rather than waiting for the next one.
    final hasIntermediateStatus =
        await progressionRepository.getStatusAchievedDate('Intermediate') !=
            null;

    // 4. Select exercises corresponding to the scheduled training focus:
    //    - Filter out exercises whose movement patterns are locked under the 48h recovery gate.
    //    - Filter out exercises requiring equipment not present in availableEquipment.
    //    - Exclude plyometrics if the general hasJointPain flag is set, OR if a female profile's
    //      age+joint-pain-specific claim (isPlyometricsAllowed) gates it.
    //    - Cap difficultyTier for accounts that haven't reached Intermediate status yet.
    final excludePlyometrics = hasJointPain ||
        (femaleProfile != null &&
            !FemalePhysiologyWrapper.isPlyometricsAllowed(
                profile: femaleProfile));

    final filteredExercises = <Exercise>[];
    for (final exercise in exerciseGraph.exercises) {
      // Equipment check
      final hasEquipment = exercise.equipmentRequirements
          .every((req) => availableEquipment.contains(req));
      if (!hasEquipment) continue;

      // Beginner tier cap
      if (!hasIntermediateStatus &&
          exercise.difficultyTier > beginnerMaxDifficultyTier) {
        continue;
      }

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

    // 4.5. All-patterns-locked recovery fallback (see recoveryFallbackTargetRpe
    // doc comment for the science): if the 48h lock left literally nothing to
    // program, recompute eligibility ignoring ONLY that lock -- equipment, the
    // beginner tier cap, and the plyometric safety exclusion still apply -- so
    // today becomes a very light session instead of an empty one.
    var recoveryReason = RecoveryReason.none;
    if (filteredExercises.isEmpty) {
      for (final exercise in exerciseGraph.exercises) {
        final hasEquipment = exercise.equipmentRequirements
            .every((req) => availableEquipment.contains(req));
        if (!hasEquipment) continue;

        if (!hasIntermediateStatus &&
            exercise.difficultyTier > beginnerMaxDifficultyTier) {
          continue;
        }

        if (excludePlyometrics) {
          final nameLower = exercise.name.toLowerCase();
          if (nameLower.contains('jumping') || nameLower.contains('plyo')) {
            continue;
          }
        }

        filteredExercises.add(exercise);
      }
      if (filteredExercises.isNotEmpty) {
        recoveryReason = RecoveryReason.allMovementPatternsLocked;
      }
    }

    // 5. Calculate H_pull and H_push from the 14-day history. Queried directly with a bounded
    // 14-day range rather than filtering an already-fetched full history (there is no full
    // history fetch left in this method at all as of the query-scaling fix).
    final completedSessions14d =
        (await sessionRepository.getSessionsInDateRange(
      currentTime.subtract(const Duration(days: 14)),
      currentTime,
    ))
            .where((s) => s.isCompleted)
            .toList();
    final historySets = completedSessions14d.expand((s) => s.sets).toList();

    final hPull = historySets
        .where((s) => s.movementPattern == MovementPattern.pulling)
        .length;
    final hPush = historySets
        .where((s) => s.movementPattern == MovementPattern.pushing)
        .length;

    // Helper to calculate sets count for an exercise. Base count comes from the
    // DayType's prescription (see DayTypePrescription.setsCount); deload and the
    // female-wrapper minimum floor are then applied on top, unchanged from before.
    int calculateExerciseSetsCount(Exercise exercise) {
      var count = prescription.setsCount;
      if (isDeload) {
        count = (count / 2).ceil();
      }
      if (femaleProfile != null) {
        count = FemalePhysiologyWrapper.adjustMinSets(
            originalMinSets: count, profile: femaleProfile);
      }
      return count;
    }

    String? posturalWarning;
    PosturalWarningReason posturalWarningReason = PosturalWarningReason.none;
    final List<Exercise> finalExercises;

    if (recoveryReason != RecoveryReason.none) {
      // Recovery-fallback sessions include everything eligible outright.
      // Postural (push/pull) balancing is a training-stress management
      // concern that doesn't apply at this volume/intensity floor -- there's
      // no meaningful "too much pushing" at 2 sets and RPE 4.
      finalExercises = filteredExercises;
    } else {
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
      var nPull = 0;
      for (final ex in pullingExercises) {
        nPull += calculateExerciseSetsCount(ex);
      }

      // Shuffle the pushing exercises list deterministically to promote variety.
      final shuffledPushing = List<Exercise>.from(pushingExercises);
      shuffledPushing.shuffle(Random(currentTime.millisecondsSinceEpoch));

      final selectedPushing = <Exercise>[];
      var nPush = 0;

      final fallbackNoPulling =
          pullingExercises.isEmpty && pushingExercises.isNotEmpty;

      if (fallbackNoPulling) {
        // Generate pushing exercises anyway
        selectedPushing.addAll(shuffledPushing);
        for (final ex in shuffledPushing) {
          nPush += calculateExerciseSetsCount(ex);
        }
        posturalWarning =
            'Postural warning: Pushing exercises generated without sufficient pulling options (2:1 ratio not satisfied).';
        posturalWarningReason = PosturalWarningReason.noPullingAvailable;
      } else {
        // Select pushing exercises sequentially checking the 2:1 postural balance ratio
        for (final ex in shuffledPushing) {
          final setsCount = calculateExerciseSetsCount(ex);
          if (hPull + nPull >= 2 * (hPush + nPush + setsCount)) {
            selectedPushing.add(ex);
            nPush += setsCount;
          }
        }
      }

      // Construct final list of exercises maintaining original order where applicable.
      // SCALING CONSIDERATION: Unconditional inclusion of all pulling exercises is a known scaling consideration for future large-scale catalogs.
      // SCALING CONSIDERATION: Unconditional inclusion of all other-pattern exercises is also a scaling consideration if an exercise-per-session cap is introduced in the future.
      final built = <Exercise>[];
      for (final ex in filteredExercises) {
        if (ex.movementPattern == MovementPattern.pulling) {
          built.add(ex);
        } else if (ex.movementPattern == MovementPattern.pushing) {
          if (selectedPushing.contains(ex)) {
            built.add(ex);
          }
        } else {
          built.add(ex);
        }
      }
      finalExercises = built;

      // Verify 2:1 ratio (combined history + session)
      if (posturalWarningReason == PosturalWarningReason.none) {
        if ((hPull + nPull) < 2 * (hPush + nPush)) {
          posturalWarning =
              'Postural warning: 2:1 pull-to-push ratio not satisfied due to historical deficit.';
          posturalWarningReason = PosturalWarningReason.historicalDeficit;
        }
      }
    }

    // 6. Construct WorkoutSession.
    final sessionId = 'session_${currentTime.millisecondsSinceEpoch}';
    final sets = <WorkoutSet>[];
    var setGlobalId = 1;

    for (final exercise in finalExercises) {
      final prog = await progressionRepository.getProgression(exercise.id);
      final vars = prog?.variables ??
          const MillerVariables(
              load: 1, bodyPosition: 1, rom: 1, height: 1, tempo: 1);

      final setsCount = recoveryReason != RecoveryReason.none
          ? recoveryFallbackSetsCount
          : calculateExerciseSetsCount(exercise);

      // Derive reps/RPE from the DayType's locked RM-zone prescription (resolved
      // once, above). highLactic is the exception: it prescribes an
      // EMOM-structured rep count (see IntensityTechniques.generateEmomRepCount)
      // keyed off the exercise's own competency level, rather than an RM-zone range.
      int setReps;
      int? setMinReps;
      int? setMaxReps;
      int targetRpeForSet;
      var dayTypeCues = const <String>[];

      if (dayType == DayType.highLactic) {
        final competencyLevel = prog?.competencyLevel ?? 1;
        final userLevel = competencyLevel >= 3
            ? 'advanced'
            : (competencyLevel == 2 ? 'intermediate' : 'beginner');
        final emomReps = IntensityTechniques.generateEmomRepCount(
          userLevel: userLevel,
          secondsPerRep: emomSecondsPerRep,
        );
        setReps = emomReps;
        setMinReps = emomReps;
        setMaxReps = emomReps;
        targetRpeForSet = prescription.targetRpe;
        dayTypeCues = [
          'EMOM Structure: Complete $emomReps reps at the top of each minute.'
        ];
      } else {
        setReps = prescription.reps;
        setMinReps = prescription.minReps;
        setMaxReps = prescription.maxReps;
        targetRpeForSet = prescription.targetRpe;
      }

      // If deload is active, cap targetRpe at 6 regardless of DayType prescription.
      if (isDeload) {
        targetRpeForSet = 6;
      }
      if (femaleProfile != null) {
        targetRpeForSet = FemalePhysiologyWrapper.adjustTargetRpe(
            originalTargetRpe: targetRpeForSet, profile: femaleProfile);
      }
      // Recovery fallback is the most conservative signal in play, so it
      // overrides deload/female adjustments rather than composing with them --
      // see recoveryFallbackTargetRpe's doc comment for why this floor is
      // lower than deload's.
      if (recoveryReason != RecoveryReason.none) {
        targetRpeForSet = recoveryFallbackTargetRpe;
        dayTypeCues = [
          ...dayTypeCues,
          'Active recovery: everything trained hard recently, so keep this light -- not a normal training stimulus.',
        ];
      }

      // DayType-driven rest interval (conditioning 45s / strength 150s, see
      // DayTypePrescription.restInterval) is the default for every account;
      // a female profile only ever adds its own early-follicular offset on
      // top of it now.
      final restDuration = femaleProfile != null
          ? FemalePhysiologyWrapper.adjustRestInterval(
              baseRest: prescription.restInterval,
              profile: femaleProfile,
            )
          : prescription.restInterval;

      // Append pelvic/spine safety cues and joint check flags to set instructions.
      final baseCues = femaleProfile != null
          ? FemalePhysiologyWrapper.getCorrectiveCues(
              exerciseName: exercise.name, profile: femaleProfile)
          : exercise.defaultCues;
      final cues = [...baseCues, ...dayTypeCues];

      for (var setNum = 1; setNum <= setsCount; setNum++) {
        sets.add(WorkoutSet(
          id: 'set_${sessionId}_${setGlobalId++}',
          sessionId: sessionId,
          exerciseId: exercise.id,
          movementPattern: exercise.movementPattern,
          setNumber: setNum,
          reps: setReps,
          minReps: setMinReps,
          maxReps: setMaxReps,
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
      recoveryReason: recoveryReason,
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
  /// The returned manager persists progress incrementally after every set is logged
  /// (see [SessionStreamManager]'s own docs), so a crash mid-workout can be recovered
  /// from via [resumeActiveSession] rather than losing all progress on the session.
  SessionStreamManager createWorkoutSession({
    required WorkoutSession session,
  }) {
    final manager = SessionStreamManager(sessionRepository: sessionRepository);
    manager.initializeSession(session);
    return manager;
  }

  /// Checks for a workout session left incomplete (e.g. after a crash, force-quit, or
  /// killed background process) and, if one exists, reconstructs a [SessionStreamManager]
  /// resumed at the correct point (the next unlogged set, or [SessionState.coolDown] if
  /// every set was already logged before the interruption). Returns `null` if there is
  /// no incomplete session to resume.
  ///
  /// Call this once at host-app startup, before offering the user a "start a new workout"
  /// action, so an interrupted session isn't silently discarded.
  Future<SessionStreamManager?> resumeActiveSession() async {
    final incomplete = await sessionRepository.getActiveIncompleteSession();
    if (incomplete == null) return null;
    final manager = SessionStreamManager(sessionRepository: sessionRepository);
    manager.resumeSession(incomplete);
    return manager;
  }

  /// Permanently discards the current incomplete session left over from a
  /// crash, force-quit, or a user who simply never came back to finish it --
  /// the counterpart to [resumeActiveSession] for a user who doesn't want to
  /// resume it. Without this, [resumeActiveSession] would keep surfacing the
  /// same abandoned session as resumable indefinitely, since nothing else
  /// ever removes a session once written. A no-op if there is nothing to
  /// discard.
  Future<void> discardActiveSession() async {
    final incomplete = await sessionRepository.getActiveIncompleteSession();
    if (incomplete == null) return;
    await sessionRepository.deleteSession(incomplete.id);
  }
}
