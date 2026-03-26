import 'dart:math';
import 'package:flutter/material.dart';

class WindIndicator extends StatefulWidget {
  final double initialAngle;
  final Function(double, String) onAngleChanged;
  /// Called when the user taps the center degree label. Receives current degrees (0-360).
  final void Function(double degrees)? onDirectionTap;

  const WindIndicator({
    super.key,
    this.initialAngle = -pi / 2,
    required this.onAngleChanged,
    this.onDirectionTap,
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

  @override
  void didUpdateWidget(WindIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAngle != widget.initialAngle) {
      setState(() => angle = widget.initialAngle);
    }
  }

  // Updates local visual state only — does NOT notify parent.
  void _updateAngle(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rawAngle = atan2(
      localPosition.dy - center.dy,
      localPosition.dx - center.dx,
    );
    double degrees = (rawAngle * 180 / pi + 90) % 360;
    if (degrees < 0) degrees += 360;
    setState(() {
      angle = (degrees.roundToDouble() - 90) * pi / 180;
    });
  }

  void _reset() {
    setState(() => angle = -pi / 2); // 12 o'clock = 0°
    _commit();
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
    final clockFormat =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    widget.onAngleChanged(degrees, clockFormat);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onDoubleTap: _reset,
          onPanUpdate: (details) => _updateAngle(details.localPosition, size),
          onPanEnd: (_) => _commit(),
          onTapUp: (_) => _commit(),
          onTapDown: (details) {
            final center = Offset(size.width / 2, size.height / 2);
            final dist = (details.localPosition - center).distance;
            final innerR = min(size.width, size.height) * 0.5 * 0.8;
            if (dist < innerR * 0.4 && widget.onDirectionTap != null) {
              double deg = (angle * 180 / pi + 90) % 360;
              if (deg < 0) deg += 360;
              widget.onDirectionTap!(deg.roundToDouble());
            } else {
              _updateAngle(details.localPosition, size);
              // Don't commit on tap down - only commit on pan end or center tap
            }
          },
          child: CustomPaint(
            painter: WindPainter(
              angle: angle,
              color: Theme.of(context).colorScheme.onSurface,
              primaryColor: Theme.of(context).colorScheme.primary,
              markerFillColor: Theme.of(context).colorScheme.primaryContainer,
              markerIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
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
  final Color markerFillColor;
  final Color markerIconColor;

  WindPainter({
    required this.angle,
    required this.color,
    required this.primaryColor,
    required this.markerFillColor,
    required this.markerIconColor,
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
      Paint()..color = color.withValues(alpha: 0.05),
    );

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
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 2,
      );

      if (i % 3 != 0) continue;
      final hourTextPainter = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final textPos = Offset(
        center.dx + (innerRadius - 25) * cos(hourAngle) - hourTextPainter.width / 2,
        center.dy +
            (innerRadius - 25) * sin(hourAngle) -
            hourTextPainter.height / 2,
      );
      hourTextPainter.paint(canvas, textPos);
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
        ..color = markerFillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      markerCenter,
      markerR + 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(markerCenter, markerR, Paint()..color = markerFillColor);
    canvas.drawCircle(
      markerCenter,
      markerR,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final iconTp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.fingerprint.codePoint),
        style: TextStyle(
          fontFamily: Icons.fingerprint.fontFamily,
          fontSize: markerR * 1.2,
          color: markerIconColor,
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

    final directionTextPainter = TextPainter(
      text: TextSpan(
        text: 'Wind direction',
        style: TextStyle(color: color.withValues(alpha: 0.55), fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    directionTextPainter.paint(
      canvas,
      Offset(
        center.dx - directionTextPainter.width / 2,
        center.dy - directionTextPainter.height / 2 - 28,
      ),
    );

    final degreesTextPainter = TextPainter(
      text: TextSpan(
        text: '${degrees.toStringAsFixed(0)}°',
        style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    degreesTextPainter.paint(
      canvas,
      Offset(
        center.dx - degreesTextPainter.width / 2,
        center.dy - degreesTextPainter.height / 2,
      ),
    );

    final clockTextPainter = TextPainter(
      text: TextSpan(
        text: clockStr,
        style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    clockTextPainter.paint(
      canvas,
      Offset(
        center.dx - clockTextPainter.width / 2,
        center.dy - clockTextPainter.height / 2 + 28,
      ),
    );
  }

  @override
  bool shouldRepaint(WindPainter oldDelegate) => true;
}
