import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/core/providers/shot_conditions_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/solver/munition.dart';
import 'package:eballistica/core/solver/unit.dart';

// ── Data classes ─────────────────────────────────────────────────────────────

class ConditionsField {
  final String label;
  final double displayValue;
  final double rawValue;
  final String symbol;
  final double displayMin;
  final double displayMax;
  final double displayStep;
  final int decimals;
  final InputField inputField;
  final Unit displayUnit;

  const ConditionsField({
    required this.label,
    required this.displayValue,
    required this.rawValue,
    required this.symbol,
    required this.displayMin,
    required this.displayMax,
    required this.displayStep,
    required this.decimals,
    required this.inputField,
    required this.displayUnit,
  });
}

class ConditionsUiState {
  final ConditionsField temperature;
  final ConditionsField altitude;
  final ConditionsField humidity;
  final ConditionsField pressure;
  final ConditionsField? powderTemperature;

  // Switches (тепер з Conditions, не з Settings!)
  final bool powderSensOn;
  final bool useDiffPowderTemp;
  final bool coriolisOn;
  final bool derivationOn;

  // Latitude/Azimuth для Coriolis
  final double? latitudeDeg;
  final double? azimuthDeg;

  // Readonly computed
  final String? mvAtPowderTemp;
  final String? powderSensitivity;

  const ConditionsUiState({
    required this.temperature,
    required this.altitude,
    required this.humidity,
    required this.pressure,
    this.powderTemperature,
    required this.powderSensOn,
    required this.useDiffPowderTemp,
    required this.coriolisOn,
    required this.derivationOn,
    this.latitudeDeg,
    this.azimuthDeg,
    this.mvAtPowderTemp,
    this.powderSensitivity,
  });
}

// ── ViewModel ────────────────────────────────────────────────────────────────

class ConditionsViewModel extends AsyncNotifier<ConditionsUiState> {
  @override
  Future<ConditionsUiState> build() async {
    final conditions = await ref.watch(shotConditionsProvider.future);
    final profile = await ref.watch(shotProfileProvider.future);
    final settings = await ref.watch(settingsProvider.future);
    final formatter = ref.watch(unitFormatterProvider);

    return _buildState(profile, conditions, settings, formatter);
  }

  // Оновлення окремих полів
  Future<void> updateTemperature(double rawCelsius) async {
    await _updateAtmo(tempC: rawCelsius);
  }

  Future<void> updateAltitude(double rawMeters) async {
    await _updateAtmo(altM: rawMeters);
  }

  Future<void> updateHumidity(double rawPercent) async {
    await _updateAtmo(humFrac: rawPercent.convert(Unit.percent, Unit.fraction));
  }

  Future<void> updatePressure(double rawHPa) async {
    await _updateAtmo(pressHPa: rawHPa);
  }

  Future<void> updatePowderTemp(double rawCelsius) async {
    await _updateAtmo(powderTempC: rawCelsius);
  }

  // Оновлення перемикачів (тепер з shotConditionsProvider)
  Future<void> setPowderSensitivity(bool value) async {
    await ref
        .read(shotConditionsProvider.notifier)
        .updateUsePowderSensitivity(value);
  }

  Future<void> setDiffPowderTemp(bool value) async {
    await ref
        .read(shotConditionsProvider.notifier)
        .updateUseDiffPowderTemp(value);
  }

  Future<void> setCoriolis(bool value) async {
    await ref.read(shotConditionsProvider.notifier).updateUseCoriolis(value);
  }

  Future<void> setDerivation(bool value) async {
    // Derivation поки що немає в Conditions, можна додати пізніше
    // або залишити в settings
    await ref.read(settingsProvider.notifier).setSwitch('derivation', value);
  }

  Future<void> updateLatitude(double? degrees) async {
    await ref.read(shotConditionsProvider.notifier).updateLatitude(degrees);
  }

  Future<void> updateAzimuth(double? degrees) async {
    await ref.read(shotConditionsProvider.notifier).updateAzimuth(degrees);
  }

  // ── Private методи ─────────────────────────────────────────────────────────

  Future<void> _updateAtmo({
    double? tempC,
    double? altM,
    double? humFrac,
    double? pressHPa,
    double? powderTempC,
  }) async {
    final current = ref.read(shotConditionsProvider).value;
    if (current == null) return;

    final atmo = current.atmo;
    final useDiffPowderTemp = current.useDiffPowderTemp;
    final powderSensOn = current.usePowderSensitivity;

    final currentTempC = atmo.temperature.in_(Unit.celsius);
    final currentAltM = atmo.altitude.in_(Unit.meter);
    final currentPressHPa = atmo.pressure.in_(Unit.hPa);
    final currentHumFrac = atmo.humidity;
    final currentPowderTempC = atmo.powderTemp.in_(Unit.celsius);

    final newTempC = tempC ?? currentTempC;
    final newAltM = altM ?? currentAltM;
    final newPressHPa = pressHPa ?? currentPressHPa;
    final newHumFrac = humFrac ?? currentHumFrac;

    final newPowderTempC =
        powderTempC ??
        (useDiffPowderTemp && powderSensOn ? currentPowderTempC : newTempC);

    final newAtmo = AtmoData(
      temperature: Temperature(newTempC, Unit.celsius),
      altitude: Distance(newAltM, Unit.meter),
      pressure: Pressure(newPressHPa, Unit.hPa),
      humidity: newHumFrac,
      powderTemp: Temperature(newPowderTempC, Unit.celsius),
    );

    await ref.read(shotConditionsProvider.notifier).updateAtmo(newAtmo);
  }

