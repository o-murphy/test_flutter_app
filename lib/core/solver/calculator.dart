// Calculator — Dart port of the TypeScript Calculator class.
//
// Wraps BcLibC (FFI layer) with the same API surface as the WASM Calculator:
//   barrelElevationForTarget, setWeaponZero, fire
//
// Usage:
//   final calc = Calculator();
//   final elev = calc.barrelElevationForTarget(shot, Distance(1000, Unit.meter));
//   calc.setWeaponZero(shot, Distance(100, Unit.meter));
//   final result = calc.fire(shot: shot, trajectoryRange: Distance(1000, Unit.meter));

import 'dart:math' as math;

import 'package:eballistica/core/solver/conditions.dart';
import 'package:eballistica/core/solver/constants.dart';
import 'package:eballistica/core/solver/ffi/bclibc_bindings.g.dart';
import 'package:eballistica/core/solver/ffi/bclibc_ffi.dart';
import 'package:eballistica/core/solver/shot.dart';
import 'package:eballistica/core/solver/trajectory_data.dart';
import 'package:eballistica/core/solver/unit.dart';

// ---------------------------------------------------------------------------
// Default config constants (mirror TS DEFAULT_CONFIG)
// ---------------------------------------------------------------------------

const double cZeroFindingAccuracy = 0.000005;
const int cMaxIterations = 40;
const double cMinimumAltitude = -1500.0;
const double cMaximumDrop = -10000.0;
const double cMinimumVelocity = 50.0;
const double cGravityConstant = -BallisticConstants.cGravityImperial;
const double cStepMultiplier = 1.0;

const BcConfig defaultConfig = BcConfig(
  zeroFindingAccuracy: cZeroFindingAccuracy,
  maxIterations: cMaxIterations,
  minimumAltitude: cMinimumAltitude,
  maximumDrop: cMaximumDrop,
  minimumVelocity: cMinimumVelocity,
  gravityConstant: cGravityConstant,
  stepMultiplier: cStepMultiplier,
);

// ---------------------------------------------------------------------------
// Calculator
// ---------------------------------------------------------------------------

class Calculator {
  final BCIntegrationMethod method;
  final BcConfig config;

  late final BcLibC _engine;

