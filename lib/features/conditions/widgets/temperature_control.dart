import 'dart:math';

import 'package:flutter/material.dart';

import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

// ─── Large temperature control (big ± buttons + tap-to-edit dialog) ───────────

class TempControl extends StatelessWidget {
  const TempControl({
    super.key,
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
    return _fc.rawUnit(rawValue).in_(displayUnit);
  }

  double _toDisplay(double raw) {
    if (_fc.rawUnit == displayUnit) return raw;
    return _fc.rawUnit(raw).in_(displayUnit);
  }

  double _toRaw(double display) {
    if (_fc.rawUnit == displayUnit) return display;
    return displayUnit(display).in_(_fc.rawUnit);
  }

  int get _accuracy {
    if (_fc.rawUnit == displayUnit) return _fc.accuracy;
    final stepDisplay =
        (_toDisplay(_fc.minRaw + _fc.stepRaw) - _toDisplay(_fc.minRaw)).abs();
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
              editRaw =
                  (editRaw + dir * _fc.stepRaw).clamp(_fc.minRaw, _fc.maxRaw);
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
                        final parsed =
                            double.tryParse(text.replaceAll(',', '.'));
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
