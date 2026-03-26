// ЧИСТИЙ DART — 0 flutter імпортів (крім flutter_riverpod)
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
import 'package:eballistica/core/solver/conditions.dart' show Wind;
import 'package:eballistica/core/solver/trajectory_data.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/models/adjustment_data.dart';
import 'package:eballistica/shared/models/chart_point.dart';
import 'package:eballistica/shared/models/formatted_row.dart';

// ── State ────────────────────────────────────────────────────────────────────

sealed class HomeUiState {
  const HomeUiState();
}

class HomeUiLoading extends HomeUiState {
  const HomeUiLoading();
}

class HomeUiReady extends HomeUiState {
  // Top block
  final String rifleName;
  final String cartridgeName;
  final double windAngleDeg;

  // Info tiles
  final String tempDisplay;
  final String altDisplay;
  final String pressDisplay;
  final String humidDisplay;

  // Bottom block — Page 1 (Reticle)
  final String cartridgeInfoLine;
  final AdjustmentData adjustment;
  final AdjustmentFormat adjustmentFormat;

  // Bottom block — Page 2 (Table)
  final FormattedTableData tableData;

  // Bottom block — Page 3 (Chart)
  final ChartData chartData;
  final HomeChartPointInfo? selectedPointInfo;
  final int? selectedChartIndex;

  const HomeUiReady({
    required this.rifleName,
    required this.cartridgeName,
    required this.windAngleDeg,
    required this.tempDisplay,
    required this.altDisplay,
    required this.pressDisplay,
    required this.humidDisplay,
    required this.cartridgeInfoLine,
    required this.adjustment,
    this.adjustmentFormat = AdjustmentFormat.arrows,
    required this.tableData,
    required this.chartData,
    this.selectedPointInfo,
    this.selectedChartIndex,
  });
}

class HomeUiError extends HomeUiState {
  final String message;
  const HomeUiError(this.message);
}

class HomeChartPointInfo {
  final String distance;
  final String velocity;
  final String energy;
  final String time;
  final String height;
  final String drop;
  final String windage;
  final String mach;

  const HomeChartPointInfo({
    required this.distance,
    required this.velocity,
    required this.energy,
    required this.time,
    required this.height,
    required this.drop,
    required this.windage,
    required this.mach,
  });
}

// ── ViewModel ────────────────────────────────────────────────────────────────

class HomeViewModel extends AsyncNotifier<HomeUiState> {
  double? _cachedZeroElevRad;
  List<double>? _lastZeroKey;

  @override
  Future<HomeUiState> build() async => const HomeUiLoading();

  Future<void> recalculate() async {
    final profile = ref.read(shotProfileProvider).value;
    final settings = ref.read(settingsProvider).value;
    final formatter = ref.read(unitFormatterProvider);

    if (profile == null || settings == null) return;

    // Keep previous Ready state visible while recalculating — no flicker.
    // Only show Loading on first calculation (when state is still Loading).
    if (state.value is! HomeUiReady) {
      state = const AsyncData(HomeUiLoading());
    }

    try {
      final opts = TargetCalcOptions(
        targetDistM: profile.targetDistance.in_(Unit.meter),
        chartStepM: settings.chartDistanceStep,
        usePowderSensitivity: settings.enablePowderSensitivity,
      );

      final zeroKey = _buildZeroKey(profile, settings.enablePowderSensitivity);
      final useCache = listEquals(zeroKey, _lastZeroKey);

      final result =
          await ref.read(ballisticsServiceProvider).calculateForTarget(
                profile,
                opts,
                cachedZeroElevRad: useCache ? _cachedZeroElevRad : null,
              );

      _cachedZeroElevRad = result.zeroElevationRad;
      _lastZeroKey = zeroKey;

      final uiState = _buildReadyState(
        profile: profile,
        settings: settings,
        formatter: formatter,
        result: result,
      );

      state = AsyncData(uiState);
    } catch (e) {
      state = AsyncData(HomeUiError(e.toString()));
    }
  }

