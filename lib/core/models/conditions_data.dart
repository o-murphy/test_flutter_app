// ЧИСТИЙ DART
import 'package:eballistica/core/solver/conditions.dart';
import 'package:eballistica/core/solver/unit.dart';

import '_storage.dart';

// ── AtmoData ──────────────────────────────────────────────────────────────────

class AtmoData {
  final Distance altitude;
  final Pressure pressure;
  final Temperature temperature;
  final double humidity; // fraction 0.0–1.0
  final Temperature powderTemp;

  const AtmoData({
    required this.altitude,
    required this.pressure,
    required this.temperature,
    required this.humidity,
    required this.powderTemp,
  });

  Atmo toAtmo() => Atmo(
    altitude: altitude,
    pressure: pressure,
    temperature: temperature,
    humidity: humidity,
    powderTemperature: powderTemp,
  );

  Map<String, dynamic> toJson() => {
    'altitude': altitude.in_(StorageUnits.atmoAltitude),
    'pressure': pressure.in_(StorageUnits.atmoPressure),
    'temperature': temperature.in_(StorageUnits.atmoTemperature),
    'humidity': humidity,
    'powderTemp': powderTemp.in_(StorageUnits.atmoPowderTemp),
  };

  factory AtmoData.fromJson(Map m) => AtmoData(
    altitude: Distance(
      (m['altitude'] as num).toDouble(),
      StorageUnits.atmoAltitude,
    ),
    pressure: Pressure(
      (m['pressure'] as num).toDouble(),
      StorageUnits.atmoPressure,
    ),
    temperature: Temperature(
      (m['temperature'] as num).toDouble(),
      StorageUnits.atmoTemperature,
    ),
    humidity: (m['humidity'] as num).toDouble(),
    powderTemp: Temperature(
      (m['powderTemp'] as num).toDouble(),
      StorageUnits.atmoPowderTemp,
    ),
  );
}

// ── WindData ──────────────────────────────────────────────────────────────────

class WindData {
  final Velocity velocity;
  final Angular directionFrom;
  final Distance untilDistance;

  const WindData({
    required this.velocity,
    required this.directionFrom,
    required this.untilDistance,
  });

  Wind toWind() => Wind(
    velocity: velocity,
    directionFrom: directionFrom,
    untilDistance: untilDistance,
  );

  Map<String, dynamic> toJson() => {
    'velocity': velocity.in_(StorageUnits.windVelocity),
    'directionFrom': directionFrom.in_(StorageUnits.windDirectionFrom),
    'untilDistance': untilDistance.in_(StorageUnits.windUntilDistance),
  };

  factory WindData.fromJson(Map w) => WindData(
    velocity: Velocity(
      (w['velocity'] as num).toDouble(),
      StorageUnits.windVelocity,
    ),
    directionFrom: Angular(
      (w['directionFrom'] as num).toDouble(),
      StorageUnits.windDirectionFrom,
    ),
    untilDistance: Distance(
      (w['untilDistance'] as num).toDouble(),
      StorageUnits.windUntilDistance,
    ),
  );
}
