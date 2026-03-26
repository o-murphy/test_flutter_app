// ЧИСТИЙ DART — без Flutter імпортів

import 'package:eballistica/core/solver/unit.dart';

/// Єдиний контракт для форматування фізичних величин у рядки для UI.
/// ViewModel і Widget ніколи не викликають .in_() напряму.
abstract interface class UnitFormatter {
  // --- Форматовані рядки (з одиницею) ---
  String velocity(Velocity dim); // "888 m/s"
  String distance(Distance dim); // "300 m"
  String shortDistance(Distance dim); // "300" (без символу, для compact UI)
  String temperature(Temperature dim); // "15 °C"
  String pressure(Pressure dim); // "1013 hPa"
  String drop(Distance dim); // "−12.5 cm"
  String windage(Distance dim); // "3.2 cm"
  String adjustment(Angular dim); // "3.45 MIL"
  String energy(Energy dim); // "4200 J"
  String weight(Weight dim); // "250 gr"
  String sightHeight(Distance dim); // "8.5 mm"
  String twist(Distance dim); // "1:10 inch"
  String humidity(double fraction); // "50 %"
  String mach(double mach); // "0.85 M"
  String time(double seconds); // "1.234 s"
  String muzzleVelocity(Velocity dim); // спеціальна точність для MV

  // --- Сирі числа (без одиниці, для слайдерів/полів вводу) ---
  double rawVelocity(Velocity dim);
  double rawDistance(Distance dim);
  double rawTemperature(Temperature dim);
  double rawPressure(Pressure dim);
  double rawDrop(Distance dim);
  double rawAdjustment(Angular dim);
  double rawEnergy(Energy dim);
  double rawWeight(Weight dim);
  double rawSightHeight(Distance dim);

  // --- Символи поточних одиниць ---
  String get velocitySymbol;
  String get distanceSymbol;
  String get temperatureSymbol;
  String get pressureSymbol;
  String get dropSymbol;
  String get adjustmentSymbol;
  String get energySymbol;
  String get weightSymbol;
  String get sightHeightSymbol;

  // --- Конвертація введення користувача назад у raw (для діалогів) ---
  /// Converts user input value (in display unit) back to raw storage unit.
  double inputToRaw(double displayValue, InputField field);
  double rawToInput(double rawValue, InputField field);
}

/// Позначає яке поле вводить користувач — для зворотної конвертації
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
