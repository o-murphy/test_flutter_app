// Unit tests for RecalcCoordinator (Phase 3).
//
// No FFI required — uses only Riverpod container with provider overrides.
//   flutter test test/recalc_coordinator_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eballistica/core/providers/recalc_coordinator.dart';
import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/projectile.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/models/sight.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/features/home/home_vm.dart';
import 'package:eballistica/features/home/shot_details_vm.dart';
import 'package:eballistica/features/tables/trajectory_tables_vm.dart';

// ── Fixtures ────────────────────────────────────────────────────────────────

ShotProfile _makeProfile() {
  final projectile = Projectile(
    name: 'Test 175gr',
    dragType: DragModelType.g7,
    weight: Weight(175, Unit.grain),
    diameter: Distance(7.62, Unit.millimeter),
    length: Distance(31.0, Unit.millimeter),
    coefRows: [CoeficientRow(bcCd: 0.475, mv: 0.0)],
  );
  final cartridge = Cartridge(
    name: 'Test .308',
    projectile: projectile,
    mv: Velocity(800, Unit.mps),
    powderTemp: Temperature(15.0, Unit.celsius),
    powderSensitivity: Ratio(1.0, Unit.fraction),
    usePowderSensitivity: true,
  );
  final rifle = Rifle(
    name: 'Test Rifle',
    sightHeight: Distance(38.0, Unit.millimeter),
    twist: Distance(11.0, Unit.inch),
  );
  final sight = Sight(
    name: 'Test Scope',
    sightHeight: Distance(38.0, Unit.millimeter),
    zeroElevation: Angular(0, Unit.radian),
  );
  return ShotProfile(
    name: 'Test Shot',
    rifle: rifle,
    sight: sight,
    cartridge: cartridge,
    conditions: AtmoData(
      temperature: Temperature(20.0, Unit.celsius),
      altitude: Distance(150.0, Unit.meter),
      pressure: Pressure(1013.25, Unit.hPa),
      humidity: 0.50,
      powderTemp: Temperature(20.0, Unit.celsius),
    ),
    lookAngle: Angular(0, Unit.degree),
  );
}

// ── Fake notifiers that track calls ────────────────────────────────────────

class _TrackingHomeVM extends HomeViewModel {
  int recalcCount = 0;

  @override
  Future<HomeUiState> build() async => const HomeUiLoading();

  @override
  Future<void> recalculate() async {
    recalcCount++;
  }
}

class _TrackingShotDetailsVM extends ShotDetailsViewModel {
  int recalcCount = 0;

  @override
  Future<ShotDetailsUiState> build() async => const ShotDetailsLoading();

  @override
  Future<void> recalculate() async {
    recalcCount++;
  }
}

class _TrackingTablesVM extends TrajectoryTablesViewModel {
  int recalcCount = 0;

  @override
  Future<TrajectoryTablesUiState> build() async =>
      const TrajectoryTablesUiLoading();

  @override
  Future<void> recalculate() async {
    recalcCount++;
  }
}

/// Profile notifier that can push new values.
class _ControllableProfileNotifier extends ShotProfileNotifier {
  final ShotProfile _initial;
  _ControllableProfileNotifier(this._initial);

  @override
  Future<ShotProfile> build() async => _initial;

  void push(ShotProfile p) => state = AsyncData(p);
}

/// Settings notifier that can push new values.
class _ControllableSettingsNotifier extends SettingsNotifier {
  final AppSettings _initial;
  _ControllableSettingsNotifier(this._initial);

  @override
  Future<AppSettings> build() async => _initial;

  void push(AppSettings s) => state = AsyncData(s);
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _TestContext {
  final ProviderContainer container;
  final _TrackingHomeVM homeVM;
  final _TrackingTablesVM tablesVM;
  final _TrackingShotDetailsVM shotDetailsVM;
  final _ControllableProfileNotifier profileNotifier;
  final _ControllableSettingsNotifier settingsNotifier;

  _TestContext({
    required this.container,
    required this.homeVM,
    required this.tablesVM,
    required this.shotDetailsVM,
    required this.profileNotifier,
    required this.settingsNotifier,
  });
}

_TestContext _createTestContext({
  AppSettings initialSettings = const AppSettings(),
}) {
  final homeVM = _TrackingHomeVM();
  final tablesVM = _TrackingTablesVM();
  final shotDetailsVM = _TrackingShotDetailsVM();
  final profileNotifier = _ControllableProfileNotifier(_makeProfile());
  final settingsNotifier = _ControllableSettingsNotifier(initialSettings);

  final container = ProviderContainer(
    overrides: [
      shotProfileProvider.overrideWith(() => profileNotifier),
      settingsProvider.overrideWith(() => settingsNotifier),
      homeVmProvider.overrideWith(() => homeVM),
      trajectoryTablesVmProvider.overrideWith(() => tablesVM),
      shotDetailsVmProvider.overrideWith(() => shotDetailsVM),
    ],
  );

  return _TestContext(
    container: container,
    homeVM: homeVM,
    tablesVM: tablesVM,
    shotDetailsVM: shotDetailsVM,
    profileNotifier: profileNotifier,
    settingsNotifier: settingsNotifier,
  );
}

/// Initialise async providers and the coordinator.
Future<void> _initCoordinator(_TestContext ctx) async {
  await ctx.container.read(shotProfileProvider.future);
  await ctx.container.read(settingsProvider.future);
  await Future<void>.delayed(Duration.zero);
  // Reading the coordinator triggers its build() which sets up listeners
  ctx.container.read(recalcCoordinatorProvider);
  await Future<void>.delayed(Duration.zero);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('RecalcCoordinator — onTabActivated', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    }); // Removed the extra closing brace here.

