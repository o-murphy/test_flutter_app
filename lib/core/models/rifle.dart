import 'package:uuid/uuid.dart';

import 'package:eballistica/core/solver/munition.dart';
import '_dim.dart';

class Rifle {
  final String id;
  final String name;
  final String? description;
  final Weapon weapon;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rifle({
    String? id,
    required this.name,
    this.description,
    required this.weapon,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Rifle copyWith({
    String? name,
    String? description,
    Weapon? weapon,
    String? notes,
  }) =>
      Rifle(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        weapon: weapon ?? this.weapon,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'weapon': {
          'sightHeight': dimToJson(weapon.sightHeight),
          'twist': dimToJson(weapon.twist),
          'zeroElevation': dimToJson(weapon.zeroElevation),
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
      weapon: Weapon(
        sightHeight: distanceFromJson(w['sightHeight'] as Map),
        twist: distanceFromJson(w['twist'] as Map),
        zeroElevation: angularFromJson(w['zeroElevation'] as Map),
      ),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
