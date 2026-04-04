import 'package:eballistica/shared/helpers/unit_constrained_convertion_helper.dart';
import 'package:eballistica/shared/widgets/unit_constrained_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

// ── Shared tile logic ───────────────────────────────────────────────────────

/// Базовий клас для тайлів з підтримкою generic типу
abstract class UnitValueFieldTileBase<T> extends StatelessWidget {
  const UnitValueFieldTileBase({
    required this.rawValue,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    required this.label,
    this.symbol,
    this.icon,
    super.key,
  });

  final T rawValue;
  final FieldConstraints constraints;
  final Unit displayUnit;
  final ValueChanged<T> onChanged;
  final String label;
  final String? symbol;
  final IconData? icon;

  String get _sym => symbol ?? displayUnit.symbol;

  /// Отримати display значення для показу (у випадку null повертає '—')
  String _getDisplayText() {
    // Для nullable варіанту rawValue може бути null, але ми не можемо це перевірити в базовому класі
    // Тому цей метод має бути перевизначений в нащадках
    throw UnimplementedError();
  }

  TextStyle? _getDisplayTextStyle(ThemeData theme) =>
      theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getDisplayText(), style: _getDisplayTextStyle(theme)),
          const SizedBox(width: 8),
          const Icon(Icons.edit_outlined, size: 16),
        ],
      ),
      onTap: () => _showDialog(context),
      dense: true,
    );
  }

  void _showDialog(BuildContext context);
}

/// Тайл для обов'язкового значення (не може бути null)
class UnitValueFieldTile extends UnitValueFieldTileBase<double> {
  const UnitValueFieldTile({
    super.key,
    required super.rawValue,
    required super.constraints,
    required super.displayUnit,
    required super.onChanged,
    required super.label,
    super.symbol,
    super.icon,
  });

  @override
  String _getDisplayText() {
    final helper = UnitConversionHelper(
      constraints: constraints,
      displayUnit: displayUnit,
    );
    return '${helper.formatDisplayValue(helper.toDisplay(rawValue))} $_sym';
  }

  @override
  void _showDialog(BuildContext context) => showUnitEditDialog(
    context,
    label: label,
    rawValue: rawValue,
    constraints: constraints,
    displayUnit: displayUnit,
    symbol: symbol,
    onChanged: onChanged,
  );
}

/// Тайл для опціонального значення (може бути null)
class NullableUnitValueFieldTile extends UnitValueFieldTileBase<double?> {
  const NullableUnitValueFieldTile({
    super.key,
    required super.rawValue,
    required super.constraints,
    required super.displayUnit,
    required super.onChanged,
    required super.label,
    super.symbol,
    super.icon,
  });

  @override
  String _getDisplayText() {
    if (rawValue == null) return '—';

    final helper = UnitConversionHelper(
      constraints: constraints,
      displayUnit: displayUnit,
    );
    return '${helper.formatDisplayValue(helper.toDisplay(rawValue!))} $_sym';
  }

  @override
  TextStyle? _getDisplayTextStyle(ThemeData theme) {
    if (rawValue == null) {
      return theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    return super._getDisplayTextStyle(theme);
  }

  @override
  void _showDialog(BuildContext context) => showNullableUnitEditDialog(
    context,
    label: label,
    rawValue: rawValue,
    constraints: constraints,
    displayUnit: displayUnit,
    symbol: symbol,
    onChanged: onChanged,
  );
}
