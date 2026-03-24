import 'dart:math';

import 'package:flutter/material.dart';
import '../helpers/dimension_converter.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/unit.dart';

// ── Standalone dialog helper ──────────────────────────────────────────────────

double _toDisp(Unit rawUnit, Unit dispUnit, double raw) {
  if (rawUnit == dispUnit) return raw;
  return valueInUnit(raw, rawUnit, dispUnit);
}

double _toRawVal(Unit rawUnit, Unit dispUnit, double disp) {
  if (rawUnit == dispUnit) return disp;
  return valueInUnit(disp, dispUnit, rawUnit);
}

int _calcAccuracy(FieldConstraints c, Unit displayUnit) {
  if (c.rawUnit == displayUnit) return c.accuracy;
  final step = (_toDisp(c.rawUnit, displayUnit, c.minRaw + c.stepRaw) -
      _toDisp(c.rawUnit, displayUnit, c.minRaw)).abs();
  if (step <= 0) return c.accuracy;
  final d = (-log(step) / ln10).ceil();
  return d < 0 ? 0 : d;
}

/// Shows the `[−] textField [+]` edit dialog for any unit-based value.
/// [rawValue] and [onChanged] work in [constraints.rawUnit].
void showUnitEditDialog(
  BuildContext context, {
  required String label,
  required double rawValue,
  required FieldConstraints constraints,
  required Unit displayUnit,
  String? symbol,
  required ValueChanged<double> onChanged,
}) {
  final sym = symbol ?? displayUnit.symbol;
  final inputAcc = _calcAccuracy(constraints, displayUnit);
  final dispMin = _toDisp(constraints.rawUnit, displayUnit, constraints.minRaw);
  final dispMax = _toDisp(constraints.rawUnit, displayUnit, constraints.maxRaw);
  double editRaw = rawValue;

  final controller = TextEditingController(
    text: _toDisp(constraints.rawUnit, displayUnit, rawValue).toStringAsFixed(inputAcc),
  );

  showDialog<void>(
    context: context,
    builder: (ctx) {
      String? errorText;
      return StatefulBuilder(
        builder: (ctx, setState) {
          void step(int dir) {
            editRaw = (editRaw + dir * constraints.stepRaw)
                .clamp(constraints.minRaw, constraints.maxRaw);
            controller.text =
                _toDisp(constraints.rawUnit, displayUnit, editRaw).toStringAsFixed(inputAcc);
            errorText = null;
          }

          return AlertDialog(
            title: Text('$label  ($sym)'),
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
                      final parsed = double.tryParse(text.replaceAll(',', '.'));
                      setState(() {
                        if (parsed == null) {
                          errorText = 'Invalid number';
                        } else if (parsed < dispMin || parsed > dispMax) {
                          errorText =
                              '${dispMin.toStringAsFixed(inputAcc)} – '
                              '${dispMax.toStringAsFixed(inputAcc)}';
                        } else {
                          errorText = null;
                          editRaw = _toRawVal(constraints.rawUnit, displayUnit, parsed);
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
                        onChanged(editRaw.clamp(constraints.minRaw, constraints.maxRaw));
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

/// Tappable row: `icon  label  value ✎`
///
/// Tapping opens a dialog with `[−] textField [+]` + Cancel/OK.
/// - [rawValue] / [onChanged] work in [constraints.rawUnit].
/// - [displayUnit] is the currently-selected user unit (from UnitSettings).
///   If [displayUnit] == [constraints.rawUnit], no conversion is done.
/// - min / max / step come from [constraints] and are in the raw unit.
class UnitValueField extends StatelessWidget {
  const UnitValueField({
    super.key,
    required this.rawValue,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    required this.label,
    this.symbol,
    this.icon,
  });

  final double               rawValue;
  final FieldConstraints     constraints;
  final Unit                 displayUnit;
  final ValueChanged<double> onChanged;
  final String               label;
  final String?              symbol;
  final IconData?            icon;

  // ── Shorthand getters ───────────────────────────────────────────────────────

  Unit   get _rawUnit => constraints.rawUnit;
  double get _minRaw  => constraints.minRaw;
  double get _stepRaw => constraints.stepRaw;

  // ── Conversion ──────────────────────────────────────────────────────────────

  double _toDisplay(double raw) {
    if (_rawUnit == displayUnit) return raw;
    return valueInUnit(raw, _rawUnit, displayUnit);
  }

  double get _displayValue => _toDisplay(rawValue);
  String get _sym          => symbol ?? displayUnit.symbol;

  /// Decimal places needed to represent [_stepRaw] in [displayUnit].
  /// Uses step-delta so temperature offset conversions work correctly.
  int get _accuracy {
    if (_rawUnit == displayUnit) return constraints.accuracy;
    final stepDisplay = (_toDisplay(_minRaw + _stepRaw) - _toDisplay(_minRaw)).abs();
    if (stepDisplay <= 0) return constraints.accuracy;
    final digits = (-log(stepDisplay) / ln10).ceil();
    return digits < 0 ? 0 : digits;
  }

  // ── Dialog ──────────────────────────────────────────────────────────────────

  void _showDialog(BuildContext context) => showUnitEditDialog(
        context,
        label: label,
        rawValue: rawValue,
        constraints: constraints,
        displayUnit: displayUnit,
        symbol: symbol,
        onChanged: onChanged,
      );

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return InkWell(
      onTap: () => _showDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              '${_displayValue.toStringAsFixed(_accuracy)} $_sym',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
