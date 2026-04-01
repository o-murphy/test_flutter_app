import 'package:uuid/uuid.dart';

import 'package:eballistica/core/solver/shot.dart';
import 'package:eballistica/core/solver/unit.dart';
import '_storage.dart';
import 'cartridge.dart';
import 'conditions_data.dart';
import 'rifle.dart';
import 'sight.dart';

class ShotProfile {
  final String id;
  final String name;
  final Rifle rifle;
  final Sight sight;
  final Cartridge cartridge;
  final AtmoData conditions;
  final List<WindData> winds;
  final Angular lookAngle;
  final double? latitudeDeg;
  final double? azimuthDeg;

  /// Range used for zeroing (default 100 m).
  final Distance zeroDistance;

  /// Optional separate conditions for zeroing. Null → use [conditions].
  final AtmoData? zeroConditions;

  /// Whether to apply powder sensitivity correction to the current shot.
  final bool usePowderSensitivity;

  /// Whether the current shot uses a separately-entered powder temperature
  /// (true) or syncs powder temp to air temperature (false).
  final bool useDiffPowderTemp;

  /// Whether to apply powder sensitivity correction to the zero calculation.
  /// Null = inherit from [usePowderSensitivity].
  final bool? zeroUsePowderSensitivity;

  /// Whether the zero conditions use a separately-entered powder temperature.
  final bool zeroUseDiffPowderTemp;

  /// Current target range for the quick-actions panel.
  final Distance targetDistance;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShotProfile({
    String? id,
    required this.name,
    required this.rifle,
    required this.sight,
    required this.cartridge,
    required this.conditions,
    this.winds = const [],
    required this.lookAngle,
    this.latitudeDeg,
    this.azimuthDeg,
    Distance? zeroDistance,
    this.zeroConditions,
    this.usePowderSensitivity = false,
    this.useDiffPowderTemp = false,
    this.zeroUsePowderSensitivity,
    this.zeroUseDiffPowderTemp = false,
    Distance? targetDistance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       zeroDistance = zeroDistance ?? Distance(100.0, Unit.meter),
       targetDistance = targetDistance ?? Distance(300.0, Unit.meter),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Shot toShot() => Shot(
    weapon: rifle.toWeapon(),
    ammo: cartridge.toAmmo(),
    lookAngle: lookAngle,
    atmo: conditions.toAtmo(),
    winds: winds.map((w) => w.toWind()).toList(),
    latitudeDeg: latitudeDeg,
    azimuthDeg: azimuthDeg,
  );

  ShotProfile copyWith({
    String? name,
    Rifle? rifle,
    Sight? sight,
    Cartridge? cartridge,
    AtmoData? conditions,
    List<WindData>? winds,
    Angular? lookAngle,
    double? latitudeDeg,
    double? azimuthDeg,
    Distance? zeroDistance,
    AtmoData? zeroConditions,
    bool clearZeroConditions = false,
    bool? usePowderSensitivity,
    bool? useDiffPowderTemp,
    bool? zeroUsePowderSensitivity,
    bool clearZeroUsePowderSensitivity = false,
    bool? zeroUseDiffPowderTemp,
    Distance? targetDistance,
  }) => ShotProfile(
    id: id,
    name: name ?? this.name,
    rifle: rifle ?? this.rifle,
    sight: sight ?? this.sight,
    cartridge: cartridge ?? this.cartridge,
    conditions: conditions ?? this.conditions,
    winds: winds ?? this.winds,
    lookAngle: lookAngle ?? this.lookAngle,
    latitudeDeg: latitudeDeg ?? this.latitudeDeg,
    azimuthDeg: azimuthDeg ?? this.azimuthDeg,
    zeroDistance: zeroDistance ?? this.zeroDistance,
    zeroConditions: clearZeroConditions
        ? null
        : (zeroConditions ?? this.zeroConditions),
    usePowderSensitivity: usePowderSensitivity ?? this.usePowderSensitivity,
    useDiffPowderTemp: useDiffPowderTemp ?? this.useDiffPowderTemp,
    zeroUsePowderSensitivity: clearZeroUsePowderSensitivity
        ? null
        : (zeroUsePowderSensitivity ?? this.zeroUsePowderSensitivity),
    zeroUseDiffPowderTemp: zeroUseDiffPowderTemp ?? this.zeroUseDiffPowderTemp,
    targetDistance: targetDistance ?? this.targetDistance,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rifle': rifle.toJson(),
    'sight': sight.toJson(),
    'cartridge': cartridge.toJson(),
    'conditions': conditions.toJson(),
    'winds': winds.map((w) => w.toJson()).toList(),
    'lookAngle': lookAngle.in_(StorageUnits.profileLookAngle),
    if (latitudeDeg != null) 'latitudeDeg': latitudeDeg,
    if (azimuthDeg != null) 'azimuthDeg': azimuthDeg,
    'zeroDistance': zeroDistance.in_(StorageUnits.profileZeroDistance),
    if (zeroConditions != null) 'zeroConditions': zeroConditions!.toJson(),
    'targetDistance': targetDistance.in_(StorageUnits.profileTargetDistance),
    'usePowderSensitivity': usePowderSensitivity,
    'useDiffPowderTemp': useDiffPowderTemp,
    if (zeroUsePowderSensitivity != null)
      'zeroUsePowderSensitivity': zeroUsePowderSensitivity,
    'zeroUseDiffPowderTemp': zeroUseDiffPowderTemp,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ShotProfile.fromJson(Map<String, dynamic> json) {
    final c = json['conditions'] as Map;
    final zc = json['zeroConditions'] as Map?;
    return ShotProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      rifle: Rifle.fromJson(json['rifle'] as Map<String, dynamic>),
      sight: Sight.fromJson(json['sight'] as Map<String, dynamic>),
      cartridge: Cartridge.fromJson(json['cartridge'] as Map<String, dynamic>),
      conditions: AtmoData.fromJson(c),
      winds: (json['winds'] as List)
          .map((w) => WindData.fromJson(w as Map))
          .toList(),
      lookAngle: Angular(
        (json['lookAngle'] as num).toDouble(),
        StorageUnits.profileLookAngle,
      ),
      latitudeDeg: (json['latitudeDeg'] as num?)?.toDouble(),
      azimuthDeg: (json['azimuthDeg'] as num?)?.toDouble(),
      zeroDistance: json['zeroDistance'] != null
          ? Distance(
              (json['zeroDistance'] as num).toDouble(),
              StorageUnits.profileZeroDistance,
            )
          : null,
      zeroConditions: AtmoData.fromJson(zc ?? c),
      targetDistance: json['targetDistance'] != null
          ? Distance(
              (json['targetDistance'] as num).toDouble(),
              StorageUnits.profileTargetDistance,
            )
          : null,
      usePowderSensitivity: json['usePowderSensitivity'] as bool? ?? false,
      useDiffPowderTemp: json['useDiffPowderTemp'] as bool? ?? false,
      zeroUsePowderSensitivity: json['zeroUsePowderSensitivity'] as bool?,
      zeroUseDiffPowderTemp: json['zeroUseDiffPowderTemp'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
