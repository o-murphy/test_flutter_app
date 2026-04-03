import 'package:eballistica/core/providers/convertors_notifier.dart';
import 'package:eballistica/features/convertors/generic_convertor_vm_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

// ── Data classes ─────────────────────────────────────────────────────────────

class LengthConvertorUiState {
  final GenericConvertorField centimeters;
  final GenericConvertorField meters;
  final GenericConvertorField inches;
  final GenericConvertorField feet;
  final GenericConvertorField yards;
  final double? rawValue;
  final Unit inputUnit;

  const LengthConvertorUiState({
    required this.centimeters,
    required this.meters,
    required this.inches,
    required this.feet,
    required this.yards,
    required this.rawValue,
    required this.inputUnit,
  });
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class LengthConvertorViewModel extends Notifier<LengthConvertorUiState> {
  @override
  LengthConvertorUiState build() {
    final convertorsState = ref.watch(convertorStateProvider);
    return _buildState(
      convertorsState.lengthValueInch,
      convertorsState.lengthUnit,
    );
  }

  void updateRawValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);

    if (rawValueInInputUnit == null) {
      ref.read(convertorsProvider.notifier).updateLengthValue(null);
      return;
    }

    final inchesValue = rawValueInInputUnit.convert(
      convertorsState.lengthUnit,
      Unit.inch,
    );
    if (inchesValue >= 0) {
      ref.read(convertorsProvider.notifier).updateLengthValue(inchesValue);
    }
  }

  void changeInputUnit(Unit newUnit) {
    ref.read(convertorsProvider.notifier).updateLengthUnit(newUnit);
  }

  double? _getDisplayValue(double? rawInches, Unit inputUnit) {
    if (rawInches == null) return null;
    return rawInches.convert(Unit.inch, inputUnit);
  }

  FieldConstraints getConstraintsForUnit(Unit unit) {
    final minInInches = 0.0;
    final maxInInches = 1000000.0.convert(Unit.centimeter, Unit.inch);

    return FieldConstraints(
      minRaw: minInInches.convert(Unit.inch, unit),
      maxRaw: maxInInches.convert(Unit.inch, unit),
      stepRaw: _getStepForUnit(unit),
      rawUnit: unit,
      accuracy: FC.convertorLength.accuracyFor(unit),
    );
  }

  double _getStepForUnit(Unit unit) {
    final baseStep = FC.convertorLength.stepRaw;
    return baseStep.convert(Unit.inch, unit);
  }

  String _formatValue(double value, int decimals, String symbol) {
    if (value.isNaN || value.isInfinite) return '— $symbol';
    return '${value.toStringAsFixed(decimals)} $symbol';
  }

  LengthConvertorUiState _buildState(double rawInches, Unit inputUnit) {
    final inchesRaw = rawInches;

    final centimetersRaw = inchesRaw.convert(Unit.inch, Unit.centimeter);
    final metersRaw = inchesRaw.convert(Unit.inch, Unit.meter);
    final inchesRawValue = inchesRaw.convert(Unit.inch, Unit.inch);
    final feetRaw = inchesRaw.convert(Unit.inch, Unit.foot);
    final yardsRaw = inchesRaw.convert(Unit.inch, Unit.yard);

    final cmAccuracy = FC.convertorLength.accuracyFor(Unit.centimeter);
    final mAccuracy = FC.convertorLength.accuracyFor(Unit.meter);
    final inAccuracy = FC.convertorLength.accuracyFor(Unit.inch);
    final ftAccuracy = FC.convertorLength.accuracyFor(Unit.foot);
    final ydAccuracy = FC.convertorLength.accuracyFor(Unit.yard);

    return LengthConvertorUiState(
      rawValue: _getDisplayValue(rawInches, inputUnit),
      inputUnit: inputUnit,
      centimeters: GenericConvertorField(
        label: 'Centimeters',
        formattedValue: _formatValue(
          centimetersRaw,
          cmAccuracy,
          Unit.centimeter.symbol,
        ),
        value: centimetersRaw,
        symbol: Unit.centimeter.symbol,
        decimals: cmAccuracy,
      ),
      meters: GenericConvertorField(
        label: 'Meters',
        formattedValue: _formatValue(metersRaw, mAccuracy, Unit.meter.symbol),
        value: metersRaw,
        symbol: Unit.meter.symbol,
        decimals: mAccuracy,
      ),
      inches: GenericConvertorField(
        label: 'Inches',
        formattedValue: _formatValue(
          inchesRawValue,
          inAccuracy,
          Unit.inch.symbol,
        ),
        value: inchesRawValue,
        symbol: Unit.inch.symbol,
        decimals: inAccuracy,
      ),
      feet: GenericConvertorField(
        label: 'Feet',
        formattedValue: _formatValue(feetRaw, ftAccuracy, Unit.foot.symbol),
        value: feetRaw,
        symbol: Unit.foot.symbol,
        decimals: ftAccuracy,
      ),
      yards: GenericConvertorField(
        label: 'Yards',
        formattedValue: _formatValue(yardsRaw, ydAccuracy, Unit.yard.symbol),
        value: yardsRaw,
        symbol: Unit.yard.symbol,
        decimals: ydAccuracy,
      ),
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final lengthConvertorVmProvider =
    NotifierProvider<LengthConvertorViewModel, LengthConvertorUiState>(
      LengthConvertorViewModel.new,
    );
