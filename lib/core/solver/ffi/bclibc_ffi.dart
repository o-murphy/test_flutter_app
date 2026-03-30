// ignore_for_file: dangling_library_doc_comments
/// Thin Dart wrapper over the bclibc C FFI layer.
///
/// API mirrors the WASM bindings:
///   findApex, findMaxRange, findZeroAngle, integrate, integrateAt
///
/// Usage:
///   final bc = BcLibC.open();
///   final hit = bc.integrate(props, request);

import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'bclibc_bindings.g.dart';

// ============================================================================
// Library loader
// ============================================================================

ffi.DynamicLibrary _openLibrary() {
  String lib(String name) {
    // During development / dart test: check local cmake build dir first.
    final env = Platform.environment['BCLIBC_FFI_PATH'];
    if (env != null && env.isNotEmpty) return env;
    final devPath = 'build/bclibc/$name';
    if (File(devPath).existsSync()) return devPath;
    return name; // bundled app (RPATH / system lookup)
  }

  if (Platform.isLinux) return ffi.DynamicLibrary.open(lib('libbclibc_ffi.so'));
  if (Platform.isWindows) return ffi.DynamicLibrary.open(lib('bclibc_ffi.dll'));
  if (Platform.isMacOS) {
    return ffi.DynamicLibrary.open(lib('libbclibc_ffi.dylib'));
  }
  throw UnsupportedError(
    'bclibc_ffi: unsupported platform ${Platform.operatingSystem}',
  );
}

// ============================================================================
// Dart-side value types (mirrors WASM JS plain-objects)
// ============================================================================

class BcConfig {
  final double stepMultiplier;
  final double zeroFindingAccuracy;
  final double minimumVelocity;
  final double maximumDrop;
  final int maxIterations;
  final double gravityConstant;
  final double minimumAltitude;

  const BcConfig({
    this.stepMultiplier = 1.0,
    this.zeroFindingAccuracy = 0.001,
    this.minimumVelocity = 50.0,
    this.maximumDrop = -15000.0,
    this.maxIterations = 50,
    this.gravityConstant = -32.17405,
    this.minimumAltitude = -1000.0,
  });
}

class BcAtmosphere {
  final double t0;
  final double a0;
  final double p0;
  final double mach;
  final double densityRatio;
  final double cLowestTempC;

  const BcAtmosphere({
    required this.t0,
    required this.a0,
    required this.p0,
    required this.mach,
    required this.densityRatio,
    required this.cLowestTempC,
  });
}

class BcCoriolis {
  final double sinLat, cosLat, sinAz, cosAz;
  final double rangeEast, rangeNorth, crossEast, crossNorth;
  final bool flatFireOnly;
  final double muzzleVelocityFps;

  const BcCoriolis({
    this.sinLat = 0,
    this.cosLat = 1,
    this.sinAz = 0,
    this.cosAz = 1,
    this.rangeEast = 0,
    this.rangeNorth = 0,
    this.crossEast = 0,
    this.crossNorth = 0,
    this.flatFireOnly = true,
    this.muzzleVelocityFps = 0,
  });
}

class BcWind {
  final double velocityFps;
  final double directionFromRad;
  final double untilDistanceFt;
  final double maxDistanceFt;

  const BcWind({
    required this.velocityFps,
    required this.directionFromRad,
    this.untilDistanceFt = 1e9,
    this.maxDistanceFt = 1e9,
  });
}

class BcDragPoint {
  final double mach;
  final double cd;
  const BcDragPoint(this.mach, this.cd);
}

class BcShotProps {
  final double bc;
  final double lookAngleRad;
  final double twistInch;
  final double lengthInch;
  final double diameterInch;
  final double weightGrain;
  final double barrelElevationRad;
  final double barrelAzimuthRad;
  final double sightHeightFt;
  final double cantAngleRad;
  final double alt0Ft;
  final double muzzleVelocityFps;
  final BcAtmosphere atmo;
  final BcCoriolis coriolis;
  final BcConfig config;

  final BCIntegrationMethod method;
  final List<BcDragPoint> dragTable;
  final List<BcWind> winds;

