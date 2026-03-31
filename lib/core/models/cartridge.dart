import 'package:eballistica/core/solver/unit.dart';
import 'package:uuid/uuid.dart';

import 'package:eballistica/core/solver/munition.dart';
import '_storage.dart';
import 'projectile.dart';

class Cartridge {
  final String id;
  final String name;
  final Projectile projectile;
  final Velocity mv;
  final Temperature powderTemp;
  final Ratio powderSensitivity;
  final bool usePowderSensitivity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cartridge({
    String? id,
    required this.name,
    required this.projectile,
    required this.mv,
    required this.powderTemp,
    required this.powderSensitivity,
    this.usePowderSensitivity = false,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Ammo toAmmo() => Ammo(
    dm: projectile.dm,
    mv: mv,
    powderTemp: powderTemp,
    tempModifier: powderSensitivity.in_(Unit.fraction),
    usePowderSensitivity: usePowderSensitivity,
  );

  Cartridge copyWith({
    String? name,
    Projectile? projectile,
    Velocity? mv,
    Temperature? powderTemp,
    Ratio? powderSensitivity,
    bool? usePowderSensitivity,
    String? notes,
  }) => Cartridge(
    id: id,
    name: name ?? this.name,
    projectile: projectile ?? this.projectile,
    mv: mv ?? this.mv,
    powderTemp: powderTemp ?? this.powderTemp,
    powderSensitivity: powderSensitivity ?? this.powderSensitivity,
    usePowderSensitivity: usePowderSensitivity ?? this.usePowderSensitivity,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'projectile': projectile.toJson(),
    'mv': mv.in_(StorageUnits.cartridgeMv),
    'powderTemp': powderTemp.in_(StorageUnits.cartridgePowderTemp),
    'powderSensitivity': powderSensitivity.in_(StorageUnits.cartridgePowderSensitivity),
    'usePowderSensitivity': usePowderSensitivity,
    if (notes != null) 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Cartridge.fromJson(Map<String, dynamic> json) => Cartridge(
    id: json['id'] as String,
    name: json['name'] as String,
    projectile: Projectile.fromJson(json['projectile'] as Map<String, dynamic>),
    mv: Velocity(json['mv'].asDouble(), StorageUnits.cartridgeMv),
    powderTemp: Temperature(json['powderTemp'].asDouble(), StorageUnits.cartridgePowderTemp),
    powderSensitivity: Ratio(json['powderSensitivity'].asDouble(), StorageUnits.cartridgePowderSensitivity),
    usePowderSensitivity: json['usePowderSensitivity'] as bool,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
