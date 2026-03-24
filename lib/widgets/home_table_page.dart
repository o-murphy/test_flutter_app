import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/dimension_converter.dart';
import '../providers/calculation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../src/models/app_settings.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/trajectory_data.dart';
import '../src/solver/unit.dart';

// ─── Page 2 — Compact Adjustment Tables ──────────────────────────────────────

class HomeTablePage extends ConsumerWidget {
  const HomeTablePage({super.key});

  double _conv(dynamic dim, Unit raw, Unit disp) {
    return valueInUnit(convertDimension(dim, raw), raw, disp);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc     = ref.watch(homeCalculationProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final units    = ref.watch(unitSettingsProvider);
    final profile  = ref.watch(shotProfileProvider).value;

    final hit = calc.value;
    if (hit == null || hit.trajectory.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final targetM = safeDimensionValue(profile?.targetDistance, Unit.meter) ?? 300.0;
    final stepM   = settings.tableConfig.stepM;

    final dists = [
      targetM - 2 * stepM,
      targetM - stepM,
      targetM,
      targetM + stepM,
      targetM + 2 * stepM,
    ];

    final points = dists
        .map((d) => d < 0 ? null : hit.getAtDistance(Distance(d, Unit.meter)))
        .toList();

    final distAcc    = FC.targetDistance.accuracyFor(units.distance);
    final distLabels = dists.map((m) {
      if (m < 0) return '—';
      final disp = Unit.meter(m).in_(units.distance);
      return disp.toStringAsFixed(distAcc);
    }).toList();

    final milAcc = FC.adjustment.accuracyFor(Unit.mil);
    final moaAcc = FC.adjustment.accuracyFor(Unit.moa);

    final rows = <(String, String, double? Function(TrajectoryData), int)>[
      ('Height',   units.drop.symbol,     (p) => _conv(p.height,       Unit.foot,      units.drop),     FC.drop.accuracyFor(units.drop)),
      ('Slant Ht', units.drop.symbol,     (p) => _conv(p.slantHeight,  Unit.foot,      units.drop),     FC.drop.accuracyFor(units.drop)),
      ('Angle',    'MIL',                 (p) => _conv(p.angle,        Unit.mil,       Unit.mil),        milAcc),
      ('Angle',    'MOA',                 (p) => _conv(p.angle,        Unit.mil,       Unit.moa),        moaAcc),
      ('Drop',     'MIL',                 (p) => _conv(p.dropAngle,    Unit.mil,       Unit.mil),        milAcc),
      ('Drop',     'MOA',                 (p) => _conv(p.dropAngle,    Unit.mil,       Unit.moa),        moaAcc),
      ('Windage',  'MIL',                 (p) => _conv(p.windageAngle, Unit.mil,       Unit.mil),        milAcc),
      ('Windage',  'MOA',                 (p) => _conv(p.windageAngle, Unit.mil,       Unit.moa),        moaAcc),
      ('Velocity', units.velocity.symbol, (p) => _conv(p.velocity,     Unit.fps,       units.velocity), FC.velocity.accuracyFor(units.velocity)),
      ('Energy',   units.energy.symbol,   (p) => _conv(p.energy,       Unit.footPound, units.energy),   FC.energy.accuracyFor(units.energy)),
      ('Time',     's',                   (p) => p.time,                                                 3),
    ];

    final theme          = Theme.of(context);
    final cs             = theme.colorScheme;
    final hdrStyle       = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface);
    final cellStyle      = theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    final targetCellStyle = cellStyle?.copyWith(color: cs.primary, fontWeight: FontWeight.w700);
    final labelStyle     = theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface);
    final labelSubStyle  = theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant);

    const targetCol = 2;

    Widget cell(String text, TextStyle? style, {Color? bg}) => Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(text, style: style, textAlign: TextAlign.right),
      ),
    );

    Widget labelCell(String label, String unit) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          Text(unit, style: labelSubStyle),
        ],
      ),
    );

    final tableRows = <TableRow>[
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(units.distance.symbol, style: labelSubStyle),
          ),
          for (var i = 0; i < dists.length; i++)
            cell(
              distLabels[i],
              i == targetCol ? hdrStyle?.copyWith(color: cs.primary) : hdrStyle,
              bg: i == targetCol ? cs.primaryContainer.withAlpha(60) : null,
            ),
        ],
      ),
      for (var ri = 0; ri < rows.length; ri++)
        TableRow(
          children: [
            labelCell(rows[ri].$1, rows[ri].$2),
            for (var ci = 0; ci < dists.length; ci++) (() {
              final p      = points[ci];
              final valStr = p == null
                  ? '—'
                  : (rows[ri].$3(p) ?? double.nan).toStringAsFixed(rows[ri].$4);
              return cell(
                valStr,
                ci == targetCol ? targetCellStyle : cellStyle,
                bg: ci == targetCol ? cs.primaryContainer.withAlpha(40) : null,
              );
            })(),
          ],
        ),
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Table(
          columnWidths: const {0: FlexColumnWidth(1.4)},
          defaultColumnWidth: const FlexColumnWidth(1.0),
          border: TableBorder.symmetric(
            inside: BorderSide(color: cs.outlineVariant, width: 0.5),
          ),
          children: tableRows,
        ),
      ),
    );
  }
}
