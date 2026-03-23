import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../src/models/app_settings.dart';
import '../src/models/cartridge.dart';
import '../src/models/rifle.dart';
import '../src/models/shot_profile.dart';
import '../src/models/sight.dart';
import 'app_storage.dart';

class JsonFileStorage implements AppStorage {
  JsonFileStorage._();
  static final JsonFileStorage instance = JsonFileStorage._();

  Future<Directory> get _dir async {
    final home = Platform.environment['HOME'] ?? (await getApplicationDocumentsDirectory()).path;
    final dir = Directory('$home/.eBalistyka');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _file(String name) async =>
      File('${(await _dir).path}/$name.json');

  // ── Generic helpers ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _readMap(String name) async {
    final f = await _file(name);
    if (!await f.exists()) return null;
    return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _readList(String name) async {
    final f = await _file(name);
    if (!await f.exists()) return [];
    final raw = jsonDecode(await f.readAsString()) as List;
    return raw.cast<Map<String, dynamic>>();
  }

  Future<void> _writeMap(String name, Map<String, dynamic> data) async =>
      (await _file(name)).writeAsString(jsonEncode(data));

  Future<void> _writeList(String name, List<Map<String, dynamic>> data) async =>
      (await _file(name)).writeAsString(jsonEncode(data));

  // ── Settings ───────────────────────────────────────────────────────────────

  @override
  Future<AppSettings?> loadSettings() async {
    final map = await _readMap('settings');
    return map == null ? null : AppSettings.fromJson(map);
  }

  @override
  Future<void> saveSettings(AppSettings s) => _writeMap('settings', s.toJson());

  // ── Current profile ────────────────────────────────────────────────────────

  @override
  Future<ShotProfile?> loadCurrentProfile() async {
    final map = await _readMap('profile');
    return map == null ? null : ShotProfile.fromJson(map);
  }

  @override
  Future<void> saveCurrentProfile(ShotProfile p) =>
      _writeMap('profile', p.toJson());

  // ── Rifles ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Rifle>> loadRifles() async =>
      (await _readList('rifles')).map(Rifle.fromJson).toList();

  @override
  Future<void> saveRifle(Rifle r) async {
    final list = await _readList('rifles');
    final idx = list.indexWhere((m) => m['id'] == r.id);
    if (idx >= 0) { list[idx] = r.toJson(); } else { list.add(r.toJson()); }
    await _writeList('rifles', list);
  }

  @override
  Future<void> deleteRifle(String id) async {
    final list = await _readList('rifles');
    list.removeWhere((m) => m['id'] == id);
    await _writeList('rifles', list);
  }

  // ── Cartridges ─────────────────────────────────────────────────────────────

  @override
  Future<List<Cartridge>> loadCartridges() async =>
      (await _readList('cartridges')).map(Cartridge.fromJson).toList();

  @override
  Future<void> saveCartridge(Cartridge c) async {
    final list = await _readList('cartridges');
    final idx = list.indexWhere((m) => m['id'] == c.id);
    if (idx >= 0) { list[idx] = c.toJson(); } else { list.add(c.toJson()); }
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
    if (idx >= 0) { list[idx] = s.toJson(); } else { list.add(s.toJson()); }
    await _writeList('sights', list);
  }

  @override
  Future<void> deleteSight(String id) async {
    final list = await _readList('sights');
    list.removeWhere((m) => m['id'] == id);
    await _writeList('sights', list);
  }

  // ── Export / Import ────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> exportAll() async => {
    'settings':   await _readMap('settings')  ?? {},
    'profile':    await _readMap('profile')   ?? {},
    'rifles':     await _readList('rifles'),
    'cartridges': await _readList('cartridges'),
    'sights':     await _readList('sights'),
  };

  @override
  Future<void> importAll(Map<String, dynamic> data) async {
    if (data['settings']   case Map<String, dynamic> s) await _writeMap('settings', s);
    if (data['profile']    case Map<String, dynamic> p) await _writeMap('profile', p);
    if (data['rifles']     case List r) await _writeList('rifles', r.cast());
    if (data['cartridges'] case List c) await _writeList('cartridges', c.cast());
    if (data['sights']     case List s) await _writeList('sights', s.cast());
  }
}
