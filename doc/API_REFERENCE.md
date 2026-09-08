# SBEE API Reference

This document serves as the formal public API reference for the Science-Based Exercise Engine (SBEE). It documents all exposed classes, constructors, methods, properties, and exceptions in `package:sbee/sbee.dart`.

---

## 1. Orchestrator Facade (`SbeeEngine`)

The class [SbeeEngine](../lib/src/sbee_engine.dart) is the main entry point to the library.

### Constructor
```dart
SbeeEngine({
  required SessionRepository sessionRepository,
  required ProgressionRepository progressionRepository,
  required ExerciseGraph exerciseGraph,
});
```

### Public Methods

#### `logSetPerformance`
Evaluates the user's completed set performance, applies autoregulation changes to Kenneth Miller's variables, and handles progression or regression across the exercise graph if upper/lower limits are hit.
```dart
Future<MillerVariables> logSetPerformance({
  required String exerciseId,
  required int reps,
  required int reportedRpe,
  required int targetRpe,
  FemaleProfile? femaleProfile,
});
```
- **Returns**: The updated [MillerVariables](../lib/src/engine/miller_variables.dart) for the exercise.
- **Side Effects**: Persists the updated progression state and completed set logs in the repositories.

#### `generateNextWorkout`
Generates a new [WorkoutSession](../lib/src/domain/models/workout_session.dart) based on periodization scheduler rotations, applying safety locks, equipment limitations, deload restrictions, and physiology overrides.
```dart
Future<WorkoutSession> generateNextWorkout({
  required String userId,
  required DateTime currentTime,
  required Set<Equipment> availableEquipment,
  FemaleProfile? femaleProfile,
  bool hasJointPain = false,
});
```
- **`hasJointPain`**: general, profile-independent joint-pain/limited-mobility flag. Excludes plyometric exercises the same way `FemaleProfile`'s age-45+-specific claim does (`FemalePhysiologyWrapper.isPlyometricsAllowed`), but available to every account regardless of whether a `FemaleProfile` is supplied at all.

#### `isMovementLocked`
Queries if a specific movement pattern is locked under the 48-hour recovery gate.
```dart
Future<bool> isMovementLocked({
  required MovementPattern pattern,
  required DateTime currentTime,
});
```

#### `validatePosturalBalance`
Evaluates postural balance across the sliding 14-day window. Returns `true` if the 2:1 pull-to-push set-volume ratio is maintained or if no push sets were completed.
```dart
Future<bool> validatePosturalBalance({
  required DateTime currentTime,
});
```

#### `createWorkoutSession`
Creates and initializes an active session stream state manager using the given session. The returned manager persists progress incrementally as sets are logged (see `SessionStreamManager`), so a crash mid-workout can be recovered via `resumeActiveSession`.
```dart
SessionStreamManager createWorkoutSession({
  required WorkoutSession session,
});
```

#### `resumeActiveSession`
Checks for a workout session left incomplete (e.g. after a crash, force-quit, or killed background process) and, if one exists, returns a `SessionStreamManager` resumed at the correct point. Returns `null` if there is nothing to resume. Call once at host-app startup before offering a "start a new workout" action.
```dart
Future<SessionStreamManager?> resumeActiveSession();
```

---

## 2. Domain Models

### `DayType` (Enum)
Represents the five day-types for Daily Undulating Periodization (DUP):
- `DayType.veryHeavy`: Neuromuscular Recruitment focus (1–5 RM)
- `DayType.moderate`: Hypertrophy / Metabolic Stress focus (8–12 RM)
- `DayType.power`: Rate of Force Development focus (low reps, explosive)
- `DayType.veryLight`: Local Muscular Endurance focus (15–20+ RM)
- `DayType.highLactic`: Metabolic Buffering (Circuits, EMOM)

