import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/widgets/unit_constrained_input_field.dart';
import 'package:eballistica/shared/widgets/unit_picker_button.dart';
import 'package:flutter/material.dart';

/// Віджет для вводу значення з вибором одиниці виміру на базі ListTile
class UnitInputWithPicker extends StatelessWidget {
  const UnitInputWithPicker({
    required this.value,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    required this.onUnitChanged,
    required this.options,
    this.hintText,
    this.unitLabel = 'Select Unit',
    super.key,
  });

  final double? value;
  final FieldConstraints constraints;
  final Unit displayUnit;
  final ValueChanged<double?> onChanged;
  final ValueChanged<Unit> onUnitChanged;
  final List<Unit> options;
  final String? hintText;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: ConstrainedUnitInputField(
        rawValue: value,
        constraints: constraints,
        displayUnit: displayUnit,
        onChanged: onChanged,
        hintText: hintText,
        hideSymbol: true,
      ),
      trailing: UnitPickerButton(
        current: displayUnit,
        onChanged: onUnitChanged,
        options: options,
        label: unitLabel,
      ),
      dense: true,
    );
  }
}
