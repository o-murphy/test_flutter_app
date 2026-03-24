import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../src/models/field_constraints.dart';
import '../src/models/unit_settings.dart';
import '../src/solver/trajectory_data.dart';
import '../src/solver/unit.dart';

// ─── Column definition ────────────────────────────────────────────────────────

class _ColDef {
  final String id;
  final String label;
  final String Function(UnitSettings) symbol;
  final double? Function(TrajectoryData, UnitSettings) extract;
  final int Function(UnitSettings) accuracy;
  final bool alwaysVisible;

  const _ColDef({
    required this.id,
    required this.label,
    required this.symbol,
    required this.extract,
    required this.accuracy,
    this.alwaysVisible = false,
  });
}

// ─── Trajectory Table ─────────────────────────────────────────────────────────

class TrajectoryTable extends ConsumerStatefulWidget {
  final List<TrajectoryData> traj;

  /// Zero-flagged rows — shown as separate mini-table above main table
  /// when TableConfig.showZeros is enabled.
  final List<TrajectoryData> zeros;

  /// Display step in metres. Points between steps are skipped.
  final double displayStepM;

  /// Whether to highlight the first row where mach < 1.
  final bool showSubsonicTransition;

  const TrajectoryTable({
    super.key,
    required this.traj,
    this.zeros = const [],
    this.displayStepM = 100.0,
    this.showSubsonicTransition = false,
  });

  @override
  ConsumerState<TrajectoryTable> createState() => _TrajectoryTableState();
}

