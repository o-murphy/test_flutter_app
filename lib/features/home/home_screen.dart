import 'dart:math' as math;

import 'package:eballistica/shared/widgets/pages_dots_indicator.dart';
import 'package:eballistica/shared/widgets/unit_constrained_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eballistica/router.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/features/home/home_vm.dart';
import 'package:eballistica/features/home/widgets/home_chart_page.dart';
import 'package:eballistica/features/home/widgets/home_reticle_page.dart';
import 'package:eballistica/features/home/widgets/home_table_page.dart';
import 'package:eballistica/features/home/widgets/quick_actions_panel.dart';
import 'package:eballistica/features/home/widgets/side_control_block.dart';
import 'package:eballistica/features/home/widgets/wind_indicator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late final _calcDoneCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  // Fade in → hold briefly → fade out
  late final _calcDoneAnim = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
  ]).animate(_calcDoneCtrl);

  @override
  void dispose() {
    _pageController.dispose();
    _calcDoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Trigger overlay animation when VM transitions from Loading → Ready.
    ref.listen<AsyncValue<HomeUiState>>(homeVmProvider, (prev, next) {
      final wasLoading = prev?.value is HomeUiLoading;
      final isReady = next.value is HomeUiReady;
      if (wasLoading && isReady) _calcDoneCtrl.forward(from: 0);
    });

    final vmAsync = ref.watch(homeVmProvider);
    final vmState = vmAsync.value;

    final rifleName = vmState is HomeUiReady ? vmState.rifleName : '—';
    final cartridgeName = vmState is HomeUiReady ? vmState.cartridgeName : '—';
    final tempStr = vmState is HomeUiReady ? vmState.tempDisplay : '—';
    final altStr = vmState is HomeUiReady ? vmState.altDisplay : '—';
    final pressStr = vmState is HomeUiReady ? vmState.pressDisplay : '—';
    final humidStr = vmState is HomeUiReady ? vmState.humidDisplay : '—';
    final windAngleDeg = vmState is HomeUiReady ? vmState.windAngleDeg : 0.0;
    final windInitialAngle = (windAngleDeg - 90) * math.pi / 180;

    return LayoutBuilder(
      builder: (context, constraints) {
        const bottomHeight = 40.0; // Fixed height of paging indicator
        const minTopH = 350.0;
        const maxTopH = 400.0;
        const minCentralH = 300.0;

        // Height for scrollable content (Top + Central)
        final scrollableHeight = math.max(
          constraints.maxHeight - bottomHeight,
          minTopH + minCentralH,
        );

        // Calculating the height of the top block
        final topBlockHeight = math.min(
          maxTopH,
          math.max(scrollableHeight * 0.55, minTopH),
        );

        // Height of the center block (what's left)
        final centralBlockHeight = scrollableHeight - topBlockHeight;

        // Is scrolling needed?
        final needsScroll =
            scrollableHeight > constraints.maxHeight - bottomHeight;

        return Stack(
          children: [
            // Scrollable content (Top + Central)
            SingleChildScrollView(
              physics: needsScroll
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── Top block ───────────────────────────────────────────────
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
                                    onPressed: () =>
                                        context.push(Routes.profiles),
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
                                  icon: const Icon(
                                    Icons.rocket_launch_outlined,
                                  ),
                                ),
                              ],
                            ),

                            // Wind indicator + side controls
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  12,
                                  0,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: SideControlBlock(
                                        topIcon: Icons.info_outline,
                                        bottomIcon: Icons.note_add_outlined,
                                        infoRows: [
                                          (
                                            Icons.device_thermostat_outlined,
                                            tempStr,
                                          ),
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
                                        initialAngle: windInitialAngle,
                                        onAngleChanged: (degrees, _) {
                                          ref
                                              .read(homeVmProvider.notifier)
                                              .updateWindDirection(degrees);
                                        },
                                        onDirectionTap: (deg) =>
                                            showUnitEditDialog(
                                              context,
                                              label: 'Wind direction',
                                              rawValue: deg,
                                              constraints: FC.windDirection,
                                              displayUnit: Unit.degree,
                                              onChanged: (newDeg) {
                                                final normalized =
                                                    ((newDeg % 360) + 360) %
                                                    360;
                                                ref
                                                    .read(
                                                      homeVmProvider.notifier,
                                                    )
                                                    .updateWindDirection(
                                                      normalized,
                                                    );
                                              },
                                            ),
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

                            SizedBox(
                              height: 80,
                              child: const QuickActionsPanel(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Central block — 3 pages ───────────────────────────────────
                  SizedBox(
                    height: centralBlockHeight,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: (i) =>
                                    setState(() => _currentPage = i),
                                children: const [
                                  HomeReticlePage(),
                                  HomeTablePage(),
                                  HomeChartPage(),
                                ],
                              ),
                            ),
                            // Padding for spacing - bottom indicator will overlay
                            const SizedBox(height: 8),
                          ],
                        ),
                        // Brief spinner overlay — fades in then out after each recalc.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: FadeTransition(
                              opacity: _calcDoneAnim,
                              child: Container(
                                color: Colors.black.withAlpha(90),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Add bottom padding to prevent content from hiding under Bottom Block
                  SizedBox(height: bottomHeight),
                ],
              ),
            ),

            // ── Bottom Block — Fixed page indicator (sticky at bottom) ────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: bottomHeight,
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.surface,
                child: PageDotsIndicator(
                  current: _currentPage,
                  count: 3,
                  onPageChanged: (page) {
                    _pageController.animateToPage(
                      page,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    setState(() => _currentPage = page);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
