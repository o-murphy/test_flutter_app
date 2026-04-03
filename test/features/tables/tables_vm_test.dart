// Unit tests for TablesViewModel (Phase 2).
//
// No FFI required — uses a fake BallisticsService with provider overrides.
//   flutter test test/viewmodels/tables_vm_test.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eballistica/core/domain/ballistics_service.dart';
import 'package:eballistica/core/providers/service_providers.dart';
import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/projectile.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/models/sight.dart';
import 'package:eballistica/core/models/unit_settings.dart';
import 'package:eballistica/core/solver/trajectory_data.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/features/tables/trajectory_tables_vm.dart';
import 'package:eballistica/features/tables/details_table_mv.dart';

// ── Fixtures ────────────────────────────────────────────────────────────────

ShotProfile _makeProfile({double windMps = 3.0, double windDeg = 90.0}) {
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
    zeroUsePowderSensitivity: true,
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
    winds: [
      WindData(
        velocity: Velocity(windMps, Unit.mps),
        directionFrom: Angular(windDeg, Unit.degree),
        untilDistance: Distance(9999.0, Unit.meter),
      ),
    ],
    lookAngle: Angular(0, Unit.degree),
    targetDistance: Distance(300.0, Unit.meter),
  );
}

/// Creates trajectory data spanning 0–2000m with 1m step.
List<TrajectoryData> _makeTraj({
  double startM = 0,
  double endM = 2000,
  double stepM = 1.0,
}) {
  final result = <TrajectoryData>[];
  for (var d = startM; d <= endM; d += stepM) {
    final t = d / 800.0;
    final vFps = 2625.0 - d * 0.8;
    final hFt = -(d * d * 0.00003);
    final m = vFps / 1116.0;
    int flag = 0;
    if ((d - 100).abs() < 0.5) flag = TrajFlag.zeroUp.value;
    if ((d - 300).abs() < 0.5) flag = TrajFlag.zeroDown.value;

    result.add(
      TrajectoryData(
        time: t,
        distance: Distance(d * 3.28084, Unit.foot),
        velocity: Velocity(vFps, Unit.fps),
        mach: m,
        height: Distance(hFt, Unit.foot),
        slantHeight: Distance(hFt, Unit.foot),
        dropAngle: Angular(d > 0 ? hFt / (d * 3.28084) * 1000 : 0, Unit.mil),
        windage: Distance(d * 0.0005, Unit.foot),
        windageAngle: Angular(
          d > 0 ? (d * 0.0005) / (d * 3.28084) * 1000 : 0,
          Unit.mil,
        ),
        slantDistance: Distance(d * 3.28084, Unit.foot),
        angle: Angular(0, Unit.mil),
        densityRatio: 1.0,
        drag: 0.3,
        energy: Energy(3000 - d * 1.2, Unit.footPound),
        ogw: Weight(500, Unit.grain),
        flag: flag,
      ),
    );
  }
  return result;
}

