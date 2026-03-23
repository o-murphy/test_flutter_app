import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../router.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/conditions.dart' as solver;
import '../src/solver/unit.dart';
import '../widgets/unit_value_field.dart';

class ConditionsScreen extends ConsumerWidget {
  const ConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(shotProfileProvider).value;
    final settings = ref.watch(settingsProvider).value;
    final units = ref.watch(unitSettingsProvider);

    final atmo = profile?.conditions;

    final tempRaw = atmo?.temperature.in_(Unit.celsius) ?? 15.0;
    final altRaw = atmo?.altitude.in_(Unit.meter) ?? 0.0;
    final pressRaw = atmo?.pressure.in_(Unit.hPa) ?? 1013.25;
    final humRaw = (atmo?.humidity ?? 0.5) * 100;

    final powderSensOn = settings?.enablePowderSensitivity ?? false;
    final useDiffPowderTemp =
        powderSensOn && (settings?.useDifferentPowderTemperature ?? false);

    final powderTempRaw = useDiffPowderTemp
        ? (atmo?.powderTemp.in_(Unit.celsius) ?? tempRaw)
        : tempRaw;

    // Readonly values calculated from cartridge
    final cartridge = profile?.cartridge;
    final refMvMps =
        (cartridge?.mv as dynamic)?.in_(Unit.mps) as double? ?? 0.0;
    final refPowderTempC =
        (cartridge?.powderTemp as dynamic)?.in_(Unit.celsius) as double? ??
        15.0;
    final tempModifier = cartridge?.tempModifier ?? 0.0;

    double mvAtTemp(double tC) {
      if (refMvMps <= 0 || tempModifier == 0) return refMvMps;
      return (tempModifier / 100.0 / (15 / refMvMps)) * (tC - refPowderTempC) +
          refMvMps;
    }

    final currentMvMps = mvAtTemp(powderTempRaw);
    final currentMvDisp =
        (Unit.mps(currentMvMps) as dynamic).in_(units.velocity) as double;
    final mvStr =
        '${currentMvDisp.toStringAsFixed(FC.muzzleVelocity.accuracy)} ${units.velocity.symbol}';
    final sensStr = '${tempModifier.toStringAsFixed(2)} %/15°C';

