// ЧИСТИЙ DART
import 'package:eballistica/core/models/unit_settings.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/domain/ballistics_service.dart';
import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/core/providers/service_providers.dart';
import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/models/projectile.dart' show DragModelType;
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/solver/trajectory_data.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/models/formatted_row.dart';

// ── Spoiler data ─────────────────────────────────────────────────────────────

class TablesSpoilerData {
  final String rifleName;
  final String? caliber;
  final String? twist;
  final String? dragModel;
  final String? bc;
  final String? zeroMv;
  final String? currentMv;
  final String? zeroDist;
  final String? bulletLen;
  final String? bulletDiam;
  final String? bulletWeight;
  final String? formFactor;
  final String? sectionalDensity;
  final String? gyroStability;
  final String? temperature;
  final String? humidity;
  final String? pressure;
  final String? windSpeed;
  final String? windDir;

  const TablesSpoilerData({
    required this.rifleName,
    this.caliber,
    this.twist,
    this.dragModel,
    this.bc,
    this.zeroMv,
    this.currentMv,
    this.zeroDist,
    this.bulletLen,
    this.bulletDiam,
    this.bulletWeight,
    this.formFactor,
    this.sectionalDensity,
    this.gyroStability,
    this.temperature,
    this.humidity,
    this.pressure,
    this.windSpeed,
    this.windDir,
  });
}

// ── State ────────────────────────────────────────────────────────────────────

sealed class TablesUiState {
  const TablesUiState();
}

class TablesUiLoading extends TablesUiState {
  const TablesUiLoading();
}

class TablesUiEmpty extends TablesUiState {
  const TablesUiEmpty();
}

class TablesUiReady extends TablesUiState {
  final TablesSpoilerData spoiler;
  final FormattedTableData? zeroCrossings;
  final FormattedTableData mainTable;

  const TablesUiReady({
    required this.spoiler,
    this.zeroCrossings,
    required this.mainTable,
  });
}

class TablesUiError extends TablesUiState {
  final String message;
  const TablesUiError(this.message);
}

// ── ViewModel ────────────────────────────────────────────────────────────────

class TablesViewModel extends AsyncNotifier<TablesUiState> {
  double? _cachedZeroElevRad;
  List<double>? _lastZeroKey;

  @override
  Future<TablesUiState> build() async => const TablesUiLoading();

  Future<void> recalculate() async {
    final profile = ref.read(shotProfileProvider).value;
    final settings = ref.read(settingsProvider).value;
    final formatter = ref.read(unitFormatterProvider);

    if (profile == null || settings == null) {
      state = const AsyncData(TablesUiEmpty());
      return;
    }

    if (state.value is! TablesUiReady) {
      state = const AsyncData(TablesUiLoading());
    }

    try {
      final cfg = settings.tableConfig;
      final opts = TableCalcOptions(
        startM: cfg.startM,
        endM: cfg.endM,
        stepM: cfg.stepM < 1.0 ? cfg.stepM : 1.0,
        usePowderSensitivity: settings.enablePowderSensitivity,
      );

      final zeroKey = _buildZeroKey(profile, settings.enablePowderSensitivity);
      final useCache = listEquals(zeroKey, _lastZeroKey);

      final result = await ref
          .read(ballisticsServiceProvider)
          .calculateTable(
            profile,
            opts,
            cachedZeroElevRad: useCache ? _cachedZeroElevRad : null,
          );

      if (!useCache) {
        _cachedZeroElevRad = result.zeroElevationRad;
        _lastZeroKey = zeroKey;
      }

      final uiState = _buildReadyState(
        profile: profile,
        settings: settings,
        formatter: formatter,
        result: result,
      );

      state = AsyncData(uiState);
    } catch (e) {
      state = AsyncData(TablesUiError(e.toString()));
    }
  }

  // ── Private builders ───────────────────────────────────────────────────────

  TablesUiReady _buildReadyState({
    required ShotProfile profile,
    required AppSettings settings,
    required UnitFormatter formatter,
    required BallisticsResult result,
  }) {
    final cfg = settings.tableConfig;
    final units = settings.units;
    final hit = result.hitResult;

    final spoiler = _buildSpoiler(profile, settings, formatter);

    // Apply per-table unit overrides
    final effUnits = units.copyWith(
      drop: cfg.dropUnit,
      adjustment: cfg.adjUnit,
    );

    // Filter trajectory to display step
    final filtered = _filterTraj(
      hit.trajectory,
      cfg.startM,
      cfg.endM,
      cfg.stepM,
    );

    final zeroDistM = profile.zeroDistance.in_(Unit.meter);
    final mainTable = _buildTable(
      filtered,
      effUnits,
      cfg,
      zeroDistM: zeroDistM,
    );

    // Zero crossings
    FormattedTableData? zeroCrossings;
    if (cfg.showZeros) {
      final zeros = hit.zeros;
      if (zeros.isNotEmpty) {
        zeroCrossings = _buildTable(zeros, effUnits, cfg, isZeroTable: true);
      }
    }

    return TablesUiReady(
      spoiler: spoiler,
      zeroCrossings: zeroCrossings,
      mainTable: mainTable,
    );
  }

