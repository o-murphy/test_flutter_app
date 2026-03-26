import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:eballistica/shared/models/chart_point.dart';

class TrajectoryChart extends StatelessWidget {
  final List<ChartPoint> points;
  final int? selectedIndex;
  final ValueChanged<int>? onIndexSelected;
  final double snapDistM;
  final bool showSubsonicLine;

  const TrajectoryChart({
    super.key,
    required this.points,
    this.selectedIndex,
    this.onIndexSelected,
    this.snapDistM = 1.0,
    this.showSubsonicLine = false,
  });

  int _tapToIndex(double tapX, double paintWidth) {
    const ml = _ChartPainter._ml;
    const mr = _ChartPainter._mr;
    final pw = paintWidth - ml - mr;
    if (pw <= 0) return 0;
    final dists = points.map((p) => p.distanceM).toList();
    final xMin = dists.first, xMax = dists.last;
    final rawD = xMin + ((tapX - ml).clamp(0.0, pw)) / pw * (xMax - xMin);
    // Snap to nearest snapDistM interval.
    final snap = snapDistM > 0 ? snapDistM : 1.0;
    final targetD = (rawD / snap).round() * snap;
    var best = 0;
    var bestDiff = double.infinity;
    for (var i = 0; i < dists.length; i++) {
      final d = (dists[i] - targetD).abs();
      if (d < bestDiff) {
        bestDiff = d;
        best = i;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onTapDown: onIndexSelected == null
              ? null
              : (d) => onIndexSelected!(
                  _tapToIndex(d.localPosition.dx, constraints.maxWidth),
                ),
          onPanUpdate: onIndexSelected == null
              ? null
              : (d) => onIndexSelected!(
                  _tapToIndex(d.localPosition.dx, constraints.maxWidth),
                ),
          child: CustomPaint(
            painter: _ChartPainter(
              points: points,
              selectedIndex: selectedIndex,
              heightColor: cs.primary,
              velColor: Colors.green.shade600,
              gridColor: cs.outlineVariant,
              textColor: cs.onSurface,
              selectedColor: cs.tertiary,
              subsonicLineColor: showSubsonicLine ? cs.tertiary : null,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final int? selectedIndex;
  final Color heightColor, velColor, gridColor, textColor, selectedColor;
  final Color? subsonicLineColor;

  static const _ml = 28.0, _mr = 24.0, _mt = 16.0, _mb = 14.0;

  _ChartPainter({
    required this.points,
    this.selectedIndex,
    required this.heightColor,
    required this.velColor,
    required this.gridColor,
    required this.textColor,
    required this.selectedColor,
    this.subsonicLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pw = size.width - _ml - _mr;
    final ph = size.height - _mt - _mb;

    final heights = points.map((p) => p.heightCm).toList();
    final vels = points.map((p) => p.velocityMps).toList();
    final dists = points.map((p) => p.distanceM).toList();

    final xMin = dists.first, xMax = dists.last;
    final yHMin = (heights.reduce(math.min) * 1.1).floorToDouble();
    final yHMax = (heights.reduce(math.max) * 1.1).ceilToDouble();
    final yVMin = (vels.reduce(math.min) * 0.95).floorToDouble();
    final yVMax = (vels.reduce(math.max) * 1.05).ceilToDouble();

    double px(double d) => _ml + (d - xMin) / (xMax - xMin) * pw;
    double pyH(double h) => _mt + (1 - (h - yHMin) / (yHMax - yHMin)) * ph;
    double pyV(double v) => _mt + (1 - (v - yVMin) / (yVMax - yVMin)) * ph;

    final gridP = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    final ts = TextStyle(fontSize: 9, color: textColor.withAlpha(180));
    final tsR = TextStyle(fontSize: 9, color: velColor.withAlpha(200));

    // Grid X (every 100 m)
    for (var d = xMin; d <= xMax + 0.1; d += 100) {
      final x = px(d);
      canvas.drawLine(Offset(x, _mt), Offset(x, _mt + ph), gridP);
      _text(canvas, '${d.toInt()}', Offset(x, _mt + ph + 3), ts, center: true);
    }

    // Grid Y left (height)
    final hStep = _niceStep(yHMax - yHMin, 5);
    for (
      var h = (yHMin / hStep).ceil() * hStep;
      h <= yHMax + 0.01;
      h += hStep
    ) {
      final y = pyH(h);
      canvas.drawLine(Offset(_ml, y), Offset(_ml + pw, y), gridP);
      _text(canvas, h.toStringAsFixed(0), Offset(_ml - 4, y - 5), ts, rightAlign: true);
    }

    // Grid Y right (velocity)
    final vStep = _niceStep(yVMax - yVMin, 5);
    for (var v = (yVMin / vStep).ceil() * vStep; v <= yVMax + 0.01; v += vStep) {
      _text(
        canvas,
        v.toStringAsFixed(0),
        Offset(_ml + pw + 3, pyV(v) - 5),
        tsR,
      );
    }

    // Velocity line (dashed)
    _drawLine(canvas, dists, vels, px, pyV, velColor, 1.5, dashed: true);

    // Height line (solid, on top)
    _drawLine(canvas, dists, heights, px, pyH, heightColor, 2.0);

    // Subsonic transition — vertical dashed line at first subsonic point
    if (subsonicLineColor != null) {
      final subIdx = points.indexWhere((p) => p.isSubsonic);
      if (subIdx >= 0) {
        final sx = px(dists[subIdx]);
        _drawLine(
          canvas,
          [sx, sx],
          [_mt, _mt + ph],
          (v) => v,
          (v) => v,
          subsonicLineColor!,
          1.0,
          dashed: true,
        );
      }
    }

    // Selected point highlight
    if (selectedIndex != null && points.isNotEmpty) {
      final si = selectedIndex!.clamp(0, points.length - 1);
      final sx = px(dists[si]);
      final syH = pyH(heights[si]);
      final syV = pyV(vels[si]);

      // Vertical guide line
      canvas.drawLine(
        Offset(sx, _mt),
        Offset(sx, _mt + ph),
        Paint()
          ..color = selectedColor.withAlpha(90)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );

      // Dot on height curve
      canvas.drawCircle(Offset(sx, syH), 5.0, Paint()..color = selectedColor);
      canvas.drawCircle(
        Offset(sx, syH),
        3.0,
        Paint()..color = Colors.white.withAlpha(200),
      );

      // Dot on velocity curve
      canvas.drawCircle(Offset(sx, syV), 5.0, Paint()..color = selectedColor);
      canvas.drawCircle(
        Offset(sx, syV),
        3.0,
        Paint()..color = Colors.white.withAlpha(200),
      );
    }

    // Border
    canvas.drawRect(
      Rect.fromLTWH(_ml, _mt, pw, ph),
      Paint()
        ..color = textColor.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );


    // Legend — above the grid in the top margin
    _drawLegendItem(canvas, Offset(_ml + 8, 2), heightColor, 'Height');
    _drawLegendItem(
      canvas,
      Offset(_ml + 80, 2),
      velColor,
      'Velocity',
      dashed: true,
    );
  }

  void _drawLine(
    Canvas canvas,
    List<double> xs,
    List<double> ys,
    double Function(double) px,
    double Function(double) py,
    Color color,
    double width, {
    bool dashed = false,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    if (!dashed) {
      final path = Path();
      for (var i = 0; i < xs.length; i++) {
        final p = Offset(px(xs[i]), py(ys[i]));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    } else {
      const dashLen = 8.0;
      const gapLen = 5.0;
      bool drawing = true;
      double remaining = dashLen;
      for (var i = 0; i < xs.length - 1; i++) {
        var a = Offset(px(xs[i]), py(ys[i]));
        final b = Offset(px(xs[i + 1]), py(ys[i + 1]));
        var seg = (b - a).distance;
        while (seg > 0) {
          final step = math.min(seg, remaining);
          final frac = step / seg;
          final c = Offset(
            a.dx + (b.dx - a.dx) * frac,
            a.dy + (b.dy - a.dy) * frac,
          );
          if (drawing) canvas.drawLine(a, c, paint);
          remaining -= step;
          seg -= step;
          a = c;
          if (remaining <= 0) {
            drawing = !drawing;
            remaining = drawing ? dashLen : gapLen;
          }
        }
      }
    }
  }

  void _drawLegendItem(
    Canvas canvas,
    Offset pos,
    Color color,
    String label, {
    bool dashed = false,
  }) {
    canvas.drawLine(
      pos,
      pos.translate(24, 0),
      Paint()
        ..color = color
        ..strokeWidth = dashed ? 1.5 : 2.0
        ..style = PaintingStyle.stroke,
    );
    _text(
      canvas,
      label,
      pos.translate(28, -5),
      TextStyle(fontSize: 9, color: color),
    );
  }

  void _text(Canvas c, String t, Offset o, TextStyle s,
      {bool center = false, bool rightAlign = false}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: s),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? -tp.width / 2 : (rightAlign ? -tp.width : 0.0);
    tp.paint(c, o.translate(dx, 0));
  }

  double _niceStep(double range, int targetSteps) {
    final rough = range / targetSteps;
    final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor());
    final normalized = rough / magnitude;
    late double nice;
    if (normalized <= 1) {
      nice = 1;
    } else if (normalized <= 2) {
      nice = 2;
    } else if (normalized <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude.toDouble();
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.points != points ||
      old.selectedIndex != selectedIndex ||
      old.subsonicLineColor != subsonicLineColor;
}
