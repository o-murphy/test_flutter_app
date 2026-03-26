// Shared helpers for serializing/deserializing Dimension types.
// Convention: {"value": 9.0, "unit": "inch"}  (unit = Unit.name)

import 'package:eballistica/core/solver/unit.dart';

Map<String, dynamic> dimToJson(Dimension d) => {
  'value': d.toDouble(),
  'unit': d.units.name,
};

Unit _unit(Map json) =>
    Unit.values.firstWhere((u) => u.name == json['unit'] as String);

Angular   angularFromJson(Map json)     => Angular(   (json['value'] as num).toDouble(), _unit(json));
Distance  distanceFromJson(Map json)    => Distance(  (json['value'] as num).toDouble(), _unit(json));
Velocity  velocityFromJson(Map json)    => Velocity(  (json['value'] as num).toDouble(), _unit(json));
Temperature temperatureFromJson(Map json) => Temperature((json['value'] as num).toDouble(), _unit(json));
Pressure  pressureFromJson(Map json)    => Pressure(  (json['value'] as num).toDouble(), _unit(json));
Weight    weightFromJson(Map json)      => Weight(    (json['value'] as num).toDouble(), _unit(json));
