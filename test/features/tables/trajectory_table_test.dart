// Widget tests for TrajectoryTable (Phase 4).
//
// TrajectoryTable is a plain StatefulWidget — no Riverpod needed.
//   flutter test test/trajectory_table_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eballistica/shared/models/formatted_row.dart';
import 'package:eballistica/features/tables/tables_vm.dart';
import 'package:eballistica/features/tables/widgets/trajectory_table.dart';

// ── Fixtures ─────────────────────────────────────────────────────────────────

FormattedTableData _makeTable({
  List<String>? headers,
  bool includeZeroCrossing = false,
  bool includeSubsonic = false,
  bool includeTargetColumn = true,
}) {
  final h = headers ?? ['100', '200', '300'];
  return FormattedTableData(
    distanceHeaders: h,
    distanceUnit: 'm',
    rows: [
      FormattedRow(
        label: 'V',
        unitSymbol: 'm/s',
        cells: [
          FormattedCell(value: '790'),
          FormattedCell(value: '760', isZeroCrossing: includeZeroCrossing),
          FormattedCell(
              value: '730',
              isTargetColumn: includeTargetColumn,
              isSubsonic: includeSubsonic),
        ],
      ),
      FormattedRow(
        label: 'Drop',
        unitSymbol: 'cm',
        cells: [
          const FormattedCell(value: '-2.1'),
          const FormattedCell(value: '-8.5'),
          const FormattedCell(value: '-19.2'),
        ],
      ),
    ],
  );
}

const TablesSpoilerData _emptySpoiler = TablesSpoilerData(rifleName: 'R');

TablesSpoilerData _makeFullSpoiler() => const TablesSpoilerData(
      rifleName: 'Test Rifle',
      caliber: '7.62 mm',
      twist: '1:11"',
      dragModel: 'G7',
      bc: '0.475 G7',
      temperature: '20 °C',
      humidity: '50 %',
      pressure: '1013 hPa',
      windSpeed: '3 m/s',
      windDir: '90°',
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('TrajectoryTable — main table rendering', () {
    testWidgets('renders distance headers', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      expect(find.text('100'), findsWidgets);
      expect(find.text('200'), findsWidgets);
      expect(find.text('300'), findsWidgets);
    });

    testWidgets('renders distance unit label', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      // 'm' appears in the header row and potentially in cells
      expect(find.text('m'), findsWidgets);
    });

    testWidgets('renders row labels', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      expect(find.text('V'), findsOneWidget);
      expect(find.text('Drop'), findsOneWidget);
    });

    testWidgets('renders row unit symbols', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      expect(find.text('m/s'), findsOneWidget);
      expect(find.text('cm'), findsOneWidget);
    });

    testWidgets('renders cell values', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      expect(find.text('790'), findsOneWidget);
      expect(find.text('-2.1'), findsOneWidget);
      expect(find.text('-8.5'), findsOneWidget);
    });

    testWidgets('always shows Trajectory section title', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      expect(find.text('Trajectory'), findsOneWidget);
    });
  });

  group('TrajectoryTable — zero crossings section', () {
    testWidgets('shows Zero Crossings title when provided', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        zeroCrossings: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      expect(find.text('Zero Crossings'), findsOneWidget);
    });

    testWidgets('Zero Crossings absent when null', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      expect(find.text('Zero Crossings'), findsNothing);
    });

    testWidgets('Zero Crossings absent when empty headers', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        zeroCrossings: const FormattedTableData(
          distanceHeaders: [],
          rows: [],
          distanceUnit: 'm',
        ),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      expect(find.text('Zero Crossings'), findsNothing);
    });
  });

  group('TrajectoryTable — spoiler', () {
    testWidgets('shows expansion tile when optional fields present', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _makeFullSpoiler(),
      )));
      await tester.pump();

      expect(find.text('Shot details'), findsOneWidget);
    });

    testWidgets('spoiler hidden when no optional fields', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      expect(find.text('Shot details'), findsNothing);
    });

    testWidgets('rifle section visible after expanding', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _makeFullSpoiler(),
      )));
      await tester.pump();

      await tester.tap(find.text('Shot details'));
      await tester.pumpAndSettle();

      expect(find.text('RIFLE'), findsOneWidget);
      expect(find.text('Test Rifle'), findsOneWidget);
      expect(find.text('7.62 mm'), findsOneWidget);
      expect(find.text('1:11"'), findsOneWidget);
    });

    testWidgets('projectile section visible after expanding', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _makeFullSpoiler(),
      )));
      await tester.pump();

      await tester.tap(find.text('Shot details'));
      await tester.pumpAndSettle();

      expect(find.text('PROJECTILE'), findsOneWidget);
      expect(find.text('G7'), findsOneWidget);
      expect(find.text('0.475 G7'), findsOneWidget);
    });

    testWidgets('atmosphere section visible after expanding', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _makeFullSpoiler(),
      )));
      await tester.pump();

      await tester.tap(find.text('Shot details'));
      await tester.pumpAndSettle();

      expect(find.text('ATMOSPHERE'), findsOneWidget);
      expect(find.text('20 °C'), findsOneWidget);
      expect(find.text('1013 hPa'), findsOneWidget);
      expect(find.text('3 m/s'), findsOneWidget);
    });

    testWidgets('spoiler collapsed by default — section titles not visible', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _makeFullSpoiler(),
      )));
      await tester.pump();

      // Before expanding, internal section titles should not be visible
      expect(find.text('RIFLE'), findsNothing);
      expect(find.text('ATMOSPHERE'), findsNothing);
    });
  });

  group('TrajectoryTable — cell detail dialog', () {
    testWidgets('tapping a cell opens detail dialog', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      await tester.tap(find.text('790').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('dialog title contains the distance header', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      // Tap first cell (column 0 → header '100')
      await tester.tap(find.text('790').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('100'), findsWidgets);
    });

    testWidgets('dialog lists all row labels with values', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      await tester.tap(find.text('790').first);
      await tester.pumpAndSettle();

      // ListTile titles contain the row label and unit
      expect(find.textContaining('V'), findsWidgets);
      expect(find.textContaining('Drop'), findsWidgets);
      // Cell value for that column
      expect(find.text('790'), findsWidgets);
    });

    testWidgets('Close button dismisses dialog', (tester) async {
      await tester.pumpWidget(_wrap(TrajectoryTable(
        mainTable: _makeTable(),
        spoiler: _emptySpoiler,
      )));
      await tester.pump();

      await tester.tap(find.text('790').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
