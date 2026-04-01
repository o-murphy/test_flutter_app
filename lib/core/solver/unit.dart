import 'dart:math';

enum Unit {
  scalar(-1, "scalar", ""),
  percent(-2, "percent", "%"),
  permille(-3, "permille", "‰"),
  fraction(-4, "fraction", ""),
  radian(0, "radian", "rad"),
  degree(1, "degree", "°"),
  moa(2, "MOA", "MOA"),
  mil(3, "MIL", "MIL"),
  mRad(4, "MRAD", "MRAD"),
  thousandth(5, "thousandth", "ths"),
  inPer100Yd(6, "inch/100yd", "in/100yd"),
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

  static Unit? fromName(String name) {
    for (var unit in values) {
      if (unit.name == name) return unit;
    }
    return null;
  }
}

abstract class Dimension<T extends Dimension<T>> {
  late double _value;
  final Unit _units;

  Dimension(double value, this._units) {
    _value = _toRaw(value, _units);
  }

  Map<Unit, double> get conversionFactors => <Unit, double>{};

  double get value => toDouble();
  double get raw => _value;
  Unit get units => _units;

  double in_(Unit unit) => _fromRaw(_value, unit);

  T to(Unit unit) => _create(in_(unit), unit);

  @override
  String toString() {
    final rounded = toDouble().toStringAsFixed(6);
    return '$rounded${_units.symbol}';
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
      '$runtimeType(rawValue: $_value, units: ${_units.label})';

  double toDouble() => _fromRaw(_value, _units);

  static Dimension<dynamic> auto(Object value, Unit units) {
    final id = units.id;
    if (value is Dimension) {
      return value.to(units);
    }

    final double val = (value as num).toDouble();

    if (id < 0) return Ratio(val, units);
    if (id >= 0 && id < 10) return Angular(val, units);
    if (id >= 10 && id < 20) return Distance(val, units);
    if (id >= 30 && id < 40) return Energy(val, units);
    if (id >= 40 && id < 50) return Pressure(val, units);
    if (id >= 50 && id < 60) return Temperature(val, units);
    if (id >= 60 && id < 70) return Velocity(val, units);
    if (id >= 70 && id < 80) return Weight(val, units);
    if (id >= 80 && id < 90) return Time(val, units);

    throw Exception('Unit ID $id is not supported for casting');
  }
}

class Angular extends Dimension<Angular> {
  Angular(super.value, super.unit);

  static const rawUnit = Unit.radian;
  static bool accepts(Unit u) => u.id >= 0 && u.id < 10;

  static final _conversionFactors = <Unit, double>{
    Unit.radian: 1.0,
    Unit.degree: pi / 180,
    Unit.moa: pi / (60 * 180),
    Unit.mil: pi / 3200,
    Unit.mRad: 1.0 / 1000,
    Unit.thousandth: pi / 3000,
    Unit.inPer100Yd: 1.0 / 3600,
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

  static const rawUnit = Unit.footPound;
  static bool accepts(Unit u) => u.id >= 30 && u.id < 40;

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

  static const rawUnit = Unit.inch;
  static bool accepts(Unit u) => u.id >= 10 && u.id < 20;

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

  static const rawUnit = Unit.mmHg;
  static bool accepts(Unit u) => u.id >= 40 && u.id < 50;

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

  static const rawUnit = Unit.fahrenheit;
  static bool accepts(Unit u) => u.id >= 50 && u.id < 60;

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
  double _fromRaw(double rawValue, Unit unit) {
    return switch (unit) {
      Unit.fahrenheit => rawValue,
      Unit.rankin => rawValue + 459.67,
      Unit.celsius => (rawValue - 32) * 5.0 / 9,
      Unit.kelvin => (rawValue - 32) * 5.0 / 9 + 273.15,
      _ => throw Exception('Temperature does not support $unit'),
    };
  }
}

class Time extends Dimension<Time> {
  Time(super.value, super.unit);

  static const rawUnit = Unit.second;
  static bool accepts(Unit u) => u.id >= 80 && u.id < 90;

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

  static const rawUnit = Unit.mps;
  static bool accepts(Unit u) => u.id >= 60 && u.id < 70;

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

  static const rawUnit = Unit.grain;
  static bool accepts(Unit u) => u.id >= 70 && u.id < 80;

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

class Ratio extends Dimension<Ratio> {
  Ratio(super.value, super.unit);

  static const rawUnit = Unit.scalar;
  static bool accepts(Unit u) => u.id < 0; // All negative IDs

  static final _conversionFactors = <Unit, double>{
    Unit.scalar: 1.0,
    Unit.percent: 0.01,
    Unit.permille: 0.001,
    Unit.fraction: 1.0,
  };

  @override
  Map<Unit, double> get conversionFactors => _conversionFactors;

  @override
  Ratio _create(double value, Unit unit) => Ratio(value, unit);

  @override
  double _toRaw(double value, Unit unit) {
    if (unit == Unit.scalar) return value;
    if (unit == Unit.percent) return value * 0.01;
    if (unit == Unit.permille) return value * 0.001;
    if (unit == Unit.fraction) return value;
    return super._toRaw(value, unit);
  }

  @override
  double _fromRaw(double rawValue, Unit unit) {
    if (unit == Unit.scalar) return rawValue;
    if (unit == Unit.percent) return rawValue * 100;
    if (unit == Unit.permille) return rawValue * 1000;
    if (unit == Unit.fraction) return rawValue;
    return super._fromRaw(rawValue, unit);
  }
}

extension UnitConvertor on double {
  double convert(Unit from, Unit to) {
    if (from == to) {
      return this;
    }
    return Dimension.auto(this, from).in_(to);
  }
}
