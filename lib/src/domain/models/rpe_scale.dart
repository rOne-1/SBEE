/// Information regarding a specific Rate of Perceived Exertion (RPE) level.
class RpeInfo {
  final int rpe;
  final String rirEquivalent;
  final String physiologicalState;
  final String engineResponse;

  const RpeInfo({
    required this.rpe,
    required this.rirEquivalent,
    required this.physiologicalState,
    required this.engineResponse,
  });

  /// True if this RPE requires recovery gating (cannot exceed 1 session/48h).
  bool get requiresGating => rpe >= 9;

  /// True if this RPE triggers Miller Variable Increment.
  bool get triggersIncrement => rpe <= 5;

  /// Retrieves the RpeInfo for a given RPE value (0-10).
  factory RpeInfo.fromRpe(int rpe) {
    if (rpe < 0 || rpe > 10) {
      throw ArgumentError('RPE must be between 0 and 10, inclusive.');
    }
    if (rpe >= 9) {
      return RpeInfo(
        rpe: rpe,
        rirEquivalent: '0 - 1',
        physiologicalState: 'Maximum Intensity: Neural drive exhaustion; total ATP-PC depletion; high motor unit recruitment.',
        engineResponse: 'Gating required; cannot exceed 1 session/48h.',
      );
    } else if (rpe == 8) {
      return RpeInfo(
        rpe: rpe,
        rirEquivalent: '2',
        physiologicalState: 'High Intensity: Lactic acid accumulation; significant metabolic byproduct concentration.',
        engineResponse: 'Target zone for Hypertrophy/Strength phases.',
      );
    } else if (rpe >= 6) {
      return RpeInfo(
        rpe: rpe,
        rirEquivalent: '3 - 4',
        physiologicalState: 'Moderate Intensity: Sustainable glycolytic flux; technical proficiency remains high.',
        engineResponse: 'Default baseline for Stabilization/Endurance phases.',
      );
    } else {
      return RpeInfo(
        rpe: rpe,
        rirEquivalent: '5+',
        physiologicalState: 'Low Intensity/Recovery: Minimal neuromuscular strain; oxidative system dominant.',
        engineResponse: 'Trigger Miller Variable Increment.',
      );
    }
  }
}
