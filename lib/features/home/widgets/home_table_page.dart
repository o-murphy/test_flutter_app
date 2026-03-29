import 'package:eballistica/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/features/home/home_vm.dart';

// ─── Page 2 — Compact Adjustment Tables ──────────────────────────────────────

class HomeTablePage extends ConsumerWidget {
  const HomeTablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(homeVmProvider);
    final vmState = vmAsync.value;

    if (vmState is! HomeUiReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final table = vmState.tableData;
    if (table.distanceHeaders.isEmpty || table.rows.isEmpty) {
      return const EmptyStatePlaceholder();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hdrStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );
    final cellStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
    );
    final targetCellStyle = cellStyle?.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
    );
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );
    final labelSubStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
    );

    Widget cell(String text, TextStyle? style, {Color? bg}) => Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(text, style: style, textAlign: TextAlign.right),
      ),
    );

    Widget labelCell(String label, String unit) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          Text(unit, style: labelSubStyle),
        ],
      ),
    );

    final tableRows = <TableRow>[
      // Header row — distance labels
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(table.distanceUnit, style: labelSubStyle),
          ),
          for (var i = 0; i < table.distanceHeaders.length; i++)
            cell(
              table.distanceHeaders[i],
              table.rows.isNotEmpty &&
                      table.rows.first.cells.length > i &&
                      table.rows.first.cells[i].isTargetColumn
                  ? hdrStyle?.copyWith(color: cs.primary)
                  : hdrStyle,
              bg:
                  table.rows.isNotEmpty &&
                      table.rows.first.cells.length > i &&
                      table.rows.first.cells[i].isTargetColumn
                  ? cs.primaryContainer.withAlpha(60)
                  : null,
            ),
        ],
      ),
      // Data rows
      for (final row in table.rows)
        TableRow(
          children: [
            labelCell(row.label, row.unitSymbol),
            for (var ci = 0; ci < row.cells.length; ci++)
              cell(
                row.cells[ci].value,
                row.cells[ci].isTargetColumn ? targetCellStyle : cellStyle,
                bg: row.cells[ci].isTargetColumn
                    ? cs.primaryContainer.withAlpha(40)
                    : null,
              ),
          ],
        ),
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Table(
          columnWidths: const {0: FlexColumnWidth(1.4)},
          defaultColumnWidth: const FlexColumnWidth(1.0),
          border: TableBorder.symmetric(
            inside: BorderSide(color: cs.outlineVariant, width: 0.5),
          ),
          children: tableRows,
        ),
      ),
    );
  }
}
