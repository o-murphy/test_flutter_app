import 'package:eballistica/features/convertors/sub_screens/convertors_sub_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/providers/recalc_coordinator.dart';

import 'features/home/home_screen.dart';
import 'features/home/sub_screens/home_sub_screens.dart';
import 'features/conditions/conditions_screen.dart';
import 'features/tables/tables_screen.dart';
import 'features/tables/sub_screens/tables_config_screen.dart';
import 'features/convertors/convertor_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/sub_screens/settings_units_screen.dart';
import 'features/settings/sub_screens/settings_adjustment_screen.dart';

// ─── Route paths ─────────────────────────────────────────────────────────────

abstract final class Routes {
  // Primary
  static const home = '/home';
  static const conditions = '/conditions';
  static const tables = '/tables';
  static const convertors = '/convertors';
  static const settings = '/settings';

  // Home stack
  static const rifleSelect = '/home/rifle-select';
  static const rifleEdit = '/home/rifle-select/rifle-edit';
  static const sightSelect = '/home/rifle-select/sight-select';
  static const cartridge = '/home/rifle-select/cartridge';
  static const cartridgeEdit = '/home/rifle-select/cartridge/edit';
  static const projectileSelect = '/home/projectile-select';
  static const projectileEdit = '/home/projectile-select/edit';
  static const shotDetails = '/home/shot-details';

  // Tables stack
  static const tableConfig = '/tables/configure';

  // Convertors stack
  static const convertor = '/convertors/:type'; // push individual convertor
  static String convertorOf(String type) => '/convertors/$type';

  // Settings stack
  static const settingsUnits = '/settings/units';
  static const settingsAdjustment = '/settings/adjustment';
}

// ─── Router ──────────────────────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _ScaffoldWithNav(shell: shell),
      branches: [
        // ── Home branch ──────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, _) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'rifle-select',
                  builder: (_, _) => const RifleSelectScreen(),
                  routes: [
                    GoRoute(
                      path: 'rifle-edit',
                      builder: (_, _) => const RifleEditScreen(),
                    ),
                    GoRoute(
                      path: 'sight-select',
                      builder: (_, _) => const SightSelectScreen(),
                    ),
                    GoRoute(
                      path: 'cartridge',
                      builder: (_, _) => const CartridgeScreen(),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (_, _) => const CartridgeEditScreen(),
                        ),
                      ],
                    ),
                  ],
                ),
                GoRoute(
                  path: 'projectile-select',
                  builder: (_, _) => const ProjectileSelectScreen(),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (_, _) => const ProjectileEditScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'shot-details',
                  builder: (_, _) => const ShotDetailsScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Conditions branch ────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.conditions,
              builder: (_, _) => const ConditionsScreen(),
            ),
          ],
        ),

        // ── Tables branch ────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.tables,
              builder: (_, _) => const TablesScreen(),
              routes: [
                GoRoute(
                  path: 'configure',
                  builder: (_, _) => const TableConfigScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Convertors branch ────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.convertors,
              builder: (_, _) => const ConvertorScreen(),
              routes: [
                GoRoute(
                  path: 'target-distance',
                  builder: (_, _) => const DistanceConvertorScreen(),
                ),
                GoRoute(
                  path: 'velocity',
                  builder: (_, _) => const VelocityConvertorScreen(),
                ),
                GoRoute(
                  path: 'length',
                  builder: (_, _) => const LengthConvertorScreen(),
                ),
                GoRoute(
                  path: 'weight',
                  builder: (_, _) => const WeightConvertorScreen(),
                ),
                GoRoute(
                  path: 'pressure',
                  builder: (_, _) => const PressureConvertorScreen(),
                ),
                GoRoute(
                  path: 'temperature',
                  builder: (_, _) => const TemperatureConvertorScreen(),
                ),
                GoRoute(
                  path: 'mil-moa',
                  builder: (_, _) => const MilMoaConvertorScreen(),
                ),
                GoRoute(
                  path: 'torque',
                  builder: (_, _) => const TorqueConvertorScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Settings branch ──────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (_, _) => const SettingsScreen(),
              routes: [
                GoRoute(path: 'units', builder: (_, _) => const UnitsScreen()),
                GoRoute(
                  path: 'adjustment',
                  builder: (_, _) => const AdjustmentDisplayScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

// ─── Shell with persistent bottom nav ────────────────────────────────────────

class _ScaffoldWithNav extends ConsumerStatefulWidget {
  const _ScaffoldWithNav({required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<_ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends ConsumerState<_ScaffoldWithNav> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(recalcCoordinatorProvider.notifier)
          .onTabActivated(widget.shell.currentIndex);
    });
  }

  void _onTabSelected(int i) {
    widget.shell.goBranch(i, initialLocation: true);
    ref.read(recalcCoordinatorProvider.notifier).onTabActivated(i);
  }

  @override
  Widget build(BuildContext context) {
    // Initialise the coordinator — it sets up its own listeners.
    ref.watch(recalcCoordinatorProvider);

    return Scaffold(
      body: SafeArea(child: widget.shell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.thunderstorm_outlined),
            label: 'Conditions',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_view_outlined),
            label: 'Tables',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            label: 'Convertors',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
