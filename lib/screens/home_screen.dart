import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/calculation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../router.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/conditions.dart' as solver;
import '../src/solver/unit.dart' as solver;
import '../src/solver/unit.dart';
import '../src/solver/trajectory_data.dart';
import '../widgets/trajectory_chart.dart';
import '../widgets/wind_indicator.dart';
import '../widgets/side_control_block.dart';
import '../widgets/quick_actions_panel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(shotProfileProvider).value;
    final units = ref.watch(unitSettingsProvider);

    final rifleName = profile?.rifle.name ?? '—';
    final cartridgeName = profile?.cartridge.name ?? '—';

    // Helper: convert a Dimension from its raw unit to the display unit.
    String dimStr(dynamic dim, Unit rawUnit, Unit dispUnit, {int dec = 0}) {
      if (dim == null) return '—';
      final raw = (dim as dynamic).in_(rawUnit) as double;
      final disp = (rawUnit(raw) as dynamic).in_(dispUnit) as double;
      return '${disp.toStringAsFixed(dec)} ${dispUnit.symbol}';
    }

    final conditions = profile?.conditions;
    final tempStr = dimStr(
      conditions?.temperature,
      Unit.celsius,
      units.temperature,
    );
    final altStr = dimStr(conditions?.altitude, Unit.meter, units.distance);
    final pressStr = dimStr(conditions?.pressure, Unit.hPa, units.pressure);
    final humidStr = conditions != null
        ? '${(conditions.humidity * 100).toStringAsFixed(0)}%'
        : '—';

    return LayoutBuilder(
      builder: (context, constraints) {
        final topBlockHeight = constraints.maxHeight * 0.55;
        final botBlockHeight = constraints.maxHeight - topBlockHeight;

        return Column(
          children: [
            // ── Top block ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: topBlockHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Column(
                    children: [
                      // Rifle / cartridge selector row
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => context.push(Routes.rifleSelect),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$rifleName · $cartridgeName',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.more_horiz_rounded),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: () =>
                                context.push(Routes.projectileSelect),
                            icon: const Icon(Icons.rocket_launch_outlined),
                          ),
                        ],
                      ),

                      // Wind indicator + side controls
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: SideControlBlock(
                                  topIcon: Icons.info_outline,
                                  bottomIcon: Icons.note_add_outlined,
                                  infoRows: [
                                    (Icons.device_thermostat_outlined, tempStr),
                                    (Icons.terrain_outlined, altStr),
                                  ],
                                  onTopPressed: () =>
                                      context.push(Routes.shotDetails),
                                  onBottomPressed: () {},
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: WindIndicator(
                                  onAngleChanged: (degrees, _) {
                                    final existing =
                                        ref
                                            .read(shotProfileProvider)
                                            .value
                                            ?.winds ??
                                        [];
                                    final wind = solver.Wind(
                                      velocity: existing.isNotEmpty
                                          ? existing.first.velocity
                                          : solver.Velocity(0, solver.Unit.mps),
                                      directionFrom: solver.Angular(
                                        degrees,
                                        solver.Unit.degree,
                                      ),
                                    );
                                    ref
                                        .read(shotProfileProvider.notifier)
                                        .updateWinds([wind]);
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: SideControlBlock(
                                  topIcon: Icons.question_mark_outlined,
                                  bottomIcon: Icons.more_horiz_outlined,
                                  infoRows: [
                                    (Icons.water_drop_outlined, humidStr),
                                    (Icons.speed_outlined, pressStr),
                                  ],
                                  onTopPressed: () {},
                                  onBottomPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 80, child: const QuickActionsPanel()),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom block — 3 pages ────────────────────────────────────────
            SizedBox(
              height: botBlockHeight,

              child: ref.watch(homeCalculationProvider).isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: PageView(
                        controller: _pageController,
                        children: const [
                          _PageReticle(),
                          _PageTable(),
                          _PageChart(),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Page stubs ───────────────────────────────────────────────────────────────

class _PageReticle extends StatelessWidget {
  const _PageReticle();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Reticle & Adjustments'));
}

class _PageTable extends StatelessWidget {
  const _PageTable();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Adjustments Table'));
}

class _PageChart extends ConsumerStatefulWidget {
  const _PageChart();
  @override
  ConsumerState<_PageChart> createState() => _PageChartState();
}

class _PageChartState extends ConsumerState<_PageChart> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(homeCalculationProvider, (prev, next) {
      if (next.value?.trajectory != prev?.value?.trajectory) {
        if (mounted) setState(() => _selectedIndex = 0);
      }
    });

    // Home chart uses a separate calculation zeroed at targetDistance.
    final calc = ref.watch(homeCalculationProvider);
    if (calc.isLoading) return const Center(child: CircularProgressIndicator());
    final hit = calc.value;
    if (hit == null || hit.trajectory.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final units = ref.watch(unitSettingsProvider);
    final snapDistM =
        ref.watch(settingsProvider).value?.chartDistanceStep ?? 100.0;
    final traj = hit.trajectory;
    final si = _selectedIndex.clamp(0, traj.length - 1);

    return Column(
      children: [
        _ChartInfoGrid(point: traj[si], units: units),
        Expanded(
          child: TrajectoryChart(
            traj: traj,
            selectedIndex: si,
            snapDistM: snapDistM,
            onIndexSelected: (i) => setState(() => _selectedIndex = i),
          ),
        ),
      ],
    );
  }
}

// ── Info grid above chart ─────────────────────────────────────────────────────

class _ChartInfoGrid extends StatelessWidget {
  final TrajectoryData point;
  final dynamic units; // UnitSettings

  const _ChartInfoGrid({required this.point, required this.units});

  // Convert a solver Dimension to display unit value.
  // rawUnit: the unit the value is stored in (e.g. Unit.foot)
  // dispUnit: the target display unit (e.g. units.distance)
  double _conv(dynamic dim, Unit rawUnit, Unit dispUnit) {
    final raw = (dim as dynamic).in_(rawUnit) as double;
    return (rawUnit(raw) as dynamic).in_(dispUnit) as double;
  }

  String _fmt(double val, int dec, String sym) =>
      '${val.toStringAsFixed(dec)} $sym';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final distVal = _conv(point.distance, Unit.foot, units.distance);
    final htVal = _conv(point.height, Unit.foot, units.drop);
    final velVal = _conv(point.velocity, Unit.fps, units.velocity);
    final dropVal = _conv(point.dropAngle, Unit.mil, units.adjustment);
    final engVal = _conv(point.energy, Unit.joule, units.energy);
    final windVal = _conv(point.windageAngle, Unit.mil, units.adjustment);

    // Left column: Distance, Velocity, Energy, Time
    // Right column: Height, Drop, Windage, Mach
    final leftItems = [
      (Icons.straighten, _fmt(distVal, 0, units.distance.symbol)),
      (Icons.speed, _fmt(velVal, 0, units.velocity.symbol)),
      (Icons.bolt, _fmt(engVal, 0, units.energy.symbol)),
      (Icons.timer_outlined, '${point.time.toStringAsFixed(3)} s'),
    ];
    final rightItems = [
      (
        Icons.height,
        _fmt(htVal.abs(), FC.drop.accuracyFor(units.drop), units.drop.symbol) +
            (htVal < 0 ? ' ↓' : ' ↑'),
      ),
      (
        Icons.arrow_downward,
        _fmt(
          dropVal,
          FC.adjustment.accuracyFor(units.adjustment),
          units.adjustment.symbol,
        ),
      ),
      (
        Icons.arrow_right_alt,
        _fmt(
          windVal,
          FC.adjustment.accuracyFor(units.adjustment),
          units.adjustment.symbol,
        ),
      ),
      (Icons.air, '${point.mach.toStringAsFixed(2)} M'),
    ];

    final valueStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );

    Widget infoRow(IconData icon, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: cs.onSurface.withAlpha(140)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
