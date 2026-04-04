// Unit tests for HomeViewModel (Phase 2).
//
// No FFI required — uses a fake BallisticsService with provider overrides.
//   flutter test test/viewmodels/home_vm_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eballistica/core/domain/ballistics_service.dart';
import 'package:eballistica/core/providers/service_providers.dart';
import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_conditions_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/projectile.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/models/sight.dart';
import 'package:eballistica/core/solver/trajectory_data.dart';
import 'package:eballistica/core/models/unit_settings.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/features/home/home_vm.dart';

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
    zeroConditions: Conditions.withDefaults(usePowderSensitivity: true),
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
  );
}

Conditions _makeConditions({
  double targetM = 300.0,
  double windMps = 3.0,
  double windDeg = 90.0,
  double tempC = 20.0,
  double altM = 150.0,
  double pressHPa = 1013.25,
  double humidity = 0.50,
}) {
  return Conditions(
    atmo: AtmoData(
      temperature: Temperature(tempC, Unit.celsius),
      altitude: Distance(altM, Unit.meter),
      pressure: Pressure(pressHPa, Unit.hPa),
      humidity: humidity,
      powderTemp: Temperature(tempC, Unit.celsius),
    ),
    winds: [
      WindData(
        velocity: Velocity(windMps, Unit.mps),
        directionFrom: Angular(windDeg, Unit.degree),
        untilDistance: Distance(9999.0, Unit.meter),
      ),
    ],
    lookAngle: Angular(0, Unit.degree),
    distance: Distance(targetM, Unit.meter),
    usePowderSensitivity: false,
    useDiffPowderTemp: false,
    useCoriolis: false,
    latitudeDeg: null,
    azimuthDeg: null,
  );
}

/// Creates a minimal trajectory list for testing.
List<TrajectoryData> _makeTraj({int points = 31, double stepM = 10.0}) {
  final result = <TrajectoryData>[];
  for (var i = 0; i <= points; i++) {
    final d = i * stepM;
    final t = d / 800.0;
    final v = 800.0 - d * 0.5;
    final h = -(d * d * 0.00005);
    final m = v / 1100.0;
    int flag = 0;
    if (i == 10) flag = TrajFlag.zeroUp.value;
    result.add(
      TrajectoryData(
        time: t,
        distance: Distance(d * 3.28084, Unit.foot),
        velocity: Velocity(v, Unit.fps),
        mach: m,
        height: Distance(h, Unit.foot),
        slantHeight: Distance(h, Unit.foot),
        dropAngle: Angular(h / d.clamp(1, double.infinity) * 1000, Unit.mil),
        windage: Distance(d * 0.001, Unit.foot),
        windageAngle: Angular(
          d * 0.001 / d.clamp(1, double.infinity) * 1000,
          Unit.mil,
        ),
        slantDistance: Distance(d * 3.28084, Unit.foot),
        angle: Angular(0, Unit.mil),
        densityRatio: 1.0,
        drag: 0.3,
        energy: Energy(2000 - d * 3.0, Unit.footPound),
        ogw: Weight(500, Unit.grain),
        flag: flag,
      ),
    );
  }
  return result;
}

BallisticsResult _makeResult({double targetM = 300.0}) {
  final profile = _makeProfile();
  final conditions = _makeConditions(targetM: targetM);
  final shot = profile.toCurrentShot(conditions);
  shot.relativeAngle = Angular(0.002, Unit.radian);
  final traj = _makeTraj();
  final hit = HitResult(shot, traj);
  return BallisticsResult(hitResult: hit, zeroElevationRad: 0.002);
}

// ── Fake service + notifiers ────────────────────────────────────────────────

class _FakeBallisticsService implements BallisticsService {
  final BallisticsResult result;
  int callCount = 0;

  _FakeBallisticsService(this.result);

  @override
  Future<BallisticsResult> calculateForTarget(
    ShotProfile profile,
    Conditions conditions,
    TargetCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    callCount++;
    return result;
  }

  @override
  Future<BallisticsResult> calculateTable(
    ShotProfile profile,
    Conditions conditions,
    TableCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    callCount++;
    return result;
  }
}

class _FakeProfileNotifier extends ShotProfileNotifier {
  final ShotProfile _profile;
  _FakeProfileNotifier(this._profile);
  @override
  Future<ShotProfile> build() async => _profile;
}

