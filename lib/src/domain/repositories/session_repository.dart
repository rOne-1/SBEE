import '../models/movement_pattern.dart';
import '../models/workout_session.dart';

/// Repository interface for saving and querying workout sessions and sets.
abstract class SessionRepository {
  /// Saves a complete workout session (including its sets).
  Future<void> saveSession(WorkoutSession session);

  /// Retrieves a workout session by its ID.
  Future<WorkoutSession?> getSession(String id);

  /// Retrieves all workout sessions within a given date range.
  Future<List<WorkoutSession>> getSessionsInDateRange(
      DateTime start, DateTime end);

  /// Retrieves all logged workout sets for a specific movement pattern since a given timestamp.
  Future<List<WorkoutSet>> getSetsForMovementPattern(
      MovementPattern pattern, DateTime since);

  /// Retrieves all logged sets within a given date range.
  Future<List<WorkoutSet>> getSetsInDateRange(DateTime start, DateTime end);

  /// Retrieves the single most recently-started completed session, or `null` if
  /// none exists. If [requireDayType] is `true`, only considers completed
  /// sessions that also have a non-null [WorkoutSession.dayType].
  ///
  /// Bounded, indexed-query replacement for the previous pattern of fetching
  /// every completed session ever (`getSessionsInDateRange(DateTime(1970), ...)`)
  /// just to find the most recent one.
  Future<WorkoutSession?> getMostRecentCompletedSession(
      {bool requireDayType = false});

  /// Retrieves the start time of the earliest completed session (the training
  /// program's start date), or `null` if no completed session exists. Returns
  /// only the timestamp rather than a full [WorkoutSession] since that is all
  /// any current caller needs.
  Future<DateTime?> getEarliestCompletedSessionStart();

  /// Retrieves the total count of completed sessions.
  Future<int> getCompletedSessionCount();

  /// Retrieves the count of logged, reported sets (`reportedRpe != null`) for
  /// a specific exercise, across all sessions.
  Future<int> getReportedSetCountForExercise(String exerciseId);

  /// Retrieves the single most recently-started incomplete (`isCompleted ==
  /// false`) session, or `null` if none exists. Used to detect and resume a
  /// workout session left in progress after an app crash or restart.
  Future<WorkoutSession?> getActiveIncompleteSession();

  /// Permanently deletes a session and its sets. Intended for discarding an
  /// abandoned incomplete session -- [getActiveIncompleteSession] would
  /// otherwise keep surfacing it as resumable indefinitely, since nothing
  /// else in this repository ever removes a session once written. Deleting a
  /// completed session is allowed at the repository level (no `isCompleted`
  /// guard) but is not something any current caller does.
  Future<void> deleteSession(String id);
}

/// Explicit exception thrown on write errors, corrupt reads, or constraint violations in the session repository.
class SessionRepositoryException implements Exception {
  final String message;
  final dynamic cause;

  SessionRepositoryException(this.message, [this.cause]);

  @override
  String toString() => 'SessionRepositoryException: $message (${cause ?? ""})';
}
