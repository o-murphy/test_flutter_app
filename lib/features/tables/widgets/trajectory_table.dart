import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';

import 'package:eballistica/shared/models/formatted_row.dart';
import 'package:eballistica/features/tables/tables_vm.dart';

// ─── Trajectory Table ─────────────────────────────────────────────────────────
//
// Layout: rows = distance points, columns = metrics (Range, Time, V, Height, …).
// The metric header row sticks to the top; columns scroll horizontally.

class TrajectoryTable extends StatefulWidget {
  final FormattedTableData mainTable;
  final FormattedTableData? zeroCrossings;
  final TablesSpoilerData spoiler;

  const TrajectoryTable({
    super.key,
    required this.mainTable,
    this.zeroCrossings,
    required this.spoiler,
  });

  @override
  State<TrajectoryTable> createState() => _TrajectoryTableState();
}

class _TrajectoryTableState extends State<TrajectoryTable> {
  // Main trajectory table scroll sync
  final _trajHdrCtrl  = ScrollController();
  final _trajDataCtrl = ScrollController();
  bool _syncingTraj = false;

  // Zero crossings table scroll sync
  final _zeroHdrCtrl  = ScrollController();
  final _zeroDataCtrl = ScrollController();
  bool _syncingZero = false;

  @override
  void initState() {
    super.initState();
    _trajDataCtrl.addListener(_onTrajDataScroll);
    _trajHdrCtrl.addListener(_onTrajHdrScroll);
    _zeroDataCtrl.addListener(_onZeroDataScroll);
    _zeroHdrCtrl.addListener(_onZeroHdrScroll);
  }

  void _onTrajDataScroll() {
    if (_syncingTraj || !_trajHdrCtrl.hasClients || !_trajDataCtrl.hasClients) return;
    _syncingTraj = true;
    _trajHdrCtrl.jumpTo(_trajDataCtrl.offset);
    _syncingTraj = false;
  }

  void _onTrajHdrScroll() {
    if (_syncingTraj || !_trajDataCtrl.hasClients || !_trajHdrCtrl.hasClients) return;
    _syncingTraj = true;
    _trajDataCtrl.jumpTo(_trajHdrCtrl.offset);
    _syncingTraj = false;
  }

  void _onZeroDataScroll() {
    if (_syncingZero || !_zeroHdrCtrl.hasClients || !_zeroDataCtrl.hasClients) return;
    _syncingZero = true;
    _zeroHdrCtrl.jumpTo(_zeroDataCtrl.offset);
    _syncingZero = false;
  }

  void _onZeroHdrScroll() {
    if (_syncingZero || !_zeroDataCtrl.hasClients || !_zeroHdrCtrl.hasClients) return;
    _syncingZero = true;
    _zeroDataCtrl.jumpTo(_zeroHdrCtrl.offset);
    _syncingZero = false;
  }

