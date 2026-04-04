import 'dart:convert';
import 'dart:io';

import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/models/convertors_state.dart';
import 'package:path_provider/path_provider.dart';

import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/sight.dart';
import 'app_storage.dart';

/// Custom exception for storage errors
class StorageException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  StorageException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() =>
      'StorageException: $message${originalError != null ? ' (${originalError.runtimeType}: $originalError)' : ''}';
}

class JsonFileStorage implements AppStorage {
  JsonFileStorage._();
  static final JsonFileStorage instance = JsonFileStorage._();

  Future<Directory> get _dir async {
    final home =
        Platform.environment['HOME'] ??
        (await getApplicationDocumentsDirectory()).path;
    final dir = Directory('$home/.eBalistyka');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _file(String name) async =>
      File('${(await _dir).path}/$name.json');

  // ── Generic helpers ────────────────────────────────────────────────────────

  /// Safely reads a JSON file and returns a map, or null if file doesn't exist.
  /// Throws StorageException on JSON decode errors or IO failures.
  Future<Map<String, dynamic>?> _readMap(String name) async {
    try {
      final f = await _file(name);
      if (!await f.exists()) return null;

      final content = await f.readAsString();
      final decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        throw StorageException(
          'Invalid JSON structure in $name: expected Map, got ${decoded.runtimeType}',
        );
      }
      return decoded;
    } on FileSystemException catch (e, st) {
      throw StorageException('Failed to read file $name: ${e.message}', e, st);
    } on FormatException catch (e, st) {
      throw StorageException('Corrupted JSON in $name: ${e.message}', e, st);
    } catch (e, st) {
      throw StorageException('Unexpected error reading $name', e, st);
    }
  }

