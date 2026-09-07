# SBEE Decisions Log

This document records the architectural history and key design decisions made during the four development phases of the Science-Based Exercise Engine (SBEE). It details the core logic invariants, limitations, database schema evolution, and contains the unedited test suite logs from the validation runs.

---

## 1. Phase-Based Design Decisions

### Phase 1: Foundations & Biomechanical Progressions
- **Kenneth Miller's 5-Variable Biomechanical Progression Framework**:
  - Resistance training variables are adjusted according to a strict priority hierarchy when load modifications are limited (e.g. bodyweight or bands):
    $$\text{Load} > \text{Body Position} > \text{Range of Motion (ROM)} > \text{Height/Elevation} > \text{Speed/Tempo}$$
  - **Increment (Progression)**: Increments the highest priority variable that is not already at its maximum limit. Access to the advanced speed/tempo (level 2) is locked unless intermediate status achieves a $\ge 21$-day unlock gate.
  - **Regression (LIFO Rollback)**: Regresses variables in reverse priority order:
    $$\text{Speed/Tempo} > \text{Height/Elevation} > \text{Range of Motion (ROM)} > \text{Body Position} > \text{Load}$$
    This operates as a Last-In, First-Out (LIFO) rollback to systematically undo the most recent biomechanical progression.
- **Advanced Tempo Gate**: Unlocking the slow-tempo execution tier (level 2) is gated by verifying that the user achieved "Intermediate" status $\ge 21$ days ago, preventing neuromuscular strain.

### Phase 2: Periodization & Safety Invariants
- **Daily Undulating Periodization (DUP)**: 
  - Day-types are rotated in a deterministic sequence to prevent adaptation plateauing:
    $$\text{moderate} \rightarrow \text{veryHeavy} \rightarrow \text{power} \rightarrow \text{veryLight} \rightarrow \text{highLactic}$$
  - Enforces that all day-types are completed within a sliding 14-day window.
- **Deload Macrocycle**: 
  - Scheduled automatically every 5th week (Weeks 4, 9, 14, etc.).
  - Restricts volume (sets per exercise) by 50% (rounded up, minimum 1 set).
  - Caps maximum target RPE for all sets to `6`.
- **48-Hour Recovery Gate Lockout**:
  - Preserves physiological recovery. If a user logs a high-intensity set ($\ge 8$ RPE or maximum effort $\ge 9$ RPE), the parent movement pattern is locked for training for 48 hours relative to the timestamp of the logged set.
  - **Design Decision**: Pattern-level (rather than exercise-level) locking was chosen because the current schema does not classify exercises into light/heavy variants. Pattern-level locking ensures that a fatigued muscle group is completely rested.
- **2:1 Pull-to-Push Balance Invariant**:
  - Enforces a postural balance constraint over a sliding 14-day window.
  - The total set volume of Pulling exercises must be at least double ($\ge 2\times$) the volume of Pushing exercises to prevent shoulder internal rotation issues common in bodyweight training.
- **14-Day Detraining Lockout**:
  - Prevents overexertion after a period of inactivity. If the gap between the current time and the last completed session is $\ge 14$ days, the detraining lockout is triggered:
    - High-intensity day-types (`veryHeavy`, `power`) are redirected to `moderate`.
    - Tempos are restricted to a strict `4-2-1` tempo baseline to re-establish joint stability.
    - Specialized stabilization cues are injected into workout instructions.

### Phase 3: Host Customizations & Female Physiology
- **Isolated Customization Layer (Pre-processing/Decorator)**:
  - Female physiology tracking was built using a wrapper class that intercepts parameters before core engine execution (pre-processing) and adds cues/offsets afterwards (decorating). This ensures that the core mathematical engine remains a single source of truth and is unaffected by external population-specific heuristics.
- **Age 45+ Safety Overrides**:
  - Replaces absolute 1RM intensity metrics with a relative Reps in Reserve (2-3 RIR) target.
  - Restricts high-impact plyometrics if joint pain is reported.
  - Mandates a volume floor of at least 3 sets per movement pattern.
- **Endocrine-Centric Explanations**:
  - Replaces traditional, male-dominated testosterone cues with cues referencing Growth Hormone (GH) pulsatility, matching female physiological adaptation profiles.
- **Menstrual Cycle Phase Offsets**:
  - During early follicular days (1-3), target RPE is reduced by `1` and rest periods are padded by `30` seconds.