  TablesSpoilerData _buildSpoiler(
    ShotProfile profile,
    AppSettings settings,
    UnitFormatter formatter,
  ) {
    final cfg = settings.tableConfig;
    final units = settings.units;
    final rifle = profile.rifle;
    final cart = profile.cartridge;
    final proj = cart.projectile;
    final dm = proj.dm;
    final conds = profile.conditions;
    final winds = profile.winds;

    final twistInch = rifle.weapon.twist.in_(Unit.inch);
    final weightGr = dm.weight.in_(Unit.grain);
    final diamInch = dm.diameter.in_(Unit.inch);
    final lenInch = dm.length.in_(Unit.inch);

    // Powder sensitivity
    final powderSensOn =
        settings.enablePowderSensitivity && cart.usePowderSensitivity;
    final useDiffTemp = powderSensOn && settings.useDifferentPowderTemperature;

    final refMvMps = cart.mv.in_(Unit.mps);
    final refPowderTempC = cart.powderTemp.in_(Unit.celsius);

    double mvAtTempC(double tC) {
      if (refMvMps <= 0 || cart.tempModifier == 0) return refMvMps;
      return (cart.tempModifier / 100.0 / (15 / refMvMps)) *
              (tC - refPowderTempC) +
          refMvMps;
    }

    // Zero MV
    final zeroAtmo = profile.zeroConditions ?? conds;
    final zeroPowderTempC = useDiffTemp
        ? zeroAtmo.powderTemp.in_(Unit.celsius)
        : zeroAtmo.temperature.in_(Unit.celsius);
    final zeroMvMps = powderSensOn ? mvAtTempC(zeroPowderTempC) : refMvMps;

    // Current MV
    final currTempC = useDiffTemp
        ? conds.powderTemp.in_(Unit.celsius)
        : conds.temperature.in_(Unit.celsius);
    final currentMvMps = powderSensOn ? mvAtTempC(currTempC) : refMvMps;

    // Gyrostability (Miller)
    double sg = profile.toShot().calculateStabilityCoefficient();

    // Sectional density + form factor
    final sd = (weightGr > 0 && diamInch > 0)
        ? (weightGr / 7000.0) / (diamInch * diamInch)
        : null;
    final ff = (sd != null && dm.bc > 0) ? sd / dm.bc : null;

    String fmtV(double mps) {
      final disp = Velocity(mps, Unit.mps).in_(units.velocity);
      return '${disp.toStringAsFixed(FC.velocity.accuracyFor(units.velocity))} ${units.velocity.symbol}';
    }

    String fmtWithAcc(Dimension dim, Unit dispUnit, FieldConstraints fc) {
      return '${dim.in_(dispUnit).toStringAsFixed(fc.accuracyFor(dispUnit))} ${dispUnit.symbol}';
    }

    return TablesSpoilerData(
      rifleName: rifle.name,
      caliber: cfg.spoilerShowCaliber && diamInch > 0
          ? fmtWithAcc(dm.diameter, units.diameter, FC.bulletDiameter)
          : null,
      twist: cfg.spoilerShowTwist && twistInch > 0
          ? () {
              final tw = Distance(twistInch, Unit.inch).in_(units.twist);
              return '1:${tw.toStringAsFixed(FC.twist.accuracyFor(units.twist))} ${units.twist.symbol}';
            }()
          : null,
      dragModel: cfg.spoilerShowDragModel
          ? switch (proj.dragType) {
              DragModelType.g1 => 'G1',
              DragModelType.g7 => 'G7',
              DragModelType.custom => 'Custom',
            }
          : null,
      bc: cfg.spoilerShowBc && dm.bc > 0
          ? dm.bc.toStringAsFixed(FC.ballisticCoefficient.accuracy)
          : null,
      zeroMv: cfg.spoilerShowZeroMv ? fmtV(zeroMvMps) : null,
      currentMv: cfg.spoilerShowCurrMv ? fmtV(currentMvMps) : null,
      zeroDist: cfg.spoilerShowZeroDist
          ? fmtWithAcc(profile.zeroDistance, units.distance, FC.zeroDistance)
          : null,
      bulletLen: cfg.spoilerShowBulletLen && lenInch > 0
          ? fmtWithAcc(dm.length, units.length, FC.bulletLength)
          : null,
      bulletDiam: cfg.spoilerShowBulletDiam && diamInch > 0
          ? fmtWithAcc(dm.diameter, units.diameter, FC.bulletDiameter)
          : null,
      bulletWeight: cfg.spoilerShowBulletWeight && weightGr > 0
          ? () {
              final wDisp = Weight(weightGr, Unit.grain).in_(units.weight);
              return '${wDisp.toStringAsFixed(FC.bulletWeight.accuracyFor(units.weight))} ${units.weight.symbol}';
            }()
          : null,
      formFactor: cfg.spoilerShowFormFactor && ff != null
          ? ff.toStringAsFixed(3)
          : null,
      sectionalDensity: cfg.spoilerShowSectionalDensity && sd != null
          ? sd.toStringAsFixed(3)
          : null,
      gyroStability: cfg.spoilerShowGyroStability
          ? sg.toStringAsFixed(2)
          : null,
      temperature: cfg.spoilerShowTemp
          ? () {
              final t = conds.temperature.in_(units.temperature);
              return '${t.toStringAsFixed(FC.temperature.accuracyFor(units.temperature))} ${units.temperature.symbol}';
            }()
          : null,
      humidity: cfg.spoilerShowHumidity
          ? '${(conds.humidity * 100).toStringAsFixed(0)} %'
          : null,
      pressure: cfg.spoilerShowPressure
          ? () {
              final p = conds.pressure.in_(units.pressure);
              return '${p.toStringAsFixed(FC.pressure.accuracyFor(units.pressure))} ${units.pressure.symbol}';
            }()
          : null,
      windSpeed: cfg.spoilerShowWindSpeed && winds.isNotEmpty
          ? () {
              final ws = winds.first.velocity.in_(units.velocity);
              return '${ws.toStringAsFixed(FC.windVelocity.accuracyFor(units.velocity))} ${units.velocity.symbol}';
            }()
          : null,
      windDir: cfg.spoilerShowWindDir && winds.isNotEmpty
          ? '${winds.first.directionFrom.in_(Unit.degree).toStringAsFixed(0)}°'
          : null,
    );
  }

