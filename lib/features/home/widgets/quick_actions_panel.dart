import 'package:eballistica/shared/widgets/unit_constrained_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/features/home/home_vm.dart';
import 'package:eballistica/shared/widgets/icon_value_button.dart';

class QuickActionsPanel extends ConsumerWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeVmProvider).value;
    if (state is! HomeUiReady) return const SizedBox.shrink();

    final units = ref.watch(unitSettingsProvider);
    final notifier = ref.read(homeVmProvider.notifier);

    return IconValueButtonRow(
      height: 104,
      items: [
        IconValueButton(
          icon: Icons.air_outlined,
          value: state.windSpeedDisplay,
          label: 'Wind speed',
          heroTag: 'qa-wind',
          onTap: () => showUnitEditDialog(
            context,
            label: 'Wind speed',
            rawValue: state.windSpeedMps,
            constraints: FC.windVelocity,
            displayUnit: units.velocity,
            onChanged: notifier.updateWindSpeed,
          ),
        ),
        IconValueButton(
          icon: Icons.square_foot,
          value: state.lookAngleDisplay,
          label: 'Look angle',
          heroTag: 'qa-angle',
          onTap: () => showUnitEditDialog(
            context,
            label: 'Look angle',
            rawValue: state.lookAngleDeg,
            constraints: FC.lookAngle,
            displayUnit: Unit.degree,
            onChanged: notifier.updateLookAngle,
          ),
        ),
        IconValueButton(
          icon: Icons.flag_outlined,
          value: state.targetDistanceDisplay,
          label: 'Target range',
          heroTag: 'qa-range',
          onTap: () => showUnitEditDialog(
            context,
            label: 'Target range',
            rawValue: state.targetDistanceM,
            constraints: FC.targetDistance,
            displayUnit: units.distance,
            onChanged: notifier.updateTargetDistance,
          ),
        ),
      ],
    );
  }
}
