import '../domain/models/movement_pattern.dart';
import '../domain/models/workout_session.dart';
import 'autoregulation.dart';
import 'miller_variables.dart';
import 'safety_rules.dart';

/// User profile input data for the female physiology pre-processing layer.
class FemaleProfile {
  final String userStatus; // E.g., "Untrained_Female", "Trained_Female"
  final int cycleDay;      // 1-indexed day of menstrual cycle (e.g., 1–28)
  final bool hasKneeDiscomfort;
  final int age;
  final bool hasJointPain;

  const FemaleProfile({
    required this.userStatus,
    required this.cycleDay,
    required this.hasKneeDiscomfort,
    required this.age,
    required this.hasJointPain,
  });
}

/// Female Physiology Wrapper implemented using the Decorator / Pre-processing pattern.
/// 
/// Adjusts training variables *before* they are processed by the core engine,
/// ensuring the core safety-tested engine logic path remains the single source of truth.
class FemalePhysiologyWrapper {
  
  /// UNVERIFIED-BIBLIOGRAPHY SOURCE
  /// Surfaces growth hormone (GH) cues rather than testosterone.
  static String getEndocrineExplanation() {
    return 'Endocrine focus: Growth Hormone (GH) pulsatility is the primary driver of tissue adaptation and lipolysis in female physiology, contrasting with testosterone-centric model cues.';
  }

  /// UNVERIFIED-BIBLIOGRAPHY SOURCE
  /// Early Follicular Adjustment: Applies an RPE offset (-1) if cycle is in days 1–3 of menses
  /// and the user has an untrained status.
  static int adjustTargetRpe({
    required int originalTargetRpe,
    required FemaleProfile profile,
  }) {
    if (profile.userStatus == 'Untrained_Female' && profile.cycleDay >= 1 && profile.cycleDay <= 3) {
      final adjusted = originalTargetRpe - 1;
      return adjusted < 0 ? 0 : adjusted;
    }
    return originalTargetRpe;
  }

  /// UNVERIFIED-BIBLIOGRAPHY SOURCE
  /// Recovery Pacing & Early Follicular Rest Density:
  /// - Sets 30-45s rest on conditioning but 2-3 mins on heavy strength.
  /// - Applies rest density increase (+30s) if Untrained_Female is in cycle days 1–3.
  /// Note: This is new logic, unit-test-covered (not decorated from a property-tested core method).
  static Duration adjustRestInterval({
    required Duration originalRest,
    required String trainingFocus, // "conditioning" or "strength"
    required FemaleProfile profile,
  }) {
    Duration baseRest = originalRest;

    // Apply recovery pacing focus
    if (trainingFocus.toLowerCase() == 'conditioning') {
      baseRest = const Duration(seconds: 45); // default conditioning rest within 30-45s range
    } else if (trainingFocus.toLowerCase() == 'strength') {
      baseRest = const Duration(minutes: 2, seconds: 30); // default heavy strength rest within 2-3m range
    }

    // Apply early follicular adjustment (+30s rest density)
    if (profile.userStatus == 'Untrained_Female' && profile.cycleDay >= 1 && profile.cycleDay <= 3) {
      baseRest = baseRest + const Duration(seconds: 30);
    }

    return baseRest;
  }

  /// UNVERIFIED-BIBLIOGRAPHY SOURCE
  /// Submaximal Pacing: Sets steady-state conditioning target to 55% - 65% of VO2 max.
  static Map<String, double> getConditioningTargetVo2Max() {
    return {
      'min': 0.55,
      'max': 0.65,
    };
  }

