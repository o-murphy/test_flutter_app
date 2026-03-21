import 'package:flutter/material.dart';
import '../widgets/wind_indicator.dart';
import '../widgets/side_control_block.dart';
import '../widgets/quick_actions_panel.dart';

Widget _buildCard(String text, Color color) {
  return Card(
    margin: const EdgeInsets.all(8),
    color: color,
    child: Center(
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 32),
      ),
    ),
  );
}

// TODO: make thunderstorm_outlined buttons a little bigger
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final topBlockHeight = constraints.maxHeight * 0.55;
        final botBlockHeight = constraints.maxHeight - topBlockHeight;

        return Column(
          children: [
            // ── Top card ──────────────────────────────────────────────────────
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
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Savage AXIS || Precision',
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
            SizedBox(
              height: botBlockHeight,
              child: PageView(
                children: [
                  _buildCard('Current projectile, reticle and adjustments', Colors.blueGrey),
                  _buildCard('Adjustments table', Colors.indigo),
                  _buildCard('Simplified Trajectory Chart', Colors.deepPurple),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
