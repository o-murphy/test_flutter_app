import 'package:eballistica/core/solver/unit.dart';
import 'package:uuid/uuid.dart';

import 'package:eballistica/core/solver/drag_model.dart';
import '_storage.dart';

enum DragModelType { g1, g7, custom }

class Projectile {
  final String id;
  final String name;
  final String? manufacturer;
  final DragModel dm;
  final DragModelType dragType;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Projectile({
    String? id,
    required this.name,
    this.manufacturer,
    required this.dm,
    this.dragType = DragModelType.custom,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Projectile copyWith({
    String? name,
    String? manufacturer,
    DragModel? dm,
    DragModelType? dragType,
    String? notes,
  }) => Projectile(
    id: id,
    name: name ?? this.name,
    manufacturer: manufacturer ?? this.manufacturer,
    dm: dm ?? this.dm,
    dragType: dragType ?? this.dragType,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (manufacturer != null) 'manufacturer': manufacturer,
    'dragType': dragType.name,
    'dm': {
      'bc': dm.bc,
      'weight': dm.weight.in_(StorageUnits.projectileWeight),
      'diameter': dm.diameter.in_(StorageUnits.projectileDiameter),
      'length': dm.length.in_(StorageUnits.projectileLength),
      'dragTable': dm.dragTable
          .map((p) => {'mach': p.mach, 'cd': p.cd})
          .toList(),
    },
    if (notes != null) 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Projectile.fromJson(Map<String, dynamic> json) {
    final d = json['dm'] as Map;
    return Projectile(
      id: json['id'] as String,
      name: json['name'] as String,
      manufacturer: json['manufacturer'] as String?,
      dragType: DragModelType.values.firstWhere(
        (t) => t.name == (json['dragType'] as String?),
        orElse: () => DragModelType.custom,
      ),
      dm: DragModel(
        bc: (d['bc'] as num).toDouble(),
        dragTable: (d['dragTable'] as List)
            .map((p) => {'mach': p['mach'], 'cd': p['cd']})
            .toList(),
        weight: Weight(d['weight'].asDouble(), StorageUnits.projectileWeight),
        diameter: Distance(d['diameter'].asDouble(), StorageUnits.projectileDiameter),
        length: Distance(d['length'].asDouble(), StorageUnits.projectileLength),
      ),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
