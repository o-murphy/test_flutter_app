import 'dart:math' as math;
import 'package:eballistica/core/solver/constants.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/core/solver/vector.dart';

class Atmo {
  late Distance _altitude;
  late Pressure _pressure;
  late Temperature _temperature;
  late Temperature _powderTemp;
  late double _humidity;

  late double _densityRatio;
  late double _mach;
  late double _t0;
  late double _p0;

  static final double cLowestTempC = Temperature(
    BallisticConstants.cLowestTempF,
    Unit.fahrenheit,
  ).in_(Unit.celsius);

  bool _initializing = true;

  Atmo({
    Distance? altitude,
    Pressure? pressure,
    Temperature? temperature,
    double humidity = 0.0,
    Temperature? powderTemperature,
  }) {
    _initializing = true;

    _altitude = altitude ?? Distance(0, Unit.meter);
    _temperature = temperature ?? Atmo.standardTemperature(_altitude);
    _pressure = pressure ?? Atmo.standardPressure(_altitude);
    _powderTemp =
        powderTemperature ?? temperature ?? Atmo.standardTemperature(_altitude);

    _t0 = _temperature.in_(Unit.celsius);
    _p0 = _pressure.in_(Unit.hPa);
    _mach = Atmo.machF(_temperature.in_(Unit.fahrenheit));

    this.humidity = humidity;

    _initializing = false;
    updateDensityRatio();
  }

  // --- Getters ---
  Distance get altitude => _altitude;
  Pressure get pressure => _pressure;
  Temperature get temperature => _temperature;
  Temperature get powderTemp => _powderTemp;
  double get densityRatio => _densityRatio;
  Velocity get mach => Velocity(_mach, Unit.fps);
  double get humidity => _humidity;

  // --- Setters ---
  set humidity(double value) {
    if (value < 0 || value > 100) {
      throw ArgumentError('Humidity must be between 0% and 100%.');
    }
    _humidity = (value > 1.0) ? value / 100.0 : value;
    if (!_initializing) updateDensityRatio();
  }

  void updateDensityRatio() {
    _densityRatio =
        calculateAirDensity(_t0, _p0, _humidity) /
        BallisticConstants.cStandardDensityMetric;
  }

  double get densityMetric =>
      _densityRatio * BallisticConstants.cStandardDensityMetric;
  double get densityImperial =>
      _densityRatio * BallisticConstants.cStandardDensity;

  // --- Static Methods ---

  static Temperature standardTemperature(Distance altitude) => Temperature(
    BallisticConstants.cStandardTemperatureF +
        altitude.in_(Unit.foot) * BallisticConstants.cLapseRateImperial,
    Unit.fahrenheit,
  );

  static Pressure standardPressure(Distance altitude) => Pressure(
    BallisticConstants.cStandardPressureMetric *
        math.pow(
          1 +
              (BallisticConstants.cLapseRateMetric * altitude.in_(Unit.meter)) /
                  (BallisticConstants.cStandardTemperatureC +
                      BallisticConstants.cDegreesCtoK),
          BallisticConstants.cPressureExponent,
        ),
    Unit.hPa,
  );

  factory Atmo.icao({
    Distance? altitude,
    Temperature? temperature,
    double humidity = 0.0,
  }) {
    final alt = altitude ?? Distance(0, Unit.meter);
    return Atmo(
      altitude: alt,
      pressure: Atmo.standardPressure(alt),
      temperature: temperature ?? Atmo.standardTemperature(alt),
      humidity: humidity,
    );
  }

  static double machF(double fahrenheit) {
    double temp = fahrenheit;
    if (fahrenheit < -BallisticConstants.cDegreesFtoR) {
      // ignore: avoid_print
      print(
        'Invalid temperature: $fahrenheit°F. Adjusted to ${BallisticConstants.cLowestTempF}°F.',
      );
      temp = BallisticConstants.cLowestTempF;
    }
    return math.sqrt(temp + BallisticConstants.cDegreesFtoR) *
        BallisticConstants.cSpeedOfSoundImperial;
  }

  static double calculateAirDensity(
    double tCelsius,
    double p_hpa,
    double humidityFraction,
  ) {
    const double R = 8.314472;
    const double Ma = 28.96546e-3;
    const double Mv = 18.01528e-3;

    double saturationVaporPressure(double tk) {
      const A = [1.2378847e-5, -1.9121316e-2, 33.93711047, -6.3431645e3];
      return math.exp(A[0] * math.pow(tk, 2) + A[1] * tk + A[2] + A[3] / tk);
    }

    double enhancementFactor(double p, double t) =>
        1.00062 + 3.14e-8 * p + 5.6e-7 * math.pow(t, 2);

    double compressibilityFactor(double p, double tk, double xv) {
      final tl = tk - BallisticConstants.cDegreesCtoK;
      const a = [1.58123e-6, -2.9331e-8, 1.1043e-10];
      const b = [5.707e-6, -2.051e-8];
      const c = [1.9898e-4, -2.376e-6];
      const d = 1.83e-11;
      const e = -0.765e-8;
      return 1 -
          (p / tk) *
              (a[0] +
                  a[1] * tl +
                  a[2] * math.pow(tl, 2) +
                  (b[0] + b[1] * tl) * xv +
                  (c[0] + c[1] * tl) * math.pow(xv, 2)) +
          math.pow(p / tk, 2) * (d + e * math.pow(xv, 2));
    }

    final tk = tCelsius + BallisticConstants.cDegreesCtoK;
    final pPa = p_hpa * 100.0;
    final psv = saturationVaporPressure(tk);
    final f = enhancementFactor(pPa, tCelsius);
    final pv = humidityFraction * f * psv;
    final xv = pv / pPa;
    final z = compressibilityFactor(pPa, tk, xv);

    return ((pPa * Ma) / (z * R * tk)) * (1 - xv * (1 - Mv / Ma));
  }
}

