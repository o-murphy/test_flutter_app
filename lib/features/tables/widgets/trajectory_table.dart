import 'package:eballistica/features/tables/trajectory_tables_vm.dart';
import 'package:eballistica/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

import 'package:eballistica/shared/models/formatted_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Trajectory Table ─────────────────────────────────────────────────────────

class TrajectoryTable extends ConsumerWidget {
  const TrajectoryTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(trajectoryTablesVmProvider);
    final vmState = vmAsync.value;

    if (vmState is TrajectoryTablesUiLoading || vmState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vmState is TrajectoryTablesUiEmpty) {
      return const EmptyStatePlaceholder();
    }

    if (vmState is TrajectoryTablesUiError) {
      return Center(child: Text('Error: ${vmState.message}'));
    }

    if (vmState is TrajectoryTablesUiReady) {
      return TrajectoryTableContent(
        mainTable: vmState.mainTable,
        zeroCrossings: vmState.zeroCrossings,
      );
    }

    return const EmptyStatePlaceholder();
  }
}

class TrajectoryTableContent extends StatefulWidget {
  final FormattedTableData mainTable;
  final FormattedTableData? zeroCrossings;
  final bool zeroCrossingEnabled;

  const TrajectoryTableContent({
    required this.mainTable,
    this.zeroCrossings,
    this.zeroCrossingEnabled = false,
    super.key,
  });

  @override
  State<TrajectoryTableContent> createState() => _TrajectoryTableContentState();
}

class _TrajectoryTableContentState extends State<TrajectoryTableContent> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                    title: Text(row.label),
                    subtitle: row.unitSymbol.isNotEmpty
                        ? Text(row.unitSymbol)
                        : null,
                    trailing: Text(
                      colIndex < row.cells.length
                          ? row.cells[colIndex].value
                          : '—',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontFamily: 'monospace'),
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
              fixedLeftColumns: 1,
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
                    ? cs.primaryContainer.withAlpha(80)
                    : isZ
                    ? cs.errorContainer.withAlpha(100)
                    : isS
                    ? cs.tertiaryContainer.withAlpha(100)
                    : (pi.isEven ? null : cs.surfaceContainerLowest);

                final style = isT
                    ? cellStyle?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      )
                    : isZ
                    ? cellStyle?.copyWith(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      )
                    : isS
                    ? cellStyle?.copyWith(
                        color: cs.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      )
                    : cellStyle;

                return DataRow2(
                  color: WidgetStateProperty.all(rowColor),
                  onTap: () => showDetail(t, pi),
                  cells: [
                    DataCell(
                      Center(child: Text(t.distanceHeaders[pi], style: style)),
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
                52 + (nPoints * 40.0) + 2, // Dynamic height for list of zeros
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
                          style: cellStyle?.copyWith(color: cs.primary),
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
          buildZeroTable()
        else if (widget.zeroCrossingEnabled)
          Container(
            width: double.infinity,
            color: Colors.redAccent.withValues(alpha: 0.2),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: const [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zero crossings not found in the current trajectory range!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
