import 'package:glados/glados.dart';
import 'package:sbee/sbee.dart';

void main() {
  Glados(any.list(any.list(any.int)), ExploreConfig(numRuns: 1000)).test(
    '2:1 Pull-to-Push Set-Volume Ratio Invariant',
    (input) {
      final currentTime = DateTime(2026, 7, 7, 12, 0);

      final sets = <WorkoutSet>[];
      for (final pair in input) {
        if (pair.length < 2) continue;
        final pattern = MovementPattern.values[pair[0].abs() % MovementPattern.values.length];
        
        // Generate random age from 0 to 719 hours (30 days ago)
        final hoursAgo = pair[1].abs() % 720;
        final timestamp = currentTime.subtract(Duration(hours: hoursAgo));

        sets.add(
          WorkoutSet(
            id: 'set_id',
            sessionId: 'session_id',
            exerciseId: 'ex_id',
            movementPattern: pattern,
            setNumber: 1,
            reps: 10,
            targetRpe: 7,
            reportedRpe: 7,
            variables: const MillerVariables(),
            timestamp: timestamp,
          ),
        );
      }

      final isValid = SafetyRules.validatePushPullRatio(
        pastSets: sets,
        currentTime: currentTime,
      );

      // Verify the logic matches the 14-day sliding window filtering.
      final windowStart = currentTime.subtract(const Duration(days: 14));
      final setsInWindow = sets.where((s) {
        return s.timestamp.isAfter(windowStart) &&
            !s.timestamp.isBefore(windowStart) &&
            !s.timestamp.isAfter(currentTime);
      }).toList();

      final pushCount = setsInWindow.where((s) => s.movementPattern == MovementPattern.pushing).length;
      final pullCount = setsInWindow.where((s) => s.movementPattern == MovementPattern.pulling).length;

      if (pushCount == 0) {
        expect(isValid, isTrue);
      } else if (pullCount >= 2 * pushCount) {
        expect(isValid, isTrue);
      } else {
        expect(isValid, isFalse);
      }
    },
  );
}
