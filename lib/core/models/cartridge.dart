import 'package:eballistica/core/solver/unit.dart';
import 'package:uuid/uuid.dart';

import 'package:eballistica/core/solver/munition.dart';
import '_storage.dart';
import 'conditions_data.dart';
import 'projectile.dart';

enum CartridgeType { cartridge, bullet }

class Cartridge {
  final String id;
  final String name;
  final CartridgeType type;
  final Projectile projectile;
  final Velocity mv;
  final Temperature powderTemp;
  final Ratio powderSensitivity;

  // ── Zero data (belongs to cartridge, not profile) ──────────────────────────
  final Distance zeroDistance;
  final AtmoData? atmo;
  final bool usePowderSensitivity;
  final bool useDiffPowderTemp;

  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cartridge({
    String? id,
    required this.name,
    this.type = CartridgeType.cartridge,
    required this.projectile,
    required this.mv,
    required this.powderTemp,
    required this.powderSensitivity,
    Distance? zeroDistance,
    this.atmo,
    this.usePowderSensitivity = false,
    this.useDiffPowderTemp = false,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       zeroDistance = zeroDistance ?? Distance(100.0, Unit.meter),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Ammo toAmmo() => Ammo(
    dm: projectile.toDragModel(),
    mv: mv,
    powderTemp: powderTemp,
    tempModifier: powderSensitivity.in_(Unit.fraction),
  );

  Cartridge copyWith({
    String? name,
    CartridgeType? type,
    Projectile? projectile,
    Velocity? mv,
    Temperature? powderTemp,
    Ratio? powderSensitivity,
    Distance? zeroDistance,
    AtmoData? conditions,
    bool? usePowderSensitivity,
    bool? useDiffPowderTemp,
    String? notes,
  }) => Cartridge(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    projectile: projectile ?? this.projectile,
    mv: mv ?? this.mv,
    powderTemp: powderTemp ?? this.powderTemp,
    powderSensitivity: powderSensitivity ?? this.powderSensitivity,
    zeroDistance: zeroDistance ?? this.zeroDistance,
    atmo: conditions ?? this.atmo,
    usePowderSensitivity: usePowderSensitivity ?? this.usePowderSensitivity,
    useDiffPowderTemp: useDiffPowderTemp ?? this.useDiffPowderTemp,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'projectile': projectile.toJson(),
    'mv': mv.in_(StorageUnits.cartridgeMv),
    'powderTemp': powderTemp.in_(StorageUnits.cartridgePowderTemp),
    'powderSensitivity': powderSensitivity.in_(
      StorageUnits.cartridgePowderSensitivity,
    ),
    'zeroDistance': zeroDistance.in_(StorageUnits.cartridgeZeroDistance),
    if (atmo != null) 'zeroConditions': atmo!.toJson(),
    'usePowderSensitivity': usePowderSensitivity,
    'useDiffPowderTemp': useDiffPowderTemp,
    if (notes != null) 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Cartridge.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = typeStr == 'bullet'
        ? CartridgeType.bullet
        : CartridgeType.cartridge;

    final zeroCondJson = json['zeroConditions'] as Map?;

    return Cartridge(
      id: json['id'] as String,
      name: json['name'] as String,
      type: type,
      projectile: Projectile.fromJson(
        json['projectile'] as Map<String, dynamic>,
      ),
      mv: Velocity((json['mv'] as num).toDouble(), StorageUnits.cartridgeMv),
      powderTemp: Temperature(
        (json['powderTemp'] as num).toDouble(),
        StorageUnits.cartridgePowderTemp,
      ),
      powderSensitivity: Ratio(
        (json['powderSensitivity'] as num).toDouble(),
        StorageUnits.cartridgePowderSensitivity,
      ),
      // zero fields — backward-compat: old cartridges without these get defaults
      zeroDistance: json['zeroDistance'] != null
          ? Distance(
              (json['zeroDistance'] as num).toDouble(),
              StorageUnits.cartridgeZeroDistance,
            )
          : null,
      atmo: zeroCondJson != null
          ? AtmoData.fromJson(zeroCondJson as Map<String, dynamic>)
          : null,
      usePowderSensitivity: json['usePowderSensitivity'] as bool? ?? false,
      useDiffPowderTemp: json['useDiffPowderTemp'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