  const BcShotProps({
    required this.bc,
    required this.lookAngleRad,
    required this.twistInch,
    required this.lengthInch,
    required this.diameterInch,
    required this.weightGrain,
    required this.barrelElevationRad,
    required this.barrelAzimuthRad,
    required this.sightHeightFt,
    this.cantAngleRad = 0.0,
    required this.alt0Ft,
    required this.muzzleVelocityFps,
    required this.atmo,
    required this.coriolis,
    this.config = const BcConfig(),
    this.method = BCIntegrationMethod.BC_INTEGRATION_RK4,
    required this.dragTable,
    this.winds = const [],
  });
}

class BcTrajectoryRequest {
  final double rangeLimitFt;
  final double rangeStepFt;
  final double timeStep;

  /// BCTrajFlag bitmask (may combine multiple flags via bitwise OR)
  final int filterFlags;

  const BcTrajectoryRequest({
    required this.rangeLimitFt,
    required this.rangeStepFt,
    this.timeStep = 0.0,
    this.filterFlags = 8, // BCTrajFlag.BC_TRAJ_FLAG_RANGE
  });
}

// ============================================================================
// Result types
// ============================================================================

class BcTrajectoryData {
  final double time, distanceFt, velocityFps, mach;
  final double heightFt, slantHeightFt, dropAngleRad;
  final double windageFt, windageAngleRad;
  final double slantDistanceFt, angleRad;
  final double densityRatio, drag;
  final double energyFtLb, ogwLb;
  final int flag; // BCTrajFlag

  const BcTrajectoryData({
    required this.time,
    required this.distanceFt,
    required this.velocityFps,
    required this.mach,
    required this.heightFt,
    required this.slantHeightFt,
    required this.dropAngleRad,
    required this.windageFt,
    required this.windageAngleRad,
    required this.slantDistanceFt,
    required this.angleRad,
    required this.densityRatio,
    required this.drag,
    required this.energyFtLb,
    required this.ogwLb,
    required this.flag,
  });

  factory BcTrajectoryData._fromNative(BCTrajectoryData s) => BcTrajectoryData(
    time: s.time,
    distanceFt: s.distance_ft,
    velocityFps: s.velocity_fps,
    mach: s.mach,
    heightFt: s.height_ft,
    slantHeightFt: s.slant_height_ft,
    dropAngleRad: s.drop_angle_rad,
    windageFt: s.windage_ft,
    windageAngleRad: s.windage_angle_rad,
    slantDistanceFt: s.slant_distance_ft,
    angleRad: s.angle_rad,
    densityRatio: s.density_ratio,
    drag: s.drag,
    energyFtLb: s.energy_ft_lb,
    ogwLb: s.ogw_lb,
    flag: s.flag,
  );
}

class BcBaseTrajData {
  final double time, px, py, pz, vx, vy, vz, mach;
  const BcBaseTrajData({
    required this.time,
    required this.px,
    required this.py,
    required this.pz,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.mach,
  });

  factory BcBaseTrajData._fromNative(BCBaseTrajData s) => BcBaseTrajData(
    time: s.time,
    px: s.px,
    py: s.py,
    pz: s.pz,
    vx: s.vx,
    vy: s.vy,
    vz: s.vz,
    mach: s.mach,
  );
}

class BcMaxRangeResult {
  final double maxRangeFt;
  final double angleAtMaxRad;
  const BcMaxRangeResult(this.maxRangeFt, this.angleAtMaxRad);
}

class BcHitResult {
  final List<BcTrajectoryData> trajectory;
  final BCTerminationReason reason;
  const BcHitResult(this.trajectory, this.reason);
}

class BcInterception {
  final BcBaseTrajData rawData;
  final BcTrajectoryData fullData;
  const BcInterception(this.rawData, this.fullData);
}

// ============================================================================
// Exception
// ============================================================================

class BcException implements Exception {
  final int code; // BCFFIStatus
  final String message;
  // OutOfRange extras
  final double? requestedDistanceFt, maxRangeFt, lookAngleRad;
  // ZeroFinding extras
  final double? zeroFindingError, lastBarrelElevationRad;
  final int? iterationsCount;

  const BcException({
    required this.code,
    required this.message,
    this.requestedDistanceFt,
    this.maxRangeFt,
    this.lookAngleRad,
    this.zeroFindingError,
    this.lastBarrelElevationRad,
    this.iterationsCount,
  });

  @override
  String toString() => 'BcException($code): $message';
}

