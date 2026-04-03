import 'package:eballistica/core/providers/convertors_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

class PressureField {
  final String label;
  final String formattedValue;
  final double value;
  final String symbol;
  final int decimals;

  const PressureField({
    required this.label,
    required this.formattedValue,
    required this.value,
    required this.symbol,
    required this.decimals,
  });
}

class PressureConvertorUiState {
  final PressureField mmHg;
  final PressureField inHg;
  final PressureField bar;
  final PressureField hPa;
  final PressureField psi;
  final PressureField atm;
  final double? rawValue;
  final Unit inputUnit;

  const PressureConvertorUiState({
    required this.mmHg,
    required this.inHg,
    required this.bar,
    required this.hPa,
    required this.psi,
    required this.atm,
    required this.rawValue,
    required this.inputUnit,
  });
}

class PressureConvertorViewModel extends Notifier<PressureConvertorUiState> {
  UnitFormatter get _formatter => ref.read(unitFormatterProvider);

  @override
  PressureConvertorUiState build() {
    final convertorsState = ref.watch(convertorStateProvider);
    return _buildState(
      convertorsState.pressureValueMmHg,
      convertorsState.pressureUnit,
    );
  }

  void updateRawValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);

    if (rawValueInInputUnit == null) {
      ref.read(convertorsProvider.notifier).updatePressureValue(null);
      return;
    }

    final mmHgValue = rawValueInInputUnit.convert(
      convertorsState.pressureUnit,
      Unit.mmHg,
    );
    if (mmHgValue >= 0) {
      ref.read(convertorsProvider.notifier).updatePressureValue(mmHgValue);
    }
  }

  void changeInputUnit(Unit newUnit) {
    ref.read(convertorsProvider.notifier).updatePressureUnit(newUnit);
  }

  double? _getDisplayValue(double? rawMmHg, Unit inputUnit) {
    if (rawMmHg == null) return null;
    return rawMmHg.convert(Unit.mmHg, inputUnit);
  }

  FieldConstraints getConstraintsForUnit(Unit unit) {
    final minInMmHg = 0.0;
    final maxInMmHg = 2000.0; // Максимум в mmHg

    return FieldConstraints(
      minRaw: minInMmHg.convert(Unit.mmHg, unit),
      maxRaw: maxInMmHg.convert(Unit.mmHg, unit),
      stepRaw: _getStepForUnit(unit),
      rawUnit: unit,
      accuracy: FC.pressure.accuracyFor(unit),
    );
  }

  double _getStepForUnit(Unit unit) {
    final baseStep = FC.pressure.stepRaw;
    return baseStep.convert(Unit.mmHg, unit);
  }

  String _formatPressure(double value, Unit unit) {
    final pressure = Pressure(value, unit);
    return _formatter.pressure(pressure);
  }

  PressureConvertorUiState _buildState(double rawMmHg, Unit inputUnit) {
    final mmHgRaw = rawMmHg;

    return PressureConvertorUiState(
      rawValue: _getDisplayValue(rawMmHg, inputUnit),
      inputUnit: inputUnit,
      mmHg: PressureField(
        label: 'mmHg',
        formattedValue: _formatPressure(mmHgRaw, Unit.mmHg),
        value: mmHgRaw,
        symbol: Unit.mmHg.symbol,
        decimals: FC.pressure.accuracyFor(Unit.mmHg),
      ),
      inHg: PressureField(
        label: 'inHg',
        formattedValue: _formatPressure(
          mmHgRaw.convert(Unit.mmHg, Unit.inHg),
          Unit.inHg,
        ),
        value: mmHgRaw.convert(Unit.mmHg, Unit.inHg),
        symbol: Unit.inHg.symbol,
        decimals: FC.pressure.accuracyFor(Unit.inHg),
      ),
      bar: PressureField(
        label: 'Bar',
        formattedValue: _formatPressure(
          mmHgRaw.convert(Unit.mmHg, Unit.bar),
          Unit.bar,
        ),
        value: mmHgRaw.convert(Unit.mmHg, Unit.bar),
        symbol: Unit.bar.symbol,
        decimals: FC.pressure.accuracyFor(Unit.bar),
      ),
      hPa: PressureField(
        label: 'hPa',
        formattedValue: _formatPressure(
          mmHgRaw.convert(Unit.mmHg, Unit.hPa),
          Unit.hPa,
        ),
        value: mmHgRaw.convert(Unit.mmHg, Unit.hPa),
        symbol: Unit.hPa.symbol,
        decimals: FC.pressure.accuracyFor(Unit.hPa),
      ),
      psi: PressureField(
        label: 'PSI',
        formattedValue: _formatPressure(
          mmHgRaw.convert(Unit.mmHg, Unit.psi),
          Unit.psi,
        ),
        value: mmHgRaw.convert(Unit.mmHg, Unit.psi),
        symbol: Unit.psi.symbol,
        decimals: FC.pressure.accuracyFor(Unit.psi),
      ),
      atm: PressureField(
        label: 'Atmosphere',
        formattedValue: _formatPressure(
          mmHgRaw.convert(Unit.mmHg, Unit.atm),
          Unit.atm,
        ),
        value: mmHgRaw.convert(Unit.mmHg, Unit.atm),
        symbol: Unit.atm.symbol,
        decimals: FC.pressure.accuracyFor(Unit.atm),
      ),
    );
  }
}

final pressureConvertorVmProvider =
    NotifierProvider<PressureConvertorViewModel, PressureConvertorUiState>(
      PressureConvertorViewModel.new,
    );