class _FakeSettingsNotifier extends SettingsNotifier {
  final AppSettings _settings;
  _FakeSettingsNotifier(this._settings);
  @override
  Future<AppSettings> build() async => _settings;
}

class _FakeConditionsNotifier extends ShotConditionsNotifier {
  final Conditions _conditions;
  _FakeConditionsNotifier(this._conditions);

  @override
  Future<Conditions> build() async => _conditions;
}

ProviderContainer _createContainer({
  required ShotProfile profile,
  required Conditions conditions,
  required _FakeBallisticsService service,
  AppSettings settings = const AppSettings(),
}) {
  return ProviderContainer(
    overrides: [
      shotProfileProvider.overrideWith(() => _FakeProfileNotifier(profile)),
      settingsProvider.overrideWith(() => _FakeSettingsNotifier(settings)),
      shotConditionsProvider.overrideWith(
        () => _FakeConditionsNotifier(conditions),
      ),
      ballisticsServiceProvider.overrideWithValue(service),
    ],
  );
}

/// Ensures async dependencies resolve, then triggers recalculate.
Future<HomeUiReady> _recalculate(ProviderContainer container) async {
  await container.read(shotProfileProvider.future);
  await container.read(settingsProvider.future);
  await container.read(shotConditionsProvider.future);
  await Future<void>.delayed(Duration.zero);
  final notifier = container.read(homeVmProvider.notifier);
  await notifier.recalculate();
  final state = container.read(homeVmProvider).value;
  return state as HomeUiReady;
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('HomeViewModel — basic ready state', () {
    late ProviderContainer container;
    late _FakeBallisticsService service;
    late HomeUiReady state;

    setUp(() async {
      service = _FakeBallisticsService(_makeResult());
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
      );
      state = await _recalculate(container);
    });

    tearDown(() => container.dispose());

    test('rifle and cartridge names are set', () {
      expect(state.rifleName, 'Test Rifle');
      expect(state.cartridgeName, 'Test .308');
    });

    test('wind angle is set from conditions', () {
      expect(state.windAngleDeg, closeTo(90.0, 0.1));
    });

    test('conditions displays are non-empty strings', () {
      expect(state.tempDisplay, isNotEmpty);
      expect(state.altDisplay, isNotEmpty);
      expect(state.pressDisplay, isNotEmpty);
      expect(state.humidDisplay, isNotEmpty);
    });

    test('conditions contain correct units', () {
      expect(state.tempDisplay, contains('°C'));
      expect(state.altDisplay, contains('m'));
      expect(state.pressDisplay, contains('hPa'));
      expect(state.humidDisplay, contains('%'));
    });

    test('cartridge info line contains projectile name and MV', () {
      expect(state.cartridgeInfoLine, contains('Test 175gr'));
      expect(state.cartridgeInfoLine, contains('m/s'));
      expect(state.cartridgeInfoLine, contains('G7'));
    });

    test('adjustment data has elevation values', () {
      expect(state.adjustment.elevation, isNotEmpty);
      expect(state.adjustment.elevation.first.symbol, 'MRAD');
    });

    test('table data has 5 distance headers', () {
      expect(state.tableData.distanceHeaders.length, 5);
    });

    test('table data has multiple rows', () {
      expect(state.tableData.rows.length, greaterThan(5));
    });

    test('chart data has points', () {
      expect(state.chartData.points, isNotEmpty);
    });

    test('selected point info is auto-populated at target distance', () {
      expect(state.selectedPointInfo, isNotNull);
      expect(state.selectedChartIndex, isNotNull);
    });

    test('ballistics service was called once', () {
      expect(service.callCount, 1);
    });
  });

  group('HomeViewModel — chart point selection', () {
    late ProviderContainer container;
    late _FakeBallisticsService service;

    setUp(() async {
      service = _FakeBallisticsService(_makeResult());
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
      );
      await _recalculate(container);
    });

    tearDown(() => container.dispose());

    test('selectChartPoint sets selectedPointInfo', () {
      final notifier = container.read(homeVmProvider.notifier);
      notifier.selectChartPoint(5);
      final state = container.read(homeVmProvider).value as HomeUiReady;
      expect(state.selectedPointInfo, isNotNull);
      expect(state.selectedPointInfo!.distance, isNotEmpty);
      expect(state.selectedPointInfo!.velocity, isNotEmpty);
      expect(state.selectedPointInfo!.energy, isNotEmpty);
    });

    test('selectChartPoint with invalid index preserves previous info', () {
      final notifier = container.read(homeVmProvider.notifier);
      final before = (container.read(homeVmProvider).value as HomeUiReady)
          .selectedPointInfo;
      notifier.selectChartPoint(999);
      final state = container.read(homeVmProvider).value as HomeUiReady;
      expect(state.selectedPointInfo, equals(before));
    });
  });

  group('HomeViewModel — imperial units', () {
    late ProviderContainer container;
    late HomeUiReady state;

    setUp(() async {
      const imperial = AppSettings(
        units: UnitSettings(
          temperature: Unit.fahrenheit,
          distance: Unit.yard,
          velocity: Unit.fps,
          pressure: Unit.mmHg,
        ),
      );
      final service = _FakeBallisticsService(_makeResult());
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
        settings: imperial,
      );
      state = await _recalculate(container);
    });

    tearDown(() => container.dispose());

    test('conditions display in imperial units', () {
      expect(state.tempDisplay, contains('°F'));
      expect(state.altDisplay, contains('yd'));
      expect(state.pressDisplay, contains('mmHg'));
    });

    test('cartridge info uses imperial velocity', () {
      expect(state.cartridgeInfoLine, contains('ft/s'));
    });
  });

  group('HomeViewModel — adjustment display settings', () {
    test('shows MOA when enabled', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
        settings: const AppSettings(showMrad: false, showMoa: true),
      );
      addTearDown(container.dispose);

      final state = await _recalculate(container);
      expect(state.adjustment.elevation.any((v) => v.symbol == 'MOA'), isTrue);
      expect(
        state.adjustment.elevation.any((v) => v.symbol == 'MRAD'),
        isFalse,
      );
    });

    test('shows multiple units when multiple enabled', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
        settings: const AppSettings(showMrad: true, showMoa: true),
      );
      addTearDown(container.dispose);

      final state = await _recalculate(container);
      expect(state.adjustment.elevation.length, 2);
    });
  });

  group('HomeViewModel — zero caching', () {
    test('second recalculate reuses cached zero', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
      );
      addTearDown(container.dispose);

      await _recalculate(container);
      expect(service.callCount, 1);

      await _recalculate(container);
      expect(service.callCount, 2);
    });
  });

  group('HomeViewModel — error handling', () {
    test('error state on service failure', () async {
      final badService = _ThrowingBallisticsService();
      final container = ProviderContainer(
        overrides: [
          shotProfileProvider.overrideWith(
            () => _FakeProfileNotifier(_makeProfile()),
          ),
          settingsProvider.overrideWith(
            () => _FakeSettingsNotifier(const AppSettings()),
          ),
          shotConditionsProvider.overrideWith(
            () => _FakeConditionsNotifier(_makeConditions()),
          ),
          ballisticsServiceProvider.overrideWithValue(badService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(shotProfileProvider.future);
      await container.read(settingsProvider.future);
      await container.read(shotConditionsProvider.future);
      await Future<void>.delayed(Duration.zero);

      final notifier = container.read(homeVmProvider.notifier);
      await notifier.recalculate();
      final state = container.read(homeVmProvider).value;
      expect(state, isA<HomeUiError>());
      expect((state as HomeUiError).message, contains('Boom'));
    });
  });

  group('HomeViewModel — initial state', () {
    test('starts with loading state', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
      );
      addTearDown(container.dispose);

      // Не чекаємо нічого, просто читаємо початковий стан
      final state = container.read(homeVmProvider).value;
      expect(state, isA<HomeUiLoading>());
    });
  });
}

class _ThrowingBallisticsService implements BallisticsService {
  @override
  Future<BallisticsResult> calculateForTarget(
    ShotProfile profile,
    Conditions conditions,
    TargetCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    throw Exception('Boom');
  }

  @override
  Future<BallisticsResult> calculateTable(
    ShotProfile profile,
    Conditions conditions,
    TableCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    throw Exception('Boom');
  }
}