// ffi.Array<ffi.Char> → Dart String (null-terminated)
String _charArrayToString(ffi.Array<ffi.Char> arr, int maxLen) {
  final codes = <int>[];
  for (var i = 0; i < maxLen; i++) {
    final c = arr[i];
    if (c == 0) break;
    codes.add(c);
  }
  return String.fromCharCodes(codes);
}

Never _throwFromError(BCLIBCFFIError err) {
  final msg = _charArrayToString(err.message, 512);
  if (err.code == BCLIBCFFIStatus.BCLIBCFFI_ERR_OUT_OF_RANGE.value) {
    throw BcException(
      code: err.code,
      message: msg,
      requestedDistanceFt: err.f64_0,
      maxRangeFt: err.f64_1,
      lookAngleRad: err.f64_2,
    );
  }
  if (err.code == BCLIBCFFIStatus.BCLIBCFFI_ERR_ZERO_FINDING.value) {
    throw BcException(
      code: err.code,
      message: msg,
      zeroFindingError: err.f64_0,
      lastBarrelElevationRad: err.f64_1,
      iterationsCount: err.i32_0,
    );
  }
  throw BcException(code: err.code, message: msg);
}

// ============================================================================
// Native struct fill helper
// ============================================================================

extension _FillNative on BcShotProps {
  void _fill(BCShotProps p, Arena arena) {
    p.bc = bc;
    p.look_angle_rad = lookAngleRad;
    p.twist_inch = twistInch;
    p.length_inch = lengthInch;
    p.diameter_inch = diameterInch;
    p.weight_grain = weightGrain;
    p.barrel_elevation_rad = barrelElevationRad;
    p.barrel_azimuth_rad = barrelAzimuthRad;
    p.sight_height_ft = sightHeightFt;
    p.cant_angle_rad = cantAngleRad;
    p.alt0_ft = alt0Ft;
    p.muzzle_velocity_fps = muzzleVelocityFps;
    p.methodAsInt = method.value;

    p.atmo.t0 = atmo.t0;
    p.atmo.a0 = atmo.a0;
    p.atmo.p0 = atmo.p0;
    p.atmo.mach = atmo.mach;
    p.atmo.density_ratio = atmo.densityRatio;
    p.atmo.cLowestTempC = atmo.cLowestTempC;

    p.coriolis.sin_lat = coriolis.sinLat;
    p.coriolis.cos_lat = coriolis.cosLat;
    p.coriolis.sin_az = coriolis.sinAz;
    p.coriolis.cos_az = coriolis.cosAz;
    p.coriolis.range_east = coriolis.rangeEast;
    p.coriolis.range_north = coriolis.rangeNorth;
    p.coriolis.cross_east = coriolis.crossEast;
    p.coriolis.cross_north = coriolis.crossNorth;
    p.coriolis.flat_fire_only = coriolis.flatFireOnly ? 1 : 0;
    p.coriolis.muzzle_velocity_fps = coriolis.muzzleVelocityFps;

    p.config.cStepMultiplier = config.stepMultiplier;
    p.config.cZeroFindingAccuracy = config.zeroFindingAccuracy;
    p.config.cMinimumVelocity = config.minimumVelocity;
    p.config.cMaximumDrop = config.maximumDrop;
    p.config.cMaxIterations = config.maxIterations;
    p.config.cGravityConstant = config.gravityConstant;
    p.config.cMinimumAltitude = config.minimumAltitude;

    final dt = arena<BCDragPoint>(dragTable.length);
    for (var i = 0; i < dragTable.length; i++) {
      dt[i].Mach = dragTable[i].mach;
      dt[i].CD = dragTable[i].cd;
    }
    p.drag_table = dt;
    p.drag_table_count = dragTable.length;

    if (winds.isEmpty) {
      p.winds = ffi.nullptr;
      p.wind_count = 0;
    } else {
      final ws = arena<BCWind>(winds.length);
      for (var i = 0; i < winds.length; i++) {
        ws[i].velocity_fps = winds[i].velocityFps;
        ws[i].direction_from_rad = winds[i].directionFromRad;
        ws[i].until_distance_ft = winds[i].untilDistanceFt;
        ws[i].max_distance_ft = winds[i].maxDistanceFt;
      }
      p.winds = ws;
      p.wind_count = winds.length;
    }
  }
}

