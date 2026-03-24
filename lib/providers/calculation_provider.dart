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

/// Custom exception for calculation errors
class CalculationException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  CalculationException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() => 'CalculationException: $message${originalError != null ? ' (${originalError.runtimeType}: $originalError)' : ''}';
}

// ── Zero fingerprint ─────────────────────────────────────────────────────────
//
// All inputs that affect setWeaponZero. Flat List<double> — equality via
// listEquals, no hashCode overrides needed on domain objects.
// bool → 1.0 / 0.0 for uniform storage.

List<double> _buildZeroKey(ShotProfile profile, bool usePowderSens) {
  final zeroAtmo = profile.zeroConditions ?? profile.conditions;
  final w  = profile.rifle.weapon;
  final c  = profile.cartridge;
  final dm = c.projectile.dm;
  return [
    w.sightHeight.in_(Unit.meter),
    w.twist.in_(Unit.inch),
    c.mv.in_(Unit.mps),
    c.powderTemp.in_(Unit.celsius),
    c.tempModifier,
    c.usePowderSensitivity ? 1.0 : 0.0,
    dm.bc,
    dm.weight.in_(Unit.gram),
    dm.diameter.in_(Unit.inch),
    dm.length.in_(Unit.inch),
    dm.dragTable.length.toDouble(),
    zeroAtmo.altitude.in_(Unit.meter),
    zeroAtmo.pressure.in_(Unit.hPa),
    zeroAtmo.temperature.in_(Unit.celsius),
    zeroAtmo.humidity,
    zeroAtmo.powderTemp.in_(Unit.celsius),
    profile.zeroDistance.in_(Unit.meter),
    profile.lookAngle.in_(Unit.radian),
    usePowderSens ? 1.0 : 0.0,
  ];
}

// ── Table calculation — zeroed at zeroDistance, full 2000 m range ─────────────

// (profile, stepM, usePowderSens, cachedZeroElevationRad?)
typedef _TableCalcArgs = (ShotProfile, double, bool, double?);
// (hitResult, freshZeroElevationRad?) — second is null when cache was reused
typedef _TableCalcResult = (HitResult?, double?);

_TableCalcResult _runTableCalculation(_TableCalcArgs args) {
  final (profile, stepM, usePowderSens, cachedZeroElevRad) = args;
  try {
    final calc     = Calculator();
    final baseAmmo = profile.cartridge.toAmmo();
    final zeroAtmo = profile.zeroConditions ?? profile.conditions;

    final Ammo shotAmmo = (usePowderSens && baseAmmo.usePowderSensitivity)
        ? baseAmmo
        : Ammo(
            dm: baseAmmo.dm,
            mv: baseAmmo.mv,
            powderTemp: baseAmmo.powderTemp,
            tempModifier: baseAmmo.tempModifier,
            usePowderSensitivity: false,
          );

    final weapon = profile.rifle.weapon;
    double? freshZeroElevRad;

    if (cachedZeroElevRad != null) {
      // Zero conditions unchanged — reuse cached elevation, skip Phase 1.
      weapon.zeroElevation = Angular(cachedZeroElevRad, Unit.radian);
    } else {
      // Phase 1 — Zero with zero conditions.
      Shot zeroShot;
      try {
        zeroShot = Shot(
          weapon:    weapon,
          ammo:      shotAmmo,
          lookAngle: profile.lookAngle,
          atmo:      zeroAtmo,
          winds:     const [],
        );
        calc.setWeaponZero(zeroShot, profile.zeroDistance);
      } catch (_) {
        zeroShot = Shot(
          weapon:    weapon,
          ammo:      shotAmmo,
          lookAngle: Angular(0.0, Unit.radian),
          atmo:      zeroAtmo,
          winds:     const [],
        );
        calc.setWeaponZero(zeroShot, profile.zeroDistance);
      }
      freshZeroElevRad = weapon.zeroElevation.in_(Unit.radian);
    }

    // Phase 2 — Fire with current conditions.
    final shot = Shot(
      weapon:      weapon,
      ammo:        shotAmmo,
      lookAngle:   profile.lookAngle,
      atmo:        profile.conditions,
      winds:       profile.winds,
      latitudeDeg: profile.latitudeDeg,
      azimuthDeg:  profile.azimuthDeg,
    );

    final result = calc.fire(
      shot:            shot,
      trajectoryRange: Distance(2000.0, Unit.meter),
      trajectoryStep:  Distance(stepM,  Unit.meter),
      filterFlags:     BCTrajFlag.BC_TRAJ_FLAG_RANGE | BCTrajFlag.BC_TRAJ_FLAG_ZERO,
    );
    return (result, freshZeroElevRad);
  } catch (e, st) {
    throw CalculationException('Table calculation failed', e, st);
  }
}

class TableCalculationNotifier extends AsyncNotifier<HitResult?> {
  bool _dirty = true;
  List<double>? _lastZeroKey;
  double? _cachedZeroElevRad;

  @override
  Future<HitResult?> build() async => null;

  void markDirty() => _dirty = true;

  void retry() {
    _dirty = true;
    _lastZeroKey = null;
    _cachedZeroElevRad = null;
    recalculateIfNeeded();
  }