  ConditionsUiState _buildState(
    ShotProfile profile,
    Conditions conditions,
    AppSettings settings,
    UnitFormatter formatter,
  ) {
    final atmo = conditions.atmo;
    final units = settings.units;

    final tempRaw = atmo.temperature.in_(Unit.celsius);
    final altRaw = atmo.altitude.in_(Unit.meter);
    final pressRaw = atmo.pressure.in_(Unit.hPa);
    final humRaw = atmo.humidity;

    final powderSensOn = conditions.usePowderSensitivity;
    final useDiffPowderTemp = powderSensOn && conditions.useDiffPowderTemp;

    final powderTempRaw = useDiffPowderTemp
        ? atmo.powderTemp.in_(Unit.celsius)
        : tempRaw;

    // MV at powder temp
    final cartridge = profile.cartridge;
    final refMvMps = cartridge?.mv.in_(Unit.mps) ?? 0.0;
    final refPowderTempC = cartridge?.powderTemp.in_(Unit.celsius) ?? 15.0;
    final powderSensitivity = cartridge?.powderSensitivity;

    double mvAtTempC(double tCurC) => velocityForPowderTemp(
      refMvMps,
      refPowderTempC,
      tCurC,
      powderSensitivity?.in_(Unit.fraction) ?? 0.0,
    );

    final currentMvMps = mvAtTempC(powderTempRaw);
    final currentMvDisp = Velocity(currentMvMps, Unit.mps).in_(units.velocity);
    final mvStr =
        '${currentMvDisp.toStringAsFixed(FC.velocity.accuracyFor(units.velocity))} ${units.velocity.symbol}';
    final sensStr =
        '${(powderSensitivity?.in_(Unit.percent) ?? 0.0).toStringAsFixed(2)} %/15°C';

    return ConditionsUiState(
      temperature: _field(
        label: 'Temperature',
        rawValue: tempRaw,
        fc: FC.temperature,
        displayUnit: units.temperature,
        inputField: InputField.temperature,
        formatter: formatter,
      ),
      altitude: _field(
        label: 'Altitude',
        rawValue: altRaw,
        fc: FC.altitude,
        displayUnit: units.distance,
        inputField: InputField.distance,
        formatter: formatter,
      ),
      humidity: _field(
        label: 'Humidity',
        rawValue: humRaw,
        fc: FC.humidity,
        displayUnit: Unit.percent,
        inputField: InputField.humidity,
        formatter: formatter,
      ),
      pressure: _field(
        label: 'Pressure',
        rawValue: pressRaw,
        fc: FC.pressure,
        displayUnit: units.pressure,
        inputField: InputField.pressure,
        formatter: formatter,
      ),
      powderTemperature: (powderSensOn && useDiffPowderTemp)
          ? _field(
              label: 'Powder temperature',
              rawValue: powderTempRaw,
              fc: FC.temperature,
              displayUnit: units.temperature,
              inputField: InputField.temperature,
              formatter: formatter,
            )
          : null,
      powderSensOn: powderSensOn,
      useDiffPowderTemp: useDiffPowderTemp,
      coriolisOn: conditions.useCoriolis, // ← з Conditions!
      derivationOn: settings.enableDerivation, // ← поки з settings
      latitudeDeg: conditions.latitudeDeg, // ← з Conditions
      azimuthDeg: conditions.azimuthDeg, // ← з Conditions
      mvAtPowderTemp: powderSensOn ? mvStr : null,
      powderSensitivity: powderSensOn ? sensStr : null,
    );
  }

  ConditionsField _field({
    required String label,
    required double rawValue,
    required FieldConstraints fc,
    required Unit displayUnit,
    required InputField inputField,
    required UnitFormatter formatter,
  }) {
    final displayValue = formatter.rawToInput(rawValue, inputField);
    final displayMin = _convertFcBound(fc.minRaw, fc.rawUnit, displayUnit);
    final displayMax = _convertFcBound(fc.maxRaw, fc.rawUnit, displayUnit);
    final displayStep = _convertFcStep(fc.stepRaw, fc.rawUnit, displayUnit);
    final decimals = fc.accuracyFor(displayUnit);

    return ConditionsField(
      label: label,
      displayValue: displayValue,
      rawValue: rawValue,
      symbol: displayUnit.symbol,
      displayMin: displayMin,
      displayMax: displayMax,
      displayStep: displayStep,
      decimals: decimals,
      inputField: inputField,
      displayUnit: displayUnit,
    );
  }

  double _convertFcBound(double rawVal, Unit rawUnit, Unit dispUnit) {
    return rawVal.convert(rawUnit, dispUnit);
  }

  double _convertFcStep(double rawStep, Unit rawUnit, Unit dispUnit) {
    final lo = (0.0).convert(rawUnit, dispUnit);
    final hi = rawStep.convert(rawUnit, dispUnit);
    return (hi - lo).abs();
  }
}

final conditionsVmProvider =
    AsyncNotifierProvider<ConditionsViewModel, ConditionsUiState>(
      ConditionsViewModel.new,
    );