// ============================================================================
// Main API class
// ============================================================================

class BcLibC {
  final BcLibCFFIBindings _b;

  BcLibC._(this._b);

  /// Open the native library. Call once per isolate.
  factory BcLibC.open() => BcLibC._(BcLibCFFIBindings(_openLibrary()));

  BcTrajectoryData findApex(BcShotProps props) => using((arena) {
    final p = arena<BCShotProps>();
    final out = arena<BCTrajectoryData>();
    final err = arena<BCLIBCFFIError>();
    props._fill(p.ref, arena);
    final st = _b.BCLIBCFFI_find_apex(p, out, err);
    if (st != 0) _throwFromError(err.ref);
    return BcTrajectoryData._fromNative(out.ref);
  });

  BcMaxRangeResult findMaxRange(
    BcShotProps props, {
    double lowAngleDeg = 0.0,
    double highAngleDeg = 45.0,
  }) => using((arena) {
    final p = arena<BCShotProps>();
    final out = arena<BCMaxRangeResult>();
    final err = arena<BCLIBCFFIError>();
    props._fill(p.ref, arena);
    final st = _b.BCLIBCFFI_find_max_range(
      p,
      lowAngleDeg,
      highAngleDeg,
      out,
      err,
    );
    if (st != 0) _throwFromError(err.ref);
    return BcMaxRangeResult(out.ref.max_range_ft, out.ref.angle_at_max_rad);
  });

  double findZeroAngle(BcShotProps props, double distanceFt) => using((arena) {
    final p = arena<BCShotProps>();
    final outAngle = arena<ffi.Double>();
    final err = arena<BCLIBCFFIError>();
    props._fill(p.ref, arena);
    final st = _b.BCLIBCFFI_find_zero_angle(p, distanceFt, outAngle, err);
    if (st != 0) _throwFromError(err.ref);
    return outAngle.value;
  });

  BcHitResult integrate(BcShotProps props, BcTrajectoryRequest request) =>
      using((arena) {
        final p = arena<BCShotProps>();
        final req = arena<BCTrajectoryRequest>();
        final pPtr = arena<ffi.Pointer<BCTrajectoryData>>();
        final pCount = arena<ffi.Int32>();
        final pReason = arena<ffi.Int32>();
        final err = arena<BCLIBCFFIError>();

        props._fill(p.ref, arena);
        req.ref.range_limit_ft = request.rangeLimitFt;
        req.ref.range_step_ft = request.rangeStepFt;
        req.ref.time_step = request.timeStep;
        req.ref.filter_flags = request.filterFlags;

        final st = _b.BCLIBCFFI_integrate(p, req, pPtr, pCount, pReason, err);
        if (st != 0) _throwFromError(err.ref);

        final count = pCount.value;
        final rawPtr = pPtr.value;
        final records = List<BcTrajectoryData>.generate(
          count,
          (i) => BcTrajectoryData._fromNative(rawPtr[i]),
        );
        if (count > 0) _b.BCLIBCFFI_free_trajectory(rawPtr);

        return BcHitResult(records, BCTerminationReason.fromValue(pReason.value));
      });

  BcInterception integrateAt(BcShotProps props, BCBaseTrajInterpKey key, double targetValue) =>
      using((arena) {
        final p = arena<BCShotProps>();
        final out = arena<BCInterception>();
        final err = arena<BCLIBCFFIError>();
        props._fill(p.ref, arena);
        final st = _b.BCLIBCFFI_integrate_at(p, key.value, targetValue, out, err);
        if (st != 0) _throwFromError(err.ref);
        return BcInterception(
          BcBaseTrajData._fromNative(out.ref.raw_data),
          BcTrajectoryData._fromNative(out.ref.full_data),
        );
      });

  double getCorrection(double distanceFt, double offsetFt) =>
      _b.BCLIBCFFI_get_correction(distanceFt, offsetFt);

  double calculateEnergy(double bulletWeightGrain, double velocityFps) =>
      _b.BCLIBCFFI_calculate_energy(bulletWeightGrain, velocityFps);

  double calculateOgw(double bulletWeightGrain, double velocityFps) =>
      _b.BCLIBCFFI_calculate_ogw(bulletWeightGrain, velocityFps);
}
