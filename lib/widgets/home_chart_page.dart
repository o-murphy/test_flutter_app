import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/dimension_converter.dart';
import '../providers/calculation_provider.dart';
import '../providers/settings_provider.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/trajectory_data.dart';
import '../src/solver/unit.dart';
import 'trajectory_chart.dart';

// ─── Page 3 — Chart ───────────────────────────────────────────────────────────

class HomeChartPage extends ConsumerStatefulWidget {
  const HomeChartPage({super.key});

  @override
  ConsumerState<HomeChartPage> createState() => _HomeChartPageState();
}

class _HomeChartPageState extends ConsumerState<HomeChartPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(homeCalculationProvider, (prev, next) {
      if (next.value?.trajectory != prev?.value?.trajectory) {
        if (mounted) setState(() => _selectedIndex = 0);
      }
    });

    final calc = ref.watch(homeCalculationProvider);
    if (calc.isLoading) return const Center(child: CircularProgressIndicator());
    final hit = calc.value;
    if (hit == null || hit.trajectory.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final units       = ref.watch(unitSettingsProvider);
    final settingsVal = ref.watch(settingsProvider).value;
    final snapDistM   = settingsVal?.chartDistanceStep ?? 100.0;
    final showSubsonic = settingsVal?.showSubsonicTransition ?? false;
    final traj = hit.trajectory;
    final si   = _selectedIndex.clamp(0, traj.length - 1);

    return Column(
      children: [
        _ChartInfoGrid(point: traj[si], units: units),
        Expanded(
          child: TrajectoryChart(
            traj: traj,
            selectedIndex: si,
            snapDistM: snapDistM,
            showSubsonicLine: showSubsonic,
            onIndexSelected: (i) => setState(() => _selectedIndex = i),
          ),
        ),
      ],
    );
  }
}

// ─── Info grid above chart ────────────────────────────────────────────────────

class _ChartInfoGrid extends StatelessWidget {
  const _ChartInfoGrid({required this.point, required this.units});

  final TrajectoryData point;
  final dynamic        units; // UnitSettings

  double _conv(dynamic dim, Unit rawUnit, Unit dispUnit) {
    return valueInUnit(convertDimension(dim, rawUnit), rawUnit, dispUnit);
  }

  String _fmt(double val, int dec, String sym) => '${val.toStringAsFixed(dec)} $sym';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final distVal = _conv(point.distance,     Unit.foot,      units.distance);
    final htVal   = _conv(point.height,       Unit.foot,      units.drop);
    final velVal  = _conv(point.velocity,     Unit.fps,       units.velocity);
    final dropVal = _conv(point.dropAngle,    Unit.mil,       units.adjustment);
    final engVal  = _conv(point.energy,       Unit.joule,     units.energy);
    final windVal = _conv(point.windageAngle, Unit.mil,       units.adjustment);

    final leftItems = [
      (Icons.straighten,    _fmt(distVal, 0, units.distance.symbol)),
      (Icons.speed,         _fmt(velVal,  0, units.velocity.symbol)),
      (Icons.bolt,          _fmt(engVal,  0, units.energy.symbol)),
      (Icons.timer_outlined,'${point.time.toStringAsFixed(3)} s'),
    ];
    final rightItems = [
      (Icons.height,
        _fmt(htVal.abs(), FC.drop.accuracyFor(units.drop), units.drop.symbol) +
            (htVal < 0 ? ' ↓' : ' ↑')),
      (Icons.arrow_downward,
        _fmt(dropVal, FC.adjustment.accuracyFor(units.adjustment), units.adjustment.symbol)),
      (Icons.arrow_right_alt,
        _fmt(windVal, FC.adjustment.accuracyFor(units.adjustment), units.adjustment.symbol)),
      (Icons.air, '${point.mach.toStringAsFixed(2)} M'),
    ];

    final valueStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface);

    Widget infoRow(IconData icon, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: cs.onSurface.withAlpha(140)),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: valueStyle, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: leftItems.map((e) => infoRow(e.$1, e.$2)).toList(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rightItems.map((e) => infoRow(e.$1, e.$2)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