    tearDown(() => ctx.container.dispose());

    test('tab 0 (Home) triggers home and shot details VMs', () {
      ctx.container.read(recalcCoordinatorProvider.notifier).onTabActivated(0);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 0);
    });

    test('tab 2 (Tables) triggers tablesVM only', () {
      ctx.container.read(recalcCoordinatorProvider.notifier).onTabActivated(2);

      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.homeVM.recalcCount, 0);
      expect(ctx.shotDetailsVM.recalcCount, 0);
    });

    test('tab 1 (Conditions) triggers nothing', () {
      ctx.container.read(recalcCoordinatorProvider.notifier).onTabActivated(1);

      expect(ctx.homeVM.recalcCount, 0);
      expect(ctx.tablesVM.recalcCount, 0);
      expect(ctx.shotDetailsVM.recalcCount, 0);
    });

    test('tab 3 (Convertors) triggers nothing', () {
      ctx.container.read(recalcCoordinatorProvider.notifier).onTabActivated(3);

      expect(ctx.homeVM.recalcCount, 0);
      expect(ctx.tablesVM.recalcCount, 0);
      expect(ctx.shotDetailsVM.recalcCount, 0);
    });

    test('tab 4 (Settings) triggers nothing', () {
      ctx.container.read(recalcCoordinatorProvider.notifier).onTabActivated(4);

      expect(ctx.homeVM.recalcCount, 0);
      expect(ctx.tablesVM.recalcCount, 0);
      expect(ctx.shotDetailsVM.recalcCount, 0);
    });
  });

  group('RecalcCoordinator — shotProfile changes', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    });

    tearDown(() => ctx.container.dispose());

    test('profile change triggers all providers', () async {
      final newProfile = _makeProfile();
      ctx.profileNotifier.push(newProfile);
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });

    test('multiple profile changes trigger multiple times', () async {
      ctx.profileNotifier.push(_makeProfile());
      await Future<void>.delayed(Duration.zero);
      ctx.profileNotifier.push(_makeProfile());
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 2);
      expect(ctx.tablesVM.recalcCount, 2);
      expect(ctx.shotDetailsVM.recalcCount, 2);
    }); // Removed the extra closing brace here.
  });

  group('RecalcCoordinator — settings changes that trigger recalc', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    });

    tearDown(() => ctx.container.dispose());

    test('profile usePowderSensitivity change triggers recalc', () async {
      ctx.profileNotifier.push(
        _makeProfile().copyWith(usePowderSensitivity: true),
      );
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });

    test('profile useDiffPowderTemp change triggers recalc', () async {
      ctx.profileNotifier.push(
        _makeProfile().copyWith(useDiffPowderTemp: true),
      );
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });

    test('chartDistanceStep change triggers recalc', () async {
      ctx.settingsNotifier.push(const AppSettings(chartDistanceStep: 50.0));
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });

    test('tableConfig.stepM change triggers recalc', () async {
      ctx.settingsNotifier.push(
        const AppSettings(tableConfig: TableConfig(stepM: 50.0)),
      );
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });
  });

  group('RecalcCoordinator — unit display toggles trigger recalc', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    });

    tearDown(() => ctx.container.dispose());

    test('showMrad change triggers recalc', () async {
      ctx.settingsNotifier.push(const AppSettings(showMrad: false));
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });

    test('showMoa change triggers recalc', () async {
      ctx.settingsNotifier.push(const AppSettings(showMoa: true));
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });
  });

  group('RecalcCoordinator — combined scenarios', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    });

    tearDown(() => ctx.container.dispose());

    test('profile change + tab activation accumulates calls', () async {
      ctx.profileNotifier.push(_makeProfile());
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);

      ctx.container.read(recalcCoordinatorProvider.notifier).onTabActivated(0);

      expect(ctx.homeVM.recalcCount, 2);
      expect(ctx.shotDetailsVM.recalcCount, 2);
    });

    test('settings change with multiple relevant fields triggers once', () async {
      // Even though multiple fields differ, it's a single push → single trigger
      ctx.settingsNotifier.push(
        const AppSettings(
          chartDistanceStep: 50.0,
          tableConfig: TableConfig(stepM: 50.0),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });
  });
}
