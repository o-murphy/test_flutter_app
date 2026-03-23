import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../src/models/shot_profile.dart';
import '../src/solver/calculator.dart';
import '../src/solver/ffi/bclibc_bindings.g.dart';
import '../src/solver/munition.dart';
import '../src/solver/shot.dart';
import '../src/solver/trajectory_data.dart';
import '../src/solver/unit.dart';
import 'settings_provider.dart';
import 'shot_profile_provider.dart';

typedef _TableCalcArgs = (ShotProfile, double, bool, bool);
typedef _HomeCalcArgs  = (ShotProfile, double, double, bool, bool); // targetDistM, chartStepM

// ── Table calculation — zeroed at zeroDistance, full 2000 m range ─────────────

HitResult? _runTableCalculation(_TableCalcArgs args) {
  final (profile, stepM, usePowderSens, useDiffPowderTemp) = args;
  try {
    final calc     = Calculator();
    final baseAmmo = profile.cartridge.toAmmo();
    final zeroAtmo = profile.zeroConditions ?? profile.conditions;

    Shot zeroShot;
    try {
      zeroShot = Shot(
        weapon:    profile.rifle.weapon,
        ammo:      baseAmmo,
        lookAngle: profile.lookAngle,
        atmo:      zeroAtmo,
        winds:     const [],
      );
      calc.setWeaponZero(zeroShot, profile.zeroDistance);
    } catch (_) {
      zeroShot = Shot(
        weapon:    profile.rifle.weapon,
        ammo:      baseAmmo,
        lookAngle: Angular(0.0, Unit.radian),
        atmo:      zeroAtmo,
        winds:     const [],
      );
      calc.setWeaponZero(zeroShot, profile.zeroDistance);
    }

    final Ammo shotAmmo;
    if (usePowderSens && baseAmmo.usePowderSensitivity) {
      final Temperature currentTemp = useDiffPowderTemp
          ? profile.conditions.powderTemp
          : profile.conditions.temperature;
      final adjustedMv = baseAmmo.getVelocityForTemp(currentTemp);
      shotAmmo = Ammo(
        dm:                   baseAmmo.dm,
        mv:                   adjustedMv,
        powderTemp:           baseAmmo.powderTemp,
        tempModifier:         baseAmmo.tempModifier,
        usePowderSensitivity: baseAmmo.usePowderSensitivity,
      );
    } else {
      shotAmmo = baseAmmo;
    }

    final shot = Shot(
      weapon:      profile.rifle.weapon,
      ammo:        shotAmmo,
      lookAngle:   profile.lookAngle,
      atmo:        profile.conditions,
      winds:       profile.winds,
      latitudeDeg: profile.latitudeDeg,
      azimuthDeg:  profile.azimuthDeg,
    );

    return calc.fire(
      shot:            shot,
      trajectoryRange: Distance(2000.0, Unit.meter),
      trajectoryStep:  Distance(stepM,  Unit.meter),
      filterFlags:     BCTrajFlag.BC_TRAJ_FLAG_RANGE | BCTrajFlag.BC_TRAJ_FLAG_ZERO,
    );
  } catch (e, st) {
    // ignore: avoid_print
    print('_runTableCalculation error: $e\n$st');
    return null;
  }
}

class TableCalculationNotifier extends AsyncNotifier<HitResult?> {
  bool _dirty = true;

  @override
  Future<HitResult?> build() async => null;

  void markDirty() => _dirty = true;

  Future<void> recalculateIfNeeded() async {
    if (!_dirty) return;
    final profile  = ref.read(shotProfileProvider).value;
    if (profile == null) return;
    final settings          = ref.read(settingsProvider).value;
    final tableStep         = settings?.tableDistanceStep ?? 100.0;
    final stepM             = tableStep < 1.0 ? tableStep : 1.0; // min(1.0, tableStep)
    final usePowderSens     = settings?.enablePowderSensitivity       ?? false;
    final useDiffPowderTemp = settings?.useDifferentPowderTemperature ?? false;
    _dirty = false;
    state  = const AsyncLoading();
    state  = AsyncData(
      await compute(_runTableCalculation, (profile, stepM, usePowderSens, useDiffPowderTemp)),
    );
  }
}

final tableCalculationProvider =
    AsyncNotifierProvider<TableCalculationNotifier, HitResult?>(TableCalculationNotifier.new);