### `DayTypePrescription` (Class)
The locked reps/RPE prescription for a given [DayType](../lib/src/domain/models/day_type.dart), translating its documented RM zone into concrete generation values. See `doc/DECISIONS_LOG.md` §2 for the full table and rationale.
```dart
const DayTypePrescription({
  required int reps,
  required int minReps,
  required int maxReps,
  required int targetRpe,
  required int setsCount,
  required Duration restInterval,
});
```
- **Static Constructor**: `static DayTypePrescription forDayType(DayType dayType)`
- `highLactic`'s reps/minReps/maxReps/targetRpe are a neutral placeholder never actually surfaced to a generated set — `generateNextWorkout` overrides them using `IntensityTechniques.generateEmomRepCount` instead, since `highLactic` is an EMOM structure, not an RM-zone prescription. Its `setsCount` (read as "EMOM rounds per exercise") *is* used as-is.
- `setsCount` is the base set count for the DayType, applied before the existing deload-halving and female-wrapper minimum-floor adjustments in `generateNextWorkout`.
- `restInterval` is the default rest between sets for the DayType — 2m30s for the strength-focused DayTypes (`veryHeavy`, `moderate`), 45s for the conditioning-focused ones (`power`, `veryLight`, `highLactic`). This is the default for every account; a `FemaleProfile` only ever adds `FemalePhysiologyWrapper.adjustRestInterval`'s early-follicular offset on top of it.

### `Equipment` (Enum)
Supported home and bodyweight training equipment options:
- `Equipment.pullUpBar`
- `Equipment.bands`
- `Equipment.suspension`
- `Equipment.ball`
- `Equipment.benchOrChair`
- `Equipment.towel`
- `Equipment.bodyweight`

### `MovementPattern` (Enum)
The five primary functional movement patterns:
- `MovementPattern.bendAndLift`
- `MovementPattern.singleLeg`
- `MovementPattern.pushing`
- `MovementPattern.pulling`
- `MovementPattern.rotation`

### `FocusCategory` (Enum)
Generic training tracks representing the primary focus of a workout session or exercise:
- `FocusCategory.strength`
- `FocusCategory.balance`
- `FocusCategory.conditioning`
- `FocusCategory.stamina`

### `Exercise` (Class)
Represents a predefined exercise in the progression catalog.
```dart
const Exercise({
  required String id,
  required String name,
  required MovementPattern movementPattern,
  required int difficultyTier,
  required Set<Equipment> equipmentRequirements,
  List<String> defaultCues = const [],
  Map<String, String> correctiveCues = const {},
});
```

### `MillerVariables` (Class)
Represents Kenneth Miller's five biomechanical variable parameters.
```dart
const MillerVariables({
  int load = 1,
  int bodyPosition = 1,
  int rom = 1,
  int height = 1,
  int tempo = 1, // 1 = Standard 4-2-1 tempo, 2 = Advanced 6s slow-tempo
});
```
- **Invariants**: `load`, `bodyPosition`, `rom`, `height` must be in the range `[1, 5]`. `tempo` must be in the range `[1, 2]`.

### `RpeInfo` (Class)
Exposes physiological states and engine rules corresponding to Borg's RPE scale values.
```dart
const RpeInfo({
  required int rpe,
  required String rirEquivalent,
  required String physiologicalState,
  required String engineResponse,
});
```
- **Static Constructor**: `factory RpeInfo.fromRpe(int rpe)`
- **Properties**:
  - `bool get requiresGating`: Returns `true` if RPE is $\ge 9$.
  - `bool get triggersIncrement`: Returns `true` if RPE is $\le 5$.

### `WorkoutSet` (Class)
Represents an individual set prescribed within a session.
```dart
const WorkoutSet({
  required String id,
  required String sessionId,
  required String exerciseId,
  required MovementPattern movementPattern,
  required int setNumber,
  required int reps,
  int? minReps, // Prescribed rep-range floor. Null if not generated from a ranged prescription.
  int? maxReps, // Prescribed rep-range ceiling. Null if not generated from a ranged prescription.
  required int targetRpe,
  int? reportedRpe, // Null until completed and logged
  required MillerVariables variables,
  required DateTime timestamp,
  Duration? restDuration,
  List<String> cues = const [],
});
```
- **`reps`**: A single representative rep count — the DayType's prescribed default before a set is logged, and the actual performed rep count once logged (via `SessionStreamManager.logCurrentSet`).
- **`minReps`/`maxReps`**: The prescribed rep-range bounds from `DayTypePrescription`, when the set was generated from a ranged prescription (`highLactic` sets set both equal to a single EMOM-computed rep count rather than a true range).
- **`hasRepRange`** (getter): `true` if both `minReps` and `maxReps` are non-null.

