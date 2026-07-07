import 'package:statemachine/statemachine.dart';

/// Enum representing the phases of a workout session.
enum SessionState {
  warmUp,
  activeSet,
  rest,
  coolDown,
  completed,
}

/// A Finite State Machine (FSM) defining valid workout transitions,
/// preventing invalid states and flow violations.
class SessionStateMachine {
  final Machine<SessionState> _machine;
  late final State<SessionState> _stateWarmUp;
  late final State<SessionState> _stateActiveSet;
  late final State<SessionState> _stateRest;
  late final State<SessionState> _stateCoolDown;
  late final State<SessionState> _stateCompleted;

  // Callback triggered when the state transitions.
  final void Function(SessionState state)? onStateChanged;

  SessionStateMachine({this.onStateChanged}) : _machine = Machine<SessionState>() {
    _stateWarmUp = _machine.newStartState(SessionState.warmUp);
    _stateActiveSet = _machine.newState(SessionState.activeSet);
    _stateRest = _machine.newState(SessionState.rest);
    _stateCoolDown = _machine.newState(SessionState.coolDown);
    _stateCompleted = _machine.newStopState(SessionState.completed);

    // Setup state entry listeners.
    for (final state in _machine.states) {
      state.onEntry(() {
        onStateChanged?.call(state.identifier);
      });
    }

    // Set initial state.
    _machine.current = _stateWarmUp;
  }

  /// Gets the current state of the session.
  SessionState get currentState => _machine.current!.identifier;

  /// Transition from [SessionState.warmUp] to [SessionState.activeSet].
  void startWorkout() {
    _verifyState(SessionState.warmUp, 'startWorkout');
    _stateActiveSet.enter();
  }

  /// Transition from [SessionState.activeSet] to [SessionState.rest].
  void completeSet() {
    _verifyState(SessionState.activeSet, 'completeSet');
    _stateRest.enter();
  }

  /// Transition from [SessionState.rest] to [SessionState.activeSet].
  void startNextSet() {
    _verifyState(SessionState.rest, 'startNextSet');
    _stateActiveSet.enter();
  }

  /// Transition from [SessionState.activeSet] or [SessionState.rest] to [SessionState.coolDown].
  void completeWorkout() {
    if (currentState != SessionState.activeSet && currentState != SessionState.rest) {
      throw StateError(
        'Cannot call completeWorkout when in $currentState state. Must be in activeSet or rest.',
      );
    }
    _stateCoolDown.enter();
  }

  /// Transition from [SessionState.coolDown] to [SessionState.completed].
  void finishSession() {
    _verifyState(SessionState.coolDown, 'finishSession');
    _stateCompleted.enter();
  }

  void _verifyState(SessionState expected, String action) {
    if (currentState != expected) {
      throw StateError('Cannot call $action when in $currentState state.');
    }
  }
}
