# SBEE Architecture

Welcome to the Science-Based Exercise Engine (SBEE) Architecture Guide. This document details the high-level design, architectural patterns, component layouts, and data flow of the SBEE library. It is designed to serve both future maintainers of the engine and host application developers seeking a deep understanding of its internal mechanics.

---

## 1. Design Philosophy

SBEE is built as a **pure-Dart library** focused on resistance training prescription, scheduling, and autoregulation. Its design is governed by the following core principles:

1. **Decoupled Core Logic**: The core mathematical rules of periodization, safety gates, and autoregulation are completely independent of any UI or environment specifics. This ensures the library remains portable, fast, and easily testable.
2. **Deterministic & Safe**: Progression rules, such as Kenneth Miller's 5-variable progression sequence and push-to-pull ratios, are strictly validated. Biomechanical safety invariants are enforced at the type level where possible, and guarded by assertions.
3. **Graph-Driven Tiering**: Exercise progressions are modeled as a Directed Acyclic Graph (DAG). This approach avoids circular progression traps and allows logical, step-by-step scaling of exercises.
4. **Adaptive Customizations**: Physiological adaptations (such as menstrual cycle day offsets or age-specific set volume overrides) pre-process input parameters before they enter the core logic, or decorate output results. This isolates host-specific or population-specific logic from the primary engine.

---

## 2. High-Level Component Layout

SBEE is divided into three distinct layers:
1. **Public Facade (`SbeeEngine`)**: The single orchestrator entry point that coordinates data retrieval, applies safety gates, invokes the scheduler, and returns workout models.
2. **Domain Layer**: Contains immutable, rich domain models (`Exercise`, `WorkoutSession`, `WorkoutSet`, `MillerVariables`) and interfaces for data persistence (`ProgressionRepository`, `SessionRepository`).
3. **Engine Core**: Internal, pure-logic components that implement specific rules (Autoregulation, Safety Rules, Scheduler, Detraining Logic).

The diagram below shows the component relationships and boundaries:

```mermaid
graph TD
    %% Define styles
    classDef facade fill:#4a154b,stroke:#333,stroke-width:2px,color:#fff;
    classDef engine fill:#1f6feb,stroke:#333,stroke-width:1px,color:#fff;
    classDef domain fill:#238636,stroke:#333,stroke-width:1px,color:#fff;
    classDef data fill:#d29922,stroke:#333,stroke-width:1px,color:#fff;

    %% Components
    HostApp[Host Application]

    subgraph SBEE_Library [SBEE Library Public API]
        EngineFacade[SbeeEngine]:::facade
        
        subgraph Domain_Layer [Domain Models & Interfaces]
            Models[Domain Models<br>Exercise, WorkoutSession, WorkoutSet,<br>MillerVariables, DayType, etc.]:::domain
            Interfaces[Repository Interfaces<br>ProgressionRepository<br>SessionRepository]:::domain
            ExGraph[ExerciseGraph DAG]:::domain
        end

        subgraph Core_Engine [Internal Engines]
            AutoReg[AutoregulationEngine]:::engine
            Safety[SafetyRules]:::engine
            Scheduler[PeriodizationScheduler]:::engine
            Detraining[DetrainingLogic]:::engine
            FemaleWrapper[FemalePhysiologyWrapper]:::engine
        end
        
        subgraph Data_Layer [Concrete Data Layer]
            DriftDB[SbeeDatabase SQLite]:::data
            DriftProgRepo[DriftProgressionRepository]:::data
            DriftSessionRepo[DriftSessionRepository]:::data
        end
    end

    %% Relationships
    HostApp -->|Invoke Facade| EngineFacade
    HostApp -->|Direct instantiation| DriftDB
    HostApp -->|Initialize| DriftProgRepo
    HostApp -->|Initialize| DriftSessionRepo
    
    EngineFacade -->|Coordinates| ExGraph
    EngineFacade -->|Calls| FemaleWrapper
    EngineFacade -->|Calls| Safety
    EngineFacade -->|Calls| Scheduler
    EngineFacade -->|Calls| AutoReg
    EngineFacade -->|Calls| Detraining
    
    EngineFacade -->|Queries & Saves| Interfaces
    
    DriftProgRepo -.->|Implements| Interfaces
    DriftSessionRepo -.->|Implements| Interfaces
    DriftDB -.->|Backs| DriftProgRepo
    DriftDB -.->|Backs| DriftSessionRepo
    
    Models -.->|Used by| EngineFacade
    Models -.->|Used by| Core_Engine
```

