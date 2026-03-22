import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../src/models/app_settings.dart';
import '../src/models/unit_settings.dart';
import '../src/solver/unit.dart';
import 'storage_provider.dart';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final storage = ref.read(appStorageProvider);
    return await storage.loadSettings() ?? const AppSettings();
  }

  Future<void> setUnit(String key, Unit unit) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(
      units: _setUnitByKey(current.units, key, unit),
    );
    await _save(updated);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _save((state.value ?? const AppSettings()).copyWith(themeMode: mode));
  }

  Future<void> setLanguage(String code) async {
    await _save((state.value ?? const AppSettings()).copyWith(languageCode: code));
  }

  Future<void> setSwitch(String key, bool value) async {
    final s = state.value ?? const AppSettings();
    await _save(switch (key) {
      'coriolis'               => s.copyWith(enableCoriolis: value),
      'powderSensitivity'      => s.copyWith(enablePowderSensitivity: value),
      'derivation'             => s.copyWith(enableDerivation: value),
      'aerodynamicJump'        => s.copyWith(enableAerodynamicJump: value),
      'pressureFromAltitude'   => s.copyWith(pressureDependsOnAltitude: value),
      'subsonicTransition'     => s.copyWith(showSubsonicTransition: value),
      _                        => s,
    });
  }

  Future<void> setTableDistanceStep(double step) async {
    await _save((state.value ?? const AppSettings()).copyWith(tableDistanceStep: step));
  }

  Future<void> setChartDistanceStep(double step) async {
    await _save((state.value ?? const AppSettings()).copyWith(chartDistanceStep: step));
  }

  Future<void> _save(AppSettings s) async {
    state = AsyncData(s);
    await ref.read(appStorageProvider).saveSettings(s);
  }

  UnitSettings _setUnitByKey(UnitSettings u, String key, Unit unit) =>
      switch (key) {
        'angular'     => u.copyWith(angular: unit),
        'distance'    => u.copyWith(distance: unit),
        'velocity'    => u.copyWith(velocity: unit),
        'pressure'    => u.copyWith(pressure: unit),
        'temperature' => u.copyWith(temperature: unit),
        'diameter'    => u.copyWith(diameter: unit),
        'length'      => u.copyWith(length: unit),
        'weight'      => u.copyWith(weight: unit),
        'adjustment'  => u.copyWith(adjustment: unit),
        'drop'        => u.copyWith(drop: unit),
        'energy'      => u.copyWith(energy: unit),
        'sightHeight' => u.copyWith(sightHeight: unit),
        'twist'       => u.copyWith(twist: unit),
        'time'        => u.copyWith(time: unit),
        _             => u,
      };
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Synchronous access — returns defaults while loading.
final unitSettingsProvider = Provider<UnitSettings>((ref) {
  return ref.watch(settingsProvider).value?.units ?? const UnitSettings();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).value?.themeMode ?? ThemeMode.system;
});
