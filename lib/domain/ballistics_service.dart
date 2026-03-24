// ЧИСТИЙ DART — без Flutter імпортів
import 'package:eballistica/src/models/shot_profile.dart';
import 'package:eballistica/src/solver/trajectory_data.dart';

class TableCalcOptions {
  final double startM;
  final double endM;
  final double stepM;
  final bool usePowderSensitivity;

  const TableCalcOptions({
    this.startM = 0,
    this.endM = 2000,
    this.stepM = 100,
    this.usePowderSensitivity = false,
  });
}

class TargetCalcOptions {
  final double targetDistM;
  final double chartStepM;
  final bool usePowderSensitivity;

  const TargetCalcOptions({
    required this.targetDistM,
    this.chartStepM = 10,
    this.usePowderSensitivity = false,
  });
}

class BallisticsResult {
  final HitResult hitResult;
  final double zeroElevationRad;

  const BallisticsResult({
    required this.hitResult,
    required this.zeroElevationRad,
  });
}

abstract interface class BallisticsService {
  Future<BallisticsResult> calculateTable(
    ShotProfile profile,
    TableCalcOptions opts, {
    double? cachedZeroElevRad,
  });

  Future<BallisticsResult> calculateForTarget(
    ShotProfile profile,
    TargetCalcOptions opts, {
    double? cachedZeroElevRad,
  });
}
