import 'package:uuid/uuid.dart';

import 'package:eballistica/core/solver/munition.dart';
import '_dim.dart';
import 'projectile.dart';

class Cartridge {
  final String id;
  final String name;
  final Projectile projectile;
  final dynamic mv;            // Velocity
  final dynamic powderTemp;    // Temperature
  final double tempModifier;
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
    this.tempModifier = 0.0,
    this.usePowderSensitivity = false,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Ammo toAmmo() => Ammo(
        dm: projectile.dm,
        mv: mv,
        powderTemp: powderTemp,
        tempModifier: tempModifier / 100.0,
        usePowderSensitivity: usePowderSensitivity,
      );

  Cartridge copyWith({
    String? name,
    Projectile? projectile,
    dynamic mv,
    dynamic powderTemp,
    double? tempModifier,
    bool? usePowderSensitivity,
    String? notes,
  }) =>
      Cartridge(
        id: id,
        name: name ?? this.name,
        projectile: projectile ?? this.projectile,
        mv: mv ?? this.mv,
        powderTemp: powderTemp ?? this.powderTemp,
        tempModifier: tempModifier ?? this.tempModifier,
        usePowderSensitivity: usePowderSensitivity ?? this.usePowderSensitivity,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'projectile': projectile.toJson(),
        'mv': dimToJson(mv),
        'powderTemp': dimToJson(powderTemp),
        'tempModifier': tempModifier,
        'usePowderSensitivity': usePowderSensitivity,
        if (notes != null) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Cartridge.fromJson(Map<String, dynamic> json) => Cartridge(
        id: json['id'] as String,
        name: json['name'] as String,
        projectile: Projectile.fromJson(json['projectile'] as Map<String, dynamic>),
        mv: velocityFromJson(json['mv'] as Map),
        powderTemp: temperatureFromJson(json['powderTemp'] as Map),
        tempModifier: (json['tempModifier'] as num).toDouble(),
        usePowderSensitivity: json['usePowderSensitivity'] as bool,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
