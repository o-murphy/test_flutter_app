import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../src/models/shot_profile.dart';
import '../src/solver/calculator.dart';
import '../src/solver/trajectory_data.dart';
import '../src/solver/unit.dart';
import 'settings_provider.dart';
import 'shot_profile_provider.dart';

HitResult? _runCalculation((ShotProfile, double) args) {
  final (profile, stepM) = args;
  try {
    final calc = Calculator();
    final shot = profile.toShot();
    // TODO: use profile.zeroDistance once that field is added.
    calc.setWeaponZero(shot, Distance(100.0, Unit.meter));
    return calc.fire(
      shot: shot,
      trajectoryRange: Distance(2000.0, Unit.meter),
      trajectoryStep:  Distance(stepM,  Unit.meter),
    );
  } catch (_) {
    return null;
  }
}

class CalculationNotifier extends AsyncNotifier<HitResult?> {
  bool _dirty = true;

  @override
  Future<HitResult?> build() async {
    ref.listen(shotProfileProvider, (_, next) {
      if (next.hasValue) _dirty = true;
    });
    return null; // lazy — calculate only when requested
  }

  Future<void> recalculateIfNeeded() async {
    if (!_dirty) return;
    final profile = ref.read(shotProfileProvider).value;
    if (profile == null) return;
    final stepM = ref.read(settingsProvider).value?.tableDistanceStep ?? 100;
    _dirty = false;
    state = const AsyncLoading();
    state = AsyncData(await compute(_runCalculation, (profile, stepM)));
  }
}

final calculationProvider =
    AsyncNotifierProvider<CalculationNotifier, HitResult?>(CalculationNotifier.new);