  Future<void> recalculateIfNeeded() async {
    if (!_dirty) return;
    final profile = ref.read(shotProfileProvider).value;
    if (profile == null) return;
    final settings      = ref.read(settingsProvider).value;
    final tableStep     = settings?.tableConfig.stepM ?? 100.0;
    final stepM         = tableStep < 1.0 ? tableStep : 1.0;
    final usePowderSens = settings?.enablePowderSensitivity ?? false;

    final zeroKey    = _buildZeroKey(profile, usePowderSens);
    final cachedElev = listEquals(zeroKey, _lastZeroKey) ? _cachedZeroElevRad : null;

    _dirty = false;
    state  = const AsyncLoading();
    try {
      final (hitResult, freshZeroElev) = await compute(
        _runTableCalculation,
        (profile, stepM, usePowderSens, cachedElev),
      );
      if (freshZeroElev != null) {
        _lastZeroKey       = zeroKey;
        _cachedZeroElevRad = freshZeroElev;
      }
      state = AsyncData(hitResult);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final tableCalculationProvider =
    AsyncNotifierProvider<TableCalculationNotifier, HitResult?>(TableCalculationNotifier.new);

// ── Home calculation — shootTheTarget pattern ─────────────────────────────────

// (profile, targetDistM, chartStepM, usePowderSens, cachedZeroElevationRad?)
typedef _HomeCalcArgs = (ShotProfile, double, double, bool, double?);
// (hitResult, freshZeroElevationRad?)
typedef _HomeCalcResult = (HitResult?, double?);

_HomeCalcResult _runHomeCalculation(_HomeCalcArgs args) {
  final (profile, targetDistM, chartStepM, usePowderSens, cachedZeroElevRad) = args;
  final internalStepM = chartStepM < 1.0 ? chartStepM : 1.0;
  try {
    final calc     = Calculator();
    final baseAmmo = profile.cartridge.toAmmo();
    final zeroAtmo = profile.zeroConditions ?? profile.conditions;

    final Ammo shotAmmo = (usePowderSens && baseAmmo.usePowderSensitivity)
        ? baseAmmo
        : Ammo(
            dm: baseAmmo.dm,
            mv: baseAmmo.mv,
            powderTemp: baseAmmo.powderTemp,
            tempModifier: baseAmmo.tempModifier,
            usePowderSensitivity: false,
          );

    final weapon = profile.rifle.weapon;
    double? freshZeroElevRad;

    if (cachedZeroElevRad != null) {
      // Zero conditions unchanged — reuse cached elevation, skip Phase 1.
      weapon.zeroElevation = Angular(cachedZeroElevRad, Unit.radian);
    } else {
      // Phase 1 — Zero with zero conditions.
      final zeroShot = Shot(
        weapon:    weapon,
        ammo:      shotAmmo,
        lookAngle: profile.lookAngle,
        atmo:      zeroAtmo,
        winds:     const [],
      );
      calc.setWeaponZero(zeroShot, profile.zeroDistance);
      freshZeroElevRad = weapon.zeroElevation.in_(Unit.radian);
    }

    // Phase 2 — New shot with current conditions.
    final newShot = Shot(
      weapon:      weapon,
      ammo:        shotAmmo,
      lookAngle:   profile.lookAngle,
      atmo:        profile.conditions,
      winds:       profile.winds,
      latitudeDeg: profile.latitudeDeg,
      azimuthDeg:  profile.azimuthDeg,
    );

    // Phase 3 — Compute hold.
    final targetElev = calc.barrelElevationForTarget(
      newShot,
      Distance(targetDistM, Unit.meter),
    );
    final holdRad = targetElev.in_(Unit.radian) - newShot.weapon.zeroElevation.in_(Unit.radian);
    newShot.relativeAngle = Angular(holdRad, Unit.radian);

    // Phase 4 — Fire.
    final result = calc.fire(
      shot:            newShot,
      trajectoryRange: Distance(targetDistM, Unit.meter),
      trajectoryStep:  Distance(internalStepM, Unit.meter),
      filterFlags:     BCTrajFlag.BC_TRAJ_FLAG_RANGE | BCTrajFlag.BC_TRAJ_FLAG_ZERO,
    );
    return (result, freshZeroElevRad);
  } catch (e, st) {
    throw CalculationException('Home calculation failed', e, st);
  }
}

class HomeCalculationNotifier extends AsyncNotifier<HitResult?> {
  bool _dirty = true;
  List<double>? _lastZeroKey;
  double? _cachedZeroElevRad;

  @override
  Future<HitResult?> build() async => null;

  void markDirty() => _dirty = true;

  void retry() {
    _dirty = true;
    _lastZeroKey = null;
    _cachedZeroElevRad = null;
    recalculateIfNeeded();
  }

  Future<void> recalculateIfNeeded() async {
    if (!_dirty) return;
    final profile = ref.read(shotProfileProvider).value;
    if (profile == null) return;
    final settings      = ref.read(settingsProvider).value;
    final targetDistM   = profile.targetDistance.in_(Unit.meter);
    final chartStepM    = settings?.chartDistanceStep ?? 100.0;
    final usePowderSens = settings?.enablePowderSensitivity ?? false;

    final zeroKey    = _buildZeroKey(profile, usePowderSens);
    final cachedElev = listEquals(zeroKey, _lastZeroKey) ? _cachedZeroElevRad : null;

    _dirty = false;
    state  = const AsyncLoading();
    try {
      final (hitResult, freshZeroElev) = await compute(
        _runHomeCalculation,
        (profile, targetDistM, chartStepM, usePowderSens, cachedElev),
      );
      if (freshZeroElev != null) {
        _lastZeroKey       = zeroKey;
        _cachedZeroElevRad = freshZeroElev;
      }
      state = AsyncData(hitResult);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final homeCalculationProvider =
    AsyncNotifierProvider<HomeCalculationNotifier, HitResult?>(HomeCalculationNotifier.new);
