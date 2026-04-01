import 'package:eballistica/core/solver/unit.dart';
import 'package:uuid/uuid.dart';

import 'package:eballistica/core/solver/drag_model.dart';
import 'package:eballistica/core/solver/drag_tables.dart';
import '_storage.dart';

enum DragModelType { g1, g7, custom }

class CoeficientRow {
  final double bcCd;
  final double mv;

  const CoeficientRow({required this.bcCd, required this.mv});

  Map<String, dynamic> toJson() => {'bc_cd': bcCd, 'mv': mv};

  factory CoeficientRow.fromJson(Map<String, dynamic> json) => CoeficientRow(
    bcCd: (json['bc_cd'] as num).toDouble(),
    mv: (json['mv'] as num).toDouble(),
  );
}

class Projectile {
  final String id;
  final String name;
  final String? manufacturer;
  final DragModelType dragType;
  final Weight weight;
  final Distance diameter;
  final Distance length;
  final List<CoeficientRow> coefRows;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Projectile({
    String? id,
    required this.name,
    this.manufacturer,
    this.dragType = DragModelType.custom,
    Weight? weight,
    Distance? diameter,
    Distance? length,
    List<CoeficientRow>? coefRows,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       weight = weight ?? Weight(0, Unit.grain),
       diameter = diameter ?? Distance(0, Unit.inch),
       length = length ?? Distance(0, Unit.inch),
       coefRows = coefRows ?? const [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// True when G1/G7 with multiple BC breakpoints (velocity-dependent BC).
  bool get isMultiBC => dragType != DragModelType.custom && coefRows.length > 1;

  /// Build a runtime [DragModel] for the ballistics solver.
  DragModel toDragModel() {
    switch (dragType) {
      case DragModelType.g1:
      case DragModelType.g7:
        final baseTable = dragType == DragModelType.g7 ? tableG7 : tableG1;
        if (coefRows.length <= 1) {
          final bc = coefRows.isEmpty || coefRows.first.bcCd == 0
              ? 1.0
              : coefRows.first.bcCd;
          return DragModel(
            bc: bc,
            dragTable: baseTable,
            weight: weight,
            diameter: diameter,
            length: length,
          );
        }
        // Multi-BC: mv values are in m/s
        final bcPoints = coefRows
            .map((r) => BCPoint(bc: r.bcCd, v: Velocity(r.mv, Unit.mps)))
            .toList();
        return createDragModelMultiBC(
          bcPoints: bcPoints,
          dragTable: baseTable,
          weight: weight,
          diameter: diameter,
          length: length,
        );
      case DragModelType.custom:
        // coefRows: bcCd = Cd, mv = Mach
        final table = coefRows.map((r) => (mach: r.mv, cd: r.bcCd)).toList();
        final sd = (weight.raw > 0 && diameter.raw > 0)
            ? calculateSectionalDensity(
                weight.in_(Unit.grain),
                diameter.in_(Unit.inch),
              )
            : 0.0;
        return DragModel(
          bc: sd > 0 ? sd : 1.0,
          dragTable: table.isNotEmpty ? table : tableG1,
          weight: weight,
          diameter: diameter,
          length: length,
        );
    }
  }

  Projectile copyWith({
    String? name,
    String? manufacturer,
    DragModelType? dragType,
    Weight? weight,
    Distance? diameter,
    Distance? length,
    List<CoeficientRow>? coefRows,
    String? notes,
  }) => Projectile(
    id: id,
    name: name ?? this.name,
    manufacturer: manufacturer ?? this.manufacturer,
    dragType: dragType ?? this.dragType,
    weight: weight ?? this.weight,
    diameter: diameter ?? this.diameter,
    length: length ?? this.length,
    coefRows: coefRows ?? this.coefRows,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (manufacturer != null) 'manufacturer': manufacturer,
    'dragType': dragType.name,
    'weight': weight.in_(StorageUnits.projectileWeight),
    'diameter': diameter.in_(StorageUnits.projectileDiameter),
    'length': length.in_(StorageUnits.projectileLength),
    'coefRows': coefRows.map((r) => r.toJson()).toList(),
    if (notes != null) 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Projectile.fromJson(Map<String, dynamic> json) {
    final dragType = DragModelType.values.firstWhere(
      (t) => t.name == (json['dragType'] as String?),
      orElse: () => DragModelType.g1,
    );

    final coefRows =
        (json['coefRows'] as List?)
            ?.map((r) => CoeficientRow.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return Projectile(
      id: json['id'] as String,
      name: json['name'] as String,
      manufacturer: json['manufacturer'] as String?,
      dragType: dragType,
      weight: Weight(
        (json['weight'] as num).toDouble(),
        StorageUnits.projectileWeight,
      ),
      diameter: Distance(
        (json['diameter'] as num).toDouble(),
        StorageUnits.projectileDiameter,
      ),
      length: Distance(
        (json['length'] as num).toDouble(),
        StorageUnits.projectileLength,
      ),
      coefRows: coefRows,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
