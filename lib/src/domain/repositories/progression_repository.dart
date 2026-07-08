import '../../engine/miller_variables.dart';

/// Represents the progression state of a specific exercise for the user.
class ExerciseProgression {
  final String exerciseId;
  final MillerVariables variables;
  final int competencyLevel; // e.g. 1 = Beginner, 2 = Intermediate, 3 = Advanced
  final DateTime lastPerformed;

  const ExerciseProgression({
    required this.exerciseId,
    required this.variables,
    required this.competencyLevel,
    required this.lastPerformed,
  });

  ExerciseProgression copyWith({
    String? exerciseId,
    MillerVariables? variables,
    int? competencyLevel,
    DateTime? lastPerformed,
  }) {
    return ExerciseProgression(
      exerciseId: exerciseId ?? this.exerciseId,
      variables: variables ?? this.variables,
      competencyLevel: competencyLevel ?? this.competencyLevel,
      lastPerformed: lastPerformed ?? this.lastPerformed,
    );
  }
}

/// Repository interface for tracking user competency, Miller Variables, and status progression.
abstract class ProgressionRepository {
  /// Retrieves the progression state for a specific exercise.
  /// Returns `null` if the user has not started this exercise yet.
  Future<ExerciseProgression?> getProgression(String exerciseId);

  /// Saves or updates the progression state for a specific exercise.
  Future<void> saveProgression(ExerciseProgression progression);

  /// Retrieves all exercise progressions for the user.
  Future<List<ExerciseProgression>> getAllProgressions();

  /// Gets the date when the user first achieved a specific overall status (e.g. 'Intermediate').
  /// Returns `null` if the status has not been achieved.
  Future<DateTime?> getStatusAchievedDate(String status);

  /// Saves the date when the user achieved a specific overall status.
  Future<void> saveStatusAchievedDate(String status, DateTime date);
}

/// Explicit exception thrown on write errors, corrupt reads, or constraint violations in the progression repository.
class ProgressionRepositoryException implements Exception {
  final String message;
  final dynamic cause;

  ProgressionRepositoryException(this.message, [this.cause]);

  @override
  String toString() => 'ProgressionRepositoryException: $message (${cause ?? ""})';
}
