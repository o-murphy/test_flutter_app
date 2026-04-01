// Canonical units used for JSON persistence.
// One constant per serialized field — changing any entry is a breaking storage format change.

import 'package:eballistica/core/solver/unit.dart';

abstract final class StorageUnits {
  // ── Weapon ────────────────────────────────────────────────────────────────
  static const weaponSightHeight = Unit.millimeter;
  static const weaponTwist = Unit.inch;
  static const weaponZeroElevation = Unit.radian;

  // ── Sight ─────────────────────────────────────────────────────────────────
  static const sightSightHeight = Unit.millimeter;
  static const sightZeroElevation = Unit.radian;

  // ── Cartridge ─────────────────────────────────────────────────────────────
  static const cartridgeMv = Unit.mps;
  static const cartridgePowderTemp = Unit.celsius;
  static const cartridgePowderSensitivity = Unit.fraction;

  // ── Projectile / DragModel ────────────────────────────────────────────────
  static const projectileWeight = Unit.grain;
  static const projectileDiameter = Unit.inch;
  static const projectileLength = Unit.inch;

  // ── BCPoint ───────────────────────────────────────────────────────────────
  static const bcPointVelocity = Unit.mps;

  // ── ShotProfile ───────────────────────────────────────────────────────────
  static const profileLookAngle = Unit.radian;
  static const profileZeroDistance = Unit.meter;
  static const profileTargetDistance = Unit.meter;

  // ── Atmo (conditions / zeroConditions) ────────────────────────────────────
  static const atmoAltitude = Unit.meter;
  static const atmoPressure = Unit.hPa;
  static const atmoTemperature = Unit.celsius;
  static const atmoPowderTemp = Unit.celsius;

  // ── Wind ──────────────────────────────────────────────────────────────────
  static const windVelocity = Unit.mps;
  static const windDirectionFrom = Unit.radian;
  static const windUntilDistance = Unit.meter;
}
