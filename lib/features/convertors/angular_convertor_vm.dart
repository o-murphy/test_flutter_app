import 'package:eballistica/core/providers/convertors_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

class AnglesConvertorField {
  final String label;
  final String formattedValue;
  final double value;
  final String symbol;
  final int decimals;

  const AnglesConvertorField({
    required this.label,
    required this.formattedValue,
    required this.value,
    required this.symbol,
    required this.decimals,
  });
}

class AnglesConvertorUiState {
  // Всі можливі одиниці кута
  final AnglesConvertorField mil;
  final AnglesConvertorField moa;
  final AnglesConvertorField cmPer100m;
  final AnglesConvertorField inchPer100Yd;
  final AnglesConvertorField mrad;
  final AnglesConvertorField degrees;

  // Дистанція
  final AnglesConvertorField meters;
  final AnglesConvertorField yards;

  // Розрахунки на дистанції
  final String oneMilAtDistance;
  final String angleInMoaAtDistance;
  final String oneMoaAtDistance;
  final String angleInMilAtDistance;

  final double? rawDistanceValue;
  final double? rawAngularValue;
  final Unit distanceInputUnit;
  final Unit angularInputUnit;

  const AnglesConvertorUiState({
    required this.mil,
    required this.moa,
    required this.cmPer100m,
    required this.inchPer100Yd,
    required this.mrad,
    required this.degrees,
    required this.meters,
    required this.yards,
    required this.oneMilAtDistance,
    required this.angleInMoaAtDistance,
    required this.oneMoaAtDistance,
    required this.angleInMilAtDistance,
    required this.rawDistanceValue,
    required this.rawAngularValue,
    required this.distanceInputUnit,
    required this.angularInputUnit,
  });
}

class AnglesConvertorViewModel extends Notifier<AnglesConvertorUiState> {
  @override
  AnglesConvertorUiState build() {
    final convertorsState = ref.watch(convertorStateProvider);
    return _buildState(
      convertorsState.anglesConvertorDistanceValueMeter,
      convertorsState.anglesConvertorDistanceUnit,
      convertorsState.anglesConvertorAngularValueMil,
      convertorsState.anglesConvertorAngularUnit,
    );
  }

