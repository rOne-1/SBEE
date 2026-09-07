/// Kenneth Miller's 5-variable progression/regression framework.
///
/// The core engine adjusts exercise biomechanics when external load modifications
/// are limited (common in home-based resistance training with bodyweight/bands).
///
/// HARDCODE: Priority logic must follow this sequence to prevent biomechanical impossibility:
/// 1. Intensity/Load (Highest Priority: Change leverage, angle, or resistance curve)
/// 2. Body Position (Base of support modification)
/// 3. Range of Motion (ROM) (Distance traveled)
/// 4. Height/Elevation (Gravity vector adjustment)
/// 5. Speed/Tempo (Lowest Priority: Time under tension)
class MillerVariables {
  final int load;
  final int bodyPosition;
  final int rom;
  final int height;
  final int tempo; // 1 = Standard 4-2-1 tempo, 2 = Advanced 6s slow-tempo

  static const int minLevel = 1;
  static const int maxLevel = 5;

  const MillerVariables({
    this.load = 1,
    this.bodyPosition = 1,
    this.rom = 1,
    this.height = 1,
    this.tempo = 1,
  })  : assert(load >= minLevel && load <= maxLevel),
        assert(bodyPosition >= minLevel && bodyPosition <= maxLevel),
        assert(rom >= minLevel && rom <= maxLevel),
        assert(height >= minLevel && height <= maxLevel),
        assert(tempo >= minLevel && tempo <= 2);

  /// Performs a progression (increment) based on Miller Variable Priority (MVP) logic:
  /// Load > Body Position > ROM > Height > Tempo.
  ///
  /// Access to advanced tempo (level 2) is controlled by [isAdvancedTempoUnlocked].
  MillerVariables increment({bool isAdvancedTempoUnlocked = false}) {
    // 1. Intensity/Load (Highest Priority)
    if (load < maxLevel) {
      return copyWith(load: load + 1);
    }
    // 2. Body Position
    if (bodyPosition < maxLevel) {
      return copyWith(bodyPosition: bodyPosition + 1);
    }
    // 3. Range of Motion (ROM)
    if (rom < maxLevel) {
      return copyWith(rom: rom + 1);
    }
    // 4. Height/Elevation
    if (height < maxLevel) {
      return copyWith(height: height + 1);
    }
    // 5. Speed/Tempo (Lowest Priority)
    if (tempo < 2 && isAdvancedTempoUnlocked) {
      return copyWith(tempo: tempo + 1);
    }
    // Already fully progressed
    return this;
  }

  /// APP-SPECIFIC DESIGN DECISION: Regression operates in reverse priority (LIFO: Tempo > Height > ROM > Body Position > Load)
  /// to systematically rollback the most recent progression step.
  MillerVariables regress() {
    // 1. Speed/Tempo (Lowest Priority, easiest to regress first)
    if (tempo > minLevel) {
      return copyWith(tempo: tempo - 1);
    }
    // 2. Height/Elevation
    if (height > minLevel) {
      return copyWith(height: height - 1);
    }
    // 3. Range of Motion (ROM)
    if (rom > minLevel) {
      return copyWith(rom: rom - 1);
    }
    // 4. Body Position
    if (bodyPosition > minLevel) {
      return copyWith(bodyPosition: bodyPosition - 1);
    }
    // 5. Intensity/Load (Highest Priority, hardest to regress last)
    if (load > minLevel) {
      return copyWith(load: load - 1);
    }
    // Already fully regressed
    return this;
  }

  MillerVariables copyWith({
    int? load,
    int? bodyPosition,
    int? rom,
    int? height,
    int? tempo,
  }) {
    return MillerVariables(
      load: load ?? this.load,
      bodyPosition: bodyPosition ?? this.bodyPosition,
      rom: rom ?? this.rom,
      height: height ?? this.height,
      tempo: tempo ?? this.tempo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MillerVariables &&
          runtimeType == other.runtimeType &&
          load == other.load &&
          bodyPosition == other.bodyPosition &&
          rom == other.rom &&
          height == other.height &&
          tempo == other.tempo;

  @override
  int get hashCode =>
      load.hashCode ^
      bodyPosition.hashCode ^
      rom.hashCode ^
      height.hashCode ^
      tempo.hashCode;

  @override
  String toString() {
    return 'MillerVariables(load: $load, pos: $bodyPosition, rom: $rom, height: $height, tempo: $tempo)';
  }
}
