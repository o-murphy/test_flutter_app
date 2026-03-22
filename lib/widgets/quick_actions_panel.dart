import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/unit.dart';
import 'icon_value_button.dart';
import 'unit_value_field.dart';

class QuickActionsPanel extends ConsumerWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(shotProfileProvider).value;
    final units   = ref.watch(unitSettingsProvider);
    final notifier = ref.read(shotProfileProvider.notifier);

    // ── Wind speed ──────────────────────────────────────────────────────────
    final windMps = profile?.winds.isNotEmpty == true
        ? (profile!.winds.first.velocity as dynamic).in_(Unit.mps) as double
        : 0.0;
    final windDisp = (Unit.mps(windMps) as dynamic).in_(units.velocity) as double;
    final windStr  = '${windDisp.toStringAsFixed(1)} ${units.velocity.symbol}';

    // ── Look angle ──────────────────────────────────────────────────────────
    final lookDeg = (profile?.lookAngle as dynamic)?.in_(Unit.degree) as double? ?? 0.0;
    final lookStr = '${lookDeg.toStringAsFixed(1)}°';

    // ── Target distance ─────────────────────────────────────────────────────
    final distM    = (profile?.targetDistance as dynamic)?.in_(Unit.meter) as double? ?? 300.0;
    final distDisp = (Unit.meter(distM) as dynamic).in_(units.distance) as double;
    final distStr  = '${distDisp.toStringAsFixed(0)} ${units.distance.symbol}';

    return IconValueButtonRow(
      height: 104,
      items: [
        IconValueButton(
          icon: Icons.air_outlined,
          value: windStr,
          label: 'Wind speed',
          heroTag: 'qa-wind',
          onTap: () => showUnitEditDialog(
            context,
            label: 'Wind speed',
            rawValue: windMps,
            constraints: FC.windVelocity,
            displayUnit: units.velocity,
            onChanged: notifier.updateWindSpeed,
          ),
        ),
        IconValueButton(
          icon: Icons.square_foot,
          value: lookStr,
          label: 'Look angle',
          heroTag: 'qa-angle',
          onTap: () => showUnitEditDialog(
            context,
            label: 'Look angle',
            rawValue: lookDeg,
            constraints: FC.lookAngle,
            displayUnit: Unit.degree,
            onChanged: notifier.updateLookAngle,
          ),
        ),
        IconValueButton(
          icon: Icons.flag_outlined,
          value: distStr,
          label: 'Target range',
          heroTag: 'qa-range',
          onTap: () => showUnitEditDialog(
            context,
            label: 'Target range',
            rawValue: distM,
            constraints: FC.targetDistance,
            displayUnit: units.distance,
            onChanged: notifier.updateTargetDistance,
          ),
        ),
      ],
    );
  }
}
