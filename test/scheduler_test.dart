import 'package:test/test.dart';
import 'package:sbee/sbee.dart';

void main() {
  group('PeriodizationScheduler Tests', () {
    test('Next day-type rotates correctly', () {
      final now = DateTime.now();
      
      // Empty history starts with moderate
      expect(PeriodizationScheduler.getNextDayType([]), equals(DayType.moderate));

      final s1 = WorkoutSession(id: '1', startTime: now, isCompleted: true, dayType: DayType.moderate);
      expect(PeriodizationScheduler.getNextDayType([s1]), equals(DayType.veryHeavy));

      final s2 = WorkoutSession(id: '2', startTime: now, isCompleted: true, dayType: DayType.veryHeavy);
      expect(PeriodizationScheduler.getNextDayType([s1, s2]), equals(DayType.power));

      final s3 = WorkoutSession(id: '3', startTime: now, isCompleted: true, dayType: DayType.power);
      expect(PeriodizationScheduler.getNextDayType([s1, s2, s3]), equals(DayType.veryLight));

      final s4 = WorkoutSession(id: '4', startTime: now, isCompleted: true, dayType: DayType.veryLight);
      expect(PeriodizationScheduler.getNextDayType([s1, s2, s3, s4]), equals(DayType.highLactic));

      final s5 = WorkoutSession(id: '5', startTime: now, isCompleted: true, dayType: DayType.highLactic);
      expect(PeriodizationScheduler.getNextDayType([s1, s2, s3, s4, s5]), equals(DayType.moderate));
    });

    test('Deload week is determined active on week 5 (index 4)', () {
      final base = DateTime(2026, 7, 1, 12, 0);
      final s = WorkoutSession(id: '1', startTime: base, isCompleted: true, dayType: DayType.moderate);
      final history = [s];

      // Day 0 to 27 (Weeks 0, 1, 2, 3) -> Deload false
      expect(PeriodizationScheduler.isDeloadActive(completedSessions: history, currentTime: base), isFalse);
      expect(PeriodizationScheduler.isDeloadActive(completedSessions: history, currentTime: base.add(const Duration(days: 10))), isFalse);
      expect(PeriodizationScheduler.isDeloadActive(completedSessions: history, currentTime: base.add(const Duration(days: 27))), isFalse);

      // Day 28 to 34 (Week 4, which is 5th week of training) -> Deload true
      expect(PeriodizationScheduler.isDeloadActive(completedSessions: history, currentTime: base.add(const Duration(days: 28))), isTrue);
      expect(PeriodizationScheduler.isDeloadActive(completedSessions: history, currentTime: base.add(const Duration(days: 34))), isTrue);

      // Day 35 (Week 5, which starts 2nd cycle of training) -> Deload false
      expect(PeriodizationScheduler.isDeloadActive(completedSessions: history, currentTime: base.add(const Duration(days: 35))), isFalse);
    });

    test('Apply deload cuts volume in half and limits target RPE to 6', () {
      final now = DateTime.now();
      final originalSession = WorkoutSession(
        id: 's',
        startTime: now,
        sets: [
          WorkoutSet(
            id: '1',
            sessionId: 's',
            exerciseId: 'ex',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 8,
            variables: const MillerVariables(),
            timestamp: now,
          ),
          WorkoutSet(
            id: '2',
            sessionId: 's',
            exerciseId: 'ex',
            movementPattern: MovementPattern.pushing,
            setNumber: 2,
            reps: 10,
            targetRpe: 9,
            variables: const MillerVariables(),
            timestamp: now,
          ),
          WorkoutSet(
            id: '3',
            sessionId: 's',
            exerciseId: 'ex',
            movementPattern: MovementPattern.pushing,
            setNumber: 3,
            reps: 10,
            targetRpe: 5,
            variables: const MillerVariables(),
            timestamp: now,
          ),
        ],
      );

      // If deload is false, session remains identical
      final sessionActive = PeriodizationScheduler.applyDeload(session: originalSession, isDeload: false);
      expect(sessionActive.sets.length, equals(3));
      expect(sessionActive.sets[0].targetRpe, equals(8));

      // If deload is true:
      // Volume = 3 sets -> ceil(3/2) = 2 sets
      // RPE 8 -> 6, RPE 9 -> 6, RPE 5 -> remains 5
      final sessionDeload = PeriodizationScheduler.applyDeload(session: originalSession, isDeload: true);
      expect(sessionDeload.sets.length, equals(2));
      expect(sessionDeload.sets[0].targetRpe, equals(6));
      expect(sessionDeload.sets[1].targetRpe, equals(6));
    });
  });
}
