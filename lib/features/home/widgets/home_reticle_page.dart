import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/models/app_settings.dart'
    show AdjustmentFormat;
import 'package:eballistica/features/home/home_vm.dart';
import 'package:eballistica/shared/models/adjustment_data.dart';

// ─── Page 1 — Reticle & Adjustments ──────────────────────────────────────────

class HomeReticlePage extends ConsumerWidget {
  const HomeReticlePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(homeVmProvider);
    final vmState = vmAsync.value;

    if (vmState is! HomeUiReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            vmState.cartridgeInfoLine,
            style: tt.labelMedium?.copyWith(color: cs.onSurface.withAlpha(160)),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: _ReticleView(cs: cs),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                  child: vmState.adjustment.elevation.isEmpty
                      ? Center(
                          child: Text('Enable units...', style: tt.bodySmall),
                        )
                      : _AdjPanel(
                          adjustment: vmState.adjustment,
                          fmt: vmState.adjustmentFormat,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Reticle view ─────────────────────────────────────────────────────────────

class _ReticleView extends StatelessWidget {
  const _ReticleView({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: CustomPaint(painter: _ReticlePainter(cs: cs)),
  );
}

class _ReticlePainter extends CustomPainter {
  const _ReticlePainter({required this.cs});
  final ColorScheme cs;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 4;

    final stroke = Paint()
      ..color = cs.onSurface.withAlpha(160)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(cx, cy), r, stroke);

    final gap = r * 0.09;
    canvas.drawLine(Offset(cx, cy - r + 2), Offset(cx, cy - gap), stroke);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + r - 2), stroke);
    canvas.drawLine(Offset(cx - r + 2, cy), Offset(cx - gap, cy), stroke);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + r - 2, cy), stroke);

    final tickPaint = Paint()
      ..color = cs.onSurface.withAlpha(90)
      ..strokeWidth = 0.8;
    for (final frac in [0.25, 0.5, 0.75]) {
      final halfTick = r * 0.055;
      final yU = cy - r * frac;
      final yD = cy + r * frac;
      final xL = cx - r * frac;
      final xR = cx + r * frac;
      canvas.drawLine(
        Offset(cx - halfTick, yU),
        Offset(cx + halfTick, yU),
        tickPaint,
      );
      canvas.drawLine(
        Offset(cx - halfTick, yD),
        Offset(cx + halfTick, yD),
        tickPaint,
      );
      canvas.drawLine(
        Offset(xL, cy - halfTick),
        Offset(xL, cy + halfTick),
        tickPaint,
      );
      canvas.drawLine(
        Offset(xR, cy - halfTick),
        Offset(xR, cy + halfTick),
        tickPaint,
      );
    }

    canvas.drawCircle(
      Offset(cx, cy),
      2.5,
      Paint()
        ..color = cs.primary
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_ReticlePainter old) => old.cs != cs;
}

// ─── Adjustment panel ─────────────────────────────────────────────────────────

class _AdjPanel extends StatelessWidget {
  const _AdjPanel({required this.adjustment, required this.fmt});

  final AdjustmentData adjustment;
  final AdjustmentFormat fmt;

  String _elevDir() {
    if (adjustment.elevation.isEmpty) return '';
    final pos = adjustment.elevation.first.isPositive;
    return switch (fmt) {
      AdjustmentFormat.arrows => pos ? '↑' : '↓',
      AdjustmentFormat.signs => pos ? '+' : '−',
      AdjustmentFormat.letters => pos ? 'U' : 'D',
    };
  }

  String _windDir() {
    if (adjustment.windage.isEmpty) return '';
    final pos = adjustment.windage.first.isPositive;
    return switch (fmt) {
      AdjustmentFormat.arrows => pos ? '→' : '←',
      AdjustmentFormat.signs => pos ? '+' : '−',
      AdjustmentFormat.letters => pos ? 'R' : 'L',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final headerStyle = tt.labelMedium!.copyWith(
      color: cs.onSurface.withAlpha(180),
      fontWeight: FontWeight.w600,
    );
    final dirStyle = tt.titleSmall!.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
    );
    final valStyle = tt.bodyMedium!.copyWith(fontWeight: FontWeight.w700);
    final unitStyle = tt.bodySmall!.copyWith(
      color: cs.onSurface.withAlpha(140),
    );

    Widget valueRow(AdjustmentValue v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Required min for correct BoxFit
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(v.absValue.toStringAsFixed(v.decimals), style: valStyle),
          const SizedBox(width: 4),
          Text(v.symbol, style: unitStyle),
        ],
      ),
    );

    Widget sectionHeader(String label, String dir) => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(label, style: headerStyle),
        if (dir.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(dir, style: dirStyle),
        ],
      ],
    );

    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      child: IntrinsicWidth(
        child: Column(
          // stretch forces the children (including the SizedBox with Divider)
          // to take up the full width calculated by IntrinsicWidth
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            sectionHeader('Drop', _elevDir()),
            const SizedBox(height: 2),
            ...adjustment.elevation.map(valueRow),

            // Wrapper container for adaptive width Divider
            const SizedBox(
              width: double.infinity,
              child: Divider(height: 16, thickness: 1, indent: 0, endIndent: 0),
            ),

            sectionHeader('Windage', _windDir()),
            const SizedBox(height: 2),
            ...adjustment.windage.map(valueRow),
          ],
        ),
      ),
    );
  }
}
