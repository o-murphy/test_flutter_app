import 'package:eballistica/core/models/conditions_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_conditions_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/models/projectile.dart' show DragModelType;
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/solver/munition.dart'
    show velocityForPowderTemp;
import 'package:eballistica/core/solver/unit.dart';

// ── Spoiler data ─────────────────────────────────────────────────────────────

class DetailsTableData {
  final String rifleName;
  final String? caliber;
  final String? twist;
  final String? dragModel;
  final String? bc;
  final String? zeroMv;
  final String? currentMv;
  final String? zeroDist;
  final String? bulletLen;
  final String? bulletDiam;
  final String? bulletWeight;
  final String? formFactor;
  final String? sectionalDensity;
  final String? gyroStability;
  final String? temperature;
  final String? humidity;
  final String? pressure;
  final String? windSpeed;
  final String? windDir;

  const DetailsTableData({
    required this.rifleName,
    this.caliber,
    this.twist,
    this.dragModel,
    this.bc,
    this.zeroMv,
    this.currentMv,
    this.zeroDist,
    this.bulletLen,
    this.bulletDiam,
    this.bulletWeight,
    this.formFactor,
    this.sectionalDensity,
    this.gyroStability,
    this.temperature,
    this.humidity,
    this.pressure,
    this.windSpeed,
    this.windDir,
  });
}

// ── Private builder ──────────────────────────────────────────────────────────

