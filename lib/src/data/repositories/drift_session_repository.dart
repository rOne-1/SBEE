import 'package:drift/drift.dart';
import '../../engine/miller_variables.dart';
import '../../domain/models/day_type.dart';
import '../../domain/models/movement_pattern.dart';
import '../../domain/models/workout_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../drift/database.dart';

/// Drift implementation of the [SessionRepository].
class DriftSessionRepository implements SessionRepository {
  final SbeeDatabase db;

  DriftSessionRepository(this.db);

  @override
  Future<void> saveSession(WorkoutSession session) async {
    await db.transaction(() async {
      await db.into(db.driftWorkoutSessions).insertOnConflictUpdate(
        DriftWorkoutSession(
          id: session.id,
          startTime: session.startTime,
          endTime: session.endTime,
          isCompleted: session.isCompleted,
          dayType: session.dayType?.index,
        ),
      );

      // Clean up previous sets for this session to avoid duplicates
      await (db.delete(db.driftWorkoutSets)..where((t) => t.sessionId.equals(session.id))).go();

      // Insert current sets
      for (final s in session.sets) {
        await db.into(db.driftWorkoutSets).insert(
          DriftWorkoutSet(
            id: s.id,
            sessionId: s.sessionId,
            exerciseId: s.exerciseId,
            movementPattern: s.movementPattern.index,
            setNumber: s.setNumber,
            reps: s.reps,
            targetRpe: s.targetRpe,
            reportedRpe: s.reportedRpe,
            loadVal: s.variables.load,
            bodyPosition: s.variables.bodyPosition,
            rom: s.variables.rom,
            height: s.variables.height,
            tempo: s.variables.tempo,
            timestamp: s.timestamp,
          ),
        );
      }
    });
  }

  @override
  Future<WorkoutSession?> getSession(String id) async {
    final sessionRow = await (db.select(db.driftWorkoutSessions)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (sessionRow == null) return null;

    final setsRows = await (db.select(db.driftWorkoutSets)..where((t) => t.sessionId.equals(id))).get();

    final sets = setsRows.map((row) => WorkoutSet(
      id: row.id,
      sessionId: row.sessionId,
      exerciseId: row.exerciseId,
      movementPattern: MovementPattern.values[row.movementPattern],
      setNumber: row.setNumber,
      reps: row.reps,
      targetRpe: row.targetRpe,
      reportedRpe: row.reportedRpe,
      variables: MillerVariables(
        load: row.loadVal,
        bodyPosition: row.bodyPosition,
        rom: row.rom,
        height: row.height,
        tempo: row.tempo,
      ),
      timestamp: row.timestamp,
    )).toList();

    return WorkoutSession(
      id: sessionRow.id,
      startTime: sessionRow.startTime,
      endTime: sessionRow.endTime,
      isCompleted: sessionRow.isCompleted,
      sets: sets,
      dayType: sessionRow.dayType != null ? DayType.values[sessionRow.dayType!] : null,
    );
  }

  @override
  Future<List<WorkoutSession>> getSessionsInDateRange(DateTime start, DateTime end) async {
    final rows = await (db.select(db.driftWorkoutSessions)
      ..where((t) => t.startTime.isBetweenValues(start, end))).get();

    final List<WorkoutSession> sessions = [];
    for (final row in rows) {
      final s = await getSession(row.id);
      if (s != null) sessions.add(s);
    }
    return sessions;
  }

  @override
  Future<List<WorkoutSet>> getSetsForMovementPattern(MovementPattern pattern, DateTime since) async {
    final rows = await (db.select(db.driftWorkoutSets)
      ..where((t) => t.movementPattern.equals(pattern.index) & t.timestamp.isBiggerOrEqualValue(since))).get();

    return rows.map((row) => WorkoutSet(
      id: row.id,
      sessionId: row.sessionId,
      exerciseId: row.exerciseId,
      movementPattern: MovementPattern.values[row.movementPattern],
      setNumber: row.setNumber,
      reps: row.reps,
      targetRpe: row.targetRpe,
      reportedRpe: row.reportedRpe,
      variables: MillerVariables(
        load: row.loadVal,
        bodyPosition: row.bodyPosition,
        rom: row.rom,
        height: row.height,
        tempo: row.tempo,
      ),
      timestamp: row.timestamp,
    )).toList();
  }

  @override
  Future<List<WorkoutSet>> getSetsInDateRange(DateTime start, DateTime end) async {
    final rows = await (db.select(db.driftWorkoutSets)
      ..where((t) => t.timestamp.isBetweenValues(start, end))).get();

    return rows.map((row) => WorkoutSet(
      id: row.id,
      sessionId: row.sessionId,
      exerciseId: row.exerciseId,
      movementPattern: MovementPattern.values[row.movementPattern],
      setNumber: row.setNumber,
      reps: row.reps,
      targetRpe: row.targetRpe,
      reportedRpe: row.reportedRpe,
      variables: MillerVariables(
        load: row.loadVal,
        bodyPosition: row.bodyPosition,
        rom: row.rom,
        height: row.height,
        tempo: row.tempo,
      ),
      timestamp: row.timestamp,
    )).toList();
  }
}
