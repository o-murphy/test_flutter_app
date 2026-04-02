// ── Profile Card ──────────────────────────────────────────────────────────────
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/models/projectile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/router.dart';
import 'package:eballistica/shared/widgets/info_tile.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileCard extends ConsumerWidget {
  const ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onSelect,
    super.key,
  });

  final ShotProfile profile;
  final bool isActive;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formatter = ref.read(unitFormatterProvider);

    final proj = profile.cartridge.projectile;
    final bcAcc = FC.ballisticCoefficient.accuracy;
    final firstBc = proj.coefRows.isNotEmpty ? proj.coefRows.first.bcCd : 0.0;
    final dragStr = switch (proj.dragType) {
      DragModelType.g1 =>
        proj.isMultiBC ? 'G1 Multi' : 'G1 ${firstBc.toStringAsFixed(bcAcc)}',
      DragModelType.g7 =>
        proj.isMultiBC ? 'G7 Multi' : 'G7 ${firstBc.toStringAsFixed(bcAcc)}',
      DragModelType.custom => 'CUSTOM',
    };

    return Card(
      color: colorScheme.surfaceContainer,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ProfileTitleRow(title: profile.name, isActive: isActive),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _ProfileControls(),
                  ListSectionTile("Rifle"),
                  ListTile(
                    leading: const Icon(Icons.military_tech_outlined),
                    title: Text(profile.rifle.name),
                    dense: true,
                    trailing: IconButton(
                      onPressed: () => context.go(Routes.profileEditRifle),
                      icon: Icon(Icons.edit_outlined, size: 16),
                    ),
                  ),
                  InfoListTile(
                    label: "Caliber",
                    value: formatter.diameter(
                      profile.cartridge.projectile.diameter,
                    ),
                    icon: Icons.circle_outlined,
                  ),
                  InfoListTile(
                    label: "Twist",
                    value: formatter.twist(profile.rifle.twist),
                    icon: Icons.rotate_left_outlined,
                  ),
                  InfoListTile(
                    label: "Twist direction",
                    value: profile.rifle.twist.raw > 0 ? "right" : "left",
                    icon: Icons.rotate_left_outlined,
                  ),
                  const Divider(height: 1),
                  ListSectionTile("Cartridge"),
                  ListTile(
                    leading: const Icon(Icons.grain_outlined),
                    title: Text(profile.cartridge.name),
                    dense: true,
                    trailing: IconButton(
                      onPressed: () => context.go(Routes.profileEditCartridge),
                      icon: Icon(Icons.edit_outlined, size: 16),
                    ),
                  ),
                  InfoListTile(
                    label: "Drag model",
                    value: dragStr,
                    icon: Icons.trending_up_outlined,
                  ),
                  InfoListTile(
                    label: "Muzzle velocity",
                    value: formatter.velocity(profile.cartridge.mv),
                    icon: Icons.speed_outlined,
                  ),
                  InfoListTile(
                    label: "Caliber",
                    value: formatter.diameter(
                      profile.cartridge.projectile.diameter,
                    ),
                    icon: Icons.circle_outlined,
                  ),
                  InfoListTile(
                    label: "Weight",
                    value: formatter.weight(
                      profile.cartridge.projectile.weight,
                    ),
                    icon: Icons.balance_outlined,
                  ),
                  const Divider(height: 1),
                  ListSectionTile("Sight"),
                  ListTile(
                    leading: const Icon(Icons.my_location_outlined),
                    title: Text(profile.sight.name),
                    dense: true,
                    trailing: IconButton(
                      onPressed: () => context.go(Routes.profileEditSight),
                      icon: Icon(Icons.edit_outlined, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: FilledButton(
                onPressed: onSelect,
                child: Text(!isActive ? 'Select' : 'Go to calculations'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTitleRow extends StatelessWidget {
  const _ProfileTitleRow({required this.title, required this.isActive});

  final String title;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        if (isActive) Icon(Icons.check_circle, color: colorScheme.primary),
      ],
    );
  }
}

class _ProfileControls extends StatelessWidget {
  const _ProfileControls();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 200,
      child: Card(
        child: Stack(
          children: [
            // Main content
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.control_point, size: 48),
                  SizedBox(height: 8),
                  Text('Profile Controls Area'),
                ],
              ),
            ),

            // Top left button
            Positioned(
              top: 8,
              left: 8,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'select_sight_button',
                onPressed: () => context.push(Routes.sightSelect),
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                child: const Icon(Icons.my_location_outlined, size: 20),
              ),
            ),

            // Bottom right button
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'select_cartridge_button',
                onPressed: () => context.push(Routes.cartridgeSelect),
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: const Icon(Icons.rocket_launch_outlined, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
