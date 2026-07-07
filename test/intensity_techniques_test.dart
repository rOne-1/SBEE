import 'package:test/test.dart';
import 'package:sbee/sbee.dart';

void main() {
  group('IntensityTechniques Tests', () {
    test('Myo-Reps generation enforces 3-5 mini-sets boundaries', () {
      final struct = IntensityTechniques.generateMyoReps(activationReps: 12, miniSetsCount: 4);
      expect(struct.activationReps, equals(12));
      expect(struct.miniSetsCount, equals(4));
      expect(struct.repsPerMiniSet, equals(3));

      // Fails if miniSetsCount < 3 or > 5
      expect(() => IntensityTechniques.generateMyoReps(activationReps: 12, miniSetsCount: 2), throwsArgumentError);
      expect(() => IntensityTechniques.generateMyoReps(activationReps: 12, miniSetsCount: 6), throwsArgumentError);
    });

    test('EMOM constraints rep selection limits', () {
      // Beginner: max 20s
      // reps: 5, secondsPerRep: 4 => 20s (Allowed)
      // reps: 6, secondsPerRep: 4 => 24s (Exceeded)
      expect(IntensityTechniques.validateEmomRepCount(reps: 5, secondsPerRep: 4, userLevel: 'beginner'), isTrue);
      expect(IntensityTechniques.validateEmomRepCount(reps: 6, secondsPerRep: 4, userLevel: 'beginner'), isFalse);

      // Intermediate: max 30s
      // reps: 7, secondsPerRep: 4 => 28s (Allowed)
      // reps: 8, secondsPerRep: 4 => 32s (Exceeded)
      expect(IntensityTechniques.validateEmomRepCount(reps: 7, secondsPerRep: 4, userLevel: 'intermediate'), isTrue);
      expect(IntensityTechniques.validateEmomRepCount(reps: 8, secondsPerRep: 4, userLevel: 'intermediate'), isFalse);

      // Advanced: max 40s
      // reps: 10, secondsPerRep: 4 => 40s (Allowed)
      // reps: 11, secondsPerRep: 4 => 44s (Exceeded)
      expect(IntensityTechniques.validateEmomRepCount(reps: 10, secondsPerRep: 4, userLevel: 'advanced'), isTrue);
      expect(IntensityTechniques.validateEmomRepCount(reps: 11, secondsPerRep: 4, userLevel: 'advanced'), isFalse);
    });

    test('Tabata hybrid progression gate checks sessions and RPE', () {
      final now = DateTime.now();

      // Session with RPE 6 (below target 7 + 1 = 8)
      final sLowRpe = WorkoutSession(
        id: 's_low',
        startTime: now,
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 'set_1',
            sessionId: 's_low',
            exerciseId: 'ex',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 7,
            reportedRpe: 6,
            variables: const MillerVariables(),
            timestamp: now,
          ),
        ],
      );

      // Session with RPE 9 (above target 7 + 1 = 8)
      final sHighRpe = WorkoutSession(
        id: 's_high',
        startTime: now,
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 'set_2',
            sessionId: 's_high',
            exerciseId: 'ex',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 7,
            reportedRpe: 9,
            variables: const MillerVariables(),
            timestamp: now,
          ),
        ],
      );

      // Too few sessions (0 sessions, need 3)
      expect(IntensityTechniques.canProgressTabata(completedTabataSessionsInPhase: [], requiredSessionCount: 3, targetRpe: 7.0), isFalse);

      // Too few sessions (2 sessions, need 3)
      expect(IntensityTechniques.canProgressTabata(completedTabataSessionsInPhase: [sLowRpe, sLowRpe], requiredSessionCount: 3, targetRpe: 7.0), isFalse);

      // Enough sessions, low RPE (3 sessions, average RPE 6.0 <= 8.0) -> Progresses
      expect(IntensityTechniques.canProgressTabata(completedTabataSessionsInPhase: [sLowRpe, sLowRpe, sLowRpe], requiredSessionCount: 3, targetRpe: 7.0), isTrue);

      // Enough sessions, high RPE (3 sessions, average RPE 9.0 > 8.0) -> Locked
      expect(IntensityTechniques.canProgressTabata(completedTabataSessionsInPhase: [sHighRpe, sHighRpe, sHighRpe], requiredSessionCount: 3, targetRpe: 7.0), isFalse);
    });
  });
}
