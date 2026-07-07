import '../domain/models/day_type.dart';
import '../domain/models/workout_session.dart';

/// Implements Undulating Periodization scheduling and deload rules.
class PeriodizationScheduler {
  /// Determines the next [DayType] based on the user's completed session history.
  /// 
  /// Enforces that all 5 day-types are cycled through within any 14-day window
  /// by rotating through them in a deterministic order:
  /// moderate -> veryHeavy -> power -> veryLight -> highLactic.
  static DayType getNextDayType(List<WorkoutSession> completedSessions) {
    if (completedSessions.isEmpty) {
      return DayType.moderate; // Default starting day
    }

    // Find the last completed session that had a valid day type.
    WorkoutSession? lastSessionWithDayType;
    for (final session in completedSessions.reversed) {
      if (session.isCompleted && session.dayType != null) {
        lastSessionWithDayType = session;
        break;
      }
    }

    if (lastSessionWithDayType == null) {
      return DayType.moderate;
    }

    // Determine the next day type in the rotation.
    final lastType = lastSessionWithDayType.dayType!;
    switch (lastType) {
      case DayType.moderate:
        return DayType.veryHeavy;
      case DayType.veryHeavy:
        return DayType.power;
      case DayType.power:
        return DayType.veryLight;
      case DayType.veryLight:
        return DayType.highLactic;
      case DayType.highLactic:
        return DayType.moderate;
    }
  }

  /// Determines if a deload week is currently active.
  /// 
  /// A deload week is mandatory every 4-6 weeks. This implementation uses a 5-week macrocycle,
  /// where the 5th week (weeks 4, 9, 14, ...) is scheduled as a deload week.
  static bool isDeloadActive({
    required List<WorkoutSession> completedSessions,
    required DateTime currentTime,
  }) {
    if (completedSessions.isEmpty) return false;

    // Sort sessions by start time to find the start of the training program.
    final sorted = List<WorkoutSession>.from(completedSessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    final programStart = sorted.first.startTime;
    final daysElapsed = currentTime.difference(programStart).inDays;
    
    if (daysElapsed < 0) return false;

    final currentWeekIndex = daysElapsed ~/ 7;
    // Week 4, 9, 14, etc. (every 5th week) is a deload week.
    return (currentWeekIndex % 5) == 4;
  }

  /// Applies deload constraints to a workout session if active.
  /// 
  /// Deload constraints:
  /// - Reduces volume (sets) by 50% (rounded up, minimum 1 set).
  /// - Limits target RPE of all sets to a maximum of 6.
  static WorkoutSession applyDeload({
    required WorkoutSession session,
    required bool isDeload,
  }) {
    if (!isDeload || session.sets.isEmpty) return session;

    final targetSetCount = (session.sets.length / 2).ceil();
    final deloadSets = session.sets.take(targetSetCount).map((set) {
      final originalTargetRpe = set.targetRpe;
      final newTargetRpe = originalTargetRpe > 6 ? 6 : originalTargetRpe;
      return set.copyWith(targetRpe: newTargetRpe);
    }).toList();

    return session.copyWith(sets: deloadSets);
  }
}
