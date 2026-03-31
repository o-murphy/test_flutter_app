// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'package:eballistica/core/solver/munition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/domain/ballistics_service.dart';
import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/core/providers/service_providers.dart';
import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/solver/trajectory_data.dart';
import 'package:eballistica/core/solver/unit.dart';

sealed class ShotDetailsUiState {
  const ShotDetailsUiState();
}

class ShotDetailsLoading extends ShotDetailsUiState {
  const ShotDetailsLoading();
}

class ShotDetailsError extends ShotDetailsUiState {
  final String message;
  const ShotDetailsError(this.message);
}

class ShotDetailsReady extends ShotDetailsUiState {
  // Velocity section
  final String currentMv;
  final String zeroMv;
  final String speedOfSound;
  final String velocityAtTarget;

  // Energy section
  final String energyAtMuzzle;
  final String energyAtTarget;

  // Stability section
  final String gyroscopicStability;

  // Trajectory section
  final String shotDistance;
  final String heightAtTarget;
  final String maxHeightDistance;
  final String windage;
  final String timeToTarget;

  const ShotDetailsReady({
    required this.currentMv,
    required this.zeroMv,
    required this.speedOfSound,
    required this.velocityAtTarget,
    required this.energyAtMuzzle,
    required this.energyAtTarget,
    required this.gyroscopicStability,
    required this.shotDistance,
    required this.heightAtTarget,
    required this.maxHeightDistance,
    required this.windage,
    required this.timeToTarget,
  });
}

class ShotDetailsViewModel extends AsyncNotifier<ShotDetailsUiState> {
  @override
  Future<ShotDetailsUiState> build() async {
    return _calculate();
  }

  Future<void> recalculate() async {
    // We can show loading if state is not ready,
    // but usually we want to just update data silently.
    try {
      final newState = await _calculate();
      if (!ref.mounted) return;
      state = AsyncData(newState);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }

  Future<ShotDetailsUiState> _calculate() async {
    try {
      final profile = await ref.read(shotProfileProvider.future);
      final settings = await ref.read(settingsProvider.future);
      final formatter = ref.read(unitFormatterProvider);

      final opts = TargetCalcOptions(
        targetDistM: profile.targetDistance.in_(Unit.meter),
        chartStepM: settings.chartDistanceStep,
      );

      final result = await ref
          .read(ballisticsServiceProvider)
          .calculateForTarget(profile, opts);
      final hit = result.hitResult;

      return _buildReadyState(profile, settings, formatter, hit);
    } catch (e) {
      return ShotDetailsError(e.toString());
    }
  }

  ShotDetailsReady _buildReadyState(
    ShotProfile profile,
    AppSettings settings,
    UnitFormatter formatter,
    HitResult hit,
  ) {
    final cartridge = profile.cartridge;
    final targetDistM = profile.targetDistance.in_(Unit.meter);
    final traj = hit.trajectory;
    final atTarget = hit.getAtDistance(Distance(targetDistM, Unit.meter));

    // MV Logic with powder sensitivity
    final refMvMps = cartridge.mv.in_(Unit.mps);
    final refPowderTempC = cartridge.powderTemp.in_(Unit.celsius);

    final currentPowderSensOn =
        profile.usePowderSensitivity && cartridge.usePowderSensitivity;
    final zeroPowderSensOn =
        (profile.zeroUsePowderSensitivity ?? profile.usePowderSensitivity) &&
        cartridge.usePowderSensitivity;
    final currentUseDiffTemp = currentPowderSensOn && profile.useDiffPowderTemp;
    final zeroUseDiffTemp = zeroPowderSensOn && profile.zeroUseDiffPowderTemp;

    double mvAtTempC(double tCurC) => velocityForPowderTemp(
      refMvMps,
      refPowderTempC,
      tCurC,
      cartridge.powderSensitivity,
    );

    final conditions = profile.conditions;
    final currentPowderTempC = currentUseDiffTemp
        ? conditions.powderTemp.in_(Unit.celsius)
        : conditions.temperature.in_(Unit.celsius);
    final currentMvMps = currentPowderSensOn
        ? mvAtTempC(currentPowderTempC)
        : refMvMps;

    final zeroAtmo = profile.zeroConditions ?? conditions;
    final zeroPowderTempC = zeroUseDiffTemp
        ? zeroAtmo.powderTemp.in_(Unit.celsius)
        : zeroAtmo.temperature.in_(Unit.celsius);
    final zeroMvMps = zeroPowderSensOn ? mvAtTempC(zeroPowderTempC) : refMvMps;

    // Speed of sound estimation from first point
    final double? soundSpeedFps = (traj.isNotEmpty && traj[0].mach > 0)
        ? (traj[0].velocity.in_(Unit.fps)) / traj[0].mach
        : null;

    // Gyroscopic stability
    final sg = profile.toShot().calculateStabilityCoefficient();

    // Trajectory markers
    final firstPoint = traj.isNotEmpty ? traj[0] : null;
    TrajectoryData? apexPoint;
    if (traj.length > 1) {
      apexPoint = traj.reduce(
        (a, b) => a.height.in_(Unit.meter) >= b.height.in_(Unit.meter) ? a : b,
      );
    }

    return ShotDetailsReady(
      currentMv: formatter.velocity(Velocity(currentMvMps, Unit.mps)),
      zeroMv: formatter.velocity(Velocity(zeroMvMps, Unit.mps)),
      speedOfSound: soundSpeedFps == null
          ? '—'
          : formatter.velocity(Velocity(soundSpeedFps, Unit.fps)),
      velocityAtTarget: formatter.velocity(atTarget.velocity),
      energyAtMuzzle: firstPoint == null
          ? '—'
          : formatter.energy(firstPoint.energy),
      energyAtTarget: formatter.energy(atTarget.energy),
      gyroscopicStability: sg.toStringAsFixed(2),
      shotDistance: formatter.distance(profile.targetDistance),
      heightAtTarget: formatter.drop(atTarget.height),
      maxHeightDistance: apexPoint == null
          ? '—'
          : formatter.distance(apexPoint.distance),
      windage: formatter.drop(atTarget.windage),
      timeToTarget: formatter.time(atTarget.time),
    );
  }
}

final shotDetailsVmProvider =
    AsyncNotifierProvider<ShotDetailsViewModel, ShotDetailsUiState>(
      ShotDetailsViewModel.new,
    );
