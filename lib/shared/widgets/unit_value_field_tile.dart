import 'dart:math';

import 'package:flutter/material.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

// ── Standalone dialog helper ──────────────────────────────────────────────────

double _toDisp(Unit rawUnit, Unit dispUnit, double raw) =>
    raw.convert(rawUnit, dispUnit);

double _toRawVal(Unit rawUnit, Unit dispUnit, double disp) =>
    disp.convert(dispUnit, rawUnit);

int _calcAccuracy(FieldConstraints c, Unit displayUnit) {
  if (c.rawUnit == displayUnit) return c.accuracy;
  final step =
      (_toDisp(c.rawUnit, displayUnit, c.minRaw + c.stepRaw) -
              _toDisp(c.rawUnit, displayUnit, c.minRaw))
          .abs();
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
    text: _toDisp(
      constraints.rawUnit,
      displayUnit,
      rawValue,
    ).toStringAsFixed(inputAcc),
  );

  showDialog<void>(
    context: context,
    builder: (ctx) {
      String? errorText;
      return StatefulBuilder(
        builder: (ctx, setState) {
          void step(int dir) {
            editRaw = (editRaw + dir * constraints.stepRaw).clamp(
              constraints.minRaw,
              constraints.maxRaw,
            );
            controller.text = _toDisp(
              constraints.rawUnit,
              displayUnit,
              editRaw,
            ).toStringAsFixed(inputAcc);
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
                          editRaw = _toRawVal(
                            constraints.rawUnit,
                            displayUnit,
                            parsed,
                          );
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
                        onChanged(
                          editRaw.clamp(constraints.minRaw, constraints.maxRaw),
                        );
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

/// Nullable variant of [UnitValueFieldTile].
///
/// - When [rawValue] is **null**: shows `—` + a "add" icon to set a value.
/// - When [rawValue] is **set**: shows the value + edit icon (tap to edit)
///   and a clear button (sets back to null).
/// - [onChanged] receives `null` when the user clears the value.
/// Nullable variant of [UnitValueFieldTile].
///
/// - When [rawValue] is **null**: shows `—` + a "add" icon to set a value.
/// - When [rawValue] is **set**: shows the value + edit icon (tap to edit)
/// - [onChanged] receives `null` when the user clears the value via dialog.
class NullableUnitValueFieldTile extends StatelessWidget {
  const NullableUnitValueFieldTile({
    super.key,
    required this.rawValue,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    required this.label,
    this.defaultRaw,
    this.symbol,
    this.icon,
  });

  final double? rawValue;
  final FieldConstraints constraints;
  final Unit displayUnit;
  final ValueChanged<double?> onChanged;
  final String label;
  final double? defaultRaw;
  final String? symbol;
  final IconData? icon;

  Unit get _rawUnit => constraints.rawUnit;
  double get _minRaw => constraints.minRaw;
  double get _stepRaw => constraints.stepRaw;

  double _toDisplay(double raw) {
    if (_rawUnit == displayUnit) return raw;
    return Dimension.auto(raw, _rawUnit).in_(displayUnit);
  }

  String get _sym => symbol ?? displayUnit.symbol;

  int get _accuracy {
    if (_rawUnit == displayUnit) return constraints.accuracy;
    final stepDisplay = (_toDisplay(_minRaw + _stepRaw) - _toDisplay(_minRaw))
        .abs();
    if (stepDisplay <= 0) return constraints.accuracy;
    final digits = (-log(stepDisplay) / ln10).ceil();
    return digits < 0 ? 0 : digits;
  }

  void _showDialog(BuildContext context) => showNullableUnitEditDialog(
    context,
    label: label,
    rawValue: rawValue,
    constraints: constraints,
    displayUnit: displayUnit,
    symbol: symbol,
    onChanged: onChanged,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSet = rawValue != null;

    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSet) ...[
            Text(
              '${_toDisplay(rawValue!).toStringAsFixed(_accuracy)} $_sym',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 16),
          ] else ...[
            Text(
              '—',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 16),
          ],
        ],
      ),
      onTap: () => _showDialog(context),
      dense: true,
    );
  }
}

/// Tappable row: `icon  label  value ✎`
///
/// Tapping opens a dialog with `[−] textField [+]` + Cancel/OK.
/// - [rawValue] / [onChanged] work in [constraints.rawUnit].
/// - [displayUnit] is the currently-selected user unit (from UnitSettings).
///   If [displayUnit] == [constraints.rawUnit], no conversion is done.
/// - min / max / step come from [constraints] and are in the raw unit.
class UnitValueFieldTile extends StatelessWidget {
  const UnitValueFieldTile({
    super.key,
    required this.rawValue,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    required this.label,
    this.symbol,
    this.icon,
  });

  final double rawValue;
  final FieldConstraints constraints;
  final Unit displayUnit;
  final ValueChanged<double> onChanged;
  final String label;
  final String? symbol;
  final IconData? icon;

  // ── Shorthand getters ───────────────────────────────────────────────────────

  Unit get _rawUnit => constraints.rawUnit;
  double get _minRaw => constraints.minRaw;
  double get _stepRaw => constraints.stepRaw;

  // ── Conversion ──────────────────────────────────────────────────────────────

  double _toDisplay(double raw) {
    if (_rawUnit == displayUnit) return raw;
    return Dimension.auto(raw, _rawUnit).in_(displayUnit);
  }

  double get _displayValue => _toDisplay(rawValue);
  String get _sym => symbol ?? displayUnit.symbol;

  /// Decimal places needed to represent [_stepRaw] in [displayUnit].
  /// Uses step-delta so temperature offset conversions work correctly.
  int get _accuracy {
    if (_rawUnit == displayUnit) return constraints.accuracy;
    final stepDisplay = (_toDisplay(_minRaw + _stepRaw) - _toDisplay(_minRaw))
        .abs();
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

    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_displayValue.toStringAsFixed(_accuracy)} $_sym',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.edit_outlined, size: 16),
        ],
      ),
      onTap: () => _showDialog(context),
      dense: true,
    );
  }
}

