import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/seed_data.dart';
import 'package:eballistica/core/models/sight.dart';
import 'storage_provider.dart';

// ── Rifles ────────────────────────────────────────────────────────────────────

class RifleLibraryNotifier extends AsyncNotifier<List<Rifle>> {
  @override
  Future<List<Rifle>> build() async {
    final rifles = await ref.read(appStorageProvider).loadRifles();
    if (rifles.isEmpty) {
      await ref.read(appStorageProvider).saveRifle(seedRifle);
      return [seedRifle];
    }
    return rifles;
  }

  Future<void> save(Rifle r) async {
    await ref.read(appStorageProvider).saveRifle(r);
    state = AsyncData([
      for (final item in (state.value ?? [])) if (item.id == r.id) r else item,
      if (!(state.value ?? []).any((item) => item.id == r.id)) r,
    ]);
  }

  Future<void> delete(String id) async {
    await ref.read(appStorageProvider).deleteRifle(id);
    state = AsyncData((state.value ?? []).where((r) => r.id != id).toList());
  }
}

final rifleLibraryProvider =
    AsyncNotifierProvider<RifleLibraryNotifier, List<Rifle>>(RifleLibraryNotifier.new);

// ── Sights ────────────────────────────────────────────────────────────────────

class SightLibraryNotifier extends AsyncNotifier<List<Sight>> {
  @override
  Future<List<Sight>> build() async {
    final sights = await ref.read(appStorageProvider).loadSights();
    if (sights.isEmpty) {
      await ref.read(appStorageProvider).saveSight(seedSight);
      return [seedSight];
    }
    return sights;
  }

  Future<void> save(Sight s) async {
    await ref.read(appStorageProvider).saveSight(s);
    state = AsyncData([
      for (final item in (state.value ?? [])) if (item.id == s.id) s else item,
      if (!(state.value ?? []).any((item) => item.id == s.id)) s,
    ]);
  }

  Future<void> delete(String id) async {
    await ref.read(appStorageProvider).deleteSight(id);
    state = AsyncData((state.value ?? []).where((s) => s.id != id).toList());
  }
}

final sightLibraryProvider =
    AsyncNotifierProvider<SightLibraryNotifier, List<Sight>>(SightLibraryNotifier.new);

// ── Cartridges ────────────────────────────────────────────────────────────────

class CartridgeLibraryNotifier extends AsyncNotifier<List<Cartridge>> {
  @override
  Future<List<Cartridge>> build() async {
    final cartridges = await ref.read(appStorageProvider).loadCartridges();
    if (cartridges.isEmpty) {
      for (final c in seedCartridges) {
        await ref.read(appStorageProvider).saveCartridge(c);
      }
      return seedCartridges;
    }
    return cartridges;
  }

  Future<void> save(Cartridge c) async {
    await ref.read(appStorageProvider).saveCartridge(c);
    state = AsyncData([
      for (final item in (state.value ?? [])) if (item.id == c.id) c else item,
      if (!(state.value ?? []).any((item) => item.id == c.id)) c,
    ]);
  }

  Future<void> delete(String id) async {
    await ref.read(appStorageProvider).deleteCartridge(id);
    state = AsyncData((state.value ?? []).where((c) => c.id != id).toList());
  }
}

final cartridgeLibraryProvider =
    AsyncNotifierProvider<CartridgeLibraryNotifier, List<Cartridge>>(CartridgeLibraryNotifier.new);
