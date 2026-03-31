import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/models/seed_data.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'storage_provider.dart';

class ProfileLibraryNotifier extends AsyncNotifier<List<ShotProfile>> {
  @override
  Future<List<ShotProfile>> build() async {
    final profiles = await ref.read(appStorageProvider).loadProfiles();
    if (profiles.isEmpty) {
      await ref.read(appStorageProvider).saveProfile(seedShotProfile);
      return [seedShotProfile];
    }
    return profiles;
  }

  Future<void> save(ShotProfile p) async {
    await ref.read(appStorageProvider).saveProfile(p);
    state = AsyncData([
      for (final item in (state.value ?? []))
        if (item.id == p.id) p else item,
      if (!(state.value ?? []).any((item) => item.id == p.id)) p,
    ]);
  }

  Future<void> delete(String id) async {
    await ref.read(appStorageProvider).deleteProfile(id);
    state = AsyncData((state.value ?? []).where((p) => p.id != id).toList());
  }
}

final profileLibraryProvider =
    AsyncNotifierProvider<ProfileLibraryNotifier, List<ShotProfile>>(
      ProfileLibraryNotifier.new,
    );