/// Shows nullable edit dialog that can return null when field is empty
Future<void> showNullableUnitEditDialog(
  BuildContext context, {
  required String label,
  required double? rawValue,
  required FieldConstraints constraints,
  required Unit displayUnit,
  String? symbol,
  required ValueChanged<double?> onChanged,
}) async {
  final sym = symbol ?? displayUnit.symbol;
  final inputAcc = _calcAccuracy(constraints, displayUnit);
  final dispMin = _toDisp(constraints.rawUnit, displayUnit, constraints.minRaw);
  final dispMax = _toDisp(constraints.rawUnit, displayUnit, constraints.maxRaw);

  // Використовуємо початкове значення або мінімальне
  double editRaw = rawValue ?? constraints.minRaw;
  bool isNullValue = rawValue == null;

  final controller = TextEditingController(
    text: rawValue != null
        ? _toDisp(
            constraints.rawUnit,
            displayUnit,
            rawValue,
          ).toStringAsFixed(inputAcc)
        : '',
  );

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      String? errorText;
      return StatefulBuilder(
        builder: (ctx, setState) {
          void step(int dir) {
            isNullValue = false;
            editRaw = (editRaw + dir * constraints.stepRaw).clamp(
              constraints.minRaw,
              constraints.maxRaw,
            );
            controller.text = _toDisp(
              constraints.rawUnit,
              displayUnit,
              editRaw,
            ).toStringAsFixed(inputAcc);
            errorText = null;
          }

          void clearField() {
            controller.clear();
            isNullValue = true;
            errorText = null;
            editRaw = constraints.minRaw; // тимчасове значення
            setState(() {}); // Оновлюємо UI
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
                      hintText: '—',
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: clearField,
                              iconSize: 12,
                            )
                          : null,
                    ),
                    onChanged: (text) {
                      final trimmed = text.trim();
                      double? parsed;

                      if (trimmed.isEmpty) {
                        parsed = null;
                      } else {
                        parsed = double.tryParse(trimmed.replaceAll(',', '.'));
                      }

                      setState(() {
                        if (parsed == null) {
                          if (trimmed.isEmpty) {
                            // Пуста строка - null значення
                            errorText = null;
                            isNullValue = true;
                            editRaw = constraints.minRaw; // тимчасове значення
                          } else {
                            errorText = 'Invalid number';
                            isNullValue = false;
                          }
                        } else if (parsed < dispMin || parsed > dispMax) {
                          errorText =
                              '${dispMin.toStringAsFixed(inputAcc)} – '
                              '${dispMax.toStringAsFixed(inputAcc)} or empty';
                          isNullValue = false;
                        } else {
                          errorText = null;
                          isNullValue = false;
                          editRaw = _toRawVal(
                            constraints.rawUnit,
                            displayUnit,
                            parsed,
                          );
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
                        if (isNullValue) {
                          onChanged(null);
                        } else {
                          onChanged(
                            editRaw.clamp(
                              constraints.minRaw,
                              constraints.maxRaw,
                            ),
                          );
                        }
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