---

## 3. Core Architectural Patterns

### A. Pre-processing & Decorator Pattern for Physiology
To prevent the core safety-tested engine logic from becoming cluttered with population-specific heuristics, SBEE employs a **Pre-processing / Decorator** pattern implemented in [FemalePhysiologyWrapper](../lib/src/engine/female_wrapper.dart).

- **Pre-processing**: Adjusts inputs (such as decreasing target RPE during early follicular phases or capping target RPE/rest intervals) before they are sent to the core progression calculation.
- **Decoration**: Appends pelvic stability and safety cues onto generated workout sets, or overrides general intensity metric descriptions (e.g. converting 1RM to RIR for older adults) on top of the standard outputs.

This encapsulation ensures that if a new wrapper (e.g. for youth athletics or diabetic populations) is added in the future, it can be written as a separate pre-processing filter without modifying the core state changes in [SbeeEngine](../lib/src/sbee_engine.dart).

```
   [Host Application]
          │
          ▼  (FemaleProfile supplied)
 ┌────────────────────────────────────────┐
 │        FemalePhysiologyWrapper         │  ◄── Pre-processes inputs
 └───────────────────┬────────────────────┘
                     │ (Adjusted targetRpe)
                     ▼
 ┌────────────────────────────────────────┐
 │        AutoregulationEngine            │  ◄── Core engine executes standard math
 └───────────────────┬────────────────────┘
                     │ (New MillerVariables)
                     ▼
 ┌────────────────────────────────────────┐
 │        FemalePhysiologyWrapper         │  ◄── Decorates outputs (Adds safety cues, offsets)
 └───────────────────┬────────────────────┘
                     │
                     ▼
             [Final WorkoutSet]
```

### B. Finite State Machine (FSM) Workout Session Tracking
Workout session execution transitions are non-linear but highly constrained. To prevent invalid states (such as resting before a set starts, or jumping from a warm-up directly to a cool-down), SBEE maps workout sessions to a formal Finite State Machine (FSM) using the [SessionStateMachine](../lib/src/engine/session_state_machine.dart) class:

- **States**: `warmUp` ➔ `activeSet` ➔ `rest` ➔ `coolDown` ➔ `completed`.
- **Transitions**:
  - `startWorkout()`: `warmUp` ➔ `activeSet`
  - `completeSet()`: `activeSet` ➔ `rest`
  - `startNextSet()`: `rest` ➔ `activeSet`
  - `completeWorkout()`: `activeSet` or `rest` ➔ `coolDown`
  - `finishSession()`: `coolDown` ➔ `completed`

This state transition logic is strictly isolated from UI rendering and exposed through a reactive stream.

### C. Reactive Pipeline via RxDart
The [SessionStreamManager](../lib/src/engine/session_stream.dart) manages active session state streams using RxDart's `BehaviorSubject`. 

The host application wires widgets directly to the stream. Any state transition triggers a new immutable `SessionProgressState` broadcast, containing:
1. The active `WorkoutSession` snapshot with logged reps/RPE.
2. The current `SessionState` of the workout.
3. The zero-indexed current set index being executed.

---

## 4. Persistence Architecture

SBEE relies on **Drift** (a reactive persistence library for Dart/Flutter backed by SQLite) to maintain persistent state. The schema is organized into four main tables:

1. **`DriftWorkoutSessions`**: Persists metadata for generated and completed sessions (start time, completion status, day type).
2. **`DriftWorkoutSets`**: Persists log details for every individual set, including reps completed, target RPE, reported RPE, rest duration, corrective cues, and the specific Kenneth Miller variables applied during that set.
3. **`DriftExerciseProgressions`**: Tracks the user's current progress parameters (Miller variables) and competency levels for each individual exercise ID.
4. **`DriftStatusAchieved`**: Tracks milestone dates (e.g. the date the user achieved 'Intermediate' status) which are used to unlock advanced features like slow-tempo variations.

Repositories enforce transactional integrity and convert between Drift's auto-generated data objects and SBEE's pure domain models.
