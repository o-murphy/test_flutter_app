import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../src/models/app_settings.dart';
import '../src/solver/unit.dart';

// ─── Units Screen ─────────────────────────────────────────────────────────────

class UnitsScreen extends ConsumerWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitSettingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    void set(String key, Unit unit) => notifier.setUnit(key, unit);

    return Column(
      children: [
        _Header(title: 'Units of Measurement'),
        Expanded(
          child: ListView(
            children: [
              _UnitTile(
                icon: Icons.speed_outlined,
                label: 'Velocity',
                current: units.velocity,
                options: const [Unit.mps, Unit.fps, Unit.kmh, Unit.mph],
                onChanged: (u) => set('velocity', u),
              ),
              _UnitTile(
                icon: Icons.straighten_outlined,
                label: 'Distance',
                current: units.distance,
                options: const [Unit.meter, Unit.yard, Unit.foot],
                onChanged: (u) => set('distance', u),
              ),
              _UnitTile(
                icon: Icons.vertical_align_center_outlined,
                label: 'Sight Height',
                current: units.sightHeight,
                options: const [Unit.millimeter, Unit.centimeter, Unit.inch],
                onChanged: (u) => set('sightHeight', u),
              ),
              _UnitTile(
                icon: Icons.compress_outlined,
                label: 'Pressure',
                current: units.pressure,
                options: const [Unit.hPa, Unit.mmHg, Unit.inHg, Unit.psi],
                onChanged: (u) => set('pressure', u),
              ),
              _UnitTile(
                icon: Icons.device_thermostat_outlined,
                label: 'Temperature',
                current: units.temperature,
                options: const [Unit.celsius, Unit.fahrenheit],
                onChanged: (u) => set('temperature', u),
              ),
              _UnitTile(
                icon: Icons.height_outlined,
                label: 'Drop / Windage',
                current: units.drop,
                options: const [
                  Unit.centimeter,
                  Unit.millimeter,
                  Unit.inch,
                  Unit.foot,
                ],
                onChanged: (u) => set('drop', u),
              ),
              _UnitTile(
                icon: Icons.rotate_90_degrees_cw_outlined,
                label: 'Drop / Windage angle',
                current: units.adjustment,
                options: const [
                  Unit.mil,
                  Unit.moa,
                  Unit.mRad,
                  Unit.cmPer100m,
                  Unit.inchesPer100Yd,
                ],
                onChanged: (u) => set('adjustment', u),
              ),
              _UnitTile(
                icon: Icons.bolt_outlined,
                label: 'Energy',
                current: units.energy,
                options: const [Unit.joule, Unit.footPound],
                onChanged: (u) => set('energy', u),
              ),
              _UnitTile(
                icon: Icons.balance_outlined,
                label: 'Bullet weight',
                current: units.weight,
                options: const [Unit.grain, Unit.gram],
                onChanged: (u) => set('weight', u),
              ),
              _UnitTile(
                icon: Icons.linear_scale_outlined,
                label: 'Bullet length',
                current: units.length,
                options: const [Unit.millimeter, Unit.centimeter, Unit.inch],
                onChanged: (u) => set('length', u),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Adjustment Display Screen ────────────────────────────────────────────────

class AdjustmentDisplayScreen extends ConsumerWidget {
  const AdjustmentDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      children: [
        _Header(title: 'Adjustment Display'),
        Expanded(
          child: ListView(
            children: [
              _SectionLabel('Format'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SegmentedButton<AdjustmentFormat>(
                  segments: const [
                    ButtonSegment(
                      value: AdjustmentFormat.arrows,
                      label: Text('↑/↓'),
                    ),
                    ButtonSegment(
                      value: AdjustmentFormat.signs,
                      label: Text('+/−'),
                    ),
                    ButtonSegment(
                      value: AdjustmentFormat.letters,
                      label: Text('U/D'),
                    ),
                  ],
                  selected: {settings.adjustmentFormat},
                  onSelectionChanged: (s) =>
                      notifier.setAdjustmentFormat(s.first),
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const Divider(height: 1),
              _SectionLabel('Show units'),
              SwitchListTile(
                title: const Text('MRAD', style: TextStyle(fontSize: 14)),
                value: settings.showMrad,
                onChanged: (v) => notifier.setAdjustmentToggle('showMrad', v),
                dense: true,
              ),
              SwitchListTile(
                title: const Text('MOA', style: TextStyle(fontSize: 14)),
                value: settings.showMoa,
                onChanged: (v) => notifier.setAdjustmentToggle('showMoa', v),
                dense: true,
              ),
              SwitchListTile(
                title: const Text('MIL', style: TextStyle(fontSize: 14)),
                value: settings.showMil,
                onChanged: (v) => notifier.setAdjustmentToggle('showMil', v),
                dense: true,
              ),
              SwitchListTile(
                title: const Text('cm / 100m', style: TextStyle(fontSize: 14)),
                value: settings.showCmPer100m,
                onChanged: (v) =>
                    notifier.setAdjustmentToggle('showCmPer100m', v),
                dense: true,
              ),
              SwitchListTile(
                title: const Text('in / 100yd', style: TextStyle(fontSize: 14)),
                value: settings.showInPer100yd,
                onChanged: (v) =>
                    notifier.setAdjustmentToggle('showInPer100yd', v),
                dense: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

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
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.icon,
    required this.label,
    required this.current,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final Unit current;
  final List<Unit> options;
  final ValueChanged<Unit> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        current.symbol,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      dense: true,
      onTap: () => _showPicker(context),
    );
  }

  void _showPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(label),
        children: options
            .map(
              (u) => RadioGroup<Unit>(
                groupValue: current,
                onChanged: (v) {
                  if (v != null) {
                    onChanged(v);
                    Navigator.pop(ctx);
                  }
                },
                child: RadioListTile<Unit>(
                  value: u,
                  title: Text('${u.label}  (${u.symbol})'),
                  dense: true,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
