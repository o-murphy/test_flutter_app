import 'package:eballistica/shared/helpers/unit_constrained_convertion_helper.dart';
import 'package:flutter/material.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

// ── Refactored dialog using the same helper ─────────────────────────────────

class _DialogState {
  double editRaw;
  bool isNullValue;
  String? errorText;

  _DialogState({required this.editRaw, required this.isNullValue})
    : errorText = null;
}

Future<void> _showUnitEditDialogInternal(
  BuildContext context, {
  required String label,
  required double? initialRawValue,
  required FieldConstraints constraints,
  required Unit displayUnit,
  required String? symbol,
  required bool allowNull,
  required void Function(double?) onChanged,
}) async {
  final helper = UnitConversionHelper(
    constraints: constraints,
    displayUnit: displayUnit,
  );
  final sym = symbol ?? displayUnit.symbol;

  final initialRaw = initialRawValue ?? constraints.minRaw;
  final controller = TextEditingController(
    text: initialRawValue != null
        ? helper.formatDisplayValue(helper.toDisplay(initialRawValue))
        : '',
  );

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final dialogState = _DialogState(
        editRaw: initialRaw,
        isNullValue: initialRawValue == null,
      );

      return StatefulBuilder(
        builder: (ctx, setState) {
          void step(int dir) {
            dialogState.isNullValue = false;
            dialogState.editRaw = (dialogState.editRaw + dir * helper.stepRaw)
                .clamp(constraints.minRaw, constraints.maxRaw);
            controller.text = helper.formatDisplayValue(
              helper.toDisplay(dialogState.editRaw),
            );
            dialogState.errorText = null;
            setState(() {});
          }

          void clearField() {
            if (!allowNull) return;
            controller.clear();
            dialogState.isNullValue = true;
            dialogState.errorText = null;
            dialogState.editRaw = constraints.minRaw;
            setState(() {});
          }

          void onTextChanged(String text) {
            final (rawValue, errorText) = helper.parseAndValidate(text);

            setState(() {
              if (errorText == null) {
                dialogState.errorText = null;
                dialogState.isNullValue = rawValue == null;
                if (rawValue != null) {
                  dialogState.editRaw = rawValue;
                }
              } else {
                dialogState.errorText = errorText;
                dialogState.isNullValue = false;
              }
            });
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
                      errorText: dialogState.errorText,
                      hintText: allowNull ? '—' : null,
                      suffixIcon: allowNull && controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: clearField,
                              iconSize: 12,
                            )
                          : null,
                    ),
                    onChanged: onTextChanged,
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
                onPressed: dialogState.errorText != null
                    ? null
                    : () {
                        if (dialogState.isNullValue && allowNull) {
                          onChanged(null);
                        } else {
                          onChanged(dialogState.editRaw);
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

// ── Public dialog functions ─────────────────────────────────────────────────

void showUnitEditDialog(
  BuildContext context, {
  required String label,
  required double rawValue,
  required FieldConstraints constraints,
  required Unit displayUnit,
  String? symbol,
  required ValueChanged<double> onChanged,
}) {
  _showUnitEditDialogInternal(
    context,
    label: label,
    initialRawValue: rawValue,
    constraints: constraints,
    displayUnit: displayUnit,
    symbol: symbol,
    allowNull: false,
    onChanged: (value) => onChanged(value!),
  );
}

Future<void> showNullableUnitEditDialog(
  BuildContext context, {
  required String label,
  required double? rawValue,
  required FieldConstraints constraints,
  required Unit displayUnit,
  String? symbol,
  required ValueChanged<double?> onChanged,
}) async {
  await _showUnitEditDialogInternal(
    context,
    label: label,
    initialRawValue: rawValue,
    constraints: constraints,
    displayUnit: displayUnit,
    symbol: symbol,
    allowNull: true,
    onChanged: onChanged,
  );
}
