# SBEE Integration Guide

This guide describes how to integrate the Science-Based Exercise Engine (SBEE) into a host application. It covers library setup, bootstrapping the exercise progression graph, generating periodized workouts, wiring reactive streams to UI components, managing active workouts, and handling exceptions.

> [!NOTE]
> SBEE is designed to be integrated by **multiple, independently-themed host applications at once** — it is not built for or coupled to any single app. Nothing in this guide, and nothing in the library itself, should assume there is only one consumer. Each host application supplies its own exercise catalog, theming, and branding (see §9, Extension & Reskin Guide); SBEE only ever sees generic domain concepts (`DayType`, `MovementPattern`, `FocusCategory`, `Equipment`).

---

## 1. Setup & Persistence Registration

### Step A: Declare Dependency
Add the SBEE package as a local path dependency in the host application's `pubspec.yaml`:
```yaml
dependencies:
  sbee:
    path: path/to/sbee
```

### Step B: Initialize Database & Repositories
SBEE provides a reference implementation using the Drift package for SQLite persistence. Instantiate the database and wire it to the repositories in your host app's dependency injection container:

```dart
import 'package:drift/native.dart';
import 'package:sbee/sbee.dart';

void initializeSbeeDependencies() {
  // 1. Instantiate the SQLite database (NativeDatabase memory for tests, or file-backed database)
  final database = SbeeDatabase(NativeDatabase.memory());
  
  // 2. Initialize repositories passing the database connection
  final SessionRepository sessionRepository = DriftSessionRepository(database);
  final ProgressionRepository progressionRepository = DriftProgressionRepository(database);

  // Register these as singletons in your application's Service Locator (e.g., GetIt)
  // GetIt.I.registerSingleton<SessionRepository>(sessionRepository);
  // GetIt.I.registerSingleton<ProgressionRepository>(progressionRepository);
}
```

---

## 2. Bootstrapping the Exercise Graph

SBEE manages exercise progression pathways via a Directed Acyclic Graph (DAG) wrapped in [ExerciseGraph](../lib/src/domain/progression/exercise_graph.dart). 

In your application startup configuration, define the full set of catalog exercises and compile them into an `ExerciseGraph` to pass to the engine facade:

```dart
import 'package:sbee/sbee.dart';

ExerciseGraph bootstrapExerciseGraph() {
  // Define exercises
  final pushup = Exercise(
    id: 'pushup_1',
    name: 'Standard Push-up',
    movementPattern: MovementPattern.pushing,
    difficultyTier: 1,
    equipmentRequirements: {Equipment.bodyweight},
    defaultCues: ['Keep your spine neutral', 'Tuck your elbows to a 45-degree angle.'],
  );

  final feetElevatedPushup = Exercise(
    id: 'pushup_2',
    name: 'Feet-Elevated Push-up',
    movementPattern: MovementPattern.pushing,
    difficultyTier: 2,
    equipmentRequirements: {Equipment.benchOrChair},
    defaultCues: ['Maintain a rigid hollow body hold', 'Keep neck neutral.'],
  );

  final pullup = Exercise(
    id: 'pullup_1',
    name: 'Standard Pull-up',
    movementPattern: MovementPattern.pulling,
    difficultyTier: 1,
    equipmentRequirements: {Equipment.pullUpBar},
  );

  // Compile the DAG map mapping each predecessor to its set of direct successors
  final Map<Exercise, Set<Exercise>> graphMap = {
    pushup: {feetElevatedPushup},
    feetElevatedPushup: {},
    pullup: {},
  };

  // The ExerciseGraph constructor will validate that the graph is acyclic
  return ExerciseGraph(graphMap);
}
```

---

## 3. Composing SbeeEngine Facade

Create the [SbeeEngine](../lib/src/sbee_engine.dart) facade, supplying the instantiated repositories and the bootstrapped exercise graph:

```dart
import 'package:sbee/sbee.dart';

SbeeEngine setupEngine(
  SessionRepository sessionRepo,
  ProgressionRepository progressionRepo,
  ExerciseGraph graph,
) {
  return SbeeEngine(
    sessionRepository: sessionRepo,
    progressionRepository: progressionRepo,
    exerciseGraph: graph,
  );
}
```

