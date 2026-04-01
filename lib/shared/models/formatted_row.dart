class FormattedCell {
  final String value;
  final bool isZeroCrossing;
  final bool isSubsonic;
  final bool isTargetColumn;

  const FormattedCell({
    required this.value,
    this.isZeroCrossing = false,
    this.isSubsonic = false,
    this.isTargetColumn = false,
  });
}

class FormattedRow {
  final String label;
  final String unitSymbol;
  final List<FormattedCell> cells;

  const FormattedRow({
    required this.label,
    required this.unitSymbol,
    required this.cells,
  });
}

class FormattedTableData {
  final List<String> distanceHeaders;
  final List<FormattedRow> rows;
  final String distanceUnit;

  const FormattedTableData({
    required this.distanceHeaders,
    required this.rows,
    required this.distanceUnit,
  });

  static const empty = FormattedTableData(
    distanceHeaders: [],
    rows: [],
    distanceUnit: '',
  );
}
