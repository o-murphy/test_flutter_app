import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/calculation_provider.dart';
import 'providers/shot_profile_provider.dart';

import 'screens/home_screen.dart';
import 'screens/home_sub_screens.dart';
import 'screens/conditions_screen.dart';
import 'screens/tables_screen.dart';
import 'screens/tables_sub_screens.dart';
import 'screens/convertor_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/settings_sub_screens.dart';

// ─── Route paths ─────────────────────────────────────────────────────────────

abstract final class Routes {
  // Primary
  static const home              = '/home';
  static const conditions        = '/conditions';
  static const tables            = '/tables';
  static const convertors        = '/convertors';
  static const settings          = '/settings';

  // Home stack
  static const rifleSelect       = '/home/rifle-select';
  static const rifleEdit         = '/home/rifle-select/rifle-edit';
  static const sightSelect       = '/home/rifle-select/sight-select';
  static const cartridge         = '/home/rifle-select/cartridge';
  static const cartridgeEdit     = '/home/rifle-select/cartridge/edit';
  static const projectileSelect  = '/home/projectile-select';
  static const projectileEdit    = '/home/projectile-select/edit';
  static const shotDetails       = '/home/shot-details';

  // Tables stack
  static const tableConfig       = '/tables/configure';

  // Convertors stack
  static const convertor         = '/convertors/:type';  // push individual convertor
  static String convertorOf(String type) => '/convertors/$type';

  // Settings stack
  static const settingsUnits       = '/settings/units';
  static const settingsAdjustment  = '/settings/adjustment';
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
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.home,
            builder: (_, _) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'rifle-select',
                builder: (_, _) => const RifleSelectScreen(),
                routes: [
                  GoRoute(path: 'rifle-edit',   builder: (_, _) => const RifleEditScreen()),
                  GoRoute(path: 'sight-select',  builder: (_, _) => const SightSelectScreen()),
                  GoRoute(
                    path: 'cartridge',
                    builder: (_, _) => const CartridgeScreen(),
                    routes: [
                      GoRoute(path: 'edit', builder: (_, _) => const CartridgeEditScreen()),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'projectile-select',
                builder: (_, _) => const ProjectileSelectScreen(),
                routes: [
                  GoRoute(path: 'edit', builder: (_, _) => const ProjectileEditScreen()),
                ],
              ),
              GoRoute(path: 'shot-details', builder: (_, _) => const ShotDetailsScreen()),
            ],
          ),
        ]),

        // ── Conditions branch ────────────────────────────────────────────────
        StatefulShellBranch(routes: [
          GoRoute(path: Routes.conditions, builder: (_, _) => const ConditionsScreen()),
        ]),

        // ── Tables branch ────────────────────────────────────────────────────
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.tables,
            builder: (_, _) => const TablesScreen(),
            routes: [
              GoRoute(path: 'configure', builder: (_, _) => const TableConfigScreen()),
            ],
          ),
        ]),

        // ── Convertors branch ────────────────────────────────────────────────
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.convertors,
            builder: (_, _) => const ConvertorScreen(),
            routes: [
              GoRoute(
                path: ':type',
                builder: (_, state) => ConvertorScreen(key: ValueKey(state.pathParameters['type'])),
              ),
            ],
          ),
        ]),

        // ── Settings branch ──────────────────────────────────────────────────
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.settings,
            builder: (_, _) => const SettingsScreen(),
            routes: [
              GoRoute(path: 'units',       builder: (_, _) => const UnitsScreen()),
              GoRoute(path: 'adjustment',  builder: (_, _) => const AdjustmentDisplayScreen()),
            ],
          ),
        ]),

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
  // Tabs 0 (Home) and 2 (Tables) trigger recalculation.
  static const _calcTabs = {0, 2};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerCalcIfNeeded(widget.shell.currentIndex));
  }

  void _triggerCalcIfNeeded(int i) {
    if (_calcTabs.contains(i)) {
      ref.read(calculationProvider.notifier).recalculateIfNeeded();
    }
  }

  void _onTabSelected(int i) {
    // Always go to the root of the branch — prevents sub-screens from persisting
    // across tab switches. Tapping the current tab also resets to root.
    widget.shell.goBranch(i, initialLocation: true);
    _triggerCalcIfNeeded(i);
  }

  @override
  Widget build(BuildContext context) {
    // Mark calculation dirty whenever the shot profile changes.
    // Done here (not inside CalculationNotifier.build) to avoid
    // accidentally re-running the notifier's build and resetting state.
    ref.listen(shotProfileProvider, (_, next) {
      if (next.hasValue) {
        final notifier = ref.read(calculationProvider.notifier);
        notifier.markDirty();
        if (_calcTabs.contains(widget.shell.currentIndex)) {
          notifier.recalculateIfNeeded();
        }
      }
    });

    return Scaffold(
      body: SafeArea(child: widget.shell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),        label: 'Home'),
          NavigationDestination(icon: Icon(Icons.thunderstorm_outlined), label: 'Conditions'),
          NavigationDestination(icon: Icon(Icons.table_view_outlined),   label: 'Tables'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined),    label: 'Convertors'),
          NavigationDestination(icon: Icon(Icons.settings_outlined),     label: 'Settings'),
        ],
      ),
    );
  }
}
