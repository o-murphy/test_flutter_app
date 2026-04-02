// Widget tests for TrajectoryTable (Phase 4).
//
// TrajectoryTable is a plain StatefulWidget — no Riverpod needed.
//   flutter test test/trajectory_table_test.dart

import 'package:eballistica/features/tables/details_table_mv.dart';
import 'package:eballistica/features/tables/widgets/details_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eballistica/shared/models/formatted_row.dart';
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
            isSubsonic: includeSubsonic,
          ),
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

DetailsTableData _makeFullSpoiler() => const DetailsTableData(
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
      await tester.pumpWidget(
        _wrap(TrajectoryTableContent(mainTable: _makeTable())),
      );
      await tester.pump();

      expect(find.text('100'), findsWidgets);
      expect(find.text('200'), findsWidgets);
      expect(find.text('300'), findsWidgets);
    });

    testWidgets('renders distance unit label', (tester) async {
      await tester.pumpWidget(
        _wrap(TrajectoryTableContent(mainTable: _makeTable())),
      );
      await tester.pump();

      // 'm' appears in the header row and potentially in cells
      expect(find.textContaining('Range, m'), findsWidgets);
    });

    testWidgets('renders row labels', (tester) async {
      await tester.pumpWidget(
        _wrap(TrajectoryTableContent(mainTable: _makeTable())),
      );
      await tester.pump();

      expect(find.text('V'), findsOneWidget);
      expect(find.text('Drop'), findsOneWidget);
    });

    testWidgets('renders row unit symbols', (tester) async {
      await tester.pumpWidget(
        _wrap(TrajectoryTableContent(mainTable: _makeTable())),
      );
      await tester.pump();

      expect(find.text('m/s'), findsOneWidget);
      expect(find.text('cm'), findsOneWidget);
    });

    testWidgets('renders cell values', (tester) async {
      await tester.pumpWidget(
        _wrap(TrajectoryTableContent(mainTable: _makeTable())),
      );
      await tester.pump();

      expect(find.text('790'), findsOneWidget);
      expect(find.text('-2.1'), findsOneWidget);
      expect(find.text('-8.5'), findsOneWidget);
    });

    testWidgets('always shows Trajectory section title', (tester) async {
      await tester.pumpWidget(
        _wrap(TrajectoryTableContent(mainTable: _makeTable())),
      );
      await tester.pump();

      expect(find.textContaining('TRAJECTORY'), findsOneWidget);
    });
  });

  group('TrajectoryTable — zero crossings section', () {
    testWidgets('shows Zero Crossings title when provided', (tester) async {
      // Set a fixed screen size for the test so that DataTable2 has room to stretch
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        _wrap(
          // Make sure you call TrajectoryTable2 if you renamed it
          TrajectoryTableContent(
            mainTable: _makeTable(),
            zeroCrossings: _makeTable(),
          ),
        ),
      );

      // Give time for the table to be calculated
      await tester.pumpAndSettle();

      // Find the title text. Use .text('ZERO CROSSINGS')
      // because in _SectionTitle we do .toUpperCase()
      expect(find.text('ZERO CROSSINGS'), findsOneWidget);

      // Reset the screen size after the test
      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('Zero Crossings absent when null', (tester) async {
      await tester.pumpWidget(
        _wrap(TrajectoryTableContent(mainTable: _makeTable())),
      );
      await tester.pump();

      expect(find.text('Zero Crossings'), findsNothing);
    });

    testWidgets('Zero Crossings absent when empty headers', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TrajectoryTableContent(
            mainTable: _makeTable(),
            zeroCrossings: const FormattedTableData(
              distanceHeaders: [],
              rows: [],
              distanceUnit: 'm',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Zero Crossings'), findsNothing);
    });
  });

  group('DetailsTable — rendering', () {
    testWidgets('renders all sections immediately (no spoiler)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(DetailsTableContent(details: _makeFullSpoiler())),
      );
      await tester.pump();

      expect(find.text('RIFLE'), findsOneWidget);
      expect(find.text('PROJECTILE'), findsOneWidget);
      expect(find.text('CONDITIONS'), findsOneWidget);
    });

    testWidgets('renders rifle details correctly', (tester) async {
      await tester.pumpWidget(
        _wrap(DetailsTableContent(details: _makeFullSpoiler())),
      );
      await tester.pump();

      expect(find.text('Test Rifle'), findsOneWidget);
      expect(find.text('7.62 mm'), findsOneWidget);
      expect(find.text('1:11"'), findsOneWidget);
    });

    testWidgets('renders projectile details correctly', (tester) async {
      await tester.pumpWidget(
        _wrap(DetailsTableContent(details: _makeFullSpoiler())),
      );
      await tester.pump();

      expect(find.text('G7'), findsOneWidget);
      expect(find.text('0.475 G7'), findsOneWidget);
    });

    testWidgets('renders atmosphere details correctly', (tester) async {
      await tester.pumpWidget(
        _wrap(DetailsTableContent(details: _makeFullSpoiler())),
      );
      await tester.pump();

      expect(find.text('20 °C'), findsOneWidget);
      expect(find.text('1013 hPa'), findsOneWidget);
      expect(find.text('3 m/s'), findsOneWidget);
      expect(find.text('90°'), findsOneWidget);
    });

    testWidgets('shows all section headers even when fields are empty', (
      tester,
    ) async {
      const emptyDetails = DetailsTableData(rifleName: '');

      await tester.pumpWidget(
        _wrap(const DetailsTableContent(details: emptyDetails)),
      );
      await tester.pump();

      // All sections always shown regardless of data
      expect(find.text('RIFLE'), findsOneWidget);
      expect(find.text('CARTRIDGE'), findsOneWidget);
      expect(find.text('PROJECTILE'), findsOneWidget);
      expect(find.text('CONDITIONS'), findsOneWidget);
    });
  });

  group('TrajectoryTable — cell detail dialog', () {
    testWidgets('tapping a cell opens detail dialog', (tester) async {
      await tester.pumpWidget(
        _wrap(TrajectoryTableContent(mainTable: _makeTable())),
      );
      await tester.pump();

      await tester.tap(find.text('790').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('dialog title contains the distance header', (tester) async {
      await tester.pumpWidget(
        _wrap(TrajectoryTableContent(mainTable: _makeTable())),
      );
      await tester.pump();

      // Tap first cell (column 0 → header '100')
      await tester.tap(find.text('790').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('100'), findsWidgets);
    });

    testWidgets('dialog lists all row labels with values', (tester) async {
      await tester.pumpWidget(
        _wrap(TrajectoryTableContent(mainTable: _makeTable())),
      );
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
      await tester.pumpWidget(
        _wrap(TrajectoryTableContent(mainTable: _makeTable())),
      );
      await tester.pump();

      await tester.tap(find.text('790').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
