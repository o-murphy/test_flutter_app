import 'package:eballistica/core/solver/unit.dart';
import 'package:uuid/uuid.dart';

import '_storage.dart';

class Sight {
  final String id;
  final String name;
  final String? manufacturer;
  final Distance sightHeight;
  final Angular zeroElevation;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sight({
    String? id,
    required this.name,
    this.manufacturer,
    required this.sightHeight,
    required this.zeroElevation,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Sight copyWith({
    String? name,
    String? manufacturer,
    Distance? sightHeight,
    Angular? zeroElevation,
    String? notes,
  }) => Sight(
    id: id,
    name: name ?? this.name,
    manufacturer: manufacturer ?? this.manufacturer,
    sightHeight: sightHeight ?? this.sightHeight,
    zeroElevation: zeroElevation ?? this.zeroElevation,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (manufacturer != null) 'manufacturer': manufacturer,
    'sightHeight': sightHeight.in_(StorageUnits.sightSightHeight),
    'zeroElevation': zeroElevation.in_(StorageUnits.sightZeroElevation),
    if (notes != null) 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Sight.fromJson(Map<String, dynamic> json) => Sight(
    id: json['id'] as String,
    name: json['name'] as String,
    manufacturer: json['manufacturer'] as String?,
    sightHeight: Distance(
      (json['sightHeight'] as num).toDouble(),
      StorageUnits.sightSightHeight,
    ),
    zeroElevation: Angular(
      (json['zeroElevation'] as num).toDouble(),
      StorageUnits.sightZeroElevation,
    ),
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
