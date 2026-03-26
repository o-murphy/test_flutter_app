import 'dart:math' as math;
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/core/solver/conditions.dart';
import 'package:eballistica/core/solver/munition.dart';

class Shot {
  final Ammo   ammo;
  final Atmo   atmo;
  final Weapon weapon;

  final Angular lookAngle;
  late  Angular relativeAngle;
  final Angular cantAngle;

  List<Wind>? _winds;
  double?     _azimuthDeg;
  double?     _latitudeDeg;

  Shot({
    required this.weapon,
    required this.ammo,
    Angular? lookAngle,
    Angular? relativeAngle,
    Angular? cantAngle,
    Atmo?    atmo,
    List<Wind>? winds,
    double? azimuthDeg,
    double? latitudeDeg,
  })  : lookAngle = lookAngle ?? Angular(0, Unit.radian),
        cantAngle = cantAngle ?? Angular(0, Unit.radian),
        atmo      = atmo      ?? Atmo.icao() {
    this.relativeAngle = relativeAngle ?? Angular(0, Unit.radian);
    this.winds       = winds;
    this.azimuthDeg  = azimuthDeg;
    this.latitudeDeg = latitudeDeg;
  }

  // --- Coriolis getters/setters ---

  double? get azimuthDeg => _azimuthDeg;
  set azimuthDeg(double? value) {
    if (value != null && (value < 0.0 || value >= 360.0)) {
      throw ArgumentError('Azimuth must be in range [0, 360).');
    }
    _azimuthDeg = value;
  }

  double? get latitudeDeg => _latitudeDeg;
  set latitudeDeg(double? value) {
    if (value != null && (value < -90.0 || value > 90.0)) {
      throw ArgumentError('Latitude must be in range [-90, 90].');
    }
    _latitudeDeg = value;
  }

  // --- Wind ---

  List<Wind> get winds {
    final list = _winds ?? [];
    return List.from(list)
      ..sort((a, b) => a.untilDistance.rawValue.compareTo(b.untilDistance.rawValue));
  }

  set winds(List<Wind>? value) => _winds = value;

  // --- Ballistic geometry ---

  Angular get barrelAzimuth => Angular(
        math.sin(cantAngle.in_(Unit.radian)) *
            (weapon.zeroElevation.in_(Unit.radian) +
                relativeAngle.in_(Unit.radian)),
        Unit.radian,
      );

  Angular get barrelElevation => Angular(
        lookAngle.in_(Unit.radian) +
            math.cos(cantAngle.in_(Unit.radian)) *
                (weapon.zeroElevation.in_(Unit.radian) +
                    relativeAngle.in_(Unit.radian)),
        Unit.radian,
      );

  set barrelElevation(Angular value) {
    relativeAngle = Angular(
      value.in_(Unit.radian) -
          lookAngle.in_(Unit.radian) -
          math.cos(cantAngle.in_(Unit.radian)) *
              weapon.zeroElevation.in_(Unit.radian),
      Unit.radian,
    );
  }

  Angular get slantAngle => lookAngle;
}
