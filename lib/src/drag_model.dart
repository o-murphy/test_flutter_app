import 'dart:math';

import 'package:test_app/src/constants.dart';
import 'package:test_app/src/drag_tables.dart';
import 'package:test_app/src/unit.dart';

class BCPoint {
  final double bc;
  final double mach;
  final Velocity? v;

  BCPoint({required this.bc, double? mach, Object? v})
    : v = v != null ? PreferredUnits.velocity(v) : null,
      mach = _calculateMach(mach, v) {
    if (bc <= 0) {
      throw ArgumentError("Ballistic coefficient must be positive");
    }
    if (mach != null && v != null) {
      throw ArgumentError(
        "You cannot specify both 'mach' and 'v' at the same time",
      );
    }
    if (mach == null && v == null) {
      throw ArgumentError("One of 'mach' and 'v' must be specified");
    }
  }

  static double _calculateMach(double? mach, Object? v) {
    if (v != null) {
      final velocityObj = PreferredUnits.velocity(v);
      return velocityObj.in_(Unit.mps) / _machC();
    }
    return mach ?? 0.0;
  }

  static double _machC() {
    return sqrt(
          BallisticConstants.cStandardTemperatureC +
              BallisticConstants.cDegreesCtoK,
        ) *
        BallisticConstants.cSpeedOfSoundMetric;
  }
}

class DragModel {
  final double bc;
  final List<DragDataPoint> dragTable;
  final Weight weight;
  final Distance diameter;
  final Distance length;

  late final double sectionalDensity;
  late final double formFactor;

  DragModel({
    required this.bc,
    required List<dynamic> dragTable,
    Object? weight,
    Object? diameter,
    Object? length,
  }) : dragTable = makeDataPoints(dragTable),
       weight = PreferredUnits.weight(weight ?? 0),
       diameter = PreferredUnits.diameter(diameter ?? 0),
       length = PreferredUnits.length(length ?? 0) {
    if (this.dragTable.isEmpty) {
      throw ArgumentError("Received empty drag table");
    }
    if (bc <= 0) {
      throw ArgumentError("Ballistic coefficient must be positive");
    }

    if (this.weight.rawValue > 0 && this.diameter.rawValue > 0) {
      sectionalDensity = _getSectionalDensity();
      formFactor = _getFormFactor(bc);
    } else {
      sectionalDensity = 0.0;
      formFactor = 0.0;
    }
  }

  double _getSectionalDensity() {
    final w = weight.in_(Unit.grain);
    final d = diameter.in_(Unit.inch);
    return calculateSectionalDensity(w, d);
  }

  double _getFormFactor(double bcValue) {
    return sectionalDensity / bcValue;
  }
}

List<DragDataPoint> makeDataPoints(List<dynamic> table) {
  return table.map((point) {
    return switch (point) {
      DragDataPoint p => p,
      Map m
          when (m['mach'] ?? m['Mach']) != null &&
              (m['cd'] ?? m['CD']) != null =>
        (
          mach: ((m['mach'] ?? m['Mach']) as num).toDouble(),
          cd: ((m['cd'] ?? m['CD']) as num).toDouble(),
        ),
      _ => throw TypeError(),
    };
  }).toList();
}

double calculateSectionalDensity(double weight, double diameter) {
  return weight / pow(diameter, 2) / 7000;
}

List<double> linearInterpolation(
  List<double> x,
  List<double> xp,
  List<double> yp,
) {
  if (xp.length != yp.length) throw ArgumentError("xp/yp length mismatch");
  if (xp.isEmpty)
    return x.isEmpty ? [] : throw ArgumentError("Empty reference points");

  return x.map((xi) {
    if (xi <= xp.first) return yp.first;
    if (xi >= xp.last) return yp.last;

    int left = 0;
    int right = xp.length - 1;
    while (left < right - 1) {
      int mid = (left + right) ~/ 2;
      if (xi < xp[mid]) {
        right = mid;
      } else {
        left = mid;
      }
    }

    final double slope = (yp[right] - yp[left]) / (xp[right] - xp[left]);
    return yp[left] + slope * (xi - xp[left]);
  }).toList();
}

DragModel createDragModelMultiBC({
  required List<BCPoint> bcPoints,
  required dynamic dragTable,
  Object? weight,
  Object? diameter,
  Object? length,
}) {
  final wObj = PreferredUnits.weight(weight ?? 0);
  final dObj = PreferredUnits.diameter(diameter ?? 0);

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
      cd: (factor > 0) ? sourcePoints[i].cd / factor : sourcePoints[i].cd,
    );
  });

  return DragModel(
    bc: bc,
    dragTable: adjustedTable,
    weight: wObj,
    diameter: dObj,
    length: length,
  );
}
