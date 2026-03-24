import 'package:flutter/material.dart';

import 'table_config.dart';
import 'unit_settings.dart';

export 'table_config.dart';

enum AdjustmentFormat { arrows, signs, letters }

class AppSettings {
  final UnitSettings     units;
  final String           languageCode;
  final ThemeMode        themeMode;
  final double           chartDistanceStep;
  final TableConfig      tableConfig;
  final bool             showSubsonicTransition;
  final bool             enableCoriolis;
  final bool             enablePowderSensitivity;
  final bool             useDifferentPowderTemperature;
  final bool             enableDerivation;
  final bool             enableAerodynamicJump;
  final bool             pressureDependsOnAltitude;
  final AdjustmentFormat adjustmentFormat;
  final bool             showMrad;
  final bool             showMoa;
  final bool             showMil;
  final bool             showCmPer100m;
  final bool             showInPer100yd;

  const AppSettings({
    this.units                         = const UnitSettings(),
    this.languageCode                  = 'en',
    this.themeMode                     = ThemeMode.system,
    this.chartDistanceStep             = 10,
    this.tableConfig                   = const TableConfig(),
    this.showSubsonicTransition        = false,
    this.enableCoriolis                = false,
    this.enablePowderSensitivity       = false,
    this.useDifferentPowderTemperature = false,
    this.enableDerivation              = false,
    this.enableAerodynamicJump         = false,
    this.pressureDependsOnAltitude     = false,
    this.adjustmentFormat              = AdjustmentFormat.arrows,
    this.showMrad                      = true,
    this.showMoa                       = false,
    this.showMil                       = false,
    this.showCmPer100m                 = false,
    this.showInPer100yd                = false,
  });

  AppSettings copyWith({
    UnitSettings?     units,
    String?           languageCode,
    ThemeMode?        themeMode,
    double?           chartDistanceStep,
    TableConfig?      tableConfig,
    bool?             showSubsonicTransition,
    bool?             enableCoriolis,
    bool?             enablePowderSensitivity,
    bool?             useDifferentPowderTemperature,
    bool?             enableDerivation,
    bool?             enableAerodynamicJump,
    bool?             pressureDependsOnAltitude,
    AdjustmentFormat? adjustmentFormat,
    bool?             showMrad,
    bool?             showMoa,
    bool?             showMil,
    bool?             showCmPer100m,
    bool?             showInPer100yd,
  }) => AppSettings(
    units:                         units                         ?? this.units,
    languageCode:                  languageCode                  ?? this.languageCode,
    themeMode:                     themeMode                     ?? this.themeMode,
    chartDistanceStep:             chartDistanceStep             ?? this.chartDistanceStep,
    tableConfig:                   tableConfig                   ?? this.tableConfig,
    showSubsonicTransition:        showSubsonicTransition        ?? this.showSubsonicTransition,
    enableCoriolis:                enableCoriolis                ?? this.enableCoriolis,
    enablePowderSensitivity:       enablePowderSensitivity       ?? this.enablePowderSensitivity,
    useDifferentPowderTemperature: useDifferentPowderTemperature ?? this.useDifferentPowderTemperature,
    enableDerivation:              enableDerivation              ?? this.enableDerivation,
    enableAerodynamicJump:         enableAerodynamicJump         ?? this.enableAerodynamicJump,
    pressureDependsOnAltitude:     pressureDependsOnAltitude     ?? this.pressureDependsOnAltitude,
    adjustmentFormat:              adjustmentFormat              ?? this.adjustmentFormat,
    showMrad:                      showMrad                      ?? this.showMrad,
    showMoa:                       showMoa                       ?? this.showMoa,
    showMil:                       showMil                       ?? this.showMil,
    showCmPer100m:                 showCmPer100m                 ?? this.showCmPer100m,
    showInPer100yd:                showInPer100yd                ?? this.showInPer100yd,
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
    'units':                         units.toJson(),
    'languageCode':                  languageCode,
    'themeMode':                     _themeModeNames[themeMode],
    'chartDistanceStep':             chartDistanceStep,
    'tableConfig':                   tableConfig.toJson(),
    'showSubsonicTransition':        showSubsonicTransition,
    'enableCoriolis':                enableCoriolis,
    'enablePowderSensitivity':       enablePowderSensitivity,
    'useDifferentPowderTemperature': useDifferentPowderTemperature,
    'enableDerivation':              enableDerivation,
    'enableAerodynamicJump':         enableAerodynamicJump,
    'pressureDependsOnAltitude':     pressureDependsOnAltitude,
    'adjustmentFormat':              _adjustmentFormatNames[adjustmentFormat],
    'showMrad':                      showMrad,
    'showMoa':                       showMoa,
    'showMil':                       showMil,
    'showCmPer100m':                 showCmPer100m,
    'showInPer100yd':                showInPer100yd,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    units:           UnitSettings.fromJson(
                       json['units'] as Map<String, dynamic>? ?? {}),
    languageCode:    json['languageCode']  as String? ?? 'en',
    themeMode:       _themeModeByName[json['themeMode']] ?? ThemeMode.system,
    chartDistanceStep: (json['chartDistanceStep'] as num?)?.toDouble() ?? 100,
    tableConfig:     json['tableConfig'] != null
                       ? TableConfig.fromJson(
                           json['tableConfig'] as Map<String, dynamic>)
                       : TableConfig(
                           // backward-compat: migrate old flat fields
                           stepM: (json['tableDistanceStep'] as num?)
                                      ?.toDouble() ?? 100,
                           hiddenCols: Set<String>.from(
                               json['tableHiddenCols'] as List? ?? []),
                         ),
    showSubsonicTransition:        json['showSubsonicTransition']        as bool? ?? true,
    enableCoriolis:                json['enableCoriolis']                as bool? ?? false,
    enablePowderSensitivity:       json['enablePowderSensitivity']       as bool? ?? false,
    useDifferentPowderTemperature: json['useDifferentPowderTemperature'] as bool? ?? false,
    enableDerivation:              json['enableDerivation']              as bool? ?? false,
    enableAerodynamicJump:         json['enableAerodynamicJump']         as bool? ?? false,
    pressureDependsOnAltitude:     json['pressureDependsOnAltitude']     as bool? ?? false,
    adjustmentFormat: _adjustmentFormatByName[json['adjustmentFormat']]
                          ?? AdjustmentFormat.arrows,
    showMrad:      json['showMrad']      as bool? ?? true,
    showMoa:       json['showMoa']       as bool? ?? false,
    showMil:       json['showMil']       as bool? ?? false,
    showCmPer100m: json['showCmPer100m'] as bool? ?? false,
    showInPer100yd:json['showInPer100yd']as bool? ?? false,
  );
}
