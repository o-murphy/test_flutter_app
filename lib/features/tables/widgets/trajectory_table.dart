import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

import 'package:eballistica/shared/models/formatted_row.dart';

// ─── Trajectory Table ─────────────────────────────────────────────────────────

class TrajectoryTable extends StatefulWidget {
  final FormattedTableData mainTable;
  final FormattedTableData? zeroCrossings;

  const TrajectoryTable({
    super.key,
    required this.mainTable,
    this.zeroCrossings,
  });

  @override
  State<TrajectoryTable> createState() => _TrajectoryTableState();
}

class _TrajectoryTableState extends State<TrajectoryTable> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Стилі тексту
    final hdrStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: cs.onSurface,
    );
    final subStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontSize: 10,
    );
    final cellStyle = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontSize: 13,
    );

    // ── Detail dialog ─────────────────────────────────────────────────────────

    void showDetail(FormattedTableData t, int colIndex) => showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(
          'Range: ${colIndex < t.distanceHeaders.length ? t.distanceHeaders[colIndex] : "—"} ${t.distanceUnit}',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: t.rows
                .map(
                  (row) => ListTile(
                    dense: true,
                    title: Text('${row.label}  (${row.unitSymbol})'),
                    trailing: Text(
                      colIndex < row.cells.length
                          ? row.cells[colIndex].value
                          : '—',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    // ── Trajectory Table Renderer ────────────────────────────────────────────

    Widget buildMainTable() {
      final t = widget.mainTable;
      final nMetrics = t.rows.length;
      final nPoints = t.distanceHeaders.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(text: 'Trajectory'),
          Expanded(
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 80 + (nMetrics * 75),
              fixedLeftColumns: 1, // ФІКСОВАНА КОЛОНКА RANGE
              headingRowHeight: 52,
              dataRowHeight: 40,
              headingRowColor: WidgetStateProperty.all(
                cs.surfaceContainerHighest,
              ),
              dividerThickness: 0.5,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: cs.outlineVariant.withAlpha(80),
                  width: 0.5,
                ),
                verticalInside: BorderSide(
                  color: cs.outlineVariant.withAlpha(80),
                  width: 0.5,
                ),
              ),
              columns: [
                DataColumn2(
                  label: Center(
                    child: Text("Range, ${t.distanceUnit}", style: hdrStyle),
                  ),
                  fixedWidth: 70,
                ),
                ...List.generate(
                  nMetrics,
                  (mi) => DataColumn2(
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          t.rows[mi].label,
                          style: hdrStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(t.rows[mi].unitSymbol, style: subStyle),
                      ],
                    ),
                    numeric: true,
                    size: ColumnSize.S,
                  ),
                ),
              ],
              rows: List.generate(nPoints, (pi) {
                final firstCell = nMetrics > 0 ? t.rows[0].cells[pi] : null;
                final isZ = firstCell?.isZeroCrossing ?? false;
                final isS = firstCell?.isSubsonic ?? false;
                final isT = firstCell?.isTargetColumn ?? false;

                final rowColor = isT
                    ? cs.primaryContainer.withAlpha(50)
                    : isZ
                    ? cs.errorContainer.withAlpha(50)
                    : isS
                    ? cs.tertiaryContainer.withAlpha(50)
                    : (pi.isEven ? null : cs.surfaceContainerLowest);

                final style = isT
                    ? cellStyle?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      )
                    : isZ
                    ? cellStyle?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.bold,
                      )
                    : cellStyle;

                return DataRow2(
                  color: WidgetStateProperty.all(rowColor),
                  onTap: () => showDetail(t, pi),
                  cells: [
                    DataCell(
                      Center(
                        child: Text(
                          t.distanceHeaders[pi],
                          style: hdrStyle?.copyWith(
                            color: isT ? cs.primary : null,
                          ),
                        ),
                      ),
                    ),
                    ...List.generate(
                      nMetrics,
                      (mi) => DataCell(
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(t.rows[mi].cells[pi].value, style: style),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      );
    }

    // ── Zero Crossings Renderer ──────────────────────────────────────────────

    Widget buildZeroTable() {
      final t = widget.zeroCrossings!;
      final nMetrics = t.rows.length;
      final nPoints = t.distanceHeaders.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle(text: 'Zero Crossings'),
          SizedBox(
            height:
                52 + (nPoints * 40.0) + 2, // Динамічна висота для списку нулів
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 80 + (nMetrics * 75),
              fixedLeftColumns: 1,
              headingRowHeight: 52,
              dataRowHeight: 40,
              headingRowColor: WidgetStateProperty.all(
                cs.surfaceContainerHighest,
              ),
              columns: [
                DataColumn2(
                  label: Center(
                    child: Text("Range, ${t.distanceUnit}", style: hdrStyle),
                  ),
                  fixedWidth: 70,
                ),
                ...List.generate(
                  nMetrics,
                  (mi) => DataColumn2(
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(t.rows[mi].label, style: hdrStyle),
                        Text(t.rows[mi].unitSymbol, style: subStyle),
                      ],
                    ),
                    numeric: true,
                  ),
                ),
              ],
              rows: List.generate(nPoints, (pi) {
                return DataRow2(
                  color: WidgetStateProperty.all(
                    cs.primaryContainer.withAlpha(40),
                  ),
                  onTap: () => showDetail(t, pi),
                  cells: [
                    DataCell(
                      Center(
                        child: Text(
                          t.distanceHeaders[pi],
                          style: hdrStyle?.copyWith(color: cs.primary),
                        ),
                      ),
                    ),
                    ...List.generate(
                      nMetrics,
                      (mi) => DataCell(
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            t.rows[mi].cells[pi].value,
                            style: cellStyle?.copyWith(color: cs.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      );
    }

    // ── Main Layout ──────────────────────────────────────────────────────────

    return Column(
      children: [
        if (widget.zeroCrossings != null &&
            widget.zeroCrossings!.distanceHeaders.isNotEmpty)
          buildZeroTable(),
        Expanded(child: buildMainTable()),
      ],
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
