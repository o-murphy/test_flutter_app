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
    final storage = ref.read(appStorageProvider);
    final activeId = await storage.loadActiveProfileId();
    final profiles = await storage.loadProfiles();

    ShotProfile loaded;
    if (activeId != null) {
      final matches = profiles.where((p) => p.id == activeId);
      loaded = matches.isNotEmpty
          ? matches.first
          : (profiles.isNotEmpty ? profiles.first : seedShotProfile);
    } else {
      loaded = profiles.isNotEmpty ? profiles.first : seedShotProfile;
    }

    // Clamp look angle to ±45° — corrupted values cause zero-finding to fail.
    final laDeg = loaded.lookAngle.in_(Unit.degree);
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

  /// Switches to [profile], restoring its own stored runtime state.
  Future<void> selectProfile(ShotProfile profile) async {
    state = AsyncData(profile);
    await ref.read(appStorageProvider).saveActiveProfileId(profile.id);
  }

  Future<void> _update(ShotProfile Function(ShotProfile) fn) async {
    final current = state.value ?? seedShotProfile;
    final updated = fn(current);
    state = AsyncData(updated);
    // Persists runtime state changes into the profile's entry in profiles.json
    await ref.read(appStorageProvider).saveProfile(updated);
  }
}

final shotProfileProvider =
    AsyncNotifierProvider<ShotProfileNotifier, ShotProfile>(
      ShotProfileNotifier.new,
    );
