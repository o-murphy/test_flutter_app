import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eballistica/router.dart';

// ─── Convertor tile data ──────────────────────────────────────────────────────

const _convertors = [
  (type: 'target-distance', label: 'Target Distance', icon: Icons.my_location_outlined),
  (type: 'velocity',        label: 'Velocity',        icon: Icons.speed_outlined),
  (type: 'length',          label: 'Length',          icon: Icons.straighten_outlined),
  (type: 'weight',          label: 'Weight',          icon: Icons.scale_outlined),
  (type: 'pressure',        label: 'Pressure',        icon: Icons.compress_outlined),
  (type: 'temperature',     label: 'Temperature',     icon: Icons.device_thermostat_outlined),
  (type: 'mil-moa',         label: 'MIL / MOA',       icon: Icons.square_foot),
  (type: 'torque',          label: 'Torque',          icon: Icons.settings_outlined),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class ConvertorScreen extends StatelessWidget {
  const ConvertorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _convertors.length,
                itemBuilder: (context, i) => _ConvertorTile(
                  type:  _convertors[i].type,
                  label: _convertors[i].label,
                  icon:  _convertors[i].icon,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
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
                onPressed: () => context.go(Routes.home),
              ),
            ),
            Text(
              'Convertors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _ConvertorTile extends StatelessWidget {
  const _ConvertorTile({required this.type, required this.label, required this.icon});
  final String   type;
  final String   label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.convertorOf(type)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