    void updateAtmo({
      double? tempC,
      double? altM,
      double? pressHPa,
      double? humPct,
      double? powderTempC,
    }) {
      final newTempC = tempC ?? tempRaw;
      ref
          .read(shotProfileProvider.notifier)
          .updateConditions(
            solver.Atmo(
              temperature: Temperature(newTempC, Unit.celsius),
              altitude: Distance(altM ?? altRaw, Unit.meter),
              pressure: Pressure(pressHPa ?? pressRaw, Unit.hPa),
              humidity: (humPct ?? humRaw) / 100,
              powderTemperature: Temperature(
                useDiffPowderTemp ? (powderTempC ?? powderTempRaw) : newTempC,
                Unit.celsius,
              ),
            ),
          );
    }

    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      children: [
        const _Header(),
        Expanded(
          child: ListView(
            children: [
              // ── Temperature — big centred control ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: _TempControl(
                  rawValue: tempRaw,
                  displayUnit: units.temperature,
                  onChanged: (v) => updateAtmo(tempC: v),
                ),
              ),
              const Divider(height: 1),

              // ── Altitude / Humidity / Pressure ────────────────────────────
              UnitValueField(
                label: 'Altitude',
                icon: Icons.terrain_outlined,
                rawValue: altRaw,
                constraints: FC.altitude,
                displayUnit: units.distance,
                onChanged: (v) => updateAtmo(altM: v),
              ),
              UnitValueField(
                label: 'Humidity',
                icon: Icons.water_drop_outlined,
                rawValue: humRaw,
                constraints: FC.humidity,
                displayUnit: FC.humidity.rawUnit,
                symbol: '%',
                onChanged: (v) => updateAtmo(humPct: v),
              ),
              UnitValueField(
                label: 'Pressure',
                icon: Icons.speed_outlined,
                rawValue: pressRaw,
                constraints: FC.pressure,
                displayUnit: units.pressure,
                onChanged: (v) => updateAtmo(pressHPa: v),
              ),
              const Divider(height: 1),
              // ── Switches ──────────────────────────────────────────────────
              _SwitchTile(
                label: 'Powder temperature sensitivity',
                icon: Icons.local_fire_department_outlined,
                value: powderSensOn,
                onChanged: (v) => notifier.setSwitch('powderSensitivity', v),
              ),
              if (powderSensOn) ...[
                _SwitchTile(
                  label: 'Use different powder temperature',
                  icon: Icons.thermostat_outlined,
                  value: useDiffPowderTemp,
                  onChanged: (v) =>
                      notifier.setSwitch('diffPowderTemperature', v),
                ),
                if (useDiffPowderTemp)
                  UnitValueField(
                    label: 'Powder temperature',
                    icon: Icons.local_fire_department_outlined,
                    rawValue: powderTempRaw,
                    constraints: FC.temperature,
                    displayUnit: units.temperature,
                    onChanged: (v) => updateAtmo(powderTempC: v),
                  ),
                _InfoTile(
                  label: 'Muzzle velocity at powder temp',
                  value: mvStr,
                  icon: Icons.speed_outlined,
                ),
                _InfoTile(
                  label: 'Powder sensitivity',
                  value: sensStr,
                  icon: Icons.show_chart_outlined,
                ),
              ],
              const Divider(height: 1),
              _SwitchTile(
                label: 'Coriolis effect',
                icon: Icons.rotate_right_outlined,
                value: settings?.enableCoriolis ?? false,
                onChanged: (v) => notifier.setSwitch('coriolis', v),
              ),
              _SwitchTile(
                label: 'Spin drift (derivation)',
                icon: Icons.rotate_left_outlined,
                value: settings?.enableDerivation ?? false,
                onChanged: (v) => notifier.setSwitch('derivation', v),
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

// ─── Temperature big control ──────────────────────────────────────────────────

class _TempControl extends StatelessWidget {
  const _TempControl({
    required this.rawValue,
    required this.displayUnit,
    required this.onChanged,
  });

  final double rawValue;
  final Unit displayUnit;
  final ValueChanged<double> onChanged;

  static final _fc = FC.temperature;

  double get _display {
    if (_fc.rawUnit == displayUnit) return rawValue;
    return (_fc.rawUnit(rawValue) as dynamic).in_(displayUnit) as double;
  }

  double _toDisplay(double raw) {
    if (_fc.rawUnit == displayUnit) return raw;
    return (_fc.rawUnit(raw) as dynamic).in_(displayUnit) as double;
  }

  double _toRaw(double display) {
    if (_fc.rawUnit == displayUnit) return display;
    return (displayUnit(display) as dynamic).in_(_fc.rawUnit) as double;
  }

  int get _accuracy {
    if (_fc.rawUnit == displayUnit) return _fc.accuracy;
    final stepDisplay = (_toDisplay(_fc.minRaw + _fc.stepRaw) - _toDisplay(_fc.minRaw)).abs();
    if (stepDisplay <= 0) return _fc.accuracy;
    final digits = (-log(stepDisplay) / ln10).ceil();
    return digits < 0 ? 0 : digits;
  }

  void _showDialog(BuildContext context) {
    final sym = displayUnit.symbol;
    final inputAcc = _accuracy;
    final dispMin = _toDisplay(_fc.minRaw);
    final dispMax = _toDisplay(_fc.maxRaw);
    double editRaw = rawValue;

    final controller = TextEditingController(
      text: _display.toStringAsFixed(inputAcc),
    );

    showDialog<void>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setState) {
            void step(int dir) {
              editRaw = (editRaw + dir * _fc.stepRaw).clamp(
                _fc.minRaw,
                _fc.maxRaw,
              );
              controller.text = _toDisplay(editRaw).toStringAsFixed(inputAcc);
              errorText = null;
            }

            return AlertDialog(
              title: Text('Temperature  ($sym)'),
              content: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => setState(() => step(-1)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        suffixText: sym,
                        errorText: errorText,
                      ),
                      onChanged: (text) {
                        final parsed = double.tryParse(
                          text.replaceAll(',', '.'),
                        );
                        setState(() {
                          if (parsed == null) {
                            errorText = 'Invalid number';
                          } else if (parsed < dispMin || parsed > dispMax) {
                            errorText =
                                '${dispMin.toStringAsFixed(inputAcc)} – '
                                '${dispMax.toStringAsFixed(inputAcc)}';
                          } else {
                            errorText = null;
                            editRaw = _toRaw(parsed);
                          }
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => step(1)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: errorText != null
                      ? null
                      : () {
                          onChanged(editRaw.clamp(_fc.minRaw, _fc.maxRaw));
                          Navigator.pop(ctx);
                        },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sym = displayUnit.symbol;
    final inputAcc = _fc.accuracy;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.remove),
          onPressed: () =>
              onChanged((rawValue - _fc.stepRaw).clamp(_fc.minRaw, _fc.maxRaw)),
          style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
        ),
        const SizedBox(width: 32),
        GestureDetector(
          onTap: () => _showDialog(context),
          child: Column(
            children: [
              Icon(Icons.device_thermostat_outlined, color: cs.primary),
              const SizedBox(height: 4),
              Text(
                '${_display.toStringAsFixed(inputAcc)} $sym',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                'Temperature',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        IconButton.filledTonal(
          icon: const Icon(Icons.add),
          onPressed: () =>
              onChanged((rawValue + _fc.stepRaw).clamp(_fc.minRaw, _fc.maxRaw)),
          style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
        ),
      ],
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
