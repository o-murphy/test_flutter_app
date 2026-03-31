// ЧИСТИЙ DART
import 'package:eballistica/core/models/unit_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/domain/ballistics_service.dart';
import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/core/providers/service_providers.dart';
import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/solver/trajectory_data.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/models/formatted_row.dart';

// ── State ────────────────────────────────────────────────────────────────────

sealed class TrajectoryTablesUiState {
  const TrajectoryTablesUiState();
}

class TrajectoryTablesUiLoading extends TrajectoryTablesUiState {
  const TrajectoryTablesUiLoading();
}

class TrajectoryTablesUiEmpty extends TrajectoryTablesUiState {
  const TrajectoryTablesUiEmpty();
}

class TrajectoryTablesUiReady extends TrajectoryTablesUiState {
  final FormattedTableData? zeroCrossings;
  final FormattedTableData mainTable;

  const TrajectoryTablesUiReady({this.zeroCrossings, required this.mainTable});
}

class TrajectoryTablesUiError extends TrajectoryTablesUiState {
  final String message;
  const TrajectoryTablesUiError(this.message);
}

// ── ViewModel ────────────────────────────────────────────────────────────────

class TrajectoryTablesViewModel extends AsyncNotifier<TrajectoryTablesUiState> {
  double? _cachedZeroElevRad;
  List<double>? _lastZeroKey;

  @override
  Future<TrajectoryTablesUiState> build() async =>
      const TrajectoryTablesUiLoading();

  Future<void> recalculate() async {
    final profile = ref.read(shotProfileProvider).value;
    final settings = ref.read(settingsProvider).value;
    final formatter = ref.read(unitFormatterProvider);

    if (profile == null || settings == null) {
      state = const AsyncData(TrajectoryTablesUiEmpty());
      return;
    }

    if (state.value is! TrajectoryTablesUiReady) {
      state = const AsyncData(TrajectoryTablesUiLoading());
    }

    try {
      final cfg = settings.tableConfig;
      final opts = TableCalcOptions(
        startM: cfg.startM,
        endM: cfg.endM,
        stepM: cfg.stepM < 1.0 ? cfg.stepM : 1.0,
      );

      final zeroKey = _buildZeroKey(profile);
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
      state = AsyncData(TrajectoryTablesUiError(e.toString()));
    }
  }

  // ── Private builders ───────────────────────────────────────────────────────

  TrajectoryTablesUiReady _buildReadyState({
    required ShotProfile profile,
    required AppSettings settings,
    required UnitFormatter formatter,
    required BallisticsResult result,
  }) {
    final cfg = settings.tableConfig;
    final units = settings.units;
    final hit = result.hitResult;

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

    return TrajectoryTablesUiReady(
      zeroCrossings: zeroCrossings,
      mainTable: mainTable,
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

  List<double> _buildZeroKey(ShotProfile profile) {
    final zeroAtmo = profile.zeroConditions ?? profile.conditions;
    final r = profile.rifle;
    final c = profile.cartridge;
    final proj = c.projectile;
    final zeroUsePowderSens =
        (profile.zeroUsePowderSensitivity ?? profile.usePowderSensitivity) &&
        c.usePowderSensitivity;
    return [
      r.sightHeight.in_(Unit.meter),
      r.twist.in_(Unit.inch),
      c.mv.in_(Unit.mps),
      c.powderTemp.in_(Unit.celsius),
      c.powderSensitivity.in_(Unit.fraction),
      c.usePowderSensitivity ? 1.0 : 0.0,
      proj.coefRows.isNotEmpty ? proj.coefRows.first.bcCd : 0.0,
      proj.weight.in_(Unit.gram),
      proj.diameter.in_(Unit.inch),
      proj.length.in_(Unit.inch),
      proj.coefRows.length.toDouble(),
      zeroAtmo.altitude.in_(Unit.meter),
      zeroAtmo.pressure.in_(Unit.hPa),
      zeroAtmo.temperature.in_(Unit.celsius),
      zeroAtmo.humidity,
      zeroAtmo.powderTemp.in_(Unit.celsius),
      profile.zeroDistance.in_(Unit.meter),
      profile.lookAngle.in_(Unit.radian),
      zeroUsePowderSens ? 1.0 : 0.0,
      profile.zeroUseDiffPowderTemp ? 1.0 : 0.0,
    ];
  }
}

final trajectoryTablesVmProvider =
    AsyncNotifierProvider<TrajectoryTablesViewModel, TrajectoryTablesUiState>(
      TrajectoryTablesViewModel.new,
    );
