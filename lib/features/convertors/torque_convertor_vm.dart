import 'package:eballistica/core/providers/convertors_notifier.dart';
import 'package:eballistica/features/convertors/generic_convertor_vm_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

class TorqueConvertorUiState {
  final GenericConvertorField newtonMeter;
  final GenericConvertorField footPound;
  final GenericConvertorField inchPound;
  final double? rawValue;
  final Unit inputUnit;

  const TorqueConvertorUiState({
    required this.newtonMeter,
    required this.footPound,
    required this.inchPound,
    required this.rawValue,
    required this.inputUnit,
  });
}

class TorqueConvertorViewModel extends Notifier<TorqueConvertorUiState> {
  @override
  TorqueConvertorUiState build() {
    final convertorsState = ref.watch(convertorStateProvider);
    return _buildState(
      convertorsState.torqueValueNewtonMeter,
      convertorsState.torqueUnit,
    );
  }

  void updateRawValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);

    if (rawValueInInputUnit == null) {
      ref.read(convertorsProvider.notifier).updateTorqueValue(null);
      return;
    }

    final newtonMeterValue = rawValueInInputUnit.convert(
      convertorsState.torqueUnit,
      Unit.newtonMeter,
    );
    if (newtonMeterValue >= 0) {
      ref.read(convertorsProvider.notifier).updateTorqueValue(newtonMeterValue);
    }
  }

  void changeInputUnit(Unit newUnit) {
    ref.read(convertorsProvider.notifier).updateTorqueUnit(newUnit);
  }

  double? _getDisplayValue(double? rawNewtonMeter, Unit inputUnit) {
    if (rawNewtonMeter == null) return null;
    return rawNewtonMeter.convert(Unit.newtonMeter, inputUnit);
  }

  FieldConstraints getConstraintsForUnit(Unit unit) {
    final minInNewtonMeter = 0.0;
    final maxInNewtonMeter = 10000.0;

    return FieldConstraints(
      minRaw: minInNewtonMeter.convert(Unit.newtonMeter, unit),
      maxRaw: maxInNewtonMeter.convert(Unit.newtonMeter, unit),
      stepRaw: _getStepForUnit(unit),
      rawUnit: unit,
      accuracy: FC.convertorTorque.accuracyFor(unit),
    );
  }

  double _getStepForUnit(Unit unit) {
    final baseStep = FC.convertorTorque.stepRaw;
    return baseStep.convert(Unit.newtonMeter, unit);
  }

  String _formatValue(double value, int decimals, String symbol) {
    if (value.isNaN || value.isInfinite) return '— $symbol';
    return '${value.toStringAsFixed(decimals)} $symbol';
  }

  TorqueConvertorUiState _buildState(double rawNewtonMeter, Unit inputUnit) {
    final newtonMeterRaw = rawNewtonMeter;

    final footPoundRaw = newtonMeterRaw.convert(
      Unit.newtonMeter,
      Unit.footPoundTorque,
    );
    final inchPoundRaw = newtonMeterRaw.convert(
      Unit.newtonMeter,
      Unit.inchPound,
    );

    final nmAccuracy = FC.convertorTorque.accuracyFor(Unit.newtonMeter);
    final ftLbAccuracy = FC.convertorTorque.accuracyFor(Unit.footPoundTorque);
    final inLbAccuracy = FC.convertorTorque.accuracyFor(Unit.inchPound);

    return TorqueConvertorUiState(
      rawValue: _getDisplayValue(rawNewtonMeter, inputUnit),
      inputUnit: inputUnit,
      newtonMeter: GenericConvertorField(
        label: 'Newton-meter',
        formattedValue: _formatValue(
          newtonMeterRaw,
          nmAccuracy,
          Unit.newtonMeter.symbol,
        ),
        value: newtonMeterRaw,
        symbol: Unit.newtonMeter.symbol,
        decimals: nmAccuracy,
      ),
      footPound: GenericConvertorField(
        label: 'Foot-pound',
        formattedValue: _formatValue(
          footPoundRaw,
          ftLbAccuracy,
          Unit.footPoundTorque.symbol,
        ),
        value: footPoundRaw,
        symbol: Unit.footPoundTorque.symbol,
        decimals: ftLbAccuracy,
      ),
      inchPound: GenericConvertorField(
        label: 'Inch-pound',
        formattedValue: _formatValue(
          inchPoundRaw,
          inLbAccuracy,
          Unit.inchPound.symbol,
        ),
        value: inchPoundRaw,
        symbol: Unit.inchPound.symbol,
        decimals: inLbAccuracy,
      ),
    );
  }
}

final torqueConvertorVmProvider =
    NotifierProvider<TorqueConvertorViewModel, TorqueConvertorUiState>(
      TorqueConvertorViewModel.new,
    );
