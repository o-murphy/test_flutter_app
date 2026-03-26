/// Global physical and atmospheric constants for ballistic calculations.
/// All constants follow international standards (ISA, ICAO).
abstract final class BallisticConstants {
  BallisticConstants._();

  static const double cGravityImperial = 32.17405; // ft/s²
  static const double cEarthAngularVelocityRadS = 7.2921159e-5; // rad/s

  // ===========================================================================
  // Global Atmosphere Constants
  // ===========================================================================

  static const double cStandardHumidity = 0.0; // %
  static const double cPressureExponent = 5.255876;

  // Atmospheric model coefficients
  static const double cA0 = 1.24871;
  static const double cA1 = 0.0988438;
  static const double cA2 = 0.00152907;
  static const double cA3 = -3.07031e-06;
  static const double cA4 = 4.21329e-07;
  static const double cA5 = 3.342e-04;

  // ===========================================================================
  // ISA Metric Constants (International Standard Atmosphere)
  // ===========================================================================

  static const double cStandardTemperatureC = 15.0; // °C
  static const double cLapseRateKperFoot = -0.0019812; // K/ft
  static const double cLapseRateMetric = -6.5e-03; // °C/m
  static const double cStandardPressureMetric = 1013.25; // hPa
  static const double cSpeedOfSoundMetric = 20.0467; // m/s per √K
  static const double cStandardDensityMetric = 1.2250; // kg/m³
  static const double cDegreesCtoK = 273.15; // K = °C + 273.15

  // ===========================================================================
  // ICAO Standard Atmosphere Constants
  // ===========================================================================

  static const double cStandardTemperatureF = 59.0; // °F
  static const double cLapseRateImperial = -3.56616e-03; // °F/ft
  static const double cStandardPressure = 29.92; // InHg
  static const double cSpeedOfSoundImperial = 49.0223; // fps per √°R
  static const double cStandardDensity = 0.076474; // lb/ft³
  static const double cDegreesFtoR = 459.67; // °R = °F + 459.67

  // ===========================================================================
  // Conversion Factors & Runtime Limits
  // ===========================================================================

  static const double cDensityImperialToMetric = 16.0185;
  static const double cLowestTempF = -130.0; // °F
  static const double cMaxWindDistanceFeet = 1e8;
}
