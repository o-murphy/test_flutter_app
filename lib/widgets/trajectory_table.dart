import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sticky_headers/sticky_headers.dart';

import '../helpers/dimension_converter.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
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
  final List<TrajectoryData> zeros;
  final double displayStepM;
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
  final _trajHdrCtrl  = ScrollController();
  final _trajDataCtrl = ScrollController();
  bool _syncingH = false;

  @override
  void initState() {
    super.initState();
    _trajDataCtrl.addListener(_onDataScroll);
    _trajHdrCtrl.addListener(_onHdrScroll);
  }

  void _onDataScroll() {
    if (_syncingH || !_trajHdrCtrl.hasClients || !_trajDataCtrl.hasClients) return;
    _syncingH = true;
    _trajHdrCtrl.jumpTo(_trajDataCtrl.offset);
    _syncingH = false;
  }

  void _onHdrScroll() {
    if (_syncingH || !_trajDataCtrl.hasClients || !_trajHdrCtrl.hasClients) return;
    _syncingH = true;
    _trajDataCtrl.jumpTo(_trajHdrCtrl.offset);
    _syncingH = false;
  }

  @override
  void dispose() {
    _trajDataCtrl.removeListener(_onDataScroll);
    _trajHdrCtrl.removeListener(_onHdrScroll);
    _trajDataCtrl.dispose();
    _trajHdrCtrl.dispose();
    super.dispose();
  }

  // ── Column catalogue ──────────────────────────────────────────────────────

  static double _conv(dynamic dim, Unit rawUnit, Unit dispUnit) {
    return valueInUnit(convertDimension(dim, rawUnit), rawUnit, dispUnit);
  }

  static final _catalogue = <_ColDef>[
    _ColDef(
      id: 'range',
      label: 'Range',
      symbol: (u) => u.distance.symbol,
      extract: (r, u) => _conv(r.distance, Unit.foot, u.distance),
      accuracy: (u) => FC.targetDistance.accuracyFor(u.distance),
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

  // ── Filtering (respects startM / endM / stepM from TableConfig) ───────────

  List<TrajectoryData> _filtered(double startM, double endM) {
    final step = widget.displayStepM;
    final result = <TrajectoryData>[];
    double nextM = startM;
    for (final p in widget.traj) {
      final d = convertDimension(p.distance, Unit.meter);
      if (d < startM - 0.5) continue;
      if (d > endM   + 0.5) break;
      if (step > 1.0 && d < nextM - 0.5) continue;
      result.add(p);
      if (step > 1.0) nextM = ((d / step).round() + 1) * step;
    }
    return result;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cfg     = ref.watch(settingsProvider).value?.tableConfig;
    final units   = ref.watch(unitSettingsProvider);
    // Apply per-table drop / adjustment unit overrides from TableConfig
    final effUnits = (cfg?.dropUnit != null || cfg?.adjUnit != null)
        ? units.copyWith(drop: cfg?.dropUnit, adjustment: cfg?.adjUnit)
        : units;

    final hidden  = cfg?.hiddenCols ?? {};
    final cols    = _visibleCols(effUnits, hidden);
    final startM  = cfg?.startM  ?? 0.0;
    final endM    = cfg?.endM    ?? 2000.0;
    final rows    = _filtered(startM, endM);

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

    int? zeroIdx;
    int? subsonicIdx;
    for (var i = 0; i < rows.length; i++) {
      if (zeroIdx == null && (rows[i].flag & TrajFlag.zero.value) != 0) zeroIdx = i;
      if (subsonicIdx == null && widget.showSubsonicTransition && rows[i].mach < 1.0) {
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

      // ── Helpers ───────────────────────────────────────────────────────────

      Widget hCell(String text, TextStyle? style) => Padding(
        padding: colPad,
        child: Text(text, style: style, textAlign: TextAlign.right),
      );

      Widget dCell(String text, TextStyle? style,
          {Color? bg, VoidCallback? onTap}) =>
          GestureDetector(
            onTap: onTap,
            child: Container(
              color: bg, padding: colPad,
              child: Text(text, style: style, textAlign: TextAlign.right),
            ),
          );

      void showDetail(TrajectoryData row) => showDialog<void>(
        context: context,
        builder: (dlgCtx) => AlertDialog(
          title: Text(
              'Range: ${_fmt(cols.first, row, effUnits)}  ${cols.first.symbol(effUnits)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: cols.skip(1).map((c) {
                final val = c.extract(row, effUnits);
                return ListTile(
                  dense: true,
                  title: Text('${c.label}  (${c.symbol(effUnits)})'),
                  trailing: Text(
                    val == null ? '—' : val.toStringAsFixed(c.accuracy(effUnits)),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Close'),
          )],
        ),
      );

      // ── Header rows ───────────────────────────────────────────────────────

      final labelRow = TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHighest),
        children: cols.map((c) => hCell(c.label, hdrStyle)).toList(),
      );
      final symbolRow = TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHigh),
        children: cols.map((c) => hCell(c.symbol(effUnits), subStyle)).toList(),
      );

      Widget hScroll(Widget table, {ScrollController? ctrl}) =>
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: ctrl,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minW),
              child: table,
            ),
          );

      // ── Section title ─────────────────────────────────────────────────────

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

      // ── Zero crossings table ──────────────────────────────────────────────

      Widget zeroTableWidget() {
        final zeroRows = widget.zeros.map((r) {
          final arrow = (r.flag & TrajFlag.zeroUp.value) != 0
              ? ' ↑'
              : (r.flag & TrajFlag.zeroDown.value) != 0 ? ' ↓' : '';
          return TableRow(
            children: cols.map((c) {
              final text = c.id == 'range'
                  ? '${_fmt(c, r, effUnits)}$arrow'
                  : _fmt(c, r, effUnits);
              return dCell(text, zeroBannerStyle,
                  bg: cs.primaryContainer.withAlpha(60),
                  onTap: () => showDetail(r));
            }).toList(),
          );
        }).toList();

        return hScroll(Table(
          columnWidths: colWidths,
          border: border,
          children: [labelRow, symbolRow, ...zeroRows],
        ));
      }

      // ── Trajectory data ───────────────────────────────────────────────────

      final trajHeaderWidget = hScroll(
        Table(
          columnWidths: colWidths,
          border: TableBorder(
            horizontalInside: BorderSide(color: cs.outlineVariant, width: 0.5),
            bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
          ),
          children: [labelRow, symbolRow],
        ),
        ctrl: _trajHdrCtrl,
      );

      final trajRows = <TableRow>[];
      for (var i = 0; i < rows.length; i++) {
        final r   = rows[i];
        final isZ = i == zeroIdx;
        final isS = i == subsonicIdx;
        final bg  = isZ
            ? cs.errorContainer.withAlpha(80)
            : isS
                ? cs.tertiaryContainer.withAlpha(80)
                : (i.isEven ? null : cs.surfaceContainerLowest);
        final style = isZ ? zeroCellStyle : isS ? subsCellStyle : cellStyle;
        trajRows.add(TableRow(
          children: cols.map((c) => dCell(
            _fmt(c, r, effUnits), style,
            bg: bg, onTap: () => showDetail(r),
          )).toList(),
        ));
      }

      final trajDataWidget = hScroll(
        Table(columnWidths: colWidths, border: border, children: trajRows),
        ctrl: _trajDataCtrl,
      );

      // ── Layout ────────────────────────────────────────────────────────────

      return ListView(
        children: [
          // 1. Details spoiler
          const _DetailsSpoiler(),

          // 2. Zero crossings (static)
          if (showZeros && widget.zeros.isNotEmpty) ...[
            sectionTitle('Zero Crossings'),
            zeroTableWidget(),
          ],

          // 3. Trajectory — section title scrolls with page; column header sticks.
          StickyHeader(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionTitle('Trajectory'),
                trajHeaderWidget,
              ],
            ),
            content: trajDataWidget,
          ),
        ],
      );
    });
  }
}

