import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/seed_data.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/sight.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'storage_provider.dart';

class ShotProfileNotifier extends AsyncNotifier<ShotProfile> {
  @override
  Future<ShotProfile> build() async {
    final loaded =
        await ref.read(appStorageProvider).loadCurrentProfile() ??
        seedShotProfile;
    // Clamp look angle to ±45° — corrupted values (e.g. from old wind-wheel
    // bug that wrote wind direction into lookAngle) cause zero-finding to fail.
    final laDeg = (loaded.lookAngle).in_(Unit.degree);
    if (laDeg.abs() > 45) {
      return loaded.copyWith(lookAngle: Angular(0.0, Unit.degree));
    }
    return loaded;
  }

  Future<void> selectRifle(Rifle r) => _update((p) => p.copyWith(rifle: r));

  Future<void> selectSight(Sight s) => _update((p) => p.copyWith(sight: s));

  Future<void> selectCartridge(Cartridge c) =>
      _update((p) => p.copyWith(cartridge: c));

  Future<void> updateConditions(AtmoData atmo) =>
      _update((p) => p.copyWith(conditions: atmo));

  Future<void> updateWinds(List<WindData> winds) =>
      _update((p) => p.copyWith(winds: winds));

  Future<void> updateLookAngle(double degrees) =>
      _update((p) => p.copyWith(lookAngle: Angular(degrees, Unit.degree)));

  Future<void> updateTargetDistance(double meters) =>
      _update((p) => p.copyWith(targetDistance: Distance(meters, Unit.meter)));

  Future<void> updateZeroDistance(double meters) =>
      _update((p) => p.copyWith(zeroDistance: Distance(meters, Unit.meter)));

  Future<void> updateZeroConditions(AtmoData? atmo) => _update(
    (p) => atmo != null
        ? p.copyWith(zeroConditions: atmo)
        : p.copyWith(clearZeroConditions: true),
  );

  Future<void> updateUsePowderSensitivity(bool value) =>
      _update((p) => p.copyWith(usePowderSensitivity: value));

  Future<void> updateUseDiffPowderTemp(bool value) =>
      _update((p) => p.copyWith(useDiffPowderTemp: value));

  Future<void> updateZeroUsePowderSensitivity(bool? value) => _update(
    (p) => value != null
        ? p.copyWith(zeroUsePowderSensitivity: value)
        : p.copyWith(clearZeroUsePowderSensitivity: true),
  );

  Future<void> updateZeroUseDiffPowderTemp(bool value) =>
      _update((p) => p.copyWith(zeroUseDiffPowderTemp: value));

  Future<void> updateWindSpeed(double mps) => _update((p) {
    final existing = p.winds;
    final dir = existing.isNotEmpty
        ? existing.first.directionFrom
        : Angular(0.0, Unit.degree);
    final until = existing.isNotEmpty
        ? existing.first.untilDistance
        : Distance(9999.0, Unit.meter);
    return p.copyWith(
      winds: [
        WindData(
          velocity: Velocity(mps, Unit.mps),
          directionFrom: dir,
          untilDistance: until,
        ),
      ],
    );
  });

  /// Applies all ballistic-profile fields from [template] while keeping the
  /// current runtime state (conditions, winds, lookAngle, targetDistance).
  Future<void> selectProfile(ShotProfile template) => _update((current) {
    ShotProfile next = current.copyWith(
      name: template.name,
      rifle: template.rifle,
      sight: template.sight,
      cartridge: template.cartridge,
      zeroDistance: template.zeroDistance,
      zeroConditions: template.zeroConditions,
      usePowderSensitivity: template.usePowderSensitivity,
      useDiffPowderTemp: template.useDiffPowderTemp,
      zeroUseDiffPowderTemp: template.zeroUseDiffPowderTemp,
    );
    final zeroUsePowderSens = template.zeroUsePowderSensitivity;
    if (zeroUsePowderSens != null) {
      next = next.copyWith(zeroUsePowderSensitivity: zeroUsePowderSens);
    } else {
      next = next.copyWith(clearZeroUsePowderSensitivity: true);
    }
    return next;
  });

  Future<void> _update(ShotProfile Function(ShotProfile) fn) async {
    final current = state.value ?? seedShotProfile;
    final updated = fn(current);
    state = AsyncData(updated);
    await ref.read(appStorageProvider).saveCurrentProfile(updated);
  }
}

final shotProfileProvider =
    AsyncNotifierProvider<ShotProfileNotifier, ShotProfile>(
      ShotProfileNotifier.new,
    );
