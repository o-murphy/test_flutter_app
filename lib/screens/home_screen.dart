import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/calculation_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../router.dart';
import '../widgets/trajectory_chart.dart';
import '../widgets/wind_indicator.dart';
import '../widgets/side_control_block.dart';
import '../widgets/quick_actions_panel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(shotProfileProvider).value;

    final rifleName     = profile?.rifle.name      ?? '—';
    final cartridgeName = profile?.cartridge.name  ?? '—';

    final conditions    = profile?.conditions;
    final tempStr       = conditions != null
        ? '${conditions.temperature.in_(conditions.temperature.units).toStringAsFixed(0)}°C'
        : '—';
    final altStr        = conditions != null
        ? '${conditions.altitude.in_(conditions.altitude.units).toStringAsFixed(0)} m'
        : '—';
    final humidStr      = conditions != null
        ? '${(conditions.humidity * 100).toStringAsFixed(0)}%'
        : '—';
    final pressStr      = conditions != null
        ? '${conditions.pressure.in_(conditions.pressure.units).toStringAsFixed(0)} hPa'
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
                  bottomLeft:  Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Rifle / cartridge selector row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => context.push(Routes.rifleSelect),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            onPressed: () => context.push(Routes.projectileSelect),
                            icon: const Icon(Icons.rocket_launch_outlined),
                          ),
                        ],
                      ),
                    ),

                    // Wind indicator + side controls
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: SideControlBlock(
                              topIcon:    Icons.info_outline,
                              bottomIcon: Icons.note_add_outlined,
                              infoRows: [
                                (Icons.thunderstorm_outlined,      ''),
                                (Icons.device_thermostat_outlined,  tempStr),
                                (Icons.terrain_outlined,            altStr),
                              ],
                              onTopPressed:    () => context.push(Routes.shotDetails),
                              onBottomPressed: () {},
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: WindIndicator(
                              onAngleChanged: (degrees, _) {
                                ref.read(shotProfileProvider.notifier)
                                    .updateLookAngle(degrees);
                              },
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: SideControlBlock(
                              topIcon:    Icons.question_mark_outlined,
                              bottomIcon: Icons.more_horiz_outlined,
                              infoRows: [
                                (Icons.thunderstorm_outlined, ''),
                                (Icons.water_drop_outlined,   humidStr),
                                (Icons.speed_outlined,        pressStr),
                              ],
                              onTopPressed:    () {},
                              onBottomPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),

                    const QuickActionsPanel(),
                  ],
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
  Widget build(BuildContext context) => const Center(child: Text('Reticle & Adjustments'));
}

class _PageTable extends StatelessWidget {
  const _PageTable();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Adjustments Table'));
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