---

## 4. Generating Workout Sessions

The host application calls `generateNextWorkout` to construct a periodized training session.

```dart
Future<WorkoutSession> planNextSession(SbeeEngine engine) async {
  // 1. Identify active user equipment
  final Set<Equipment> availableEquipment = {
    Equipment.bodyweight,
    Equipment.benchOrChair,
  };

  // 2. Fetch or build the user's physiology profile (e.g. for female physiology tracking)
  final femaleProfile = FemaleProfile(
    userStatus: 'Untrained_Female',
    cycleDay: 2, // Early Follicular
    hasKneeDiscomfort: true,
    age: 28,
    hasJointPain: false,
  );

  // 3. Generate the session
  final session = await engine.generateNextWorkout(
    userId: 'user_987',
    currentTime: DateTime.now(),
    availableEquipment: availableEquipment,
    femaleProfile: femaleProfile,
  );

  return session;
}
```

### Applied Constraints During Generation:
- **Periodization Rotation**: Day type is automatically scheduled (`moderate` ➔ `veryHeavy` ➔ `power` ➔ `veryLight` ➔ `highLactic`).
- **48-Hour Recovery Gate**: Excludes exercises belonging to movement patterns locked by high-intensity sets logged within the past 48 hours.
- **Detraining Lockout**: If inactivity is $\ge 14$ days, high-intensity day-types (`veryHeavy`, `power`) are redirected to `moderate`. Strict `4-2-1` tempo constraints and Stabilization cues are added.
- **Physiological Adjustments**: During early follicular days (1–3), target RPE is reduced by `1` and rest periods are padded by `30` seconds. If `hasKneeDiscomfort` is true, knee alignment cues are added, and lower body sets are given a rep count floor of `12-15` reps.
- **Postural Balance Generation Enforcement**: Restricts generated pushing sets to satisfy a 2:1 pull-to-push ratio over the sliding 14-day history window. Bypasses push-limiting and flags `noPullingAvailable` if no pulling exercises are in the pool, and flags `historicalDeficit` if the ratio is unsatisfied.

---

## 4.5. FemalePhysiologyWrapper Direct-Call Usage & Safety Warnings

### FemalePhysiologyWrapper Direct-Call Examples
In scenarios where the host application needs to query physiological cues, VO2 max targets, rest intervals, or plyometric safety restrictions outside the standard automated generation flow, invoke the static methods on `FemalePhysiologyWrapper` directly:

```dart
import 'package:sbee/sbee.dart';

void queryFemalePhysiologyDirectly() {
  final profile = FemaleProfile(
    userStatus: 'Untrained_Female',
    cycleDay: 2,
    hasKneeDiscomfort: true,
    age: 46,
    hasJointPain: true,
  );

  // 1. Query conditioning target VO2 max boundaries (55% - 65% range)
  final vo2MaxRange = FemalePhysiologyWrapper.getConditioningTargetVo2Max();
  final minVo2 = vo2MaxRange['min']; // 0.55
  final maxVo2 = vo2MaxRange['max']; // 0.65
  print('Target VO2 Max: $minVo2 to $maxVo2');

  // 2. Query corrective and safety alignment cues for a given exercise
  final cues = FemalePhysiologyWrapper.getCorrectiveCues(
    exerciseName: 'Standard Squat',
    profile: profile,
  );
  // Returns:
  // - 'Breathing: Exhale with effort during the concentric phase.'
  // - 'Stance: Ensure stable foot stance and align hips and knees.'
  // - 'Knee Safety: Trigger McGill Big 3 and Side Plank with Hip Abduction...'
  // - 'Knee Safety Rep Floor: Set a floor of 12-15 repetitions...'
  print('Cues: $cues');

  // 3. Calculate cycle-adjusted rest intervals for a specific training focus
  final rest = FemalePhysiologyWrapper.adjustRestInterval(
    originalRest: const Duration(seconds: 90),
    trainingFocus: 'conditioning',
    profile: profile,
  );
  // Returns 75 seconds (45s base rest for conditioning + 30s follicular offset)
  print('Adjusted Rest: ${rest.inSeconds} seconds');

  // 4. Check if plyometric exercises are allowed
  final isAllowed = FemalePhysiologyWrapper.isPlyometricsAllowed(profile: profile);
  // Returns false because age >= 45 and hasJointPain is true
  print('Plyometrics allowed: $isAllowed');
}
```

