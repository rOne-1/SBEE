/// Core Science-Based Exercise Engine (SBEE) library.
library sbee;

// Facade Engine
export 'src/sbee_engine.dart';

// Domain Models
export 'src/domain/models/day_type.dart';
export 'src/domain/models/equipment.dart';
export 'src/domain/models/exercise.dart';
export 'src/domain/models/focus_category.dart';
export 'src/domain/models/movement_pattern.dart';
export 'src/domain/models/rpe_scale.dart';
export 'src/domain/models/workout_session.dart';
export 'src/engine/miller_variables.dart';
export 'src/domain/progression/exercise_graph.dart';
export 'src/domain/repositories/progression_repository.dart' show ExerciseProgression;

// Female physiology wrapper (Direct Export)
export 'src/engine/female_wrapper.dart' show FemaleProfile, FemalePhysiologyWrapper;

// Named Intensity Techniques and Structures
export 'src/engine/intensity_techniques.dart' show IntensityTechniques, ClusterSetsStructure, RestPauseStructure, MyoRepsStructure;

// Repositories Interfaces
export 'src/domain/repositories/session_repository.dart';
export 'src/domain/repositories/progression_repository.dart';

// FSM Session Management
export 'src/engine/session_state_machine.dart' show SessionState;
export 'src/engine/session_stream.dart' show SessionStreamManager, WorkoutSessionState;

// Drift Reference Implementation
export 'src/data/drift/database.dart' show SbeeDatabase;
export 'src/data/repositories/drift_progression_repository.dart';
export 'src/data/repositories/drift_session_repository.dart';
