import 'package:flutter/material.dart';

import 'unit_settings.dart';

enum AdjustmentFormat { arrows, signs, letters }

class AppSettings {
  final UnitSettings units;
  final String languageCode;
  final ThemeMode themeMode;
  final double tableDistanceStep;
  final double chartDistanceStep;
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
    this.units                    = const UnitSettings(),
    this.languageCode             = 'en',
    this.themeMode                = ThemeMode.system,
    this.tableDistanceStep        = 100,
    this.chartDistanceStep        = 100,
    this.showSubsonicTransition   = true,
    this.enableCoriolis           = false,
    this.enablePowderSensitivity          = false,
    this.useDifferentPowderTemperature    = false,
    this.enableDerivation                 = false,
    this.enableAerodynamicJump    = false,
    this.pressureDependsOnAltitude = false,
    this.adjustmentFormat          = AdjustmentFormat.arrows,
    this.showMrad                  = true,
    this.showMoa                   = false,
    this.showMil                   = false,
    this.showCmPer100m             = false,
    this.showInPer100yd            = false,
  });

  AppSettings copyWith({
    UnitSettings? units,
    String? languageCode,
    ThemeMode? themeMode,
    double? tableDistanceStep,
    double? chartDistanceStep,
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
    units:                      units                     ?? this.units,
    languageCode:               languageCode              ?? this.languageCode,
    themeMode:                  themeMode                 ?? this.themeMode,
    tableDistanceStep:          tableDistanceStep         ?? this.tableDistanceStep,
    chartDistanceStep:          chartDistanceStep         ?? this.chartDistanceStep,
    showSubsonicTransition:     showSubsonicTransition    ?? this.showSubsonicTransition,
    enableCoriolis:             enableCoriolis            ?? this.enableCoriolis,
    enablePowderSensitivity:          enablePowderSensitivity         ?? this.enablePowderSensitivity,
    useDifferentPowderTemperature:    useDifferentPowderTemperature   ?? this.useDifferentPowderTemperature,
    enableDerivation:                 enableDerivation                ?? this.enableDerivation,
    enableAerodynamicJump:      enableAerodynamicJump     ?? this.enableAerodynamicJump,
    pressureDependsOnAltitude:  pressureDependsOnAltitude ?? this.pressureDependsOnAltitude,
    adjustmentFormat:           adjustmentFormat          ?? this.adjustmentFormat,
    showMrad:                   showMrad                  ?? this.showMrad,
    showMoa:                    showMoa                   ?? this.showMoa,
    showMil:                    showMil                   ?? this.showMil,
    showCmPer100m:              showCmPer100m             ?? this.showCmPer100m,
    showInPer100yd:             showInPer100yd            ?? this.showInPer100yd,
  );

  static const _adjustmentFormatNames = {
    AdjustmentFormat.arrows:  'arrows',
    AdjustmentFormat.signs:   'signs',
    AdjustmentFormat.letters: 'letters',
  };
  static const _adjustmentFormatByName = {
    'arrows':  AdjustmentFormat.arrows,
    'signs':   AdjustmentFormat.signs,
    'letters': AdjustmentFormat.letters,
  };

  static const _themeModeNames = {
    ThemeMode.system: 'system',
    ThemeMode.light:  'light',
    ThemeMode.dark:   'dark',
  };
  static const _themeModeByName = {
    'system': ThemeMode.system,
    'light':  ThemeMode.light,
    'dark':   ThemeMode.dark,
  };

  Map<String, dynamic> toJson() => {
    'units':                      units.toJson(),
    'languageCode':               languageCode,
    'themeMode':                  _themeModeNames[themeMode],
    'tableDistanceStep':          tableDistanceStep,
    'chartDistanceStep':          chartDistanceStep,
    'showSubsonicTransition':     showSubsonicTransition,
    'enableCoriolis':             enableCoriolis,
    'enablePowderSensitivity':          enablePowderSensitivity,
    'useDifferentPowderTemperature':    useDifferentPowderTemperature,
    'enableDerivation':                 enableDerivation,
    'enableAerodynamicJump':      enableAerodynamicJump,
    'pressureDependsOnAltitude':  pressureDependsOnAltitude,
    'adjustmentFormat':           _adjustmentFormatNames[adjustmentFormat],
    'showMrad':                   showMrad,
    'showMoa':                    showMoa,
    'showMil':                    showMil,
    'showCmPer100m':              showCmPer100m,
    'showInPer100yd':             showInPer100yd,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    units:                      UnitSettings.fromJson(json['units'] as Map<String, dynamic>? ?? {}),
    languageCode:               json['languageCode'] as String? ?? 'en',
    themeMode:                  _themeModeByName[json['themeMode']] ?? ThemeMode.system,
    tableDistanceStep:          (json['tableDistanceStep'] as num?)?.toDouble() ?? 100,
    chartDistanceStep:          (json['chartDistanceStep'] as num?)?.toDouble() ?? 100,
    showSubsonicTransition:     json['showSubsonicTransition'] as bool? ?? true,
    enableCoriolis:             json['enableCoriolis'] as bool? ?? false,
    enablePowderSensitivity:          json['enablePowderSensitivity']       as bool? ?? false,
    useDifferentPowderTemperature:    json['useDifferentPowderTemperature'] as bool? ?? false,
    enableDerivation:                 json['enableDerivation']              as bool? ?? false,
    enableAerodynamicJump:      json['enableAerodynamicJump'] as bool? ?? false,
    pressureDependsOnAltitude:  json['pressureDependsOnAltitude'] as bool? ?? false,
    adjustmentFormat:           _adjustmentFormatByName[json['adjustmentFormat']] ?? AdjustmentFormat.arrows,
    showMrad:                   json['showMrad']        as bool? ?? true,
    showMoa:                    json['showMoa']         as bool? ?? false,
    showMil:                    json['showMil']         as bool? ?? false,
    showCmPer100m:              json['showCmPer100m']   as bool? ?? false,
    showInPer100yd:             json['showInPer100yd']  as bool? ?? false,
  );
}
