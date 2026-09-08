import 'package:test/test.dart';
import 'package:sbee/sbee.dart';

void main() {
  group('FemalePhysiologyWrapper Tests', () {
    test('Endocrine Explanation surfaces growth hormone correctly', () {
      final explanation = FemalePhysiologyWrapper.getEndocrineExplanation();
      expect(explanation, contains('Growth Hormone'));
      expect(explanation, contains('GH'));
      expect(explanation, contains('testosterone-centric'));
    });

    test('Early Follicular RPE and Rest offsets are applied correctly', () {
      const untrainedFollicular = FemaleProfile(
        userStatus: 'Untrained_Female',
        cycleDay: 2, // early follicular (days 1-3)
        hasKneeDiscomfort: false,
        age: 30,
        hasJointPain: false,
      );

      const trainedFollicular = FemaleProfile(
        userStatus: 'Trained_Female',
        cycleDay: 2,
        hasKneeDiscomfort: false,
        age: 30,
        hasJointPain: false,
      );

      const untrainedLuteal = FemaleProfile(
        userStatus: 'Untrained_Female',
        cycleDay: 15,
        hasKneeDiscomfort: false,
        age: 30,
        hasJointPain: false,
      );

      // Target RPE offset test
      expect(
          FemalePhysiologyWrapper.adjustTargetRpe(
              originalTargetRpe: 8, profile: untrainedFollicular),
          equals(7));
      expect(
          FemalePhysiologyWrapper.adjustTargetRpe(
              originalTargetRpe: 8, profile: trainedFollicular),
          equals(8));
      expect(
          FemalePhysiologyWrapper.adjustTargetRpe(
              originalTargetRpe: 8, profile: untrainedLuteal),
          equals(8));

      // Rest density offset test
      const baseRest = Duration(minutes: 1);

      // Untrained follicular gets +30s rest density addition
      final res1 = FemalePhysiologyWrapper.adjustRestInterval(
          baseRest: baseRest, profile: untrainedFollicular);
      expect(res1, equals(const Duration(minutes: 1, seconds: 30)));

      // Trained follicular does not get it
      final res2 = FemalePhysiologyWrapper.adjustRestInterval(
          baseRest: baseRest, profile: trainedFollicular);
      expect(res2, equals(baseRest));
    });

    test('Submaximal pacing VO2 max range', () {
      final target = FemalePhysiologyWrapper.getConditioningTargetVo2Max();
      expect(target['min'], equals(0.55));
      expect(target['max'], equals(0.65));
    });

    test('McGill Big 3 and Knee valgus safety rail cues are triggered', () {
      const noDiscomfort = FemaleProfile(
        userStatus: 'Trained_Female',
        cycleDay: 10,
        hasKneeDiscomfort: false,
        age: 28,
        hasJointPain: false,
      );

      const discomfort = FemaleProfile(
        userStatus: 'Trained_Female',
        cycleDay: 10,
        hasKneeDiscomfort: true,
        age: 28,
        hasJointPain: false,
      );

      final cuesNo = FemalePhysiologyWrapper.getCorrectiveCues(
          exerciseName: 'Squat', profile: noDiscomfort);
      expect(cuesNo.any((c) => c.contains('McGill Big 3')), isFalse);

      final cuesDis = FemalePhysiologyWrapper.getCorrectiveCues(
          exerciseName: 'Squat', profile: discomfort);
      expect(cuesDis.any((c) => c.contains('McGill Big 3')), isTrue);
      expect(cuesDis.any((c) => c.contains('12-15 repetitions')), isTrue);
    });

    test('Spinal flexion core pacing cue override', () {
      const profile = FemaleProfile(
        userStatus: 'Trained_Female',
        cycleDay: 10,
        hasKneeDiscomfort: false,
        age: 28,
        hasJointPain: false,
      );

      final cuesSquat = FemalePhysiologyWrapper.getCorrectiveCues(
          exerciseName: 'Squat', profile: profile);
      expect(cuesSquat.any((c) => c.contains('crunches')), isFalse);

      final cuesCrunch = FemalePhysiologyWrapper.getCorrectiveCues(
          exerciseName: 'Crunch Exercise', profile: profile);
      expect(
          cuesCrunch.any((c) => c.contains('neutral stabilization')), isTrue);
    });

    test('Age 45+ logic overrides target metric and gates plyometrics', () {
      const young = FemaleProfile(
        userStatus: 'Trained_Female',
        cycleDay: 10,
        hasKneeDiscomfort: false,
        age: 30,
        hasJointPain: true,
      );

      const seniorNoPain = FemaleProfile(
        userStatus: 'Trained_Female',
        cycleDay: 10,
        hasKneeDiscomfort: false,
        age: 50,
        hasJointPain: false,
      );

      const seniorWithPain = FemaleProfile(
        userStatus: 'Trained_Female',
        cycleDay: 10,
        hasKneeDiscomfort: false,
        age: 50,
        hasJointPain: true,
      );

      // Intensity metric check
      expect(
          FemalePhysiologyWrapper.adjustIntensityMetric(
              originalMetric: '1RM %', profile: young),
          equals('1RM %'));
      expect(
          FemalePhysiologyWrapper.adjustIntensityMetric(
              originalMetric: '1RM %', profile: seniorNoPain),
          contains('2-3 RIR'));

      // Sets minimum floor check
      expect(
          FemalePhysiologyWrapper.adjustMinSets(
              originalMinSets: 2, profile: young),
          equals(2));
      expect(
          FemalePhysiologyWrapper.adjustMinSets(
              originalMinSets: 2, profile: seniorNoPain),
          equals(3));
      expect(
          FemalePhysiologyWrapper.adjustMinSets(
              originalMinSets: 4, profile: seniorNoPain),
          equals(4));

      // Plyometrics gating check
      expect(
          FemalePhysiologyWrapper.isPlyometricsAllowed(profile: young), isTrue);
      expect(
          FemalePhysiologyWrapper.isPlyometricsAllowed(profile: seniorNoPain),
          isTrue);
      expect(
          FemalePhysiologyWrapper.isPlyometricsAllowed(profile: seniorWithPain),
          isFalse);
    });

    test('adjustRestInterval only ever applies its own offset on top of the passed-in baseline', () {
      // The conditioning-vs-strength baseline this used to compute internally
      // moved to DayTypePrescription.restInterval (see day_type_prescription_test.dart)
      // so it's the default for every account, not just FemaleProfile ones.
      // This wrapper's only remaining job is the early-follicular +30s offset.
      const trainedProfile = FemaleProfile(
        userStatus: 'Trained_Female',
        cycleDay: 10,
        hasKneeDiscomfort: false,
        age: 30,
        hasJointPain: false,
      );
      const untrainedFollicular = FemaleProfile(
        userStatus: 'Untrained_Female',
        cycleDay: 2,
        hasKneeDiscomfort: false,
        age: 30,
        hasJointPain: false,
      );

      const someBaseline = Duration(seconds: 45);

      expect(
          FemalePhysiologyWrapper.adjustRestInterval(
              baseRest: someBaseline, profile: trainedProfile),
          equals(someBaseline),
          reason: 'No offset applies outside the untrained early-follicular window');

      expect(
          FemalePhysiologyWrapper.adjustRestInterval(
              baseRest: someBaseline, profile: untrainedFollicular),
          equals(const Duration(seconds: 75)),
          reason: 'Untrained + cycle day 1-3 adds a flat +30s on top of whatever baseline was passed in');
    });
  });
}
