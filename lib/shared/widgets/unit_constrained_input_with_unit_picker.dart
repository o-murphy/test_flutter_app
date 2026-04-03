import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/widgets/unit_constrained_input_field.dart';
import 'package:eballistica/shared/widgets/unit_picker_button.dart';
import 'package:flutter/material.dart';

class ValueInputWithUnitPicker extends StatelessWidget {
  const ValueInputWithUnitPicker({
    required this.value,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    required this.onUnitChanged,
    required this.options,
    required this.label,
    this.hintText,
    this.icon,
    this.unitLabel = 'Select Unit',
    super.key,
  });

  final double? value;
  final FieldConstraints constraints;
  final Unit displayUnit;
  final ValueChanged<double?> onChanged;
  final ValueChanged<Unit> onUnitChanged;
  final List<Unit> options;
  final String label;
  final String? hintText;
  final IconData? icon;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: ConstrainedUnitInputField(
              rawValue: value,
              constraints: constraints,
              displayUnit: displayUnit,
              onChanged: onChanged,
              hintText: hintText,
              hideSymbol: true,
            ),
          ),
          const SizedBox(width: 8),
          UnitPickerButton(
            current: displayUnit,
            onChanged: onUnitChanged,
            options: options,
            label: unitLabel,
          ),
        ],
      ),
      dense: true,
    );
  }
}
