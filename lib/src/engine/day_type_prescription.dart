import '../domain/models/day_type.dart';

/// The reps/RPE prescription for a given [DayType], expressing the science-based
/// rep-max (RM) zone each day-type trains within.
///
/// APP-SPECIFIC DESIGN DECISION: Locked DayType Prescription Table
/// Each `DayType` names a training focus and an RM zone in its own doc comments
/// (e.g. `veryHeavy`: 1-5 RM), but prior to this table nothing in the generator
/// actually varied reps or targetRpe by DayType — every set used a hardcoded
/// `reps: 10, targetRpe: 8`. This table is the single source of truth translating
/// each DayType's documented RM zone into a concrete prescription. [highLactic] is
/// intentionally excluded from the RM-zone model: it is generated via
/// [IntensityTechniques]'s EMOM structure instead (see `sbee_engine.dart`), so its
/// entry here is a neutral placeholder never actually surfaced to a generated set.
class DayTypePrescription {
  /// A single representative rep count for this DayType, used for display and
  /// as the pre-fill default before a set is logged.
  final int reps;

  /// Prescribed rep-range floor (the RM zone's low end).
  final int minReps;

  /// Prescribed rep-range ceiling (the RM zone's high end).
  final int maxReps;

  /// Target Rate of Perceived Exertion for sets generated under this DayType.
  final int targetRpe;

  const DayTypePrescription({
    required this.reps,
    required this.minReps,
    required this.maxReps,
    required this.targetRpe,
  });

  /// Returns the locked prescription for [dayType].
  static DayTypePrescription forDayType(DayType dayType) {
    switch (dayType) {
      case DayType.veryHeavy:
        // Neuromuscular Recruitment focus (1-5 RM). Near-maximal effort by design:
        // an RPE 9 target here is expected to trigger the 48h recovery lock on the
        // trained movement pattern once reported, which is the intended safety behavior.
        return const DayTypePrescription(reps: 4, minReps: 1, maxReps: 5, targetRpe: 9);
      case DayType.moderate:
        // Hypertrophy / Metabolic Stress focus (8-12 RM).
        return const DayTypePrescription(reps: 10, minReps: 8, maxReps: 12, targetRpe: 8);
      case DayType.power:
        // Rate of Force Development focus: low reps, but submaximal effort —
        // explosive/RFD work is intentionally not trained to failure, since
        // grinding reps degrades bar/movement speed, the actual training target.
        return const DayTypePrescription(reps: 4, minReps: 3, maxReps: 5, targetRpe: 7);
      case DayType.veryLight:
        // Local Muscular Endurance focus (15-20+ RM). maxReps is capped at 20 as a
        // concrete stand-in for the open-ended "20+" zone described in DayType's docs.
        return const DayTypePrescription(reps: 18, minReps: 15, maxReps: 20, targetRpe: 7);
      case DayType.highLactic:
        // Metabolic Buffering (Circuits/EMOM): not an RM-zone prescription at all.
        // The generator overrides reps/minReps/maxReps/targetRpe for this DayType
        // using IntensityTechniques.generateEmomRepCount instead; this entry exists
        // only so every DayType has a total switch case and is never surfaced.
        return const DayTypePrescription(reps: 10, minReps: 10, maxReps: 10, targetRpe: 7);
    }
  }
}
