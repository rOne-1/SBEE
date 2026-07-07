import 'equipment.dart';
import 'movement_pattern.dart';

/// Represents an exercise in the system.
class Exercise {
  final String id;
  final String name;
  final MovementPattern movementPattern;
  final int difficultyTier;
  final Set<Equipment> equipmentRequirements;
  final List<String> defaultCues;
  final Map<String, String> correctiveCues; // key: trigger/feedback, value: cue

  const Exercise({
    required this.id,
    required this.name,
    required this.movementPattern,
    required this.difficultyTier,
    required this.equipmentRequirements,
    this.defaultCues = const [],
    this.correctiveCues = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          movementPattern == other.movementPattern &&
          difficultyTier == other.difficultyTier;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      movementPattern.hashCode ^
      difficultyTier.hashCode;

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, pattern: $movementPattern, tier: $difficultyTier)';
  }
}
