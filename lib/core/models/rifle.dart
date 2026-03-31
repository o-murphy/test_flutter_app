import 'package:eballistica/core/solver/munition.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:uuid/uuid.dart';

import '_storage.dart';

class Rifle {
  final String id;
  final String name;
  final String? description;
  final Distance sightHeight;
  final Distance twist;
  final Angular zeroElevation;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rifle({
    String? id,
    required this.name,
    this.description,
    required this.sightHeight,
    required this.twist,
    Angular? zeroElevation,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       zeroElevation = zeroElevation ?? Angular(0, Unit.radian),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Weapon toWeapon() => Weapon(
    sightHeight: sightHeight,
    twist: twist,
    zeroElevation: zeroElevation,
  );

  Rifle copyWith({
    String? name,
    String? description,
    Distance? sightHeight,
    Distance? twist,
    Angular? zeroElevation,
    String? notes,
  }) => Rifle(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    sightHeight: sightHeight ?? this.sightHeight,
    twist: twist ?? this.twist,
    zeroElevation: zeroElevation ?? this.zeroElevation,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'weapon': {
      'sightHeight': sightHeight.in_(StorageUnits.weaponSightHeight),
      'twist': twist.in_(StorageUnits.weaponTwist),
      'zeroElevation': zeroElevation.in_(StorageUnits.weaponZeroElevation),
    },
    if (notes != null) 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Rifle.fromJson(Map<String, dynamic> json) {
    final w = json['weapon'] as Map;
    return Rifle(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sightHeight: Distance(
        (w['sightHeight'] as num).toDouble(),
        StorageUnits.weaponSightHeight,
      ),
      twist: Distance((w['twist'] as num).toDouble(), StorageUnits.weaponTwist),
      zeroElevation: Angular(
        (w['zeroElevation'] as num).toDouble(),
        StorageUnits.weaponZeroElevation,
      ),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
