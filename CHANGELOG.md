# Changelog

## 0.3.0

- **Set volume (`setsCount`) now varies by `DayType`** instead of the same flat `4` sets used for every day-type. `DayTypePrescription` gained a `setsCount` field (veryHeavy: 5, moderate: 4, power: 5, veryLight: 3, highLactic: 6 EMOM rounds), applied as the new base before the existing deload-halving and female-wrapper minimum-floor adjustments.
- Adds 2 new tests (51 total). See `doc/DECISIONS_LOG.md` Phase 4 for rationale.

## 0.2.0

- **DayType-driven workout generation.** `generateNextWorkout` previously hardcoded `reps: 10, targetRpe: 8` for every set regardless of `DayType`. Added `DayTypePrescription`, the single source of truth mapping each `DayType`'s documented RM zone (e.g. `veryHeavy`: 1-5 RM) to a concrete reps/RPE prescription, and wired it into generation.
- **`WorkoutSet` gained nullable `minReps`/`maxReps` fields** carrying the prescribed rep-range (Drift schema v4). `reps` is unchanged and still serves its existing role.
- **`highLactic` days now generate an EMOM structure** via a new `IntensityTechniques.generateEmomRepCount`, instead of the same plain straight-set prescription as every other day-type. Rep count is keyed off the exercise's own competency level.
- **Competency progression is no longer dead code.** `ExerciseProgression.competencyLevel` is now actually computed (from completed-set history) instead of being stored and copied forward unchanged forever.
- **The "Intermediate" status is now auto-detected**, so the previously-unreachable 21-day advanced-tempo unlock gate in `logSetPerformance` can actually trigger.
- See `doc/DECISIONS_LOG.md` Phase 4 for the full rationale and the exact thresholds chosen.

## 0.1.1

- Fixed a public API export bug: `lib/sbee.dart` exported a non-existent `WorkoutSessionState` name; the actual class is `SessionProgressState`. Corrected the export and the matching reference in `README.md`.
- Added the `lints` package as a dev dependency. `analysis_options.yaml` has always declared `include: package:lints/recommended.yaml`, but the package was never added, so the include was silently failing and the "recommended" rule set was never actually active.
- Corrected this changelog's own schema version claim below (was stale at "v2"; the schema has been at v3, with postural-warning columns, since the postural balance enforcement work landed).

## 0.1.0

- Initial release of the Science-Based Exercise Engine (SBEE) core library.
- Implemented core domain models: `Equipment`, `FocusCategory`, `MovementPattern`, `DayType`, `RpeInfo`, and `Exercise`.
- Built cycle-resistant exercise progression Directed Acyclic Graph (`ExerciseGraph`).
- Implemented autoregulation engine (`AutoregulationEngine`) utilizing Kenneth Miller's 5-variable progression priority framework.
- Built active session state machine (`SessionStateMachine`) and RxDart stream manager (`SessionStreamManager`).
- Implemented Drift database schema (v3) supporting indices, custom columns for session tracking, and postural-warning tracking.
- Developed the pre-processing `FemalePhysiologyWrapper` handling RPE offsets, rest duration adjustments, knee discomfort corrective cues, and senior training limits.
- Built return-to-training (`DetrainingLogic`) locking out high-intensity day-types and prescribing Stabilization baseline (4-2-1 tempo) after 14+ days of inactivity.
- Added comprehensive unit tests, integration tests, and Glados property-based tests (1,000 runs) for safety rules, detraining, and repositories.
