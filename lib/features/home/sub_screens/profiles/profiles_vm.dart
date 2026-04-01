import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/providers/profile_library_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class ProfilesUiState {
  const ProfilesUiState();
}

class ProfilesLoading extends ProfilesUiState {
  const ProfilesLoading();
}

class ProfilesReady extends ProfilesUiState {
  final List<ShotProfile> profiles;
  final String? activeProfileId;

  const ProfilesReady({required this.profiles, this.activeProfileId});
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class ProfilesViewModel extends AsyncNotifier<ProfilesUiState> {
  @override
  Future<ProfilesUiState> build() async {
    final profiles = await ref.watch(profileLibraryProvider.future);
    final activeProfile = ref.watch(shotProfileProvider).value;
    return ProfilesReady(
      profiles: profiles,
      activeProfileId: activeProfile?.id,
    );
  }

  Future<void> selectProfile(String id) async {
    final profiles = ref.read(profileLibraryProvider).value ?? [];
    final profile = profiles.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('Profile $id not found'),
    );
    await ref.read(shotProfileProvider.notifier).selectProfile(profile);
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
