// Shared helpers for serializing/deserializing Dimension types.
// Convention: {"value": 9.0, "unit": "inch"}  (unit = Unit.name)

import 'package:eballistica/core/solver/unit.dart';

Map<String, dynamic> dimToJson(Dimension d) => {
  'value': d.toDouble(),
  'unit': d.units.name,
};

T _parse<T>(Map<String, dynamic> json, T Function(double, Unit) factory) {
  return factory(
    (json['value'] as num).toDouble(),
    .fromName(json['unit'] as String),
  );
}

Angular angularFromJson(Map<String, dynamic> json) => _parse(json, Angular.new);
Distance distanceFromJson(Map<String, dynamic> json) =>
    _parse(json, Distance.new);
Velocity velocityFromJson(Map<String, dynamic> json) =>
    _parse(json, Velocity.new);
Temperature temperatureFromJson(Map<String, dynamic> json) =>
    _parse(json, Temperature.new);
Pressure pressureFromJson(Map<String, dynamic> json) =>
    _parse(json, Pressure.new);
Weight weightFromJson(Map<String, dynamic> json) => _parse(json, Weight.new);
