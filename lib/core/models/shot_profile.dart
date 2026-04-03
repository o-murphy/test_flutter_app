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

  // ── Embedded у JSON профілю ───────────────────────────────────────────────
  final Rifle rifle;
  final AtmoData conditions;
  final List<WindData> winds;
  final Angular lookAngle;
  final double? latitudeDeg;
  final double? azimuthDeg;
  final Distance targetDistance;

  /// Whether to apply powder sensitivity correction to the current shot.
  final bool usePowderSensitivity;

  /// Whether the current shot uses a separately-entered powder temperature.
  final bool useDiffPowderTemp;

  // ── References до бібліотек (тільки id у JSON) ────────────────────────────
  final String? cartridgeId;
  final String? sightId;

  // ── Resolved об'єкти (НЕ зберігаються в JSON) ────────────────────────────
  // Заповнюються тільки для активного профілю через shotProfileProvider.
  final Cartridge? cartridge;
  final Sight? sight;

  final DateTime createdAt;
  final DateTime updatedAt;

  ShotProfile({
    String? id,
    required this.name,
    required this.rifle,
    this.cartridgeId,
    this.sightId,
    this.cartridge,
    this.sight,
    required this.conditions,
    this.winds = const [],
    required this.lookAngle,
    this.latitudeDeg,
    this.azimuthDeg,
    this.usePowderSensitivity = false,
    this.useDiffPowderTemp = false,
    Distance? targetDistance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       targetDistance = targetDistance ?? Distance(300.0, Unit.meter),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // ── isReadyForCalculation ─────────────────────────────────────────────────

  bool get isReadyForCalculation =>
      cartridge != null &&
      cartridge!.mv.in_(Unit.mps) > 0 &&
      cartridge!.projectile.coefRows.isNotEmpty &&
      cartridge!.projectile.diameter.in_(Unit.inch) > 0 &&
      cartridge!.projectile.weight.in_(Unit.grain) > 0 &&
      rifle.twist.in_(Unit.inch) != 0;

  // ── toShot ────────────────────────────────────────────────────────────────

  Shot toShot() => Shot(
    weapon: rifle.toWeapon(),
    ammo: cartridge!.toAmmo(),
    lookAngle: lookAngle,
    atmo: conditions.toAtmo(),
    winds: winds.map((w) => w.toWind()).toList(),
    latitudeDeg: latitudeDeg,
    azimuthDeg: azimuthDeg,
  );

  // ── copyWith ──────────────────────────────────────────────────────────────

  ShotProfile copyWith({
    String? name,
    Rifle? rifle,
    // Cartridge: передаємо об'єкт — cartridgeId оновлюється автоматично.
    // clearCartridge: true — обнуляє і cartridge, і cartridgeId.
    Cartridge? cartridge,
    bool clearCartridge = false,
    // Sight: аналогічно.
    Sight? sight,
    bool clearSight = false,
    AtmoData? conditions,
    List<WindData>? winds,
    Angular? lookAngle,
    double? latitudeDeg,
    double? azimuthDeg,
    bool? usePowderSensitivity,
    bool? useDiffPowderTemp,
    Distance? targetDistance,
  }) => ShotProfile(
    id: id,
    name: name ?? this.name,
    rifle: rifle ?? this.rifle,
    cartridgeId: clearCartridge ? null : (cartridge?.id ?? cartridgeId),
    cartridge: clearCartridge ? null : (cartridge ?? this.cartridge),
    sightId: clearSight ? null : (sight?.id ?? sightId),
    sight: clearSight ? null : (sight ?? this.sight),
    conditions: conditions ?? this.conditions,
    winds: winds ?? this.winds,
    lookAngle: lookAngle ?? this.lookAngle,
    latitudeDeg: latitudeDeg ?? this.latitudeDeg,
    azimuthDeg: azimuthDeg ?? this.azimuthDeg,
    usePowderSensitivity: usePowderSensitivity ?? this.usePowderSensitivity,
    useDiffPowderTemp: useDiffPowderTemp ?? this.useDiffPowderTemp,
    targetDistance: targetDistance ?? this.targetDistance,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  // ── JSON ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rifle': rifle.toJson(),
    if (cartridgeId != null) 'cartridgeId': cartridgeId,
    if (sightId != null) 'sightId': sightId,
    'conditions': conditions.toJson(),
    'winds': winds.map((w) => w.toJson()).toList(),
    'lookAngle': lookAngle.in_(StorageUnits.profileLookAngle),
    if (latitudeDeg != null) 'latitudeDeg': latitudeDeg,
    if (azimuthDeg != null) 'azimuthDeg': azimuthDeg,
    'targetDistance': targetDistance.in_(StorageUnits.profileTargetDistance),
    'usePowderSensitivity': usePowderSensitivity,
    'useDiffPowderTemp': useDiffPowderTemp,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ShotProfile.fromJson(Map<String, dynamic> json) {
    final c = json['conditions'] as Map;

    // ── Sight: new format (sightId) або backward-compat (embedded sight) ────
    final sightIdNew = json['sightId'] as String?;
    Sight? inlineSight;
    String? resolvedSightId = sightIdNew;

    if (sightIdNew == null) {
      final sightJson = json['sight'] as Map<String, dynamic>?;
      if (sightJson != null) {
        inlineSight = Sight.fromJson(sightJson);
        resolvedSightId = inlineSight.id;
      }
    }

    // ── Cartridge: new format (cartridgeId) або backward-compat ─────────────
    final cartridgeIdNew = json['cartridgeId'] as String?;
    Cartridge? inlineCartridge;
    String? resolvedCartridgeId = cartridgeIdNew;

    if (cartridgeIdNew == null) {
      final cartridgeJson = json['cartridge'] as Map<String, dynamic>?;
      if (cartridgeJson != null) {
        // Старий формат: cartridge embedded + zero дані на рівні профілю.
        // Переносимо zero поля на cartridge під час міграції.
        final baseCartridge = Cartridge.fromJson(cartridgeJson);

        final oldZeroDistJson = json['zeroDistance'] as num?;
        final oldZeroCondJson = json['zeroConditions'] as Map?;
        final oldZeroUsePowderSens =
            json['zeroUsePowderSensitivity'] as bool? ?? false;
        final oldZeroUseDiffPowderTemp =
            json['zeroUseDiffPowderTemp'] as bool? ?? false;

        inlineCartridge = Cartridge(
          id: baseCartridge.id,
          name: baseCartridge.name,
          type: baseCartridge.type,
          projectile: baseCartridge.projectile,
          mv: baseCartridge.mv,
          powderTemp: baseCartridge.powderTemp,
          powderSensitivity: baseCartridge.powderSensitivity,
          zeroDistance: oldZeroDistJson != null
              ? Distance(
                  oldZeroDistJson.toDouble(),
                  StorageUnits.profileZeroDistance,
                )
              : baseCartridge.zeroDistance,
          zeroConditions: oldZeroCondJson != null
              ? AtmoData.fromJson(oldZeroCondJson as Map<String, dynamic>)
              : baseCartridge.zeroConditions,
          zeroUsePowderSensitivity: oldZeroUsePowderSens,
          zeroUseDiffPowderTemp: oldZeroUseDiffPowderTemp,
          notes: baseCartridge.notes,
          createdAt: baseCartridge.createdAt,
          updatedAt: baseCartridge.updatedAt,
        );
        resolvedCartridgeId = inlineCartridge.id;
      }
    }

    return ShotProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      rifle: Rifle.fromJson(json['rifle'] as Map<String, dynamic>),
      cartridgeId: resolvedCartridgeId,
      cartridge: inlineCartridge,
      sightId: resolvedSightId,
      sight: inlineSight,
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
      targetDistance: json['targetDistance'] != null
          ? Distance(
              (json['targetDistance'] as num).toDouble(),
              StorageUnits.profileTargetDistance,
            )
          : null,
      usePowderSensitivity: json['usePowderSensitivity'] as bool? ?? false,
      useDiffPowderTemp: json['useDiffPowderTemp'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
