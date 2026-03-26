import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/widgets/icon_value_button.dart';
import 'package:eballistica/shared/widgets/unit_value_field.dart';

class QuickActionsPanel extends ConsumerWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(shotProfileProvider).value;
    final units   = ref.watch(unitSettingsProvider);
    final notifier = ref.read(shotProfileProvider.notifier);

    // ── Wind speed ──────────────────────────────────────────────────────────
    final windMps = profile?.winds.isNotEmpty == true
        ? profile!.winds.first.velocity.in_(Unit.mps)
        : 0.0;
    final windDisp = Unit.mps(windMps).in_(units.velocity);
    final windStr  = '${windDisp.toStringAsFixed(FC.windVelocity.accuracyFor(units.velocity))} ${units.velocity.symbol}';

    // ── Look angle ──────────────────────────────────────────────────────────
    final lookDeg = profile?.lookAngle.in_(Unit.degree) ?? 0.0;
    final lookStr = '${lookDeg.toStringAsFixed(FC.lookAngle.accuracy)}°';

    // ── Target distance ─────────────────────────────────────────────────────
    final distM    = profile?.targetDistance.in_(Unit.meter) ?? 300.0;
    final distDisp = Unit.meter(distM).in_(units.distance);
    final distStr  = '${distDisp.toStringAsFixed(FC.targetDistance.accuracyFor(units.distance))} ${units.distance.symbol}';

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
