import 'package:flutter/material.dart';

import 'table_config.dart';
import 'unit_settings.dart';

export 'table_config.dart';

enum AdjustmentFormat { arrows, signs, letters }

class AppSettings {
  final UnitSettings units;
  final String languageCode;
  final ThemeMode themeMode;
  final double chartDistanceStep;
  final double homeTableStep;
  final TableConfig tableConfig;
  final bool showSubsonicTransition;
  final bool enableCoriolis;
  final bool enablePowderSensitivity;
  final bool useDifferentPowderTemperature;
  final bool enableDerivation;
  final bool enableAerodynamicJump;
  final bool pressureDependsOnAltitude;
  final AdjustmentFormat adjustmentFormat;
  final bool showMrad;
  final bool showMoa;
  final bool showMil;
  final bool showCmPer100m;
  final bool showInPer100yd;

  const AppSettings({
    this.units = const UnitSettings(),
    this.languageCode = 'en',
    this.themeMode = ThemeMode.system,
    this.chartDistanceStep = 10,
    this.homeTableStep = 100,
    this.tableConfig = const TableConfig(),
    this.showSubsonicTransition = false,
    this.enableCoriolis = false,
    this.enablePowderSensitivity = false,
    this.useDifferentPowderTemperature = false,
    this.enableDerivation = false,
    this.enableAerodynamicJump = false,
    this.pressureDependsOnAltitude = false,
    this.adjustmentFormat = AdjustmentFormat.arrows,
    this.showMrad = true,
    this.showMoa = false,
    this.showMil = false,
    this.showCmPer100m = false,
    this.showInPer100yd = false,
  });

  AppSettings copyWith({
    UnitSettings? units,
    String? languageCode,
    ThemeMode? themeMode,
    double? chartDistanceStep,
    double? homeTableStep,
    TableConfig? tableConfig,
    bool? showSubsonicTransition,
    bool? enableCoriolis,
    bool? enablePowderSensitivity,
    bool? useDifferentPowderTemperature,
    bool? enableDerivation,
    bool? enableAerodynamicJump,
    bool? pressureDependsOnAltitude,
    AdjustmentFormat? adjustmentFormat,
    bool? showMrad,
    bool? showMoa,
    bool? showMil,
    bool? showCmPer100m,
    bool? showInPer100yd,
  }) => AppSettings(
    units: units ?? this.units,
    languageCode: languageCode ?? this.languageCode,
    themeMode: themeMode ?? this.themeMode,
    chartDistanceStep: chartDistanceStep ?? this.chartDistanceStep,
    homeTableStep: homeTableStep ?? this.homeTableStep,
    tableConfig: tableConfig ?? this.tableConfig,
    showSubsonicTransition:
        showSubsonicTransition ?? this.showSubsonicTransition,
    enableCoriolis: enableCoriolis ?? this.enableCoriolis,
    enablePowderSensitivity:
        enablePowderSensitivity ?? this.enablePowderSensitivity,
    useDifferentPowderTemperature:
        useDifferentPowderTemperature ?? this.useDifferentPowderTemperature,
    enableDerivation: enableDerivation ?? this.enableDerivation,
    enableAerodynamicJump: enableAerodynamicJump ?? this.enableAerodynamicJump,
    pressureDependsOnAltitude:
        pressureDependsOnAltitude ?? this.pressureDependsOnAltitude,
    adjustmentFormat: adjustmentFormat ?? this.adjustmentFormat,
    showMrad: showMrad ?? this.showMrad,
    showMoa: showMoa ?? this.showMoa,
    showMil: showMil ?? this.showMil,
    showCmPer100m: showCmPer100m ?? this.showCmPer100m,
    showInPer100yd: showInPer100yd ?? this.showInPer100yd,
  );

  static const _adjustmentFormatNames = {
    AdjustmentFormat.arrows: 'arrows',
    AdjustmentFormat.signs: 'signs',
    AdjustmentFormat.letters: 'letters',
  };
  static const _adjustmentFormatByName = {
    'arrows': AdjustmentFormat.arrows,
    'signs': AdjustmentFormat.signs,
    'letters': AdjustmentFormat.letters,
  };
  static const _themeModeNames = {
    ThemeMode.system: 'system',
    ThemeMode.light: 'light',
    ThemeMode.dark: 'dark',
  };
  static const _themeModeByName = {
    'system': ThemeMode.system,
    'light': ThemeMode.light,
    'dark': ThemeMode.dark,
  };

  Map<String, dynamic> toJson() => {
    'units': units.toJson(),
    'languageCode': languageCode,
    'themeMode': _themeModeNames[themeMode],
    'chartDistanceStep': chartDistanceStep,
    'homeTableStep': homeTableStep,
    'showSubsonicTransition': showSubsonicTransition,
    'enableCoriolis': enableCoriolis,
    'enablePowderSensitivity': enablePowderSensitivity,
    'useDifferentPowderTemperature': useDifferentPowderTemperature,
    'enableDerivation': enableDerivation,
    'enableAerodynamicJump': enableAerodynamicJump,
    'pressureDependsOnAltitude': pressureDependsOnAltitude,
    'showMrad': showMrad,
    'showMoa': showMoa,
    'showMil': showMil,
    'showCmPer100m': showCmPer100m,
    'showInPer100yd': showInPer100yd,
    'adjustmentFormat': _adjustmentFormatNames[adjustmentFormat],
    'tableConfig': tableConfig.toJson(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    bool b(String key, bool default_) {
      return json[key] as bool? ?? default_;
    }

    double d(String key, double default_) {
      return (json[key] as num?)?.toDouble() ?? default_;
    }

    return AppSettings(
      units: UnitSettings.fromJson(
        json['units'] as Map<String, dynamic>? ?? {},
      ),
      languageCode: json['languageCode'] as String? ?? 'en',
      themeMode: _themeModeByName[json['themeMode']] ?? ThemeMode.system,
      chartDistanceStep: d('chartDistanceStep', 100),
      homeTableStep: d('homeTableStep', 100),
      showSubsonicTransition: b('showSubsonicTransition', true),
      enableCoriolis: b('enableCoriolis', false),
      enablePowderSensitivity: b('enablePowderSensitivity', false),
      useDifferentPowderTemperature: b('useDifferentPowderTemperature', false),
      enableDerivation: b('enableDerivation', false),
      enableAerodynamicJump: b('enableAerodynamicJump', false),
      pressureDependsOnAltitude: b('pressureDependsOnAltitude', false),
      showMrad: b('showMrad', true),
      showMoa: b('showMoa', false),
      showMil: b('showMil', false),
      showCmPer100m: b('showCmPer100m', false),
      showInPer100yd: b('showInPer100yd', false),
      adjustmentFormat:
          _adjustmentFormatByName[json['adjustmentFormat']] ??
          AdjustmentFormat.arrows,
      tableConfig: json['tableConfig'] != null
          ? TableConfig.fromJson(json['tableConfig'] as Map<String, dynamic>)
          : TableConfig(
              // backward-compat: migrate old flat fields
              stepM: d('tableDistanceStep', 100),
              hiddenCols: Set<String>.from(
                json['tableHiddenCols'] as List? ?? [],
              ),
            ),
    );
  }
}
