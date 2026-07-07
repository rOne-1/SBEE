import '../models/movement_pattern.dart';
import '../models/workout_session.dart';

/// Repository interface for saving and querying workout sessions and sets.
abstract class SessionRepository {
  /// Saves a complete workout session (including its sets).
  Future<void> saveSession(WorkoutSession session);

  /// Retrieves a workout session by its ID.
  Future<WorkoutSession?> getSession(String id);

  /// Retrieves all workout sessions within a given date range.
  Future<List<WorkoutSession>> getSessionsInDateRange(DateTime start, DateTime end);

  /// Retrieves all logged workout sets for a specific movement pattern since a given timestamp.
  Future<List<WorkoutSet>> getSetsForMovementPattern(MovementPattern pattern, DateTime since);

  /// Retrieves all logged sets within a given date range.
  Future<List<WorkoutSet>> getSetsInDateRange(DateTime start, DateTime end);
}