DetailsTableData _buildDetails(
  ShotProfile profile,
  Conditions conditions,
  AppSettings settings,
) {
  final units = settings.units;
  final rifle = profile.rifle;
  final cart = profile.cartridge!;
  final proj = cart.projectile;
  final atmo = conditions.atmo;
  final winds = conditions.winds;

  final twistInch = rifle.twist.in_(Unit.inch);
  final weightGr = proj.weight.in_(Unit.grain);
  final diamInch = proj.diameter.in_(Unit.inch);
  final lenInch = proj.length.in_(Unit.inch);

  // Powder sensitivity — separate flags for zero and current
  final currentPowderSensOn = conditions.usePowderSensitivity;
  // Zero conditions from cartridge
  final zeroConditions = cart.zeroConditions;
  final zeroPowderSensOn = zeroConditions.usePowderSensitivity;
  final currentUseDiffTemp =
      currentPowderSensOn && conditions.useDiffPowderTemp;
  final zeroUseDiffTemp = zeroPowderSensOn && zeroConditions.useDiffPowderTemp;

  final refMvMps = cart.mv.in_(Unit.mps);
  final refPowderTempC = cart.powderTemp.in_(Unit.celsius);

  double mvAtTempC(double tCurC) => velocityForPowderTemp(
    refMvMps,
    refPowderTempC,
    tCurC,
    cart.powderSensitivity.in_(Unit.fraction),
  );

  // Zero MV - використовуємо zeroConditions замість cart.atmo
  final zeroAtmo = zeroConditions.atmo;
  final zeroPowderTempC = zeroUseDiffTemp
      ? zeroAtmo.powderTemp.in_(Unit.celsius)
      : zeroAtmo.temperature.in_(Unit.celsius);
  final zeroMvMps = zeroPowderSensOn ? mvAtTempC(zeroPowderTempC) : refMvMps;

  // Current MV
  final currTempC = currentUseDiffTemp
      ? atmo.powderTemp.in_(Unit.celsius)
      : atmo.temperature.in_(Unit.celsius);
  final currentMvMps = currentPowderSensOn ? mvAtTempC(currTempC) : refMvMps;

  // Gyrostability (Miller)
  final currentShot = profile.toCurrentShot(
    conditions,
    profile.rifle.toWeapon(),
  );
  double sg = currentShot.calculateStabilityCoefficient();

  // Sectional density + form factor
  final sd = (weightGr > 0 && diamInch > 0)
      ? (weightGr / 7000.0) / (diamInch * diamInch)
      : null;
  final displayBc = (!proj.isMultiBC && proj.coefRows.isNotEmpty)
      ? proj.coefRows.first.bcCd
      : 0.0;
  final ff = (sd != null && displayBc > 0) ? sd / displayBc : null;

  String fmtV(double mps) {
    final disp = Velocity(mps, Unit.mps).in_(units.velocity);
    return '${disp.toStringAsFixed(FC.velocity.accuracyFor(units.velocity))} ${units.velocity.symbol}';
  }

  String fmtWithAcc(Dimension dim, Unit dispUnit, FieldConstraints fc) {
    return '${dim.in_(dispUnit).toStringAsFixed(fc.accuracyFor(dispUnit))} ${dispUnit.symbol}';
  }

  return DetailsTableData(
    rifleName: rifle.name,
    caliber: diamInch > 0
        ? fmtWithAcc(proj.diameter, units.diameter, FC.bulletDiameter)
        : null,
    twist: twistInch > 0
        ? () {
            final tw = Distance(twistInch, Unit.inch).in_(units.twist);
            return '1:${tw.toStringAsFixed(FC.twist.accuracyFor(units.twist))} ${units.twist.symbol}';
          }()
        : null,
    dragModel: switch (proj.dragType) {
      DragModelType.g1 => 'G1',
      DragModelType.g7 => 'G7',
      DragModelType.custom => 'Custom',
    },
    bc: displayBc > 0
        ? displayBc.toStringAsFixed(FC.ballisticCoefficient.accuracy)
        : null,
    zeroMv: fmtV(zeroMvMps),
    currentMv: fmtV(currentMvMps),
    zeroDist: fmtWithAcc(
      zeroConditions.distance,
      units.distance,
      FC.zeroDistance,
    ),
    bulletLen: lenInch > 0
        ? fmtWithAcc(proj.length, units.length, FC.bulletLength)
        : null,
    bulletDiam: diamInch > 0
        ? fmtWithAcc(proj.diameter, units.diameter, FC.bulletDiameter)
        : null,
    bulletWeight: weightGr > 0
        ? () {
            final wDisp = Weight(weightGr, Unit.grain).in_(units.weight);
            return '${wDisp.toStringAsFixed(FC.bulletWeight.accuracyFor(units.weight))} ${units.weight.symbol}';
          }()
        : null,
    formFactor: ff?.toStringAsFixed(3),
    sectionalDensity: sd?.toStringAsFixed(3),
    gyroStability: sg.toStringAsFixed(2),
    temperature: () {
      final t = atmo.temperature.in_(units.temperature);
      return '${t.toStringAsFixed(FC.temperature.accuracyFor(units.temperature))} ${units.temperature.symbol}';
    }(),
    humidity:
        '${(atmo.humidity.convert(Unit.fraction, Unit.percent)).toStringAsFixed(0)} %',
    pressure: () {
      final p = atmo.pressure.in_(units.pressure);
      return '${p.toStringAsFixed(FC.pressure.accuracyFor(units.pressure))} ${units.pressure.symbol}';
    }(),
    windSpeed: () {
      final ws =
          (winds.isNotEmpty ? winds.first.velocity : Velocity(0.0, Unit.mps))
              .in_(units.velocity);
      return '${ws.toStringAsFixed(FC.windVelocity.accuracyFor(units.velocity))} ${units.velocity.symbol}';
    }(),
    windDir:
        '${(winds.isNotEmpty ? winds.first.directionFrom : Angular(0.0, Unit.degree)).in_(Unit.degree).toStringAsFixed(0)}°',
  );
}

// ── Provider ─────────────────────────────────────────────────────────────────

final detailsTableMvProvider = Provider<DetailsTableData?>((ref) {
  final profile = ref.watch(shotProfileProvider).value;
  final conditions = ref.watch(shotConditionsProvider).value;
  final settings = ref.watch(settingsProvider).value;

  if (profile == null || conditions == null || settings == null) return null;
  if (profile.cartridge == null) return null;

  return _buildDetails(profile, conditions, settings);
});
