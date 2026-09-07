import 'package:test/test.dart';
import 'package:sbee/sbee.dart';

void main() {
  group('DayTypePrescription Tests', () {
    test('every DayType returns a prescription with minReps <= reps <= maxReps and a positive setsCount', () {
      for (final dayType in DayType.values) {
        final prescription = DayTypePrescription.forDayType(dayType);
        expect(prescription.minReps, lessThanOrEqualTo(prescription.reps),
            reason: '$dayType: minReps should not exceed reps');
        expect(prescription.reps, lessThanOrEqualTo(prescription.maxReps),
            reason: '$dayType: reps should not exceed maxReps');
        expect(prescription.targetRpe, inInclusiveRange(0, 10), reason: '$dayType: targetRpe out of RPE bounds');
        expect(prescription.setsCount, greaterThan(0), reason: '$dayType: setsCount must be positive');
      }
    });

    test('setsCount varies by DayType instead of a flat default', () {
      final counts = {
        for (final dayType in DayType.values) dayType: DayTypePrescription.forDayType(dayType).setsCount,
      };
      // Not every DayType should collapse to the same set count -- that would
      // mean this field isn't actually doing anything.
      expect(counts.values.toSet().length, greaterThan(1),
          reason: 'setsCount should differ across DayTypes, not be a single flat value');
      expect(counts[DayType.veryHeavy], equals(5));
      expect(counts[DayType.moderate], equals(4));
      expect(counts[DayType.power], equals(5));
      expect(counts[DayType.veryLight], equals(3));
      expect(counts[DayType.highLactic], equals(6));
    });

    test('veryHeavy prescribes the documented 1-5 RM neuromuscular zone', () {
      final p = DayTypePrescription.forDayType(DayType.veryHeavy);
      expect(p.minReps, equals(1));
      expect(p.maxReps, equals(5));
    });

    test('moderate prescribes the documented 8-12 RM hypertrophy zone', () {
      final p = DayTypePrescription.forDayType(DayType.moderate);
      expect(p.minReps, equals(8));
      expect(p.maxReps, equals(12));
    });

    test('veryLight prescribes the documented 15-20+ RM endurance zone', () {
      final p = DayTypePrescription.forDayType(DayType.veryLight);
      expect(p.minReps, equals(15));
      expect(p.maxReps, equals(20));
    });

    test('power prescribes low reps at a submaximal (not-to-failure) RPE', () {
      final p = DayTypePrescription.forDayType(DayType.power);
      expect(p.maxReps, lessThanOrEqualTo(5));
      expect(p.targetRpe, lessThan(8), reason: 'RFD/power work should stay submaximal to preserve movement speed');
    });
  });
}
