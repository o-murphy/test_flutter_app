import 'package:eballistica/core/solver/unit.dart';

class UnitSettings {
  final Unit angular;
  final Unit distance;
  final Unit velocity;
  final Unit pressure;
  final Unit temperature;
  final Unit diameter;
  final Unit length;
  final Unit weight;
  final Unit adjustment;
  final Unit drop;
  final Unit energy;
  final Unit sightHeight;
  final Unit twist;
  final Unit time;

  const UnitSettings({
    this.angular      = Unit.degree,
    this.distance     = Unit.meter,
    this.velocity     = Unit.mps,
    this.pressure     = Unit.hPa,
    this.temperature  = Unit.celsius,
    this.diameter     = Unit.inch,
    this.length       = Unit.inch,
    this.weight       = Unit.grain,
    this.adjustment   = Unit.mil,
    this.drop         = Unit.centimeter,
    this.energy       = Unit.joule,
    this.sightHeight  = Unit.millimeter,
    this.twist        = Unit.inch,
    this.time         = Unit.second,
  });

  UnitSettings copyWith({
    Unit? angular, Unit? distance, Unit? velocity, Unit? pressure,
    Unit? temperature, Unit? diameter, Unit? length, Unit? weight,
    Unit? adjustment, Unit? drop, Unit? energy, Unit? sightHeight,
    Unit? twist, Unit? time,
  }) => UnitSettings(
    angular:     angular     ?? this.angular,
    distance:    distance    ?? this.distance,
    velocity:    velocity    ?? this.velocity,
    pressure:    pressure    ?? this.pressure,
    temperature: temperature ?? this.temperature,
    diameter:    diameter    ?? this.diameter,
    length:      length      ?? this.length,
    weight:      weight      ?? this.weight,
    adjustment:  adjustment  ?? this.adjustment,
    drop:        drop        ?? this.drop,
    energy:      energy      ?? this.energy,
    sightHeight: sightHeight ?? this.sightHeight,
    twist:       twist       ?? this.twist,
    time:        time        ?? this.time,
  );

  Map<String, dynamic> toJson() => {
    'angular':     angular.name,
    'distance':    distance.name,
    'velocity':    velocity.name,
    'pressure':    pressure.name,
    'temperature': temperature.name,
    'diameter':    diameter.name,
    'length':      length.name,
    'weight':      weight.name,
    'adjustment':  adjustment.name,
    'drop':        drop.name,
    'energy':      energy.name,
    'sightHeight': sightHeight.name,
    'twist':       twist.name,
    'time':        time.name,
  };

  factory UnitSettings.fromJson(Map<String, dynamic> json) {
    Unit u(String key, Unit fallback) {
      final name = json[key] as String?;
      if (name == null) return fallback;
      return Unit.values.firstWhere((u) => u.name == name, orElse: () => fallback);
    }
    return UnitSettings(
      angular:     u('angular',     Unit.degree),
      distance:    u('distance',    Unit.meter),
      velocity:    u('velocity',    Unit.mps),
      pressure:    u('pressure',    Unit.hPa),
      temperature: u('temperature', Unit.celsius),
      diameter:    u('diameter',    Unit.inch),
      length:      u('length',      Unit.inch),
      weight:      u('weight',      Unit.grain),
      adjustment:  u('adjustment',  Unit.mil),
      drop:        u('drop',        Unit.centimeter),
      energy:      u('energy',      Unit.joule),
      sightHeight: u('sightHeight', Unit.millimeter),
      twist:       u('twist',       Unit.inch),
      time:        u('time',        Unit.second),
    );
  }
}
