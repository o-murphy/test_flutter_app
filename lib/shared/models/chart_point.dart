// ЧИСТИЙ DART

class ChartPoint {
  final double distanceM;
  final double heightCm;
  final double velocityMps;
  final double mach;
  final double energyJ;
  final double time;
  final double dropAngleMil;
  final double windageAngleMil;
  final bool isZeroCrossing;
  final bool isSubsonic;

  const ChartPoint({
    required this.distanceM,
    required this.heightCm,
    required this.velocityMps,
    required this.mach,
    required this.energyJ,
    required this.time,
    required this.dropAngleMil,
    required this.windageAngleMil,
    this.isZeroCrossing = false,
    this.isSubsonic = false,
  });
}

class ChartData {
  final List<ChartPoint> points;
  final double snapDistM;

  const ChartData({required this.points, required this.snapDistM});

  static const empty = ChartData(points: [], snapDistM: 100);

  ChartPoint? pointAt(int index) =>
      (index >= 0 && index < points.length) ? points[index] : null;
}
