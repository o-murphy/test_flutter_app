import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/models/projectile.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/core/providers/profile_library_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';

// ── Display model ─────────────────────────────────────────────────────────────

class ProfileCardData {
  const ProfileCardData({
    required this.id,
    required this.name,
    required this.rifleName,
    required this.caliber,
    required this.twist,
    required this.twistDirection,
    required this.cartridgeName,
    required this.dragModel,
    required this.muzzleVelocity,
    required this.weight,
    required this.sightName,
  });

  final String id;
  final String name;

  // Rifle section
  final String rifleName;
  final String caliber;
  final String twist;
  final String twistDirection;

  // Cartridge section
  final String cartridgeName;
  final String dragModel;
  final String muzzleVelocity;
  final String weight;

  // Sight section
  final String sightName;
}

// ── State ─────────────────────────────────────────────────────────────────────

sealed class ProfilesUiState {
  const ProfilesUiState();
}

class ProfilesLoading extends ProfilesUiState {
  const ProfilesLoading();
}

class ProfilesReady extends ProfilesUiState {
  final List<ProfileCardData> profiles;
  final String? activeProfileId;

  const ProfilesReady({required this.profiles, this.activeProfileId});
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class ProfilesViewModel extends AsyncNotifier<ProfilesUiState> {
  @override
  Future<ProfilesUiState> build() async {
    final profiles = await ref.watch(profileLibraryProvider.future);
    final formatter = ref.read(unitFormatterProvider);
    // ref.read (not watch) — щоб зміна активного профілю не ініціювала
    // повний async rebuild з AsyncLoading → AsyncData, що спричиняє фліккер.
    // selectProfile() оновлює activeProfileId напряму через state = AsyncData(...).
    final activeProfileId = ref.read(shotProfileProvider).value?.id;
    return ProfilesReady(
      profiles: profiles.map((p) => _buildCardData(p, formatter)).toList(),
      activeProfileId: activeProfileId,
    );
  }

  ProfileCardData _buildCardData(ShotProfile profile, UnitFormatter fmt) {
    final proj = profile.cartridge.projectile;
    final bcAcc = FC.ballisticCoefficient.accuracy;
    final firstBc = proj.coefRows.isNotEmpty ? proj.coefRows.first.bcCd : 0.0;
    final dragModel = switch (proj.dragType) {
      DragModelType.g1 =>
        proj.isMultiBC ? 'G1 Multi' : 'G1 ${firstBc.toStringAsFixed(bcAcc)}',
      DragModelType.g7 =>
        proj.isMultiBC ? 'G7 Multi' : 'G7 ${firstBc.toStringAsFixed(bcAcc)}',
      DragModelType.custom => 'CUSTOM',
    };

    return ProfileCardData(
      id: profile.id,
      name: profile.name,
      rifleName: profile.rifle.name,
      caliber: fmt.diameter(profile.cartridge.projectile.diameter),
      twist: fmt.twist(profile.rifle.twist),
      twistDirection: profile.rifle.twist.raw > 0 ? 'right' : 'left',
      cartridgeName: profile.cartridge.name,
      dragModel: dragModel,
      muzzleVelocity: fmt.velocity(profile.cartridge.mv),
      weight: fmt.weight(profile.cartridge.projectile.weight),
      sightName: profile.sight.name,
    );
  }

  Future<void> selectProfile(String id) async {
    final profiles = ref.read(profileLibraryProvider).value ?? [];
    final profile = profiles.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('Profile $id not found'),
    );
    // Відновлює повний стан профілю (включно з runtime) і зберігає activeProfileId
    await ref.read(shotProfileProvider.notifier).selectProfile(profile);
    // Переміщуємо обраний профіль на першу позицію в бібліотеці
    await ref.read(profileLibraryProvider.notifier).moveToFirst(id);
    // Оновлюємо стан ViewModel без повного async rebuild
    final current = state.value;
    if (current is ProfilesReady) {
      final idx = current.profiles.indexWhere((p) => p.id == id);
      final reordered = idx > 0
          ? [
              current.profiles[idx],
              ...current.profiles.sublist(0, idx),
              ...current.profiles.sublist(idx + 1),
            ]
          : current.profiles;
      state = AsyncData(
        ProfilesReady(profiles: reordered, activeProfileId: id),
      );
    }
  }

  Future<void> removeProfile(String id) async {
    await ref.read(profileLibraryProvider.notifier).delete(id);
  }

  Future<void> saveProfile(ShotProfile profile) async {
    await ref.read(profileLibraryProvider.notifier).save(profile);
  }

  Future<void> importFromA7pBytes(List<int> bytes, {String? fileName}) async {
    // A7pParser works with a Payload parsed from bytes — this is handled
    // upstream (file picker → parse → call saveProfile).
    // This stub is intentionally empty; the screen invokes saveProfile directly
    // after parsing.
  }
}

final rifleSelectVmProvider =
    AsyncNotifierProvider<ProfilesViewModel, ProfilesUiState>(
      ProfilesViewModel.new,
    );
