import 'package:rxdart/subjects.dart';
import '../domain/models/workout_session.dart';
import '../domain/repositories/session_repository.dart';
import 'session_state_machine.dart';

/// The detailed progression state of the active workout session.
class SessionProgressState {
  final WorkoutSession? session;
  final SessionState state;
  final int currentSetIndex;

  const SessionProgressState({
    this.session,
    this.state = SessionState.warmUp,
    this.currentSetIndex = 0,
  });

  bool get hasActiveSession => session != null;

  SessionProgressState copyWith({
    WorkoutSession? session,
    SessionState? state,
    int? currentSetIndex,
  }) {
    return SessionProgressState(
      session: session ?? this.session,
      state: state ?? this.state,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
    );
  }

  @override
  String toString() =>
      'SessionProgressState(state: $state, setIndex: $currentSetIndex, sessionExist: ${session != null})';
}

/// Manages the active session state pipeline, exposing it reactively via RxDart.
///
/// APP-SPECIFIC DESIGN DECISION: Incremental Mid-Workout Persistence
/// Previously, nothing persisted an active session until the host app explicitly
/// called `SessionRepository.saveSession()` at the very end of the workout (after
/// `finalizeSession()`). If the app crashed, was killed, or lost focus mid-workout,
/// all progress on the in-progress session -- including sets already logged -- was
/// lost with no recovery path. When constructed with a [sessionRepository], this
/// manager now persists the session after every state-changing action
/// (`initializeSession`, `logCurrentSet`), so `sessionRepository.getActiveIncompleteSession()`
/// can find it again after a restart, and [resumeSession] can reconstruct a manager
/// picking up from the correct set. This persistence is fire-and-forget by design:
/// a transient write failure must not crash the active workout FSM, since the UX cost
/// of that would exceed the cost of occasionally missing one incremental checkpoint.
/// The final, authoritative save at `finalizeSession()` time remains the host app's
/// explicit, awaited responsibility (via `SessionRepository.saveSession()`), unchanged.
class SessionStreamManager {
  final _stateSubject = BehaviorSubject<SessionProgressState>.seeded(
    const SessionProgressState(),
  );

  final SessionRepository? _sessionRepository;

  SessionStateMachine? _fsm;

  SessionStreamManager({SessionRepository? sessionRepository})
      : _sessionRepository = sessionRepository;

  /// Exposes the reactive stream of the active session's progress.
  Stream<SessionProgressState> get progressStream => _stateSubject.stream;

  /// Retrieves the current snapshot of the active session progress state.
  SessionProgressState get currentState => _stateSubject.value;

  void _persistInBackground(WorkoutSession session) {
    // Fire-and-forget: a persistence hiccup must not crash the active FSM.
    // ignore: discarded_futures
    _sessionRepository?.saveSession(session).catchError((_) {});
  }

  /// Starts a new workout session, transitioning the FSM to [SessionState.warmUp].
  void initializeSession(WorkoutSession session) {
    if (_stateSubject.value.session != null &&
        !_stateSubject.value.session!.isCompleted) {
      throw StateError(
          'A session is already active. Complete the current session first.');
    }

    _fsm = SessionStateMachine(
      onStateChanged: (newState) {
        _stateSubject.add(
          _stateSubject.value.copyWith(state: newState),
        );
      },
    );

    _stateSubject.add(
      SessionProgressState(
        session: session,
        state: SessionState.warmUp,
        currentSetIndex: 0,
      ),
    );
    _persistInBackground(session);
  }

