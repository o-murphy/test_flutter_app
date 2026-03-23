import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/calculation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../src/models/app_settings.dart';
import '../src/models/projectile.dart' show DragModelType;
import '../router.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/conditions.dart' as solver;
import '../src/solver/unit.dart' as solver;
import '../src/solver/unit.dart';
import '../src/solver/trajectory_data.dart';
import '../widgets/trajectory_chart.dart';
import '../widgets/wind_indicator.dart';
import '../widgets/side_control_block.dart';
import '../widgets/quick_actions_panel.dart';
import '../widgets/unit_value_field.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(shotProfileProvider).value;
    final units = ref.watch(unitSettingsProvider);

    final rifleName = profile?.rifle.name ?? '—';
    final cartridgeName = profile?.cartridge.name ?? '—';

    // Helper: convert a Dimension from its raw unit to the display unit.
    String dimStr(dynamic dim, Unit rawUnit, Unit dispUnit, {int dec = 0}) {
      if (dim == null) return '—';
      final raw = (dim as dynamic).in_(rawUnit) as double;
      final disp = (rawUnit(raw) as dynamic).in_(dispUnit) as double;
      return '${disp.toStringAsFixed(dec)} ${dispUnit.symbol}';
    }

    // Wind direction → initial wheel angle
    final windDirDeg = profile?.winds.isNotEmpty == true
        ? (profile!.winds.first.directionFrom as dynamic).in_(solver.Unit.degree) as double
        : 0.0;
    final windInitialAngle = (windDirDeg - 90) * math.pi / 180;

    final conditions = profile?.conditions;
    final tempStr = dimStr(
      conditions?.temperature,
      Unit.celsius,
      units.temperature,
    );
    final altStr = dimStr(conditions?.altitude, Unit.meter, units.distance);
    final pressStr = dimStr(conditions?.pressure, Unit.hPa, units.pressure);
    final humidStr = conditions != null
        ? '${(conditions.humidity * 100).toStringAsFixed(0)}%'
        : '—';

    return LayoutBuilder(
      builder: (context, constraints) {
        const minTopH = 350.0;
        const minBotH =
            300.0; // TODO: change page 1 adjustments layout to avoid overlap
        final totalH = math.max(constraints.maxHeight, minTopH + minBotH);
        final topBlockHeight = math.max(totalH * 0.55, minTopH);
        final botBlockHeight = totalH - topBlockHeight;

        return SingleChildScrollView(
          physics: totalH > constraints.maxHeight
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: totalH,
            child: Column(
              children: [
                // ── Top block ────────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  height: topBlockHeight,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                      child: Column(
                        children: [
                          // Rifle / cartridge selector row
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: () =>
                                      context.push(Routes.rifleSelect),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$rifleName · $cartridgeName',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.more_horiz_rounded),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                onPressed: () =>
                                    context.push(Routes.projectileSelect),
                                icon: const Icon(Icons.rocket_launch_outlined),
                              ),
                            ],
                          ),

                          // Wind indicator + side controls
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: SideControlBlock(
                                      topIcon: Icons.info_outline,
                                      bottomIcon: Icons.note_add_outlined,
                                      infoRows: [
                                        (
                                          Icons.device_thermostat_outlined,
                                          tempStr,
                                        ),
                                        (Icons.terrain_outlined, altStr),
                                      ],
                                      onTopPressed: () =>
                                          context.push(Routes.shotDetails),
                                      onBottomPressed: () {},
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: WindIndicator(
                                      initialAngle: windInitialAngle,
                                      onAngleChanged: (degrees, _) {
                                        final existing = ref.read(shotProfileProvider).value?.winds ?? [];
                                        ref.read(shotProfileProvider.notifier).updateWinds([
                                          solver.Wind(
                                            velocity: existing.isNotEmpty
                                                ? existing.first.velocity
                                                : solver.Velocity(0, solver.Unit.mps),
                                            directionFrom: solver.Angular(degrees, solver.Unit.degree),
                                          ),
                                        ]);
                                      },
                                      onDirectionTap: (deg) => showUnitEditDialog(
                                        context,
                                        label: 'Wind direction',
                                        rawValue: deg,
                                        constraints: FC.windDirection,
                                        displayUnit: Unit.degree,
                                        onChanged: (newDeg) {
                                          final normalized = ((newDeg % 360) + 360) % 360;
                                          final existing = ref.read(shotProfileProvider).value?.winds ?? [];
                                          ref.read(shotProfileProvider.notifier).updateWinds([
                                            solver.Wind(
                                              velocity: existing.isNotEmpty
                                                  ? existing.first.velocity
                                                  : solver.Velocity(0, solver.Unit.mps),
                                              directionFrom: solver.Angular(normalized, solver.Unit.degree),
                                            ),
                                          ]);
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: SideControlBlock(
                                      topIcon: Icons.question_mark_outlined,
                                      bottomIcon: Icons.more_horiz_outlined,
                                      infoRows: [
                                        (Icons.water_drop_outlined, humidStr),
                                        (Icons.speed_outlined, pressStr),
                                      ],
                                      onTopPressed: () {},
                                      onBottomPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(
                            height: 80,
                            child: const QuickActionsPanel(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom block — 3 pages ────────────────────────────────────────
                SizedBox(
                  height: botBlockHeight,
                  child: ref.watch(homeCalculationProvider).isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: (i) =>
                                    setState(() => _currentPage = i),
                                children: const [
                                  _PageReticle(),
                                  _PageTable(),
                                  _PageChart(),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: _PageDots(current: _currentPage, count: 3),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Page dots indicator ──────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  const _PageDots({required this.current, required this.count});
  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.onSurface.withAlpha(60),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─── Page 1 — Reticle & Adjustments ──────────────────────────────────────────

class _PageReticle extends ConsumerWidget {
  const _PageReticle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final units = ref.watch(unitSettingsProvider);
    final calc = ref.watch(homeCalculationProvider);
    final profile = ref.watch(shotProfileProvider).value;

    final hit = calc.value;
    final traj = hit?.trajectory ?? [];

    final targetM =
        (profile?.targetDistance as dynamic)?.in_(Unit.meter) as double? ??
        300.0;
    final point = (hit != null && traj.isNotEmpty)
        ? hit.getAtDistance(Distance(targetM, Unit.meter))
        : null;

    final elevAngle = hit?.shot.relativeAngle; // elevation hold (positive = up)
    final windAngle = point?.windageAngle; // lateral drift (positive = right)

    final dispUnits = <(Unit, String)>[
      if (settings.showMrad) (Unit.mRad, 'MRAD'),
      if (settings.showMoa) (Unit.moa, 'MOA'),
      if (settings.showMil) (Unit.mil, 'MIL'),
      if (settings.showCmPer100m) (Unit.cmPer100m, 'cm/100m'),
      if (settings.showInPer100yd) (Unit.inchesPer100Yd, 'in/100yd'),
    ];

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final proj = profile?.cartridge.projectile;
    final mvDisp = profile != null
        ? (profile.cartridge.mv as dynamic).in_(units.velocity) as double
        : null;
    final mvStr = mvDisp != null
        ? '${mvDisp.toStringAsFixed(FC.muzzleVelocity.accuracyFor(units.velocity))} ${units.velocity.symbol}'
        : '—';
    final bcAcc = FC.ballisticCoefficient.accuracy;
    final dragStr = switch (proj?.dragType) {
      DragModelType.g1 => 'G1 ${proj!.dm.bc.toStringAsFixed(bcAcc)}',
      DragModelType.g7 => 'G7 ${proj!.dm.bc.toStringAsFixed(bcAcc)}',
      DragModelType.custom => 'Custom',
      null => '—',
    };
    final cartridgeLabel = proj != null
        ? '${proj.name};  $mvStr;  $dragStr'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Bullet / drag info ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            cartridgeLabel,
            style: tt.labelMedium?.copyWith(color: cs.onSurface.withAlpha(160)),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // ── Reticle + Adjustments ────────────────────────────────────────
        Expanded(
          child: Row(
            children: [
              // Left: Reticle
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: _ReticleView(cs: cs),
                ),
              ),
              // Right: Adjustment values
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

// ─── Reticle placeholder ──────────────────────────────────────────────────────

class _ReticleView extends StatelessWidget {
  const _ReticleView({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: _ReticlePainter(cs: cs)),
    );
  }
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

    // Crosshair arms with gap at centre
    final gap = r * 0.09;
    canvas.drawLine(Offset(cx, cy - r + 2), Offset(cx, cy - gap), stroke);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + r - 2), stroke);
    canvas.drawLine(Offset(cx - r + 2, cy), Offset(cx - gap, cy), stroke);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + r - 2, cy), stroke);

    // Hash marks on arms at ¼, ½, ¾ radius
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

    // Centre dot
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
  const _AdjPanel({
    required this.dispUnits,
    required this.elevAngle,
    required this.windAngle,
    required this.fmt,
  });

  final List<(Unit, String)> dispUnits;
  final Angular? elevAngle;
  final Angular? windAngle;
  final AdjustmentFormat fmt;

  // Direction indicator shown in the section header.
  String _elevDir() {
    if (elevAngle == null) return '';
    final v = (elevAngle! as dynamic).in_(Unit.mRad) as double;
    return switch (fmt) {
      AdjustmentFormat.arrows => v >= 0 ? '↑' : '↓',
      AdjustmentFormat.signs => v >= 0 ? '+' : '−',
      AdjustmentFormat.letters => v >= 0 ? 'U' : 'D',
    };
  }

  String _windDir() {
    if (windAngle == null) return '';
    final corr = -((windAngle! as dynamic).in_(Unit.mRad) as double);
    return switch (fmt) {
      AdjustmentFormat.arrows => corr >= 0 ? '→' : '←',
      AdjustmentFormat.signs => corr >= 0 ? '+' : '−',
      AdjustmentFormat.letters => corr >= 0 ? 'R' : 'L',
    };
  }

  String _elevVal(Unit unit) {
    if (elevAngle == null) return '—';
    final v = (elevAngle! as dynamic).in_(unit) as double;
    return v.abs().toStringAsFixed(unit.accuracy);
  }

  // Windage correction = opposite of drift.
  String _windVal(Unit unit) {
    if (windAngle == null) return '—';
    final v = (windAngle! as dynamic).in_(unit) as double;
    return v.abs().toStringAsFixed(unit.accuracy);
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
        if (dir.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(dir, style: dirStyle),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        sectionHeader('Drop', _elevDir()),
        const SizedBox(height: 2),
        ...dispUnits.map((u) => valueRow(_elevVal(u.$1), u.$2)),
        const Divider(height: 16),
        sectionHeader('Windage', _windDir()),
        const SizedBox(height: 2),
        ...dispUnits.map((u) => valueRow(_windVal(u.$1), u.$2)),
      ],
    );
  }
}

// ─── Page 2 — Compact Adjustment Tables ──────────────────────────────────────

class _PageTable extends ConsumerWidget {
  const _PageTable();

  double _conv(dynamic dim, Unit raw, Unit disp) {
    final v = (dim as dynamic).in_(raw) as double;
    return (raw(v) as dynamic).in_(disp) as double;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc = ref.watch(homeCalculationProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final units = ref.watch(unitSettingsProvider);
    final profile = ref.watch(shotProfileProvider).value;

    final hit = calc.value;
    if (hit == null || hit.trajectory.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final targetM =
        (profile?.targetDistance as dynamic)?.in_(Unit.meter) as double? ??
        300.0;
    final stepM = settings.tableDistanceStep;

    final dists = [
      targetM - 2 * stepM,
      targetM - stepM,
      targetM,
      targetM + stepM,
      targetM + 2 * stepM,
    ];

    final points =
        dists
            .map((d) => d < 0 ? null : hit.getAtDistance(Distance(d, Unit.meter)))
            .toList();

    final distAcc = FC.distance.accuracyFor(units.distance);
    final distLabels = dists.map((m) {
      if (m < 0) return '—';
      final disp = (Unit.meter(m) as dynamic).in_(units.distance) as double;
      return disp.toStringAsFixed(distAcc);
    }).toList();

    final milAcc = FC.adjustment.accuracyFor(Unit.mil);
    final moaAcc = FC.adjustment.accuracyFor(Unit.moa);

    // Each row: (label, unit symbol, value extractor, decimal places)
    final rows = <(String, String, double? Function(TrajectoryData), int)>[
      (
        'Height',
        units.drop.symbol,
        (p) => _conv(p.height, Unit.foot, units.drop),
        FC.drop.accuracyFor(units.drop),
      ),
      (
        'Slant Ht',
        units.drop.symbol,
        (p) => _conv(p.slantHeight, Unit.foot, units.drop),
        FC.drop.accuracyFor(units.drop),
      ),
      (
        'Angle',
        'MIL',
        (p) => _conv(p.angle, Unit.mil, Unit.mil),
        milAcc,
      ),
      (
        'Angle',
        'MOA',
        (p) => _conv(p.angle, Unit.mil, Unit.moa),
        moaAcc,
      ),
      (
        'Drop',
        'MIL',
        (p) => _conv(p.dropAngle, Unit.mil, Unit.mil),
        milAcc,
      ),
      (
        'Drop',
        'MOA',
        (p) => _conv(p.dropAngle, Unit.mil, Unit.moa),
        moaAcc,
      ),
      (
        'Windage',
        'MIL',
        (p) => _conv(p.windageAngle, Unit.mil, Unit.mil),
        milAcc,
      ),
      (
        'Windage',
        'MOA',
        (p) => _conv(p.windageAngle, Unit.mil, Unit.moa),
        moaAcc,
      ),
      (
        'Velocity',
        units.velocity.symbol,
        (p) => _conv(p.velocity, Unit.fps, units.velocity),
        FC.velocity.accuracyFor(units.velocity),
      ),
      (
        'Energy',
        units.energy.symbol,
        (p) => _conv(p.energy, Unit.footPound, units.energy),
        FC.energy.accuracyFor(units.energy),
      ),
      ('Time', 's', (p) => p.time, 3),
    ];

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hdrStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );
final cellStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
    );
    final targetCellStyle = cellStyle?.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
    );

    const targetCol = 2; // index of target column in dists

    Widget cell(String text, TextStyle? style, {Color? bg}) => Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(text, style: style, textAlign: TextAlign.right),
      ),
    );

    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );
    final labelSubStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
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

    // Build table columns: [label | d0 | d1 | d2 | d3 | d4]
    final tableRows = <TableRow>[
      // Distance header row
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
      // Data rows
      for (var ri = 0; ri < rows.length; ri++)
        TableRow(
          children: [
            labelCell(rows[ri].$1, rows[ri].$2),
            for (var ci = 0; ci < dists.length; ci++) (() {
              final p = points[ci];
              final valStr = p == null
                  ? '—'
                  : (rows[ri].$3(p) ?? double.nan)
                        .toStringAsFixed(rows[ri].$4);
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

class _PageChart extends ConsumerStatefulWidget {
  const _PageChart();
  @override
  ConsumerState<_PageChart> createState() => _PageChartState();
}

class _PageChartState extends ConsumerState<_PageChart> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(homeCalculationProvider, (prev, next) {
      if (next.value?.trajectory != prev?.value?.trajectory) {
        if (mounted) setState(() => _selectedIndex = 0);
      }
    });

    // Home chart uses a separate calculation zeroed at targetDistance.
    final calc = ref.watch(homeCalculationProvider);
    if (calc.isLoading) return const Center(child: CircularProgressIndicator());
    final hit = calc.value;
    if (hit == null || hit.trajectory.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final units = ref.watch(unitSettingsProvider);
    final snapDistM =
        ref.watch(settingsProvider).value?.chartDistanceStep ?? 100.0;
    final traj = hit.trajectory;
    final si = _selectedIndex.clamp(0, traj.length - 1);

    return Column(
      children: [
        _ChartInfoGrid(point: traj[si], units: units),
        Expanded(
          child: TrajectoryChart(
            traj: traj,
            selectedIndex: si,
            snapDistM: snapDistM,
            onIndexSelected: (i) => setState(() => _selectedIndex = i),
          ),
        ),
      ],
    );
  }
}

// ── Info grid above chart ─────────────────────────────────────────────────────

class _ChartInfoGrid extends StatelessWidget {
  final TrajectoryData point;
  final dynamic units; // UnitSettings

  const _ChartInfoGrid({required this.point, required this.units});

  // Convert a solver Dimension to display unit value.
  // rawUnit: the unit the value is stored in (e.g. Unit.foot)
  // dispUnit: the target display unit (e.g. units.distance)
  double _conv(dynamic dim, Unit rawUnit, Unit dispUnit) {
    final raw = (dim as dynamic).in_(rawUnit) as double;
    return (rawUnit(raw) as dynamic).in_(dispUnit) as double;
  }

  String _fmt(double val, int dec, String sym) =>
      '${val.toStringAsFixed(dec)} $sym';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final distVal = _conv(point.distance, Unit.foot, units.distance);
    final htVal = _conv(point.height, Unit.foot, units.drop);
    final velVal = _conv(point.velocity, Unit.fps, units.velocity);
    final dropVal = _conv(point.dropAngle, Unit.mil, units.adjustment);
    final engVal = _conv(point.energy, Unit.joule, units.energy);
    final windVal = _conv(point.windageAngle, Unit.mil, units.adjustment);

    // Left column: Distance, Velocity, Energy, Time
    // Right column: Height, Drop, Windage, Mach
    final leftItems = [
      (Icons.straighten, _fmt(distVal, 0, units.distance.symbol)),
      (Icons.speed, _fmt(velVal, 0, units.velocity.symbol)),
      (Icons.bolt, _fmt(engVal, 0, units.energy.symbol)),
      (Icons.timer_outlined, '${point.time.toStringAsFixed(3)} s'),
    ];
    final rightItems = [
      (
        Icons.height,
        _fmt(htVal.abs(), FC.drop.accuracyFor(units.drop), units.drop.symbol) +
            (htVal < 0 ? ' ↓' : ' ↑'),
      ),
      (
        Icons.arrow_downward,
        _fmt(
          dropVal,
          FC.adjustment.accuracyFor(units.adjustment),
          units.adjustment.symbol,
        ),
      ),
      (
        Icons.arrow_right_alt,
        _fmt(
          windVal,
          FC.adjustment.accuracyFor(units.adjustment),
          units.adjustment.symbol,
        ),
      ),
      (Icons.air, '${point.mach.toStringAsFixed(2)} M'),
    ];

    final valueStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );

    Widget infoRow(IconData icon, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: cs.onSurface.withAlpha(140)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: leftItems.map((e) => infoRow(e.$1, e.$2)).toList(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rightItems.map((e) => infoRow(e.$1, e.$2)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