### `WorkoutSession` (Class)
Represents a structured collection of workout sets scheduled for execution.
```dart
const WorkoutSession({
  required String id,
  required DateTime startTime,
  DateTime? endTime,
  List<WorkoutSet> sets = const [],
  bool isCompleted = false,
  DayType? dayType,
  String? posturalWarning,
  PosturalWarningReason posturalWarningReason = PosturalWarningReason.none,
  RecoveryReason recoveryReason = RecoveryReason.none,
});
```

### `PosturalWarningReason` (Enum)
Represents warning reasons corresponding to postural alignment issues flagged during workout generation:
- `PosturalWarningReason.none`: No postural warning active.
- `PosturalWarningReason.noPullingAvailable`: Bypassed the 2:1 safety ratio because no pulling exercises were available in the candidate pool.
- `PosturalWarningReason.historicalDeficit`: The 2:1 ratio is not satisfied due to a historical pull set deficit.

### `RecoveryReason` (Enum)
Represents reasons a generated session deviates from its DayType prescription for whole-body fatigue management, distinct from postural (push/pull) balance:
- `RecoveryReason.none`: No recovery fallback active.
- `RecoveryReason.allMovementPatternsLocked`: Every movement pattern was under the 48h post-RPE8 recovery lock at once (see `SafetyRules.isMovementLocked`), which would otherwise leave the session with zero exercises. The session falls back to the same equipment-eligible catalog at `SbeeEngine.recoveryFallbackTargetRpe` / `recoveryFallbackSetsCount` instead of the DayType's normal prescription.

### Beginner Exercise-Tier Cap
Until an account reaches whole-account `Intermediate` status (`ProgressionRepository.getStatusAchievedDate('Intermediate')` non-null), `generateNextWorkout` excludes any exercise with `difficultyTier > SbeeEngine.beginnerMaxDifficultyTier` (3) from the candidate pool, including during the recovery fallback above. Every shared-core exercise is tier 1-3 and every Path specialty exercise is tier 4-6, so in practice this means a fresh account trains the core catalog only, regardless of chosen Path or available equipment, until it has a real track record.

---

## 3. Female Physiology Wrapper

The [FemalePhysiologyWrapper](../lib/src/engine/female_wrapper.dart) class applies endocrine-centric adjustments.

### `FemaleProfile` (Class)
```dart
const FemaleProfile({
  required String userStatus, // E.g., "Untrained_Female", "Trained_Female"
  required int cycleDay,      // 1-indexed day of menstrual cycle (e.g., 1–28)
  required bool hasKneeDiscomfort,
  required int age,
  required bool hasJointPain,
});
```

### Static Methods

#### `getEndocrineExplanation`
```dart
static String getEndocrineExplanation();
```
- **Returns**: A string explanation highlighting Growth Hormone (GH) pulsatility.

#### `adjustTargetRpe`
```dart
static int adjustTargetRpe({
  required int originalTargetRpe,
  required FemaleProfile profile,
});
```
- **Returns**: Adjusted target RPE. Reduces it by `1` during cycle days 1–3 if `userStatus` is `"Untrained_Female"`.

#### `adjustRestInterval`
```dart
static Duration adjustRestInterval({
  required Duration baseRest,
  required FemaleProfile profile,
});
```
- **Returns**: `baseRest` plus a `30s` rest density buffer during cycle days 1-3 if `"Untrained_Female"`, otherwise `baseRest` unchanged. The conditioning-vs-strength baseline (`45s` / `150s`) this used to compute internally moved to `DayTypePrescription.restInterval` — pass that in as `baseRest`.

#### `getConditioningTargetVo2Max`
```dart
static Map<String, double> getConditioningTargetVo2Max();
```
- **Returns**: A map containing `'min': 0.55` and `'max': 0.65` representing steady-state conditioning target limits ($55\% - 65\%$ VO2 max).

#### `getCorrectiveCues`
```dart
static List<String> getCorrectiveCues({
  required String exerciseName,
  required FemaleProfile profile,
});
```
- **Returns**: A list of corrective alignment and pelvic floor stability cues.

