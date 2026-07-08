# Changelog

## 0.1.0

- Initial release of the Science-Based Exercise Engine (SBEE) core library.
- Implemented core domain models: `Equipment`, `FocusCategory`, `MovementPattern`, `DayType`, `RpeInfo`, and `Exercise`.
- Built cycle-resistant exercise progression Directed Acyclic Graph (`ExerciseGraph`).
- Implemented autoregulation engine (`AutoregulationEngine`) utilizing Kenneth Miller's 5-variable progression priority framework.
- Built active session state machine (`SessionStateMachine`) and RxDart stream manager (`SessionStreamManager`).
- Implemented Drift database schema (v2) supporting indices and custom columns for session tracking.
- Developed the pre-processing `FemalePhysiologyWrapper` handling RPE offsets, rest duration adjustments, knee discomfort corrective cues, and senior training limits.
- Built return-to-training (`DetrainingLogic`) locking out high-intensity day-types and prescribing Stabilization baseline (4-2-1 tempo) after 14+ days of inactivity.
- Added comprehensive unit tests, integration tests, and Glados property-based tests (1,000 runs) for safety rules, detraining, and repositories.