### Phase 4: Completing Workout Generation (DayType Prescription, EMOM, Competency Progression)
Prior to this phase, `generateNextWorkout` scheduled a `DayType` label but never varied the actual prescription by it: every set was hardcoded to `reps: 10, targetRpe: 8` (`6` under deload) regardless of whether the day was `veryHeavy` or `veryLight`. `IntensityTechniques` (EMOM/Tabata/cluster/rest-pause/myo-reps) was never called from the generator despite `highLactic` being documented as "Metabolic Buffering (Circuits, EMOM)". And `ExerciseProgression.competencyLevel` plus the whole-account "Intermediate" status (`saveStatusAchievedDate`) were both dead: stored/copied but never computed or written by anything, meaning the 21-day advanced-tempo unlock gate in `logSetPerformance` could never actually trigger.

- **DayType-Driven Rep/RPE Prescription**: See [DayTypePrescription](../lib/src/engine/day_type_prescription.dart), the single source of truth translating each `DayType`'s documented RM zone into a concrete reps/minReps/maxReps/targetRpe prescription (table in §2 below). `WorkoutSet` gained nullable `minReps`/`maxReps` fields (schema v4) to carry the RM-zone range; `reps` is retained unchanged for its existing dual role (generation default / actual-performed count once logged) so no existing call site broke.
- **highLactic via EMOM, not an RM zone**: `highLactic` is excluded from the RM-zone model entirely. Its sets are generated via `IntensityTechniques.generateEmomRepCount(userLevel, secondsPerRep)` (a new generator counterpart to the pre-existing `validateEmomRepCount` validator, sharing the same level-duration table so the two can't drift apart), keyed off the exercise's own `competencyLevel` (1→'beginner', 2→'intermediate', 3→'advanced', default 'beginner'). `secondsPerRep` defaults to `3` — a documented assumption, not a measured value.
- **Competency Progression (per-exercise)**: `ExerciseProgression.competencyLevel` is now derived inside `logSetPerformance` from that exercise's own completed-set history (sets with a non-null `reportedRpe`): promotes 1→2 at `8` completed sets, 2→3 at `20`. Monotonic — never lowers a level already reached.
- **Whole-Account "Intermediate" Status (auto-detected)**: `generateNextWorkout` now checks, once per call, whether the account has `≥ 12` completed sessions **and** `≥ 14` days have elapsed since the very first completed session, and writes `saveStatusAchievedDate('Intermediate', currentTime)` exactly once (idempotent) the first time both are true. Requiring both a count and a day-spread (reusing the codebase's existing 14-day window convention) prevents a burst of same-day sessions from fast-tracking the status — consistent with the "calendar-day progression is strictly forbidden" philosophy already documented on `IntensityTechniques.canProgressTabata`.

---

## 2. Core Invariants & Variable Range Limits

SBEE maintains strict numeric boundaries across all calculations:

| Attribute | Minimum Value | Maximum Value | Default | Rules / Invariants |
| :--- | :--- | :--- | :--- | :--- |
| `load` | 1 | 5 | 1 | Miller biomechanical load variable |
| `bodyPosition` | 1 | 5 | 1 | Miller body position modifier |
| `rom` | 1 | 5 | 1 | Miller range of motion modifier |
| `height` | 1 | 5 | 1 | Miller height/elevation modifier |
| `tempo` | 1 | 2 | 1 | 1 = Standard 4-2-1, 2 = Slow 6s tempo |
| `RPE` | 0 | 10 | — | subjective Borg exertion index |
| `set count floor` | 1 | — | 1 | Default floor is 1 (general-population floor gap). Age 45+ overrides minimum generated sets to 3. |
| competency promotion (1→2) | — | — | 8 sets | Per-exercise completed-set count (`reportedRpe != null`) required to promote `competencyLevel` from Beginner to Intermediate. |
| competency promotion (2→3) | — | — | 20 sets | Per-exercise completed-set count required to promote `competencyLevel` from Intermediate to Advanced. |
| Intermediate status threshold | — | — | 12 sessions | Whole-account completed-session count required before "Intermediate" status can be auto-detected. |
| Intermediate status min spread | — | — | 14 days | Minimum elapsed days since the account's first completed session, required alongside the session count above. |
| EMOM `secondsPerRep` default | — | — | 3s | Assumed per-rep pacing used to compute `highLactic` EMOM rep counts. A documented assumption, not a measured value. |

### DayType Prescription Table (Phase 4)

| DayType | reps | minReps | maxReps | targetRpe | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `veryHeavy` | 4 | 1 | 5 | 9 | Near-maximal by design — expected to trigger the 48h recovery lock once reported. |
| `moderate` | 10 | 8 | 12 | 8 | Matches the prior hardcoded default exactly, preserving first-workout behavior. |
| `power` | 4 | 3 | 5 | 7 | Submaximal on purpose — RFD/explosive work is not trained to failure. |
| `veryLight` | 18 | 15 | 20 | 7 | `maxReps` capped at 20 as a concrete stand-in for the open-ended "20+" zone. |
| `highLactic` | EMOM-computed | = reps | = reps | 7 | Not an RM-zone prescription — see `IntensityTechniques.generateEmomRepCount`. |

## 3. App-Specific Design Decisions

### `APP-SPECIFIC DESIGN DECISION`: Predecessor-Traversal-and-Max-Out Regression Logic
During Phase 3 review, a critical training-stimulus decision was finalized concerning regression along the [ExerciseGraph](../lib/src/domain/progression/exercise_graph.dart) DAG.

- **Problem**: When a user reports over-stimulation (reported RPE > target RPE + 1) while working at the lowest biomechanical baseline tier (`load=1, bodyPosition=1, rom=1, height=1, tempo=1`), they must regress to the predecessor exercise in the graph. However, simply resetting the predecessor exercise variables to `1, 1, 1, 1, 1` drops the user's workload excessively, leading to rapid detraining.
- **Decision**: When regressing to a predecessor exercise, the engine dynamically sets the predecessor's variables to their absolute maximum limit (`load=5, bodyPosition=5, rom=5, height=5, tempo=2`). This "predecessor-traversal-and-max-out" strategy sustains stimulus at a safe tier immediately below the failed exercise, facilitating high-density stabilization work instead of dropping the user back to baseline.

### `APP-SPECIFIC DESIGN DECISION`: Postural Balance Generation Enforcement
Enforcing a 2:1 pull-to-push set-volume ratio is required for preventing shoulder internal rotation issues.

- **Problem**: Previously, postural balance checks were only descriptive (`validatePosturalBalance`). It was possible for the generator to output sessions with excess push sets, requiring application-level corrections.
- **Decision**: Enforced ratio checks directly on the generator side (`generateNextWorkout`). Pushing exercises are selected sequentially from a deterministically shuffled list, and only added if the combined history + new session sets satisfy:
  $$H_{\text{pull}} + N_{\text{pull}} \ge 2 \times (H_{\text{push}} + N_{\text{push}} + \text{setsCount})$$
  If no pulling exercises are available in the candidate pool, the engine falls back to select pushing exercises anyway and flags the session with `PosturalWarningReason.noPullingAvailable`. Deficits that cannot be corrected are flagged as `PosturalWarningReason.historicalDeficit`.
- **Scaling Points**: All other-pattern and pulling exercises are included unconditionally in their original order. For massive catalogs, introducing sizing constraints or exercise count caps is deferred as a known scaling point.

---

## 4. Database Schema Versioning

Drift persistence schema versions are tracked as follows:
- **Schema Version 1**: Core tracking. Supported exercises, sets (reps, target RPE, reported RPE), and Miller variables.
- **Schema Version 2**: Upgraded to support undulating periodization and advanced wrapper details:
  - Added `dayType` column to `DriftWorkoutSessions`.
  - Added `restDurationSeconds` and `cuesJson` columns to `DriftWorkoutSets` for detailed feedback logs.
  - Added indexes `idx_workout_sessions_time` and `idx_workout_sets_pattern_time` to optimize range-based safety queries.
- **Schema Version 3**: Added postural balance tracking features:
  - Added `posturalWarning` and `posturalWarningReason` text columns to `DriftWorkoutSessions` table.
- **Schema Version 4**: Added DayType-driven prescription range tracking:
  - Added nullable `minReps` and `maxReps` integer columns to `DriftWorkoutSets`, backing `WorkoutSet`'s new rep-range fields.

---

## 4.5. Known Limitations & Deferred Items

The current design of SBEE has the following known limitations and deferred implementation items:
- **Kegel / Pelvic Floor Module**: Although endocrine and structural cues are generated, a dedicated, parameterized tracking module for Kegel or direct pelvic floor exercises was deferred and is not built in the current release.
- **General-Population Set-Volume Floor Gap**: A general-population minimum set floor is not enforced globally inside [SafetyRules](../lib/src/engine/safety_rules.dart), leaving it at a default floor of `1` (which acts as a floor gap). The only active set floor constraint currently in place is the age 45+ wrapper override, which sets a minimum floor of `3`.
- **Unverified Bibliography Source Warnings**: The physiological and cycle-based rules (such as menstrual cycle day offsets, endocrine Growth Hormone cues, and submaximal pacing VO2 max ranges) are based on research from the unverified bibliography, which remains subject to ongoing scientific consensus validation.
- **Test-Scale Exercise Dataset**: The default internal exercise structures used for validation are test-scale. Production scaling requires the host application database integration to load a full catalog.

---

## 4.8. Versioning

The current library version is `0.2.0`. All changes, database schema migrations, and feature additions are recorded in the [CHANGELOG.md](../CHANGELOG.md) in the repository root.

---

## 5. Unedited Test Suite Logs

Below is the complete, unedited list of the 49 unique tests verifying all components of the SBEE library.

```
14-Day Detraining Lockout Invariant (testing 1000 inputs)
2:1 Pull-to-Push Set-Volume Ratio Invariant (testing 1000 inputs)
48-Hour Recovery Gate Lockout Invariant with Pattern Isolation (testing 1000 inputs)
AutoregulationEngine Tests Correctly adjusts Miller variables (Load > Pos > ROM > Height > Tempo)
AutoregulationEngine Tests Correctly evaluates RPE differences
AutoregulationEngine Tests Locks advanced tempo (level 2) if flag is false
DayTypePrescription Tests every DayType returns a prescription with minReps <= reps <= maxReps
DayTypePrescription Tests veryHeavy prescribes the documented 1-5 RM neuromuscular zone
DayTypePrescription Tests moderate prescribes the documented 8-12 RM hypertrophy zone
DayTypePrescription Tests veryLight prescribes the documented 15-20+ RM endurance zone
DayTypePrescription Tests power prescribes low reps at a submaximal (not-to-failure) RPE
DetrainingLogic Tests Inactivity of >= 14 days triggers detraining
DetrainingLogic Tests Locked out day-types under detraining status
DetrainingLogic Tests Lockout Interaction Integration: 48h Recovery Lock + Detraining Lockout
DetrainingLogic Tests Lockout Interaction Integration: Case 1: Detraining active, 48h Recovery Lock inactive
DetrainingLogic Tests Lockout Interaction Integration: Case 2: Detraining inactive, 48h Recovery Lock active
DetrainingLogic Tests Lockout Interaction Integration: Case 3: Both locks inactive
DetrainingLogic Tests Tempo and corrective cues under detraining status
Drift Database Migration Tests Upgrade path from schema version 1 to 4 runs successfully
Drift Repositories Tests DriftProgressionRepository tracks competency and status date
Drift Repositories Tests DriftSessionRepository saves and retrieves sessions and sets
ExerciseGraph Tests Successfully builds acyclic graph and sorts topologically
ExerciseGraph Tests Throws ArgumentError if a cycle is introduced
FemalePhysiologyWrapper Tests Age 45+ logic overrides target metric and gates plyometrics
FemalePhysiologyWrapper Tests Early Follicular RPE and Rest offsets are applied correctly
FemalePhysiologyWrapper Tests Endocrine Explanation surfaces growth hormone correctly
FemalePhysiologyWrapper Tests McGill Big 3 and Knee valgus safety rail cues are triggered
FemalePhysiologyWrapper Tests Recovery rest intervals pacing for conditioning and strength
FemalePhysiologyWrapper Tests Spinal flexion core pacing cue override
FemalePhysiologyWrapper Tests Submaximal pacing VO2 max range
IntensityTechniques Tests EMOM constraints rep selection limits
IntensityTechniques Tests EMOM rep count generation stays within level work-duration limits
IntensityTechniques Tests Myo-Reps generation enforces 3-5 mini-sets boundaries
IntensityTechniques Tests Tabata hybrid progression gate checks sessions and RPE
IntensityTechniques Tests Tabata hybrid progression gate zero-session edge case
PeriodizationScheduler Tests Apply deload cuts volume in half and limits target RPE to 6
PeriodizationScheduler Tests Deload week is determined active on week 5 (index 4)
PeriodizationScheduler Tests Next day-type rotates correctly
Repository Validation and Exception Invariant (testing 1000 inputs)
SbeeEngine Tests Per-exercise competencyLevel is promoted after enough completed sets
SbeeEngine Tests generateNextWorkout auto-detects Intermediate status once session-count and day-spread thresholds are met
SbeeEngine Tests generateNextWorkout filters equipment, recovery locks, and joint-pain plyometrics
SbeeEngine Tests generateNextWorkout prescribes DayType-driven reps/RPE instead of a hardcoded default
SbeeEngine Tests generateNextWorkout uses EMOM-structured reps on highLactic days
SbeeEngine Tests generateNextWorkout withholds Intermediate status below the session-count threshold
SbeeEngine Tests logSetPerformance triggers DAG progression when maxed out and under-stimulated
SbeeEngine Tests logSetPerformance triggers predecessor-traversal-and-max-out regression when at baseline and over-stimulated
SessionStateMachine & Stream Tests SessionStateMachine enforces correct transitions
SessionStateMachine & Stream Tests SessionStreamManager pipelines workout flow reactively
```