  /// Safely reads a JSON file and returns a list of maps.
  /// Returns empty list if file doesn't exist. Throws StorageException on errors.
  Future<List<Map<String, dynamic>>> _readList(String name) async {
    try {
      final f = await _file(name);
      if (!await f.exists()) return [];

      final content = await f.readAsString();
      final decoded = jsonDecode(content);

      if (decoded is! List) {
        throw StorageException(
          'Invalid JSON structure in $name: expected List, got ${decoded.runtimeType}',
        );
      }

      // Validate each element is a map
      final result = <Map<String, dynamic>>[];
      for (int i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is! Map<String, dynamic>) {
          throw StorageException(
            'Invalid item at index $i in $name: expected Map, got ${item.runtimeType}',
          );
        }
        result.add(item);
      }
      return result;
    } on FileSystemException catch (e, st) {
      throw StorageException('Failed to read file $name: ${e.message}', e, st);
    } on FormatException catch (e, st) {
      throw StorageException('Corrupted JSON in $name: ${e.message}', e, st);
    } catch (e, st) {
      if (e is StorageException) rethrow;
      throw StorageException('Unexpected error reading list from $name', e, st);
    }
  }

  Future<void> _writeMap(String name, Map<String, dynamic> data) async {
    try {
      await (await _file(name)).writeAsString(jsonEncode(data));
    } on FileSystemException catch (e, st) {
      throw StorageException('Failed to write file $name: ${e.message}', e, st);
    } catch (e, st) {
      throw StorageException('Unexpected error writing $name', e, st);
    }
  }

  Future<void> _writeList(String name, List<Map<String, dynamic>> data) async {
    try {
      await (await _file(name)).writeAsString(jsonEncode(data));
    } on FileSystemException catch (e, st) {
      throw StorageException('Failed to write file $name: ${e.message}', e, st);
    } catch (e, st) {
      throw StorageException('Unexpected error writing list to $name', e, st);
    }
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  @override
  Future<AppSettings?> loadSettings() async {
    final map = await _readMap('settings');
    return map == null ? null : AppSettings.fromJson(map);
  }

  @override
  Future<void> saveSettings(AppSettings s) => _writeMap('settings', s.toJson());

  // ── Conditions ─────────────────────────────────────────────────────────────

  @override
  Future<Conditions?> loadConditions() async {
    final map = await _readMap('conditions');
    return map == null ? null : Conditions.fromJson(map);
  }

  @override
  Future<void> saveConditions(Conditions c) =>
      _writeMap('conditions', c.toJson());

  // ── Cartridges ─────────────────────────────────────────────────────────────

  @override
  Future<List<Cartridge>> loadCartridges() async =>
      (await _readList('cartridges')).map(Cartridge.fromJson).toList();

  @override
  Future<void> saveCartridge(Cartridge c) async {
    final list = await _readList('cartridges');
    final idx = list.indexWhere((m) => m['id'] == c.id);
    if (idx >= 0) {
      list[idx] = c.toJson();
    } else {
      list.add(c.toJson());
    }
    await _writeList('cartridges', list);
  }

  @override
  Future<void> deleteCartridge(String id) async {
    final list = await _readList('cartridges');
    list.removeWhere((m) => m['id'] == id);
    await _writeList('cartridges', list);
  }

  // ── Sights ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Sight>> loadSights() async =>
      (await _readList('sights')).map(Sight.fromJson).toList();

  @override
  Future<void> saveSight(Sight s) async {
    final list = await _readList('sights');
    final idx = list.indexWhere((m) => m['id'] == s.id);
    if (idx >= 0) {
      list[idx] = s.toJson();
    } else {
      list.add(s.toJson());
    }
    await _writeList('sights', list);
  }

  @override
  Future<void> deleteSight(String id) async {
    final list = await _readList('sights');
    list.removeWhere((m) => m['id'] == id);
    await _writeList('sights', list);
  }

  // ── Profile library ────────────────────────────────────────────────────────
  // profiles.json format: {"activeProfileId": "...", "profiles": [...]}
  // Backward-compat: if file contains a plain array, treat as profiles with no active ID.

  Future<(List<Map<String, dynamic>>, String?)> _readProfilesFile() async {
    try {
      final f = await _file('profiles');
      if (!await f.exists()) return (<Map<String, dynamic>>[], null);
      final content = await f.readAsString();
      if (content.trim().isEmpty) return (<Map<String, dynamic>>[], null);
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        final list = ((decoded['profiles'] as List?) ?? [])
            .cast<Map<String, dynamic>>();
        final activeId = decoded['activeProfileId'] as String?;
        return (list, activeId);
      }
      if (decoded is List) {
        // Old plain-array format
        return (decoded.cast<Map<String, dynamic>>(), null);
      }
      return (<Map<String, dynamic>>[], null);
    } on StorageException {
      rethrow;
    } catch (e, st) {
      throw StorageException('Failed to read profiles.json', e, st);
    }
  }

  Future<void> _writeProfilesFile(
    List<Map<String, dynamic>> profiles,
    String? activeProfileId,
  ) => _writeMap('profiles', {
    'activeProfileId': activeProfileId,
    'profiles': profiles,
  });

  @override
  Future<String?> loadActiveProfileId() async {
    final (_, activeId) = await _readProfilesFile();
    return activeId;
  }

  @override
  Future<void> saveActiveProfileId(String id) async {
    final (profiles, _) = await _readProfilesFile();
    await _writeProfilesFile(profiles, id);
  }

  @override
  Future<List<ShotProfile>> loadProfiles() async {
    final (list, _) = await _readProfilesFile();
    return list.map(ShotProfile.fromJson).toList();
  }

  @override
  Future<void> saveProfile(ShotProfile p) async {
    final (list, activeId) = await _readProfilesFile();
    final idx = list.indexWhere((m) => m['id'] == p.id);
    if (idx >= 0) {
      list[idx] = p.toJson();
    } else {
      list.add(p.toJson());
    }
    await _writeProfilesFile(list, activeId);
  }

  @override
  Future<void> saveProfilesOrdered(List<ShotProfile> profiles) async {
    final (_, activeId) = await _readProfilesFile();
    await _writeProfilesFile(
      profiles.map((p) => p.toJson()).toList(),
      activeId,
    );
  }

  @override
  Future<void> deleteProfile(String id) async {
    final (list, activeId) = await _readProfilesFile();
    list.removeWhere((m) => m['id'] == id);
    await _writeProfilesFile(list, activeId);
  }

  // ── Built-in collection cache ──────────────────────────────────────────────

  @override
  Future<String?> loadCollectionJson() async {
    final f = await _file('collection');
    if (!await f.exists()) return null;
    return f.readAsString();
  }

  @override
  Future<void> saveCollectionJson(String json) async {
    await (await _file('collection')).writeAsString(json);
  }

  // ── Convertors State ─────────────────────────────────────────────────────────

  @override
  Future<ConvertorsState?> loadConvertorsState() async {
    try {
      final map = await _readMap('convertors');
      if (map == null) return null;

      return ConvertorsState.fromJson(map);
    } on StorageException {
      rethrow;
    } catch (e, st) {
      throw StorageException('Failed to load convertors state', e, st);
    }
  }

  @override
  Future<void> saveConvertorsState(ConvertorsState state) async {
    try {
      await _writeMap('convertors', state.toJson());
    } on StorageException {
      rethrow;
    } catch (e, st) {
      throw StorageException('Failed to save convertors state', e, st);
    }
  }

  // ── Export / Import ────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> exportAll() async {
    final (profilesList, activeProfileId) = await _readProfilesFile();
    return {
      'settings': await _readMap('settings') ?? {},
      'conditions': await _readMap('conditions') ?? {},
      'cartridges': await _readList('cartridges'),
      'sights': await _readList('sights'),
      'activeProfileId': activeProfileId,
      'profiles': profilesList,
      'convertors': await _readMap('convertors') ?? {},
    };
  }

  @override
  Future<void> importAll(Map<String, dynamic> data) async {
    try {
      // Validate and write each section with proper type checking
      if (data.containsKey('settings')) {
        final s = data['settings'];
        if (s is! Map<String, dynamic>) {
          throw StorageException(
            'Invalid settings: expected Map, got ${s.runtimeType}',
          );
        }
        await _writeMap('settings', s);
      }

      if (data.containsKey('conditions')) {
        final s = data['conditions'];
        if (s is! Map<String, dynamic>) {
          throw StorageException(
            'Invalid conditions: expected Map, got ${s.runtimeType}',
          );
        }
        await _writeMap('settings', s);
      }

      if (data.containsKey('cartridges')) {
        final c = data['cartridges'];
        if (c is! List) {
          throw StorageException(
            'Invalid cartridges: expected List, got ${c.runtimeType}',
          );
        }
        final cartridges = <Map<String, dynamic>>[];
        for (int i = 0; i < c.length; i++) {
          final item = c[i];
          if (item is! Map<String, dynamic>) {
            throw StorageException(
              'Invalid cartridge at index $i: expected Map, got ${item.runtimeType}',
            );
          }
          cartridges.add(item);
        }
        await _writeList('cartridges', cartridges);
      }

      if (data.containsKey('sights')) {
        final s = data['sights'];
        if (s is! List) {
          throw StorageException(
            'Invalid sights: expected List, got ${s.runtimeType}',
          );
        }
        final sights = <Map<String, dynamic>>[];
        for (int i = 0; i < s.length; i++) {
          final item = s[i];
          if (item is! Map<String, dynamic>) {
            throw StorageException(
              'Invalid sight at index $i: expected Map, got ${item.runtimeType}',
            );
          }
          sights.add(item);
        }
        await _writeList('sights', sights);
      }

      if (data.containsKey('profiles')) {
        final p = data['profiles'];
        if (p is! List) {
          throw StorageException(
            'Invalid profiles: expected List, got ${p.runtimeType}',
          );
        }
        final profiles = <Map<String, dynamic>>[];
        for (int i = 0; i < p.length; i++) {
          final item = p[i];
          if (item is! Map<String, dynamic>) {
            throw StorageException(
              'Invalid profile at index $i: expected Map, got ${item.runtimeType}',
            );
          }
          profiles.add(item);
        }
        final activeId = data['activeProfileId'] as String?;
        await _writeProfilesFile(profiles, activeId);
      }

      // Додаємо імпорт для convertors
      if (data.containsKey('convertors') && data['convertors'] != null) {
        final c = data['convertors'];
        if (c is! Map<String, dynamic>) {
          throw StorageException(
            'Invalid convertors: expected Map, got ${c.runtimeType}',
          );
        }
        try {
          ConvertorsState.fromJson(c); // Валідація
          await _writeMap('convertors', c);
        } catch (e) {
          throw StorageException('Invalid convertors state format: $e');
        }
      }
    } catch (e, st) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to import data', e, st);
    }
  }
}