### Safety-Clarity Warnings & Integration Constraints
> [!IMPORTANT]
> **Implicit Execution Warning**:
> `isPlyometricsAllowed` is **already automatically applied** during `generateNextWorkout`'s internal exercise-filtering step. If a user is age $\ge 45$ and reports joint pain, exercises containing "jumping" or "plyo" in their names are excluded from the returned workout session. Host applications calling `isPlyometricsAllowed` directly for UI-level customization must not double-apply or contradict this filtering to avoid redundant or inconsistent user states.
>
> **Knee Valgus Safety Rail - No Physical Exercise Swap**:
> `generateNextWorkout` does **not** automatically perform physical exercise substitutions (such as physically swapping a "Squat" node for a "McGill Big 3" or "Side Plank" node) in the generated workout session. Instead, it embeds the appropriate biomechanical alignment and knee-valgus safety cues *within* the generated `WorkoutSet` entries. The host application is responsible for rendering these cues clearly to the user. Any literal swap/substitution of the active exercise in the UI must be managed client-side by the host application.

---

## 5. Active Session Tracking & Stream Wiring

During workout execution, use `SessionStreamManager` to coordinate progress. In a Flutter host app, wire the manager directly to reactive widgets.

```dart
import 'package:sbee/sbee.dart';

class WorkoutCoordinator {
  final SbeeEngine engine;
  late SessionStreamManager streamManager;

  WorkoutCoordinator(this.engine);

  void startWorkoutSession(WorkoutSession session) {
    // Instantiate and initialize the stream manager
    streamManager = engine.createWorkoutSession(session: session);
    
    // Begin the workout (transitions Warm-up -> Active Set)
    streamManager.startWorkout();
  }

  void handleSetLogging(int repsCompleted, int reportedRpe) {
    // Logs the completed set. The manager updates the internal list and transitions:
    // - If it is the last set: transitions to Cool-down state
    // - Otherwise: transitions to Rest state
    streamManager.logCurrentSet(
      reps: repsCompleted,
      reportedRpe: reportedRpe,
    );
  }

  void nextSet() {
    // Transitions state back from Rest -> Active Set, incrementing set number
    streamManager.startNextSet();
  }

  void endWorkout() {
    // Finalizes workout (transitions Cool-down -> Completed)
    streamManager.finalizeSession();
    
    // Dispose resources
    streamManager.dispose();
  }
}
```

### UI Navigation Mapping Flow:
A host app can map state changes emitted by the stream to specific screens:

| `SessionState` | Description | Typical UI View | Actions Available |
| :--- | :--- | :--- | :--- |
| `warmUp` | Workout has not started yet | Pre-workout activation drills / Mobility cues | `startWorkout()` |
| `activeSet` | User is performing a set | Exercise demonstration, active rep timer, cues | `logCurrentSet()` |
| `rest` | Recovery timer is running | Rest countdown timer (e.g. 45s, 150s) | `startNextSet()` (or auto-advance) |
| `coolDown` | Active sets complete, stretching | Cool-down instruction list | `finalizeSession()` |
| `completed` | Workout completed | Summary screen, stats saved | Close/Navigate back |

### Recovering an Interrupted Workout

`SbeeEngine.createWorkoutSession` returns a `SessionStreamManager` that persists progress after every logged set. If the app is killed mid-workout (backgrounded and reclaimed by the OS, a crash, a force-quit), that progress is not lost — call `resumeActiveSession()` once at app startup, before offering a "start a new workout" action:

