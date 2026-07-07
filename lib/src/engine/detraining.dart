import '../domain/models/day_type.dart';
import '../domain/models/workout_session.dart';

/// Implements dynamic return-to-training (detraining) safety checks.
/// 
/// If the inactivity period since the last completed workout session is 14 days or longer,
/// high-intensity day-types (Very Heavy, Power) are locked out, and a Stabilization baseline
/// focusing on 4-2-1 tempos and corrective cues is enforced.
class DetrainingLogic {
  
  /// Dynamically computes if the user has a detraining status at query time.
  /// 
  /// Inactivity trigger: gap between [currentTime] and last completed session is >= 14 days.
  static bool isDetrainingActive({
    required List<WorkoutSession> completedSessions,
    required DateTime currentTime,
  }) {
    if (completedSessions.isEmpty) return false;

    // Find the most recently completed session
    WorkoutSession? lastSession;
    for (final session in completedSessions) {
      if (session.isCompleted) {
        if (lastSession == null || session.startTime.isAfter(lastSession.startTime)) {
          lastSession = session;
        }
      }
    }

    if (lastSession == null) return false;

    // Use endTime if available, otherwise startTime
    final lastActiveTime = lastSession.endTime ?? lastSession.startTime;
    final gap = currentTime.difference(lastActiveTime).inDays;

    return gap >= 14;
  }

  /// Checks if a proposed training [dayType] is allowed.
  /// 
  /// Under detraining status, high-intensity day-types (Very Heavy, Power) are locked out.
  static bool isDayTypeAllowed({
    required DayType dayType,
    required List<WorkoutSession> completedSessions,
    required DateTime currentTime,
  }) {
    if (isDetrainingActive(completedSessions: completedSessions, currentTime: currentTime)) {
      if (dayType == DayType.veryHeavy || dayType == DayType.power) {
        return false;
      }
    }
    return true;
  }

  /// Prescribes the training tempo.
  /// 
  /// Enforces a strict 4-2-1 tempo to re-establish neuromuscular control under detraining status.
  static String getPrescribedTempo({
    required List<WorkoutSession> completedSessions,
    required DateTime currentTime,
    required String defaultTempo,
  }) {
    if (isDetrainingActive(completedSessions: completedSessions, currentTime: currentTime)) {
      return '4-2-1';
    }
    return defaultTempo;
  }

  /// Generates Stabilization corrective cues if detraining is active.
  static List<String> getCorrectiveCues({
    required List<WorkoutSession> completedSessions,
    required DateTime currentTime,
  }) {
    if (isDetrainingActive(completedSessions: completedSessions, currentTime: currentTime)) {
      return [
        'Stabilization Baseline: Inactivity detected >= 14 days. Focus on corrective alignment movements.',
        'Stabilization Tempo: Maintain a strict 4-2-1 tempo to re-establish joint stability and neuromuscular control.',
      ];
    }
    return [];
  }
}
