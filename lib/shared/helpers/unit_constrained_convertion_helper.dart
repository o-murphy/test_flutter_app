import 'dart:math' as math;

import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

// ── Core conversion & validation logic ──────────────────────────────────────

/// Утиліта для роботи з конвертацією одиниць та валідацією
class UnitConversionHelper {
  final FieldConstraints constraints;
  final Unit displayUnit;

  UnitConversionHelper({required this.constraints, required this.displayUnit});

  Unit get _rawUnit => constraints.rawUnit;

  double toDisplay(double raw) {
    if (_rawUnit == displayUnit) return raw;
    return raw.convert(_rawUnit, displayUnit);
  }

  double toRaw(double display) {
    if (_rawUnit == displayUnit) return display;
    return display.convert(displayUnit, _rawUnit);
  }

  int get accuracy {
    if (_rawUnit == displayUnit) return constraints.accuracy;
    final stepDisplay =
        (toDisplay(constraints.minRaw + constraints.stepRaw) -
                toDisplay(constraints.minRaw))
            .abs();
    if (stepDisplay <= 0) return constraints.accuracy;
    final digits = (-math.log(stepDisplay) / math.ln10).ceil();
    return digits < 0 ? 0 : digits;
  }

  double get displayMin => toDisplay(constraints.minRaw);
  double get displayMax => toDisplay(constraints.maxRaw);
  double get stepRaw => constraints.stepRaw;

  String formatDisplayValue(double value) {
    return value.toStringAsFixed(accuracy);
  }

  /// Валідує display значення та повертає raw значення
  double? validateDisplayValue(double displayValue) {
    if (displayValue < displayMin - 1e-10 ||
        displayValue > displayMax + 1e-10) {
      return null;
    }
    return toRaw(displayValue).clamp(constraints.minRaw, constraints.maxRaw);
  }

  /// Парсить рядок. Повертає (rawValue, errorText)
  (double?, String?) parseAndValidate(String text) {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return (null, null);
    }

    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null) {
      return (null, 'Invalid number');
    }

    if (parsed < displayMin - 1e-10 || parsed > displayMax + 1e-10) {
      return (
        null,
        '${formatDisplayValue(displayMin)} — ${formatDisplayValue(displayMax)}',
      );
    }

    final rawValue = toRaw(
      parsed,
    ).clamp(constraints.minRaw, constraints.maxRaw);
    return (rawValue, null);
  }
}
