import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:test_app/src/solver/trajectory_data.dart';
import 'package:test_app/src/solver/unit.dart';

const _ftToM   = 1.0 / 3.28084;
const _ftToCm  = 30.48;
const _fpsToms = 1.0 / 3.28084;

class TrajectoryChart extends StatelessWidget {
  final List<TrajectoryData> traj;

  const TrajectoryChart({super.key, required this.traj});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CustomPaint(
        painter: _ChartPainter(
          traj:        traj,
          heightColor: cs.primary,
          velColor:    Colors.green.shade600,
          gridColor:   cs.outlineVariant,
          textColor:   cs.onSurface,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<TrajectoryData> traj;
  final Color heightColor, velColor, gridColor, textColor;

  static const _ml = 52.0, _mr = 56.0, _mt = 20.0, _mb = 36.0;

  _ChartPainter({
    required this.traj,
    required this.heightColor,
    required this.velColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pw = size.width  - _ml - _mr;
    final ph = size.height - _mt - _mb;

    final heights = traj.map((r) => r.height.in_(Unit.foot) * _ftToCm).toList();
    final vels    = traj.map((r) => r.velocity.in_(Unit.fps) * _fpsToms).toList();
    final dists   = traj.map((r) => r.distance.in_(Unit.foot) * _ftToM).toList();

    final xMin = dists.first, xMax = dists.last;
    final yHMin = (heights.reduce(math.min) * 1.1).floorToDouble();
    final yHMax = (heights.reduce(math.max) * 1.1).ceilToDouble();
    final yVMax = (vels.reduce(math.max) * 1.05).ceilToDouble();

    double px(double d)  => _ml + (d - xMin) / (xMax - xMin) * pw;
    double pyH(double h) => _mt + (1 - (h - yHMin) / (yHMax - yHMin)) * ph;
    double pyV(double v) => _mt + (1 - v / yVMax) * ph;

    final gridP = Paint()..color = gridColor..strokeWidth = 0.5;
    final ts  = TextStyle(fontSize: 9, color: textColor.withAlpha(180));
    final tsR = TextStyle(fontSize: 9, color: velColor.withAlpha(200));

    // Grid X (every 100 m)
    for (var d = xMin; d <= xMax + 0.1; d += 100) {
      final x = px(d);
      canvas.drawLine(Offset(x, _mt), Offset(x, _mt + ph), gridP);
      _text(canvas, '${d.toInt()}', Offset(x, _mt + ph + 3), ts, center: true);
    }

    // Grid Y left (height)
    final hStep = _niceStep(yHMax - yHMin, 5);
    for (var h = (yHMin / hStep).ceil() * hStep; h <= yHMax + 0.01; h += hStep) {
      final y = pyH(h);
      canvas.drawLine(Offset(_ml, y), Offset(_ml + pw, y), gridP);
      _text(canvas, h.toStringAsFixed(0), Offset(2, y - 5), ts);
    }

    // Grid Y right (velocity)
    final vStep = _niceStep(yVMax, 5);
    for (var v = 0.0; v <= yVMax + 0.01; v += vStep) {
      _text(canvas, v.toStringAsFixed(0), Offset(_ml + pw + 3, pyV(v) - 5), tsR);
    }

    // Zero reference line
    canvas.drawLine(
      Offset(_ml, pyH(0)), Offset(_ml + pw, pyH(0)),
      Paint()
        ..color = Colors.orange.shade400
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Velocity line (dashed)
    _drawLine(canvas, dists, vels, px, pyV, velColor, 1.5, dashed: true);

    // Height line (solid, on top)
    _drawLine(canvas, dists, heights, px, pyH, heightColor, 2.0);

    // Border
    canvas.drawRect(
      Rect.fromLTWH(_ml, _mt, pw, ph),
      Paint()..color = textColor.withAlpha(80)..style = PaintingStyle.stroke..strokeWidth = 1,
    );

    // Axis labels
    _text(canvas, 'Distance (m)', Offset(_ml + pw / 2, size.height - 2),
        TextStyle(fontSize: 10, color: textColor), center: true);
    _textRotated(canvas, 'Height (cm)',
        Offset(10, _mt + ph / 2), TextStyle(fontSize: 10, color: heightColor));
    _textRotated(canvas, 'Velocity (m/s)',
        Offset(size.width - 10, _mt + ph / 2), TextStyle(fontSize: 10, color: velColor),
        rightAligned: true);

    // Legend
    _drawLegendItem(canvas, Offset(_ml + 8,   _mt + 8), heightColor,          'Height');
    _drawLegendItem(canvas, Offset(_ml + 80,  _mt + 8), velColor,              'Velocity', dashed: true);
    _drawLegendItem(canvas, Offset(_ml + 160, _mt + 8), Colors.orange.shade400,'Zero line');
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
      const gapLen  = 5.0;
      bool drawing = true;
      double remaining = dashLen;
      for (var i = 0; i < xs.length - 1; i++) {
        var a = Offset(px(xs[i]), py(ys[i]));
        final b = Offset(px(xs[i + 1]), py(ys[i + 1]));
        var seg = (b - a).distance;
        while (seg > 0) {
          final step = math.min(seg, remaining);
          final frac = step / seg;
          final c = Offset(a.dx + (b.dx - a.dx) * frac, a.dy + (b.dy - a.dy) * frac);
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

  void _drawLegendItem(Canvas canvas, Offset pos, Color color, String label,
      {bool dashed = false}) {
    canvas.drawLine(
      pos, pos.translate(24, 0),
      Paint()..color = color..strokeWidth = dashed ? 1.5 : 2.0..style = PaintingStyle.stroke,
    );
    _text(canvas, label, pos.translate(28, -5), TextStyle(fontSize: 9, color: color));
  }

  void _text(Canvas c, String t, Offset o, TextStyle s, {bool center = false}) {
    final tp = TextPainter(
        text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, center ? o.translate(-tp.width / 2, 0) : o);
  }

  void _textRotated(Canvas c, String t, Offset center, TextStyle s,
      {bool rightAligned = false}) {
    final tp = TextPainter(
        text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)
      ..layout();
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(rightAligned ? math.pi / 2 : -math.pi / 2);
    tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
    c.restore();
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
  bool shouldRepaint(covariant _ChartPainter old) => old.traj != traj;
}
