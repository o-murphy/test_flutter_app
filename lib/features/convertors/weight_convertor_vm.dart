import 'package:eballistica/core/providers/convertors_notifier.dart';
import 'package:eballistica/features/convertors/generic_convertor_vm_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

class WeightConvertorUiState {
  final GenericConvertorField grams;
  final GenericConvertorField kilograms;
  final GenericConvertorField grains;
  final GenericConvertorField pounds;
  final GenericConvertorField ounces;
  final double? rawValue;
  final Unit inputUnit;

  const WeightConvertorUiState({
    required this.grams,
    required this.kilograms,
    required this.grains,
    required this.pounds,
    required this.ounces,
    required this.rawValue,
    required this.inputUnit,
  });
}

class WeightConvertorViewModel extends Notifier<WeightConvertorUiState> {
  @override
  WeightConvertorUiState build() {
    final convertorsState = ref.watch(convertorStateProvider);
    return _buildState(
      convertorsState.weightValueGrain,
      convertorsState.weightUnit,
    );
  }

  void updateRawValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);

    if (rawValueInInputUnit == null) {
      ref.read(convertorsProvider.notifier).updateWeightValue(null);
      return;
    }

    final grainsValue = rawValueInInputUnit.convert(
      convertorsState.weightUnit,
      Unit.grain,
    );
    if (grainsValue >= 0) {
      ref.read(convertorsProvider.notifier).updateWeightValue(grainsValue);
    }
  }

  void changeInputUnit(Unit newUnit) {
    ref.read(convertorsProvider.notifier).updateWeightUnit(newUnit);
  }

  double? _getDisplayValue(double? rawGrains, Unit inputUnit) {
    if (rawGrains == null) return null;
    return rawGrains.convert(Unit.grain, inputUnit);
  }

  FieldConstraints getConstraintsForUnit(Unit unit) {
    final minInGrains = 0.0;
    final maxInGrains = 100000.0;

    return FieldConstraints(
      minRaw: minInGrains.convert(Unit.grain, unit),
      maxRaw: maxInGrains.convert(Unit.grain, unit),
      stepRaw: _getStepForUnit(unit),
      rawUnit: unit,
      accuracy: FC.convertorWeight.accuracyFor(unit),
    );
  }

  double _getStepForUnit(Unit unit) {
    final baseStep = FC.convertorWeight.stepRaw;
    return baseStep.convert(Unit.grain, unit);
  }

  String _formatValue(double value, int decimals, String symbol) {
    if (value.isNaN || value.isInfinite) return '— $symbol';
    return '${value.toStringAsFixed(decimals)} $symbol';
  }

  WeightConvertorUiState _buildState(double rawGrains, Unit inputUnit) {
    final grainsRaw = rawGrains;

    final gramsRaw = grainsRaw.convert(Unit.grain, Unit.gram);
    final kilogramsRaw = grainsRaw.convert(Unit.grain, Unit.kilogram);
    final grainsRawValue = grainsRaw.convert(Unit.grain, Unit.grain);
    final poundsRaw = grainsRaw.convert(Unit.grain, Unit.pound);
    final ouncesRaw = grainsRaw.convert(Unit.grain, Unit.ounce);

    final gramsAccuracy = FC.convertorWeight.accuracyFor(Unit.gram);
    final kilogramsAccuracy = FC.convertorWeight.accuracyFor(Unit.kilogram);
    final grainsAccuracy = FC.convertorWeight.accuracyFor(Unit.grain);
    final poundsAccuracy = FC.convertorWeight.accuracyFor(Unit.pound);
    final ouncesAccuracy = FC.convertorWeight.accuracyFor(Unit.ounce);

    return WeightConvertorUiState(
      rawValue: _getDisplayValue(rawGrains, inputUnit),
      inputUnit: inputUnit,
      grams: GenericConvertorField(
        label: 'Grams',
        formattedValue: _formatValue(gramsRaw, gramsAccuracy, Unit.gram.symbol),
        value: gramsRaw,
        symbol: Unit.gram.symbol,
        decimals: gramsAccuracy,
      ),
      kilograms: GenericConvertorField(
        label: 'Kilograms',
        formattedValue: _formatValue(
          kilogramsRaw,
          kilogramsAccuracy,
          Unit.kilogram.symbol,
        ),
        value: kilogramsRaw,
        symbol: Unit.kilogram.symbol,
        decimals: kilogramsAccuracy,
      ),
      grains: GenericConvertorField(
        label: 'Grains',
        formattedValue: _formatValue(
          grainsRawValue,
          grainsAccuracy,
          Unit.grain.symbol,
        ),
        value: grainsRawValue,
        symbol: Unit.grain.symbol,
        decimals: grainsAccuracy,
      ),
      pounds: GenericConvertorField(
        label: 'Pounds',
        formattedValue: _formatValue(
          poundsRaw,
          poundsAccuracy,
          Unit.pound.symbol,
        ),
        value: poundsRaw,
        symbol: Unit.pound.symbol,
        decimals: poundsAccuracy,
      ),
      ounces: GenericConvertorField(
        label: 'Ounces',
        formattedValue: _formatValue(
          ouncesRaw,
          ouncesAccuracy,
          Unit.ounce.symbol,
        ),
        value: ouncesRaw,
        symbol: Unit.ounce.symbol,
        decimals: ouncesAccuracy,
      ),
    );
  }
}

final weightConvertorVmProvider =
    NotifierProvider<WeightConvertorViewModel, WeightConvertorUiState>(
      WeightConvertorViewModel.new,
    );
