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

  // Home stack — shot info
  static const shotDetails = '/home/shot-details';

  // Profile (profiles) stack
  static const profiles = '/home/profiles';

  // Profile add → rifle selection
  static const profileAdd = '/home/profiles/profile-add';
  static const profileAddRifleCreate =
      '/home/profiles/profile-add/rifle-create';
  static const profileAddRifleCollection =
      '/home/profiles/profile-add/rifle-collection';

  // Cartridge select (from profile card)
  static const cartridgeSelect = '/home/profiles/cartridge-select';
  static const cartridgeCreate = '/home/profiles/cartridge-select/create';
  static const cartridgeCollection =
      '/home/profiles/cartridge-select/collection';

  // Projectile select (future — nested under cartridge)
  static const projectileSelect =
      '/home/profiles/cartridge-select/projectile-select';
  static const projectileCreate =
      '/home/profiles/cartridge-select/projectile-select/create';
  static const projectileCollection =
      '/home/profiles/cartridge-select/projectile-select/collection';

  // Sight select (from profile card)
  static const sightSelect = '/home/profiles/sight-select';
  static const sightCreate = '/home/profiles/sight-select/create';
  static const sightCollection = '/home/profiles/sight-select/collection';

  // Profile inline edits (from profile card)
  static const profileEditRifle = '/home/profiles/rifle-edit';
  static const profileEditCartridge = '/home/profiles/cartridge-edit';
  static const profileEditSight = '/home/profiles/sight-edit';

  // Tables stack
  static const tableConfig = '/tables/configure';

  // Convertors stack
  static const convertor = '/convertors/:type';
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
                  path: 'shot-details',
                  builder: (_, _) => const ShotDetailsScreen(),
                ),
                GoRoute(
                  path: 'profiles',
                  builder: (_, _) => const ProfilesScreen(),
                  routes: [
                    // ── Profile add ─────────────────────────────────────────
                    GoRoute(
                      path: 'profile-add',
                      builder: (_, _) => const ProfileAddScreen(),
                      routes: [
                        GoRoute(
                          path: 'rifle-create',
                          builder: (_, _) => const CreateRifleWizardScreen(),
                        ),
                        GoRoute(
                          path: 'rifle-collection',
                          builder: (_, _) =>
                              const SelectRifleCollectionScreen(),
                        ),
                      ],
                    ),
                    // ── Cartridge select ────────────────────────────────────
                    GoRoute(
                      path: 'cartridge-select',
                      builder: (_, _) => const CartridgeSelectScreen(),
                      routes: [
                        GoRoute(
                          path: 'create',
                          builder: (_, _) =>
                              const CreateCartridgeWizardScreen(),
                        ),
                        GoRoute(
                          path: 'collection',
                          builder: (_, _) =>
                              const SelectCartridgeCollectionScreen(),
                        ),
                        // future: projectile nested under cartridge
                        GoRoute(
                          path: 'projectile-select',
                          builder: (_, _) => const ProjectileSelectScreen(),
                          routes: [
                            GoRoute(
                              path: 'create',
                              builder: (_, _) =>
                                  const CreateProjectileWizardScreen(),
                            ),
                            GoRoute(
                              path: 'collection',
                              builder: (_, _) =>
                                  const SelectProjectileCollectionScreen(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // ── Sight select ────────────────────────────────────────
                    GoRoute(
                      path: 'sight-select',
                      builder: (_, _) => const SightSelectScreen(),
                      routes: [
                        GoRoute(
                          path: 'create',
                          builder: (_, _) => const CreateSightWizardScreen(),
                        ),
                        GoRoute(
                          path: 'collection',
                          builder: (_, _) =>
                              const SelectSightCollectionScreen(),
                        ),
                      ],
                    ),
                    // ── Profile inline edits ────────────────────────────────
                    GoRoute(
                      path: 'rifle-edit',
                      builder: (_, _) => const RifleEditScreen(),
                    ),
                    GoRoute(
                      path: 'cartridge-edit',
                      builder: (_, _) => const CartridgeEditScreen(),
                    ),
                    GoRoute(
                      path: 'sight-edit',
                      builder: (_, _) => const SightEditScreen(),
                    ),
                  ],
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
