import 'package:test/test.dart';
import 'package:sbee/sbee.dart';

void main() {
  group('DetrainingLogic Tests', () {
    test('Inactivity of >= 14 days triggers detraining', () {
      final base = DateTime(2026, 7, 1, 12, 0);

      // Empty sessions -> detraining false
      expect(DetrainingLogic.isDetrainingActive(completedSessions: [], currentTime: base), isFalse);

      final s1 = WorkoutSession(
        id: '1',
        startTime: base,
        endTime: base.add(const Duration(minutes: 45)),
        isCompleted: true,
      );

      // Under 14 days -> false
      expect(DetrainingLogic.isDetrainingActive(completedSessions: [s1], currentTime: base.add(const Duration(days: 10))), isFalse);
      expect(DetrainingLogic.isDetrainingActive(completedSessions: [s1], currentTime: base.add(const Duration(days: 13))), isFalse);

      // 14 days or longer -> true
      expect(DetrainingLogic.isDetrainingActive(completedSessions: [s1], currentTime: base.add(const Duration(days: 14, minutes: 45))), isTrue);
      expect(DetrainingLogic.isDetrainingActive(completedSessions: [s1], currentTime: base.add(const Duration(days: 20))), isTrue);
    });

    test('Locked out day-types under detraining status', () {
      final base = DateTime(2026, 7, 1, 12, 0);
      final s = WorkoutSession(id: '1', startTime: base, endTime: base.add(const Duration(minutes: 30)), isCompleted: true);
      final history = [s];

      final activeTime = base.add(const Duration(days: 5)); // No detraining
      final detrainedTime = base.add(const Duration(days: 20)); // Detraining active

      // When active
      expect(DetrainingLogic.isDayTypeAllowed(dayType: DayType.veryHeavy, completedSessions: history, currentTime: activeTime), isTrue);
      expect(DetrainingLogic.isDayTypeAllowed(dayType: DayType.power, completedSessions: history, currentTime: activeTime), isTrue);
      expect(DetrainingLogic.isDayTypeAllowed(dayType: DayType.moderate, completedSessions: history, currentTime: activeTime), isTrue);

      // When detrained
      expect(DetrainingLogic.isDayTypeAllowed(dayType: DayType.veryHeavy, completedSessions: history, currentTime: detrainedTime), isFalse);
      expect(DetrainingLogic.isDayTypeAllowed(dayType: DayType.power, completedSessions: history, currentTime: detrainedTime), isFalse);
      expect(DetrainingLogic.isDayTypeAllowed(dayType: DayType.moderate, completedSessions: history, currentTime: detrainedTime), isTrue);
    });

    test('Tempo and corrective cues under detraining status', () {
      final base = DateTime(2026, 7, 1, 12, 0);
      final s = WorkoutSession(id: '1', startTime: base, endTime: base.add(const Duration(minutes: 30)), isCompleted: true);
      final history = [s];

      final activeTime = base.add(const Duration(days: 5));
      final detrainedTime = base.add(const Duration(days: 20));

      // Tempo
      expect(DetrainingLogic.getPrescribedTempo(completedSessions: history, currentTime: activeTime, defaultTempo: '6-0-0'), equals('6-0-0'));
      expect(DetrainingLogic.getPrescribedTempo(completedSessions: history, currentTime: detrainedTime, defaultTempo: '6-0-0'), equals('4-2-1'));

      // Cues
      expect(DetrainingLogic.getCorrectiveCues(completedSessions: history, currentTime: activeTime), isEmpty);
      expect(DetrainingLogic.getCorrectiveCues(completedSessions: history, currentTime: detrainedTime), isNotEmpty);
    });

    test('Lockout Interaction Integration: 48h Recovery Lock + Detraining Lockout', () {
      final base = DateTime(2026, 7, 1, 12, 0);
      
      // Let's create a history where:
      // 1. The user completed a workout 15 days ago (causing detraining to be active now).
      // 2. The user did a high-intensity pushing set (RPE 8) 12 hours ago (causing a 48h recovery lock on pushing).
      //
      // We want to verify that BOTH safety checks compose correctly:
      // - Detraining locks Very Heavy / Power days.
      // - 48h Recovery locks the pushing movement pattern.
      // - Neither suppresses the other.

      final oldSession = WorkoutSession(
        id: 'old_1',
        startTime: base.subtract(const Duration(days: 15)),
        endTime: base.subtract(const Duration(days: 15, minutes: 45)),
        isCompleted: true,
      );

      final recentSet = WorkoutSet(
        id: 'recent_set',
        sessionId: 'recent_session',
        exerciseId: 'ex_push',
        movementPattern: MovementPattern.pushing,
        setNumber: 1,
        reps: 5,
        targetRpe: 8,
        reportedRpe: 9, // RPE >= 8 triggers recovery lock
        variables: const MillerVariables(),
        timestamp: base.subtract(const Duration(hours: 12)),
      );

      final recentSession = WorkoutSession(
        id: 'recent_session',
        startTime: base.subtract(const Duration(hours: 12)),
        isCompleted: true,
        sets: [recentSet],
      );

      final history = [oldSession, recentSession];

      // 1. Detraining lockout is active because the last completed session is NOT oldSession,
      // but wait! The most recently completed session is recentSession (which was 12 hours ago).
      // Therefore, the gap is 12 hours. Detraining is NOT active relative to recentSession.
      //
      // To test BOTH active at the same time:
      // Let's assume the user has been inactive for 20 days (detraining active).
      // Then, the user starts a session, does a high-intensity pushing set, and is still in menses or has joint discomfort.
      // Wait, if the user completed a high-intensity workout 12 hours ago, detraining is no longer active (since they trained 12 hours ago).
      // To have BOTH active:
      // What if the user completed a high-intensity pushing set (RPE 9) 15 days ago?
      // - Gap is 15 days -> Detraining IS active (gap >= 14).
      // - Recovery gate is NOT active because 15 days > 48 hours.
      //
      // Wait, is it possible to have both active?
      // Yes! If the user performs a high-intensity set and then immediately gets locked out?
      // Or if a user has a high-intensity workout on Day 1. Then on Day 15 (14 days of inactivity later),
      // the recovery lockout is no longer active because it's past 48 hours.
      // Wait, how can both be active at the same time?
      // What if the "current time" is Day 15, and the user did a high-intensity session 12 hours ago? Then the gap is 12 hours, so detraining is NOT active.
      // Ah! What if the user logged a high-intensity set, but it was in an UNCOMPLETED session?
      // The detraining logic looks at COMPLETED sessions (`session.isCompleted`).
      // If the user started a session 12 hours ago, completed a high-intensity set, but left the session UNCOMPLETED.
      // Then:
      // - Last completed session was 15 days ago -> Detraining IS active (since last completed session was >= 14 days ago).
      // - Recent set was 12 hours ago -> Recovery lockout IS active for Pushing!
      // This is a perfect real-world scenario where both are active together!

      final uncompletedSession = WorkoutSession(
        id: 'recent_uncompleted',
        startTime: base.subtract(const Duration(hours: 12)),
        isCompleted: false, // NOT completed
        sets: [recentSet],
      );

      final integrationHistory = [oldSession, uncompletedSession];

      // Check Detraining state
      final isDetraining = DetrainingLogic.isDetrainingActive(
        completedSessions: integrationHistory,
        currentTime: base,
      );
      expect(isDetraining, isTrue, reason: 'Detraining should be active because the last COMPLETED session was 15 days ago.');

      // Check Recovery Lock state
      final isPushLocked = SafetyRules.isMovementLocked(
        pastSets: [recentSet],
        pattern: MovementPattern.pushing,
        currentTime: base,
      );
      expect(isPushLocked, isTrue, reason: 'Pushing should be locked because a set with RPE 9 was done 12 hours ago.');

      // Verify composition: both lockouts are active, and neither suppresses the other
      final isVeryHeavyAllowed = DetrainingLogic.isDayTypeAllowed(
        dayType: DayType.veryHeavy,
        completedSessions: integrationHistory,
        currentTime: base,
      );
      expect(isVeryHeavyAllowed, isFalse, reason: 'Very Heavy is locked by detraining.');

      final isPullingLocked = SafetyRules.isMovementLocked(
        pastSets: [recentSet],
        pattern: MovementPattern.pulling,
        currentTime: base,
      );
      expect(isPullingLocked, isFalse, reason: 'Pulling is not locked.');
    });
  });
}
