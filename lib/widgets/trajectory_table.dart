import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../src/models/field_constraints.dart';
import '../src/models/unit_settings.dart';
import '../src/solver/trajectory_data.dart';
import '../src/solver/unit.dart';

class TrajectoryTable extends ConsumerWidget {
  final List<TrajectoryData> traj;
  final double availableWidth;
  /// Zero distance in metres. Used to highlight the zero-crossing row.
  final double zeroDistanceM;
  /// Display step in metres. Points between steps are skipped.
  final double displayStepM;

  const TrajectoryTable({
    super.key,
    required this.traj,
    required this.availableWidth,
    this.zeroDistanceM = 100.0,
    this.displayStepM  = 100.0,
  });

  List<TrajectoryData> _filtered() {
    if (displayStepM <= 1.0) return traj;
    final result = <TrajectoryData>[];
    double nextTargetM = 0.0;
    for (final p in traj) {
      final d = (p.distance as dynamic).in_(Unit.meter) as double;
      if (d >= nextTargetM - 0.5) {
        result.add(p);
        nextTargetM = ((d / displayStepM).round() + 1) * displayStepM;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitSettingsProvider);
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final rows  = _filtered();

    // Highlight row closest to zero distance.
    int? zeroIdx;
    double minDelta = double.infinity;
    for (var i = 0; i < rows.length; i++) {
      final distM = (rows[i].distance as dynamic).in_(Unit.meter) as double;
      final delta = (distM - zeroDistanceM).abs();
      if (delta < minDelta) { minDelta = delta; zeroIdx = i; }
    }

    final hdr      = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface);
    final sub      = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final cell     = theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    final zeroCell = cell?.copyWith(color: cs.error, fontWeight: FontWeight.bold);

    final cols = _columns(units);

    final tableRows = [
      TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHighest),
        children: cols.map((c) => _cell(c.$1, hdr)).toList(),
      ),
      TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHigh),
        children: cols.map((c) => _cell(c.$2, sub)).toList(),
      ),
      for (var i = 0; i < rows.length; i++)
        TableRow(
          decoration: BoxDecoration(
            color: i == zeroIdx
                ? cs.errorContainer.withAlpha(80)
                : (i.isEven ? null : cs.surfaceContainerLowest),
          ),
          children: _rowData(rows[i], units)
              .map((v) => _cell(v, i == zeroIdx ? zeroCell : cell))
              .toList(),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: availableWidth),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(flex: 1.0),
          border: TableBorder.all(color: cs.outlineVariant, width: 0.5),
          children: tableRows,
        ),
      ),
    );
  }

  // ─── Column definitions ────────────────────────────────────────────────────

  List<(String, String)> _columns(UnitSettings u) => [
    ('Time',   's'),
    ('Range',  u.distance.symbol),
    ('V',      u.velocity.symbol),
    ('Height', u.drop.symbol),
    ('Drop',   u.drop.symbol),
    ('Adj',    u.adjustment.symbol),
    ('Wind',   u.drop.symbol),
    ('W.Adj',  u.adjustment.symbol),
    ('Mach',   ''),
    ('Energy', u.energy.symbol),
  ];

  // ─── Row formatting ────────────────────────────────────────────────────────

  double _conv(dynamic dim, Unit raw, Unit disp) =>
      (raw(((dim as dynamic).in_(raw) as double)) as dynamic).in_(disp) as double;

  List<String> _rowData(TrajectoryData r, UnitSettings u) {
    final distAcc  = FC.distance.accuracyFor(u.distance);
    final velAcc   = FC.velocity.accuracyFor(u.velocity);
    final dropAcc  = FC.drop.accuracyFor(u.drop);
    final adjAcc   = FC.adjustment.accuracyFor(u.adjustment);
    final energyAcc = FC.energy.accuracyFor(u.energy);

    return [
      r.time.toStringAsFixed(3),
      _conv(r.distance,      Unit.foot, u.distance).toStringAsFixed(distAcc),
      _conv(r.velocity,      Unit.fps,  u.velocity).toStringAsFixed(velAcc),
      _conv(r.height,        Unit.foot, u.drop).toStringAsFixed(dropAcc),
      _conv(r.slantHeight,   Unit.foot, u.drop).toStringAsFixed(dropAcc),
      _conv(r.dropAngle,     Unit.mil,  u.adjustment).toStringAsFixed(adjAcc),
      _conv(r.windage,       Unit.foot, u.drop).toStringAsFixed(dropAcc),
      _conv(r.windageAngle,  Unit.mil,  u.adjustment).toStringAsFixed(adjAcc),
      r.mach.toStringAsFixed(2),
      _conv(r.energy,        Unit.footPound, u.energy).toStringAsFixed(energyAcc),
    ];
  }

  Widget _cell(String text, TextStyle? style) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Text(text, style: style, textAlign: TextAlign.right),
  );
}
