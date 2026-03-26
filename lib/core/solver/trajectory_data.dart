import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/core/solver/shot.dart';

enum TrajFlag {
  none(0),
  zeroUp(1),
  zeroDown(2),
  zero(3),
  mach(4),
  range(8),
  apex(16),
  mrt(32);

  final int value;
  const TrajFlag(this.value);

  static String getName(int flagValue) {
    if (flagValue == 0) return "NONE";
    List<String> parts = [];
    if (flagValue & zeroUp.value != 0) parts.add("ZERO_UP");
    if (flagValue & zeroDown.value != 0) parts.add("ZERO_DOWN");
    if (flagValue & mach.value != 0) parts.add("MACH");
    if (flagValue & range.value != 0) parts.add("RANGE");
    if (flagValue & apex.value != 0) parts.add("APEX");
    return parts.isEmpty ? "UNKNOWN" : parts.join("|");
  }
}

class TrajectoryData {
  final double time;
  final Distance distance;
  final Velocity velocity;
  final double mach;
  final Distance height;
  final Distance slantHeight;
  final Angular dropAngle;
  final Distance windage;
  final Angular windageAngle;
  final Distance slantDistance;
  final Angular angle;
  final double densityRatio;
  final double drag;
  final Energy energy;
  final Weight ogw;
  final int flag;

  TrajectoryData({
    required this.time,
    required this.distance,
    required this.velocity,
    required this.mach,
    required this.height,
    required this.slantHeight,
    required this.dropAngle,
    required this.windage,
    required this.windageAngle,
    required this.slantDistance,
    required this.angle,
    required this.densityRatio,
    required this.drag,
    required this.energy,
    required this.ogw,
    required this.flag,
  });

  List<String> formatted() {
    return [
      "${time.toStringAsFixed(3)} s",
      distance.toString(),
      velocity.toString(),
      "${mach.toStringAsFixed(2)} mach",
      height.toString(),
      windage.toString(),
      dropAngle.toString(),
      TrajFlag.getName(flag),
    ];
  }
}

class HitResult {
  final Shot shot;
  final List<TrajectoryData> trajectory;
  final int filterFlags;
  final Exception? error;

  HitResult(this.shot, this.trajectory, {this.filterFlags = 0, this.error});

  int get length => trajectory.length;

  TrajectoryData getAtDistance(Distance d) {
    final target = d.in_(Unit.foot);
    final index = trajectory.indexWhere(
      (step) => step.distance.in_(Unit.foot) >= target,
    );
    if (index == -1) {
      return trajectory.last;
    }
    return trajectory[index];
  }

  List<TrajectoryData> get zeros {
    return trajectory
        .where((step) => (step.flag & TrajFlag.zero.value) != 0)
        .toList();
  }
}
