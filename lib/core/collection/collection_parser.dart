import 'dart:convert';

import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/projectile.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/sight.dart';
import 'package:eballistica/core/solver/unit.dart';

class BuiltinCollection {
  final List<Rifle> rifles;
  final List<Cartridge> cartridges;
  final List<Projectile> projectiles;
  final List<Sight> sights;

  const BuiltinCollection({
    required this.rifles,
    required this.cartridges,
    required this.projectiles,
    required this.sights,
  });

  static const empty = BuiltinCollection(
    rifles: [],
    cartridges: [],
    projectiles: [],
    sights: [],
  );
}

abstract final class CollectionParser {
  static BuiltinCollection parse(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;

    // calibers lookup: id → diameter in inches
    // collection.json uses both "diameter" and "caliber" keys (inconsistency in dev file)
    final calibers = <int, double>{};
    for (final c in (map['calibers'] as List? ?? [])) {
      final cm = c as Map<String, dynamic>;
      calibers[cm['id'] as int] = ((cm['diameter'] ?? cm['caliber']) as num)
          .toDouble();
    }

    return BuiltinCollection(
      rifles: (map['weapon'] as List? ?? [])
          .map((w) => _parseRifle(w as Map<String, dynamic>, calibers))
          .toList(),
      cartridges: (map['cartridges'] as List? ?? [])
          .map((c) => _parseCartridge(c as Map<String, dynamic>, calibers))
          .toList(),
      projectiles: (map['projectiles'] as List? ?? [])
          .map((p) => _parseProjectile(p as Map<String, dynamic>, calibers))
          .toList(),
      sights: (map['sights'] as List? ?? [])
          .map((s) => _parseSight(s as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Rifle ──────────────────────────────────────────────────────────────────

  static Rifle _parseRifle(Map<String, dynamic> j, Map<int, double> calibers) {
    final caliberId = j['caliberId'] as int?;
    final diameterInch = caliberId != null ? calibers[caliberId] : null;
    final barrelRaw =
        (j['extra'] as Map<String, dynamic>?)?['barrelLength'] as num?;
    return Rifle(
      name: j['name'] as String,
      description: j['vendor'] as String?,
      // sightHeight is not in the collection — default to 0, user sets it in wizard
      sightHeight: Distance(0.0, Unit.millimeter),
      twist: Distance((j['rTwist'] as num).toDouble(), Unit.inch),
      caliberDiameter: diameterInch != null
          ? Distance(diameterInch, Unit.inch)
          : null,
      barrelLength: barrelRaw != null
          ? Distance(barrelRaw.toDouble(), Unit.inch)
          : null,
    );
  }

  // ── Cartridge ──────────────────────────────────────────────────────────────

  static Cartridge _parseCartridge(
    Map<String, dynamic> j,
    Map<int, double> calibers,
  ) {
    final caliberId = j['caliberId'] as int?;
    final diameterInch =
        (caliberId != null ? calibers[caliberId] : null) ?? 0.0;
    final dType = _dragType(j['dType'] as String? ?? 'G1');
    final name = j['name'] as String;

    return Cartridge(
      name: name,
      type: CartridgeType.cartridge,
      projectile: _projectileFrom(
        j: j,
        name: name,
        vendor: j['vendor'] as String?,
        diameterInch: diameterInch,
        dType: dType,
      ),
      mv: Velocity((j['muzzleVelocity'] as num).toDouble(), Unit.mps),
      powderTemp: Temperature(
        (j['powderTemperature'] as num? ?? 15.0).toDouble(),
        Unit.celsius,
      ),
      powderSensitivity: Ratio(
        (j['powderSensitivity'] as num? ?? 0.0).toDouble(),
        Unit.fraction,
      ),
      usePowderSensitivity: j['usePowderSensitivity'] as bool? ?? false,
      useDiffPowderTemp: j['useDiffPowderTemp'] as bool? ?? false,
    );
  }

  // ── Projectile (bullet-only) ───────────────────────────────────────────────

  static Projectile _parseProjectile(
    Map<String, dynamic> j,
    Map<int, double> calibers,
  ) {
    final caliberId = j['caliberId'] as int?;
    final diameterInch =
        (caliberId != null ? calibers[caliberId] : null) ?? 0.0;
    final dType = _dragType(j['dType'] as String? ?? 'G1');
    return _projectileFrom(
      j: j,
      name: j['name'] as String,
      vendor: j['vendor'] as String?,
      diameterInch: diameterInch,
      dType: dType,
    );
  }

  // ── Sight ──────────────────────────────────────────────────────────────────

  static Sight _parseSight(Map<String, dynamic> j) => Sight(
    name: j['name'] as String,
    manufacturer: j['vendor'] as String?,
    // collection stores sightHeight in inches
    sightHeight: Distance(
      (j['sightHeight'] as num? ?? 0.0).toDouble(),
      Unit.inch,
    ),
    zeroElevation: Angular(0.0, Unit.radian),
  );

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Projectile _projectileFrom({
    required Map<String, dynamic> j,
    required String name,
    required String? vendor,
    required double diameterInch,
    required DragModelType dType,
  }) {
    final useMultiG1 = j['useMultiBcG1'] as bool? ?? false;
    final useMultiG7 = j['useMultiBcG7'] as bool? ?? false;

    final List<CoeficientRow> coefRows;
    if (dType == DragModelType.g7 && useMultiG7) {
      coefRows = _multiBC(j['multiBCtableG7'] as List? ?? []);
    } else if (dType == DragModelType.g1 && useMultiG1) {
      coefRows = _multiBC(j['multiBCtableG1'] as List? ?? []);
    } else {
      final bc = dType == DragModelType.g7
          ? (j['bcG7'] as num? ?? 0.0).toDouble()
          : (j['bcG1'] as num? ?? 0.0).toDouble();
      coefRows = [CoeficientRow(bcCd: bc, mv: 0.0)];
    }

    return Projectile(
      name: name,
      manufacturer: vendor,
      dragType: dType,
      weight: Weight((j['bulletWeight'] as num? ?? 0.0).toDouble(), Unit.grain),
      diameter: Distance(diameterInch, Unit.inch),
      length: Distance(
        (j['bulletLength'] as num? ?? 0.0).toDouble(),
        Unit.inch,
      ),
      coefRows: coefRows,
    );
  }

  static List<CoeficientRow> _multiBC(List table) => table.map((r) {
    final row = r as Map<String, dynamic>;
    return CoeficientRow(
      bcCd: (row['bc'] as num).toDouble(),
      mv: (row['v'] as num).toDouble(), // m/s
    );
  }).toList();

  static DragModelType _dragType(String raw) => switch (raw.toUpperCase()) {
    'G7' => DragModelType.g7,
    _ => DragModelType.g1,
  };
}