BallisticsResult _makeResult() {
  final profile = _makeProfile();
  final shot = profile.toShot();
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
    TargetCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    callCount++;
    return result;
  }

  @override
  Future<BallisticsResult> calculateTable(
    ShotProfile profile,
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

ProviderContainer _createContainer({
  required ShotProfile profile,
  required _FakeBallisticsService service,
  AppSettings settings = const AppSettings(),
}) {
  return ProviderContainer(
    overrides: [
      shotProfileProvider.overrideWith(() => _FakeProfileNotifier(profile)),
      settingsProvider.overrideWith(() => _FakeSettingsNotifier(settings)),
      ballisticsServiceProvider.overrideWithValue(service),
    ],
  );
}

Future<TrajectoryTablesUiReady> _recalculate(
  ProviderContainer container,
) async {
  await container.read(shotProfileProvider.future);
  await container.read(settingsProvider.future);
  await Future<void>.delayed(Duration.zero);
  final notifier = container.read(trajectoryTablesVmProvider.notifier);
  await notifier.recalculate();
  final state = container.read(trajectoryTablesVmProvider).value;
  return state as TrajectoryTablesUiReady;
}

// ── Helper to get details from provider ─────────────────────────────────────

DetailsTableData? _getDetails(ProviderContainer container) {
  return container.read(detailsTableMvProvider);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('TablesViewModel — basic ready state', () {
    late ProviderContainer container;
    late _FakeBallisticsService service;
    late TrajectoryTablesUiReady state;
    late DetailsTableData? details;

    setUp(() async {
      service = _FakeBallisticsService(_makeResult());
      container = _createContainer(profile: _makeProfile(), service: service);
      state = await _recalculate(container);
      details = _getDetails(container);
    });

    tearDown(() => container.dispose());

    test('spoiler has rifle name', () {
      expect(details?.rifleName, 'Test Rifle');
    });

    test('spoiler shows caliber', () {
      expect(details?.caliber, isNotNull);
    });

    test('spoiler shows twist', () {
      expect(details?.twist, isNotNull);
      expect(details?.twist, contains('1:'));
    });

    test('spoiler shows drag model', () {
      expect(details?.dragModel, 'G7');
    });

    test('spoiler shows BC', () {
      expect(details?.bc, isNotNull);
      expect(details?.bc, contains('0.475'));
    });

    test('spoiler shows zero MV', () {
      expect(details?.zeroMv, isNotNull);
      expect(details?.zeroMv, contains('m/s'));
    });

    test('spoiler shows current MV', () {
      expect(details?.currentMv, isNotNull);
    });

    test('spoiler shows zero distance', () {
      expect(details?.zeroDist, isNotNull);
      expect(details?.zeroDist, contains('m'));
    });

    test('spoiler shows temperature', () {
      expect(details?.temperature, isNotNull);
      expect(details?.temperature, contains('°C'));
    });

    test('spoiler shows humidity', () {
      expect(details?.humidity, isNotNull);
      expect(details?.humidity, contains('%'));
    });

    test('spoiler shows pressure', () {
      expect(details?.pressure, isNotNull);
      expect(details?.pressure, contains('hPa'));
    });

    test('spoiler shows wind speed', () {
      expect(details?.windSpeed, isNotNull);
    });

    test('spoiler shows wind direction', () {
      expect(details?.windDir, isNotNull);
      expect(details?.windDir, contains('90'));
    });

    test('main table has distance headers', () {
      expect(state.mainTable.distanceHeaders, isNotEmpty);
    });

    test('main table has rows', () {
      expect(state.mainTable.rows, isNotEmpty);
    });

    test('main table distance unit is set', () {
      expect(state.mainTable.distanceUnit, isNotEmpty);
    });

    test('ballistics service was called once', () {
      expect(service.callCount, 1);
    });
  });

  group('TablesViewModel — zero crossings', () {
    late ProviderContainer container;
    late TrajectoryTablesUiReady state;

    setUp(() async {
      final service = _FakeBallisticsService(_makeResult());
      container = _createContainer(
        profile: _makeProfile(),
        service: service,
        settings: const AppSettings(tableConfig: TableConfig(showZeros: true)),
      );
      state = await _recalculate(container);
    });

    tearDown(() => container.dispose());

    test('zero crossings table is present', () {
      expect(state.zeroCrossings, isNotNull);
    });

    test('zero crossings have arrow indicators', () {
      final headers = state.zeroCrossings!.distanceHeaders;
      final hasArrow = headers.any((h) => h.contains('↑') || h.contains('↓'));
      expect(hasArrow, isTrue);
    });
  });

  group('TablesViewModel — hidden columns', () {
    test('hiding columns reduces row count', () async {
      final service = _FakeBallisticsService(_makeResult());
      final containerAll = _createContainer(
        profile: _makeProfile(),
        service: service,
      );
      addTearDown(containerAll.dispose);
      final stateAll = await _recalculate(containerAll);

      final service2 = _FakeBallisticsService(_makeResult());
      final containerHidden = _createContainer(
        profile: _makeProfile(),
        service: service2,
        settings: const AppSettings(
          tableConfig: TableConfig(
            hiddenCols: {'time', 'velocity', 'mach', 'energy'},
          ),
        ),
      );
      addTearDown(containerHidden.dispose);
      final stateHidden = await _recalculate(containerHidden);

      expect(
        stateHidden.mainTable.rows.length,
        lessThan(stateAll.mainTable.rows.length),
      );
    });
  });

  group('TablesViewModel — imperial units', () {
    late ProviderContainer container;
    late TrajectoryTablesUiReady state;
    late DetailsTableData? details;

    setUp(() async {
      const imperial = AppSettings(
        units: UnitSettings(
          temperature: Unit.fahrenheit,
          distance: Unit.yard,
          velocity: Unit.fps,
          pressure: Unit.mmHg,
          drop: Unit.inch,
          adjustment: Unit.moa,
          energy: Unit.footPound,
        ),
      );
      final service = _FakeBallisticsService(_makeResult());
      container = _createContainer(
        profile: _makeProfile(),
        service: service,
        settings: imperial,
      );
      state = await _recalculate(container);
      details = _getDetails(container);
    });

    tearDown(() => container.dispose());

    test('spoiler shows imperial temperature', () {
      expect(details?.temperature, isNotNull);
      expect(details?.temperature, contains('°F'));
    });

    test('spoiler shows imperial pressure', () {
      expect(details?.pressure, isNotNull);
      expect(details?.pressure, contains('mmHg'));
    });

    test('main table distance unit is yd', () {
      expect(state.mainTable.distanceUnit, contains('yd'));
    });
  });

  group('TablesViewModel — empty state', () {
    test('returns empty when profile is null', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = ProviderContainer(
        overrides: [
          shotProfileProvider.overrideWith(() => _PendingProfileNotifier()),
          settingsProvider.overrideWith(
            () => _FakeSettingsNotifier(const AppSettings()),
          ),
          ballisticsServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      await container.read(trajectoryTablesVmProvider.future);
      await container.read(settingsProvider.future);
      await Future<void>.delayed(Duration.zero);
      final notifier = container.read(trajectoryTablesVmProvider.notifier);
      await notifier.recalculate();
      final state = container.read(trajectoryTablesVmProvider).value;
      expect(state, isA<TrajectoryTablesUiEmpty>());
    });
  });

  group('TablesViewModel — error handling', () {
    test('returns error state on service failure', () async {
      final container = ProviderContainer(
        overrides: [
          shotProfileProvider.overrideWith(
            () => _FakeProfileNotifier(_makeProfile()),
          ),
          settingsProvider.overrideWith(
            () => _FakeSettingsNotifier(const AppSettings()),
          ),
          ballisticsServiceProvider.overrideWithValue(
            _ThrowingBallisticsService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(shotProfileProvider.future);
      await container.read(settingsProvider.future);
      await Future<void>.delayed(Duration.zero);

      final notifier = container.read(trajectoryTablesVmProvider.notifier);
      await notifier.recalculate();
      final state = container.read(trajectoryTablesVmProvider).value;
      expect(state, isA<TrajectoryTablesUiError>());
      expect((state as TrajectoryTablesUiError).message, contains('Boom'));
    });
  });

  group('TablesViewModel — initial state', () {
    test('starts with loading state', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = _createContainer(
        profile: _makeProfile(),
        service: service,
      );
      addTearDown(container.dispose);

      await container.read(trajectoryTablesVmProvider.future);
      final state = container.read(trajectoryTablesVmProvider).value;
      expect(state, isA<TrajectoryTablesUiLoading>());
    });
  });

  group('TablesViewModel — zero caching', () {
    test('second recalculate reuses cached zero elevation', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = _createContainer(
        profile: _makeProfile(),
        service: service,
      );
      addTearDown(container.dispose);

      await _recalculate(container);
      expect(service.callCount, 1);

      await _recalculate(container);
      expect(service.callCount, 2);
    });
  });
}

/// Profile notifier that never completes — simulates "still loading" state.
class _PendingProfileNotifier extends ShotProfileNotifier {
  @override
  Future<ShotProfile> build() => Completer<ShotProfile>().future;
}

class _ThrowingBallisticsService implements BallisticsService {
  @override
  Future<BallisticsResult> calculateForTarget(
    ShotProfile profile,
    TargetCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    throw Exception('Boom');
  }

  @override
  Future<BallisticsResult> calculateTable(
    ShotProfile profile,
    TableCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    throw Exception('Boom');
  }
}
