import 'dart:math';

enum Unit {
  radian(0, "radian", "rad"),
  degree(1, "degree", "°"),
  moa(2, "MOA", "MOA"),
  mil(3, "MIL", "MIL"),
  mRad(4, "MRAD", "MRAD"),
  thousandth(5, "thousandth", "ths"),
  inchesPer100Yd(6, "inch/100yd", "in/100yd"),
  cmPer100m(7, "cm/100m", "cm/100m"),
  oClock(8, "hour", "h"),
  inch(10, "inch", "inch"),
  foot(11, "foot", "ft"),
  yard(12, "yard", "yd"),
  mile(13, "mile", "mi"),
  nauticalMile(14, "nautical mile", "nm"),
  millimeter(15, "millimeter", "mm"),
  centimeter(16, "centimeter", "cm"),
  meter(17, "meter", "m"),
  kilometer(18, "kilometer", "km"),
  line(19, "line", "ln"),
  footPound(30, "foot-pound", "ft·lb"),
  joule(31, "joule", "J"),
  mmHg(40, "mmHg", "mmHg"),
  inHg(41, "inHg", "inHg"),
  bar(42, "bar", "bar"),
  hPa(43, "hPa", "hPa"),
  psi(44, "psi", "psi"),
  fahrenheit(50, "fahrenheit", "°F"),
  celsius(51, "celsius", "°C"),
  kelvin(52, "kelvin", "°K"),
  rankin(53, "rankin", "°R"),
  mps(60, "mps", "m/s"),
  kmh(61, "kmh", "km/h"),
  fps(62, "fps", "ft/s"),
  mph(63, "mph", "mph"),
  kt(64, "knot", "kt"),
  grain(70, "grain", "gr"),
  ounce(71, "ounce", "oz"),
  gram(72, "gram", "g"),
  pound(73, "pound", "lb"),
  kilogram(74, "kilogram", "kg"),
  newton(75, "newton", "N"),
  minute(80, "minute", "min"),
  second(81, "second", "s"),
  millisecond(82, "millisecond", "ms"),
  microsecond(83, "microsecond", "µs"),
  nanosecond(84, "nanosecond", "ns"),
  picosecond(85, "picosecond", "ps");

  const Unit(this.id, this.label, this.symbol);
  final int id;
  final String label;
  final String symbol;

  static Unit fromName(String name) =>
      Unit.values.firstWhere((u) => u.name == name);
}

extension UnitCallable on Unit {
  dynamic call(Object value) {
    if (value is Dimension) {
      return value.to(this);
    }

    final double val = (value as num).toDouble();

    if (id >= 0 && id < 10) return Angular(val, this);
    if (id >= 10 && id < 20) return Distance(val, this);
    if (id >= 30 && id < 40) return Energy(val, this);
    if (id >= 40 && id < 50) return Pressure(val, this);
    if (id >= 50 && id < 60) return Temperature(val, this);
    if (id >= 60 && id < 70) return Velocity(val, this);
    if (id >= 70 && id < 80) return Weight(val, this);
    if (id >= 80 && id < 90) return Time(val, this);

    throw Exception('Unit ID $id is not supported for casting');
  }
}

extension UnitParser on Unit {
  static Dimension parse(String input, [Unit? preferred]) {
    final cleanInput = input.trim().toLowerCase().replaceAll(' ', '');

    final match = RegExp(r"^(-?\d+\.?\d*)(.*)$").firstMatch(cleanInput);

    if (match != null) {
      final double value = .parse(match.group(1)!);
      final alias = match.group(2)!;

      if (alias.isEmpty) {
        if (preferred != null) return preferred(value);
        throw Exception("No unit alias found and no preferred unit provided");
      }

      final unit = Unit.values.firstWhere(
        (u) => u.symbol.toLowerCase() == alias || u.name.toLowerCase() == alias,
        orElse: () => throw Exception("Unknown unit alias: $alias"),
      );

      return unit(value);
    }
    throw Exception("Could not parse: $input");
  }
}

abstract class Dimension<T extends Dimension<T>> {
  late double _rawValue;
  final Unit _definedUnits;

  Dimension(double value, this._definedUnits) {
    _rawValue = _toRaw(value, _definedUnits);
  }

  Map<Unit, double> get conversionFactors => <Unit, double>{};

  double get value => toDouble();
  double get raw => _rawValue;
  Unit get units => _definedUnits;

  double in_(Unit unit) => _fromRaw(_rawValue, unit);

  T to(Unit unit) => _create(in_(unit), unit);

  @override
  String toString() {
    final rounded = toDouble().toStringAsFixed(6);
    return '$rounded${_definedUnits.symbol}';
  }

  T _create(double value, Unit unit);

  double _getFactor(Unit unit) {
    final factor = conversionFactors[unit];
    if (factor == null) {
      throw Exception('$runtimeType: unit ${unit.label} is not supported');
    }
    return factor;
  }

  double _toRaw(double value, Unit unit) => value * _getFactor(unit);

  double _fromRaw(double rawValue, Unit unit) => rawValue / _getFactor(unit);

  String get debugDetails =>
      '$runtimeType(rawValue: $_rawValue, units: ${_definedUnits.label})';

  double toDouble() => _fromRaw(_rawValue, _definedUnits);
}

class Angular extends Dimension<Angular> {
  Angular(super.value, super.unit);

