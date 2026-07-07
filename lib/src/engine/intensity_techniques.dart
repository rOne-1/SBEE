import '../domain/models/workout_session.dart';

/// Structure for Myo-Reps prescription.
class MyoRepsStructure {
  final String label;
  final int activationReps;
  final int miniSetsCount;
  final int repsPerMiniSet;
  final String restInterval;

  const MyoRepsStructure({
    required this.label,
    required this.activationReps,
    required this.miniSetsCount,
    required this.repsPerMiniSet,
    required this.restInterval,
  });
}

/// Structure for Cluster Sets prescription.
class ClusterSetsStructure {
  final String label;
  final int targetReps;
  final int repsPerMiniSet;
  final int intraSetRestSeconds;

  const ClusterSetsStructure({
    required this.label,
    required this.targetReps,
    required this.repsPerMiniSet,
    required this.intraSetRestSeconds,
  });
}

/// Structure for Rest-Pause prescription.
class RestPauseStructure {
  final String label;
  final int targetReps;
  final int postFailureRestSeconds;

  const RestPauseStructure({
    required this.label,
    required this.targetReps,
    required this.postFailureRestSeconds,
  });
}

/// Implements Named High-Intensity Techniques and their validation constraints.
class IntensityTechniques {
  
  /// KINESIOLOGIC ANALOGY: Extrapolated from loaded-training research
  /// Cluster Sets divide target reps into mini-sets with 10s intra-set rest.
  static ClusterSetsStructure generateClusterSet({
    required int targetReps,
    int repsPerMiniSet = 2,
  }) {
    return ClusterSetsStructure(
      label: 'Kinesiologic Analogy: Extrapolated from loaded-training research',
      targetReps: targetReps,
      repsPerMiniSet: repsPerMiniSet,
      intraSetRestSeconds: 10,
    );
  }

  /// KINESIOLOGIC ANALOGY: Extrapolated from loaded-training research
  /// Rest-Pause implements a post-failure rest (15s) to accumulate 2-3 additional reps.
  static RestPauseStructure generateRestPause({
    required int targetReps,
  }) {
    return RestPauseStructure(
      label: 'Kinesiologic Analogy: Extrapolated from loaded-training research',
      targetReps: targetReps,
      postFailureRestSeconds: 15,
    );
  }

  /// KINESIOLOGIC ANALOGY: Extrapolated from loaded-training research
  /// Myo-Reps prescription: 1 activation set + 3-5 mini-sets of 3 reps.
  static MyoRepsStructure generateMyoReps({
    required int activationReps,
    int miniSetsCount = 4,
  }) {
    if (miniSetsCount < 3 || miniSetsCount > 5) {
      throw ArgumentError('Myo-Reps must specify 3 to 5 mini-sets.');
    }
    return MyoRepsStructure(
      label: 'Kinesiologic Analogy: Extrapolated from loaded-training research',
      activationReps: activationReps,
      miniSetsCount: miniSetsCount,
      repsPerMiniSet: 3,
      restInterval: '15s',
    );
  }

  /// SYNTHESIZED DESIGN DECISION: EMOM Work-Duration Constraints
  /// Prevents users from selecting rep counts exceeding level-specific work-duration thresholds:
  /// - Beginner: Max work duration 20s
  /// - Intermediate: Max work duration 30s
  /// - Advanced: Max work duration 40s
  static bool validateEmomRepCount({
    required int reps,
    required int secondsPerRep,
    required String userLevel,
  }) {
    final workDuration = reps * secondsPerRep;
    final int maxAllowedDuration;

    switch (userLevel.toLowerCase()) {
      case 'beginner':
        maxAllowedDuration = 20;
        break;
      case 'intermediate':
        maxAllowedDuration = 30;
        break;
      case 'advanced':
        maxAllowedDuration = 40;
        break;
      default:
        throw ArgumentError('Invalid user level: $userLevel');
    }

    return workDuration <= maxAllowedDuration;
  }

  /// Tabata hybrid progression gate logic.
  /// 
  /// Tabata is 20s work / 10s rest for 8 rounds.
  /// Calendar-day progression is strictly forbidden.
  /// Progression requires:
  /// (a) a minimum number of completed sessions at the current phase [requiredSessionCount]
  /// (b) average reported RPE of those sessions is at or below the target RPE + 1 threshold
  static bool canProgressTabata({
    required List<WorkoutSession> completedTabataSessionsInPhase,
    required int requiredSessionCount,
    required double targetRpe,
  }) {
    if (completedTabataSessionsInPhase.length < requiredSessionCount) {
      return false;
    }

    var rpeSum = 0.0;
    var validRpeCount = 0;
    for (final session in completedTabataSessionsInPhase) {
      for (final set in session.sets) {
        if (set.reportedRpe != null) {
          rpeSum += set.reportedRpe!;
          validRpeCount++;
        }
      }
    }

    if (validRpeCount == 0) return false;

    final avgRpe = rpeSum / validRpeCount;
    return avgRpe <= (targetRpe + 1.0);
  }
}
