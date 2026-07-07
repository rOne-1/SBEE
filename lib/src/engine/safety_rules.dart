import '../domain/models/movement_pattern.dart';
import '../domain/models/workout_session.dart';

/// Implements science-based safety and balance rules for workout prescription.
class SafetyRules {
  static bool validatePushPullRatio({
    required List<WorkoutSet> pastSets,
    required DateTime currentTime,
  }) {
    final windowStart = currentTime.subtract(const Duration(days: 14));
    final setsInWindow = pastSets.where((s) {
      // Timestamp must be within the last 14 days and not in the future relative to currentTime
      return s.timestamp.isAfter(windowStart) && !s.timestamp.isBefore(windowStart) && !s.timestamp.isAfter(currentTime);
    }).toList();
    
    final pushSets = setsInWindow.where((s) => s.movementPattern == MovementPattern.pushing).length;
    final pullSets = setsInWindow.where((s) => s.movementPattern == MovementPattern.pulling).length;

    if (pushSets == 0) return true;
    return pullSets >= (2 * pushSets);
  }

  /// DESIGN REASONING: Pattern-level (not exercise-level) locking is intentional
  /// given the current absence of a light/heavy exercise classification in the schema.
  /// This should be revisited if/when exercise-level intensity tagging is added later.
  static bool isMovementLocked({
    required List<WorkoutSet> pastSets,
    required MovementPattern pattern,
    required DateTime currentTime,
  }) {
    for (final set in pastSets) {
      if (set.movementPattern == pattern && set.reportedRpe != null && set.reportedRpe! >= 8) {
        final difference = currentTime.difference(set.timestamp);
        if (difference.inHours >= 0 && difference.inHours < 48) {
          return true; // Locked
        }
      }
    }
    return false; // Free to train
  }
}
