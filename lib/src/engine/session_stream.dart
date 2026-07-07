import 'package:rxdart/subjects.dart';
import '../domain/models/workout_session.dart';
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
  String toString() => 'SessionProgressState(state: $state, setIndex: $currentSetIndex, sessionExist: ${session != null})';
}

/// Manages the active session state pipeline, exposing it reactively via RxDart.
class SessionStreamManager {
  final _stateSubject = BehaviorSubject<SessionProgressState>.seeded(
    const SessionProgressState(),
  );

  SessionStateMachine? _fsm;

  /// Exposes the reactive stream of the active session's progress.
  Stream<SessionProgressState> get progressStream => _stateSubject.stream;

  /// Retrieves the current snapshot of the active session progress state.
  SessionProgressState get currentState => _stateSubject.value;

  /// Starts a new workout session, transitioning the FSM to [SessionState.warmUp].
  void initializeSession(WorkoutSession session) {
    if (_stateSubject.value.session != null && !_stateSubject.value.session!.isCompleted) {
      throw StateError('A session is already active. Complete the current session first.');
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
      throw StateError('Session manager has not been initialized with a session.');
    }
  }

  /// Disposes of the active session stream resources.
  void dispose() {
    _stateSubject.close();
  }
}
