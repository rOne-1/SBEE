import 'package:glados/glados.dart';
import 'package:sbee/sbee.dart';
import 'package:sbee/src/engine/detraining.dart';

void main() {
  Glados(any.list(any.int), ExploreConfig(numRuns: 1000)).test(
    '14-Day Detraining Lockout Invariant',
    (input) {
      final currentTime = DateTime(2026, 7, 7, 12, 0);

      final completedSessions = <WorkoutSession>[];
      for (var i = 0; i < input.length; i++) {
        // Generate a random positive age in hours from 0 to 1000
        final hoursAgo = input[i].abs() % 1000;
        final startTime = currentTime.subtract(Duration(hours: hoursAgo));
        final endTime = startTime.add(const Duration(minutes: 45));

        completedSessions.add(
          WorkoutSession(
            id: 'session_$i',
            startTime: startTime,
            endTime: endTime,
            isCompleted: true,
            dayType: DayType.moderate,
          ),
        );
      }

      // Check if detraining is active
      final isDetraining = DetrainingLogic.isDetrainingActive(
        completedSessions: completedSessions,
        currentTime: currentTime,
      );

      // Manual check for gap:
      // Find the minimum gap in days
      var minGapInDays = 999999;
      for (final session in completedSessions) {
        final lastActiveTime = session.endTime ?? session.startTime;
        final gap = currentTime.difference(lastActiveTime).inDays;
        if (gap < minGapInDays) {
          minGapInDays = gap;
        }
      }

      final expectedDetraining = completedSessions.isNotEmpty && minGapInDays >= 14;
      expect(isDetraining, equals(expectedDetraining));

      // Test locks
      final isHeavyAllowed = DetrainingLogic.isDayTypeAllowed(
        dayType: DayType.veryHeavy,
        completedSessions: completedSessions,
        currentTime: currentTime,
      );

      final isPowerAllowed = DetrainingLogic.isDayTypeAllowed(
        dayType: DayType.power,
        completedSessions: completedSessions,
        currentTime: currentTime,
      );

      final isModerateAllowed = DetrainingLogic.isDayTypeAllowed(
        dayType: DayType.moderate,
        completedSessions: completedSessions,
        currentTime: currentTime,
      );

      if (isDetraining) {
        expect(isHeavyAllowed, isFalse, reason: 'Very Heavy must be locked when detraining is active');
        expect(isPowerAllowed, isFalse, reason: 'Power must be locked when detraining is active');
        expect(isModerateAllowed, isTrue, reason: 'Moderate must remain allowed under detraining status');
      } else {
        expect(isHeavyAllowed, isTrue, reason: 'Very Heavy must be allowed when detraining is inactive');
        expect(isPowerAllowed, isTrue, reason: 'Power must be allowed when detraining is inactive');
        expect(isModerateAllowed, isTrue);
      }
    },
  );
}
