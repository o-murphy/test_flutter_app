import 'dart:math';

enum Unit {
  radian(0, "radian", 6, "rad"),
  degree(1, "degree", 4, "°"),
  moa(2, "MOA", 2, "MOA"),
  mil(3, "MIL", 3, "MIL"),
  mRad(4, "MRAD", 2, "MRAD"),
  thousandth(5, "thousandth", 2, "ths"),
  inchesPer100Yd(6, "inch/100yd", 2, "in/100yd"),
  cmPer100m(7, "cm/100m", 2, "cm/100m"),
  oClock(8, "hour", 2, "h"),
  inch(10, "inch", 1, "inch"),
  foot(11, "foot", 2, "ft"),
  yard(12, "yard", 1, "yd"),
  mile(13, "mile", 3, "mi"),
  nauticalMile(14, "nautical mile", 3, "nm"),
  millimeter(15, "millimeter", 3, "mm"),
  centimeter(16, "centimeter", 3, "cm"),
  meter(17, "meter", 1, "m"),
  kilometer(18, "kilometer", 3, "km"),
  line(19, "line", 3, "ln"),
  footPound(30, "foot-pound", 0, "ft·lb"),
  joule(31, "joule", 0, "J"),
  mmHg(40, "mmHg", 0, "mmHg"),
  inHg(41, "inHg", 6, "inHg"),
  bar(42, "bar", 2, "bar"),
  hPa(43, "hPa", 4, "hPa"),
  psi(44, "psi", 4, "psi"),
  fahrenheit(50, "fahrenheit", 1, "°F"),
  celsius(51, "celsius", 1, "°C"),
  kelvin(52, "kelvin", 1, "°K"),
  rankin(53, "rankin", 1, "°R"),
  mps(60, "mps", 0, "m/s"),
  kmh(61, "kmh", 1, "km/h"),
  fps(62, "fps", 1, "ft/s"),
  mph(63, "mph", 1, "mph"),
  kt(64, "knot", 1, "kt"),
  grain(70, "grain", 1, "gr"),
  ounce(71, "ounce", 1, "oz"),
  gram(72, "gram", 1, "g"),
  pound(73, "pound", 0, "lb"),
  kilogram(74, "kilogram", 3, "kg"),
  newton(75, "newton", 3, "N"),
  minute(80, "minute", 0, "min"),
  second(81, "second", 1, "s"),
  millisecond(82, "millisecond", 3, "ms"),
  microsecond(83, "microsecond", 6, "µs"),
  nanosecond(84, "nanosecond", 9, "ns"),
  picosecond(85, "picosecond", 12, "ps");

