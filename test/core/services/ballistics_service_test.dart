// Unit tests for BallisticsService (Phase 1).
//
// Requires the native FFI library to be built:
//   make native
//   dart test test/services/ballistics_service_test.dart

import 'package:test/test.dart';
import 'package:eballistica/core/domain/ballistics_service.dart';
import 'package:eballistica/core/services/ballistics_service_impl.dart';
import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/projectile.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/sight.dart';
import 'package:eballistica/core/solver/unit.dart';

// ── Test fixtures ────────────────────────────────────────────────────────────

/// Realistic .308 Win profile for testing.
ShotProfile _makeProfile({
  double mvMps = 800.0,
  double zeroDistM = 100.0,
  double targetDistM = 300.0,
  AtmoData? conditions,
  AtmoData? zeroConditions,
  List<WindData> winds = const [],
}) {
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
    mv: Velocity(mvMps, Unit.mps),
    powderTemp: Temperature(15.0, Unit.celsius),
    powderSensitivity: Ratio(0.0, Unit.fraction),
    zeroDistance: Distance(zeroDistM, Unit.meter),
    atmo: zeroConditions,
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
    cartridgeId: cartridge.id,
    cartridge: cartridge,
    sightId: sight.id,
    sight: sight,
    conditions:
        conditions ??
        AtmoData(
          altitude: Distance(0, Unit.meter),
          temperature: Temperature(15.0, Unit.celsius),
          pressure: Pressure(1013.25, Unit.hPa),
          humidity: 0.0,
          powderTemp: Temperature(15.0, Unit.celsius),
        ),
    winds: winds,
    lookAngle: Angular(0, Unit.degree),
    targetDistance: Distance(targetDistM, Unit.meter),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late BallisticsService service;

  setUp(() {
    service = BallisticsServiceImpl();
  });

  group('BallisticsService — calculateTable', () {
    test('returns non-empty trajectory for standard profile', () async {
      final profile = _makeProfile();
      final result = await service.calculateTable(
        profile,
        const TableCalcOptions(stepM: 100),
      );

      expect(result.hitResult.trajectory, isNotEmpty);
      expect(result.zeroElevationRad, isNot(0.0));
    });

    test('trajectory starts near zero distance', () async {
      final profile = _makeProfile();
      final result = await service.calculateTable(
        profile,
        const TableCalcOptions(stepM: 100),
      );

      final firstPoint = result.hitResult.trajectory.first;
      expect(firstPoint.distance.in_(Unit.meter), closeTo(0.0, 1.0));
    });

    test('trajectory extends to ~2000m', () async {
      final profile = _makeProfile();
      final result = await service.calculateTable(
        profile,
        const TableCalcOptions(stepM: 100),
      );

      final lastPoint = result.hitResult.trajectory.last;
      expect(lastPoint.distance.in_(Unit.meter), greaterThan(1900));
    });

    test('step size affects number of trajectory points', () async {
      final profile = _makeProfile();

      final fine = await service.calculateTable(
        profile,
        const TableCalcOptions(stepM: 1.0),
      );
      final coarse = await service.calculateTable(
        profile,
        const TableCalcOptions(stepM: 100.0),
      );

      expect(
        fine.hitResult.trajectory.length,
        greaterThan(coarse.hitResult.trajectory.length),
      );
    });

    test('cached zero elevation skips re-zeroing', () async {
      final profile = _makeProfile();

      // First call — computes zero elevation
      final first = await service.calculateTable(
        profile,
        const TableCalcOptions(stepM: 100),
      );

      // Second call — uses cached zero elevation
      final second = await service.calculateTable(
        profile,
        const TableCalcOptions(stepM: 100),
        cachedZeroElevRad: first.zeroElevationRad,
      );

      // Results should be equivalent
      expect(
        second.hitResult.trajectory.length,
        equals(first.hitResult.trajectory.length),
      );
      expect(second.zeroElevationRad, closeTo(first.zeroElevationRad, 1e-9));
    });

    test('velocity decreases along trajectory', () async {
      final profile = _makeProfile();
      final result = await service.calculateTable(
        profile,
        const TableCalcOptions(stepM: 100),
      );

      final traj = result.hitResult.trajectory;
      for (var i = 1; i < traj.length; i++) {
        expect(
          traj[i].velocity.in_(Unit.mps),
          lessThan(traj[i - 1].velocity.in_(Unit.mps)),
          reason: 'Velocity should decrease at point $i',
        );
      }
    });

    test('zero elevation is reasonable for 100m zero', () async {
      final profile = _makeProfile(zeroDistM: 100.0);
      final result = await service.calculateTable(
        profile,
        const TableCalcOptions(stepM: 100),
      );

      // Zero elevation should be a small positive angle (bullet rises to zero)
      final zeroElev = result.zeroElevationRad;
      expect(zeroElev, greaterThan(0.0));
      expect(zeroElev, lessThan(0.01)); // less than ~0.57 degrees
    });
  });

  group('BallisticsService — calculateForTarget', () {
    test('returns non-empty trajectory', () async {
      final profile = _makeProfile(targetDistM: 300.0);
      final result = await service.calculateForTarget(
        profile,
        const TargetCalcOptions(targetDistM: 300.0, chartStepM: 10.0),
      );

      expect(result.hitResult.trajectory, isNotEmpty);
      expect(result.zeroElevationRad, isNot(0.0));
    });

    test('trajectory extends to target distance', () async {
      final profile = _makeProfile(targetDistM: 500.0);
      final result = await service.calculateForTarget(
        profile,
        const TargetCalcOptions(targetDistM: 500.0, chartStepM: 10.0),
      );

      final lastPoint = result.hitResult.trajectory.last;
      expect(lastPoint.distance.in_(Unit.meter), closeTo(500.0, 2.0));
    });

    test('target shot has hold applied (relative angle set)', () async {
      final profile = _makeProfile(targetDistM: 300.0);
      final result = await service.calculateForTarget(
        profile,
        const TargetCalcOptions(targetDistM: 300.0, chartStepM: 10.0),
      );

      // The shot should have a relative angle set (hold for target)
      final shot = result.hitResult.shot;
      final holdRad = shot.relativeAngle.in_(Unit.radian);
      // For 300m target with 100m zero, hold should be negative (bullet drops)
      expect(holdRad, isNot(0.0));
    });

    test('cached zero elevation gives same results', () async {
      final profile = _makeProfile(targetDistM: 300.0);
      final opts = const TargetCalcOptions(
        targetDistM: 300.0,
        chartStepM: 10.0,
      );

      final first = await service.calculateForTarget(profile, opts);
      final second = await service.calculateForTarget(
        profile,
        opts,
        cachedZeroElevRad: first.zeroElevationRad,
      );

      expect(
        second.hitResult.trajectory.length,
        equals(first.hitResult.trajectory.length),
      );
      expect(second.zeroElevationRad, closeTo(first.zeroElevationRad, 1e-9));
    });

    test('different target distances produce different results', () async {
      final profile = _makeProfile();

      final short = await service.calculateForTarget(
        profile,
        const TargetCalcOptions(targetDistM: 200.0, chartStepM: 10.0),
      );
      final long = await service.calculateForTarget(
        profile,
        const TargetCalcOptions(targetDistM: 800.0, chartStepM: 10.0),
      );

      expect(
        long.hitResult.trajectory.length,
        greaterThan(short.hitResult.trajectory.length),
      );
    });
  });

  group('BallisticsService — wind effects', () {
    test('wind produces non-zero windage', () async {
      final profile = _makeProfile(
        winds: [
          WindData(
            velocity: Velocity(5.0, Unit.mps),
            directionFrom: Angular(90.0, Unit.degree),
            untilDistance: Distance(2000.0, Unit.meter),
          ),
        ],
      );

      final result = await service.calculateTable(
        profile,
        const TableCalcOptions(stepM: 100),
      );

      // At long range, windage should be non-zero
      final lastPoint = result.hitResult.trajectory.last;
      expect(lastPoint.windage.in_(Unit.centimeter).abs(), greaterThan(0.1));
    });

    test('no wind gives much less windage than with wind', () async {
      final noWindProfile = _makeProfile(winds: const []);
      final windProfile = _makeProfile(
        winds: [
          WindData(
            velocity: Velocity(10.0, Unit.mps),
            directionFrom: Angular(90.0, Unit.degree),
            untilDistance: Distance(2000.0, Unit.meter),
          ),
        ],
      );

      final noWindResult = await service.calculateTable(
        noWindProfile,
        const TableCalcOptions(stepM: 100),
      );
      final windResult = await service.calculateTable(
        windProfile,
        const TableCalcOptions(stepM: 100),
      );

      // At long range, wind should cause significantly more windage
      // than spin drift alone
      final noWindLast = noWindResult.hitResult.trajectory.last;
      final windLast = windResult.hitResult.trajectory.last;
      expect(
        windLast.windage.in_(Unit.centimeter).abs(),
        greaterThan(noWindLast.windage.in_(Unit.centimeter).abs() * 5),
        reason: 'Wind should cause much more windage than spin drift alone',
      );
    });
  });

  group('BallisticsService — error handling', () {
    test('throws CalculationException for invalid profile', () async {
      // BC must be positive, zero MV will cause issues in zeroing
      final projectile = Projectile(
        name: 'Bad',
        dragType: DragModelType.g7,
        weight: Weight(1, Unit.grain),
        coefRows: [CoeficientRow(bcCd: 0.001, mv: 0.0)],
      );
      final cartridge = Cartridge(
        name: 'Bad',
        projectile: projectile,
        mv: Velocity(10.0, Unit.mps), // extremely low velocity
        powderTemp: Temperature(15.0, Unit.celsius),
        powderSensitivity: Ratio(0.0, Unit.fraction),
        zeroDistance: Distance(3000.0, Unit.meter), // impossible zero
      );
      final rifle = Rifle(
        name: 'Bad',
        sightHeight: Distance(38.0, Unit.millimeter),
        twist: Distance(0.0, Unit.inch),
      );
      final sight = Sight(
        name: 'Bad',
        sightHeight: Distance(38.0, Unit.millimeter),
        zeroElevation: Angular(0, Unit.radian),
      );
      final badProfile = ShotProfile(
        name: 'Bad Shot',
        rifle: rifle,
        cartridgeId: cartridge.id,
        cartridge: cartridge,
        sightId: sight.id,
        sight: sight,
        conditions: AtmoData(
          altitude: Distance(0, Unit.meter),
          temperature: Temperature(15.0, Unit.celsius),
          pressure: Pressure(1013.25, Unit.hPa),
          humidity: 0.0,
          powderTemp: Temperature(15.0, Unit.celsius),
        ),
        lookAngle: Angular(0, Unit.degree),
      );

      expect(
        () => service.calculateTable(
          badProfile,
          const TableCalcOptions(stepM: 100),
        ),
        throwsA(isA<CalculationException>()),
      );
    });
  });

  group('BallisticsService — powder sensitivity', () {
    test('powder sensitivity changes trajectory', () async {
      final profile = _makeProfile().copyWith(
        cartridge: Cartridge(
          name: 'Temp Sens',
          projectile: Projectile(
            name: 'Test',
            dragType: DragModelType.g7,
            weight: Weight(175, Unit.grain),
            diameter: Distance(7.62, Unit.millimeter),
            coefRows: [CoeficientRow(bcCd: 0.475, mv: 0.0)],
          ),
          mv: Velocity(800, Unit.mps),
          powderTemp: Temperature(15, Unit.celsius),
          powderSensitivity: Ratio(
            1.0,
            Unit.fraction,
          ), // 1.0 m/s per °C (stored as %)
          usePowderSensitivity: true,
        ),
        conditions: AtmoData(
          temperature: Temperature(35, Unit.celsius), // 20°C above reference
          altitude: Distance(0, Unit.meter),
          pressure: Pressure(1013.25, Unit.hPa),
          humidity: 0.0,
          powderTemp: Temperature(35, Unit.celsius),
        ),
      );

      final withSens = await service.calculateTable(
        profile.copyWith(usePowderSensitivity: true),
        const TableCalcOptions(stepM: 100),
      );
      final withoutSens = await service.calculateTable(
        profile.copyWith(usePowderSensitivity: false),
        const TableCalcOptions(stepM: 100),
      );

      // With +20°C and powder sensitivity, MV is higher → different zero elev
      expect(
        withSens.zeroElevationRad,
        isNot(closeTo(withoutSens.zeroElevationRad, 1e-9)),
      );
    });
  });

  group('BallisticsResult data class', () {
    test('stores hitResult and zeroElevationRad', () async {
      final profile = _makeProfile();
      final result = await service.calculateTable(
        profile,
        const TableCalcOptions(stepM: 100),
      );

      expect(result.hitResult, isNotNull);
      expect(result.zeroElevationRad, isA<double>());
      expect(result.zeroElevationRad.isFinite, isTrue);
    });
  });

  group('TableCalcOptions / TargetCalcOptions', () {
    test('TableCalcOptions defaults', () {
      const opts = TableCalcOptions();
      expect(opts.startM, 0);
      expect(opts.endM, 2000);
      expect(opts.stepM, 100);
    });

    test('TargetCalcOptions required targetDistM', () {
      const opts = TargetCalcOptions(targetDistM: 500.0);
      expect(opts.targetDistM, 500.0);
      expect(opts.chartStepM, 10.0);
    });
  });
}
