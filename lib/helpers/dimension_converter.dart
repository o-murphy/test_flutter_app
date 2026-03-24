/// Helper functions for type-safe dimension conversions.
/// 
/// Replaces unsafe `(dim as dynamic).in_(unit) as double` patterns throughout the app.
/// All dimension classes (Distance, Temperature, Weight, etc.) inherit from Dimension<T>
/// and have `.in_()` methods. These helpers provide clean, safe conversion APIs.

import '../src/solver/unit.dart';

/// Converts any Dimension to a double in the specified target unit.
/// 
/// Safe alternative to:
///   (dim as dynamic).in_(unit) as double  ❌ UNSAFE
/// 
/// Usage:
///   convertDimension(temperature, Unit.celsius)  ✅ SAFE
double convertDimension(dynamic dim, Unit targetUnit) {
  if (dim is Dimension) {
    return dim.in_(targetUnit);
  }
  throw ArgumentError(
    'Expected Dimension but got ${dim.runtimeType}. '
    'Cannot convert to unit: $targetUnit',
  );
}

/// Converts a dimension value (raw) from source unit to display unit.
/// This is the key function for handling unit conversions throughout the app.
/// 
/// Usage:
///   valueInUnit(10.5, Unit.meter, Unit.foot)  -> 34.45 feet
///   valueInUnit(celsius, Unit.celsius, Unit.fahrenheit)
double valueInUnit(double rawValue, Unit sourceUnit, Unit targetUnit) {
  if (sourceUnit == targetUnit) return rawValue;
  // Create a temporary dimension using source unit, then convert to target
  try {
    final tempDim = sourceUnit.call(rawValue);
    return convertDimension(tempDim, targetUnit);
  } catch (_) {
    // Fallback if unit creation fails
    return rawValue;
  }
}

/// Safely extracts raw value from nullable dimension object.
/// 
/// Usage:
///   final temp = profile?.temperature;
///   final celsius = safeDimensionValue(temp, Unit.celsius) ?? 15.0;
double? safeDimensionValue(dynamic dim, Unit unit) {
  if (dim == null) return null;
  if (dim is Dimension) {
    return dim.in_(unit);
  }
  return null;
}

/// Format a dimension value for display with proper unit symbol.
/// 
/// Usage:
///   formatDimension(distance, Unit.kilometer)
///   -> "1.5 km"
String formatDimension(
  dynamic dim,
  Unit unit, {
  int precision = 2,
}) {
  if (dim is Dimension) {
    final value = dim.in_(unit);
    return '${value.toStringAsFixed(precision)} ${unit.symbol}';
  }
  return 'N/A';
}

/// Extension methods for cleaner syntax on Dimension objects.
extension DimensionExt on Dimension {
  /// Convert to target unit. Type-safe alternative to: (this as dynamic).in_(unit) as double
  /// 
  /// Usage:
  ///   distance.convertTo(Unit.foot)  ✅ CLEAN & SAFE
  double convertTo(Unit unit) => in_(unit);

  /// Format with unit symbol.
  /// 
  /// Usage:
  ///   distance.format(Unit.meter, precision: 1)  -> "5.5 m"
  String format(Unit unit, {int precision = 2}) {
    return '${in_(unit).toStringAsFixed(precision)} ${unit.symbol}';
  }
}

/// For cases where you need to handle potentially-nullable dimensions.
extension NullableDimensionExt on Dimension? {
  /// Safe conversion of nullable dimension.
  /// 
  /// Usage:
  ///   (profile?.temperature).safeConvertTo(Unit.celsius) ?? 15.0
  double? safeConvertTo(Unit unit) {
    if (this == null) return null;
    return this!.in_(unit);
  }

  /// Format nullable dimension with fallback.
  /// 
  /// Usage:
  ///   (profile?.distance).safeFormat(Unit.foot, fallback: '—')  -> "100.5 ft" or "—"
  String safeFormat(
    Unit unit, {
    String fallback = 'N/A',
    int precision = 2,
  }) {
    if (this == null) return fallback;
    return this!.format(unit, precision: precision);
  }
}
