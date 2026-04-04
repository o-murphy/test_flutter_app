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
  final Conditions zeroConditions;

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
    Conditions? zeroConditions,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       zeroConditions = zeroConditions ?? Conditions.withDefaults(),
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
    Conditions? zeroConditions,
    String? notes,
  }) => Cartridge(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    projectile: projectile ?? this.projectile,
    mv: mv ?? this.mv,
    powderTemp: powderTemp ?? this.powderTemp,
    powderSensitivity: powderSensitivity ?? this.powderSensitivity,
    zeroConditions: zeroConditions ?? this.zeroConditions,
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
    'zeroConditions': zeroConditions.toJson(),
    if (notes != null) 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Cartridge.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = typeStr == 'bullet'
        ? CartridgeType.bullet
        : CartridgeType.cartridge;

    Conditions zeroConditions;

    if (json['zeroConditions'] != null) {
      zeroConditions = Conditions.fromJson(
        json['zeroConditions'] as Map<String, dynamic>,
      );
    } else {
      // Старий формат: створюємо Conditions з окремих полів
      final zeroDistance = json['zeroDistance'] != null
          ? Distance(
              (json['zeroDistance'] as num).toDouble(),
              StorageUnits.cartridgeZeroDistance,
            )
          : Distance(100.0, Unit.meter);

      final zeroAtmoJson = json['zeroConditions_legacy'] as Map?;
      final zeroAtmo = zeroAtmoJson != null
          ? AtmoData.fromJson(zeroAtmoJson)
          : null;

      final usePowderSensitivity =
          json['usePowderSensitivity'] as bool? ?? false;
      final useDiffPowderTemp = json['useDiffPowderTemp'] as bool? ?? false;

      zeroConditions = Conditions.withDefaults(
        atmo: zeroAtmo,
        distance: zeroDistance,
        usePowderSensitivity: usePowderSensitivity,
        useDiffPowderTemp: useDiffPowderTemp,
      );
    }

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
      zeroConditions: zeroConditions,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