class _TrajectoryTableState extends ConsumerState<TrajectoryTable> {
  // Each table has two separate scroll controllers so the header can be
  // driven programmatically via a listener on the data controller.
  final _zeroDataCtrl   = ScrollController();
  final _zeroHeaderCtrl = ScrollController();
  final _trajDataCtrl   = ScrollController();
  final _trajHeaderCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _zeroDataCtrl.addListener(_syncZeroHeader);
    _trajDataCtrl.addListener(_syncTrajHeader);
  }

  void _syncZeroHeader() {
    if (_zeroHeaderCtrl.hasClients) {
      _zeroHeaderCtrl.jumpTo(_zeroDataCtrl.offset);
    }
  }

  void _syncTrajHeader() {
    if (_trajHeaderCtrl.hasClients) {
      _trajHeaderCtrl.jumpTo(_trajDataCtrl.offset);
    }
  }

  @override
  void dispose() {
    _zeroDataCtrl.removeListener(_syncZeroHeader);
    _trajDataCtrl.removeListener(_syncTrajHeader);
    _zeroDataCtrl.dispose();
    _zeroHeaderCtrl.dispose();
    _trajDataCtrl.dispose();
    _trajHeaderCtrl.dispose();
    super.dispose();
  }

  // ── Column catalogue ────────────────────────────────────────────────────────

  static double _conv(dynamic dim, Unit rawUnit, Unit dispUnit) {
    final v = (dim as dynamic).in_(rawUnit) as double;
    return (rawUnit(v) as dynamic).in_(dispUnit) as double;
  }

  static final _catalogue = <_ColDef>[
    _ColDef(
      id: 'range',
      label: 'Range',
      symbol: (u) => u.distance.symbol,
      extract: (r, u) => _conv(r.distance, Unit.foot, u.distance),
      accuracy: (u) => FC.distance.accuracyFor(u.distance),
      alwaysVisible: true,
    ),
    _ColDef(
      id: 'time',
      label: 'Time',
      symbol: (_) => 's',
      extract: (r, _) => r.time,
      accuracy: (_) => 3,
    ),
    _ColDef(
      id: 'velocity',
      label: 'V',
      symbol: (u) => u.velocity.symbol,
      extract: (r, u) => _conv(r.velocity, Unit.fps, u.velocity),
      accuracy: (u) => FC.velocity.accuracyFor(u.velocity),
    ),
    _ColDef(
      id: 'height',
      label: 'Height',
      symbol: (u) => u.drop.symbol,
      extract: (r, u) => _conv(r.height, Unit.foot, u.drop),
      accuracy: (u) => FC.drop.accuracyFor(u.drop),
    ),
    _ColDef(
      id: 'drop',
      label: 'Drop',
      symbol: (u) => u.drop.symbol,
      extract: (r, u) => _conv(r.slantHeight, Unit.foot, u.drop),
      accuracy: (u) => FC.drop.accuracyFor(u.drop),
    ),
    _ColDef(
      id: 'adjDrop',
      label: 'Drop°',
      symbol: (u) => u.adjustment.symbol,
      extract: (r, u) => _conv(r.dropAngle, Unit.mil, u.adjustment),
      accuracy: (u) => FC.adjustment.accuracyFor(u.adjustment),
    ),
    _ColDef(
      id: 'wind',
      label: 'Wind',
      symbol: (u) => u.drop.symbol,
      extract: (r, u) => _conv(r.windage, Unit.foot, u.drop),
      accuracy: (u) => FC.drop.accuracyFor(u.drop),
    ),
    _ColDef(
      id: 'adjWind',
      label: 'Wind°',
      symbol: (u) => u.adjustment.symbol,
      extract: (r, u) => _conv(r.windageAngle, Unit.mil, u.adjustment),
      accuracy: (u) => FC.adjustment.accuracyFor(u.adjustment),
    ),
    _ColDef(
      id: 'mach',
      label: 'Mach',
      symbol: (_) => '',
      extract: (r, _) => r.mach,
      accuracy: (_) => 2,
    ),
    _ColDef(
      id: 'energy',
      label: 'Energy',
      symbol: (u) => u.energy.symbol,
      extract: (r, u) => _conv(r.energy, Unit.footPound, u.energy),
      accuracy: (u) => FC.energy.accuracyFor(u.energy),
    ),
  ];

  List<_ColDef> _visibleCols(UnitSettings u, Set<String> hidden) =>
      _catalogue.where((c) => c.alwaysVisible || !hidden.contains(c.id)).toList();

  // ── Filtering ───────────────────────────────────────────────────────────────

  List<TrajectoryData> _filtered() {
    final step = widget.displayStepM;
    if (step <= 1.0) return widget.traj;
    final result = <TrajectoryData>[];
    double nextM = 0.0;
    for (final p in widget.traj) {
      final d = (p.distance as dynamic).in_(Unit.meter) as double;
      if (d >= nextM - 0.5) {
        result.add(p);
        nextM = ((d / step).round() + 1) * step;
      }
    }
    return result;
  }

  // ── Row detail dialog ────────────────────────────────────────────────────────

  void _showDetail(BuildContext ctx, TrajectoryData row,
      List<_ColDef> cols, UnitSettings u) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Range: ${_fmt(cols.first, row, u)}  ${cols.first.symbol(u)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: cols.skip(1).map((c) {
              final val = c.extract(row, u);
              return ListTile(
                dense: true,
                title: Text('${c.label}  (${c.symbol(u)})'),
                trailing: Text(
                  val == null ? '—' : val.toStringAsFixed(c.accuracy(u)),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _fmt(_ColDef c, TrajectoryData r, UnitSettings u) {
    final v = c.extract(r, u);
    return v == null ? '—' : v.toStringAsFixed(c.accuracy(u));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cfg    = ref.watch(settingsProvider).value?.tableConfig;
    final units  = ref.watch(unitSettingsProvider);
    final hidden = cfg?.hiddenCols ?? {};
    final cols   = _visibleCols(units, hidden);
    final rows   = _filtered();

    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    const colPad = EdgeInsets.symmetric(horizontal: 6, vertical: 4);

    final hdrStyle        = theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.bold, color: cs.onSurface);
    final subStyle        = theme.textTheme.labelSmall?.copyWith(
        color: cs.onSurfaceVariant);
    final cellStyle       = theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace');
    final zeroCellStyle   = cellStyle?.copyWith(
        color: cs.error, fontWeight: FontWeight.bold);
    final subsCellStyle   = cellStyle?.copyWith(
        color: cs.tertiary, fontWeight: FontWeight.bold);
    final zeroBannerStyle = theme.textTheme.bodySmall?.copyWith(
        color: cs.primary, fontWeight: FontWeight.bold, fontFamily: 'monospace');

    // Find zero / subsonic row indices in main table.
    int? zeroIdx;
    int? subsonicIdx;
    for (var i = 0; i < rows.length; i++) {
      if (zeroIdx == null && (rows[i].flag & TrajFlag.zero.value) != 0) {
        zeroIdx = i;
      }
      if (subsonicIdx == null &&
          widget.showSubsonicTransition &&
          rows[i].mach < 1.0) {
        subsonicIdx = i;
      }
    }

    final showZeros = cfg?.showZeros ?? true;

    return LayoutBuilder(builder: (context, constraints) {
      final minW = max(constraints.maxWidth, cols.length * 72.0);

      final colWidths = <int, TableColumnWidth>{
        for (var i = 0; i < cols.length; i++) i: const FlexColumnWidth(1.0),
      };
      final border = TableBorder.all(color: cs.outlineVariant, width: 0.5);

      // ── Cell builders ────────────────────────────────────────────────────

      Widget hCell(String text, TextStyle? style) => Padding(
        padding: colPad,
        child: Text(text, style: style, textAlign: TextAlign.right),
      );

      Widget dCell(String text, TextStyle? style,
          {Color? bg, VoidCallback? onTap}) =>
          GestureDetector(
            onTap: onTap,
            child: Container(
              color: bg,
              padding: colPad,
              child: Text(text, style: style, textAlign: TextAlign.right),
            ),
          );

      // ── Header rows (reused by both tables) ──────────────────────────────

      final labelRow = TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHighest),
        children: cols.map((c) => hCell(c.label, hdrStyle)).toList(),
      );
      final symbolRow = TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHigh),
        children: cols.map((c) => hCell(c.symbol(units), subStyle)).toList(),
      );

      // ── Helper: horizontal-scrollable table widget ───────────────────────

      Widget hTable(List<TableRow> tableRows, ScrollController ctrl) =>
          SingleChildScrollView(
            controller: ctrl,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minW),
              child: Table(
                columnWidths: colWidths,
                border: border,
                children: tableRows,
              ),
            ),
          );

      // ── Build data rows for zero crossings table ─────────────────────────

      final zeroDataRows = widget.zeros.map((r) {
        final arrow = (r.flag & TrajFlag.zeroUp.value) != 0
            ? ' ↑'
            : (r.flag & TrajFlag.zeroDown.value) != 0
                ? ' ↓'
                : '';
        return TableRow(
          children: cols.map((c) {
            final text = c.id == 'range'
                ? '${_fmt(c, r, units)}$arrow'
                : _fmt(c, r, units);
            return dCell(text, zeroBannerStyle,
                bg: cs.primaryContainer.withAlpha(60),
                onTap: () => _showDetail(context, r, cols, units));
          }).toList(),
        );
      }).toList();

      // ── Build data rows for main trajectory table ────────────────────────

      final trajDataRows = <TableRow>[];
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        final isZ = i == zeroIdx;
        final isS = i == subsonicIdx;
        final bg = isZ
            ? cs.errorContainer.withAlpha(80)
            : isS
                ? cs.tertiaryContainer.withAlpha(80)
                : (i.isEven ? null : cs.surfaceContainerLowest);
        final style = isZ ? zeroCellStyle : isS ? subsCellStyle : cellStyle;

        trajDataRows.add(TableRow(
          children: cols.map((c) => dCell(
            _fmt(c, r, units),
            style,
            bg: bg,
            onTap: () => _showDetail(context, r, cols, units),
          )).toList(),
        ));
      }

      // ── Section title ────────────────────────────────────────────────────

      Widget sectionTitle(String text) => Container(
        color: cs.surfaceContainerHigh.withAlpha(80),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurface.withAlpha(160),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      );

      // ── Layout ───────────────────────────────────────────────────────────

      return Column(
        children: [
          // 1. TODO 8.4: Details spoiler

          // 2. Zero crossings table (conditional)
          if (showZeros && widget.zeros.isNotEmpty) ...[
            sectionTitle('Zero Crossings'),
            // Frozen header (follows _zeroDataCtrl via listener)
            hTable([labelRow, symbolRow], _zeroHeaderCtrl),
            // Data rows (drives the listener)
            hTable(zeroDataRows, _zeroDataCtrl),
          ],

          // 3. Main trajectory table
          sectionTitle('Trajectory'),
          // Frozen header (follows _trajDataCtrl via listener)
          hTable([labelRow, symbolRow], _trajHeaderCtrl),
          // Scrollable data: vertical inside Expanded, horizontal via _trajDataCtrl
          Expanded(
            child: SingleChildScrollView(
              child: hTable(trajDataRows, _trajDataCtrl),
            ),
          ),
        ],
      );
    });
  }
}
