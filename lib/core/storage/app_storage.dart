import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/sight.dart';

abstract interface class AppStorage {
  // Settings
  Future<AppSettings?> loadSettings();
  Future<void> saveSettings(AppSettings s);

  // Current profile
  Future<ShotProfile?> loadCurrentProfile();
  Future<void> saveCurrentProfile(ShotProfile p);

  // Rifles
  Future<List<Rifle>> loadRifles();
  Future<void> saveRifle(Rifle r);
  Future<void> deleteRifle(String id);

  // Cartridges
  Future<List<Cartridge>> loadCartridges();
  Future<void> saveCartridge(Cartridge c);
  Future<void> deleteCartridge(String id);

  // Sights
  Future<List<Sight>> loadSights();
  Future<void> saveSight(Sight s);
  Future<void> deleteSight(String id);

  // Profile library
  Future<List<ShotProfile>> loadProfiles();
  Future<void> saveProfile(ShotProfile p);
  Future<void> deleteProfile(String id);

  // Import / Export
  Future<Map<String, dynamic>> exportAll();
  Future<void> importAll(Map<String, dynamic> data);
}
