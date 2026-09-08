import 'package:drift/drift.dart';
import '../../engine/miller_variables.dart';
import '../../domain/models/day_type.dart';
import '../../domain/models/movement_pattern.dart';
import '../../domain/models/workout_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../drift/database.dart';

/// Drift implementation of the [SessionRepository] with input validation and exception wrapping.
class DriftSessionRepository implements SessionRepository {
  final SbeeDatabase db;

  DriftSessionRepository(this.db);

  @override
  Future<void> saveSession(WorkoutSession session) async {
    // 1. Input Validation
    if (session.id.isEmpty) {
      throw SessionRepositoryException('Session ID cannot be empty');
    }
    final seenSetIds = <String>{};
    for (final s in session.sets) {
      if (s.id.isEmpty) {
        throw SessionRepositoryException('Set ID cannot be empty');
      }
      if (s.sessionId.isEmpty) {
        throw SessionRepositoryException('Set sessionId cannot be empty');
      }
      if (s.reps < 0) {
        throw SessionRepositoryException(
            'Set reps cannot be negative: ${s.reps}');
      }
      if (s.targetRpe < 0) {
        throw SessionRepositoryException(
            'Set targetRpe cannot be negative: ${s.targetRpe}');
      }
      if (seenSetIds.contains(s.id)) {
        throw SessionRepositoryException(
            'Duplicate Set ID in session: ${s.id}');
      }
      seenSetIds.add(s.id);
    }

    try {
      await db.transaction(() async {
        await db.into(db.driftWorkoutSessions).insertOnConflictUpdate(
              DriftWorkoutSession(
                id: session.id,
                startTime: session.startTime,
                endTime: session.endTime,
                isCompleted: session.isCompleted,
                dayType: session.dayType?.index,
                posturalWarning: session.posturalWarning,
                posturalWarningReason: session.posturalWarningReason.name,
                recoveryReason: session.recoveryReason.name,
              ),
            );

        // Clean up previous sets for this session to avoid duplicates
        await (db.delete(db.driftWorkoutSets)
              ..where((t) => t.sessionId.equals(session.id)))
            .go();

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
                  minReps: s.minReps,
                  maxReps: s.maxReps,
                  targetRpe: s.targetRpe,
                  reportedRpe: s.reportedRpe,
                  loadVal: s.variables.load,
                  bodyPosition: s.variables.bodyPosition,
                  rom: s.variables.rom,
                  height: s.variables.height,
                  tempo: s.variables.tempo,
                  timestamp: s.timestamp,
                  restDurationSeconds: s.restDuration?.inSeconds,
                  cuesJson: s.cues.isEmpty ? null : s.cues.join('||'),
                ),
              );
        }
      });
    } catch (e) {
      throw SessionRepositoryException(
          'Failed to save session ${session.id}', e);
    }
  }

  @override
  Future<WorkoutSession?> getSession(String id) async {
    try {
      final sessionRow = await (db.select(db.driftWorkoutSessions)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (sessionRow == null) return null;

      final setsRows = await (db.select(db.driftWorkoutSets)
            ..where((t) => t.sessionId.equals(id)))
          .get();

      final sets = setsRows
          .map((row) => WorkoutSet(
                id: row.id,
                sessionId: row.sessionId,
                exerciseId: row.exerciseId,
                movementPattern: MovementPattern.values[row.movementPattern],
                setNumber: row.setNumber,
                reps: row.reps,
                minReps: row.minReps,
                maxReps: row.maxReps,
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
                restDuration: row.restDurationSeconds != null
                    ? Duration(seconds: row.restDurationSeconds!)
                    : null,
                cues: row.cuesJson != null && row.cuesJson!.isNotEmpty
                    ? row.cuesJson!.split('||')
                    : const [],
              ))
          .toList();

      PosturalWarningReason parsedReason = PosturalWarningReason.none;
      if (sessionRow.posturalWarningReason != null) {
        for (final r in PosturalWarningReason.values) {
          if (r.name == sessionRow.posturalWarningReason) {
            parsedReason = r;
            break;
          }
        }
      }

      RecoveryReason parsedRecoveryReason = RecoveryReason.none;
      if (sessionRow.recoveryReason != null) {
        for (final r in RecoveryReason.values) {
          if (r.name == sessionRow.recoveryReason) {
            parsedRecoveryReason = r;
            break;
          }
        }
      }

      return WorkoutSession(
        id: sessionRow.id,
        startTime: sessionRow.startTime,
        endTime: sessionRow.endTime,
        isCompleted: sessionRow.isCompleted,
        sets: sets,
        dayType: sessionRow.dayType != null
            ? DayType.values[sessionRow.dayType!]
            : null,
        posturalWarning: sessionRow.posturalWarning,
        posturalWarningReason: parsedReason,
        recoveryReason: parsedRecoveryReason,
      );
    } catch (e) {
      throw SessionRepositoryException('Failed to read session $id', e);
    }
  }

  @override
  Future<List<WorkoutSession>> getSessionsInDateRange(
      DateTime start, DateTime end) async {
    try {
      final rows = await (db.select(db.driftWorkoutSessions)
            ..where((t) => t.startTime.isBetweenValues(start, end)))
          .get();

      final List<WorkoutSession> sessions = [];
      for (final row in rows) {
        final s = await getSession(row.id);
        if (s != null) sessions.add(s);
      }
      return sessions;
    } catch (e) {
      throw SessionRepositoryException(
          'Failed to query sessions in date range', e);
    }
  }

  @override
  Future<List<WorkoutSet>> getSetsForMovementPattern(
      MovementPattern pattern, DateTime since) async {
    try {
      final rows = await (db.select(db.driftWorkoutSets)
            ..where((t) =>
                t.movementPattern.equals(pattern.index) &
                t.timestamp.isBiggerOrEqualValue(since)))
          .get();

      return rows
          .map((row) => WorkoutSet(
                id: row.id,
                sessionId: row.sessionId,
                exerciseId: row.exerciseId,
                movementPattern: MovementPattern.values[row.movementPattern],
                setNumber: row.setNumber,
                reps: row.reps,
                minReps: row.minReps,
                maxReps: row.maxReps,
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
                restDuration: row.restDurationSeconds != null
                    ? Duration(seconds: row.restDurationSeconds!)
                    : null,
                cues: row.cuesJson != null && row.cuesJson!.isNotEmpty
                    ? row.cuesJson!.split('||')
                    : const [],
              ))
          .toList();
    } catch (e) {
      throw SessionRepositoryException(
          'Failed to query sets for movement pattern', e);
    }
  }

  @override
  Future<List<WorkoutSet>> getSetsInDateRange(
      DateTime start, DateTime end) async {
    try {
      final rows = await (db.select(db.driftWorkoutSets)
            ..where((t) => t.timestamp.isBetweenValues(start, end)))
          .get();

      return rows
          .map((row) => WorkoutSet(
                id: row.id,
                sessionId: row.sessionId,
                exerciseId: row.exerciseId,
                movementPattern: MovementPattern.values[row.movementPattern],
                setNumber: row.setNumber,
                reps: row.reps,
                minReps: row.minReps,
                maxReps: row.maxReps,
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
                restDuration: row.restDurationSeconds != null
                    ? Duration(seconds: row.restDurationSeconds!)
                    : null,
                cues: row.cuesJson != null && row.cuesJson!.isNotEmpty
                    ? row.cuesJson!.split('||')
                    : const [],
              ))
          .toList();
    } catch (e) {
      throw SessionRepositoryException('Failed to query sets in date range', e);
    }
  }

  @override
  Future<WorkoutSession?> getMostRecentCompletedSession(
      {bool requireDayType = false}) async {
    final DriftWorkoutSession? row;
    try {
      final query = db.select(db.driftWorkoutSessions)
        ..where((t) => requireDayType
            ? (t.isCompleted.equals(true) & t.dayType.isNotNull())
            : t.isCompleted.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
        ..limit(1);
      row = await query.getSingleOrNull();
    } catch (e) {
      throw SessionRepositoryException(
          'Failed to query most recent completed session', e);
    }
    if (row == null) return null;
    return getSession(row.id);
  }

  @override
  Future<DateTime?> getEarliestCompletedSessionStart() async {
    final DateTime? earliest;
    try {
      final minStart = db.driftWorkoutSessions.startTime.min();
      final query = db.selectOnly(db.driftWorkoutSessions)
        ..addColumns([minStart])
        ..where(db.driftWorkoutSessions.isCompleted.equals(true));
      final row = await query.getSingle();
      earliest = row.read(minStart);
    } catch (e) {
      throw SessionRepositoryException(
          'Failed to query earliest completed session start', e);
    }
    return earliest;
  }

  @override
  Future<int> getCompletedSessionCount() async {
    final int? count;
    try {
      final countExpr = db.driftWorkoutSessions.id.count();
      final query = db.selectOnly(db.driftWorkoutSessions)
        ..addColumns([countExpr])
        ..where(db.driftWorkoutSessions.isCompleted.equals(true));
      final row = await query.getSingle();
      count = row.read(countExpr);
    } catch (e) {
      throw SessionRepositoryException(
          'Failed to query completed session count', e);
    }
    return count ?? 0;
  }

  @override
  Future<int> getReportedSetCountForExercise(String exerciseId) async {
    final int? count;
    try {
      final countExpr = db.driftWorkoutSets.id.count();
      final query = db.selectOnly(db.driftWorkoutSets)
        ..addColumns([countExpr])
        ..where(db.driftWorkoutSets.exerciseId.equals(exerciseId) &
            db.driftWorkoutSets.reportedRpe.isNotNull());
      final row = await query.getSingle();
      count = row.read(countExpr);
    } catch (e) {
      throw SessionRepositoryException(
          'Failed to query completed set count for exercise $exerciseId', e);
    }
    return count ?? 0;
  }

  @override
  Future<WorkoutSession?> getActiveIncompleteSession() async {
    final DriftWorkoutSession? row;
    try {
      final query = db.select(db.driftWorkoutSessions)
        ..where((t) => t.isCompleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
        ..limit(1);
      row = await query.getSingleOrNull();
    } catch (e) {
      throw SessionRepositoryException(
          'Failed to query active incomplete session', e);
    }
    if (row == null) return null;
    return getSession(row.id);
  }

  @override
  Future<void> deleteSession(String id) async {
    try {
      await db.transaction(() async {
        await (db.delete(db.driftWorkoutSets)
              ..where((t) => t.sessionId.equals(id)))
            .go();
        await (db.delete(db.driftWorkoutSessions)
              ..where((t) => t.id.equals(id)))
            .go();
      });
    } catch (e) {
      throw SessionRepositoryException('Failed to delete session $id', e);
    }
  }
}
