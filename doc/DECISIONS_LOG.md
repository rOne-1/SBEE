# SBEE Decisions Log

This document records the architectural history and key design decisions made during the five development phases of the Science-Based Exercise Engine (SBEE). It details the core logic invariants, limitations, database schema evolution, and contains the unedited test suite logs from the validation runs.

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
- **DayType-Driven Set Volume**: Before this decision, every exercise always generated the same flat `4` sets regardless of `DayType` (only deload-halving and the age-45+ female-wrapper floor could change it) — a `veryHeavy` day and a `veryLight` day produced the same set count, just with different reps/RPE after the change above. `DayTypePrescription` gained a `setsCount` field (table in §2 below), applied as the new base count in `generateNextWorkout`'s `calculateExerciseSetsCount` helper, with the existing deload-halving and female-wrapper floor logic applied on top unchanged.

### Phase 5: Query Scaling & Mid-Workout Resilience
Two production-readiness gaps identified during a review of "how far is SBEE from daily-drivable": every `generateNextWorkout`/`logSetPerformance` call scanned the **entire** session/set history (`getSessionsInDateRange(DateTime(1970), currentTime)` / `getSetsInDateRange(DateTime(1970), DateTime.now())`) just to find a single most-recent value or a count — fine at zero rows, but an unbounded full-table scan on every screen load after months of real use. Separately, an active `SessionStreamManager` lived entirely in Riverpod/in-memory state; nothing persisted a workout's progress until the host app explicitly called `saveSession()` after `finalizeSession()` — an app crash, force-quit, or backgrounded-process kill mid-workout lost the entire session, including sets already logged.

