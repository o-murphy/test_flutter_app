import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calculation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../src/models/app_settings.dart';
import '../src/models/field_constraints.dart';
import '../src/models/projectile.dart' show DragModelType;
import '../src/solver/unit.dart';

// ─── Page 1 — Reticle & Adjustments ──────────────────────────────────────────

class HomeReticlePage extends ConsumerWidget {
  const HomeReticlePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final units    = ref.watch(unitSettingsProvider);
    final calc     = ref.watch(homeCalculationProvider);
    final profile  = ref.watch(shotProfileProvider).value;

    final hit       = calc.value;
    final traj      = hit?.trajectory ?? [];
    final targetM   = (profile?.targetDistance as dynamic)?.in_(Unit.meter) as double? ?? 300.0;
    final point     = (hit != null && traj.isNotEmpty)
        ? hit.getAtDistance(Distance(targetM, Unit.meter))
        : null;

    final elevAngle = hit?.shot.relativeAngle;
    final windAngle = point?.windageAngle;

    final dispUnits = <(Unit, String)>[
      if (settings.showMrad) (Unit.mRad, 'MRAD'),
      if (settings.showMoa)  (Unit.moa,  'MOA'),
      if (settings.showMil)  (Unit.mil,  'MIL'),
      if (settings.showCmPer100m)   (Unit.cmPer100m,      'cm/100m'),
      if (settings.showInPer100yd)  (Unit.inchesPer100Yd, 'in/100yd'),
    ];

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final proj   = profile?.cartridge.projectile;
    final mvDisp = profile != null
        ? (profile.cartridge.mv as dynamic).in_(units.velocity) as double
        : null;
    final mvStr  = mvDisp != null
        ? '${mvDisp.toStringAsFixed(FC.muzzleVelocity.accuracyFor(units.velocity))} ${units.velocity.symbol}'
        : '—';
    final bcAcc  = FC.ballisticCoefficient.accuracy;
    final dragStr = switch (proj?.dragType) {
      DragModelType.g1     => 'G1 ${proj!.dm.bc.toStringAsFixed(bcAcc)}',
      DragModelType.g7     => 'G7 ${proj!.dm.bc.toStringAsFixed(bcAcc)}',
      DragModelType.custom => 'Custom',
      null                 => '—',
    };
    // Gyroscopic stability factor Sg (Miller)
    String? sgStr;
    if (proj != null && profile != null) {
      final twistInch  = (profile.rifle.weapon.twist as dynamic).in_(Unit.inch) as double;
      final weightGr   = (proj.dm.weight   as dynamic).in_(Unit.grain) as double;
      final diamInch   = (proj.dm.diameter as dynamic).in_(Unit.inch)  as double;
      final lenInch    = (proj.dm.length   as dynamic).in_(Unit.inch)  as double;
      if (weightGr > 0 && diamInch > 0 && lenInch > 0 && twistInch > 0) {
        final lCal = lenInch / diamInch;
        final nCal = twistInch / diamInch;
        final sg = (30.0 * weightGr) /
            (nCal * nCal * diamInch * diamInch * diamInch * lCal * (1.0 + lCal * lCal));
        sgStr = 'Sg ${sg.toStringAsFixed(2)}';
      }
    }
    final cartridgeLabel = proj != null
        ? '${proj.name};  $mvStr;  $dragStr${sgStr != null ? ';  $sgStr' : ''}'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            cartridgeLabel,
            style: tt.labelMedium?.copyWith(color: cs.onSurface.withAlpha(160)),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Row(
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
                  child: dispUnits.isEmpty
                      ? Center(
                          child: Text(
                            'Enable units in\nSettings → Adjustment Display',
                            textAlign: TextAlign.center,
                            style: tt.bodySmall,
                          ),
                        )
                      : _AdjPanel(
                          dispUnits: dispUnits,
                          elevAngle: elevAngle,
                          windAngle: windAngle,
                          fmt: settings.adjustmentFormat,
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
  Widget build(BuildContext context) =>
      AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _ReticlePainter(cs: cs)));
}

class _ReticlePainter extends CustomPainter {
  const _ReticlePainter({required this.cs});
  final ColorScheme cs;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = math.min(cx, cy) - 4;

    final stroke = Paint()
      ..color       = cs.onSurface.withAlpha(160)
      ..strokeWidth = 1.2
      ..style       = PaintingStyle.stroke;

    canvas.drawCircle(Offset(cx, cy), r, stroke);

