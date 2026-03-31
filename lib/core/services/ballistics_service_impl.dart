// ЧИСТИЙ DART (крім compute — для ізоляту)
import 'package:flutter/foundation.dart' show compute;

import 'package:eballistica/core/domain/ballistics_service.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/solver/calculator.dart';
import 'package:eballistica/core/solver/ffi/bclibc_bindings.g.dart';
import 'package:eballistica/core/solver/munition.dart';
import 'package:eballistica/core/solver/shot.dart';
import 'package:eballistica/core/solver/trajectory_data.dart';
import 'package:eballistica/core/solver/unit.dart';

// ── Isolate top-level functions ──────────────────────────────────────────────

// (profile, stepM, cachedZeroElevationRad?)
typedef _TableCalcArgs = (ShotProfile, double, double?);
// (hitResult, freshZeroElevationRad?)
typedef _TableCalcResult = (HitResult?, double?);

/// Builds an [Ammo] from [baseAmmo] with powder sensitivity enabled or not.
Ammo _makeAmmo(Ammo baseAmmo, bool usePowderSens) => usePowderSens
    ? baseAmmo
    : Ammo(
        dm: baseAmmo.dm,
        mv: baseAmmo.mv,
        powderTemp: baseAmmo.powderTemp,
        tempModifier: baseAmmo.tempModifier,
        usePowderSensitivity: false,
      );

_TableCalcResult _runTableCalculation(_TableCalcArgs args) {
  final (profile, stepM, cachedZeroElevRad) = args;
  try {
    final calc = Calculator();
    final baseAmmo = profile.cartridge.toAmmo();
    final zeroAtmo = profile.zeroConditions ?? profile.conditions;

    // Per-profile flags — zero and current may differ.
    final currentUsePowderSens =
        profile.usePowderSensitivity && baseAmmo.usePowderSensitivity;
    final zeroUsePowderSens =
        (profile.zeroUsePowderSensitivity ?? profile.usePowderSensitivity) &&
        baseAmmo.usePowderSensitivity;

    final currentAmmo = _makeAmmo(baseAmmo, currentUsePowderSens);
    final zeroAmmo = _makeAmmo(baseAmmo, zeroUsePowderSens);

    final weapon = profile.rifle.toWeapon();
    double? freshZeroElevRad;

    if (cachedZeroElevRad != null) {
      weapon.zeroElevation = Angular(cachedZeroElevRad, Unit.radian);
    } else {
      Shot zeroShot;
      try {
        zeroShot = Shot(
          weapon: weapon,
          ammo: zeroAmmo,
          lookAngle: profile.lookAngle,
          atmo: zeroAtmo.toAtmo(),
          winds: const [],
        );
        calc.setWeaponZero(zeroShot, profile.zeroDistance);
      } catch (_) {
        zeroShot = Shot(
          weapon: weapon,
          ammo: zeroAmmo,
          lookAngle: Angular(0.0, Unit.radian),
          atmo: zeroAtmo.toAtmo(),
          winds: const [],
        );
        calc.setWeaponZero(zeroShot, profile.zeroDistance);
      }
      freshZeroElevRad = weapon.zeroElevation.in_(Unit.radian);
    }

    final shot = Shot(
      weapon: weapon,
      ammo: currentAmmo,
      lookAngle: profile.lookAngle,
      atmo: profile.conditions.toAtmo(),
      winds: profile.winds.map((w) => w.toWind()).toList(),
      latitudeDeg: profile.latitudeDeg,
      azimuthDeg: profile.azimuthDeg,
    );

    final result = calc.fire(
      shot: shot,
      trajectoryRange: Distance(2000.0, Unit.meter),
      trajectoryStep: Distance(stepM, Unit.meter),
      filterFlags:
          BCTrajFlag.BC_TRAJ_FLAG_RANGE.value |
          BCTrajFlag.BC_TRAJ_FLAG_ZERO.value,
    );
    return (result, freshZeroElevRad);
  } catch (e, st) {
    throw CalculationException('Table calculation failed', e, st);
  }
}

