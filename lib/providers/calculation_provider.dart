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

typedef _CalcArgs = (ShotProfile, double, bool, bool);

HitResult? _runCalculation(_CalcArgs args) {
  final (profile, stepM, usePowderSens, useDiffPowderTemp) = args;
  try {
    final calc = Calculator();

    // Base ammo — reference MV from cartridge, used for zeroing.
    final baseAmmo = profile.cartridge.toAmmo();

    Shot zeroShot;
    try {
      zeroShot = Shot(
        weapon:     profile.rifle.weapon,
        ammo:       baseAmmo,
        lookAngle:  profile.lookAngle,
        atmo:       profile.conditions,
        winds:      const [],
      );
      calc.setWeaponZero(zeroShot, profile.zeroDistance);
    } catch (_) {
      zeroShot = Shot(
        weapon:    profile.rifle.weapon,
        ammo:      baseAmmo,
        lookAngle: Angular(0.0, Unit.radian),
        atmo:      profile.conditions,
        winds:     const [],
      );
      calc.setWeaponZero(zeroShot, profile.zeroDistance);
    }

    // Shot ammo — MV adjusted for current powder / atmo temperature.
    final Ammo shotAmmo;
    if (usePowderSens && baseAmmo.usePowderSensitivity) {
      final Temperature currentTemp = useDiffPowderTemp
          ? profile.conditions.powderTemp   // separate powder temp
          : profile.conditions.temperature; // atmo temp
      final adjustedMv = baseAmmo.getVelocityForTemp(currentTemp);
      shotAmmo = Ammo(
        dm:                  baseAmmo.dm,
        mv:                  adjustedMv,
        powderTemp:          baseAmmo.powderTemp,
        tempModifier:        baseAmmo.tempModifier,
        usePowderSensitivity: baseAmmo.usePowderSensitivity,
      );
    } else {
      shotAmmo = baseAmmo;
    }

    final shot = Shot(
      weapon:     profile.rifle.weapon,
      ammo:       shotAmmo,
      lookAngle:  profile.lookAngle,
      atmo:       profile.conditions,
      winds:      profile.winds,
      latitudeDeg: profile.latitudeDeg,
      azimuthDeg:  profile.azimuthDeg,
    );

    return calc.fire(
      shot:             shot,
      trajectoryRange:  Distance(2000.0, Unit.meter),
      trajectoryStep:   Distance(stepM,  Unit.meter),
      filterFlags:      BCTrajFlag.BC_TRAJ_FLAG_RANGE | BCTrajFlag.BC_TRAJ_FLAG_ZERO,
    );
  } catch (e, st) {
    // ignore: avoid_print
    print('_runCalculation error: $e\n$st');
    return null;
  }
}

class CalculationNotifier extends AsyncNotifier<HitResult?> {
  bool _dirty = true;

  @override
  Future<HitResult?> build() async => null; // lazy — calculate only when requested

  void markDirty() => _dirty = true;

  Future<void> recalculateIfNeeded() async {
    if (!_dirty) return;
    final profile  = ref.read(shotProfileProvider).value;
    if (profile == null) return;
    final settings = ref.read(settingsProvider).value;
    final stepM    = settings?.tableDistanceStep ?? 100;
    final usePowderSens    = settings?.enablePowderSensitivity       ?? false;
    final useDiffPowderTemp = settings?.useDifferentPowderTemperature ?? false;
    _dirty = false;
    state = const AsyncLoading();
    state = AsyncData(
      await compute(_runCalculation, (profile, stepM, usePowderSens, useDiffPowderTemp)),
    );
  }
}

final calculationProvider =
    AsyncNotifierProvider<CalculationNotifier, HitResult?>(CalculationNotifier.new);