String _fmt(_ColDef c, TrajectoryData r, UnitSettings u) {
  final v = c.extract(r, u);
  return v == null ? '—' : v.toStringAsFixed(c.accuracy(u));
}

// ─── Details spoiler ──────────────────────────────────────────────────────────

class _DetailsSpoiler extends ConsumerWidget {
  const _DetailsSpoiler();

  static double _conv(dynamic dim, Unit raw, Unit disp) {
    final v = (dim as dynamic).in_(raw) as double;
    return (raw(v) as dynamic).in_(disp) as double;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg      = ref.watch(settingsProvider).value?.tableConfig;
    final units    = ref.watch(unitSettingsProvider);
    final settings = ref.watch(settingsProvider).value;
    final profile  = ref.watch(shotProfileProvider).value;

    if (cfg == null || profile == null) return const SizedBox.shrink();

    // Check if any section is enabled at all
    final anyEnabled = cfg.spoilerShowRifle || cfg.spoilerShowProjectile || cfg.spoilerShowAtmo;
    if (!anyEnabled) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace', color: cs.onSurface);
    final sectionStyle = theme.textTheme.labelSmall?.copyWith(
        color: cs.primary, fontWeight: FontWeight.w700, letterSpacing: 0.6);

    // ── Data extraction ──────────────────────────────────────────────────────

    final rifle   = profile.rifle;
    final cart    = profile.cartridge;
    final proj    = cart.projectile;
    final dm      = proj.dm;
    final conds   = profile.conditions;
    final winds   = profile.winds;

    final twistInch  = convertDimension(rifle.weapon.twist, Unit.inch);
    final weightGr   = convertDimension(dm.weight, Unit.grain);
    final diamInch   = convertDimension(dm.diameter, Unit.inch);
    final lenInch    = convertDimension(dm.length, Unit.inch);

    // Zero MV — direct from cartridge
    final zeroMvMps = convertDimension(cart.mv, Unit.mps);

    // Current MV — apply powder sensitivity if enabled
    double currentMvMps = zeroMvMps;
    final powderSensOn = (settings?.enablePowderSensitivity ?? false) &&
        cart.usePowderSensitivity;
    if (powderSensOn && cart.tempModifier != 0 && zeroMvMps > 0) {
      final useDiff  = settings?.useDifferentPowderTemperature ?? false;
      final zeroAtmo = profile.zeroConditions ?? conds;
      final currTempC = useDiff
          ? convertDimension(conds.powderTemp, Unit.celsius)
          : convertDimension(conds.temperature, Unit.celsius);
      final zeroPowderTempC = useDiff
          ? convertDimension(zeroAtmo.powderTemp, Unit.celsius)
          : convertDimension(zeroAtmo.temperature, Unit.celsius);
      currentMvMps = (cart.tempModifier / 100.0 / (15 / zeroMvMps)) *
          (currTempC - zeroPowderTempC) + zeroMvMps;
    }

    // Gyrostability (Miller)
    double? sg;
    if (weightGr > 0 && diamInch > 0 && lenInch > 0 && twistInch > 0) {
      final lCal = lenInch / diamInch;
      final nCal = twistInch / diamInch;
      sg = (30.0 * weightGr) /
          (nCal * nCal * diamInch * diamInch * diamInch * lCal * (1.0 + lCal * lCal));
    }

    // Sectional density + form factor
    final sd = (weightGr > 0 && diamInch > 0)
        ? (weightGr / 7000.0) / (diamInch * diamInch)
        : null;
    final ff = (sd != null && dm.bc > 0) ? sd / dm.bc : null;

    // ── Format helpers ────────────────────────────────────────────────────

    String fmtV(double mps) {
      final disp = Unit.mps(mps).in_(units.velocity);
      return '${disp.toStringAsFixed(FC.muzzleVelocity.accuracyFor(units.velocity))} ${units.velocity.symbol}';
    }

    String fmtDist(dynamic dim, Unit raw, Unit disp) {
      final v = _conv(dim, raw, disp);
      return '${v.toStringAsFixed(FC.targetDistance.accuracyFor(disp))} ${disp.symbol}';
    }

    // ── Build rows ────────────────────────────────────────────────────────

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

    // ── Rifle section ─────────────────────────────────────────────────────
    if (cfg.spoilerShowRifle) {
      items.add(section('Rifle'));
      items.add(row('Name', rifle.name));
      if (cfg.spoilerShowCaliber && diamInch > 0) {
        items.add(row('Caliber', fmtDist(dm.diameter, Unit.inch, units.diameter)));
      }
      if (cfg.spoilerShowTwist && twistInch > 0) {
        final tw = _conv(rifle.weapon.twist, Unit.inch, units.twist);
        items.add(row('Twist', '1:${tw.toStringAsFixed(FC.targetDistance.accuracyFor(units.twist))} ${units.twist.symbol}'));
      }
      // spoilerShowTwistDir — no twist direction field in the data model
    }

    // ── Projectile section ────────────────────────────────────────────────
    if (cfg.spoilerShowProjectile) {
      items.add(section('Projectile'));
      items.add(row('Name', proj.name));
      if (cfg.spoilerShowDragModel) {
        final dmStr = switch (proj.dragType) {
          _ when proj.dragType.name == 'g1'     => 'G1',
          _ when proj.dragType.name == 'g7'     => 'G7',
          _                                      => 'Custom',
        };
        items.add(row('Drag model', dmStr));
      }
      if (cfg.spoilerShowBc && dm.bc > 0) {
        items.add(row('BC', dm.bc.toStringAsFixed(FC.ballisticCoefficient.accuracy)));
      }
      if (cfg.spoilerShowZeroMv) {
        items.add(row('Zero MV', fmtV(zeroMvMps)));
      }
      if (cfg.spoilerShowCurrMv) {
        items.add(row('Current MV', fmtV(currentMvMps)));
      }
      if (cfg.spoilerShowZeroDist) {
        items.add(row('Zero distance', fmtDist(profile.zeroDistance, Unit.meter, units.distance)));
      }
      if (cfg.spoilerShowBulletLen && lenInch > 0) {
        items.add(row('Length', fmtDist(dm.length, Unit.inch, units.length)));
      }
      if (cfg.spoilerShowBulletDiam && diamInch > 0) {
        items.add(row('Diameter', fmtDist(dm.diameter, Unit.inch, units.diameter)));
      }
      if (cfg.spoilerShowBulletWeight && weightGr > 0) {
        final wDisp = _conv(dm.weight, Unit.grain, units.weight);
        items.add(row('Weight', '${wDisp.toStringAsFixed(FC.bulletWeight.accuracyFor(units.weight))} ${units.weight.symbol}'));
      }
      if (cfg.spoilerShowFormFactor && ff != null) {
        items.add(row('Form factor', ff.toStringAsFixed(3)));
      }
      if (cfg.spoilerShowSectionalDensity && sd != null) {
        items.add(row('Sectional density', sd.toStringAsFixed(3)));
      }
      if (cfg.spoilerShowGyroStability && sg != null) {
        items.add(row('Gyrostability (Sg)', sg.toStringAsFixed(2)));
      }
    }

    // ── Atmosphere section ────────────────────────────────────────────────
    if (cfg.spoilerShowAtmo) {
      items.add(section('Atmosphere'));
      if (cfg.spoilerShowTemp) {
        final t = _conv(conds.temperature, Unit.celsius, units.temperature);
        items.add(row('Temperature',
            '${t.toStringAsFixed(FC.temperature.accuracyFor(units.temperature))} ${units.temperature.symbol}'));
      }
      if (cfg.spoilerShowHumidity) {
        final h = (conds.humidity * 100).toStringAsFixed(0);
        items.add(row('Humidity', '$h %'));
      }
      if (cfg.spoilerShowPressure) {
        final p = _conv(conds.pressure, Unit.hPa, units.pressure);
        items.add(row('Pressure',
            '${p.toStringAsFixed(FC.pressure.accuracyFor(units.pressure))} ${units.pressure.symbol}'));
      }
      if (cfg.spoilerShowWindSpeed && winds.isNotEmpty) {
        final ws = _conv(winds.first.velocity, Unit.mps, units.velocity);
        items.add(row('Wind speed',
            '${ws.toStringAsFixed(FC.windVelocity.accuracyFor(units.velocity))} ${units.velocity.symbol}'));
      }
      if (cfg.spoilerShowWindDir && winds.isNotEmpty) {
        final wd = convertDimension(winds.first.directionFrom, Unit.degree);
        items.add(row('Wind direction', '${wd.toStringAsFixed(0)}°'));
      }
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
