import 'package:drift/drift.dart';
import '../../engine/miller_variables.dart';
import '../../domain/repositories/progression_repository.dart';
import '../drift/database.dart';

/// Drift implementation of the [ProgressionRepository].
class DriftProgressionRepository implements ProgressionRepository {
  final SbeeDatabase db;

  DriftProgressionRepository(this.db);

  @override
  Future<ExerciseProgression?> getProgression(String exerciseId) async {
    final row = await (db.select(db.driftExerciseProgressions)
      ..where((t) => t.exerciseId.equals(exerciseId))).getSingleOrNull();

    if (row == null) return null;

    return ExerciseProgression(
      exerciseId: row.exerciseId,
      variables: MillerVariables(
        load: row.loadVal,
        bodyPosition: row.bodyPosition,
        rom: row.rom,
        height: row.height,
        tempo: row.tempo,
      ),
      competencyLevel: row.competencyLevel,
      lastPerformed: row.lastPerformed,
    );
  }

  @override
  Future<void> saveProgression(ExerciseProgression progression) async {
    await db.into(db.driftExerciseProgressions).insertOnConflictUpdate(
      DriftExerciseProgression(
        exerciseId: progression.exerciseId,
        loadVal: progression.variables.load,
        bodyPosition: progression.variables.bodyPosition,
        rom: progression.variables.rom,
        height: progression.variables.height,
        tempo: progression.variables.tempo,
        competencyLevel: progression.competencyLevel,
        lastPerformed: progression.lastPerformed,
      ),
    );
  }

  @override
  Future<List<ExerciseProgression>> getAllProgressions() async {
    final rows = await db.select(db.driftExerciseProgressions).get();

    return rows.map((row) => ExerciseProgression(
      exerciseId: row.exerciseId,
      variables: MillerVariables(
        load: row.loadVal,
        bodyPosition: row.bodyPosition,
        rom: row.rom,
        height: row.height,
        tempo: row.tempo,
      ),
      competencyLevel: row.competencyLevel,
      lastPerformed: row.lastPerformed,
    )).toList();
  }

  @override
  Future<DateTime?> getStatusAchievedDate(String status) async {
    final row = await (db.select(db.driftStatusAchieved)
      ..where((t) => t.status.equals(status))).getSingleOrNull();
    return row?.achievedDate;
  }

  @override
  Future<void> saveStatusAchievedDate(String status, DateTime date) async {
    await db.into(db.driftStatusAchieved).insertOnConflictUpdate(
      DriftStatusAchievedData(
        status: status,
        achievedDate: date,
      ),
    );
  }
}
