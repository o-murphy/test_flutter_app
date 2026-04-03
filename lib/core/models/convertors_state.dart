import 'package:eballistica/core/solver/unit.dart';

// В файлі convertors_state.dart

class ConvertorsState {
  final double lengthValueInch;
  final Unit lengthUnit;
  final double weightValueGrain;
  final Unit weightUnit;
  final double pressureValueMmHg; // Базова одиниця - mmHg
  final Unit pressureUnit;

  const ConvertorsState({
    this.lengthValueInch = 100.0,
    this.lengthUnit = Unit.inch,
    this.weightValueGrain = 100.0,
    this.weightUnit = Unit.grain,
    this.pressureValueMmHg = 1013.0, // Стандартний тиск 1013 hPa = 760 mmHg
    this.pressureUnit = Unit.hPa, // За замовчуванням показуємо в hPa
  });

  ConvertorsState copyWith({
    double? lengthValueInch,
    Unit? lengthUnit,
    double? weightValueGrain,
    Unit? weightUnit,
    double? pressureValueMmHg,
    Unit? pressureUnit,
  }) {
    return ConvertorsState(
      lengthValueInch: lengthValueInch ?? this.lengthValueInch,
      lengthUnit: lengthUnit ?? this.lengthUnit,
      weightValueGrain: weightValueGrain ?? this.weightValueGrain,
      weightUnit: weightUnit ?? this.weightUnit,
      pressureValueMmHg: pressureValueMmHg ?? this.pressureValueMmHg,
      pressureUnit: pressureUnit ?? this.pressureUnit,
    );
  }

  Map<String, dynamic> toJson() => {
    'lengthValue': lengthValueInch,
    'lengthUnit': lengthUnit.name,
    'weightValue': weightValueGrain,
    'weightUnit': weightUnit.name,
    'pressureValue': pressureValueMmHg,
    'pressureUnit': pressureUnit.name,
  };

  factory ConvertorsState.fromJson(Map<String, dynamic> json) {
    double d(String key, double defaultValue) {
      return (json[key] as num?)?.toDouble() ?? defaultValue;
    }

    Unit u(String key, Unit fallback, bool Function(Unit) accepts) {
      final name = json[key] as String?;
      final unit = name != null ? Unit.fromName(name) : null;
      return (unit != null && accepts(unit)) ? unit : fallback;
    }

    return ConvertorsState(
      lengthValueInch: d('lengthValue', 100.0),
      lengthUnit: u('lengthUnit', Unit.inch, Distance.accepts),
      weightValueGrain: d('weightValue', 100.0),
      weightUnit: u('weightUnit', Unit.grain, Weight.accepts),
      pressureValueMmHg: d('pressureValue', 1013.0),
      pressureUnit: u('pressureUnit', Unit.hPa, Pressure.accepts),
    );
  }
}