  Calculator({
    this.method = BCIntegrationMethod.BC_INTEGRATION_RK4,
    BcConfig? config,
  }) : config = config ?? defaultConfig {
    _engine = BcLibC.open();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the barrel elevation (relative to look-angle) needed to hit
  /// a target at [targetDistance].
  Angular barrelElevationForTarget(Shot shot, Distance targetDistance) {
    final distFt = _toFeet(targetDistance);
    final props = _toBcShotProps(shot);
    final totalRad = _engine.findZeroAngle(props, distFt);
    return Angular(totalRad - shot.lookAngle.in_(Unit.radian), Unit.radian);
  }

  /// Zeros the weapon by storing the required barrel elevation in
  /// [Weapon.zeroElevation] and resetting [shot.relativeAngle] to zero.
  ///
  /// Any subsequent [Shot] that uses the same [Weapon] instance will
  /// automatically inherit the zero elevation, matching the JS-library
  /// behaviour where `weapon.zeroElevation` is mutable.
  Angular setWeaponZero(Shot shot, Distance zeroDistance) {
    final elev = barrelElevationForTarget(shot, zeroDistance);
    shot.weapon.zeroElevation = elev;
    shot.relativeAngle = Angular(0, Unit.radian);
    return elev;
  }

  /// Fires a shot and returns the full trajectory as a [HitResult].
  ///
  /// [trajectoryRange] and [trajectoryStep] accept a [Distance] object or
  /// a raw number in the preferred distance unit.
  HitResult fire({
    required Shot shot,
    required Distance trajectoryRange,
    Distance? trajectoryStep,
    double timeStep = 0.0,
    int filterFlags = 8, // BCTrajFlag.BC_TRAJ_FLAG_RANGE
    bool raiseRangeError = true,
  }) {
    final rangeFt = _toFeet(trajectoryRange);
    final stepFt = trajectoryStep != null ? _toFeet(trajectoryStep) : rangeFt;

    final request = BcTrajectoryRequest(
      rangeLimitFt: rangeFt,
      rangeStepFt: stepFt,
      timeStep: timeStep,
      filterFlags: filterFlags,
    );

    late BcHitResult bcResult;
    try {
      bcResult = _engine.integrate(_toBcShotProps(shot), request);
    } on BcException catch (e) {
      if (raiseRangeError) rethrow;
      return HitResult(shot, [], filterFlags: filterFlags, error: e);
    }

    final traj = bcResult.trajectory.map(_toTrajectoryData).toList();
    return HitResult(shot, traj, filterFlags: filterFlags);
  }

  // ── Conversion helpers ─────────────────────────────────────────────────────

  static double _toFeet(Distance d) => d.in_(Unit.foot);

  /// Converts [Shot] + calculator settings to the flat C struct expected by BcLibC.
  BcShotProps _toBcShotProps(Shot shot) {
    final mvFps = shot.ammo
        .getVelocityForTemp(shot.atmo.powderTemp)
        .in_(Unit.fps);

    return BcShotProps(
      bc: shot.ammo.dm.bc,
      lookAngleRad: shot.lookAngle.in_(Unit.radian),
      twistInch: shot.weapon.twist.in_(Unit.inch),
      lengthInch: shot.ammo.dm.length.in_(Unit.inch),
      diameterInch: shot.ammo.dm.diameter.in_(Unit.inch),
      weightGrain: shot.ammo.dm.weight.in_(Unit.grain),
      barrelElevationRad: shot.barrelElevation.in_(Unit.radian),
      barrelAzimuthRad: shot.barrelAzimuth.in_(Unit.radian),
      sightHeightFt: shot.weapon.sightHeight.in_(Unit.foot),
      cantAngleRad: shot.cantAngle.in_(Unit.radian),
      alt0Ft: shot.atmo.altitude.in_(Unit.foot),
      muzzleVelocityFps: mvFps,
      atmo: _toAtmo(shot.atmo),
      coriolis: _toCoriolis(shot, mvFps),
      config: config,
      method: method,
      dragTable: shot.ammo.dm.dragTable
          .map((p) => BcDragPoint(p.mach, p.cd))
          .toList(),
      winds: shot.winds.map(_toWind).toList(),
    );
  }

  static BcAtmosphere _toAtmo(Atmo a) => BcAtmosphere(
    t0: a.temperature.in_(Unit.celsius),
    a0: a.altitude.in_(Unit.foot),
    p0: a.pressure.in_(Unit.hPa),
    mach: a.mach.in_(Unit.fps),
    densityRatio: a.densityRatio,
    cLowestTempC: Atmo.cLowestTempC,
  );

  static BcWind _toWind(Wind w) => BcWind(
    velocityFps: w.velocity.in_(Unit.fps),
    directionFromRad: w.directionFrom.in_(Unit.radian),
    untilDistanceFt: w.untilDistance.in_(Unit.foot),
    maxDistanceFt: Wind.maxDistanceFeet,
  );

  /// Mirrors the TypeScript Coriolis constructor logic.
  static BcCoriolis _toCoriolis(Shot shot, double mvFps) {
    final lat = shot.latitudeDeg;
    if (lat == null) {
      // No Coriolis
      return BcCoriolis(muzzleVelocityFps: mvFps);
    }

    final latRad = lat * math.pi / 180.0;
    final sinLat = math.sin(latRad);
    final cosLat = math.cos(latRad);

    final az = shot.azimuthDeg;
    if (az == null) {
      // Flat-fire approximation
      return BcCoriolis(
        sinLat: sinLat,
        cosLat: cosLat,
        flatFireOnly: true,
        muzzleVelocityFps: mvFps,
      );
    }

    // Full 3D Coriolis
    final azRad = az * math.pi / 180.0;
    final sinAz = math.sin(azRad);
    final cosAz = math.cos(azRad);
    return BcCoriolis(
      sinLat: sinLat,
      cosLat: cosLat,
      sinAz: sinAz,
      cosAz: cosAz,
      rangeEast: sinAz,
      rangeNorth: cosAz,
      crossEast: cosAz,
      crossNorth: -sinAz,
      flatFireOnly: false,
      muzzleVelocityFps: mvFps,
    );
  }

  // ── Result conversion ──────────────────────────────────────────────────────

  static TrajectoryData _toTrajectoryData(BcTrajectoryData d) => TrajectoryData(
    time: d.time,
    distance: Distance(d.distanceFt, Unit.foot),
    velocity: Velocity(d.velocityFps, Unit.fps),
    mach: d.mach,
    height: Distance(d.heightFt, Unit.foot),
    slantHeight: Distance(d.slantHeightFt, Unit.foot),
    dropAngle: Angular(d.dropAngleRad, Unit.radian),
    windage: Distance(d.windageFt, Unit.foot),
    windageAngle: Angular(d.windageAngleRad, Unit.radian),
    slantDistance: Distance(d.slantDistanceFt, Unit.foot),
    angle: Angular(d.angleRad, Unit.radian),
    densityRatio: d.densityRatio,
    drag: d.drag,
    energy: Energy(d.energyFtLb, Unit.footPound),
    ogw: Weight(d.ogwLb, Unit.pound),
    flag: d.flag,
  );
}
