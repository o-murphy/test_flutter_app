import 'package:uuid/uuid.dart';

import 'package:eballistica/core/solver/conditions.dart';
import 'package:eballistica/core/solver/shot.dart';
import 'package:eballistica/core/solver/unit.dart';
import '_dim.dart';
import 'cartridge.dart';
import 'rifle.dart';
import 'sight.dart';

class ShotProfile {
  final String id;
  final String name;
  final Rifle rifle;
  final Sight sight;
  final Cartridge cartridge;
  final Atmo conditions;
  final List<Wind> winds;
  final Angular lookAngle; // Angular
  final double? latitudeDeg;
  final double? azimuthDeg;

  /// Range used for zeroing (default 100 m).
  final Distance zeroDistance;

  /// Optional separate conditions for zeroing. Null → use [conditions].
  final Atmo? zeroConditions;

  /// Whether to apply powder sensitivity correction to the current shot.
  /// Moved here from AppSettings so it is per-profile, not global.
  final bool usePowderSensitivity;

  /// Whether the current shot uses a separately-entered powder temperature
  /// (true) or syncs powder temp to air temperature (false).
  /// Moved here from AppSettings so it is per-profile, not global.
  final bool useDiffPowderTemp;

  /// Whether to apply powder sensitivity correction to the zero calculation.
  /// Null = inherit from [usePowderSensitivity].
  final bool? zeroUsePowderSensitivity;

  /// Whether the zero conditions use a separately-entered powder temperature
  /// (true) or sync powder temp to zero air temperature (false).
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
    weapon: rifle.weapon,
    ammo: cartridge.toAmmo(),
    lookAngle: lookAngle,
    atmo: conditions,
    winds: winds,
    latitudeDeg: latitudeDeg,
    azimuthDeg: azimuthDeg,
  );

  ShotProfile copyWith({
    String? name,
    Rifle? rifle,
    Sight? sight,
    Cartridge? cartridge,
    Atmo? conditions,
    List<Wind>? winds,
    Angular? lookAngle,
    double? latitudeDeg,
    double? azimuthDeg,
    Distance? zeroDistance,
    Atmo? zeroConditions,
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
    'conditions': {
      'altitude': dimToJson(conditions.altitude),
      'pressure': dimToJson(conditions.pressure),
      'temperature': dimToJson(conditions.temperature),
      'humidity': conditions.humidity,
      'powderTemp': dimToJson(conditions.powderTemp),
    },
    'winds': winds
        .map(
          (w) => {
            'velocity': dimToJson(w.velocity),
            'directionFrom': dimToJson(w.directionFrom),
            'untilDistance': dimToJson(w.untilDistance),
          },
        )
        .toList(),
    'lookAngle': dimToJson(lookAngle),
    if (latitudeDeg != null) 'latitudeDeg': latitudeDeg,
    if (azimuthDeg != null) 'azimuthDeg': azimuthDeg,
    'zeroDistance': dimToJson(zeroDistance),
    if (zeroConditions != null)
      'zeroConditions': {
        'altitude': dimToJson(zeroConditions!.altitude),
        'pressure': dimToJson(zeroConditions!.pressure),
        'temperature': dimToJson(zeroConditions!.temperature),
        'humidity': zeroConditions!.humidity,
        'powderTemp': dimToJson(zeroConditions!.powderTemp),
      },
    'targetDistance': dimToJson(targetDistance),
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
      conditions: Atmo(
        altitude: distanceFromJson(c['altitude'] as Map<String, dynamic>),
        pressure: pressureFromJson(c['pressure'] as Map<String, dynamic>),
        temperature: temperatureFromJson(
          c['temperature'] as Map<String, dynamic>,
        ),
        humidity: (c['humidity'] as num).toDouble(),
        powderTemperature: temperatureFromJson(
          c['powderTemp'] as Map<String, dynamic>,
        ),
      ),
      winds: (json['winds'] as List)
          .map(
            (w) => Wind(
              velocity: velocityFromJson(w['velocity'] as Map<String, dynamic>),
              directionFrom: angularFromJson(
                w['directionFrom'] as Map<String, dynamic>,
              ),
              untilDistance: distanceFromJson(
                w['untilDistance'] as Map<String, dynamic>,
              ),
            ),
          )
          .toList(),
      lookAngle: angularFromJson(json['lookAngle'] as Map<String, dynamic>),
      latitudeDeg: (json['latitudeDeg'] as num?)?.toDouble(),
      azimuthDeg: (json['azimuthDeg'] as num?)?.toDouble(),
      zeroDistance: json['zeroDistance'] != null
          ? distanceFromJson(json['zeroDistance'] as Map<String, dynamic>)
          : null,
      zeroConditions: Atmo(
        altitude: distanceFromJson(
          (zc ?? c)['altitude'] as Map<String, dynamic>,
        ),
        pressure: pressureFromJson(
          (zc ?? c)['pressure'] as Map<String, dynamic>,
        ),
        temperature: temperatureFromJson(
          (zc ?? c)['temperature'] as Map<String, dynamic>,
        ),
        humidity: ((zc ?? c)['humidity'] as num).toDouble(),
        powderTemperature: temperatureFromJson(
          (zc ?? c)['powderTemp'] as Map<String, dynamic>,
        ),
      ),
      targetDistance: json['targetDistance'] != null
          ? distanceFromJson(json['targetDistance'] as Map<String, dynamic>)
          : null,
      usePowderSensitivity: json['usePowderSensitivity'] as bool? ?? false,
      useDiffPowderTemp: json['useDiffPowderTemp'] as bool? ?? false,
      zeroUsePowderSensitivity: json['zeroUsePowderSensitivity'] as bool?,
      // Default true for backward-compat: preserve stored powderTemp in existing profiles.
      zeroUseDiffPowderTemp: json['zeroUseDiffPowderTemp'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
