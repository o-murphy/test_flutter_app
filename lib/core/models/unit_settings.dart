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
    this.angular = Unit.degree,
    this.distance = Unit.meter,
    this.velocity = Unit.mps,
    this.pressure = Unit.hPa,
    this.temperature = Unit.celsius,
    this.diameter = Unit.inch,
    this.length = Unit.inch,
    this.weight = Unit.grain,
    this.adjustment = Unit.mil,
    this.drop = Unit.centimeter,
    this.energy = Unit.joule,
    this.sightHeight = Unit.millimeter,
    this.twist = Unit.inch,
    this.time = Unit.second,
  });

  UnitSettings copyWith({
    Unit? angular,
    Unit? distance,
    Unit? velocity,
    Unit? pressure,
    Unit? temperature,
    Unit? diameter,
    Unit? length,
    Unit? weight,
    Unit? adjustment,
    Unit? drop,
    Unit? energy,
    Unit? sightHeight,
    Unit? twist,
    Unit? time,
  }) => UnitSettings(
    angular: angular ?? this.angular,
    distance: distance ?? this.distance,
    velocity: velocity ?? this.velocity,
    pressure: pressure ?? this.pressure,
    temperature: temperature ?? this.temperature,
    diameter: diameter ?? this.diameter,
    length: length ?? this.length,
    weight: weight ?? this.weight,
    adjustment: adjustment ?? this.adjustment,
    drop: drop ?? this.drop,
    energy: energy ?? this.energy,
    sightHeight: sightHeight ?? this.sightHeight,
    twist: twist ?? this.twist,
    time: time ?? this.time,
  );

  Map<String, dynamic> toJson() => {
    'angular': angular.name,
    'distance': distance.name,
    'velocity': velocity.name,
    'pressure': pressure.name,
    'temperature': temperature.name,
    'diameter': diameter.name,
    'length': length.name,
    'weight': weight.name,
    'adjustment': adjustment.name,
    'drop': drop.name,
    'energy': energy.name,
    'sightHeight': sightHeight.name,
    'twist': twist.name,
    'time': time.name,
  };

  factory UnitSettings.fromJson(Map<String, dynamic> json) {
    Unit u(String key, Unit fallback, bool Function(Unit) accepts) {
      final name = json[key] as String?;
      final unit = name != null ? Unit.fromName(name) : null;
      return (unit != null && accepts(unit)) ? unit : fallback;
    }

    return UnitSettings(
      angular: u('angular', Angular.rawUnit, Angular.accepts),
      distance: u('distance', Distance.rawUnit, Distance.accepts),
      velocity: u('velocity', Velocity.rawUnit, Velocity.accepts),
      pressure: u('pressure', Pressure.rawUnit, Pressure.accepts),
      temperature: u('temperature', Temperature.rawUnit, Temperature.accepts),
      diameter: u('diameter', Distance.rawUnit, Distance.accepts),
      length: u('length', Distance.rawUnit, Distance.accepts),
      weight: u('weight', Weight.rawUnit, Weight.accepts),
      adjustment: u('adjustment', Angular.rawUnit, Angular.accepts),
      drop: u('drop', Distance.rawUnit, Distance.accepts),
      energy: u('energy', Energy.rawUnit, Energy.accepts),
      sightHeight: u('sightHeight', Distance.rawUnit, Distance.accepts),
      twist: u('twist', Distance.rawUnit, Distance.accepts),
      time: u('time', Time.rawUnit, Time.accepts),
    );
  }
}
