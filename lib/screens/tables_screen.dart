import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:test_app/src/conditions.dart';
import 'package:test_app/src/unit.dart';
import 'package:test_app/src/ffi/bclibc_ffi.dart';
import 'package:test_app/src/ffi/bclibc_bindings.g.dart' show BCTrajFlag;
import '../widgets/trajectory_chart.dart';
import '../widgets/trajectory_table.dart';

// ─── G7 standard drag table ───────────────────────────────────────────────────

const _g7 = [
  (0.000, 0.1198),
  (0.050, 0.1197),
  (0.100, 0.1196),
  (0.150, 0.1194),
  (0.200, 0.1193),
  (0.250, 0.1194),
  (0.300, 0.1194),
  (0.350, 0.1194),
  (0.400, 0.1193),
  (0.450, 0.1193),
  (0.500, 0.1194),
  (0.550, 0.1193),
  (0.600, 0.1194),
  (0.650, 0.1197),
  (0.700, 0.1202),
  (0.725, 0.1207),
  (0.750, 0.1215),
  (0.775, 0.1226),
  (0.800, 0.1242),
  (0.825, 0.1266),
  (0.850, 0.1306),
  (0.875, 0.1368),
  (0.900, 0.1464),
  (0.925, 0.1660),
  (0.950, 0.2054),
  (0.975, 0.2993),
  (1.000, 0.3803),
  (1.025, 0.4015),
  (1.050, 0.4043),
  (1.075, 0.4034),
  (1.100, 0.4014),
  (1.150, 0.3955),
  (1.200, 0.3884),
  (1.300, 0.3750),
  (1.400, 0.3618),
  (1.500, 0.3498),
  (1.600, 0.3388),
  (1.800, 0.3189),
  (2.000, 0.3018),
  (2.200, 0.2873),
  (2.400, 0.2744),
  (2.600, 0.2635),
  (2.800, 0.2540),
  (3.000, 0.2456),
];

// ─── Ballistic calculation ────────────────────────────────────────────────────
//   .338 Lapua Mag 300gr SMK, BC G7=0.381, MV=815 m/s
//   Zero: 100 m @ 150 m alt, 745 mmHg, -1°C, 78%
//   Current: 150 m alt, 992 hPa, 23°C, 29%
//   Trajectory: 0–1000 m, step 100 m

BcAtmosphere _bcAtmo(Atmo a) => BcAtmosphere(
  t0: a.temperature.in_(Unit.celsius),
  a0: a.altitude.in_(Unit.foot),
  p0: a.pressure.in_(Unit.hPa),
  mach: a.mach.in_(Unit.fps),
  densityRatio: a.densityRatio,
  cLowestTempC: Atmo.cLowestTempC,
);

List<BcTrajectoryData> _runCalc() {
  final bc = BcLibC.open();

  final zeroAtmo = Atmo(
    altitude: Unit.meter(150),
    pressure: Unit.mmHg(745),
    temperature: Unit.celsius(-1),
    humidity: 78,
  );
  final curAtmo = Atmo(
    altitude: Unit.meter(150),
    pressure: Unit.hPa(992),
    temperature: Unit.celsius(23),
    humidity: 29,
  );

  final dragTable = _g7.map((p) => BcDragPoint(p.$1, p.$2)).toList();

  const mvFps = 815.0 * 3.28084;
  const sightFt = 9.0 / 30.48;

  BcShotProps makeProps({
    required BcAtmosphere atmo,
    required double barrelElevationRad,
  }) => BcShotProps(
    bc: 0.381,
    lookAngleRad: 0.0,
    twistInch: 10.0,
    lengthInch: 1.7,
    diameterInch: 0.338,
    weightGrain: 300.0,
    barrelElevationRad: barrelElevationRad,
    barrelAzimuthRad: 0.0,
    sightHeightFt: sightFt,
    alt0Ft: atmo.a0,
    muzzleVelocityFps: mvFps,
    atmo: atmo,
    coriolis: const BcCoriolis(),
    dragTable: dragTable,
  );

  final zeroAngle = bc.findZeroAngle(
    makeProps(atmo: _bcAtmo(zeroAtmo), barrelElevationRad: 0.0),
    100.0 * 3.28084,
  );

  final result = bc.integrate(
    makeProps(atmo: _bcAtmo(curAtmo), barrelElevationRad: zeroAngle),
    BcTrajectoryRequest(
      rangeLimitFt: 1000.0 * 3.28084,
      rangeStepFt: 100.0 * 3.28084,
      filterFlags: BCTrajFlag.BC_TRAJ_FLAG_RANGE,
    ),
  );

  return result.trajectory;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List<BcTrajectoryData>? _traj;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  Future<void> _calculate() async {
    setState(() {
      _loading = true;
      _error = null;
      _traj = null;
    });
    try {
      final traj = await Future(_runCalc);
      if (mounted) {
        setState(() {
          _traj = traj;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _calculate, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_traj == null) return const SizedBox.shrink();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const chartH = 300.0;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              // TODO: add Detailes card and hide under spoiler
              children: [
                // TODO: hide TrajectoryChart under spoiler
                SizedBox(
                  width: constraints.maxWidth,
                  height: chartH,
                  child: TrajectoryChart(traj: _traj!),
                ),
                const Divider(height: 1),
                // TODO: add Zeros table and hide under spoiler
                TrajectoryTable(
                  traj: _traj!,
                  availableWidth: constraints.maxWidth,
                ),
              ],
            ),
          );
        },
      ),
    );
    // TODO: add Row with filled buttons configure-btn and export-btn under the scroll
  }
}
