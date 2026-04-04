import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/models/convertors_state.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/sight.dart';

abstract interface class AppStorage {
  // Settings
  Future<AppSettings?> loadSettings();
  Future<void> saveSettings(AppSettings s);

  // Conditions
  Future<Conditions?> loadConditions();
  Future<void> saveConditions(Conditions c);

  // Cartridges
  Future<List<Cartridge>> loadCartridges();
  Future<void> saveCartridge(Cartridge c);
  Future<void> deleteCartridge(String id);

  // Sights
  Future<List<Sight>> loadSights();
  Future<void> saveSight(Sight s);
  Future<void> deleteSight(String id);

  // Profile library  (profiles.json stores {activeProfileId, profiles:[...]})
  Future<String?> loadActiveProfileId();
  Future<void> saveActiveProfileId(String id);
  Future<List<ShotProfile>> loadProfiles();
  Future<void> saveProfile(ShotProfile p);
  Future<void> saveProfilesOrdered(List<ShotProfile> profiles);
  Future<void> deleteProfile(String id);

  // Built-in collection cache (collection.json downloaded from network)
  Future<String?> loadCollectionJson();
  Future<void> saveCollectionJson(String json);

  // Convertors State
  Future<ConvertorsState?> loadConvertorsState();
  Future<void> saveConvertorsState(ConvertorsState state);

  // Import / Export
  Future<Map<String, dynamic>> exportAll();
  Future<void> importAll(Map<String, dynamic> data);
}
