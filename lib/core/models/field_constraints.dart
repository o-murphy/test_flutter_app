import 'dart:math';
import 'package:eballistica/core/solver/unit.dart';

/// Constraints for a physical quantity role — used by [UnitValueField]
/// and for display formatting in tables, charts, and widgets.
///
/// All values are in [rawUnit] (the storage/base unit).
/// The UI converts to the selected display unit before showing.
class FieldConstraints {
  const FieldConstraints({
    required this.rawUnit,
    required this.minRaw,
    required this.maxRaw,
    required this.stepRaw,
    required this.accuracy,
  });

  final Unit rawUnit;
  final double minRaw;
  final double maxRaw;
  final double stepRaw;

  /// Decimal places when displayed in [rawUnit]. Used as fallback.
  final int accuracy;

  /// Returns the number of decimal places appropriate for [displayUnit].
  ///
  /// Mirrors the logic used internally by [UnitValueField]: converts
  /// [stepRaw] to [displayUnit] and infers the required precision from it.
  int accuracyFor(Unit displayUnit) {
    if (rawUnit == displayUnit) return accuracy;
    if (rawUnit == Unit.second) return accuracy; // sentinel (dimensionless)
    final lo = (rawUnit(minRaw) as Dimension).in_(displayUnit);
    final hi = (rawUnit(minRaw + stepRaw) as Dimension).in_(displayUnit);
    final step = (hi - lo).abs();
    if (step <= 0) return accuracy;
    final d = (-log(step) / ln10).ceil();
    return d < 0 ? 0 : d;
  }
}

// ─── Role definitions ─────────────────────────────────────────────────────────

abstract final class FC {
  // Environmental
  static const temperature = FieldConstraints(
    rawUnit: Unit.celsius,
    minRaw: -100.0,
    maxRaw: 100.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const altitude = FieldConstraints(
    rawUnit: Unit.meter,
    minRaw: -500.0,
    maxRaw: 15000.0,
    stepRaw: 10.0,
    accuracy: 0,
  );

  static const pressure = FieldConstraints(
    rawUnit: Unit.hPa,
    minRaw: 300.0,
    maxRaw: 1500.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  /// Humidity in percent (0–100). No unit conversion.
  static const humidity = FieldConstraints(
    rawUnit: Unit.second, // sentinel — no conversion used for humidity
    minRaw: 0.0,
    maxRaw: 100.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  // Ballistic inputs
  static const windVelocity = FieldConstraints(
    rawUnit: Unit.mps,
    minRaw: 0.0,
    maxRaw: 30.0,
    stepRaw: 0.5,
    accuracy: 1,
  );

  static const lookAngle = FieldConstraints(
    rawUnit: Unit.degree,
    minRaw: -90.0,
    maxRaw: 90.0,
    stepRaw: 1.0,
    accuracy: 1,
  );

  static const windDirection = FieldConstraints(
    rawUnit: Unit.degree,
    minRaw: 0.0,
    maxRaw: 360.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const targetDistance = FieldConstraints(
    rawUnit: Unit.meter,
    minRaw: 10.0,
    maxRaw: 3000.0,
    stepRaw: 10.0,
    accuracy: 0,
  );

  // Weapon / optics
  static const sightHeight = FieldConstraints(
    rawUnit: Unit.millimeter,
    minRaw: 0.0,
    maxRaw: 200.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const twistRate = FieldConstraints(
    rawUnit: Unit.inch,
    minRaw: 1.0,
    maxRaw: 30.0,
    stepRaw: 0.25,
    accuracy: 2,
  );

  static const zeroDistance = FieldConstraints(
    rawUnit: Unit.meter,
    minRaw: 10.0,
    maxRaw: 1000.0,
    stepRaw: 10.0,
    accuracy: 0,
  );

  // Projectile
  static const muzzleVelocity = FieldConstraints(
    rawUnit: Unit.mps,
    minRaw: 100.0,
    maxRaw: 1800.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const bulletWeight = FieldConstraints(
    rawUnit: Unit.grain,
    minRaw: 1.0,
    maxRaw: 800.0,
    stepRaw: 0.1,
    accuracy: 1,
  );

  static const bulletLength = FieldConstraints(
    rawUnit: Unit.millimeter,
    minRaw: 1.0,
    maxRaw: 100.0,
    stepRaw: 0.1,
    accuracy: 1,
  );

  static const bulletDiameter = FieldConstraints(
    rawUnit: Unit.millimeter,
    minRaw: 1.0,
    maxRaw: 30.0,
    stepRaw: 0.1,
    accuracy: 2,
  );

  static const ballisticCoefficient = FieldConstraints(
    rawUnit: Unit.second, // sentinel — dimensionless, no conversion
    minRaw: 0.001,
    maxRaw: 2.000,
    stepRaw: 0.001,
    accuracy: 3,
  );

  // Display-only — trajectory output

  /// Bullet height / windage offset (linear). Raw stored in feet.
  static const drop = FieldConstraints(
    rawUnit: Unit.foot,
    minRaw: -500.0,
    maxRaw: 500.0,
    stepRaw: 0.1,
    accuracy: 1, // suitable for cm (default unit)
  );

  static const windage = drop;

  /// Scope adjustment angle. Raw stored in radians.
  static const adjustment = FieldConstraints(
    rawUnit: Unit.mil,
    minRaw: -6.28,
    maxRaw: 6.28,
    stepRaw: 0.001,
    accuracy: 2, // suitable for MIL / MOA / MRAD (default unit)
  );

  static const velocity = FieldConstraints(
    rawUnit: Unit.mps,
    minRaw: 0.0,
    maxRaw: 3000.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const energy = FieldConstraints(
    rawUnit: Unit.footPound,
    minRaw: 0.0,
    maxRaw: 20000.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const tableRange = FieldConstraints(
    rawUnit: Unit.meter,
    minRaw: 0.0,
    maxRaw: 5000.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const distanceStep = FieldConstraints(
    rawUnit: Unit.meter,
    minRaw: 1.0,
    maxRaw: 1000.0,
    stepRaw: 1.0,
    accuracy: 0,
  );
}
