// ЧИСТИЙ DART — без Flutter імпортів
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/core/models/unit_settings.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/formatting/unit_formatter.dart';

class UnitFormatterImpl implements UnitFormatter {
  final UnitSettings _u;

  const UnitFormatterImpl(this._u);

  // --- Helpers ---

  /// Extract value from a Dimension in the given display unit.
  double _val(dynamic dim, Unit displayUnit) =>
      (dim as dynamic).in_(displayUnit) as double;

  // --- Formatted strings ---

  @override
  String velocity(dynamic dim) {
    final v = _val(dim, _u.velocity);
    return '${v.toStringAsFixed(FC.velocity.accuracyFor(_u.velocity))} ${_u.velocity.symbol}';
  }

  @override
  String muzzleVelocity(dynamic dim) {
    final v = _val(dim, _u.velocity);
    return '${v.toStringAsFixed(FC.muzzleVelocity.accuracyFor(_u.velocity))} ${_u.velocity.symbol}';
  }

  @override
  String distance(dynamic dim) {
    final v = _val(dim, _u.distance);
    return '${v.toStringAsFixed(FC.targetDistance.accuracyFor(_u.distance))} ${_u.distance.symbol}';
  }

  @override
  String shortDistance(dynamic dim) {
    final v = _val(dim, _u.distance);
    return v.toStringAsFixed(FC.targetDistance.accuracyFor(_u.distance));
  }

  @override
  String temperature(dynamic dim) {
    final v = _val(dim, _u.temperature);
    return '${v.toStringAsFixed(FC.temperature.accuracyFor(_u.temperature))} ${_u.temperature.symbol}';
  }

  @override
  String pressure(dynamic dim) {
    final v = _val(dim, _u.pressure);
    return '${v.toStringAsFixed(FC.pressure.accuracyFor(_u.pressure))} ${_u.pressure.symbol}';
  }

  @override
  String drop(dynamic dim) {
    final v = _val(dim, _u.drop);
    return '${v.toStringAsFixed(FC.drop.accuracyFor(_u.drop))} ${_u.drop.symbol}';
  }

  @override
  String windage(dynamic dim) => drop(dim);

  @override
  String adjustment(dynamic dim) {
    final v = _val(dim, _u.adjustment);
    return '${v.toStringAsFixed(FC.adjustment.accuracyFor(_u.adjustment))} ${_u.adjustment.symbol}';
  }

  @override
  String energy(dynamic dim) {
    final v = _val(dim, _u.energy);
    return '${v.toStringAsFixed(FC.energy.accuracyFor(_u.energy))} ${_u.energy.symbol}';
  }

  @override
  String weight(dynamic dim) {
    final v = _val(dim, _u.weight);
    return '${v.toStringAsFixed(FC.bulletWeight.accuracyFor(_u.weight))} ${_u.weight.symbol}';
  }

  @override
  String sightHeight(dynamic dim) {
    final v = _val(dim, _u.sightHeight);
    return '${v.toStringAsFixed(FC.sightHeight.accuracyFor(_u.sightHeight))} ${_u.sightHeight.symbol}';
  }

  @override
  String twist(dynamic dim) {
    final v = _val(dim, _u.twist);
    return '1:${v.toStringAsFixed(FC.twistRate.accuracyFor(_u.twist))} ${_u.twist.symbol}';
  }

  @override
  String humidity(double fraction) =>
      '${(fraction * 100).toStringAsFixed(0)} %';

  @override
  String mach(double m) => '${m.toStringAsFixed(2)} M';

  @override
  String time(double seconds) => '${seconds.toStringAsFixed(3)} s';

  // --- Raw numbers ---

