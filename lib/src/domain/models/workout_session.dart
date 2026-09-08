import 'day_type.dart';
import '../../engine/miller_variables.dart';
import 'movement_pattern.dart';

/// Represents a single logged set in a workout session.
class WorkoutSet {
  final String id;
  final String sessionId;
  final String exerciseId;
  final MovementPattern movementPattern;
  final int setNumber;
  final int reps;
  final int?
      minReps; // Prescribed rep-range floor. Null if this set was not generated from a ranged prescription.
  final int?
      maxReps; // Prescribed rep-range ceiling. Null if this set was not generated from a ranged prescription.
  final int targetRpe;
  final int? reportedRpe; // Null if set is not yet completed/reported
  final MillerVariables variables;
  final DateTime timestamp;
  final Duration? restDuration;
  final List<String> cues;

  const WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.movementPattern,
    required this.setNumber,
    required this.reps,
    this.minReps,
    this.maxReps,
    required this.targetRpe,
    this.reportedRpe,
    required this.variables,
    required this.timestamp,
    this.restDuration,
    this.cues = const [],
  });

  bool get isHighIntensity => (reportedRpe ?? 0) >= 8;

  /// True if this set was generated from a min/max rep-range prescription
  /// (e.g. DayType-driven generation) rather than a single fixed [reps] value.
  bool get hasRepRange => minReps != null && maxReps != null;

  WorkoutSet copyWith({
    String? id,
    String? sessionId,
    String? exerciseId,
    MovementPattern? movementPattern,
    int? setNumber,
    int? reps,
    int? minReps,
    int? maxReps,
    int? targetRpe,
    int? reportedRpe,
    MillerVariables? variables,
    DateTime? timestamp,
    Duration? restDuration,
    List<String>? cues,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      movementPattern: movementPattern ?? this.movementPattern,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      minReps: minReps ?? this.minReps,
      maxReps: maxReps ?? this.maxReps,
      targetRpe: targetRpe ?? this.targetRpe,
      reportedRpe: reportedRpe ?? this.reportedRpe,
      variables: variables ?? this.variables,
      timestamp: timestamp ?? this.timestamp,
      restDuration: restDuration ?? this.restDuration,
      cues: cues ?? this.cues,
    );
  }
}

enum PosturalWarningReason {
  none,
  noPullingAvailable,
  historicalDeficit,
}

/// Explains why a generated session deviates from its normal DayType
/// prescription for a reason distinct from postural (push/pull) balance --
/// specifically, whole-body fatigue. Kept as its own enum rather than folded
/// into [PosturalWarningReason], which is documented and tested as
/// specifically about push/pull ratio, not fatigue management.
enum RecoveryReason {
  none,

  /// Every movement pattern the exercise pool could otherwise draw from was
  /// under the 48h post-RPE8 recovery lock at once (see
  /// `SafetyRules.isMovementLocked`), which would otherwise leave the
  /// session with zero exercises. Rather than generating nothing, the
  /// engine falls back to the same equipment-eligible catalog at a steep
  /// volume/intensity floor (`SbeeEngine.recoveryFallbackTargetRpe` /
  /// `recoveryFallbackSetsCount`) -- active-recovery-style light movement,
  /// not a suspension of the lock itself.
  allMovementPatternsLocked,
}

/// Represents a workout session containing multiple exercise sets.
class WorkoutSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutSet> sets;
  final bool isCompleted;
  final DayType? dayType; // Null if not scheduled or custom
  final String? posturalWarning;
  final PosturalWarningReason posturalWarningReason;
  final RecoveryReason recoveryReason;

  const WorkoutSession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.sets = const [],
    this.isCompleted = false,
    this.dayType,
    this.posturalWarning,
    this.posturalWarningReason = PosturalWarningReason.none,
    this.recoveryReason = RecoveryReason.none,
  });

  WorkoutSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    List<WorkoutSet>? sets,
    bool? isCompleted,
    DayType? dayType,
    String? posturalWarning,
    PosturalWarningReason? posturalWarningReason,
    RecoveryReason? recoveryReason,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sets: sets ?? this.sets,
      isCompleted: isCompleted ?? this.isCompleted,
      dayType: dayType ?? this.dayType,
      posturalWarning: posturalWarning ?? this.posturalWarning,
      posturalWarningReason:
          posturalWarningReason ?? this.posturalWarningReason,
      recoveryReason: recoveryReason ?? this.recoveryReason,
    );
  }
}
