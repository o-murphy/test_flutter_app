import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/domain/ballistics_service.dart';
import 'package:eballistica/src/models/shot_profile.dart';
import 'package:eballistica/src/solver/trajectory_data.dart';
import 'package:eballistica/src/solver/unit.dart';
import 'service_providers.dart';
import 'settings_provider.dart';
import 'shot_profile_provider.dart';

// Re-export so existing consumers keep working.
export 'package:eballistica/services/ballistics_service_impl.dart'
    show CalculationException;

// ── Zero fingerprint ─────────────────────────────────────────────────────────
//
// All inputs that affect setWeaponZero. Flat List<double> — equality via
// listEquals, no hashCode overrides needed on domain objects.

List<double> _buildZeroKey(ShotProfile profile, bool usePowderSens) {
  final zeroAtmo = profile.zeroConditions ?? profile.conditions;
  final w = profile.rifle.weapon;
  final c = profile.cartridge;
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

// ── Table calculation notifier ───────────────────────────────────────────────

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
    final settings = ref.read(settingsProvider).value;
    final tableStep = settings?.tableConfig.stepM ?? 100.0;
    final stepM = tableStep < 1.0 ? tableStep : 1.0;
    final usePowderSens = settings?.enablePowderSensitivity ?? false;

    final zeroKey = _buildZeroKey(profile, usePowderSens);
    final cachedElev =
        listEquals(zeroKey, _lastZeroKey) ? _cachedZeroElevRad : null;

    _dirty = false;
    state = const AsyncLoading();
    try {
      final service = ref.read(ballisticsServiceProvider);
      final result = await service.calculateTable(
        profile,
        TableCalcOptions(stepM: stepM, usePowderSensitivity: usePowderSens),
        cachedZeroElevRad: cachedElev,
      );
      if (cachedElev == null) {
        _lastZeroKey = zeroKey;
        _cachedZeroElevRad = result.zeroElevationRad;
      }
      state = AsyncData(result.hitResult);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final tableCalculationProvider =
    AsyncNotifierProvider<TableCalculationNotifier, HitResult?>(
        TableCalculationNotifier.new);

// ── Home calculation notifier ────────────────────────────────────────────────

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
    final settings = ref.read(settingsProvider).value;
    final targetDistM = profile.targetDistance.in_(Unit.meter);
    final chartStepM = settings?.chartDistanceStep ?? 100.0;
    final usePowderSens = settings?.enablePowderSensitivity ?? false;

    final zeroKey = _buildZeroKey(profile, usePowderSens);
    final cachedElev =
        listEquals(zeroKey, _lastZeroKey) ? _cachedZeroElevRad : null;

    _dirty = false;
    state = const AsyncLoading();
    try {
      final service = ref.read(ballisticsServiceProvider);
      final result = await service.calculateForTarget(
        profile,
        TargetCalcOptions(
          targetDistM: targetDistM,
          chartStepM: chartStepM,
          usePowderSensitivity: usePowderSens,
        ),
        cachedZeroElevRad: cachedElev,
      );
      if (cachedElev == null) {
        _lastZeroKey = zeroKey;
        _cachedZeroElevRad = result.zeroElevationRad;
      }
      state = AsyncData(result.hitResult);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final homeCalculationProvider =
    AsyncNotifierProvider<HomeCalculationNotifier, HitResult?>(
        HomeCalculationNotifier.new);