  @override
  double rawVelocity(dynamic dim) => _val(dim, _u.velocity);
  @override
  double rawDistance(dynamic dim) => _val(dim, _u.distance);
  @override
  double rawTemperature(dynamic dim) => _val(dim, _u.temperature);
  @override
  double rawPressure(dynamic dim) => _val(dim, _u.pressure);
  @override
  double rawDrop(dynamic dim) => _val(dim, _u.drop);
  @override
  double rawAdjustment(dynamic dim) => _val(dim, _u.adjustment);
  @override
  double rawEnergy(dynamic dim) => _val(dim, _u.energy);
  @override
  double rawWeight(dynamic dim) => _val(dim, _u.weight);
  @override
  double rawSightHeight(dynamic dim) => _val(dim, _u.sightHeight);

  // --- Symbols ---

  @override
  String get velocitySymbol => _u.velocity.symbol;
  @override
  String get distanceSymbol => _u.distance.symbol;
  @override
  String get temperatureSymbol => _u.temperature.symbol;
  @override
  String get pressureSymbol => _u.pressure.symbol;
  @override
  String get dropSymbol => _u.drop.symbol;
  @override
  String get adjustmentSymbol => _u.adjustment.symbol;
  @override
  String get energySymbol => _u.energy.symbol;
  @override
  String get weightSymbol => _u.weight.symbol;
  @override
  String get sightHeightSymbol => _u.sightHeight.symbol;

  // --- Input conversion (для діалогів вводу) ---

  @override
  double inputToRaw(double displayValue, InputField field) {
    return switch (field) {
      InputField.velocity => Velocity(displayValue, _u.velocity).in_(Unit.mps),
      InputField.distance =>
        Distance(displayValue, _u.distance).in_(Unit.meter),
      InputField.targetDistance =>
        Distance(displayValue, _u.distance).in_(Unit.meter),
      InputField.zeroDistance =>
        Distance(displayValue, _u.distance).in_(Unit.meter),
      InputField.temperature =>
        Temperature(displayValue, _u.temperature).in_(Unit.celsius),
      InputField.pressure =>
        Pressure(displayValue, _u.pressure).in_(Unit.hPa),
      InputField.humidity => displayValue / 100.0,
      InputField.windVelocity =>
        Velocity(displayValue, _u.velocity).in_(Unit.mps),
      InputField.lookAngle => displayValue, // завжди degrees
      InputField.sightHeight =>
        Distance(displayValue, _u.sightHeight).in_(Unit.millimeter),
      InputField.twist => Distance(displayValue, _u.twist).in_(Unit.inch),
      InputField.bulletWeight =>
        Weight(displayValue, _u.weight).in_(Unit.grain),
      InputField.bulletLength =>
        Distance(displayValue, _u.length).in_(Unit.millimeter),
      InputField.bulletDiameter =>
        Distance(displayValue, _u.diameter).in_(Unit.millimeter),
      InputField.bc => displayValue, // dimensionless
    };
  }

  @override
  double rawToInput(double rawValue, InputField field) {
    return switch (field) {
      InputField.velocity => Velocity(rawValue, Unit.mps).in_(_u.velocity),
      InputField.distance => Distance(rawValue, Unit.meter).in_(_u.distance),
      InputField.targetDistance =>
        Distance(rawValue, Unit.meter).in_(_u.distance),
      InputField.zeroDistance =>
        Distance(rawValue, Unit.meter).in_(_u.distance),
      InputField.temperature =>
        Temperature(rawValue, Unit.celsius).in_(_u.temperature),
      InputField.pressure => Pressure(rawValue, Unit.hPa).in_(_u.pressure),
      InputField.humidity => rawValue * 100.0,
      InputField.windVelocity => Velocity(rawValue, Unit.mps).in_(_u.velocity),
      InputField.lookAngle => rawValue,
      InputField.sightHeight =>
        Distance(rawValue, Unit.millimeter).in_(_u.sightHeight),
      InputField.twist => Distance(rawValue, Unit.inch).in_(_u.twist),
      InputField.bulletWeight => Weight(rawValue, Unit.grain).in_(_u.weight),
      InputField.bulletLength =>
        Distance(rawValue, Unit.millimeter).in_(_u.length),
      InputField.bulletDiameter =>
        Distance(rawValue, Unit.millimeter).in_(_u.diameter),
      InputField.bc => rawValue,
    };
  }
}
