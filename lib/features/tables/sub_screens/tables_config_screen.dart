import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

// ─── Table Configuration Screen ───────────────────────────────────────────────

class TableConfigScreen extends ConsumerWidget {
  const TableConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final cfg = settings.tableConfig;
    final notifier = ref.read(settingsProvider.notifier);
    final distanceUnit = settings.units.distance;

    void save(TableConfig updated) => notifier.updateTableConfig(updated);

    return BaseScreen(
      title: 'Table Configuration',
      isSubscreen: true,
      body: ListView(
        children: [
          // ── Range ──────────────────────────────────────────────────────
          const ListSectionTile('Range'),

          _DistanceTile(
            icon: Icons.first_page_outlined,
            label: 'Start distance',
            valueM: cfg.startM,
            units: distanceUnit,
            constraints: FC.tableRange,
            maxValueM: cfg.endM,
            onChanged: (v) => save(cfg.copyWith(startM: v)),
          ),
          _DistanceTile(
            icon: Icons.last_page_outlined,
            label: 'End distance',
            valueM: cfg.endM,
            units: distanceUnit,
            constraints: FC.tableRange,
            minValueM: cfg.startM,
            onChanged: (v) => save(cfg.copyWith(endM: v)),
          ),

          _DistanceTile(
            icon: Icons.straighten_outlined,
            label: 'Distance step',
            valueM: cfg.stepM,
            units: distanceUnit,
            constraints: FC.distanceStep,
            onChanged: (v) => save(cfg.copyWith(stepM: v)),
          ),

          const Divider(height: 1),

          // ── Extra tables ───────────────────────────────────────────────
          const ListSectionTile('Extra'),

          SwitchListTile(
            secondary: const Icon(Icons.swap_vert_outlined),
            title: const Text(
              'Show zero crossings table',
              style: TextStyle(fontSize: 14),
            ),
            value: cfg.showZeros,
            onChanged: (v) => save(cfg.copyWith(showZeros: v)),
            dense: true,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.speed_outlined),
            title: const Text(
              'Show subsonic transition',
              style: TextStyle(fontSize: 14),
            ),
            value: cfg.showSubsonicTransition,
            onChanged: (v) => save(cfg.copyWith(showSubsonicTransition: v)),
            dense: true,
          ),

          const Divider(height: 1),
          const ListSectionTile('Visible columns'),

          for (final col in _columnDefs)
            if (!col.alwaysOn)
              SwitchListTile(
                title: Text(col.label, style: const TextStyle(fontSize: 14)),
                value: !cfg.hiddenCols.contains(col.id),
                onChanged: (v) {
                  final hidden = Set<String>.from(cfg.hiddenCols);
                  if (v) {
                    hidden.remove(col.id);
                  } else {
                    hidden.add(col.id);
                  }
                  save(cfg.copyWith(hiddenCols: hidden));
                },
                dense: true,
              ),

          const Divider(height: 1),
          const ListSectionTile('Adjustment columns'),

          SwitchListTile(
            title: const Text('MRAD', style: TextStyle(fontSize: 14)),
            value: cfg.tableShowMrad,
            onChanged: (v) => save(cfg.copyWith(tableShowMrad: v)),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('MOA', style: TextStyle(fontSize: 14)),
            value: cfg.tableShowMoa,
            onChanged: (v) => save(cfg.copyWith(tableShowMoa: v)),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('MIL', style: TextStyle(fontSize: 14)),
            value: cfg.tableShowMil,
            onChanged: (v) => save(cfg.copyWith(tableShowMil: v)),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('cm/100m', style: TextStyle(fontSize: 14)),
            value: cfg.tableShowCmPer100m,
            onChanged: (v) => save(cfg.copyWith(tableShowCmPer100m: v)),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('in/100yd', style: TextStyle(fontSize: 14)),
            value: cfg.tableShowInPer100yd,
            onChanged: (v) => save(cfg.copyWith(tableShowInPer100yd: v)),
            dense: true,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
}

// ── Distance tile with text field dialog ──────────────────────────────────────

class _DistanceTile extends StatelessWidget {
  const _DistanceTile({
    required this.icon,
    required this.label,
    required this.valueM,
    required this.units,
    required this.constraints,
    required this.onChanged,
    this.minValueM,
    this.maxValueM,
  });

  final IconData icon;
  final String label;
  final double valueM;
  final Unit units;
  final FieldConstraints constraints;
  final ValueChanged<double> onChanged;

  /// Cross-field lower bound (metres). Overrides constraints.minRaw if set.
  final double? minValueM;

  /// Cross-field upper bound (metres). Overrides constraints.maxRaw if set.
  final double? maxValueM;

  @override
  Widget build(BuildContext context) {
    final acc = constraints.accuracyFor(units);
    final disp = Distance(valueM, Unit.meter).in_(units);
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        '${disp.toStringAsFixed(acc)} ${units.symbol}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      dense: true,
      onTap: () => _showDialog(context, disp, acc),
    );
  }

  void _showDialog(BuildContext context, double currentDisp, int acc) {
    final ctrl = TextEditingController(text: currentDisp.toStringAsFixed(acc));
    final effectiveMinM = (minValueM != null && minValueM! > constraints.minRaw)
        ? minValueM!
        : constraints.minRaw;
    final effectiveMaxM = (maxValueM != null && maxValueM! < constraints.maxRaw)
        ? maxValueM!
        : constraints.maxRaw;
    final minDisp = Distance(effectiveMinM, Unit.meter).in_(units);
    final maxDisp = Distance(effectiveMaxM, Unit.meter).in_(units);
    final rangeMsg =
        '${minDisp.toStringAsFixed(acc)}–${maxDisp.toStringAsFixed(acc)} ${units.symbol}';

    String? error;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('$label (${units.symbol})'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: units.symbol,
              errorText: error,
            ),
            onChanged: (t) {
              setState(() {
                final v = double.tryParse(t.replaceAll(',', '.'));
                if (v == null) {
                  error = 'Invalid number';
                } else {
                  final rawM = Distance(v, units).in_(Unit.meter);
                  error = (rawM < effectiveMinM || rawM > effectiveMaxM)
                      ? rangeMsg
                      : null;
                }
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: error != null
                  ? null
                  : () {
                      final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
                      if (v != null) {
                        final rawM = Distance(v, units).in_(Unit.meter);
                        onChanged(rawM.clamp(effectiveMinM, effectiveMaxM));
                      }
                      Navigator.pop(ctx);
                    },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Column catalogue (mirrors trajectory_table.dart) ─────────────────────────

class _ColEntry {
  final String id;
  final String label;
  final bool alwaysOn;
  const _ColEntry(this.id, this.label, {this.alwaysOn = false});
}

const _columnDefs = [
  _ColEntry('range', 'Range', alwaysOn: true),
  _ColEntry('time', 'Time'),
  _ColEntry('velocity', 'Velocity'),
  _ColEntry('height', 'Height'),
  _ColEntry('drop', 'Drop (slant height)'),
  _ColEntry('adjDrop', 'Drop adjustment'),
  _ColEntry('wind', 'Windage'),
  _ColEntry('adjWind', 'Windage adjustment'),
  _ColEntry('mach', 'Mach'),
  _ColEntry('drag', 'Drag coefficient'),
  _ColEntry('energy', 'Energy'),
];