class Vacuum extends Atmo {
  static final double cLowestTempC = -BallisticConstants.cDegreesCtoK;

  Vacuum({super.altitude, super.temperature})
    : super(pressure: Pressure(0, Unit.hPa), humidity: 0);

  @override
  void updateDensityRatio() => _densityRatio = 0.0;
}

class Wind {
  final Velocity velocity;
  final Angular directionFrom;
  final Distance untilDistance;

  static double maxDistanceFeet = BallisticConstants.cMaxWindDistanceFeet;

  Wind({
    Velocity? velocity,
    Angular? directionFrom,
    Distance? untilDistance,
    double? customMaxDistanceFeet,
  }) : velocity = velocity ?? Velocity(0, Unit.mps),
       directionFrom = directionFrom ?? Angular(0, Unit.radian),
       untilDistance =
           untilDistance ??
           Distance(customMaxDistanceFeet ?? maxDistanceFeet, Unit.foot) {
    if (customMaxDistanceFeet != null) {
      maxDistanceFeet = customMaxDistanceFeet;
    }
  }

  @override
  String toString() =>
      'Wind(Vel: $velocity, From: $directionFrom, Until: $untilDistance)';
}

class Coriolis {
  final double sinLat;
  final double cosLat;
  final double? sinAz;
  final double? cosAz;
  final double? rangeEast;
  final double? rangeNorth;
  final double? crossEast;
  final double? crossNorth;
  final bool flatFireOnly;
  final double muzzleVelocityFps;

  Coriolis._({
    required this.sinLat,
    required this.cosLat,
    required this.muzzleVelocityFps,
    this.sinAz,
    this.cosAz,
    this.rangeEast,
    this.rangeNorth,
    this.crossEast,
    this.crossNorth,
    required this.flatFireOnly,
  });

  static Coriolis? create({
    double? latitude,
    double? azimuth,
    required double muzzleVelocityFps,
  }) {
    if (latitude == null) return null;

    final latRad = latitude * (math.pi / 180.0);
    final sinLat = math.sin(latRad);
    final cosLat = math.cos(latRad);

    if (azimuth == null) {
      return Coriolis._(
        sinLat: sinLat,
        cosLat: cosLat,
        muzzleVelocityFps: muzzleVelocityFps,
        flatFireOnly: true,
      );
    }

    final azRad = azimuth * (math.pi / 180.0);
    final sAz = math.sin(azRad);
    final cAz = math.cos(azRad);

    return Coriolis._(
      sinLat: sinLat,
      cosLat: cosLat,
      muzzleVelocityFps: muzzleVelocityFps,
      sinAz: sAz,
      cosAz: cAz,
      rangeEast: sAz,
      rangeNorth: cAz,
      crossEast: cAz,
      crossNorth: -sAz,
      flatFireOnly: false,
    );
  }

  bool get isFull3d => !flatFireOnly;

  Vector coriolisAccelerationLocal(Vector velocity) {
    if (!isFull3d) return Vector.zero;

    final velEast = velocity.x * rangeEast! + velocity.z * crossEast!;
    final velNorth = velocity.x * rangeNorth! + velocity.z * crossNorth!;
    final velUp = velocity.y;

    const factor = -2.0 * BallisticConstants.cEarthAngularVelocityRadS;

    final accelEast = factor * (cosLat * velUp - sinLat * velNorth);
    final accelNorth = factor * (sinLat * velEast);
    final accelUp = factor * (-cosLat * velEast);

    final accelRange = accelEast * rangeEast! + accelNorth * rangeNorth!;
    final accelCross = accelEast * crossEast! + accelNorth * crossNorth!;

    return Vector(accelRange, accelUp, accelCross);
  }

  (double vertical, double horizontal) flatFireOffsets(
    double time,
    double distanceFt,
    double dropFt,
  ) {
    if (isFull3d) return (0.0, 0.0);

    final horizontal =
        BallisticConstants.cEarthAngularVelocityRadS *
        distanceFt *
        sinLat *
        time;

    double vertical = 0.0;
    if (sinAz != null) {
      final verticalFactor =
          -2.0 *
          BallisticConstants.cEarthAngularVelocityRadS *
          muzzleVelocityFps *
          cosLat *
          sinAz!;
      vertical =
          dropFt * (verticalFactor / BallisticConstants.cGravityImperial);
    }

    return (vertical, horizontal);
  }

  Vector adjustPosition(double time, Vector position) {
    if (isFull3d) return position;

    final (deltaY, deltaZ) = flatFireOffsets(time, position.x, position.y);
    if (deltaY == 0.0 && deltaZ == 0.0) return position;

    return Vector(position.x, position.y + deltaY, position.z + deltaZ);
  }
}
