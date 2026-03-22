import 'dart:math';
import 'package:flutter/material.dart';

class WindIndicator extends StatefulWidget {
  final double initialAngle;
  final Function(double, String) onAngleChanged;

  const WindIndicator({
    super.key,
    this.initialAngle = -pi / 2,
    required this.onAngleChanged,
  });

  @override
  State<WindIndicator> createState() => _WindIndicatorState();
}

class _WindIndicatorState extends State<WindIndicator> {
  late double angle;

  @override
  void initState() {
    super.initState();
    angle = widget.initialAngle;
  }

  // Updates local visual state only — does NOT notify parent.
  void _updateAngle(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rawAngle = atan2(localPosition.dy - center.dy, localPosition.dx - center.dx);
    double degrees = (rawAngle * 180 / pi + 90) % 360;
    if (degrees < 0) degrees += 360;
    setState(() {
      angle = (degrees.roundToDouble() - 90) * pi / 180;
    });
  }

  // Commits the current angle to the parent (called on gesture end / tap).
  void _commit() {
    double degrees = (angle * 180 / pi + 90) % 360;
    if (degrees < 0) degrees += 360;
    degrees = degrees.roundToDouble();
    final totalMin = (degrees * 2).round();
    int hour = (totalMin ~/ 60) % 12;
    if (hour == 0) hour = 12;
    final minute = totalMin % 60;
    final clockFormat = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    widget.onAngleChanged(degrees, clockFormat);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanUpdate: (details) => _updateAngle(details.localPosition, size),
          onPanEnd:    (_)       => _commit(),
          onTapDown:   (details) { _updateAngle(details.localPosition, size); _commit(); },
          child: CustomPaint(
            painter: WindPainter(
              angle: angle,
              color: Theme.of(context).colorScheme.onSurface,
              primaryColor: Theme.of(context).colorScheme.primary,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class WindPainter extends CustomPainter {
  final double angle;
  final Color color;
  final Color primaryColor;

  WindPainter({
    required this.angle,
    required this.color,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.5;
    final innerRadius = radius * 0.8;

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = color.withOpacity(0.05),
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 12; i++) {
      double hourAngle = (i * 30 - 90) * pi / 180;

      final tickStart = Offset(
        center.dx + innerRadius * cos(hourAngle),
        center.dy + innerRadius * sin(hourAngle),
      );
      final tickEnd = Offset(
        center.dx + (innerRadius - 10) * cos(hourAngle),
        center.dy + (innerRadius - 10) * sin(hourAngle),
      );
      canvas.drawLine(
        tickStart,
        tickEnd,
        Paint()
          ..color = color.withOpacity(0.5)
          ..strokeWidth = 2,
      );

      if (i % 3 != 0) continue;
      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      final textPos = Offset(
        center.dx + (innerRadius - 25) * cos(hourAngle) - textPainter.width / 2,
        center.dy +
            (innerRadius - 25) * sin(hourAngle) -
            textPainter.height / 2,
      );
      textPainter.paint(canvas, textPos);
    }

    const markerR = 16.0;
    const markerOver = 6.0;
    final markerCenter = Offset(
      center.dx + (radius - markerR + markerOver) * cos(angle),
      center.dy + (radius - markerR + markerOver) * sin(angle),
    );

    final fx = -cos(angle);
    final fy = -sin(angle);
    final rx = -sin(angle);
    final ry = cos(angle);

    const stemW = 4.0;
    const headW = 11.0;
    const totalL = 45.0;
    const headL = 14.0;

    final bx = markerCenter.dx;
    final by = markerCenter.dy;
    final mx = bx + fx * (totalL - headL);
    final my = by + fy * (totalL - headL);
    final tx = bx + fx * totalL;
    final ty = by + fy * totalL;

    final arrowPath = Path()
      ..moveTo(bx + rx * stemW, by + ry * stemW)
      ..lineTo(mx + rx * stemW, my + ry * stemW)
      ..lineTo(mx + rx * headW, my + ry * headW)
      ..lineTo(tx, ty)
      ..lineTo(mx - rx * headW, my - ry * headW)
      ..lineTo(mx - rx * stemW, my - ry * stemW)
      ..lineTo(bx - rx * stemW, by - ry * stemW)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      markerCenter,
      markerR + 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(markerCenter, markerR, Paint()..color = primaryColor);

    final iconTp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.fingerprint.codePoint),
        style: TextStyle(
          fontFamily: Icons.fingerprint.fontFamily,
          fontSize: markerR * 1.2,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconTp.paint(
      canvas,
      Offset(
        markerCenter.dx - iconTp.width / 2,
        markerCenter.dy - iconTp.height / 2,
      ),
    );

    double degrees = (angle * 180 / pi + 90) % 360;
    if (degrees < 0) degrees += 360;

    final totalMin = (degrees * 2).round();
    int hour = (totalMin ~/ 60) % 12;
    if (hour == 0) hour = 12;
    final minute = totalMin % 60;
    final clockStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    textPainter.text = TextSpan(
      text: 'Wind direction',
      style: TextStyle(color: color.withValues(alpha: 0.55), fontSize: 11),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - 28,
      ),
    );

    textPainter.text = TextSpan(
      text: '${degrees.toStringAsFixed(0)}°',
      style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    textPainter.text = TextSpan(
      text: clockStr,
      style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 + 28,
      ),
    );
  }

  @override
  bool shouldRepaint(WindPainter oldDelegate) => true;
}