  @override
  void dispose() {
    _trajDataCtrl.removeListener(_onTrajDataScroll);
    _trajHdrCtrl.removeListener(_onTrajHdrScroll);
    _zeroDataCtrl.removeListener(_onZeroDataScroll);
    _zeroHdrCtrl.removeListener(_onZeroHdrScroll);
    _trajDataCtrl.dispose();
    _trajHdrCtrl.dispose();
    _zeroDataCtrl.dispose();
    _zeroHdrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final table = widget.mainTable;

    const colPad  = EdgeInsets.symmetric(horizontal: 6, vertical: 4);
    const colW    = 72.0;

    final hdrStyle      = theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface);
    final subStyle      = theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant);
    final cellStyle     = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    final zeroCellStyle = cellStyle?.copyWith(color: cs.error, fontWeight: FontWeight.bold);
    final subsCellStyle = cellStyle?.copyWith(color: cs.tertiary, fontWeight: FontWeight.bold);
    final zeroBannerStyle = theme.textTheme.bodySmall?.copyWith(
        color: cs.primary, fontWeight: FontWeight.bold, fontFamily: 'monospace');
    // ── Helpers ──────────────────────────────────────────────────────────────

    Widget hCell(String text, TextStyle? style, {double width = colW}) => SizedBox(
      width: width,
      child: Padding(
        padding: colPad,
        child: Text(text, style: style, textAlign: TextAlign.right),
      ),
    );

    Widget dCell(String text, TextStyle? style, {Color? bg, VoidCallback? onTap}) =>
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: colW,
            color: bg,
            padding: colPad,
            child: Text(text, style: style, textAlign: TextAlign.right),
          ),
        );

    Widget rowDivider() => Divider(height: 1, color: cs.outlineVariant, thickness: 0.5);

    // ── Section title ─────────────────────────────────────────────────────────

    Widget sectionTitle(String text) => Container(
      color: cs.surfaceContainerHigh,
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

    // ── Detail dialog ─────────────────────────────────────────────────────────

    void showDetail(FormattedTableData t, int colIndex) => showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(
            'Range: ${colIndex < t.distanceHeaders.length ? t.distanceHeaders[colIndex] : "—"} ${t.distanceUnit}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: t.rows.map((row) => ListTile(
              dense: true,
              title: Text('${row.label}  (${row.unitSymbol})'),
              trailing: Text(
                colIndex < row.cells.length ? row.cells[colIndex].value : '—',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            )).toList(),
          ),
        ),
        actions: [TextButton(
          onPressed: () => Navigator.pop(dlgCtx),
          child: const Text('Close'),
        )],
      ),
    );

    // ── Main table renderer (rows = distance points, cols = metrics) ────────

    Widget buildTable(FormattedTableData t) {
      final nMetrics = t.rows.length;
      final nPoints  = t.distanceHeaders.length;
      final totalW   = colW * (1 + nMetrics);

      // Metric label header row
      Widget labelRow() => Container(
        color: cs.surfaceContainerHighest,
        child: Row(children: [
          hCell('Range', hdrStyle),
          ...List.generate(nMetrics, (i) => hCell(t.rows[i].label, hdrStyle)),
        ]),
      );

      // Metric unit sub-header
      Widget unitRow() => Container(
        color: cs.surfaceContainerHigh,
        child: Row(children: [
          hCell(t.distanceUnit, subStyle),
          ...List.generate(nMetrics, (i) => hCell(t.rows[i].unitSymbol, subStyle)),
        ]),
      );

      // Data rows: one per distance point
      Widget dataRows() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var pi = 0; pi < nPoints; pi++) ...[
            if (pi > 0) rowDivider(),
            Builder(builder: (_) {
              final firstCell = nMetrics > 0 && pi < t.rows[0].cells.length
                  ? t.rows[0].cells[pi]
                  : null;
              final isZ = firstCell?.isZeroCrossing ?? false;
              final isS = firstCell?.isSubsonic ?? false;
              final isTarget = firstCell?.isTargetColumn ?? false;
              final bg = isTarget
                  ? cs.primaryContainer.withAlpha(60)
                  : isZ
                      ? cs.errorContainer.withAlpha(80)
                      : isS
                          ? cs.tertiaryContainer.withAlpha(80)
                          : (pi.isEven ? null : cs.surfaceContainerLowest);
              final style = isTarget
                  ? cellStyle?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)
                  : isZ ? zeroCellStyle : isS ? subsCellStyle : cellStyle;
              final distStyle = isTarget
                  ? hdrStyle?.copyWith(color: cs.primary)
                  : hdrStyle;
              return Row(children: [
                dCell(t.distanceHeaders[pi], distStyle,
                    bg: bg, onTap: () => showDetail(t, pi)),
                ...List.generate(nMetrics, (mi) {
                  final cell = pi < t.rows[mi].cells.length
                      ? t.rows[mi].cells[pi]
                      : null;
                  return dCell(cell?.value ?? '—', style,
                      bg: bg, onTap: () => showDetail(t, pi));
                }),
              ]);
            }),
          ],
        ],
      );

      Widget hScroll(Widget child, {ScrollController? ctrl}) =>
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: ctrl,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: totalW),
              child: child,
            ),
          );

      return StickyHeader(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionTitle('Trajectory'),
            hScroll(Column(children: [labelRow(), unitRow()]), ctrl: _trajHdrCtrl),
            Divider(height: 1, color: cs.outlineVariant, thickness: 0.5),
          ],
        ),
        content: hScroll(dataRows(), ctrl: _trajDataCtrl),
      );
    }

    // ── Zero crossings table (transposed: rows = points, cols = metrics) ─────

    Widget buildZeroTable(FormattedTableData t) {
      // Columns: Range + each metric
      final nMetrics = t.rows.length;
      final nPoints  = t.distanceHeaders.length;
      final totalW   = colW * (1 + nMetrics);

      // Header row: Range, Time, V, Height, ...
      Widget headerRow() => Container(
        color: cs.surfaceContainerHighest,
        child: Row(children: [
          hCell('Range', hdrStyle),
          ...List.generate(nMetrics, (i) => hCell(t.rows[i].label, hdrStyle)),
        ]),
      );

      // Unit sub-header
      Widget unitRow() => Container(
        color: cs.surfaceContainerHighest,
        child: Row(children: [
          hCell(t.distanceUnit, subStyle),
          ...List.generate(nMetrics, (i) => hCell(t.rows[i].unitSymbol, subStyle)),
        ]),
      );

      // Data rows: one per zero crossing point
      Widget dataArea() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var pi = 0; pi < nPoints; pi++) ...[
            if (pi > 0) rowDivider(),
            Container(
              color: cs.primaryContainer.withAlpha(60),
              child: Row(children: [
                dCell(t.distanceHeaders[pi], zeroBannerStyle),
                ...List.generate(nMetrics, (mi) {
                  final cell = pi < t.rows[mi].cells.length
                      ? t.rows[mi].cells[pi]
                      : null;
                  return dCell(cell?.value ?? '—', zeroBannerStyle);
                }),
              ]),
            ),
          ],
        ],
      );

      Widget zHScroll(Widget child, {ScrollController? ctrl}) =>
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: ctrl,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: totalW),
              child: child,
            ),
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          zHScroll(Column(children: [headerRow(), unitRow()]), ctrl: _zeroHdrCtrl),
          Divider(height: 1, color: cs.outlineVariant, thickness: 0.5),
          zHScroll(dataArea(), ctrl: _zeroDataCtrl),
        ],
      );
    }

    // ── Layout ────────────────────────────────────────────────────────────────

    return ListView(
      children: [
        // 1. Details spoiler
        _DetailsSpoiler(spoiler: widget.spoiler),

        // 2. Zero crossings (row-per-point layout)
        if (widget.zeroCrossings != null &&
            widget.zeroCrossings!.distanceHeaders.isNotEmpty) ...[
          sectionTitle('Zero Crossings'),
          buildZeroTable(widget.zeroCrossings!),
        ],

        // 3. Main trajectory table (StickyHeader — must be direct ListView child)
        buildTable(table),
      ],
    );
  }
}

