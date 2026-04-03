import 'package:eballistica/core/providers/convertors_notifier.dart';
import 'package:eballistica/features/convertors/generic_convertor_vm_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

class TemperatureConvertorUiState {
  final GenericConvertorField fahrenheit;
  final GenericConvertorField celsius;
  final double? rawValue;
  final Unit inputUnit;

  const TemperatureConvertorUiState({
    required this.fahrenheit,
    required this.celsius,
    required this.rawValue,
    required this.inputUnit,
  });
}

class TemperatureConvertorViewModel
    extends Notifier<TemperatureConvertorUiState> {
  @override
  TemperatureConvertorUiState build() {
    final convertorsState = ref.watch(convertorStateProvider);
    return _buildState(
      convertorsState.temperatureValueFahrenheit,
      convertorsState.temperatureUnit,
    );
  }

  void updateRawValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);

    if (rawValueInInputUnit == null) {
      ref.read(convertorsProvider.notifier).updateTemperatureValue(null);
      return;
    }

    final fahrenheitValue = rawValueInInputUnit.convert(
      convertorsState.temperatureUnit,
      Unit.fahrenheit,
    );
    ref
        .read(convertorsProvider.notifier)
        .updateTemperatureValue(fahrenheitValue);
  }

  void changeInputUnit(Unit newUnit) {
    ref.read(convertorsProvider.notifier).updateTemperatureUnit(newUnit);
  }

  double? _getDisplayValue(double? rawFahrenheit, Unit inputUnit) {
    if (rawFahrenheit == null) return null;
    return rawFahrenheit.convert(Unit.fahrenheit, inputUnit);
  }

  FieldConstraints getConstraintsForUnit(Unit unit) {
    final minInFahrenheit = -459.67; // Абсолютний нуль
    final maxInFahrenheit = 10000.0;

    return FieldConstraints(
      minRaw: minInFahrenheit.convert(Unit.fahrenheit, unit),
      maxRaw: maxInFahrenheit.convert(Unit.fahrenheit, unit),
      stepRaw: _getStepForUnit(unit),
      rawUnit: unit,
      accuracy: _getAccuracyForUnit(unit),
    );
  }

  double _getStepForUnit(Unit unit) {
    switch (unit) {
      case Unit.celsius:
        return 0.1;
      case Unit.fahrenheit:
        return 0.1;
      default:
        return 1.0;
    }
  }

  int _getAccuracyForUnit(Unit unit) {
    switch (unit) {
      case Unit.celsius:
        return 1;
      case Unit.fahrenheit:
        return 1;
      default:
        return 1;
    }
  }

  String _formatValue(double value, int decimals, String symbol) {
    if (value.isNaN || value.isInfinite) return '— $symbol';
    return '${value.toStringAsFixed(decimals)} $symbol';
  }

  TemperatureConvertorUiState _buildState(
    double rawFahrenheit,
    Unit inputUnit,
  ) {
    final fahrenheitRaw = rawFahrenheit;
    final celsiusRaw = fahrenheitRaw.convert(Unit.fahrenheit, Unit.celsius);

    final fahrenheitAccuracy = _getAccuracyForUnit(Unit.fahrenheit);
    final celsiusAccuracy = _getAccuracyForUnit(Unit.celsius);

    return TemperatureConvertorUiState(
      rawValue: _getDisplayValue(rawFahrenheit, inputUnit),
      inputUnit: inputUnit,
      fahrenheit: GenericConvertorField(
        label: 'Fahrenheit',
        formattedValue: _formatValue(
          fahrenheitRaw,
          fahrenheitAccuracy,
          Unit.fahrenheit.symbol,
        ),
        value: fahrenheitRaw,
        symbol: Unit.fahrenheit.symbol,
        decimals: fahrenheitAccuracy,
      ),
      celsius: GenericConvertorField(
        label: 'Celsius',
        formattedValue: _formatValue(
          celsiusRaw,
          celsiusAccuracy,
          Unit.celsius.symbol,
        ),
        value: celsiusRaw,
        symbol: Unit.celsius.symbol,
        decimals: celsiusAccuracy,
      ),
    );
  }
}

final temperatureConvertorVmProvider =
    NotifierProvider<
      TemperatureConvertorViewModel,
      TemperatureConvertorUiState
    >(TemperatureConvertorViewModel.new);