  FormattedTableData _buildTable(
    List<TrajectoryData> rows,
    UnitSettings effUnits, // UnitSettings
    TableConfig cfg, {
    bool isZeroTable = false,
    double? zeroDistM,
  }) {
    final hidden = cfg.hiddenCols;

    // Column definitions matching TrajectoryTable._catalogue
    final colDefs =
        <
          (
            String,
            String,
            String Function(Dimension?),
            double? Function(TrajectoryData),
            int,
          )
        >[
          (
            'range',
            'Range',
            (_) => (effUnits.distance).symbol,
            (r) => r.distance.in_(effUnits.distance),
            FC.targetDistance.accuracyFor(effUnits.distance),
          ),
          if (!hidden.contains('time'))
            ('time', 'Time', (_) => 's', (r) => r.time, 3),
          if (!hidden.contains('velocity'))
            (
              'velocity',
              'V',
              (_) => (effUnits.velocity).symbol,
              (r) => r.velocity.in_(effUnits.velocity),
              FC.velocity.accuracyFor(effUnits.velocity),
            ),
          if (!hidden.contains('height'))
            (
              'height',
              'Height',
              (_) => (effUnits.drop).symbol,
              (r) => r.height.in_(effUnits.drop),
              FC.drop.accuracyFor(effUnits.drop),
            ),
          if (!hidden.contains('drop'))
            (
              'drop',
              'Drop',
              (_) => (effUnits.drop).symbol,
              (r) => r.slantHeight.in_(effUnits.drop),
              FC.drop.accuracyFor(effUnits.drop),
            ),
          if (!hidden.contains('adjDrop'))
            (
              'adjDrop',
              'Drop°',
              (_) => (effUnits.adjustment).symbol,
              (r) => r.dropAngle.in_(effUnits.adjustment),
              FC.adjustment.accuracyFor(effUnits.adjustment),
            ),
          if (!hidden.contains('wind'))
            (
              'wind',
              'Wind',
              (_) => (effUnits.drop).symbol,
              (r) => r.windage.in_(effUnits.drop),
              FC.drop.accuracyFor(effUnits.drop),
            ),
          if (!hidden.contains('adjWind'))
            (
              'adjWind',
              'Wind°',
              (_) => (effUnits.adjustment).symbol,
              (r) => r.windageAngle.in_(effUnits.adjustment),
              FC.adjustment.accuracyFor(effUnits.adjustment),
            ),
          if (!hidden.contains('mach'))
            ('mach', 'Mach', (_) => '', (r) => r.mach, 2),
          if (!hidden.contains('energy'))
            (
              'energy',
              'Energy',
              (_) => (effUnits.energy).symbol,
              (r) => r.energy.in_(effUnits.energy),
              FC.energy.accuracyFor(effUnits.energy),
            ),
        ];

    // Distance headers (first column values serve as "headers")
    final distHeaders = <String>[];
    final tableRows = <FormattedRow>[];

    // Build as column-based: each colDef after 'range' becomes a FormattedRow
    // with cells for each trajectory point
    for (final row in rows) {
      final rangeVal = colDefs.first.$4(row);
      final rangeStr = rangeVal != null
          ? rangeVal.toStringAsFixed(colDefs.first.$5)
          : '—';

      // For zero table, add arrow indicator
      if (isZeroTable) {
        final arrow = (row.flag & TrajFlag.zeroUp.value) != 0
            ? ' ↑'
            : (row.flag & TrajFlag.zeroDown.value) != 0
            ? ' ↓'
            : '';
        distHeaders.add('$rangeStr$arrow');
      } else {
        distHeaders.add(rangeStr);
      }
    }

    // Precompute which distance points match the sighting zero distance
    final zeroDistFlags = <bool>[];
    if (zeroDistM != null) {
      for (final row in rows) {
        final distM = row.distance.in_(Unit.meter);
        zeroDistFlags.add((distM - zeroDistM).abs() < 0.5);
      }
    }

    // Find the single subsonic transition point (first row where mach drops below 1.0)
    int subsonicIndex = -1;
    if (cfg.showSubsonicTransition) {
      for (var i = 0; i < rows.length; i++) {
        if (rows[i].mach < 1.0) {
          subsonicIndex = i;
          break;
        }
      }
    }

    // Build rows (one per column definition, excluding range)
    for (var ci = 1; ci < colDefs.length; ci++) {
      final col = colDefs[ci];
      final cells = <FormattedCell>[];
      for (var pi = 0; pi < rows.length; pi++) {
        final row = rows[pi];
        final val = col.$4(row);
        final valStr = val != null ? val.toStringAsFixed(col.$5) : '—';
        final isZero = (row.flag & TrajFlag.zero.value) != 0;
        final isTarget = zeroDistFlags.isNotEmpty && zeroDistFlags[pi];
        cells.add(
          FormattedCell(
            value: valStr,
            isZeroCrossing: isZero,
            isSubsonic: pi == subsonicIndex,
            isTargetColumn: isTarget,
          ),
        );
      }
      tableRows.add(
        FormattedRow(label: col.$2, unitSymbol: col.$3(null), cells: cells),
      );
    }

    return FormattedTableData(
      distanceHeaders: distHeaders,
      rows: tableRows,
      distanceUnit: colDefs.first.$3(null),
    );
  }