  /// Reconstructs this manager from a previously-incomplete [incompleteSession]
  /// (as returned by `SessionRepository.getActiveIncompleteSession()`), restoring
  /// the FSM and current-set index to the correct point: resuming at the next
  /// unlogged set (or [SessionState.coolDown] if every set was already logged).
  ///
  /// Unlike [initializeSession], this replays the FSM's own guarded transitions
  /// directly against the raw state machine (not the reported reps/RPE of the
  /// already-logged sets, which must not be re-written or re-timestamped) purely
  /// to reach the correct internal state; no new set data is touched.
  void resumeSession(WorkoutSession incompleteSession) {
    if (_stateSubject.value.session != null &&
        !_stateSubject.value.session!.isCompleted) {
      throw StateError(
          'A session is already active. Complete the current session first.');
    }

    final totalSets = incompleteSession.sets.length;
    final completedCount =
        incompleteSession.sets.where((s) => s.reportedRpe != null).length;

    _fsm = SessionStateMachine(
      onStateChanged: (newState) {
        _stateSubject.add(_stateSubject.value.copyWith(state: newState));
      },
    );

    if (totalSets > 0) {
      _fsm!.startWorkout();
      for (var i = 0; i < completedCount; i++) {
        if (i == totalSets - 1) {
          _fsm!.completeWorkout();
        } else {
          _fsm!.completeSet();
          _fsm!.startNextSet();
        }
      }
    }

    _stateSubject.add(
      SessionProgressState(
        session: incompleteSession,
        state: _fsm!.currentState,
        currentSetIndex: completedCount < totalSets
            ? completedCount
            : (totalSets == 0 ? 0 : totalSets - 1),
      ),
    );
  }

  /// Transitions the state from Warm-up to Active Set.
  void startWorkout() {
    _ensureInitialized();
    _fsm!.startWorkout();
  }

  /// Logs the reported RPE for the current set and transitions to Rest (or Cool-down if last set).
  ///
  /// Updates the active session state in the stream.
  void logCurrentSet({required int reps, required int reportedRpe}) {
    _ensureInitialized();
    final progress = _stateSubject.value;
    final session = progress.session;
    if (session == null) throw StateError('No active session to log sets.');

    final currentIdx = progress.currentSetIndex;
    if (currentIdx >= session.sets.length) {
      throw RangeError('Set index $currentIdx exceeds session set count.');
    }

    // Update the set at the current index with the reported RPE.
    final updatedSets = List<WorkoutSet>.from(session.sets);
    final targetSet = updatedSets[currentIdx];
    updatedSets[currentIdx] = targetSet.copyWith(
      reportedRpe: reportedRpe,
      reps: reps,
      timestamp: DateTime.now(),
    );

    final updatedSession = session.copyWith(sets: updatedSets);

    final isLastSet = currentIdx == session.sets.length - 1;

    if (isLastSet) {
      _fsm!.completeWorkout();
      _stateSubject.add(
        progress.copyWith(
          session: updatedSession,
          state: SessionState.coolDown,
        ),
      );
    } else {
      _fsm!.completeSet();
      _stateSubject.add(
        progress.copyWith(
          session: updatedSession,
          state: SessionState.rest,
        ),
      );
    }
    _persistInBackground(updatedSession);
  }

  /// Transitions the state from Rest back to Active Set for the next set.
  void startNextSet() {
    _ensureInitialized();
    final progress = _stateSubject.value;
    if (progress.state != SessionState.rest) {
      throw StateError('Cannot start next set when not in Rest state.');
    }

    _fsm!.startNextSet();
    _stateSubject.add(
      progress.copyWith(
        currentSetIndex: progress.currentSetIndex + 1,
        state: SessionState.activeSet,
      ),
    );
  }

  /// Finalizes the active session, transitioning to [SessionState.completed].
  void finalizeSession() {
    _ensureInitialized();
    final progress = _stateSubject.value;
    final session = progress.session;
    if (session == null) throw StateError('No active session to finalize.');

    _fsm!.finishSession();

    final completedSession = session.copyWith(
      isCompleted: true,
      endTime: DateTime.now(),
    );

    _stateSubject.add(
      progress.copyWith(
        session: completedSession,
        state: SessionState.completed,
      ),
    );
  }

  void _ensureInitialized() {
    if (_fsm == null) {
      throw StateError(
          'Session manager has not been initialized with a session.');
    }
  }

  /// Disposes of the active session stream resources.
  void dispose() {
    _stateSubject.close();
  }
}
