import 'day_type.dart';
import 'equipment.dart';
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
    required this.targetRpe,
    this.reportedRpe,
    required this.variables,
    required this.timestamp,
    this.restDuration,
    this.cues = const [],
  });

  bool get isHighIntensity => (reportedRpe ?? 0) >= 8;

  WorkoutSet copyWith({
    String? id,
    String? sessionId,
    String? exerciseId,
    MovementPattern? movementPattern,
    int? setNumber,
    int? reps,
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

  const WorkoutSession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.sets = const [],
    this.isCompleted = false,
    this.dayType,
    this.posturalWarning,
    this.posturalWarningReason = PosturalWarningReason.none,
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
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sets: sets ?? this.sets,
      isCompleted: isCompleted ?? this.isCompleted,
      dayType: dayType ?? this.dayType,
      posturalWarning: posturalWarning ?? this.posturalWarning,
      posturalWarningReason: posturalWarningReason ?? this.posturalWarningReason,
    );
  }
}
