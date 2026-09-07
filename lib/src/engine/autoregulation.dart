import 'miller_variables.dart';

/// Enum representing the output decision of the autoregulation logic gate.
enum AutoregulationAction {
  increment,
  regress,
  maintain,
}

/// The Autoregulation Engine evaluates subjective user feedback (reported RPE)
/// against a target RPE to dynamically adjust intensity parameters.
class AutoregulationEngine {
  /// Evaluates the user reported RPE against the target RPE and determines the action.
  ///
  /// Logic:
  /// - IF User_Reported_RPE < (Target_RPE - 1): Trigger Miller Variable Increment.
  /// - IF User_Reported_RPE > (Target_RPE + 1): Trigger Miller Variable Regression.
  /// - Otherwise: Maintain current parameters.
  static AutoregulationAction evaluate({
    required int reportedRpe,
    required int targetRpe,
  }) {
    if (reportedRpe < 0 ||
        reportedRpe > 10 ||
        targetRpe < 0 ||
        targetRpe > 10) {
      throw ArgumentError('RPE must be in the range [0, 10].');
    }

    if (reportedRpe < (targetRpe - 1)) {
      return AutoregulationAction.increment;
    } else if (reportedRpe > (targetRpe + 1)) {
      return AutoregulationAction.regress;
    } else {
      return AutoregulationAction.maintain;
    }
  }

  /// Evaluates and applies the autoregulation adjustment directly to [currentVariables].
  ///
  /// Takes into account whether the advanced 6s tempo is unlocked via [isAdvancedTempoUnlocked].
  static MillerVariables adjustVariables({
    required MillerVariables currentVariables,
    required int reportedRpe,
    required int targetRpe,
    bool isAdvancedTempoUnlocked = false,
  }) {
    final action = evaluate(reportedRpe: reportedRpe, targetRpe: targetRpe);
    switch (action) {
      case AutoregulationAction.increment:
        return currentVariables.increment(
            isAdvancedTempoUnlocked: isAdvancedTempoUnlocked);
      case AutoregulationAction.regress:
        return currentVariables.regress();
      case AutoregulationAction.maintain:
        return currentVariables;
    }
  }
}
