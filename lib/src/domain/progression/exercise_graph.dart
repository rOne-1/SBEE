import 'package:directed_graph/directed_graph.dart';
import '../models/exercise.dart';

/// A Directed Acyclic Graph (DAG) wrapper representing exercise progression pathways.
/// Structurally prevents cycles and provides topological ordering.
class ExerciseGraph {
  final DirectedGraph<Exercise> _graph;

  /// Creates a new [ExerciseGraph] and validates that it is acyclic.
  /// Throws [ArgumentError] if the graph contains any cycle.
  ExerciseGraph(Map<Exercise, Set<Exercise>> graphMap)
      : _graph = DirectedGraph<Exercise>(
          graphMap,
          comparator: (a, b) => a.id.compareTo(b.id),
        ) {
    if (!_graph.isAcyclic) {
      throw ArgumentError(
          'Exercise graph must be acyclic (no cycles allowed).');
    }
  }

  /// Returns all exercises in the graph.
  Iterable<Exercise> get exercises => _graph.vertices;

  /// Finds an exercise in the graph by its unique ID.
  /// Returns `null` if not found.
  Exercise? findById(String id) {
    for (final exercise in _graph.vertices) {
      if (exercise.id == id) {
        return exercise;
      }
    }
    return null;
  }

  /// Retrieves the direct progressions (successors) of a given [exercise].
  List<Exercise> getProgressions(Exercise exercise) {
    return _graph.edges(exercise).toList();
  }

  /// Retrieves the direct regressions (predecessors) of a given [exercise].
  List<Exercise> getRegressions(Exercise exercise) {
    return _graph.vertices
        .where((v) => _graph.edges(v).contains(exercise))
        .toList();
  }

  /// Returns a topologically sorted list of all exercises.
  List<Exercise> getTopologicalOrder() {
    return _graph.sortedVertices.toList();
  }
}
