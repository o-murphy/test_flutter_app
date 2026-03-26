import 'dart:math';

import 'package:eballistica/core/solver/constants.dart';
import 'package:eballistica/core/solver/drag_tables.dart';
import 'package:eballistica/core/solver/unit.dart';

class BCPoint {
  final double   bc;
  final double   mach;
  final Velocity? v;

  BCPoint({required this.bc, double? mach, this.v})
      : mach = _calculateMach(mach, v) {
    if (bc <= 0) throw ArgumentError('Ballistic coefficient must be positive');
    if (mach != null && v != null) {
      throw ArgumentError("Cannot specify both 'mach' and 'v'");
    }
    if (mach == null && v == null) {
      throw ArgumentError("One of 'mach' or 'v' must be specified");
    }
  }

  static double _calculateMach(double? mach, Velocity? v) {
    if (v != null) return v.in_(Unit.mps) / _machC();
    return mach ?? 0.0;
  }

  static double _machC() =>
      sqrt(BallisticConstants.cStandardTemperatureC + BallisticConstants.cDegreesCtoK) *
      BallisticConstants.cSpeedOfSoundMetric;
}

class DragModel {
  final double bc;
  final List<DragDataPoint> dragTable;
  final Weight   weight;
  final Distance diameter;
  final Distance length;

  late final double sectionalDensity;
  late final double formFactor;

  DragModel({
    required this.bc,
    required List<dynamic> dragTable,
    Weight?   weight,
    Distance? diameter,
    Distance? length,
  })  : dragTable = makeDataPoints(dragTable),
        weight   = weight   ?? Weight(0, Unit.grain),
        diameter = diameter ?? Distance(0, Unit.inch),
        length   = length   ?? Distance(0, Unit.inch) {
    if (this.dragTable.isEmpty) throw ArgumentError('Received empty drag table');
    if (bc <= 0) throw ArgumentError('Ballistic coefficient must be positive');

    if (this.weight.rawValue > 0 && this.diameter.rawValue > 0) {
      sectionalDensity = _getSectionalDensity();
      formFactor       = _getFormFactor(bc);
    } else {
      sectionalDensity = 0.0;
      formFactor       = 0.0;
    }
  }

  double _getSectionalDensity() =>
      calculateSectionalDensity(weight.in_(Unit.grain), diameter.in_(Unit.inch));

  double _getFormFactor(double bcValue) => sectionalDensity / bcValue;
}

List<DragDataPoint> makeDataPoints(List<dynamic> table) {
  return table.map((point) {
    return switch (point) {
      DragDataPoint p => p,
      Map m when (m['mach'] ?? m['Mach']) != null && (m['cd'] ?? m['CD']) != null =>
        (
          mach: ((m['mach'] ?? m['Mach']) as num).toDouble(),
          cd:   ((m['cd']   ?? m['CD'])   as num).toDouble(),
        ),
      _ => throw TypeError(),
    };
  }).toList();
}

double calculateSectionalDensity(double weight, double diameter) =>
    weight / pow(diameter, 2) / 7000;

List<double> linearInterpolation(
  List<double> x,
  List<double> xp,
  List<double> yp,
) {
  if (xp.length != yp.length) throw ArgumentError('xp/yp length mismatch');
  if (xp.isEmpty) return x.isEmpty ? [] : throw ArgumentError('Empty reference points');

  return x.map((xi) {
    if (xi <= xp.first) return yp.first;
    if (xi >= xp.last)  return yp.last;

    int left = 0, right = xp.length - 1;
    while (left < right - 1) {
      final mid = (left + right) ~/ 2;
      if (xi < xp[mid]) { right = mid; } else { left = mid; }
    }

    final slope = (yp[right] - yp[left]) / (xp[right] - xp[left]);
    return yp[left] + slope * (xi - xp[left]);
  }).toList();
}

DragModel createDragModelMultiBC({
  required List<BCPoint> bcPoints,
  required dynamic       dragTable,
  Weight?   weight,
  Distance? diameter,
  Distance? length,
}) {
  final wObj = weight   ?? Weight(0, Unit.grain);
  final dObj = diameter ?? Distance(0, Unit.inch);

  final double bc = (wObj.rawValue > 0 && dObj.rawValue > 0)
      ? calculateSectionalDensity(wObj.in_(Unit.grain), dObj.in_(Unit.inch))
      : 1.0;

  final List<DragDataPoint> sourcePoints = (dragTable is DragTable)
      ? dragTable.points
      : makeDataPoints(dragTable as List);

  final sortedBCPoints = List<BCPoint>.from(bcPoints)
    ..sort((a, b) => a.mach.compareTo(b.mach));

  final bcFactors = linearInterpolation(
    sourcePoints.map((p) => p.mach).toList(),
    sortedBCPoints.map((p) => p.mach).toList(),
    sortedBCPoints.map((p) => p.bc / bc).toList(),
  );

  final adjustedTable = List<DragDataPoint>.generate(sourcePoints.length, (i) {
    final factor = bcFactors[i];
    return (
      mach: sourcePoints[i].mach,
      cd: factor > 0 ? sourcePoints[i].cd / factor : sourcePoints[i].cd,
    );
  });

  return DragModel(
    bc:        bc,
    dragTable: adjustedTable,
    weight:    wObj,
    diameter:  dObj,
    length:    length,
  );
}