  /// UNVERIFIED-BIBLIOGRAPHY SOURCE
  /// Core & Pelvic Floor Pacing / Knee Valgus Safety Rail:
  /// - Replaces spinal flexion with neutral stabilization.
  /// - Adds stance cues and outputs "exhale with effort" cues.
  /// - Triggers McGill Big 3 & Side Plank with Hip Abduction + 12-15 repetition floor if knee discomfort is present.
  static List<String> getCorrectiveCues({
    required String exerciseName,
    required FemaleProfile profile,
  }) {
    final cues = <String>[];

    // Pelvic floor & Stance cues
    cues.add('Breathing: Exhale with effort during the concentric phase.');
    cues.add('Stance: Ensure stable foot stance and align hips and knees.');

    // Spine stabilization override
    if (exerciseName.toLowerCase().contains('crunch') || exerciseName.toLowerCase().contains('flexion')) {
      cues.add('Core Pacing: Replace spinal flexion (crunches) with neutral stabilization.');
    }

    // Knee Valgus Safety Rail
    if (profile.hasKneeDiscomfort) {
      cues.add('Knee Safety: Trigger McGill Big 3 and Side Plank with Hip Abduction for hip-knee alignment control.');
      cues.add('Knee Safety Rep Floor: Set a floor of 12-15 repetitions for lower-body sets to focus on alignment.');
    }

    return cues;
  }

  /// UNVERIFIED-BIBLIOGRAPHY SOURCE
  /// Age 45+ Logic: Replaces 1RM intensity logic with RIR target (2-3 RIR).
  /// Note: This is new logic, unit-test-covered (not decorated from a property-tested core method).
  static String adjustIntensityMetric({
    required String originalMetric,
    required FemaleProfile profile,
  }) {
    if (profile.age >= 45) {
      return '2-3 RIR (Reps in Reserve) target';
    }
    return originalMetric;
  }

  /// UNVERIFIED-BIBLIOGRAPHY SOURCE
  /// Age 45+ Logic: Mandates a floor of 3 sets per pattern.
  /// Note: This is new logic, unit-test-covered (not decorated from a property-tested core method).
  static int adjustMinSets({
    required int originalMinSets,
    required FemaleProfile profile,
  }) {
    if (profile.age >= 45) {
      return originalMinSets < 3 ? 3 : originalMinSets;
    }
    return originalMinSets;
  }

  /// UNVERIFIED-BIBLIOGRAPHY SOURCE
  /// Age 45+ Logic: Gates plyometrics based on joint pain status.
  /// Note: This is new logic, unit-test-covered (not decorated from a property-tested core method).
  static bool isPlyometricsAllowed({
    required FemaleProfile profile,
  }) {
    if (profile.age >= 45 && profile.hasJointPain) {
      return false; // Gated
    }
    return true; // Allowed
  }

  /// Decorator for AutoregulationEngine.adjustVariables.
  /// Adjusts targetRpe first before delegating.
  static MillerVariables adjustVariables({
    required MillerVariables currentVariables,
    required int reportedRpe,
    required int targetRpe,
    required FemaleProfile profile,
    bool isAdvancedTempoUnlocked = false,
  }) {
    final adjustedTarget = adjustTargetRpe(originalTargetRpe: targetRpe, profile: profile);
    return AutoregulationEngine.adjustVariables(
      currentVariables: currentVariables,
      reportedRpe: reportedRpe,
      targetRpe: adjustedTarget,
      isAdvancedTempoUnlocked: isAdvancedTempoUnlocked,
    );
  }

  /// Decorator for SafetyRules.isMovementLocked.
  static bool isMovementLocked({
    required List<WorkoutSet> pastSets,
    required MovementPattern pattern,
    required DateTime currentTime,
  }) {
    return SafetyRules.isMovementLocked(
      pastSets: pastSets,
      pattern: pattern,
      currentTime: currentTime,
    );
  }

  /// Decorator for SafetyRules.validatePushPullRatio.
  static bool validatePushPullRatio({
    required List<WorkoutSet> pastSets,
    required DateTime currentTime,
  }) {
    return SafetyRules.validatePushPullRatio(
      pastSets: pastSets,
      currentTime: currentTime,
    );
  }
}
