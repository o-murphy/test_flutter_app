export 'shot_details_screen.dart';

import 'package:eballistica/shared/widgets/_stub_screen.dart';
import 'package:flutter/material.dart';

class RifleSelectScreen extends StatelessWidget {
  const RifleSelectScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Select Rifle');
}

class RifleEditScreen extends StatelessWidget {
  const RifleEditScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Edit Rifle');
}

class SightSelectScreen extends StatelessWidget {
  const SightSelectScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Select Sight');
}

class CartridgeScreen extends StatelessWidget {
  const CartridgeScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Cartridge');
}

class CartridgeEditScreen extends StatelessWidget {
  const CartridgeEditScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Edit Cartridge');
}

class ProjectileSelectScreen extends StatelessWidget {
  const ProjectileSelectScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Select Projectile');
}

class ProjectileEditScreen extends StatelessWidget {
  const ProjectileEditScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Edit Projectile');
}
