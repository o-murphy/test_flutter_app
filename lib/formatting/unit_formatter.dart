// ЧИСТИЙ DART — без Flutter імпортів

/// Єдиний контракт для форматування фізичних величин у рядки для UI.
/// ViewModel і Widget ніколи не викликають .in_() напряму.
abstract interface class UnitFormatter {
  // --- Форматовані рядки (з одиницею) ---
  String velocity(dynamic dim); // "888 m/s"
  String distance(dynamic dim); // "300 m"
  String shortDistance(dynamic dim); // "300" (без символу, для compact UI)
  String temperature(dynamic dim); // "15 °C"
  String pressure(dynamic dim); // "1013 hPa"
  String drop(dynamic dim); // "−12.5 cm"
  String windage(dynamic dim); // "3.2 cm"
  String adjustment(dynamic dim); // "3.45 MIL"
  String energy(dynamic dim); // "4200 J"
  String weight(dynamic dim); // "250 gr"
  String sightHeight(dynamic dim); // "8.5 mm"
  String twist(dynamic dim); // "1:10 inch"
  String humidity(double fraction); // "50 %"
  String mach(double mach); // "0.85 M"
  String time(double seconds); // "1.234 s"
  String muzzleVelocity(dynamic dim); // спеціальна точність для MV

  // --- Сирі числа (без одиниці, для слайдерів/полів вводу) ---
  double rawVelocity(dynamic dim);
  double rawDistance(dynamic dim);
  double rawTemperature(dynamic dim);
  double rawPressure(dynamic dim);
  double rawDrop(dynamic dim);
  double rawAdjustment(dynamic dim);
  double rawEnergy(dynamic dim);
  double rawWeight(dynamic dim);
  double rawSightHeight(dynamic dim);

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