- **Targeted Repository Queries Replace Full-History Scans**: `SessionRepository` gained five new, narrowly-scoped, indexed query methods: `getMostRecentCompletedSession({requireDayType})`, `getEarliestCompletedSessionStart()`, `getCompletedSessionCount()`, `getReportedSetCountForExercise(exerciseId)`, and `getActiveIncompleteSession()`. `generateNextWorkout` and `logSetPerformance` now call exactly the targeted query each consumer needs (e.g. `PeriodizationScheduler.isDeloadActive` only ever reads the earliest session's `startTime`) instead of fetching everything and filtering in Dart. The pure scheduling/detraining functions themselves (`PeriodizationScheduler.getNextDayType`, `isDeloadActive`; `DetrainingLogic.isDetrainingActive`) were deliberately left with their existing `List<WorkoutSession>` signatures unchanged (avoiding any risk to their existing, well-tested behavior) — callers now just pass a minimal 0-or-1-element list built from the targeted query result, which is behaviorally exact for every call site verified against the existing test suite (all 1000-iteration property tests and unit tests passed unchanged after the refactor). `DriftSessionRepository` implements these via `ORDER BY ... LIMIT 1` and `COUNT`/`MIN` aggregate queries rather than `SELECT *` scans.
- **Incremental Mid-Workout Persistence & Resume**: `SessionStreamManager` now optionally accepts a `SessionRepository` and persists the session (fire-and-forget, errors swallowed so a transient write failure can't crash the active FSM) after `initializeSession` and every `logCurrentSet`. `SessionRepository.getActiveIncompleteSession()` finds a session left with `isCompleted == false`; `SessionStreamManager.resumeSession()` reconstructs the FSM at the correct point (replaying its own guarded transitions against already-logged sets without re-writing their recorded data), and the new `SbeeEngine.resumeActiveSession()` facade method ties both together for a host app to call once at startup. The final, authoritative save at `finalizeSession()` time remains the host app's own explicit, awaited `saveSession()` call, unchanged. No schema change was needed — this reads/writes only the existing `isCompleted`/`startTime`/set fields.
- **Scope note**: this phase closes the two `SBEE`-side gaps identified. It does **not** include a host-app UI for offering "resume your workout?" — that decision (when to check, what to show) belongs entirely to each host app.

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

| DayType | reps | minReps | maxReps | targetRpe | setsCount | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `veryHeavy` | 4 | 1 | 5 | 9 | 5 | Near-maximal by design — expected to trigger the 48h recovery lock once reported. More sets is standard practice for a low-rep heavy day. |
| `moderate` | 10 | 8 | 12 | 8 | 4 | Matches the prior hardcoded default exactly, preserving first-workout behavior. |
| `power` | 4 | 3 | 5 | 7 | 5 | Submaximal on purpose — RFD/explosive work is not trained to failure. More (shorter) sets accumulate quality explosive reps. |
| `veryLight` | 18 | 15 | 20 | 7 | 3 | `maxReps` capped at 20 as a concrete stand-in for the open-ended "20+" zone. Fewer sets — each one is already long/fatiguing at this rep range. |
| `highLactic` | EMOM-computed | = reps | = reps | 7 | 6 | Not an RM-zone prescription — see `IntensityTechniques.generateEmomRepCount`. `setsCount` here means "EMOM rounds per exercise." |

`setsCount` is a base value: the existing deload-halving (rounded up, minimum 1) and age-45+ female-wrapper minimum-floor adjustments in `generateNextWorkout` are still applied on top of it, unchanged.

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

### `APP-SPECIFIC DESIGN DECISION`: All-Patterns-Locked Recovery Fallback
A user training hard across their entire routine in a short span can trigger the 48h post-RPE8 recovery lock on every movement pattern simultaneously, which previously left `generateNextWorkout` with nothing to program.

- **Problem**: `generateNextWorkout` returned a session with zero exercises whenever the lock removed every pattern from the candidate pool at once. An empty session is worse for adherence than a light one — habit-formation research treats a broken routine as a bigger dropout risk than an easy session — and forfeits the recovery benefit light movement has over complete rest.
- **Decision**: When the lock leaves the pool empty, the engine recomputes eligibility ignoring ONLY that lock (equipment and the plyometric exclusion still apply) and, if anything qualifies, generates a session capped at `SbeeEngine.recoveryFallbackTargetRpe` (4) and `recoveryFallbackSetsCount` (2) — deliberately below even a scheduled deload's RPE 6 / 50% volume, since deload assumes moderate freshness going into a planned reduction while this reacts to every pattern having just been pushed to near-failure. Postural (push/pull) balancing is skipped for these sessions. Flagged via `WorkoutSession.recoveryReason = RecoveryReason.allMovementPatternsLocked` so host apps can explain the reduced session instead of surfacing a dead end.
- **Scope**: This does not shorten or bypass the 48h lock itself — the lock still governs normal generation; this only changes what happens when it would otherwise produce nothing.

### `APP-SPECIFIC DESIGN DECISION`: Whole-Account Beginner Exercise-Tier Cap
Every exercise carries a `difficultyTier` (1-6), but exercise selection never used it — a brand-new account with reasonable equipment could be handed tier-6 movements (pistol squats, suspension-trainer fallouts) in its very first session, with nothing in the selection logic aware this might be someone's first time training at all.

- **Problem**: unsupervised first-session exposure to high-skill or high-eccentric-demand movements is a real injury vector for a true beginner, not just a difficulty mismatch — and the catalog already splits cleanly on this line (every shared-core exercise is tier 1-3, every Path specialty exercise is tier 4-6).
- **Decision**: reuse the existing whole-account "Intermediate" status detection (session B above) rather than inventing a new signal. Until that status is achieved, `generateNextWorkout` excludes any exercise with `difficultyTier > SbeeEngine.beginnerMaxDifficultyTier` (3) from the candidate pool, including during the recovery fallback — a fatigued beginner never gets bumped up to a specialty movement just because everything else was filtered out. This is a hard exclusion, not a soft/occasional exposure.
- **Scope**: gates exercise-pool selection only. Chosen Path still determines theme and which specialty pool unlocks later; it no longer determines what's trainable on day one.

### `APP-SPECIFIC DESIGN DECISION`: Generalizing Two Female-Wrapper-Gated Features
Two behaviors were implemented only inside the `FemaleProfile`/`FemalePhysiologyWrapper` path even though neither is actually population-specific: DayType-aware rest intervals, and joint-pain-driven plyometric exclusion.

- **Problem**: `restDuration` was only ever DayType-aware (45s conditioning / 150s strength) for accounts with a `FemaleProfile`; every general-population account got a flat 90s regardless of whether the day was a strength or conditioning focus. Separately, excluding plyometrics required a `FemaleProfile` **and** `age >= 45` **and** `hasJointPain` (`FemalePhysiologyWrapper.isPlyometricsAllowed`) — so a user with real joint pain or limited mobility who wasn't 45+, or wasn't using the female-specific flow at all, had no way anywhere in the app to ask for jumping/high-skill movements to be excluded.
- **Decision**: moved the conditioning/strength rest baseline to `DayTypePrescription.restInterval` (see the schema/prescription decision above) so it's the default for every account; `FemalePhysiologyWrapper.adjustRestInterval` now only adds its own early-follicular `+30s` offset on top of that baseline instead of recomputing it. Added a new `hasJointPain` parameter directly to `generateNextWorkout`, independent of `FemaleProfile`, so any account can request plyometric exclusion; the narrower age-45+-specific claim (`isPlyometricsAllowed`) still applies on top for the population it was written for.
- **Scope**: no existing `FemaleProfile` behavior changed for callers who don't also pass the new flag — a female-profile user under 45 with joint pain still isn't gated by `isPlyometricsAllowed` alone, exactly as before. What changed is that the accommodation is now *reachable* without a `FemaleProfile` at all.
- **Lesson for future wrapper methods**: check whether new logic is genuinely population-specific before writing it inside `FemalePhysiologyWrapper` — see the caution note in ARCHITECTURE.md §3.A.

### `APP-SPECIFIC DESIGN DECISION`: Beginner Session-Volume Taper
`beginnerMaxDifficultyTier` (Phase 5 above) gates *which* exercises a new account can be handed, but nothing previously gated *how much* — `DayTypePrescription.setsCount`/`restInterval` apply identically to a first-ever session and a hundredth one.

- **Problem**: a brand-new account's first "moderate day" produces roughly 10 exercises x 4 sets x 150s rest — upwards of 100 minutes of rest alone before any work time — with nothing about the prescription aware this might be someone's very first time training at all. Difficulty-tier capping alone doesn't address session length or a beginner's likely first-session overwhelm.
- **Decision**: reuse the exact same whole-account "Intermediate" status detection `beginnerMaxDifficultyTier` already reuses (rather than a second, parallel "is this a beginner" signal). Until that status is achieved, `calculateExerciseSetsCount` halves the DayType's prescribed set count (rounded up, minimum 1 via `.ceil()`) — the same halving this function already applies for a scheduled deload (its `isDeload` branch), reused rather than inventing a new, undocumented percentage. (`PeriodizationScheduler.applyDeload` is a separate, session-level truncation exercised only by its own tests — it is not the mechanism either reduction in `calculateExerciseSetsCount` actually uses.) Applied before the female-wrapper minimum-floor adjustment, so that floor always has final say over any reduction stacked before it. If a deload week and a beginner account coincide, the two reductions compose (quartering the base count, still floored at 1) — intentional, since both are independently valid reasons to train lighter.
- **Scope**: deliberately limited to set count only, not rest interval or exercise count per session. `restInterval` is the physiologically-appropriate recovery window for the prescribed RPE regardless of account experience — shortening it would work against recovery, not for it. Exercise-count-per-session is an emergent property of movement-pattern selection and the 2:1 postural balance invariant, not a single tunable value; changing it would risk that invariant rather than simply reducing volume. Set count is the one lever that directly shortens session duration without touching either.

### `APP-SPECIFIC DESIGN DECISION`: Discarding an Abandoned Incomplete Session
`SessionRepository` had a way to find an abandoned incomplete session (`getActiveIncompleteSession`, backing `resumeActiveSession`) but no way to ever remove one.

- **Problem**: a session left incomplete (app closed mid-workout, or the user simply changes their mind) would be surfaced as resumable by `resumeActiveSession` forever, since nothing in the repository contract could delete it. A host app's only option was to hide its own resume prompt locally, which reappears on every restart since the underlying row never goes away.
- **Decision**: added `SessionRepository.deleteSession(String id)` (removes the session and its sets in one transaction) and `SbeeEngine.discardActiveSession()`, a convenience that deletes whatever `getActiveIncompleteSession()` currently returns — a no-op if there's nothing to discard. Deliberately symmetric with `resumeActiveSession()`: one continues the abandoned session, the other ends it for good.
- **Scope**: `deleteSession` is not guarded to incomplete sessions only — the repository permits deleting a completed one too, since there's no reason to make the method more restrictive than the interface needs to be. No current caller does that.

### `APP-SPECIFIC DESIGN DECISION`: Host-App-Facing Deload Status Query
`generateNextWorkout` has always resolved whether a deload week is active internally (step 3) to size that call's own session, but `PeriodizationScheduler.isDeloadActive` itself is not exported and `SbeeEngine` had no host-app-facing equivalent — unlike the movement-lock and postural-balance checks, which have always been queryable via `isMovementLocked`/`validatePosturalBalance`.

- **Problem**: surfaced by a host app's code review, which found its own macrocycle/training-phase dashboard re-implementing the same `daysElapsed ~/ 7 % 5 == 4` week-modulo arithmetic by hand to answer "is this a deload week?" for display purposes, since there was nothing to call instead. The re-implementation happened to be correct at the time (same formula, same inputs), but that's exactly the "duplicated implementation will drift from the real one eventually" trap `doc/HOST_APP_ONBOARDING.md` already warns against for the other two checks — the only reason this one wasn't already caught by that guidance is that this method didn't exist to call.
- **Decision**: added `SbeeEngine.isDeloadActive({required DateTime currentTime})`, mirroring `isMovementLocked`/`validatePosturalBalance`'s existing shape exactly. Internally it reproduces `generateNextWorkout`'s own resolution: reads only the earliest completed session's start date via `SessionRepository.getEarliestCompletedSessionStart()` (an indexed, targeted query — not a full-history scan) and wraps it in a minimal single-session carrier before delegating to `PeriodizationScheduler.isDeloadActive`, since that method only ever reads that one date off its `completedSessions` argument.
- **Scope**: purely additive — a new public method, no change to `generateNextWorkout`'s existing behavior or to `PeriodizationScheduler`'s formula. Answers only "is a deload week active right now"; it does not expose which week-in-cycle or cycle-number a host app might want for its own UI narrative (e.g. "week 3 of 5") — that numbering is a host-app presentation concern with no corresponding SBEE concept, and is intentionally left to the host app to compute from its own session history using the same `getEarliestCompletedSessionStart()` anchor.

### `APP-SPECIFIC DESIGN DECISION`: Closing the Abort/Persist Race Window
`SessionStreamManager`'s incremental mid-workout persistence (`_persistInBackground`, see the class doc) is deliberately fire-and-forget, and `SbeeEngine.discardActiveSession()` (added above) reads-then-deletes the same row from a completely separate call path, with nothing coordinating the two.

- **Problem**: surfaced by a host app's code review. A set logged immediately before the user aborts the workout can still have its incremental save in flight when `discardActiveSession()`'s delete runs; if that save lands afterward, it resurrects the very session the user just chose to discard. `SbeeEngine` can't close this itself — `createWorkoutSession`/`resumeActiveSession` hand the `SessionStreamManager` instance to the host app and keep no reference of their own, so the engine has no way to know whether a manager for the session it's about to delete is even still live, let alone whether it has a write in flight.
- **Decision**: added `SessionStreamManager.awaitPendingPersistence()`, which returns the `Future` behind the most recently launched incremental persist (already-completed if none is in flight). This keeps the coordination where the state actually lives — the manager already tracks the persist call it fires — rather than adding tracking state to `SbeeEngine` or the repository for something neither owns. The host app is responsible for awaiting it before calling `discardActiveSession()` when its manager for that session is still around; documented on both methods.
- **Scope**: purely additive, and does not change `_persistInBackground`'s fire-and-forget behavior or its error-swallowing for the FSM's own sake — only exposes the in-flight `Future` for a caller that specifically needs to sequence against it. A host app that never discards a session (or always does so through a fresh `resumeActiveSession()` on the next launch, i.e. never while a live manager is racing it) has no reason to call the new method.

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
- **Schema Version 5**: Added the all-patterns-locked recovery fallback:
  - Added nullable `recoveryReason` text column to `DriftWorkoutSessions`, backing `WorkoutSession`'s new `RecoveryReason` field (same enum-name-as-text convention as `posturalWarningReason`).

---

## 4.5. Known Limitations & Deferred Items

The current design of SBEE has the following known limitations and deferred implementation items:
- **Kegel / Pelvic Floor Module**: Although endocrine and structural cues are generated, a dedicated, parameterized tracking module for Kegel or direct pelvic floor exercises was deferred and is not built in the current release.
- **General-Population Set-Volume Floor Gap**: A general-population minimum set floor is not enforced globally inside [SafetyRules](../lib/src/engine/safety_rules.dart), leaving it at a default floor of `1` (which acts as a floor gap). The only active set floor constraint currently in place is the age 45+ wrapper override, which sets a minimum floor of `3`.
- **Unverified Bibliography Source Warnings**: The physiological and cycle-based rules (such as menstrual cycle day offsets, endocrine Growth Hormone cues, and submaximal pacing VO2 max ranges) are based on research from the unverified bibliography, which remains subject to ongoing scientific consensus validation. See §4.6 for the complete, individually-cited list of every such claim.
- **Test-Scale Exercise Dataset**: The default internal exercise structures used for validation are test-scale. Production scaling requires the host application database integration to load a full catalog.

---

## 4.6. Unverified Physiological Claims — Complete Enumeration

All 8 methods in [`FemalePhysiologyWrapper`](../lib/src/engine/female_wrapper.dart) that are marked `UNVERIFIED-BIBLIOGRAPHY SOURCE` in their own doc comments. None of these have been checked against real, citable research literature — they are implemented and unit-tested for *internal consistency* (the code does what its comment says), not validated for *physiological accuracy*. Listed here in full, not just summarized, since this is exactly the kind of claim that needs to be checkable at a glance before anyone treats it as more than a documented assumption.

| # | Method | File:Line | Claim |
| :-- | :--- | :--- | :--- |
| 1 | `getEndocrineExplanation()` | `female_wrapper.dart:31` | Frames female tissue adaptation/lipolysis as primarily driven by Growth Hormone (GH) pulsatility, in deliberate contrast to a testosterone-centric model. |
| 2 | `adjustTargetRpe()` | `female_wrapper.dart:38` | During cycle days 1–3 (early follicular) for an `Untrained_Female`, reduces target RPE by exactly `1`. |
| 3 | `adjustRestInterval()` | `female_wrapper.dart:56` | Early-follicular days add a `+30s` rest density buffer for `Untrained_Female`, on top of whatever baseline the caller passes in. (The conditioning-45s/strength-150s baseline this claim used to include has moved to `DayTypePrescription.restInterval` — general rest-interval-by-training-goal programming, not a female-specific claim, so it's tracked separately and is no longer part of this table's scope. It hasn't been independently verified either, just recategorized.) |
| 4 | `getConditioningTargetVo2Max()` | `female_wrapper.dart:85` | Steady-state conditioning should target `55%–65%` of VO2 max. |
| 5 | `getCorrectiveCues()` | `female_wrapper.dart:97` | Knee discomfort should trigger "McGill Big 3" and "Side Plank with Hip Abduction" cues, plus a `12–15` rep floor for lower-body sets. |
| 6 | `adjustIntensityMetric()` | `female_wrapper.dart:128` | Age ≥ 45 should replace 1RM-based intensity with a `2–3 RIR` (Reps in Reserve) target. |
| 7 | `adjustMinSets()` | `female_wrapper.dart:141` | Age ≥ 45 should mandate a minimum floor of `3` sets per movement pattern. |
| 8 | `isPlyometricsAllowed()` | `female_wrapper.dart:154` | Age ≥ 45 **and** reported joint pain together should gate out plyometric exercises entirely. (This is a narrower claim layered on top of `generateNextWorkout(hasJointPain: ...)`, a plain, non-physiology-specific accommodation available to every account regardless of age or profile — see ARCHITECTURE.md §3.A — which is not itself part of the unverified claim.) |

**What would actually close this**, in order of rigor: (a) a sports-science/kinesiology-literate reviewer checking each numbered claim above against real citable sources and either confirming, correcting, or removing it; or (b) short of that, an explicit "informational, not medical advice" disclaimer surfaced to end users in the host app, so the gap is disclosed rather than silently implied to be settled science. A general web research pass can surface candidate literature but cannot by itself close claims this specific and this safety-adjacent — treat any such pass as a lead-generation step for a real reviewer, not a verification.

---

## 4.8. Versioning

The current library version is `0.7.0`. All changes, database schema migrations, and feature additions are recorded in the [CHANGELOG.md](../CHANGELOG.md) in the repository root.

---

## 5. Unedited Test Suite Logs

Below is the complete, unedited list of the 58 unique tests verifying all components of the SBEE library.

```
14-Day Detraining Lockout Invariant (testing 1000 inputs)
2:1 Pull-to-Push Set-Volume Ratio Invariant (testing 1000 inputs)
48-Hour Recovery Gate Lockout Invariant with Pattern Isolation (testing 1000 inputs)
AutoregulationEngine Tests Correctly adjusts Miller variables (Load > Pos > ROM > Height > Tempo)
AutoregulationEngine Tests Correctly evaluates RPE differences
AutoregulationEngine Tests Locks advanced tempo (level 2) if flag is false
DayTypePrescription Tests every DayType returns a prescription with minReps <= reps <= maxReps and a positive setsCount
DayTypePrescription Tests veryHeavy prescribes the documented 1-5 RM neuromuscular zone
DayTypePrescription Tests moderate prescribes the documented 8-12 RM hypertrophy zone
DayTypePrescription Tests veryLight prescribes the documented 15-20+ RM endurance zone
DayTypePrescription Tests power prescribes low reps at a submaximal (not-to-failure) RPE
DayTypePrescription Tests setsCount varies by DayType instead of a flat default
DetrainingLogic Tests Inactivity of >= 14 days triggers detraining
DetrainingLogic Tests Locked out day-types under detraining status
DetrainingLogic Tests Lockout Interaction Integration: 48h Recovery Lock + Detraining Lockout
DetrainingLogic Tests Lockout Interaction Integration: Case 1: Detraining active, 48h Recovery Lock inactive
DetrainingLogic Tests Lockout Interaction Integration: Case 2: Detraining inactive, 48h Recovery Lock active
DetrainingLogic Tests Lockout Interaction Integration: Case 3: Both locks inactive
DetrainingLogic Tests Tempo and corrective cues under detraining status
Drift Database Migration Tests Upgrade path from schema version 1 to 4 runs successfully
Drift Repositories Tests DriftProgressionRepository tracks competency and status date
Drift Repositories Tests DriftSessionRepository bounded-query methods replace full-history scans
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
SbeeEngine Tests generateNextWorkout uses DayType-driven setsCount, not a flat default
SbeeEngine Tests generateNextWorkout uses EMOM-structured reps on highLactic days
SbeeEngine Tests generateNextWorkout withholds Intermediate status below the session-count threshold
SbeeEngine Tests logSetPerformance triggers DAG progression when maxed out and under-stimulated
SbeeEngine Tests logSetPerformance triggers predecessor-traversal-and-max-out regression when at baseline and over-stimulated
SbeeEngine Tests resumeActiveSession recovers a workout interrupted mid-session (no finalize called)
SbeeEngine Tests resumeActiveSession returns null when there is nothing to resume
SessionStateMachine & Stream Tests SessionStateMachine enforces correct transitions
SessionStateMachine & Stream Tests SessionStreamManager persists progress incrementally when given a repository
SessionStateMachine & Stream Tests SessionStreamManager pipelines workout flow reactively
SessionStateMachine & Stream Tests SessionStreamManager.resumeSession rejects resuming while a session is already active
SessionStateMachine & Stream Tests SessionStreamManager.resumeSession resumes at coolDown if every set was already logged
SessionStateMachine & Stream Tests SessionStreamManager.resumeSession restores the FSM at the next unlogged set
```
