import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/dimension_converter.dart';
import '../providers/calculation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/trajectory_data.dart';
import '../src/solver/unit.dart';
import '../widgets/section_header.dart';

class ShotDetailsScreen extends ConsumerWidget {
  const ShotDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(shotProfileProvider).value;
    final settings = ref.watch(settingsProvider).value;
    final units = ref.watch(unitSettingsProvider);
    final calc = ref.watch(homeCalculationProvider);

    final cartridge = profile?.cartridge;
    final targetDistM = safeDimensionValue(profile?.targetDistance, Unit.meter) ?? 300.0;

    // ── MV with powder sensitivity ─────────────────────────────────────────
    final refMvMps = safeDimensionValue(cartridge?.mv, Unit.mps) ?? 0.0;
    final refPowderTempC = safeDimensionValue(cartridge?.powderTemp, Unit.celsius) ?? 15.0;
    final tempModifier = cartridge?.tempModifier ?? 0.0;
    final powderSensOn =
        (settings?.enablePowderSensitivity ?? false) &&
        (cartridge?.usePowderSensitivity ?? false);
    final useDiffTemp =
        powderSensOn && (settings?.useDifferentPowderTemperature ?? false);

    double mvAtTempC(double tC) {
      if (refMvMps <= 0 || tempModifier == 0) return refMvMps;
      return (tempModifier / 100.0 / (15 / refMvMps)) * (tC - refPowderTempC) +
          refMvMps;
    }

    final conditions = profile?.conditions;
    final currentPowderTempC = useDiffTemp
        ? (safeDimensionValue(conditions?.powderTemp, Unit.celsius) ?? 15.0)
        : (safeDimensionValue(conditions?.temperature, Unit.celsius) ?? 15.0);
    final currentMvMps = powderSensOn
        ? mvAtTempC(currentPowderTempC)
        : refMvMps;

    final zeroAtmo = profile?.zeroConditions ?? conditions;
    final zeroPowderTempC = useDiffTemp
        ? (safeDimensionValue(zeroAtmo?.powderTemp, Unit.celsius) ?? 15.0)
        : (safeDimensionValue(zeroAtmo?.temperature, Unit.celsius) ?? 15.0);
    final zeroMvMps = powderSensOn ? mvAtTempC(zeroPowderTempC) : refMvMps;

    // ── Gyroscopic stability factor Sg (Miller formula) ───────────────────
    final dm = cartridge?.projectile.dm;
    final twistInch = safeDimensionValue(profile?.rifle.weapon.twist, Unit.inch) ?? 0.0;
    final weightGr = safeDimensionValue(dm?.weight, Unit.grain) ?? 0.0;
    final diamInch = safeDimensionValue(dm?.diameter, Unit.inch) ?? 0.0;
    final lenInch = safeDimensionValue(dm?.length, Unit.inch) ?? 0.0;

    double? sg;
    if (weightGr > 0 && diamInch > 0 && lenInch > 0 && twistInch > 0) {
      final lCal = lenInch / diamInch;
      final nCal = twistInch / diamInch;
      sg =
          (30.0 * weightGr) /
          (nCal *
              nCal *
              diamInch *
              diamInch *
              diamInch *
              lCal *
              (1.0 + lCal * lCal));
    }

    // ── Trajectory data ────────────────────────────────────────────────────
    final hit = calc.value;
    final traj = hit?.trajectory ?? [];
    final atTarget = hit?.getAtDistance(Distance(targetDistM, Unit.meter));

    // Speed of sound: fps / mach at first point
    final double? soundSpeedFps = (traj.isNotEmpty && traj[0].mach > 0)
        ? ((traj[0].velocity as dynamic).in_(Unit.fps) as double) / traj[0].mach
        : null;

    // First-point energy (near barrel)
    final firstPoint = traj.isNotEmpty ? traj[0] : null;

    // Apex: trajectory point with maximum height
    TrajectoryData? apexPoint;
    if (traj.length > 1) {
      apexPoint = traj.reduce((a, b) {
        final ha = (a.height as dynamic).in_(Unit.foot) as double;
        final hb = (b.height as dynamic).in_(Unit.foot) as double;
        return ha >= hb ? a : b;
      });
    }