// ── Home calculation — zeroed at targetDistance ───────────────────────────────

HitResult? _runHomeCalculation(_HomeCalcArgs args) {
  final (profile, targetDistM, chartStepM, usePowderSens, useDiffPowderTemp) = args;
  final internalStepM = chartStepM < 1.0 ? chartStepM : 1.0; // min(1.0, chartStep)
  try {
    final calc     = Calculator();
    final baseAmmo = profile.cartridge.toAmmo();
    final zeroAtmo = profile.zeroConditions ?? profile.conditions;

    // 1. Zero the weapon at zeroDistance with zero conditions.
    //    setWeaponZero stores the elevation in weapon.zeroElevation (mutable).
    final zeroShot = Shot(
      weapon:    profile.rifle.weapon,
      ammo:      baseAmmo,
      lookAngle: profile.lookAngle,
      atmo:      zeroAtmo,
      winds:     const [],
    );
    calc.setWeaponZero(zeroShot, profile.zeroDistance);

    final Ammo shotAmmo;
    if (usePowderSens && baseAmmo.usePowderSensitivity) {
      final Temperature currentTemp = useDiffPowderTemp
          ? profile.conditions.powderTemp
          : profile.conditions.temperature;
      final adjustedMv = baseAmmo.getVelocityForTemp(currentTemp);
      shotAmmo = Ammo(
        dm:                   baseAmmo.dm,
        mv:                   adjustedMv,
        powderTemp:           baseAmmo.powderTemp,
        tempModifier:         baseAmmo.tempModifier,
        usePowderSensitivity: baseAmmo.usePowderSensitivity,
      );
    } else {
      shotAmmo = baseAmmo;
    }

    // 2. New shot with current conditions.
    //    weapon.zeroElevation is already set, so barrelElevation = zero angle.
    final newShot = Shot(
      weapon:      profile.rifle.weapon,
      ammo:        shotAmmo,
      lookAngle:   profile.lookAngle,
      atmo:        profile.conditions,
      winds:       profile.winds,
      latitudeDeg: profile.latitudeDeg,
      azimuthDeg:  profile.azimuthDeg,
    );

    // 3. Compute the hold: elevation needed to hit the target minus the stored
    //    zero elevation (mirrors JS shootTheTarget logic).
    final zeroElev   = newShot.weapon.zeroElevation;
    final targetElev = calc.barrelElevationForTarget(
      newShot,
      Distance(targetDistM, Unit.meter),
    );
    final holdRad = targetElev.in_(Unit.radian) - zeroElev.in_(Unit.radian);
    newShot.relativeAngle = Angular(holdRad, Unit.radian);

    // 4. Fire — trajectory crosses 0 (LoS) at targetDistance.
    return calc.fire(
      shot:            newShot,
      trajectoryRange: Distance(targetDistM + chartStepM, Unit.meter),
      trajectoryStep:  Distance(internalStepM,            Unit.meter),
      filterFlags:     BCTrajFlag.BC_TRAJ_FLAG_RANGE | BCTrajFlag.BC_TRAJ_FLAG_ZERO,
    );
  } catch (e, st) {
    // ignore: avoid_print
    print('_runHomeCalculation error: $e\n$st');
    return null;
  }
}

class HomeCalculationNotifier extends AsyncNotifier<HitResult?> {
  bool _dirty = true;

  @override
  Future<HitResult?> build() async => null;

  void markDirty() => _dirty = true;

  Future<void> recalculateIfNeeded() async {
    if (!_dirty) return;
    final profile  = ref.read(shotProfileProvider).value;
    if (profile == null) return;
    final settings          = ref.read(settingsProvider).value;
    final targetDistM       = profile.targetDistance.in_(Unit.meter);
    final chartStepM        = settings?.chartDistanceStep ?? 100.0;
    final usePowderSens     = settings?.enablePowderSensitivity       ?? false;
    final useDiffPowderTemp = settings?.useDifferentPowderTemperature ?? false;
    _dirty = false;
    state  = const AsyncLoading();
    state  = AsyncData(
      await compute(
        _runHomeCalculation,
        (profile, targetDistM, chartStepM, usePowderSens, useDiffPowderTemp),
      ),
    );
  }
}

final homeCalculationProvider =
    AsyncNotifierProvider<HomeCalculationNotifier, HitResult?>(HomeCalculationNotifier.new);