#### `adjustIntensityMetric`
```dart
static String adjustIntensityMetric({
  required String originalMetric,
  required FemaleProfile profile,
});
```
- **Returns**: Returns `'2-3 RIR (Reps in Reserve) target'` if user age is $\ge 45$. Otherwise, returns the original metric string.

#### `adjustMinSets`
```dart
static int adjustMinSets({
  required int originalMinSets,
  required FemaleProfile profile,
});
```
- **Returns**: Enforces a minimum set volume floor of `3` sets per movement pattern if age is $\ge 45$.

#### `isPlyometricsAllowed`
```dart
static bool isPlyometricsAllowed({
  required FemaleProfile profile,
});
```
- **Returns**: Returns `false` if the user is $\ge 45$ and has joint pain, gating plyometrics. Otherwise, returns `true`. This is a narrower, age-specific claim on top of the general `generateNextWorkout(hasJointPain: ...)` flag above — a `FemaleProfile` user's plyometric exclusion is `hasJointPain || !isPlyometricsAllowed(profile)`, not this function alone.

---

## 4. Intensity Techniques (`IntensityTechniques`)

The [IntensityTechniques](../lib/src/engine/intensity_techniques.dart) class generates structural parameter sets for high-intensity prescription and checks progress gates.

### Parameter Structures
- **`ClusterSetsStructure`**: Represents cluster sets. Exposes:
  - `String label`, `int targetReps`, `int repsPerMiniSet`, `int intraSetRestSeconds`.
- **`RestPauseStructure`**: Represents rest-pause sets. Exposes:
  - `String label`, `int targetReps`, `int postFailureRestSeconds`.
- **`MyoRepsStructure`**: Represents Myo-Reps. Exposes:
  - `String label`, `int activationReps`, `int miniSetsCount`, `int repsPerMiniSet`, `String restInterval`.

### Static Methods

#### `generateClusterSet`
```dart
static ClusterSetsStructure generateClusterSet({
  required int targetReps,
  int repsPerMiniSet = 2,
});
```

#### `generateRestPause`
```dart
static RestPauseStructure generateRestPause({
  required int targetReps,
});
```

#### `generateMyoReps`
```dart
static MyoRepsStructure generateMyoReps({
  required int activationReps,
  int miniSetsCount = 4,
});
```
- **Throws**: `ArgumentError` if `miniSetsCount` is less than `3` or greater than `5`.

#### `validateEmomRepCount`
Validates that the selected rep count does not exceed level-specific work-duration thresholds.
```dart
static bool validateEmomRepCount({
  required int reps,
  required int secondsPerRep,
  required String userLevel,
});
```
- **User Level Limits**:
  - `beginner`: Max work duration $20\text{s}$
  - `intermediate`: Max work duration $30\text{s}$
  - `advanced`: Max work duration $40\text{s}$

#### `generateEmomRepCount`
Generates a compliant EMOM rep count for a given user level: the largest rep count whose total work duration does not exceed that level's max threshold (shares the same duration table as `validateEmomRepCount`, so the two cannot drift apart). Always returns at least `1`. Used by `generateNextWorkout` to prescribe `highLactic` day sets.
```dart
static int generateEmomRepCount({
  required String userLevel,
  int secondsPerRep = 3,
});
```
- **Throws**: `ArgumentError` if `userLevel` is not one of `beginner`/`intermediate`/`advanced`, or if `secondsPerRep` is not positive.

#### `canProgressTabata`
Determines if a user has met the hybrid progression gate criteria to move to the next Tabata training phase.
```dart
static bool canProgressTabata({
  required List<WorkoutSession> completedTabataSessionsInPhase,
  required int requiredSessionCount,
  required double targetRpe,
});
```
- **Progression Criteria**:
  1. The user must have completed a minimum of `requiredSessionCount` Tabata sessions in the current phase.
  2. The average reported RPE across all sets in those completed sessions must be $\le$ `targetRpe + 1.0`.

---

## 5. Active Session Streams & State Management

### `SessionState` (Enum)
Values: `warmUp`, `activeSet`, `rest`, `coolDown`, `completed`.

