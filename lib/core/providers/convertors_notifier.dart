import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/models/convertors_state.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'storage_provider.dart';

class ConvertorsNotifier extends AsyncNotifier<ConvertorsState> {
  @override
  Future<ConvertorsState> build() async {
    final storage = ref.read(appStorageProvider);
    final saved = await storage.loadConvertorsState();
    return saved ?? const ConvertorsState();
  }

  Future<void> updateLengthValue(double? valueInInches) async {
    if (valueInInches != null && valueInInches >= 0) {
      final current = state.value ?? const ConvertorsState();
      await _save(current.copyWith(lengthValueInch: valueInInches));
    }
  }

  Future<void> updateLengthUnit(Unit unit) async {
    final current = state.value ?? const ConvertorsState();
    await _save(current.copyWith(lengthUnit: unit));
  }

  Future<void> updateWeightValue(double? valueInGrains) async {
    if (valueInGrains != null && valueInGrains >= 0) {
      final current = state.value ?? const ConvertorsState();
      await _save(current.copyWith(weightValueGrain: valueInGrains));
    }
  }

  Future<void> updateWeightUnit(Unit unit) async {
    final current = state.value ?? const ConvertorsState();
    await _save(current.copyWith(weightUnit: unit));
  }

  Future<void> updatePressureValue(double? valueInMmHg) async {
    if (valueInMmHg != null && valueInMmHg >= 0) {
      final current = state.value ?? const ConvertorsState();
      await _save(current.copyWith(pressureValueMmHg: valueInMmHg));
    }
  }

  Future<void> updatePressureUnit(Unit unit) async {
    final current = state.value ?? const ConvertorsState();
    await _save(current.copyWith(pressureUnit: unit));
  }

  Future<void> updateTemperatureValue(double? valueInFahrenheit) async {
    if (valueInFahrenheit != null) {
      final current = state.value ?? const ConvertorsState();
      await _save(
        current.copyWith(temperatureValueFahrenheit: valueInFahrenheit),
      );
    }
  }

  Future<void> updateTemperatureUnit(Unit unit) async {
    final current = state.value ?? const ConvertorsState();
    await _save(current.copyWith(temperatureUnit: unit));
  }

  Future<void> updateTorqueValue(double? valueInNewtonMeter) async {
    if (valueInNewtonMeter != null && valueInNewtonMeter >= 0) {
      final current = state.value ?? const ConvertorsState();
      await _save(current.copyWith(torqueValueNewtonMeter: valueInNewtonMeter));
    }
  }

  Future<void> updateTorqueUnit(Unit unit) async {
    final current = state.value ?? const ConvertorsState();
    await _save(current.copyWith(torqueUnit: unit));
  }

  Future<void> updateAnglesConvertorDistanceValue(double? valueInMeters) async {
    if (valueInMeters != null && valueInMeters >= 0) {
      final current = state.value ?? const ConvertorsState();
      await _save(
        current.copyWith(anglesConvertorDistanceValueMeter: valueInMeters),
      );
    }
  }

  Future<void> updateAnglesConvertorDistanceUnit(Unit unit) async {
    final current = state.value ?? const ConvertorsState();
    await _save(current.copyWith(anglesConvertorDistanceUnit: unit));
  }

  Future<void> updateAnglesConvertorAngularValue(double? valueInMil) async {
    if (valueInMil != null && valueInMil >= 0) {
      final current = state.value ?? const ConvertorsState();
      await _save(current.copyWith(anglesConvertorAngularValueMil: valueInMil));
    }
  }

  Future<void> updateAnglesConvertorAngularUnit(Unit unit) async {
    final current = state.value ?? const ConvertorsState();
    await _save(current.copyWith(anglesConvertorAngularUnit: unit));
  }

  Future<void> updateAnglesConvertorOutputUnit(Unit unit) async {
    final current = state.value ?? const ConvertorsState();
    await _save(current.copyWith(anglesConvertorOutputUnit: unit));
  }

  Future<void> _save(ConvertorsState newState) async {
    state = AsyncData(newState);
    await ref.read(appStorageProvider).saveConvertorsState(newState);
  }
}

final convertorsProvider =
    AsyncNotifierProvider<ConvertorsNotifier, ConvertorsState>(
      ConvertorsNotifier.new,
    );

// Синхронний доступ до стану конвертора
final convertorStateProvider = Provider<ConvertorsState>((ref) {
  return ref.watch(convertorsProvider).value ?? const ConvertorsState();
});
