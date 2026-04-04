import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/seed_data.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/sight.dart';
import 'library_provider.dart';
import 'profile_library_provider.dart';
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

    return _resolve(loaded);
  }

  // ── Resolve cartridge/sight з бібліотеки ──────────────────────────────────

  Future<ShotProfile> _resolve(ShotProfile profile) async {
    final storage = ref.read(appStorageProvider);

    // Якщо cartridge вже вбудований (backward-compat або seed) — зберегти у бібліотеці.
    Cartridge? cartridge = profile.cartridge;
    String? cartridgeId = profile.cartridgeId;

    if (cartridge != null && cartridgeId != null) {
      // Inline cartridge з backward-compat fromJson або seed: зберегти у бібліотеку,
      // щоб далі воно було доступне через cartridgeLibraryProvider.
      await storage.saveCartridge(cartridge);
      await ref.read(cartridgeLibraryProvider.notifier).save(cartridge);
    } else if (cartridgeId != null) {
      // Стандартний шлях: lookup по id.
      final cartridges = await storage.loadCartridges();
      final found = cartridges.where((c) => c.id == cartridgeId);
      if (found.isNotEmpty) {
        cartridge = found.first;
      } else {
        // Broken ref → обнуляємо id
        cartridgeId = null;
        cartridge = null;
        // TODO: show toast "Cartridge not found, please select again"
      }
    }

    // Sight
    Sight? sight = profile.sight;
    String? sightId = profile.sightId;

    if (sight != null && sightId != null) {
      await storage.saveSight(sight);
      await ref.read(sightLibraryProvider.notifier).save(sight);
    } else if (sightId != null) {
      final sights = await storage.loadSights();
      final found = sights.where((s) => s.id == sightId);
      if (found.isNotEmpty) {
        sight = found.first;
      } else {
        sightId = null;
        sight = null;
        // TODO: show toast "Sight not found, please select again"
      }
    }

    // Якщо refs змінились — зберегти оновлений профіль (без inline об'єктів)
    if (cartridgeId != profile.cartridgeId || sightId != profile.sightId) {
      final cleaned = ShotProfile(
        id: profile.id,
        name: profile.name,
        rifle: profile.rifle,
        cartridgeId: cartridgeId,
        cartridge: cartridge,
        sightId: sightId,
        sight: sight,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );
      await storage.saveProfile(cleaned);
      await ref.read(profileLibraryProvider.notifier).save(cleaned);
      return cleaned;
    }

    return ShotProfile(
      id: profile.id,
      name: profile.name,
      rifle: profile.rifle,
      cartridgeId: cartridgeId,
      cartridge: cartridge,
      sightId: sightId,
      sight: sight,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> selectRifle(Rifle r) => _update((p) => p.copyWith(rifle: r));

  Future<void> selectSight(Sight s) => _update((p) => p.copyWith(sight: s));

  Future<void> selectCartridge(Cartridge c) =>
      _update((p) => p.copyWith(cartridge: c));

  /// Switches to [profile], restoring its own stored runtime state.
  Future<void> selectProfile(ShotProfile profile) async {
    final resolved = await _resolve(profile);
    state = AsyncData(resolved);
    await ref.read(appStorageProvider).saveActiveProfileId(resolved.id);
  }

  Future<void> _update(ShotProfile Function(ShotProfile) fn) async {
    final current = state.value ?? seedShotProfile;
    final updated = fn(current);
    state = AsyncData(updated);
    await ref.read(appStorageProvider).saveProfile(updated);
    // Sync profileLibraryProvider in-memory state so switching profiles
    // restores the latest runtime state (conditions, winds, etc.)
    await ref.read(profileLibraryProvider.notifier).save(updated);
  }
}

final shotProfileProvider =
    AsyncNotifierProvider<ShotProfileNotifier, ShotProfile>(
      ShotProfileNotifier.new,
    );
