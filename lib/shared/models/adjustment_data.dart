// ЧИСТИЙ DART

class AdjustmentValue {
  final double absValue;
  final bool isPositive;
  final String symbol;
  final int decimals;

  const AdjustmentValue({
    required this.absValue,
    required this.isPositive,
    required this.symbol,
    required this.decimals,
  });

  String get formatted =>
      '${absValue.toStringAsFixed(decimals)} $symbol';
}

class AdjustmentData {
  final List<AdjustmentValue> elevation;
  final List<AdjustmentValue> windage;

  const AdjustmentData({
    required this.elevation,
    required this.windage,
  });

  static const empty = AdjustmentData(elevation: [], windage: []);
}
