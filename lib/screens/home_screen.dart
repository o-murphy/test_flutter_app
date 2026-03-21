import 'package:flutter/material.dart';
import '../widgets/wind_indicator.dart';
import '../widgets/side_control_block.dart';
import '../widgets/quick_actions_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight * 0.55;

        return Column(
          children: [
            // ── Top card ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Cartridge selector
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () {},
                              child: const Text(
                                '.338 Lapua Mag 300gr SMK',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: () {},
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
                              topIcon: Icons.info_outline,
                              bottomIcon: Icons.note_add_outlined,
                              infoRows: const [
                                (Icons.thunderstorm_outlined, ''),
                                (Icons.device_thermostat_outlined, '23°C'),
                                (Icons.terrain_outlined, '150 m'),
                              ],
                              onTopPressed: () => print("Info pressed"),
                              onBottomPressed: () => print("Notes pressed"),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: WindIndicator(
                              onAngleChanged: (degrees, clockFormat) {
                                print("Wind direction: $degrees°");
                              },
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: SideControlBlock(
                              topIcon: Icons.question_mark_outlined,
                              bottomIcon: Icons.more_horiz_outlined,
                              infoRows: const [
                                (Icons.thunderstorm_outlined, ''),
                                (Icons.water_drop_outlined, '29%'),
                                (Icons.speed_outlined, '992 hPa'),
                              ],
                              onTopPressed: () => print("Help pressed"),
                              onBottomPressed: () => print("Tools pressed"),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick actions
                    const QuickActionsPanel(),
                  ],
                ),
              ),
            ),

            // ── Ballistic parameters (scrollable) ─────────────────────────────
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [Text('There will be calculation result')],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