### `SessionProgressState` (Class)
The read-only state snapshot emitted by the session manager.
- `WorkoutSession? get session`: The active session.
- `SessionState get state`: The current state of execution.
- `int get currentSetIndex`: The zero-indexed current set.
- `bool get hasActiveSession`: `true` if a session has been initialized.

### `SessionStreamManager` (Class)
Orchestrates the active workout session, driving changes via an internal state machine and piping updates reactively.
```dart
SessionStreamManager({SessionRepository? sessionRepository});
```
- **`sessionRepository`** (optional): when supplied, the manager persists the session (fire-and-forget; write errors are swallowed rather than crashing the FSM) after `initializeSession` and every `logCurrentSet`, enabling crash recovery via `resumeSession`/`SbeeEngine.resumeActiveSession`.
- `Stream<SessionProgressState> get progressStream`: The reactive stream of session progress.
- `SessionProgressState get currentState`: Synchronous getter for the current state snapshot.
- `void initializeSession(WorkoutSession session)`: Sets up state and starts at `warmUp`.
- `void resumeSession(WorkoutSession incompleteSession)`: Reconstructs the manager from a previously-incomplete session (as returned by `SessionRepository.getActiveIncompleteSession()`), restoring the FSM and current-set index to the next unlogged set (or `coolDown` if every set was already logged). Does not modify or re-timestamp already-logged sets. Throws `StateError` if a session is already active.
- `void startWorkout()`: Transition from `warmUp` to `activeSet`.
- `void logCurrentSet({required int reps, required int reportedRpe})`: Records performance on the current set, transitioning to `rest` (or `coolDown` if it is the final set).
- `void startNextSet()`: Transition from `rest` to `activeSet` and increments the set index.
- `void finalizeSession()`: Finalizes the session, marking it as completed.
- `void dispose()`: Closes the underlying stream emitter.

---

## 6. Repository Interfaces

### `ProgressionRepository` (Abstract Class)
Tracks user exercise competence status, achievements, and individual exercise variables.
- `Future<ExerciseProgression?> getProgression(String exerciseId)`
- `Future<void> saveProgression(ExerciseProgression progression)`
- `Future<List<ExerciseProgression>> getAllProgressions()`
- `Future<DateTime?> getStatusAchievedDate(String status)`
- `Future<void> saveStatusAchievedDate(String status, DateTime date)`

### `SessionRepository` (Abstract Class)
Saves completed workouts and provides query methods for safety validation.
- `Future<void> saveSession(WorkoutSession session)`
- `Future<WorkoutSession?> getSession(String id)`
- `Future<List<WorkoutSession>> getSessionsInDateRange(DateTime start, DateTime end)`
- `Future<List<WorkoutSet>> getSetsForMovementPattern(MovementPattern pattern, DateTime since)`
- `Future<List<WorkoutSet>> getSetsInDateRange(DateTime start, DateTime end)`
- `Future<WorkoutSession?> getMostRecentCompletedSession({bool requireDayType = false})`: The single most recently-started completed session, or `null`. If `requireDayType` is `true`, only considers sessions that also have a non-null `dayType`.
- `Future<DateTime?> getEarliestCompletedSessionStart()`: The start time of the earliest completed session (the training program's start date), or `null`.
- `Future<int> getCompletedSessionCount()`: Total count of completed sessions.
- `Future<int> getReportedSetCountForExercise(String exerciseId)`: Count of logged sets (`reportedRpe != null`) for a specific exercise, across all sessions regardless of the parent session's completion status.
- `Future<WorkoutSession?> getActiveIncompleteSession()`: The single most recently-started incomplete (`isCompleted == false`) session, or `null`. Used to detect and resume a workout left in progress after a crash or restart.

> [!NOTE]
> The five methods above exist specifically so implementers (and SBEE's own internal calls) never need to fetch the entire session/set history just to find one recent value or a count — each should be backed by a real bounded/indexed query (e.g. `ORDER BY ... LIMIT 1`, `COUNT(*)`), not a full table scan filtered in application code.

### Persistence Exceptions
- **`ProgressionRepositoryException`**: Thrown on write errors, corrupt reads, or constraint violations in the progression repository.
- **`SessionRepositoryException`**: Thrown on write errors, corrupt reads, or constraint violations in the session repository.
