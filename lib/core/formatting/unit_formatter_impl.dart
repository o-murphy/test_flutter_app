import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/core/models/unit_settings.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/formatting/unit_formatter.dart';

class UnitFormatterImpl implements UnitFormatter {
  final UnitSettings _u;

  const UnitFormatterImpl(this._u);

  String _fmt(Dimension dim, FieldConstraints fc, Unit unit) {
    final value = dim.in_(unit);
    final accuracy = fc.accuracyFor(unit);
    return '${value.toStringAsFixed(accuracy)} ${unit.symbol}';
  }

  // --- Formatted strings ---

  @override
  String velocity(Velocity dim) => _fmt(dim, FC.velocity, _u.velocity);

  @override
  String distance(Distance dim) => _fmt(dim, FC.targetDistance, _u.distance);

  @override
  String temperature(Temperature dim) =>
      _fmt(dim, FC.temperature, _u.temperature);

  @override
  String pressure(Pressure dim) => _fmt(dim, FC.pressure, _u.pressure);

  @override
  String drop(Distance dim) => _fmt(dim, FC.drop, _u.drop);

  @override
  String windage(Distance dim) => drop(dim);

  @override
  String adjustment(Angular dim) => _fmt(dim, FC.adjustment, _u.adjustment);

  @override
  String energy(Energy dim) => _fmt(dim, FC.energy, _u.energy);

  @override
  String weight(Weight dim) => _fmt(dim, FC.bulletWeight, _u.weight);

  @override
  String sightHeight(Distance dim) => _fmt(dim, FC.sightHeight, _u.sightHeight);

  @override
  String twist(Distance dim) => '1:${_fmt(dim, FC.twist, _u.twist)}';

  @override
  String humidity(Ratio dim) => _fmt(dim, FC.humidity, Unit.percent);

  @override
  String mach(double m) => '${m.toStringAsFixed(2)} M';

  @override
  String time(double seconds) => '${seconds.toStringAsFixed(3)} s';

  @override
  String powderSensitivity(Ratio dim) =>
      _fmt(dim, FC.powderSensitivity, Unit.percent);

  // --- Raw numbers ---

  @override
  double rawVelocity(Velocity dim) => dim.in_(_u.velocity);
  @override
  double rawDistance(Distance dim) => dim.in_(_u.distance);
  @override
  double rawTemperature(Temperature dim) => dim.in_(_u.temperature);
  @override
  double rawPressure(Pressure dim) => dim.in_(_u.pressure);
  @override
  double rawDrop(Distance dim) => dim.in_(_u.drop);
  @override
  double rawAdjustment(Angular dim) => dim.in_(_u.adjustment);
  @override
  double rawEnergy(Energy dim) => dim.in_(_u.energy);
  @override
  double rawWeight(Weight dim) => dim.in_(_u.weight);
  @override
  double rawSightHeight(Distance dim) => dim.in_(_u.sightHeight);

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

  // --- Input conversion (for input dialogs) ---

  @override
  double inputToRaw(double displayValue, InputField field) {
    return switch (field) {
      InputField.velocity => Velocity(displayValue, _u.velocity).in_(Unit.mps),
      InputField.distance => Distance(
        displayValue,
        _u.distance,
      ).in_(Unit.meter),
      InputField.targetDistance => Distance(
        displayValue,
        _u.distance,
      ).in_(Unit.meter),
      InputField.zeroDistance => Distance(
        displayValue,
        _u.distance,
      ).in_(Unit.meter),
      InputField.temperature => Temperature(
        displayValue,
        _u.temperature,
      ).in_(Unit.celsius),
      InputField.pressure => Pressure(displayValue, _u.pressure).in_(Unit.hPa),
      InputField.humidity => displayValue / 100.0,
      InputField.windVelocity => Velocity(
        displayValue,
        _u.velocity,
      ).in_(Unit.mps),
      InputField.lookAngle => displayValue, // always degrees
      InputField.sightHeight => Distance(
        displayValue,
        _u.sightHeight,
      ).in_(Unit.millimeter),
      InputField.twist => Distance(displayValue, _u.twist).in_(Unit.inch),
      InputField.bulletWeight => Weight(
        displayValue,
        _u.weight,
      ).in_(Unit.grain),
      InputField.bulletLength => Distance(
        displayValue,
        _u.length,
      ).in_(Unit.millimeter),
      InputField.bulletDiameter => Distance(
        displayValue,
        _u.diameter,
      ).in_(Unit.millimeter),
      InputField.bc => displayValue, // dimensionless
    };
  }

  @override
  double rawToInput(double rawValue, InputField field) {
    return switch (field) {
      InputField.velocity => Velocity(rawValue, Unit.mps).in_(_u.velocity),
      InputField.distance => Distance(rawValue, Unit.meter).in_(_u.distance),
      InputField.targetDistance => Distance(
        rawValue,
        Unit.meter,
      ).in_(_u.distance),
      InputField.zeroDistance => Distance(
        rawValue,
        Unit.meter,
      ).in_(_u.distance),
      InputField.temperature => Temperature(
        rawValue,
        Unit.celsius,
      ).in_(_u.temperature),
      InputField.pressure => Pressure(rawValue, Unit.hPa).in_(_u.pressure),
      InputField.humidity => rawValue * 100.0,
      InputField.windVelocity => Velocity(rawValue, Unit.mps).in_(_u.velocity),
      InputField.lookAngle => rawValue,
      InputField.sightHeight => Distance(
        rawValue,
        Unit.millimeter,
      ).in_(_u.sightHeight),
      InputField.twist => Distance(rawValue, Unit.inch).in_(_u.twist),
      InputField.bulletWeight => Weight(rawValue, Unit.grain).in_(_u.weight),
      InputField.bulletLength => Distance(
        rawValue,
        Unit.millimeter,
      ).in_(_u.length),
      InputField.bulletDiameter => Distance(
        rawValue,
        Unit.millimeter,
      ).in_(_u.diameter),
      InputField.bc => rawValue,
    };
  }
}