    final gap = r * 0.09;
    canvas.drawLine(Offset(cx, cy - r + 2), Offset(cx, cy - gap), stroke);
    canvas.drawLine(Offset(cx, cy + gap),   Offset(cx, cy + r - 2), stroke);
    canvas.drawLine(Offset(cx - r + 2, cy), Offset(cx - gap, cy), stroke);
    canvas.drawLine(Offset(cx + gap, cy),   Offset(cx + r - 2, cy), stroke);

    final tickPaint = Paint()
      ..color       = cs.onSurface.withAlpha(90)
      ..strokeWidth = 0.8;
    for (final frac in [0.25, 0.5, 0.75]) {
      final halfTick = r * 0.055;
      final yU = cy - r * frac;
      final yD = cy + r * frac;
      final xL = cx - r * frac;
      final xR = cx + r * frac;
      canvas.drawLine(Offset(cx - halfTick, yU), Offset(cx + halfTick, yU), tickPaint);
      canvas.drawLine(Offset(cx - halfTick, yD), Offset(cx + halfTick, yD), tickPaint);
      canvas.drawLine(Offset(xL, cy - halfTick), Offset(xL, cy + halfTick), tickPaint);
      canvas.drawLine(Offset(xR, cy - halfTick), Offset(xR, cy + halfTick), tickPaint);
    }

    canvas.drawCircle(
      Offset(cx, cy), 2.5,
      Paint()..color = cs.primary..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_ReticlePainter old) => old.cs != cs;
}

// ─── Adjustment panel ─────────────────────────────────────────────────────────

class _AdjPanel extends StatelessWidget {
  const _AdjPanel({
    required this.dispUnits,
    required this.elevAngle,
    required this.windAngle,
    required this.fmt,
  });

  final List<(Unit, String)> dispUnits;
  final Angular?             elevAngle;
  final Angular?             windAngle;
  final AdjustmentFormat     fmt;

  String _elevDir() {
    if (elevAngle == null) return '';
    final v = (elevAngle! as dynamic).in_(Unit.mRad) as double;
    return switch (fmt) {
      AdjustmentFormat.arrows  => v >= 0 ? '↑' : '↓',
      AdjustmentFormat.signs   => v >= 0 ? '+' : '−',
      AdjustmentFormat.letters => v >= 0 ? 'U' : 'D',
    };
  }

  String _windDir() {
    if (windAngle == null) return '';
    final corr = -((windAngle! as dynamic).in_(Unit.mRad) as double);
    return switch (fmt) {
      AdjustmentFormat.arrows  => corr >= 0 ? '→' : '←',
      AdjustmentFormat.signs   => corr >= 0 ? '+' : '−',
      AdjustmentFormat.letters => corr >= 0 ? 'R' : 'L',
    };
  }

  String _elevVal(Unit unit) {
    if (elevAngle == null) return '—';
    return ((elevAngle! as dynamic).in_(unit) as double).abs().toStringAsFixed(unit.accuracy);
  }

  String _windVal(Unit unit) {
    if (windAngle == null) return '—';
    return ((windAngle! as dynamic).in_(unit) as double).abs().toStringAsFixed(unit.accuracy);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final headerStyle = tt.labelMedium!.copyWith(color: cs.onSurface.withAlpha(180), fontWeight: FontWeight.w600);
    final dirStyle    = tt.titleSmall!.copyWith(color: cs.primary, fontWeight: FontWeight.w700);
    final valStyle    = tt.bodyMedium!.copyWith(fontWeight: FontWeight.w700);
    final unitStyle   = tt.bodySmall!.copyWith(color: cs.onSurface.withAlpha(140));

    Widget valueRow(String val, String unitLabel) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(val, style: valStyle),
          const SizedBox(width: 4),
          Text(unitLabel, style: unitStyle),
        ],
      ),
    );

    Widget sectionHeader(String label, String dir) => Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(label, style: headerStyle),
        if (dir.isNotEmpty) ...[const SizedBox(width: 6), Text(dir, style: dirStyle)],
      ],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          sectionHeader('Drop', _elevDir()),
          const SizedBox(height: 2),
          ...dispUnits.map((u) => valueRow(_elevVal(u.$1), u.$2)),
          const Divider(height: 16),
          sectionHeader('Windage', _windDir()),
          const SizedBox(height: 2),
          ...dispUnits.map((u) => valueRow(_windVal(u.$1), u.$2)),
        ],
      ),
    );
  }
}
