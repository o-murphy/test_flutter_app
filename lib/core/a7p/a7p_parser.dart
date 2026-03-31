import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/models/projectile.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/sight.dart';
import '../proto/profedit.pb.dart' hide CoefRow;
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
    final rifle = Rifle(
      name: p.profileName,
      sightHeight: Distance(p.scHeight.toDouble(), Unit.millimeter),
      twist: Distance(p.rTwist / 100.0, Unit.inch),
    );

    final sight = Sight(
      name: p.profileName,
      sightHeight: rifle.sightHeight,
      zeroElevation: rifle.zeroElevation,
    );

    final projectile = Projectile(
      name: p.bulletName,
      dragType: _dragType(p.bcType),
      weight: Weight(p.bWeight / 10.0, Unit.grain),
      diameter: Distance(p.bDiameter / 1000.0, Unit.inch),
      length: Distance(p.bLength / 1000.0, Unit.inch),
      coefRows: _parseCoefRows(p),
    );

    final cartridge = Cartridge(
      name: p.cartridgeName,
      projectile: projectile,
      mv: Velocity(p.cMuzzleVelocity / 10.0, Unit.mps),
      powderTemp: Temperature(p.cZeroTemperature.toDouble(), Unit.celsius),
      powderSensitivity: Ratio(p.cTCoeff / 1000.0, Unit.fraction),
      usePowderSensitivity: p.cTCoeff != 0,
    );

    final zeroConds = _buildAtmoData(
      altitudeM: 0,
      pressureHPa: p.cZeroAirPressure / 10.0,
      tempC: p.cZeroAirTemperature.toDouble(),
      humidity: p.cZeroAirHumidity.toDouble(),
      powderTempC: p.cZeroPTemperature.toDouble(),
    );

    final currentConds = _buildAtmoData(
      altitudeM: 0,
      pressureHPa: p.cZeroAirPressure / 10.0,
      tempC: p.cZeroAirTemperature.toDouble(),
      humidity: p.cZeroAirHumidity.toDouble(),
      powderTempC: p.cZeroPTemperature.toDouble(),
    );

    final zeroDist = _zeroDistance(p);

    return ShotProfile(
      name: p.profileName,
      rifle: rifle,
      sight: sight,
      cartridge: cartridge,
      conditions: currentConds,
      lookAngle: Angular(0, Unit.radian),
      zeroDistance: zeroDist,
      zeroConditions: zeroConds,
      usePowderSensitivity: p.cTCoeff != 0,
      useDiffPowderTemp: false,
      zeroUseDiffPowderTemp: p.cZeroPTemperature != p.cZeroAirTemperature,
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static AtmoData _buildAtmoData({
    required double altitudeM,
    required double pressureHPa,
    required double tempC,
    required double humidity,
    required double powderTempC,
  }) => AtmoData(
    altitude: Distance(altitudeM, Unit.meter),
    pressure: Pressure(pressureHPa, Unit.hPa),
    temperature: Temperature(tempC, Unit.celsius),
    humidity: humidity / 100.0,
    powderTemp: Temperature(powderTempC, Unit.celsius),
  );

  static Distance _zeroDistance(Profile p) {
    if (p.distances.isNotEmpty) {
      final idx = p.cZeroDistanceIdx.clamp(0, p.distances.length - 1);
      return Distance(p.distances[idx] / 100.0, Unit.meter);
    }
    return Distance(100.0, Unit.meter);
  }

  static DragModelType _dragType(GType t) => switch (t) {
    GType.G1 => DragModelType.g1,
    GType.G7 => DragModelType.g7,
    GType.CUSTOM => DragModelType.custom,
    _ => DragModelType.g1,
  };

  /// Parse coefRows from the a7p payload into storage-ready [CoeficientRow] objects.
  ///
  /// G1/G7: bcCd = BC value (bcCd/10000), mv = velocity m/s (mv/10)
  /// CUSTOM: bcCd = Cd value (bcCd/10000), mv = Mach (mv/10000)
  static List<CoeficientRow> _parseCoefRows(Profile p) {
    if (p.bcType == GType.CUSTOM) {
      final sorted = List.of(p.coefRows)..sort((a, b) => a.mv.compareTo(b.mv));
      return sorted
          .map<CoeficientRow>(
            (r) => CoeficientRow(bcCd: r.bcCd / 10000.0, mv: r.mv / 10000.0),
          )
          .toList();
    }
    // G1 / G7
    return p.coefRows
        .map<CoeficientRow>(
          (r) => CoeficientRow(bcCd: r.bcCd / 10000.0, mv: r.mv / 10.0),
        )
        .toList();
  }
}