  void selectChartPoint(int index) {
    final current = state.value;
    if (current is! HomeUiReady) return;
    final point = current.chartData.pointAt(index);
    if (point == null) return;

    final formatter = ref.read(unitFormatterProvider);
    final info = _buildPointInfo(point, formatter);
    state = AsyncData(HomeUiReady(
      rifleName: current.rifleName,
      cartridgeName: current.cartridgeName,
      windAngleDeg: current.windAngleDeg,
      tempDisplay: current.tempDisplay,
      altDisplay: current.altDisplay,
      pressDisplay: current.pressDisplay,
      humidDisplay: current.humidDisplay,
      cartridgeInfoLine: current.cartridgeInfoLine,
      adjustment: current.adjustment,
      adjustmentFormat: current.adjustmentFormat,
      tableData: current.tableData,
      chartData: current.chartData,
      selectedPointInfo: info,
      selectedChartIndex: index,
    ));
  }

  Future<void> updateWindDirection(double degrees) async {
    ref.read(shotProfileProvider.notifier).updateWinds([
      Wind(
        velocity: _currentWindVelocity(),
        directionFrom: Angular(degrees, Unit.degree),
      ),
    ]);
  }

  Future<void> updateWindSpeed(double rawMps) async {
    ref.read(shotProfileProvider.notifier).updateWindSpeed(rawMps);
  }

  Future<void> updateLookAngle(double degrees) async {
    ref.read(shotProfileProvider.notifier).updateLookAngle(degrees);
  }

  Future<void> updateTargetDistance(double meters) async {
    ref.read(shotProfileProvider.notifier).updateTargetDistance(meters);
  }

  // ── Private builders ───────────────────────────────────────────────────────

  Velocity _currentWindVelocity() {
    final winds =
        ref.read(shotProfileProvider).value?.winds ?? const <Wind>[];
    return winds.isNotEmpty ? winds.first.velocity : Velocity(0, Unit.mps);
  }

  HomeUiReady _buildReadyState({
    required ShotProfile profile,
    required AppSettings settings,
    required UnitFormatter formatter,
    required BallisticsResult result,
  }) {
    final hit = result.hitResult;
    final traj = hit.trajectory;
    final targetM = profile.targetDistance.in_(Unit.meter);

    // ── Top block ──
    final windDirDeg = profile.winds.isNotEmpty
        ? profile.winds.first.directionFrom.in_(Unit.degree)
        : 0.0;

    final conditions = profile.conditions;
    final tempStr = formatter.temperature(conditions.temperature);
    final altStr = formatter.distance(conditions.altitude);
    final pressStr = formatter.pressure(conditions.pressure);
    final humidStr = formatter.humidity(conditions.humidity);

    // ── Cartridge info line ──
    final cartridgeInfoLine = _buildCartridgeInfoLine(profile, formatter);

    // ── Adjustment data ──
    final adjustment = _buildAdjustment(hit, targetM, settings);

    // ── Table data (5 distances around target) ──
    final tableData = _buildHomeTable(hit, targetM, settings, formatter);

    // ── Chart data + auto-select target point ──
    final chartData = _buildChartData(traj, settings);
    final autoIndex = _closestIndex(chartData.points, targetM);
    final autoInfo = autoIndex != null
        ? _buildPointInfo(chartData.points[autoIndex], formatter)
        : null;

    return HomeUiReady(
      rifleName: profile.rifle.name,
      cartridgeName: profile.cartridge.name,
      windAngleDeg: windDirDeg,
      tempDisplay: tempStr,
      altDisplay: altStr,
      pressDisplay: pressStr,
      humidDisplay: humidStr,
      cartridgeInfoLine: cartridgeInfoLine,
      adjustment: adjustment,
      adjustmentFormat: settings.adjustmentFormat,
      tableData: tableData,
      chartData: chartData,
      selectedPointInfo: autoInfo,
      selectedChartIndex: autoIndex,
    );
  }

