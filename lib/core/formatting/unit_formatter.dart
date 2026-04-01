import 'package:eballistica/core/solver/unit.dart';

/// A single contract for formatting physical quantities into strings for UI.
/// ViewModel і Widget never call .in_() directly.
abstract interface class UnitFormatter {
  // --- Formatted strings (with unit) ---
  String velocity(Velocity dim); // "888 m/s"
  String distance(Distance dim); // "300 m"
  String temperature(Temperature dim); // "15 °C"
  String pressure(Pressure dim); // "1013 hPa"
  String drop(Distance dim); // "−12.5 cm"
  String windage(Distance dim); // "3.2 cm"
  String adjustment(Angular dim); // "3.45 MIL"
  String energy(Energy dim); // "4200 J"
  String weight(Weight dim); // "250 gr"
  String sightHeight(Distance dim); // "8.5 mm"
  String twist(Distance dim); // "1:10 inch"
  String humidity(Ratio dim); // "50 %"
  String mach(double mach); // "0.85 M"
  String time(double seconds); // "1.234 s"
  String powderSensitivity(Ratio dim); // "2.00 %"

  // --- Raw numbers (without units, for sliders/input fields) ---
  double rawVelocity(Velocity dim);
  double rawDistance(Distance dim);
  double rawTemperature(Temperature dim);
  double rawPressure(Pressure dim);
  double rawDrop(Distance dim);
  double rawAdjustment(Angular dim);
  double rawEnergy(Energy dim);
  double rawWeight(Weight dim);
  double rawSightHeight(Distance dim);

  // --- Current unit symbols ---
  String get velocitySymbol;
  String get distanceSymbol;
  String get temperatureSymbol;
  String get pressureSymbol;
  String get dropSymbol;
  String get adjustmentSymbol;
  String get energySymbol;
  String get weightSymbol;
  String get sightHeightSymbol;

  /// Converts user input value (in display unit) back to raw storage unit.
  double inputToRaw(double displayValue, InputField field);
  double rawToInput(double rawValue, InputField field);
}

/// Indicates which field the user enters — for reverse conversion
enum InputField {
  velocity,
  distance,
  temperature,
  pressure,
  humidity,
  windVelocity,
  lookAngle,
  targetDistance,
  zeroDistance,
  sightHeight,
  twist,
  bulletWeight,
  bulletLength,
  bulletDiameter,
  bc,
}
