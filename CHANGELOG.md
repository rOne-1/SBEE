# Changelog

## 0.8.0

- **Added `SbeeEngine.isDeloadActive()`.** `generateNextWorkout` has always resolved whether a deload week is active internally to size its own session, but there was no host-app-facing equivalent — unlike the movement-lock and postural-balance checks, which have always been queryable via `isMovementLocked`/`validatePosturalBalance`. A host app wanting to *display* deload status (e.g. a training-phase dashboard) had no way to ask without re-implementing the same week-modulo arithmetic by hand, exactly the "duplicated implementation will drift from the real one eventually" trap those other two checks already prevent. Mirrors their shape and internals exactly: reads only the earliest completed session's start date via the existing indexed `getEarliestCompletedSessionStart()` query, no full-history scan. Purely additive — no change to `generateNextWorkout` or `PeriodizationScheduler`.
- See `doc/DECISIONS_LOG.md` for full rationale.

## 0.7.0

- **Beginner session-volume taper.** `SbeeEngine.beginnerMaxDifficultyTier` (0.5.0) already capped *which* exercises a new account could be handed, but nothing capped *how much* — `DayTypePrescription.setsCount` applied identically to a first-ever session and a hundredth one, so a brand-new account's first "moderate day" could run to 100+ minutes of rest alone (10 exercises x 4 sets x 150s rest) before any work time. `calculateExerciseSetsCount` now halves the DayType's prescribed set count (rounded up, minimum 1) for any account without whole-account "Intermediate" status — reusing the same status signal `beginnerMaxDifficultyTier` already reuses, and the same halving this function already applies for a scheduled deload, rather than introducing a new signal or an unvetted percentage. Composes with a scheduled deload (both reductions apply) since each is an independently valid reason to train lighter. Deliberately scoped to set count only — rest interval is the physiologically-appropriate recovery window regardless of experience, and exercise-count-per-session is an emergent property of the 2:1 postural balance invariant, not a single tunable value.
- See `doc/DECISIONS_LOG.md` for full rationale.

## 0.6.0

- **Added a real way to discard an abandoned incomplete session.** `SessionRepository.getActiveIncompleteSession()`/`SbeeEngine.resumeActiveSession()` could find a session left over from a crash or a user who never came back to finish it, but nothing could ever remove one — a host app's only option was to hide its own resume prompt locally while the row stayed in the database forever. Added `SessionRepository.deleteSession(String id)` (deletes the session and its sets in one transaction) and `SbeeEngine.discardActiveSession()`, the symmetric counterpart to `resumeActiveSession()`.
- See `doc/DECISIONS_LOG.md` for full rationale.

## 0.5.0

Beginner-safety pass: three related gaps found by walking through the app as a complete-beginner, sedentary, low-mobility persona.

- **All-patterns-locked recovery fallback.** `generateNextWorkout` previously returned a session with zero exercises whenever the 48h post-RPE8 lock removed every movement pattern from the candidate pool at once. It now falls back to the same equipment-eligible catalog at a floor deliberately below even a scheduled deload (`SbeeEngine.recoveryFallbackTargetRpe` = 4, `recoveryFallbackSetsCount` = 2), flagged via the new `WorkoutSession.recoveryReason` (`RecoveryReason` enum). Schema v4 → v5 adds the `recovery_reason` column.
- **Whole-account beginner exercise-tier cap.** Exercise selection filtered by equipment and the recovery lock but never by `difficultyTier` — a brand-new account could be handed tier-6 movements (pistol squats, suspension-trainer fallouts) in its very first session. Every shared-core exercise is tier 1-3 and every Path specialty exercise is tier 4-6, so `generateNextWorkout` now caps candidates to `SbeeEngine.beginnerMaxDifficultyTier` (3) until the account reaches whole-account "Intermediate" status, including during the recovery fallback above.
- **Generalized two features that were accidentally female-profile-only.** DayType-aware rest intervals (45s conditioning / 150s strength) and joint-pain-driven plyometric exclusion both existed only inside the `FemaleProfile`/`FemalePhysiologyWrapper` path, even though neither is population-specific. Moved the rest baseline to `DayTypePrescription.restInterval` (now the default for every account) and added a `hasJointPain` parameter directly to `generateNextWorkout`, independent of `FemaleProfile`. `FemalePhysiologyWrapper.adjustRestInterval`'s signature changed (`baseRest` instead of `originalRest`/`trainingFocus`) since it now only applies its own offset on top of the general baseline rather than recomputing it.
- See `doc/DECISIONS_LOG.md` for full rationale on all three.

## 0.4.0

- **Replaced unbounded full-history table scans with targeted, indexed queries.** `generateNextWorkout` and `logSetPerformance` previously fetched every session/set ever recorded (`getSessionsInDateRange(DateTime(1970), ...)`) just to find a single most-recent value or a count. Added `getMostRecentCompletedSession`, `getEarliestCompletedSessionStart`, `getCompletedSessionCount`, `getReportedSetCountForExercise`, and `getActiveIncompleteSession` to `SessionRepository`, each backed by a real `ORDER BY ... LIMIT 1` / `COUNT` / `MIN` query in `DriftSessionRepository`. No behavior change — the full existing test suite (including all 1000-iteration property tests) passes unchanged.
- **Added incremental mid-workout persistence and crash recovery.** Previously, nothing persisted an active workout session until the host app explicitly saved it after finalizing — an app crash, force-quit, or backgrounded-process kill mid-workout lost all progress, including sets already logged. `SessionStreamManager` now optionally persists after every logged set when given a `SessionRepository`, and a new `SbeeEngine.resumeActiveSession()` reconstructs an in-progress session (resuming at the correct set) after a restart.
- See `doc/DECISIONS_LOG.md` Phase 5 for full rationale.

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