  const Unit(this.id, this.label, this.accuracy, this.symbol);
  final int id;
  final String label;
  final int accuracy;
  final String symbol;
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
      final value = double.parse(match.group(1)!);
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
    _rawValue = toRaw(value, _definedUnits);
  }

  Map<Unit, double> get conversionFactors => <Unit, double>{};

  double get rawValue => _rawValue;

  Unit get units => _definedUnits;

  @override
  String toString() {
    final v = fromRaw(_rawValue, _definedUnits);
    final rounded = v.toStringAsFixed(_definedUnits.accuracy);
    return '$rounded${_definedUnits.symbol}';
  }

  T create(double value, Unit unit);

  T createFromRaw(double value, Unit unit) =>
      create(fromRaw(value, unit), unit);

  double _getFactor(Unit unit) {
    final factor = conversionFactors[unit];
    if (factor == null) {
      throw Exception('$runtimeType: unit ${unit.label} is not supported');
    }
    return factor;
  }

  double in_(Unit unit) => fromRaw(_rawValue, unit);

  T to(Unit unit) => create(in_(unit), unit);

  double toRaw(double value, Unit unit) => value * _getFactor(unit);

  double fromRaw(double rawValue, Unit unit) => rawValue / _getFactor(unit);

  String get debugDetails =>
      '$runtimeType(rawValue: $_rawValue, units: ${_definedUnits.label})';

  double toDouble() => fromRaw(_rawValue, _definedUnits);

  double get _unitsToRawDelta {
    if (conversionFactors.isEmpty) return 0.0;
    return _getFactor(_definedUnits);
  }

  T operator *(Object other) {
    if (other is num) {
      // self._value * other
      return createFromRaw(_rawValue * other.toDouble(), _definedUnits);
    }
    throw ArgumentError('Multiplication is only supported for numbers');
  }

  dynamic operator /(Object other) {
    if (other is num) {
      if (other == 0) throw ArgumentError('Division by zero');
      // self._value / other
      return createFromRaw(_rawValue / other.toDouble(), _definedUnits);
    }
    if (other is T) {
      if (other.rawValue == 0) throw ArgumentError('Division by zero');
      // float(self._value) / float(other.raw_value)
      return _rawValue / other.rawValue;
    }
    throw ArgumentError(
      'Division is only supported for numbers or same Dimension',
    );
  }

  T operator +(Object other) {
    if (other is num) {
      // self._value + float(other) * self._units_to_raw_delta()
      return createFromRaw(
        _rawValue + (other.toDouble() * _unitsToRawDelta),
        _definedUnits,
      );
    }
    if (other is T) {
      // self._value + other._value
      return createFromRaw(_rawValue + other.rawValue, _definedUnits);
    }
    throw ArgumentError(
      'Addition is only supported for numbers or same Dimension',
    );
  }

  T operator -(Object other) {
    if (other is num) {
      return createFromRaw(
        _rawValue - (other.toDouble() * _unitsToRawDelta),
        _definedUnits,
      );
    }
    if (other is T) {
      return createFromRaw(_rawValue - other.rawValue, _definedUnits);
    }
    throw ArgumentError(
      'Subtraction is only supported for numbers or same Dimension',
    );
  }
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
  Angular create(double value, Unit unit) => Angular(value, unit);

  @override
  double toRaw(double value, Unit unit) {
    // Note: The logic here remains the same,
    // ensuring the result is normalized between (-pi, pi]
    final radians = super.toRaw(value, unit);
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
  Energy create(double value, Unit unit) => Energy(value, unit);
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
  Distance create(double value, Unit unit) => Distance(value, unit);
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
  Pressure create(double value, Unit unit) => Pressure(value, unit);
}

class Temperature extends Dimension<Temperature> {
  Temperature(super.value, super.unit);

  @override
  Map<Unit, double> get conversionFactors => const {};

  @override
  Temperature create(double value, Unit unit) => Temperature(value, unit);

  @override
  double toRaw(double value, Unit unit) {
    return switch (unit) {
      Unit.fahrenheit => value,
      Unit.rankin => value - 459.67,
      Unit.celsius => value * 9.0 / 5 + 32,
      Unit.kelvin => (value - 273.15) * 9.0 / 5 + 32,
      _ => throw Exception('Temperature does not support $unit'),
    };
  }

  @override
  double fromRaw(double value, Unit unit) {
    return switch (unit) {
      Unit.fahrenheit => value,
      Unit.rankin => value + 459.67,
      Unit.celsius => (value - 32) * 5.0 / 9,
      Unit.kelvin => (value - 32) * 5.0 / 9 + 273.15,
      _ => throw Exception('Temperature does not support $unit'),
    };
  }

  @override
  double get _unitsToRawDelta {
    return switch (units) {
      Unit.fahrenheit || Unit.rankin => 1.0,
      Unit.celsius || Unit.kelvin => 9.0 / 5.0,
      _ => 1.0,
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
  Time create(double value, Unit unit) => Time(value, unit);
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
  Velocity create(double value, Unit unit) => Velocity(value, unit);
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
  Weight create(double value, Unit unit) => Weight(value, unit);
}
