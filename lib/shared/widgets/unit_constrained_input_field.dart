// ── Reusable input field ─────────────────────────────────────────────────────

import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/helpers/unit_constrained_convertion_helper.dart';
import 'package:flutter/material.dart';

/// Поле вводу з валідацією за констрейнтами
class ConstrainedUnitInputField extends StatefulWidget {
  const ConstrainedUnitInputField({
    super.key,
    required this.rawValue,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    this.label,
    this.hintText,
    this.symbol,
    this.autofocus = false,
    this.enabled = true,
    this.prefixIcon,
    this.hideSymbol = false,
  });

  final double? rawValue;
  final FieldConstraints constraints;
  final Unit displayUnit;
  final ValueChanged<double?> onChanged;
  final String? label;
  final String? hintText;
  final String? symbol;
  final bool autofocus;
  final bool enabled;
  final Widget? prefixIcon;
  final bool hideSymbol;

  @override
  State<ConstrainedUnitInputField> createState() =>
      _ConstrainedUnitInputFieldState();
}

class _ConstrainedUnitInputFieldState extends State<ConstrainedUnitInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final UnitConversionHelper _helper;

  double? _currentRawValue;
  String? _errorText;

  String get _sym => widget.symbol ?? widget.displayUnit.symbol;

  void _updateControllerFromValue() {
    if (_currentRawValue != null) {
      _controller.text = _helper.formatDisplayValue(
        _helper.toDisplay(_currentRawValue!),
      );
    } else {
      _controller.clear();
    }
  }

  void _validateAndUpdate() {
    final (rawValue, errorText) = _helper.parseAndValidate(_controller.text);

    setState(() {
      _errorText = errorText;
      if (errorText == null) {
        _currentRawValue = rawValue;
      }
      // Не викликаємо onChanged поки що, тільки при submit
    });
  }

  void _submit() {
    final (rawValue, errorText) = _helper.parseAndValidate(_controller.text);

    setState(() {
      if (errorText == null) {
        _currentRawValue = rawValue;
        _updateControllerFromValue();
        _errorText = null;
        widget.onChanged(_currentRawValue);
        _focusNode.unfocus();
      } else {
        _errorText = errorText;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _helper = UnitConversionHelper(
      constraints: widget.constraints,
      displayUnit: widget.displayUnit,
    );
    _currentRawValue = widget.rawValue;
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _updateControllerFromValue();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _submit();
      }
    });
  }

  @override
  void didUpdateWidget(ConstrainedUnitInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.constraints != oldWidget.constraints ||
        widget.displayUnit != oldWidget.displayUnit) {
      _helper = UnitConversionHelper(
        constraints: widget.constraints,
        displayUnit: widget.displayUnit,
      );
    }
    if (widget.rawValue != oldWidget.rawValue) {
      _currentRawValue = widget.rawValue;
      _updateControllerFromValue();
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixText: widget.hideSymbol ? null : _sym,
        errorText: _errorText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: (_) => _validateAndUpdate(), // Валідація при кожній зміні
      onSubmitted: (_) => _submit(),
    );
  }
}
