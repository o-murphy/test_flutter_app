// ЧИСТИЙ DART
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/unit_settings.dart';
import 'package:eballistica/core/solver/munition.dart'
    show velocityForPowderTemp;
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

  // Switches
  final bool powderSensOn;
  final bool useDiffPowderTemp;
  final bool coriolisOn;
  final bool derivationOn;

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
    this.mvAtPowderTemp,
    this.powderSensitivity,
  });
}

// ── ViewModel ────────────────────────────────────────────────────────────────

class ConditionsViewModel extends AsyncNotifier<ConditionsUiState> {
  @override
  Future<ConditionsUiState> build() async {
    final profile = ref.watch(shotProfileProvider).value;
    final settings = ref.watch(settingsProvider).value;
    final formatter = ref.watch(unitFormatterProvider);

    if (profile == null || settings == null) {
      return _emptyState(formatter, settings);
    }

    return _buildState(profile, settings, formatter);
  }

  Future<void> updateTemperature(double rawCelsius) async {
    _updateAtmo(tempC: rawCelsius);
  }

  Future<void> updateAltitude(double rawMeters) async {
    _updateAtmo(altM: rawMeters);
  }

  Future<void> updateHumidity(double rawPercent) async {
    _updateAtmo(humFrac: rawPercent.convert(Unit.percent, Unit.fraction));
  }

  Future<void> updatePressure(double rawHPa) async {
    _updateAtmo(pressHPa: rawHPa);
  }

  Future<void> updatePowderTemp(double rawCelsius) async {
    _updateAtmo(powderTempC: rawCelsius);
  }

  Future<void> setPowderSensitivity(bool value) async {
    await ref
        .read(shotProfileProvider.notifier)
        .updateUsePowderSensitivity(value);
  }

  Future<void> setDiffPowderTemp(bool value) async {
    await ref.read(shotProfileProvider.notifier).updateUseDiffPowderTemp(value);
  }

  Future<void> setCoriolis(bool value) async {
    await ref.read(settingsProvider.notifier).setSwitch('coriolis', value);
  }

  Future<void> setDerivation(bool value) async {
    await ref.read(settingsProvider.notifier).setSwitch('derivation', value);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  void _updateAtmo({
    double? tempC,
    double? altM,
    double? humFrac,
    double? pressHPa,
    double? powderTempC,
  }) {
    final profile = ref.read(shotProfileProvider).value;
    if (profile == null) return;

    final atmo = profile.conditions;

    final currentTempC = atmo.temperature.in_(Unit.celsius);
    final currentAltM = atmo.altitude.in_(Unit.meter);
    final currentPressHPa = atmo.pressure.in_(Unit.hPa);
    final currentHumFrac = atmo.humidity;

    final powderSensOn = profile.usePowderSensitivity;
    final useDiffTemp = powderSensOn && profile.useDiffPowderTemp;

    final currentPowderTempC = useDiffTemp
        ? atmo.powderTemp.in_(Unit.celsius)
        : currentTempC;

    final newTempC = tempC ?? currentTempC;

    ref
        .read(shotProfileProvider.notifier)
        .updateConditions(
          AtmoData(
            temperature: Temperature(newTempC, Unit.celsius),
            altitude: Distance(altM ?? currentAltM, Unit.meter),
            pressure: Pressure(pressHPa ?? currentPressHPa, Unit.hPa),
            humidity: humFrac ?? currentHumFrac,
            powderTemp: Temperature(
              useDiffTemp ? (powderTempC ?? currentPowderTempC) : newTempC,
              Unit.celsius,
            ),
          ),
        );
  }

  ConditionsUiState _buildState(
    ShotProfile profile,
    AppSettings settings,
    UnitFormatter formatter,
  ) {
    final atmo = profile.conditions;
    final units = settings.units;

    final tempRaw = atmo.temperature.in_(Unit.celsius);
    final altRaw = atmo.altitude.in_(Unit.meter);
    final pressRaw = atmo.pressure.in_(Unit.hPa);
    final humRaw = atmo.humidity;

    final powderSensOn = profile.usePowderSensitivity;
    final useDiffPowderTemp = powderSensOn && profile.useDiffPowderTemp;

    final powderTempRaw = useDiffPowderTemp
        ? atmo.powderTemp.in_(Unit.celsius)
        : tempRaw;

    // MV at powder temp
    final cartridge = profile.cartridge;
    final refMvMps = cartridge.mv.in_(Unit.mps);
    final refPowderTempC = cartridge.powderTemp.in_(Unit.celsius);
    final powderSensitivity = cartridge.powderSensitivity;

    double mvAtTempC(double tCurC) => velocityForPowderTemp(
      refMvMps,
      refPowderTempC,
      tCurC,
      powderSensitivity,
    );

    final currentMvMps = mvAtTempC(powderTempRaw);
    final currentMvDisp = Velocity(currentMvMps, Unit.mps).in_(units.velocity);
    final mvStr =
        '${currentMvDisp.toStringAsFixed(FC.velocity.accuracyFor(units.velocity))} ${units.velocity.symbol}';
    final sensStr =
        '${(powderSensitivity.in_(Unit.percent)).toStringAsFixed(2)} %/15°C';

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
      coriolisOn: settings.enableCoriolis,
      derivationOn: settings.enableDerivation,
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

  ConditionsUiState _emptyState(
    UnitFormatter? formatter,
    AppSettings? settings,
  ) {
    final units = settings?.units ?? const UnitSettings();
    return ConditionsUiState(
      temperature: ConditionsField(
        label: 'Temperature',
        displayValue: 15,
        rawValue: 15,
        symbol: units.temperature.symbol,
        displayMin: -100,
        displayMax: 100,
        displayStep: 1,
        decimals: 0,
        inputField: InputField.temperature,
        displayUnit: units.temperature,
      ),
      altitude: ConditionsField(
        label: 'Altitude',
        displayValue: 0,
        rawValue: 0,
        symbol: units.distance.symbol,
        displayMin: -500,
        displayMax: 15000,
        displayStep: 10,
        decimals: 0,
        inputField: InputField.distance,
        displayUnit: units.distance,
      ),
      humidity: ConditionsField(
        label: 'Humidity',
        displayValue: 50,
        rawValue: 0.5,
        symbol: '%',
        displayMin: 0,
        displayMax: 100,
        displayStep: 1,
        decimals: 0,
        inputField: InputField.humidity,
        displayUnit: Unit.percent,
      ),
      pressure: ConditionsField(
        label: 'Pressure',
        displayValue: 1013,
        rawValue: 1013,
        symbol: units.pressure.symbol,
        displayMin: 300,
        displayMax: 1500,
        displayStep: 1,
        decimals: 0,
        inputField: InputField.pressure,
        displayUnit: units.pressure,
      ),
      powderSensOn: false,
      useDiffPowderTemp: false,
      coriolisOn: false,
      derivationOn: false,
    );
  }
}

final conditionsVmProvider =
    AsyncNotifierProvider<ConditionsViewModel, ConditionsUiState>(
      ConditionsViewModel.new,
    );
