# Science-Based Exercise Engine (SBEE)

SBEE is a pure-Dart exercise progression and scheduling engine designed for resistance training. It features undulating periodization, deload schedules, autoregulated bio-mechanic adjustments (Kenneth Miller's 5-variable progression), safety lockouts, female physiology wrappers, and return-to-training (detraining) safety gates.

---

## Documentation Index

Explore the comprehensive technical documentation for SBEE:
- **[Architecture Guide](doc/ARCHITECTURE.md)**: Conceptual layout, design patterns (Pre-processing/Decorator), session state tracking FSM, and database schemas.
- **[API Reference Guide](doc/API_REFERENCE.md)**: Class-level signatures, constructors, parameters, properties, and exceptions.
- **[Integration Guide](doc/INTEGRATION_GUIDE.md)**: Step-by-step setup walkthrough, active session tracking stream wiring, generic focus category mapping, and exception recovery.
- **[Decisions Log](doc/DECISIONS_LOG.md)**: Chronological phase log, core numeric invariants, the predecessor-traversal-and-max-out regression design decision, database schema migration notes, and the unedited list of the 38 unique tests.

---

## Public API

The curated public API (`package:sbee/sbee.dart`) exposes:
- **Orchestrator Facade**: `SbeeEngine`
- **Domain Models**: `DayType`, `Equipment`, `Exercise`, `FocusCategory`, `MovementPattern`, `RpeInfo`, `WorkoutSession`, `WorkoutSet`, `MillerVariables`, and `ExerciseGraph`.
- **Female Physiology Profile**: `FemaleProfile`, `FemalePhysiologyWrapper`.
- **Named Intensity Techniques**: `IntensityTechniques`, `ClusterSetsStructure`, `RestPauseStructure`, `MyoRepsStructure`.
- **FSM State Management**: `SessionState`, `SessionStreamManager`, `WorkoutSessionState`.
- **Drift Database Reference**: `SbeeDatabase`, `DriftSessionRepository`, `DriftProgressionRepository`.

Internal engine details (such as `AutoregulationEngine`, `SafetyRules`, `PeriodizationScheduler`, and `DetrainingLogic`) are kept private within `src/` to preserve architecture boundaries.

---

## Setup & Integration

To consume this package in a parent project as a local path dependency, declare it in your `pubspec.yaml`:

```yaml
dependencies:
  sbee:
    path: path/to/SBEE
```

---

## Code Examples

### 1. Database Setup

To instantiate the Drift database reference and concrete repositories:

```dart
import 'package:drift/native.dart';
import 'package:sbee/sbee.dart';

void main() {
  // Setup in-memory SQLite database (or NativeDatabase(File('sbee.db')))
  final database = SbeeDatabase(NativeDatabase.memory());
  
  final sessionRepository = DriftSessionRepository(database);
  final progressionRepository = DriftProgressionRepository(database);
}
```

### 2. Composing & Initializing `SbeeEngine`

Create your exercise graph and initialize the engine facade:

```dart
import 'package:sbee/sbee.dart';

void setupEngine(
  SessionRepository sessionRepo, 
  ProgressionRepository progressionRepo
) {
  // Define exercises
  final pushup = Exercise(
    id: 'pushup_1',
    name: 'Push-up Baseline',
    movementPattern: MovementPattern.pushing,
    difficultyTier: 1,
    equipmentRequirements: {},
  );

  final inclinePushup = Exercise(
    id: 'pushup_2',
    name: 'Incline Push-up (Successor)',
    movementPattern: MovementPattern.pushing,
    difficultyTier: 2,
    equipmentRequirements: {},
  );

  // Build progression DAG
  final exerciseGraph = ExerciseGraph({
    pushup: {inclinePushup},
    inclinePushup: {},
  });

  // Initialize the engine facade
  final engine = SbeeEngine(
    sessionRepository: sessionRepo,
    progressionRepository: progressionRepo,
    exerciseGraph: exerciseGraph,
  );
}
```

### 3. Calling the Facade Engine

#### Generate the Next Scheduled Workout

```dart
Future<void> generateWorkout(SbeeEngine engine) async {
  final now = DateTime.now();
  final availableEquipment = {Equipment.bodyweight};

  // Optional: Provide female profile for endocrine adjustments
  final profile = FemaleProfile(
    userStatus: 'Untrained_Female',
    cycleDay: 2, // Day 2 of menses
    hasKneeDiscomfort: true,
    age: 30,
    hasJointPain: false,
  );

  final workout = await engine.generateNextWorkout(
    userId: 'user_123',
    currentTime: now,
    availableEquipment: availableEquipment,
    femaleProfile: profile,
  );

  print('DayType: ${workout.dayType}');
  for (final set in workout.sets) {
    print('Exercise: ${set.exerciseId}, Target RPE: ${set.targetRpe}');
    print('Safety Cues: ${set.cues}');
    print('Rest Interval: ${set.restDuration?.inSeconds} seconds');
  }
}
```

#### Log Set Performance (Autoregulation & DAG Traversal)

```dart
Future<void> logSet(SbeeEngine engine) async {
  // Log performance. The engine automatically adjusts MillerVariables
  // and moves the user along the progression/regression DAG if limits are hit.
  final nextVariables = await engine.logSetPerformance(
    exerciseId: 'pushup_1',
    reps: 10,
    reportedRpe: 5, // under-stimulated (RPE < target - 1)
    targetRpe: 8,
  );

  print('Next training variables: load=${nextVariables.load}, tempo=${nextVariables.tempo}');
}
```