  String _buildCartridgeInfoLine(ShotProfile profile, UnitFormatter fmt) {
    final proj = profile.cartridge.projectile;
    final mvStr = fmt.muzzleVelocity(profile.cartridge.mv);
    final bcAcc = FC.ballisticCoefficient.accuracy;
    final dragStr = switch (proj.dragType) {
      DragModelType.g1 => 'G1 ${proj.dm.bc.toStringAsFixed(bcAcc)}',
      DragModelType.g7 => 'G7 ${proj.dm.bc.toStringAsFixed(bcAcc)}',
      DragModelType.custom => 'Custom',
    };

    // Gyroscopic stability factor Sg (Miller)
    String? sgStr;
    final twistInch = profile.rifle.weapon.twist.in_(Unit.inch);
    final weightGr = proj.dm.weight.in_(Unit.grain);
    final diamInch = proj.dm.diameter.in_(Unit.inch);
    final lenInch = proj.dm.length.in_(Unit.inch);
    if (weightGr > 0 && diamInch > 0 && lenInch > 0 && twistInch > 0) {
      final lCal = lenInch / diamInch;
      final nCal = twistInch / diamInch;
      final sg = (30.0 * weightGr) /
          (nCal * nCal *
              diamInch *
              diamInch *
              diamInch *
              lCal *
              (1.0 + lCal * lCal));
      sgStr = 'Sg ${sg.toStringAsFixed(2)}';
    }

    return '${proj.name};  $mvStr;  $dragStr${sgStr != null ? ';  $sgStr' : ''}';
  }

  AdjustmentData _buildAdjustment(
    HitResult hit,
    double targetM,
    AppSettings settings,
  ) {
    final elevAngle = hit.shot.relativeAngle;
    final point = hit.trajectory.isNotEmpty
        ? hit.getAtDistance(Distance(targetM, Unit.meter))
        : null;
    final windAngle = point?.windageAngle;

    final dispUnits = <(Unit, String)>[
      if (settings.showMrad) (Unit.mRad, 'MRAD'),
      if (settings.showMoa) (Unit.moa, 'MOA'),
      if (settings.showMil) (Unit.mil, 'MIL'),
      if (settings.showCmPer100m) (Unit.cmPer100m, 'cm/100m'),
      if (settings.showInPer100yd) (Unit.inchesPer100Yd, 'in/100yd'),
    ];

    final elevValues = dispUnits.map((u) {
      final val = elevAngle.in_(u.$1);
      return AdjustmentValue(
        absValue: val.abs(),
        isPositive: val >= 0,
        symbol: u.$2,
        decimals: u.$1.accuracy,
      );
    }).toList();

    final windValues = windAngle != null
        ? dispUnits.map((u) {
            final corr = -(windAngle.in_(u.$1));
            return AdjustmentValue(
              absValue: corr.abs(),
              isPositive: corr >= 0,
              symbol: u.$2,
              decimals: u.$1.accuracy,
            );
          }).toList()
        : <AdjustmentValue>[];

    return AdjustmentData(elevation: elevValues, windage: windValues);
  }