```dart
Future<void> checkForInterruptedWorkout(SbeeEngine engine, WidgetRef ref) async {
  final resumed = await engine.resumeActiveSession();
  if (resumed != null) {
    // A session was left in progress. Wire it up exactly like a freshly-created
    // manager (see startWorkoutSession above) and navigate to whatever screen
    // matches resumed.currentState.state -- e.g. straight back to the active-set
    // screen if it resumed at `activeSet`.
    ref.read(sessionStreamManagerProvider.notifier).state = resumed;
  }
  // If null, there was nothing to resume -- proceed normally.
}
```

> [!NOTE]
> SBEE only provides the recovery *capability*. Whether and how to surface "resume your last workout?" to the user (a prompt, silent auto-resume, a banner) is entirely a host-app UI decision.

---

## 6. Autoregulation & DAG Traversal

After a session is successfully finalized, the host app should commit the performance updates back to the progression database. The SbeeEngine processes this by calling `logSetPerformance` for each completed set.

```dart
Future<void> syncWorkoutPerformance(
  SbeeEngine engine, 
  WorkoutSession completedSession,
  FemaleProfile? femaleProfile,
) async {
  for (final set in completedSession.sets) {
    if (set.reportedRpe != null) {
      // logSetPerformance computes the next MillerVariables.
      // If variable limits are reached, the engine automatically traverses the exercise Graph.
      final nextVars = await engine.logSetPerformance(
        exerciseId: set.exerciseId,
        reps: set.reps,
        reportedRpe: set.reportedRpe!,
        targetRpe: set.targetRpe,
        femaleProfile: femaleProfile,
      );
      
      print('Next variables for ${set.exerciseId}: Load=${nextVars.load}, ROM=${nextVars.rom}, Tempo=${nextVars.tempo}');
    }
  }
}
```

---

## 7. Focus Category & Postural Balance

### A. Focus Category Integration
When integrating SBEE into host-app specific training paths, map generic [FocusCategory](../lib/src/domain/models/focus_category.dart) enums onto your host application's tracks:

- `FocusCategory.strength` ➔ E.g., "Warrior Path", "Heavy Weight Track"
- `FocusCategory.conditioning` ➔ E.g., "Speed Path", "High-Intensity Circuit Track"
- `FocusCategory.balance` ➔ E.g., "Stabilization Track", "Functional Agility Track"
- `FocusCategory.stamina` ➔ E.g., "Endurance Track", "Fat Loss Track"

### B. Validation of Postural Invariant
To ensure safety, validate structural push-pull ratios periodically before prescribing additional pushing exercises:
```dart
Future<void> runSafetyChecks(SbeeEngine engine) async {
  final isBalanced = await engine.validatePosturalBalance(currentTime: DateTime.now());
  if (!isBalanced) {
    // Notify host application to append additional Pulling exercises 
    // to correct the 2:1 pull-to-push imbalance.
    print('WARNING: Postural balance out of limits. Set ratio must be 2:1 Pull to Push.');
  }
}
```

---

## 8. Exception Handling

Implement robust error boundaries around SBEE invocations to catch library-specific exceptions:

```dart
try {
  final session = await engine.generateNextWorkout(
    userId: 'user_1',
    currentTime: DateTime.now(),
    availableEquipment: {Equipment.bodyweight},
  );
} on SessionRepositoryException catch (e) {
  // Handles Drift database read failures or constraint violations in session tables
  log('Session Repository Error: ${e.message}', error: e.cause);
} on ProgressionRepositoryException catch (e) {
  // Handles Drift database errors relating to progression variables
  log('Progression Repository Error: ${e.message}', error: e.cause);
} on StateError catch (e) {
  // Handles FSM flow violations (e.g. calling logCurrentSet when in Rest state)
  log('Invalid FSM transition: ${e.message}');
} on ArgumentError catch (e) {
  // Handles invalid parameters, such as invalid exerciseId in the graph
  log('Invalid arguments: ${e.message}');
}
```

---

## 9. Extension & Reskin Guide