  static final _conversionFactors = <Unit, double>{
    Unit.radian: 1.0,
    Unit.degree: pi / 180,
    Unit.moa: pi / (60 * 180),
    Unit.mil: pi / 3200,
    Unit.mRad: 1.0 / 1000,
    Unit.thousandth: pi / 3000,
    Unit.inchesPer100Yd: 1.0 / 3600,
    Unit.cmPer100m: 1.0 / 10000,
    Unit.oClock: pi / 6,
  };

  @override
  Map<Unit, double> get conversionFactors => _conversionFactors;

  @override
  Angular _create(double value, Unit unit) => Angular(value, unit);

  @override
  double _toRaw(double value, Unit unit) {
    // Note: The logic here remains the same,
    // ensuring the result is normalized between (-pi, pi]
    final radians = super._toRaw(value, unit);
    final r = (radians + pi) % (2.0 * pi) - pi;
    return r > -pi ? r : pi;
  }
}

class Energy extends Dimension<Energy> {
  Energy(super.value, super.unit);

  static final _conversionFactors = <Unit, double>{
    Unit.footPound: 1.0,
    Unit.joule: 1 / 1.3558179483314,
  };

  @override
  Map<Unit, double> get conversionFactors => _conversionFactors;

  @override
  Energy _create(double value, Unit unit) => Energy(value, unit);
}

class Distance extends Dimension<Distance> {
  Distance(super.value, super.unit);

  static final _conversionFactors = <Unit, double>{
    Unit.inch: 1.0,
    Unit.foot: 12.0,
    Unit.yard: 36.0,
    Unit.mile: 63_360.0,
    Unit.nauticalMile: 72_913.3858,
    Unit.line: 0.1,
    Unit.millimeter: 1.0 / 25.4,
    Unit.centimeter: 10.0 / 25.4,
    Unit.meter: 1_000.0 / 25.4,
    Unit.kilometer: 1_000_000.0 / 25.4,
  };

  @override
  Map<Unit, double> get conversionFactors => _conversionFactors;

  @override
  Distance _create(double value, Unit unit) => Distance(value, unit);
}

class Pressure extends Dimension<Pressure> {
  Pressure(super.value, super.unit);

  static final _conversionFactors = <Unit, double>{
    Unit.mmHg: 1.0,
    Unit.inHg: 25.4,
    Unit.bar: 750.061683,
    Unit.hPa: 750.061683 / 1_000,
    Unit.psi: 51.714924102396,
  };

  @override
  Map<Unit, double> get conversionFactors => _conversionFactors;

  @override
  Pressure _create(double value, Unit unit) => Pressure(value, unit);
}

class Temperature extends Dimension<Temperature> {
  Temperature(super.value, super.unit);

  @override
  Map<Unit, double> get conversionFactors => const {};

  @override
  Temperature _create(double value, Unit unit) => Temperature(value, unit);

  @override
  double _toRaw(double value, Unit unit) {
    return switch (unit) {
      Unit.fahrenheit => value,
      Unit.rankin => value - 459.67,
      Unit.celsius => value * 9.0 / 5 + 32,
      Unit.kelvin => (value - 273.15) * 9.0 / 5 + 32,
      _ => throw Exception('Temperature does not support $unit'),
    };
  }

  @override
  double _fromRaw(double value, Unit unit) {
    return switch (unit) {
      Unit.fahrenheit => value,
      Unit.rankin => value + 459.67,
      Unit.celsius => (value - 32) * 5.0 / 9,
      Unit.kelvin => (value - 32) * 5.0 / 9 + 273.15,
      _ => throw Exception('Temperature does not support $unit'),
    };
  }
}

class Time extends Dimension<Time> {
  Time(super.value, super.unit);

  static final _conversionFactors = <Unit, double>{
    Unit.second: 1.0,
    Unit.minute: 60.0,
    Unit.millisecond: 1.0 / 1_000,
    Unit.microsecond: 1.0 / 1_000_000,
    Unit.nanosecond: 1.0 / 1_000_000_000,
    Unit.picosecond: 1.0 / 1_000_000_000_000,
  };

  @override
  Map<Unit, double> get conversionFactors => _conversionFactors;

  @override
  Time _create(double value, Unit unit) => Time(value, unit);
}

class Velocity extends Dimension<Velocity> {
  Velocity(super.value, super.unit);

  static final _conversionFactors = <Unit, double>{
    Unit.mps: 1.0,
    Unit.kmh: 1.0 / 3.6,
    Unit.fps: 1.0 / 3.2808399,
    Unit.mph: 1.0 / 2.23693629,
    Unit.kt: 1.0 / 1.94384449,
  };

  @override
  Map<Unit, double> get conversionFactors => _conversionFactors;

  @override
  Velocity _create(double value, Unit unit) => Velocity(value, unit);
}

class Weight extends Dimension<Weight> {
  Weight(super.value, super.unit);

  static final _conversionFactors = <Unit, double>{
    Unit.grain: 1.0,
    Unit.ounce: 437.5,
    Unit.gram: 15.4323584,
    Unit.pound: 7_000.0,
    Unit.kilogram: 15_432.3584,
    Unit.newton: 1_573.662597,
  };

  @override
  Map<Unit, double> get conversionFactors => _conversionFactors;

  @override
  Weight _create(double value, Unit unit) => Weight(value, unit);
}
