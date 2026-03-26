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
  final dynamic lookAngle;  // Angular
  final double? latitudeDeg;
  final double? azimuthDeg;
  /// Range used for zeroing (default 100 m).
  final Distance zeroDistance;
  /// Optional separate conditions for zeroing. Null → use [conditions].
  final Atmo? zeroConditions;
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
    Distance? targetDistance,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
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
    dynamic lookAngle,
    double? latitudeDeg,
    double? azimuthDeg,
    Distance? zeroDistance,
    Atmo? zeroConditions,
    bool clearZeroConditions = false,
    Distance? targetDistance,
  }) =>
      ShotProfile(
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
        zeroConditions: clearZeroConditions ? null : (zeroConditions ?? this.zeroConditions),
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
        'winds': winds.map((w) => {
          'velocity': dimToJson(w.velocity),
          'directionFrom': dimToJson(w.directionFrom),
          'untilDistance': dimToJson(w.untilDistance),
        }).toList(),
        'lookAngle': dimToJson(lookAngle),
        if (latitudeDeg != null) 'latitudeDeg': latitudeDeg,
        if (azimuthDeg != null) 'azimuthDeg': azimuthDeg,
        'zeroDistance': dimToJson(zeroDistance),
        if (zeroConditions != null) 'zeroConditions': {
          'altitude': dimToJson(zeroConditions!.altitude),
          'pressure': dimToJson(zeroConditions!.pressure),
          'temperature': dimToJson(zeroConditions!.temperature),
          'humidity': zeroConditions!.humidity,
          'powderTemp': dimToJson(zeroConditions!.powderTemp),
        },
        'targetDistance': dimToJson(targetDistance),
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
        altitude: distanceFromJson(c['altitude'] as Map),
        pressure: pressureFromJson(c['pressure'] as Map),
        temperature: temperatureFromJson(c['temperature'] as Map),
        humidity: (c['humidity'] as num).toDouble(),
        powderTemperature: temperatureFromJson(c['powderTemp'] as Map),
      ),
      winds: (json['winds'] as List).map((w) => Wind(
            velocity: velocityFromJson(w['velocity'] as Map),
            directionFrom: angularFromJson(w['directionFrom'] as Map),
            untilDistance: distanceFromJson(w['untilDistance'] as Map),
          )).toList(),
      lookAngle: angularFromJson(json['lookAngle'] as Map),
      latitudeDeg: (json['latitudeDeg'] as num?)?.toDouble(),
      azimuthDeg: (json['azimuthDeg'] as num?)?.toDouble(),
      zeroDistance: json['zeroDistance'] != null
          ? distanceFromJson(json['zeroDistance'] as Map)
          : null,
      zeroConditions: Atmo(
        altitude:    distanceFromJson(   (zc ?? c)['altitude']    as Map),
        pressure:    pressureFromJson(   (zc ?? c)['pressure']    as Map),
        temperature: temperatureFromJson((zc ?? c)['temperature'] as Map),
        humidity:    ((zc ?? c)['humidity'] as num).toDouble(),
        powderTemperature: temperatureFromJson((zc ?? c)['powderTemp'] as Map),
      ),
      targetDistance: json['targetDistance'] != null
          ? distanceFromJson(json['targetDistance'] as Map)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