    // ── Helpers ────────────────────────────────────────────────────────────
    double conv(dynamic dim, Unit raw, Unit disp) {
      final v = (dim as dynamic).in_(raw) as double;
      return (raw(v) as dynamic).in_(disp) as double;
    }

    String fmtV(double? mps) {
      if (mps == null) return '—';
      final disp = (Unit.mps(mps) as dynamic).in_(units.velocity) as double;
      return '${disp.toStringAsFixed(FC.muzzleVelocity.accuracyFor(units.velocity))} ${units.velocity.symbol}';
    }

    String fmtDist(dynamic dim) {
      if (dim == null) return '—';
      final v = conv(dim, Unit.foot, units.distance);
      return '${v.toStringAsFixed(FC.targetDistance.accuracyFor(units.distance))} ${units.distance.symbol}';
    }

    String fmtDrop(dynamic dim) {
      if (dim == null) return '—';
      final v = conv(dim, Unit.foot, units.drop);
      return '${v.toStringAsFixed(FC.drop.accuracyFor(units.drop))} ${units.drop.symbol}';
    }

    String fmtEnergy(dynamic dim) {
      if (dim == null) return '—';
      final v = conv(dim, Unit.footPound, units.energy);
      return '${v.toStringAsFixed(FC.energy.accuracyFor(units.energy))} ${units.energy.symbol}';
    }

    // ── Values ─────────────────────────────────────────────────────────────
    final distDisp =
        (Unit.meter(targetDistM) as dynamic).in_(units.distance) as double;
    final distStr =
        '${distDisp.toStringAsFixed(FC.targetDistance.accuracyFor(units.distance))} ${units.distance.symbol}';

    final soundDisp = soundSpeedFps == null
        ? '—'
        : '${((Unit.fps(soundSpeedFps) as dynamic).in_(units.velocity) as double).toStringAsFixed(FC.velocity.accuracyFor(units.velocity))} ${units.velocity.symbol}';

    final items = <Widget>[
      SectionHeader('Velocity'),
      _InfoTile(
        icon: Icons.speed_outlined,
        label: 'Current muzzle velocity',
        value: fmtV(currentMvMps),
      ),
      _InfoTile(
        icon: Icons.speed_outlined,
        label: 'Zero muzzle velocity',
        value: fmtV(zeroMvMps),
      ),
      _InfoTile(
        icon: Icons.graphic_eq_outlined,
        label: 'Speed of sound',
        value: soundDisp,
      ),
      _InfoTile(
        icon: Icons.arrow_forward_outlined,
        label: 'Velocity at target',
        value: atTarget == null
            ? '—'
            : fmtV(conv(atTarget.velocity, Unit.fps, Unit.mps)),
      ),
      const Divider(height: 1),
      SectionHeader('Energy'),
      _InfoTile(
        icon: Icons.bolt_outlined,
        label: 'Energy at muzzle',
        value: fmtEnergy(firstPoint?.energy),
      ),
      _InfoTile(
        icon: Icons.bolt_outlined,
        label: 'Energy at target',
        value: fmtEnergy(atTarget?.energy),
      ),
      const Divider(height: 1),
      SectionHeader('Stability'),
      _InfoTile(
        icon: Icons.rotate_right_outlined,
        label: 'Gyroscopic stability factor',
        value: sg != null ? sg.toStringAsFixed(2) : '—',
      ),
      const Divider(height: 1),
      SectionHeader('Trajectory'),
      _InfoTile(
        icon: Icons.flag_outlined,
        label: 'Shot distance',
        value: distStr,
      ),
      _InfoTile(
        icon: Icons.height,
        label: 'Height at target',
        value: fmtDrop(atTarget?.height),
      ),
      _InfoTile(
        icon: Icons.architecture_outlined,
        label: 'Max height distance',
        value: apexPoint == null ? '—' : fmtDist(apexPoint.distance),
      ),
      _InfoTile(
        icon: Icons.arrow_right_alt_outlined,
        label: 'Windage',
        value: fmtDrop(atTarget?.windage),
      ),
      _InfoTile(
        icon: Icons.timer_outlined,
        label: 'Time to target',
        value: atTarget == null ? '—' : '${atTarget.time.toStringAsFixed(3)} s',
      ),
      const SizedBox(height: 16),
    ];

    return Column(
      children: [
        const _Header(),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => items[i],
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Text('Shot Info', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