// (profile, targetDistM, chartStepM, cachedZeroElevationRad?)
typedef _HomeCalcArgs = (ShotProfile, double, double, double?);
// (hitResult, freshZeroElevationRad?)
typedef _HomeCalcResult = (HitResult?, double?);

_HomeCalcResult _runHomeCalculation(_HomeCalcArgs args) {
  final (profile, targetDistM, chartStepM, cachedZeroElevRad) = args;
  final internalStepM = chartStepM < 1.0 ? chartStepM : 1.0;
  try {
    final calc = Calculator();
    final baseAmmo = profile.cartridge.toAmmo();
    final zeroAtmo = profile.zeroConditions ?? profile.conditions;

    final currentUsePowderSens =
        profile.usePowderSensitivity && baseAmmo.usePowderSensitivity;
    final zeroUsePowderSens =
        (profile.zeroUsePowderSensitivity ?? profile.usePowderSensitivity) &&
        baseAmmo.usePowderSensitivity;

    final currentAmmo = _makeAmmo(baseAmmo, currentUsePowderSens);
    final zeroAmmo = _makeAmmo(baseAmmo, zeroUsePowderSens);

    final weapon = profile.rifle.toWeapon();
    double? freshZeroElevRad;

    if (cachedZeroElevRad != null) {
      weapon.zeroElevation = Angular(cachedZeroElevRad, Unit.radian);
    } else {
      final zeroShot = Shot(
        weapon: weapon,
        ammo: zeroAmmo,
        lookAngle: profile.lookAngle,
        atmo: zeroAtmo.toAtmo(),
        winds: const [],
      );
      calc.setWeaponZero(zeroShot, profile.zeroDistance);
      freshZeroElevRad = weapon.zeroElevation.in_(Unit.radian);
    }

    final newShot = Shot(
      weapon: weapon,
      ammo: currentAmmo,
      lookAngle: profile.lookAngle,
      atmo: profile.conditions.toAtmo(),
      winds: profile.winds.map((w) => w.toWind()).toList(),
      latitudeDeg: profile.latitudeDeg,
      azimuthDeg: profile.azimuthDeg,
    );

    final targetElev = calc.barrelElevationForTarget(
      newShot,
      Distance(targetDistM, Unit.meter),
    );
    final holdRad =
        targetElev.in_(Unit.radian) -
        newShot.weapon.zeroElevation.in_(Unit.radian);
    newShot.relativeAngle = Angular(holdRad, Unit.radian);

    final result = calc.fire(
      shot: newShot,
      trajectoryRange: Distance(targetDistM, Unit.meter),
      trajectoryStep: Distance(internalStepM, Unit.meter),
      filterFlags:
          BCTrajFlag.BC_TRAJ_FLAG_RANGE.value |
          BCTrajFlag.BC_TRAJ_FLAG_ZERO.value,
    );
    return (result, freshZeroElevRad);
  } catch (e, st) {
    throw CalculationException('Home calculation failed', e, st);
  }
}

// ── Exception ────────────────────────────────────────────────────────────────

class CalculationException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  CalculationException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() =>
      'CalculationException: $message${originalError != null ? ' (${originalError.runtimeType}: $originalError)' : ''}';
}

// ── Implementation ───────────────────────────────────────────────────────────

class BallisticsServiceImpl implements BallisticsService {
  @override
  Future<BallisticsResult> calculateTable(
    ShotProfile profile,
    TableCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    final (hit, freshZero) = await compute(_runTableCalculation, (
      profile,
      opts.stepM,
      cachedZeroElevRad,
    ));
    if (hit == null) throw StateError('Table calculation returned null');
    return BallisticsResult(
      hitResult: hit,
      zeroElevationRad: freshZero ?? cachedZeroElevRad ?? 0.0,
    );
  }

  @override
  Future<BallisticsResult> calculateForTarget(
    ShotProfile profile,
    TargetCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    final (hit, freshZero) = await compute(_runHomeCalculation, (
      profile,
      opts.targetDistM,
      opts.chartStepM,
      cachedZeroElevRad,
    ));
    if (hit == null) throw StateError('Target calculation returned null');
    return BallisticsResult(
      hitResult: hit,
      zeroElevationRad: freshZero ?? cachedZeroElevRad ?? 0.0,
    );
  }
}
