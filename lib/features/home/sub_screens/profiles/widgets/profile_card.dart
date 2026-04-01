// ── Profile Card ──────────────────────────────────────────────────────────────

import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/router.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainer,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ProfileTitleRow(title: profile.name, isActive: isActive),
            const SizedBox(height: 16), // Додаємо відступ
            Expanded(
              child: ListView(
                children: [
                  _ProfileControls(),
                  ListSectionTile(
                    "Rifle",
                    trailing: IconButton(
                      onPressed: () => debugPrint("Rifle edit"),
                      icon: Icon(
                        Icons.edit,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.military_tech_outlined),
                    title: Text(profile.rifle.name),
                    dense: true,
                    onTap: () => debugPrint("edit rifle"),
                  ),
                  const Divider(height: 1),
                  ListSectionTile(
                    "Cartridge",
                    trailing: IconButton(
                      onPressed: () => debugPrint("Cartridge edit"),
                      icon: Icon(
                        Icons.edit,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.grain_outlined),
                    title: Text(profile.cartridge.name),
                    dense: true,
                    onTap: () => debugPrint("edit cartridge"),
                  ),
                  const Divider(height: 1),
                  ListSectionTile(
                    "Sight",
                    trailing: IconButton(
                      onPressed: () => debugPrint("Sight edit"),
                      icon: Icon(
                        Icons.edit,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.my_location_outlined),
                    title: Text(profile.sight.name),
                    dense: true,
                    onTap: () => debugPrint("edit sight"),
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
            // Основний контент
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

            // Ліва верхня кнопка
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

            // Права нижня кнопка
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
