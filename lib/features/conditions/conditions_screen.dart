import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eballistica/router.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/features/conditions/conditions_vm.dart';
import 'package:eballistica/features/conditions/widgets/temperature_control.dart';
import 'package:eballistica/shared/widgets/unit_value_field.dart';

class ConditionsScreen extends ConsumerWidget {
  const ConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(conditionsVmProvider);
    final state = vmAsync.value;

    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final notifier = ref.read(conditionsVmProvider.notifier);

    return Column(
      children: [
        const _Header(),
        Expanded(
          child: ListView(
            children: [
              // ── Temperature — big centred control ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: TempControl(
                  rawValue: state.temperature.rawValue,
                  displayUnit: state.temperature.displayUnit,
                  onChanged: (v) => notifier.updateTemperature(v),
                ),
              ),
              const Divider(height: 1),

              // ── Altitude / Humidity / Pressure ────────────────────────────
              UnitValueField(
                label: 'Altitude',
                icon: Icons.terrain_outlined,
                rawValue: state.altitude.rawValue,
                constraints: FC.altitude,
                displayUnit: state.altitude.displayUnit,
                onChanged: (v) => notifier.updateAltitude(v),
              ),
              UnitValueField(
                label: 'Humidity',
                icon: Icons.water_drop_outlined,
                rawValue: state.humidity.rawValue,
                constraints: FC.humidity,
                displayUnit: state.humidity.displayUnit,
                symbol: '%',
                onChanged: (v) => notifier.updateHumidity(v),
              ),
              UnitValueField(
                label: 'Pressure',
                icon: Icons.speed_outlined,
                rawValue: state.pressure.rawValue,
                constraints: FC.pressure,
                displayUnit: state.pressure.displayUnit,
                onChanged: (v) => notifier.updatePressure(v),
              ),
              const Divider(height: 1),

              // ── Switches ──────────────────────────────────────────────────
              _SwitchTile(
                label: 'Powder temperature sensitivity',
                icon: Icons.local_fire_department_outlined,
                value: state.powderSensOn,
                onChanged: (v) => notifier.setPowderSensitivity(v),
              ),
              if (state.powderSensOn) ...[
                _SwitchTile(
                  label: 'Use different powder temperature',
                  icon: Icons.thermostat_outlined,
                  value: state.useDiffPowderTemp,
                  onChanged: (v) => notifier.setDiffPowderTemp(v),
                ),
                if (state.powderTemperature != null)
                  UnitValueField(
                    label: 'Powder temperature',
                    icon: Icons.local_fire_department_outlined,
                    rawValue: state.powderTemperature!.rawValue,
                    constraints: FC.temperature,
                    displayUnit: state.powderTemperature!.displayUnit,
                    onChanged: (v) => notifier.updatePowderTemp(v),
                  ),
                if (state.mvAtPowderTemp != null)
                  _InfoTile(
                    label: 'Muzzle velocity at powder temp',
                    value: state.mvAtPowderTemp!,
                    icon: Icons.speed_outlined,
                  ),
                if (state.powderSensitivity != null)
                  _InfoTile(
                    label: 'Powder sensitivity',
                    value: state.powderSensitivity!,
                    icon: Icons.show_chart_outlined,
                  ),
              ],
              const Divider(height: 1),
              _SwitchTile(
                label: 'Coriolis effect',
                icon: Icons.rotate_right_outlined,
                value: state.coriolisOn,
                onChanged: (v) => notifier.setCoriolis(v),
              ),
              _SwitchTile(
                label: 'Spin drift (derivation)',
                icon: Icons.rotate_left_outlined,
                value: state.derivationOn,
                onChanged: (v) => notifier.setDerivation(v),
              ),
              // Always ON — engine limitation, control disabled
              const _SwitchTile(
                label: 'Aerodynamic jump',
                icon: Icons.air_outlined,
                value: true,
                onChanged: null,
              ),
              const _SwitchTile(
                label: 'Pressure depends on altitude',
                icon: Icons.compress_outlined,
                value: true,
                onChanged: null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

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
            Text('Conditions', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

// ─── Info tile (readonly) ────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Switch tile ──────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }
}