// ─── Details spoiler ──────────────────────────────────────────────────────────

class _DetailsSpoiler extends StatelessWidget {
  const _DetailsSpoiler({required this.spoiler});

  final TablesSpoilerData spoiler;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final labelStyle   = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final valueStyle   = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: cs.onSurface);
    final sectionStyle = theme.textTheme.labelSmall?.copyWith(
        color: cs.primary, fontWeight: FontWeight.w700, letterSpacing: 0.6);

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ]),
    );

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Text(title.toUpperCase(), style: sectionStyle),
    );

    final items = <Widget>[];

    // Rifle
    final hasRifle = spoiler.caliber != null || spoiler.twist != null;
    if (hasRifle) {
      items.add(section('Rifle'));
      items.add(row('Name', spoiler.rifleName));
      if (spoiler.caliber    != null) items.add(row('Caliber', spoiler.caliber!));
      if (spoiler.twist      != null) items.add(row('Twist',   spoiler.twist!));
    }

    // Projectile
    final hasProj = spoiler.dragModel != null || spoiler.bc != null ||
        spoiler.zeroMv != null || spoiler.currentMv != null ||
        spoiler.zeroDist != null || spoiler.bulletLen != null ||
        spoiler.bulletDiam != null || spoiler.bulletWeight != null ||
        spoiler.formFactor != null || spoiler.sectionalDensity != null ||
        spoiler.gyroStability != null;
    if (hasProj) {
      items.add(section('Projectile'));
      if (spoiler.dragModel       != null) items.add(row('Drag model',         spoiler.dragModel!));
      if (spoiler.bc              != null) items.add(row('BC',                 spoiler.bc!));
      if (spoiler.zeroMv          != null) items.add(row('Zero MV',            spoiler.zeroMv!));
      if (spoiler.currentMv       != null) items.add(row('Current MV',         spoiler.currentMv!));
      if (spoiler.zeroDist        != null) items.add(row('Zero distance',       spoiler.zeroDist!));
      if (spoiler.bulletLen       != null) items.add(row('Length',             spoiler.bulletLen!));
      if (spoiler.bulletDiam      != null) items.add(row('Diameter',           spoiler.bulletDiam!));
      if (spoiler.bulletWeight    != null) items.add(row('Weight',             spoiler.bulletWeight!));
      if (spoiler.formFactor      != null) items.add(row('Form factor',        spoiler.formFactor!));
      if (spoiler.sectionalDensity != null) items.add(row('Sectional density', spoiler.sectionalDensity!));
      if (spoiler.gyroStability   != null) items.add(row('Gyrostability (Sg)', spoiler.gyroStability!));
    }

    // Atmosphere
    final hasAtmo = spoiler.temperature != null || spoiler.humidity != null ||
        spoiler.pressure != null || spoiler.windSpeed != null || spoiler.windDir != null;
    if (hasAtmo) {
      items.add(section('Atmosphere'));
      if (spoiler.temperature != null) items.add(row('Temperature',    spoiler.temperature!));
      if (spoiler.humidity    != null) items.add(row('Humidity',       spoiler.humidity!));
      if (spoiler.pressure    != null) items.add(row('Pressure',       spoiler.pressure!));
      if (spoiler.windSpeed   != null) items.add(row('Wind speed',     spoiler.windSpeed!));
      if (spoiler.windDir     != null) items.add(row('Wind direction', spoiler.windDir!));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text('Shot details',
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        backgroundColor: cs.surfaceContainerLowest,
        collapsedBackgroundColor: cs.surfaceContainerLowest,
        children: items,
      ),
    );
  }
}