  FormattedTableData _buildHomeTable(
    HitResult hit,
    double targetM,
    AppSettings settings,
    UnitFormatter fmt,
  ) {
    final stepM = settings.homeTableStep;
    final units = settings.units;
    final distAcc = FC.targetDistance.accuracyFor(units.distance);

    final dists = [
      targetM - 2 * stepM,
      targetM - stepM,
      targetM,
      targetM + stepM,
      targetM + 2 * stepM,
    ];

    final points = dists
        .map((d) =>
            d < 0 ? null : hit.getAtDistance(Distance(d, Unit.meter)))
        .toList();

    final distHeaders = dists.map<String>((m) {
      if (m < 0) return '—';
      final disp = Unit.meter(m).in_(units.distance);
      return disp.toStringAsFixed(distAcc);
    }).toList();

    const targetCol = 2;
    final milAcc = FC.adjustment.accuracyFor(Unit.mil);
    final moaAcc = FC.adjustment.accuracyFor(Unit.moa);

    double conv(dynamic dim, Unit rawUnit, Unit dispUnit) {
      final raw = (dim as dynamic).in_(rawUnit) as double;
      return (rawUnit(raw) as dynamic).in_(dispUnit) as double;
    }

    final rowDefs = <(String, String, double? Function(TrajectoryData), int)>[
      ('Height', units.drop.symbol,
          (p) => conv(p.height, Unit.foot, units.drop),
          FC.drop.accuracyFor(units.drop)),
      ('Slant Ht', units.drop.symbol,
          (p) => conv(p.slantHeight, Unit.foot, units.drop),
          FC.drop.accuracyFor(units.drop)),
      ('Angle', 'MIL',
          (p) => conv(p.angle, Unit.mil, Unit.mil), milAcc),
      ('Angle', 'MOA',
          (p) => conv(p.angle, Unit.mil, Unit.moa), moaAcc),
      ('Drop', 'MIL',
          (p) => conv(p.dropAngle, Unit.mil, Unit.mil), milAcc),
      ('Drop', 'MOA',
          (p) => conv(p.dropAngle, Unit.mil, Unit.moa), moaAcc),
      ('Windage', 'MIL',
          (p) => conv(p.windageAngle, Unit.mil, Unit.mil), milAcc),
      ('Windage', 'MOA',
          (p) => conv(p.windageAngle, Unit.mil, Unit.moa), moaAcc),
      ('Velocity', units.velocity.symbol,
          (p) => conv(p.velocity, Unit.fps, units.velocity),
          FC.velocity.accuracyFor(units.velocity)),
      ('Energy', units.energy.symbol,
          (p) => conv(p.energy, Unit.footPound, units.energy),
          FC.energy.accuracyFor(units.energy)),
      ('Time', 's', (p) => p.time, 3),
    ];

    final rows = rowDefs.map((rd) {
      final cells = <FormattedCell>[];
      for (var ci = 0; ci < dists.length; ci++) {
        final p = points[ci];
        final valStr = p == null
            ? '—'
            : (rd.$3(p) ?? double.nan).toStringAsFixed(rd.$4);
        cells.add(FormattedCell(
          value: valStr,
          isTargetColumn: ci == targetCol,
        ));
      }
      return FormattedRow(label: rd.$1, unitSymbol: rd.$2, cells: cells);
    }).toList();

    return FormattedTableData(
      distanceHeaders: distHeaders,
      rows: rows,
      distanceUnit: units.distance.symbol,
    );
  }

  int? _closestIndex(List<ChartPoint> points, double targetM) {
    if (points.isEmpty) return null;
    var best = 0;
    var bestDist = (points[0].distanceM - targetM).abs();
    for (var i = 1; i < points.length; i++) {
      final d = (points[i].distanceM - targetM).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  ChartData _buildChartData(List<TrajectoryData> traj, AppSettings settings) {
    final points = traj.map((td) {
      final isZero = (td.flag & TrajFlag.zero.value) != 0;
      final isMach = (td.flag & TrajFlag.mach.value) != 0;
      return ChartPoint(
        distanceM: td.distance.in_(Unit.meter),
        heightCm: td.height.in_(Unit.centimeter),
        velocityMps: td.velocity.in_(Unit.mps),
        mach: td.mach,
        energyJ: td.energy.in_(Unit.joule),
        time: td.time,
        dropAngleMil: td.dropAngle.in_(Unit.mil),
        windageAngleMil: td.windageAngle.in_(Unit.mil),
        isZeroCrossing: isZero,
        isSubsonic: isMach || td.mach < 1.0,
      );
    }).toList();

    return ChartData(
      points: points,
      snapDistM: settings.chartDistanceStep,
    );
  }

  HomeChartPointInfo _buildPointInfo(ChartPoint point, UnitFormatter fmt) {
    return HomeChartPointInfo(
      distance: fmt.distance(Distance(point.distanceM, Unit.meter)),
      velocity: fmt.velocity(Velocity(point.velocityMps, Unit.mps)),
      energy: fmt.energy(Energy(point.energyJ, Unit.joule)),
      time: fmt.time(point.time),
      height: fmt.drop(Distance(point.heightCm / 100.0, Unit.meter)),
      drop:
          '${point.dropAngleMil.toStringAsFixed(2)} ${fmt.adjustmentSymbol}',
      windage:
          '${point.windageAngleMil.toStringAsFixed(2)} ${fmt.adjustmentSymbol}',
      mach: fmt.mach(point.mach),
    );
  }

  // ── Zero key (copied from calculation_provider) ────────────────────────────

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

final homeVmProvider = AsyncNotifierProvider<HomeViewModel, HomeUiState>(
  HomeViewModel.new,
);
