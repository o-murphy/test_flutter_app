import 'package:flutter/material.dart';
import 'package:test_app/src/solver/trajectory_data.dart';
import 'package:test_app/src/solver/unit.dart';

const _ftToM   = 1.0 / 3.28084;
const _ftToCm  = 30.48;
const _fpsToms = 1.0 / 3.28084;
const _ftLbToJ = 1.35582;

class TrajectoryTable extends StatelessWidget {
  final List<TrajectoryData> traj;
  final double availableWidth;
  /// Zero distance in metres. Used to highlight the zero-crossing row.
  final double zeroDistanceM;
  /// Display step in metres. Points between steps are skipped.
  /// Defaults to 100 m. Set to `min(1.0, tableStep)` for fine-step traj.
  final double displayStepM;

  const TrajectoryTable({
    super.key,
    required this.traj,
    required this.availableWidth,
    this.zeroDistanceM = 100.0,
    this.displayStepM  = 100.0,
  });

  /// Filter fine-step trajectory to one point per [displayStepM] interval.
  List<TrajectoryData> _filtered() {
    if (displayStepM <= 1.0) return traj; // already at display resolution
    final result = <TrajectoryData>[];
    double nextTargetM = 0.0;
    for (final p in traj) {
      final d = p.distance.in_(Unit.foot) * _ftToM;
      if (d >= nextTargetM - 0.5) {
        result.add(p);
        nextTargetM = ((d / displayStepM).round() + 1) * displayStepM;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final rows = _filtered();

    // Highlight the row whose distance is closest to the zero distance.
    int? zeroIdx;
    double minDelta = double.infinity;
    for (var i = 0; i < rows.length; i++) {
      final distM = rows[i].distance.in_(Unit.foot) * _ftToM;
      final delta = (distM - zeroDistanceM).abs();
      if (delta < minDelta) { minDelta = delta; zeroIdx = i; }
    }

    final hdr      = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface);
    final sub      = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final cell     = theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    final zeroCell = cell?.copyWith(color: cs.error, fontWeight: FontWeight.bold);

    const cols = [
      ('Time',    's'),
      ('Range',   'm'),
      ('V',       'm/s'),
      ('Height',  'cm'),
      ('Drop',    'cm'),
      ('Adj',     'MIL'),
      ('Wind',    'cm'),
      ('W.Adj',   'MIL'),
      ('Mach',    ''),
      ('Density', ''),
      ('Drag',    ''),
      ('Energy',  'J'),
    ];

    List<String> rowData(TrajectoryData r) => [
      r.time.toStringAsFixed(3),
      (r.distance.in_(Unit.foot)     * _ftToM  ).toStringAsFixed(0),
      (r.velocity.in_(Unit.fps)      * _fpsToms).toStringAsFixed(0),
      (r.height.in_(Unit.foot)       * _ftToCm ).toStringAsFixed(1),
      (r.slantHeight.in_(Unit.foot)  * _ftToCm ).toStringAsFixed(1),
      (r.dropAngle.in_(Unit.radian)  * 1000    ).toStringAsFixed(2),
      (r.windage.in_(Unit.foot)      * _ftToCm ).toStringAsFixed(1),
      (r.windageAngle.in_(Unit.radian) * 1000  ).toStringAsFixed(2),
      r.mach.toStringAsFixed(2),
      r.densityRatio.toStringAsFixed(3),
      r.drag.toStringAsFixed(4),
      (r.energy.in_(Unit.footPound)  * _ftLbToJ).toStringAsFixed(0),
    ];

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
          children: rowData(rows[i])
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

  Widget _cell(String text, TextStyle? style) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(text, style: style, textAlign: TextAlign.right),
      );
}
