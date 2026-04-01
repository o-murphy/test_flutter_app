export 'shot_details_screen.dart';
export 'profiles_screen.dart';

import 'package:eballistica/shared/widgets/_stub_screen.dart';
import 'package:flutter/material.dart';

// ── Profile Add ───────────────────────────────────────────────────────────────

class ProfileAddScreen extends StatelessWidget {
  const ProfileAddScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Add Profile');
}

// ── Rifle ─────────────────────────────────────────────────────────────────────

class CreateRifleWizardScreen extends StatelessWidget {
  const CreateRifleWizardScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Create Rifle');
}

class SelectRifleCollectionScreen extends StatelessWidget {
  const SelectRifleCollectionScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Rifle Collection');
}

class RifleEditScreen extends StatelessWidget {
  const RifleEditScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Edit Rifle');
}

// ── Cartridge ─────────────────────────────────────────────────────────────────

class CartridgeSelectScreen extends StatelessWidget {
  const CartridgeSelectScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Select Cartridge');
}

class CreateCartridgeWizardScreen extends StatelessWidget {
  const CreateCartridgeWizardScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Create Cartridge');
}

class SelectCartridgeCollectionScreen extends StatelessWidget {
  const SelectCartridgeCollectionScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Cartridge Collection');
}

class CartridgeEditScreen extends StatelessWidget {
  const CartridgeEditScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Edit Cartridge');
}

// ── Projectile (future) ───────────────────────────────────────────────────────

class ProjectileSelectScreen extends StatelessWidget {
  const ProjectileSelectScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Select Projectile');
}

class CreateProjectileWizardScreen extends StatelessWidget {
  const CreateProjectileWizardScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Create Projectile');
}

class SelectProjectileCollectionScreen extends StatelessWidget {
  const SelectProjectileCollectionScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Projectile Collection');
}

// ── Sight ─────────────────────────────────────────────────────────────────────

class SightSelectScreen extends StatelessWidget {
  const SightSelectScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Select Sight');
}

class CreateSightWizardScreen extends StatelessWidget {
  const CreateSightWizardScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Create Sight');
}

class SelectSightCollectionScreen extends StatelessWidget {
  const SelectSightCollectionScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Sight Collection');
}

class SightEditScreen extends StatelessWidget {
  const SightEditScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Edit Sight');
}