  List<TrajectoryData> _filterTraj(
    List<TrajectoryData> traj,
    double startM,
    double endM,
    double stepM,
  ) {
    final result = <TrajectoryData>[];
    double nextM = startM;
    for (final p in traj) {
      final d = p.distance.in_(Unit.meter);
      if (d < startM - 0.5) continue;
      if (d > endM + 0.5) break;
      if (stepM > 1.0 && d < nextM - 0.5) continue;
      result.add(p);
      if (stepM > 1.0) nextM = ((d / stepM).round() + 1) * stepM;
    }
    return result;
  }

  // ── Zero key ───────────────────────────────────────────────────────────────

  List<double> _buildZeroKey(ShotProfile profile, bool usePowderSens) {
    final zeroAtmo = profile.zeroConditions ?? profile.conditions;
    final w = profile.rifle.weapon;
    final c = profile.cartridge;
    final dm = c.projectile.dm;
    return [
      w.sightHeight.in_(Unit.meter),
      w.twist.in_(Unit.inch),
      c.mv.in_(Unit.mps),
      c.powderTemp.in_(Unit.celsius),
      c.tempModifier,
      c.usePowderSensitivity ? 1.0 : 0.0,
      dm.bc,
      dm.weight.in_(Unit.gram),
      dm.diameter.in_(Unit.inch),
      dm.length.in_(Unit.inch),
      dm.dragTable.length.toDouble(),
      zeroAtmo.altitude.in_(Unit.meter),
      zeroAtmo.pressure.in_(Unit.hPa),
      zeroAtmo.temperature.in_(Unit.celsius),
      zeroAtmo.humidity,
      zeroAtmo.powderTemp.in_(Unit.celsius),
      profile.zeroDistance.in_(Unit.meter),
      profile.lookAngle.in_(Unit.radian),
      usePowderSens ? 1.0 : 0.0,
    ];
  }
}

final tablesVmProvider = AsyncNotifierProvider<TablesViewModel, TablesUiState>(
  TablesViewModel.new,
);
