import 'package:uuid/uuid.dart';

import 'package:eballistica/core/solver/shot.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/core/solver/munition.dart';
import 'cartridge.dart';
import 'conditions_data.dart';
import 'rifle.dart';
import 'sight.dart';

class ShotProfile {
  final String id;
  final String name;

  // ── Embedded у JSON профілю ───────────────────────────────────────────────
  final Rifle rifle;

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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
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

  Shot toZeroShot(Angular lookAngle, Weapon weapon) {
    final zeroAmmo = Ammo(
      dm: cartridge!.projectile.toDragModel(),
      mv: cartridge!.mv,
      powderTemp: cartridge!.powderTemp,
      tempModifier: cartridge!.powderSensitivity.in_(Unit.fraction),
      usePowderSensitivity: cartridge!.zeroConditions.usePowderSensitivity,
    );

    final zeroAtmo = cartridge!.zeroConditions.atmo;

    return Shot(
      weapon: weapon,
      ammo: zeroAmmo,
      lookAngle: lookAngle,
      atmo: zeroAtmo.toAtmo(),
      winds: const [],
    );
  }

  Shot toCurrentShot(Conditions conditions, Weapon weapon) {
    final currentAmmo = Ammo(
      dm: cartridge!.projectile.toDragModel(),
      mv: cartridge!.mv,
      powderTemp: conditions.atmo.powderTemp,
      tempModifier: cartridge!.powderSensitivity.in_(Unit.fraction),
      usePowderSensitivity: conditions.usePowderSensitivity,
    );

    return Shot(
      weapon: weapon,
      ammo: currentAmmo,
      lookAngle: conditions.lookAngle,
      atmo: conditions.toAtmo(),
      winds: conditions.winds.map((w) => w.toWind()).toList(),
      latitudeDeg: conditions.latitudeDeg,
      azimuthDeg: conditions.azimuthDeg,
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────────────
  ShotProfile copyWith({
    String? name,
    Rifle? rifle,
    Cartridge? cartridge,
    bool clearCartridge = false,
    Sight? sight,
    bool clearSight = false,
  }) => ShotProfile(
    id: id,
    name: name ?? this.name,
    rifle: rifle ?? this.rifle,
    cartridgeId: clearCartridge ? null : (cartridge?.id ?? cartridgeId),
    cartridge: clearCartridge ? null : (cartridge ?? this.cartridge),
    sightId: clearSight ? null : (sight?.id ?? sightId),
    sight: clearSight ? null : (sight ?? this.sight),
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
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ShotProfile.fromJson(Map<String, dynamic> json) {
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
        inlineCartridge = Cartridge.fromJson(cartridgeJson);
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
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