  void updateDistanceValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);
    if (rawValueInInputUnit == null) {
      ref
          .read(convertorsProvider.notifier)
          .updateAnglesConvertorDistanceValue(null);
      return;
    }
    final metersValue = rawValueInInputUnit.convert(
      convertorsState.anglesConvertorDistanceUnit,
      Unit.meter,
    );
    if (metersValue >= 0) {
      ref
          .read(convertorsProvider.notifier)
          .updateAnglesConvertorDistanceValue(metersValue);
    }
  }

  void updateAngularValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);
    if (rawValueInInputUnit == null) {
      ref
          .read(convertorsProvider.notifier)
          .updateAnglesConvertorAngularValue(null);
      return;
    }
    final milValue = rawValueInInputUnit.convert(
      convertorsState.anglesConvertorAngularUnit,
      Unit.mil,
    );
    if (milValue >= 0) {
      ref
          .read(convertorsProvider.notifier)
          .updateAnglesConvertorAngularValue(milValue);
    }
  }

  void changeDistanceUnit(Unit newUnit) {
    ref
        .read(convertorsProvider.notifier)
        .updateAnglesConvertorDistanceUnit(newUnit);
  }

  void changeAngularUnit(Unit newUnit) {
    ref
        .read(convertorsProvider.notifier)
        .updateAnglesConvertorAngularUnit(newUnit);
  }

  FieldConstraints getDistanceConstraintsForUnit(Unit unit) {
    return FieldConstraints(
      minRaw: FC.convertorDistance.minRaw.convert(
        FC.convertorDistance.rawUnit,
        unit,
      ),
      maxRaw: FC.convertorDistance.maxRaw.convert(
        FC.convertorDistance.rawUnit,
        unit,
      ),
      stepRaw: FC.convertorDistance.stepRaw.convert(
        FC.convertorDistance.rawUnit,
        unit,
      ),
      rawUnit: unit,
      accuracy: FC.convertorDistance.accuracyFor(unit),
    );
  }

  FieldConstraints getAngularConstraintsForUnit(Unit unit) {
    return FieldConstraints(
      minRaw: FC.convertorAngular.minRaw.convert(
        FC.convertorAngular.rawUnit,
        unit,
      ),
      maxRaw: FC.convertorAngular.maxRaw.convert(
        FC.convertorAngular.rawUnit,
        unit,
      ),
      stepRaw: FC.convertorAngular.stepRaw.convert(
        FC.convertorAngular.rawUnit,
        unit,
      ),
      rawUnit: unit,
      accuracy: FC.convertorAngular.accuracyFor(unit),
    );
  }

  String _formatValue(double value, int decimals, String symbol) {
    if (value.isNaN || value.isInfinite) return '— $symbol';
    return '${value.toStringAsFixed(decimals)} $symbol';
  }

  AnglesConvertorUiState _buildState(
    double rawMeters,
    Unit distanceUnit,
    double rawMil,
    Unit angularUnit,
  ) {
    // Дистанція
    final metersRaw = rawMeters;
    final yardsRaw = metersRaw.convert(Unit.meter, Unit.yard);

    // Конвертація кута в різні одиниці
    final milRaw = rawMil;
    final moaRaw = milRaw.convert(Unit.mil, Unit.moa);
    final mradRaw = milRaw.convert(Unit.mil, Unit.mRad);
    final degreesRaw = milRaw.convert(Unit.mil, Unit.degree);

    // cm/100m та inch/100yd для кута
    final cmPer100mRaw = milRaw * 10; // 1 MIL = 10 cm/100m
    final inchPer100YdRaw = milRaw * 3.6; // 1 MIL ≈ 3.6 inch/100yd

    // Розрахунки на дистанції (в см)
    final distanceInMeters = rawMeters;

    // 1 MIL на дистанції
    final oneMilCm = (0.1 * distanceInMeters).convert(
      Unit.meter,
      Unit.centimeter,
    );

    // Кут в MOA на дистанції
    final angleMoaCm = (moaRaw * 0.0291 * distanceInMeters).convert(
      Unit.meter,
      Unit.centimeter,
    );

    // 1 MOA на дистанції
    final oneMoaCm = (0.0291 * distanceInMeters).convert(
      Unit.meter,
      Unit.centimeter,
    );

    // Кут в MIL на дистанції
    final angleMilCm = (rawMil * 0.1 * distanceInMeters).convert(
      Unit.meter,
      Unit.centimeter,
    );

    return AnglesConvertorUiState(
      rawDistanceValue: rawMeters.convert(Unit.meter, distanceUnit),
      rawAngularValue: rawMil.convert(Unit.mil, angularUnit),
      distanceInputUnit: distanceUnit,
      angularInputUnit: angularUnit,

      // Дистанція
      meters: AnglesConvertorField(
        label: 'Meters',
        formattedValue: _formatValue(metersRaw, 0, Unit.meter.symbol),
        value: metersRaw,
        symbol: Unit.meter.symbol,
        decimals: 0,
      ),
      yards: AnglesConvertorField(
        label: 'Yards',
        formattedValue: _formatValue(yardsRaw, 0, Unit.yard.symbol),
        value: yardsRaw,
        symbol: Unit.yard.symbol,
        decimals: 0,
      ),

      // Конвертація кута
      mil: AnglesConvertorField(
        label: 'MIL',
        formattedValue: _formatValue(milRaw, 1, Unit.mil.symbol),
        value: milRaw,
        symbol: Unit.mil.symbol,
        decimals: 1,
      ),
      moa: AnglesConvertorField(
        label: 'MOA',
        formattedValue: _formatValue(moaRaw, 1, Unit.moa.symbol),
        value: moaRaw,
        symbol: Unit.moa.symbol,
        decimals: 1,
      ),
      cmPer100m: AnglesConvertorField(
        label: 'cm/100m',
        formattedValue: _formatValue(cmPer100mRaw, 1, 'cm/100m'),
        value: cmPer100mRaw,
        symbol: 'cm/100m',
        decimals: 1,
      ),
      inchPer100Yd: AnglesConvertorField(
        label: 'in/100yd',
        formattedValue: _formatValue(inchPer100YdRaw, 2, 'in/100yd'),
        value: inchPer100YdRaw,
        symbol: 'in/100yd',
        decimals: 2,
      ),
      mrad: AnglesConvertorField(
        label: 'MRAD',
        formattedValue: _formatValue(mradRaw, 2, Unit.mRad.symbol),
        value: mradRaw,
        symbol: Unit.mRad.symbol,
        decimals: 2,
      ),
      degrees: AnglesConvertorField(
        label: 'Degrees',
        formattedValue: _formatValue(degreesRaw, 2, Unit.degree.symbol),
        value: degreesRaw,
        symbol: Unit.degree.symbol,
        decimals: 2,
      ),

      // Розрахунки на дистанції
      oneMilAtDistance: _formatValue(oneMilCm, 1, 'cm'),
      angleInMoaAtDistance: _formatValue(angleMoaCm, 1, 'cm'),
      oneMoaAtDistance: _formatValue(oneMoaCm, 1, 'cm'),
      angleInMilAtDistance: _formatValue(angleMilCm, 1, 'cm'),
    );
  }
}

final anglesConvertorVmProvider =
    NotifierProvider<AnglesConvertorViewModel, AnglesConvertorUiState>(
      AnglesConvertorViewModel.new,
    );
