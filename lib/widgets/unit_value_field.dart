import 'package:flutter/material.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/unit.dart';

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
  double get _maxRaw  => constraints.maxRaw;
  double get _stepRaw => constraints.stepRaw;

  // ── Conversion ──────────────────────────────────────────────────────────────

  double _toDisplay(double raw) {
    if (_rawUnit == displayUnit) return raw;
    return (_rawUnit(raw) as dynamic).in_(displayUnit) as double;
  }

  double _toRaw(double display) {
    if (_rawUnit == displayUnit) return display;
    return (displayUnit(display) as dynamic).in_(_rawUnit) as double;
  }

  double get _displayValue => _toDisplay(rawValue);
  int    get _accuracy     => constraints.accuracy;
  String get _sym          => symbol ?? displayUnit.symbol;

  // ── Dialog ──────────────────────────────────────────────────────────────────

  void _showDialog(BuildContext context) {
    double editRaw = rawValue;
    final inputAcc = displayUnit.accuracy;
    final controller = TextEditingController(
      text: _displayValue.toStringAsFixed(inputAcc),
    );
    final displayMin = _toDisplay(_minRaw);
    final displayMax = _toDisplay(_maxRaw);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setState) {
            void step(int dir) {
              editRaw = (editRaw + dir * _stepRaw).clamp(_minRaw, _maxRaw);
              controller.text = _toDisplay(editRaw).toStringAsFixed(inputAcc);
              errorText = null;
            }

            return AlertDialog(
              title: Text('$label  ($_sym)'),
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
                        suffixText: _sym,
                        errorText: errorText,
                      ),
                      onChanged: (text) {
                        final parsed =
                            double.tryParse(text.replaceAll(',', '.'));
                        setState(() {
                          if (parsed == null) {
                            errorText = 'Invalid number';
                          } else if (parsed < displayMin ||
                              parsed > displayMax) {
                            errorText =
                                '${displayMin.toStringAsFixed(inputAcc)} – '
                                '${displayMax.toStringAsFixed(inputAcc)}';
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
                          onChanged(editRaw.clamp(_minRaw, _maxRaw));
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
