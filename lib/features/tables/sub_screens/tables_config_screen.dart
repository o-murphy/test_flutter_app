import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';
import 'package:eballistica/shared/widgets/unit_value_field_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

// ─── Table Configuration Screen ───────────────────────────────────────────────

class TableConfigScreen extends ConsumerWidget {
  const TableConfigScreen({super.key});

  static void _toggleColumnVisibility(
    String colId,
    bool visible,
    TableConfig cfg,
    void Function(TableConfig) save,
  ) {
    final hidden = Set<String>.from(cfg.hiddenCols);
    if (visible) {
      hidden.remove(colId);
    } else {
      hidden.add(colId);
    }
    save(cfg.copyWith(hiddenCols: hidden));
  }

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

          _ConstrainedDistanceTile(
            icon: Icons.first_page_outlined,
            label: 'Start distance',
            rawValueM: cfg.startM,
            constraints: FC.tableRange,
            displayUnit: distanceUnit,
            maxRawM: cfg.endM, // no more than end
            onChanged: (v) => save(cfg.copyWith(startM: v)),
          ),

          _ConstrainedDistanceTile(
            icon: Icons.last_page_outlined,
            label: 'End distance',
            rawValueM: cfg.endM,
            constraints: FC.tableRange,
            displayUnit: distanceUnit,
            minRawM: cfg.startM, // not less than start
            onChanged: (v) => save(cfg.copyWith(endM: v)),
          ),

          _ConstrainedDistanceTile(
            icon: Icons.straighten_outlined,
            label: 'Distance step',
            rawValueM: cfg.stepM,
            constraints: FC.distanceStep,
            displayUnit: distanceUnit,
            onChanged: (v) => save(cfg.copyWith(stepM: v)),
          ),

          const Divider(height: 1),

          // ── Extra tables ───────────────────────────────────────────────
          const ListSectionTile('Extra'),

          SwitchListTile(
            secondary: const Icon(Icons.swap_vert_outlined),
            title: const Text('Show zero crossings table'),
            value: cfg.showZeros,
            onChanged: (v) => save(cfg.copyWith(showZeros: v)),
            dense: true,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.speed_outlined),
            title: const Text('Show subsonic transition'),
            value: cfg.showSubsonicTransition,
            onChanged: (v) => save(cfg.copyWith(showSubsonicTransition: v)),
            dense: true,
          ),

          const Divider(height: 1),
          const ListSectionTile('Visible columns'),

          for (final col in _columnDefs)
            if (!col.alwaysOn)
              SwitchListTile(
                title: Text(col.label),
                value: !cfg.hiddenCols.contains(col.id),
                onChanged: (v) => _toggleColumnVisibility(col.id, v, cfg, save),
                dense: true,
              ),

          const Divider(height: 1),
          const ListSectionTile('Adjustment columns'),

          SwitchListTile(
            title: const Text('MRAD'),
            value: cfg.tableShowMrad,
            onChanged: (v) => save(cfg.copyWith(tableShowMrad: v)),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('MOA'),
            value: cfg.tableShowMoa,
            onChanged: (v) => save(cfg.copyWith(tableShowMoa: v)),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('MIL'),
            value: cfg.tableShowMil,
            onChanged: (v) => save(cfg.copyWith(tableShowMil: v)),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('cm/100m'),
            value: cfg.tableShowCmPer100m,
            onChanged: (v) => save(cfg.copyWith(tableShowCmPer100m: v)),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('in/100yd'),
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

/// Distance tile with cross-field constraints (min/max in metres).
class _ConstrainedDistanceTile extends StatelessWidget {
  const _ConstrainedDistanceTile({
    required this.icon,
    required this.label,
    required this.rawValueM,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    this.minRawM,
    this.maxRawM,
  });

  final IconData icon;
  final String label;
  final double rawValueM;
  final FieldConstraints constraints;
  final Unit displayUnit;
  final ValueChanged<double> onChanged;
  final double? minRawM;
  final double? maxRawM;

  @override
  Widget build(BuildContext context) {
    final effectiveMin =
        minRawM?.clamp(constraints.minRaw, constraints.maxRaw) ??
        constraints.minRaw;
    final effectiveMax =
        maxRawM?.clamp(constraints.minRaw, constraints.maxRaw) ??
        constraints.maxRaw;

    final updatedConstraints = FieldConstraints(
      rawUnit: constraints.rawUnit,
      minRaw: effectiveMin,
      maxRaw: effectiveMax,
      stepRaw: constraints.stepRaw,
      accuracy: constraints.accuracy,
    );

    return UnitValueFieldTile(
      icon: icon,
      label: label,
      rawValue: rawValueM,
      constraints: updatedConstraints,
      displayUnit: displayUnit,
      onChanged: onChanged,
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
