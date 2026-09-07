import 'package:glados/glados.dart';
import 'package:sbee/sbee.dart';
import 'package:sbee/src/engine/safety_rules.dart';

void main() {
  Glados(any.list(any.list(any.int)), ExploreConfig(numRuns: 1000)).test(
    '48-Hour Recovery Gate Lockout Invariant with Pattern Isolation',
    (input) {
      final currentTime = DateTime(2026, 7, 7, 12, 0);

      final sets = <WorkoutSet>[];
      for (final list in input) {
        if (list.length < 3) continue;
        final rpe = list[0].abs() % 11; // RPE 0 to 10
        final hoursAgo = list[1].abs() % 100; // 0 to 99 hours ago
        final pattern = MovementPattern
            .values[list[2].abs() % MovementPattern.values.length];

        sets.add(
          WorkoutSet(
            id: 'set_id',
            sessionId: 'session_id',
            exerciseId: 'ex_id',
            movementPattern: pattern,
            setNumber: 1,
            reps: 10,
            targetRpe: 7,
            reportedRpe: rpe,
            variables: const MillerVariables(),
            timestamp: currentTime.subtract(Duration(hours: hoursAgo)),
          ),
        );
      }

      // Check the lockout state for all possible movement patterns.
      // This explicitly verifies pattern-isolation.
      for (final pattern in MovementPattern.values) {
        final isLocked = SafetyRules.isMovementLocked(
          pastSets: sets,
          pattern: pattern,
          currentTime: currentTime,
        );

        // The pattern must be locked if and only if there is a high-intensity set (RPE >= 8)
        // of that SPECIFIC pattern within the last 48 hours.
        final expectedLocked = sets.any((s) {
          final hours = currentTime.difference(s.timestamp).inHours;
          return s.movementPattern == pattern &&
              (s.reportedRpe ?? 0) >= 8 &&
              hours >= 0 &&
              hours < 48;
        });

        expect(isLocked, equals(expectedLocked),
            reason: 'Isolation check failed for pattern: $pattern');
      }
    },
  );
}
