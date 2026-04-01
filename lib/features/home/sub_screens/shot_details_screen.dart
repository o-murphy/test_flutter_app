import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/info_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/features/home/shot_details_vm.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';

class ShotDetailsScreen extends ConsumerWidget {
  const ShotDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shotDetailsVmProvider);

    return BaseScreen(
      title: 'Shot Info',
      isSubscreen: true,
      body: state.when(
        data: (uiState) => _buildContent(context, uiState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ShotDetailsUiState state) {
    if (state is! ShotDetailsReady) {
      if (state is ShotDetailsError) return Center(child: Text(state.message));
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        const ListSectionTile('Velocity'),
        InfoTile(
          icon: Icons.speed_outlined,
          label: 'Current muzzle velocity',
          value: state.currentMv,
        ),
        InfoTile(
          icon: Icons.speed_outlined,
          label: 'Zero muzzle velocity',
          value: state.zeroMv,
        ),
        InfoTile(
          icon: Icons.graphic_eq_outlined,
          label: 'Speed of sound',
          value: state.speedOfSound,
        ),
        InfoTile(
          icon: Icons.arrow_forward_outlined,
          label: 'Velocity at target',
          value: state.velocityAtTarget,
        ),
        const Divider(height: 1),
        const ListSectionTile('Energy'),
        InfoTile(
          icon: Icons.bolt_outlined,
          label: 'Energy at muzzle',
          value: state.energyAtMuzzle,
        ),
        InfoTile(
          icon: Icons.bolt_outlined,
          label: 'Energy at target',
          value: state.energyAtTarget,
        ),
        const Divider(height: 1),
        const ListSectionTile('Stability'),
        InfoTile(
          icon: Icons.rotate_right_outlined,
          label: 'Gyroscopic stability factor',
          value: state.gyroscopicStability,
        ),
        const Divider(height: 1),
        const ListSectionTile('Trajectory'),
        InfoTile(
          icon: Icons.flag_outlined,
          label: 'Shot distance',
          value: state.shotDistance,
        ),
        InfoTile(
          icon: Icons.height,
          label: 'Height at target',
          value: state.heightAtTarget,
        ),
        InfoTile(
          icon: Icons.architecture_outlined,
          label: 'Max height distance',
          value: state.maxHeightDistance,
        ),
        InfoTile(
          icon: Icons.arrow_right_alt_outlined,
          label: 'Windage',
          value: state.windage,
        ),
        InfoTile(
          icon: Icons.timer_outlined,
          label: 'Time to target',
          value: state.timeToTarget,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
