import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/calculation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../router.dart';
import '../src/solver/conditions.dart' as solver;
import '../src/solver/unit.dart' as solver;
import '../src/solver/unit.dart';
import '../widgets/trajectory_chart.dart';
import '../widgets/wind_indicator.dart';
import '../widgets/side_control_block.dart';
import '../widgets/quick_actions_panel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(shotProfileProvider).value;
    final units   = ref.watch(unitSettingsProvider);

    final rifleName    = profile?.rifle.name ?? '—';
    final cartridgeName = profile?.cartridge.name ?? '—';

    // Helper: convert a Dimension from its raw unit to the display unit.
    String dimStr(dynamic dim, Unit rawUnit, Unit dispUnit, {int dec = 0}) {
      if (dim == null) return '—';
      final raw  = (dim as dynamic).in_(rawUnit) as double;
      final disp = (rawUnit(raw) as dynamic).in_(dispUnit) as double;
      return '${disp.toStringAsFixed(dec)} ${dispUnit.symbol}';
    }

    final conditions = profile?.conditions;
    final tempStr  = dimStr(conditions?.temperature, Unit.celsius, units.temperature);
    final altStr   = dimStr(conditions?.altitude,    Unit.meter,   units.distance);
    final pressStr = dimStr(conditions?.pressure,    Unit.hPa,     units.pressure);
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

              child: ref.watch(calculationProvider).isLoading
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

class _PageChart extends ConsumerWidget {
  const _PageChart();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc = ref.watch(calculationProvider);
    if (calc.isLoading) return const Center(child: CircularProgressIndicator());
    final traj = calc.value?.trajectory ?? [];
    if (traj.isEmpty) return const Center(child: Text('No data'));
    return TrajectoryChart(traj: traj);
  }
}