This section is not a hypothetical — supporting multiple, differently-themed host applications on the same engine is the actual design goal of SBEE, not an incidental possibility. Any application extending, wrapping, or reskinning the SBEE library should follow these implementation steps to adapt the engine to their ecosystem:

### A. Implementing Custom Database Repositories
If the host application chooses not to use the reference Drift database implementation, it must implement the `ProgressionRepository` and `SessionRepository` interfaces to connect to their own database structure (such as Firebase, Hive, or custom REST APIs):

```dart
import 'package:sbee/sbee.dart';

class CustomProgressionRepository implements ProgressionRepository {
  @override
  Future<ExerciseProgression?> getProgression(String exerciseId) async {
    // Implement custom fetch from local storage or cloud
    return null; 
  }

  @override
  Future<void> saveProgression(ExerciseProgression progression) async {
    // Implement custom save
  }

  @override
  Future<List<ExerciseProgression>> getAllProgressions() async {
    return [];
  }

  @override
  Future<DateTime?> getStatusAchievedDate(String status) async {
    return null;
  }

  @override
  Future<void> saveStatusAchievedDate(String status, DateTime date) async {
    // Implement custom save
  }
}
```

### B. Constructing a Custom Exercise Progression Graph
Compile your proprietary exercise database into a custom Directed Acyclic Graph (DAG) layout mapping the progression tiers:

```dart
ExerciseGraph buildProprietaryGraph() {
  final bodyweightSquat = Exercise(
    id: 'squat_1',
    name: 'Bodyweight Squat',
    movementPattern: MovementPattern.bendAndLift,
    difficultyTier: 1,
    equipmentRequirements: {Equipment.bodyweight},
  );

  final gobletSquat = Exercise(
    id: 'squat_2',
    name: 'Goblet Squat',
    movementPattern: MovementPattern.bendAndLift,
    difficultyTier: 2,
    equipmentRequirements: {Equipment.bands}, // Adapt to available equipment
  );

  return ExerciseGraph({
    bodyweightSquat: {gobletSquat},
    gobletSquat: {},
  });
}
```

### C. Mapping Focus Categories to Host Thematic Paths
Map the library's domain-agnostic `FocusCategory` enum onto your host app's proprietary thematic paths:

```dart
String getThematicPathName(FocusCategory category) {
  switch (category) {
    case FocusCategory.strength:
      return 'Warrior Path'; // E.g., The strength-training track
    case FocusCategory.conditioning:
      return 'Speed Path'; // E.g., The high-intensity/cardio track
    case FocusCategory.balance:
      return 'Control Path'; // E.g., The stabilization track
    case FocusCategory.stamina:
      return 'Stamina Path'; // E.g., The endurance track
  }
}
```

---

## 10. Never Do This (Critical Anti-Patterns)

To prevent bugs, architectural drift, and security issues, adhere strictly to the following restrictions:

> [!CAUTION]
> ### 1. Never Import directly from `src/`
> Internal code residing inside `lib/src/` is private and subject to breaking modifications. Always import exclusively from the public facade exports library:
> ```dart
> // CORRECT:
> import 'package:sbee/sbee.dart';
> 
> // INCORRECT (DO NOT DO):
> import 'package:sbee/src/engine/autoregulation.dart';
> ```
>
> ### 2. Never Reimplement or Double-Calculate Safety Rules in the Client
> Do not recreate safety validations (such as verifying postural ratios, checking 48-hour movement locks, or evaluating detraining inactive gaps) in client-side code. This creates divergent logic paths. Always delegate to the `SbeeEngine` facade methods:
> - Use `engine.validatePosturalBalance()` to check push-pull balance.
> - Use `engine.isMovementLocked()` to query pattern recovery states.
>
> ### 3. Never Hand-Assemble Workout Sessions
> Avoid bypassing `SbeeEngine.generateNextWorkout` by hand-assembling custom `WorkoutSession` or `WorkoutSet` collections for standard scheduling. Hand-assembly skips periodization, deload week volumes, detraining locks, and the female physiology wrapper decoration layers, leading to unvalidated and potentially unsafe workouts.
```
