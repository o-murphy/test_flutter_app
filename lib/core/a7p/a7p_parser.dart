import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/projectile.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/sight.dart';
import '../proto/profedit.pb.dart';
import 'package:eballistica/core/solver/conditions.dart';
import 'package:eballistica/core/solver/drag_model.dart';
import 'package:eballistica/core/solver/drag_tables.dart';
import 'package:eballistica/core/solver/munition.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'a7p_validator.dart';

/// Converts a validated [Payload] into a [ShotProfile].
///
/// Call [A7pValidator.validate] before this if you want explicit error
/// reporting; [fromPayload] will throw [A7pValidationException] on its own
/// by default (pass [validate] = false to skip).
class A7pParser {
  static ShotProfile fromPayload(Payload payload, {bool validate = true}) {
    if (validate) A7pValidator.validate(payload);
    return _parseProfile(payload.profile);
  }

  // ── main ───────────────────────────────────────────────────────────────────

  static ShotProfile _parseProfile(Profile p) {
    final dm = _buildDragModel(p);

    final weapon = Weapon(
      sightHeight: Distance(p.scHeight.toDouble(), Unit.millimeter),
      twist:       Distance(p.rTwist / 100.0,      Unit.inch),
      // zeroElevation is computed by the calculation engine; start at 0
      zeroElevation: Angular(0, Unit.radian),
    );

    final rifle = Rifle(
      name:   p.profileName,
      weapon: weapon,
    );

    final sight = Sight(
      name:          p.profileName,
      sightHeight:   weapon.sightHeight,
      zeroElevation: weapon.zeroElevation,
    );

    final projectile = Projectile(
      name:     p.bulletName,
      dm:       dm,
      dragType: _dragType(p.bcType),
    );

    final cartridge = Cartridge(
      name:                p.cartridgeName,
      projectile:          projectile,
      mv:                  Velocity(p.cMuzzleVelocity / 10.0, Unit.mps),
      powderTemp:          Temperature(p.cZeroTemperature.toDouble(), Unit.celsius),
      tempModifier:        p.cTCoeff / 1000.0,
      usePowderSensitivity: p.cTCoeff != 0,
    );

    final zeroConds = _buildAtmo(
      altitudeM:    0,
      pressureHPa:  p.cZeroAirPressure / 10.0,
      tempC:        p.cZeroAirTemperature.toDouble(),
      humidity:     p.cZeroAirHumidity.toDouble(),
      powderTempC:  p.cZeroPTemperature.toDouble(),
    );

    // The .a7p format does not carry separate current conditions — use zero
    // conditions as the default current conditions too.
    final currentConds = _buildAtmo(
      altitudeM:   0,
      pressureHPa: p.cZeroAirPressure / 10.0,
      tempC:       p.cZeroAirTemperature.toDouble(),
      humidity:    p.cZeroAirHumidity.toDouble(),
      powderTempC: p.cZeroPTemperature.toDouble(),
    );

    // Resolve zero distance from the distances list.
    final zeroDist = _zeroDistance(p);

    return ShotProfile(
      name:           p.profileName,
      rifle:          rifle,
      sight:          sight,
      cartridge:      cartridge,
      conditions:     currentConds,
      lookAngle:      Angular(0, Unit.radian),
      zeroDistance:   zeroDist,
      zeroConditions: zeroConds,
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static Atmo _buildAtmo({
    required double altitudeM,
    required double pressureHPa,
    required double tempC,
    required double humidity,
    required double powderTempC,
  }) =>
      Atmo(
        altitude:           Distance(altitudeM, Unit.meter),
        pressure:           Pressure(pressureHPa, Unit.hPa),
        temperature:        Temperature(tempC, Unit.celsius),
        humidity:           humidity,
        powderTemperature:  Temperature(powderTempC, Unit.celsius),
      );

  static Distance _zeroDistance(Profile p) {
    if (p.distances.isNotEmpty) {
      final idx = p.cZeroDistanceIdx.clamp(0, p.distances.length - 1);
      return Distance(p.distances[idx] / 100.0, Unit.meter);
    }
    return Distance(100.0, Unit.meter);
  }

  static DragModelType _dragType(GType t) => switch (t) {
        GType.G1     => DragModelType.g1,
        GType.G7     => DragModelType.g7,
        GType.CUSTOM => DragModelType.custom,
        _            => DragModelType.g1,
      };

  static DragModel _buildDragModel(Profile p) {
    final weight   = Weight(   p.bWeight   / 10.0,   Unit.grain);
    final diameter = Distance( p.bDiameter / 1000.0, Unit.inch);
    final length   = Distance( p.bLength   / 1000.0, Unit.inch);

    if (p.bcType == GType.CUSTOM) {
      return _buildCustomDragModel(p, weight, diameter, length);
    }

    return _buildBcDragModel(p, weight, diameter, length);
  }

  /// G1 / G7 — BC-based model, possibly multi-BC.
  static DragModel _buildBcDragModel(
    Profile p,
    Weight weight,
    Distance diameter,
    Distance length,
  ) {
    final baseTable = p.bcType == GType.G7 ? tableG7 : tableG1;

    if (p.coefRows.isEmpty) {
      // Fallback: bc = 1.0 (validator should have caught empty rows)
      return DragModel(
        bc: 1.0, dragTable: baseTable, weight: weight, diameter: diameter, length: length,
      );
    }

    // Single-BC: only one row, or all mv == 0
    final hasMvBreakpoints = p.coefRows.any((r) => r.mv != 0);

    if (!hasMvBreakpoints) {
      final bc = p.coefRows.first.bcCd / 10000.0;
      return DragModel(
        bc: bc, dragTable: baseTable, weight: weight, diameter: diameter, length: length,
      );
    }

    // Multi-BC
    final bcPoints = p.coefRows.map((r) {
      final bc = r.bcCd / 10000.0;
      final v  = Velocity(r.mv / 10.0, Unit.mps);
      return BCPoint(bc: bc, v: v);
    }).toList();

    return createDragModelMultiBC(
      bcPoints:  bcPoints,
      dragTable: baseTable,
      weight:    weight,
      diameter:  diameter,
      length:    length,
    );
  }

  /// CUSTOM drag model — coef_rows are (Cd×10000, Mach×10000) pairs.
  static DragModel _buildCustomDragModel(
    Profile p,
    Weight weight,
    Distance diameter,
    Distance length,
  ) {
    // Sort by mach ascending (A7P files may not guarantee order).
    final sorted = List.of(p.coefRows)
      ..sort((a, b) => a.mv.compareTo(b.mv));

    final table = sorted
        .map((r) => (
              mach: r.mv / 10000.0,
              cd:   r.bcCd / 10000.0,
            ))
        .toList();

    // bc for CUSTOM is derived from sectional density (same as createDragModelMultiBC)
    final sd = (weight.rawValue > 0 && diameter.rawValue > 0)
        ? calculateSectionalDensity(weight.in_(Unit.grain), diameter.in_(Unit.inch))
        : 1.0;

    return DragModel(
      bc: sd > 0 ? sd : 1.0,
      dragTable: table,
      weight:    weight,
      diameter:  diameter,
      length:    length,
    );
  }
}
