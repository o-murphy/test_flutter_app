// Widget tests for TablesScreen (Phase 4).
//
// Uses tablesVmProvider override — no FFI, no real ballistics.
//   flutter test test/tables_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eballistica/shared/models/formatted_row.dart';
import 'package:eballistica/features/tables/tables_vm.dart';
import 'package:eballistica/features/tables/tables_screen.dart';
import 'package:eballistica/features/tables/widgets/trajectory_table.dart';

// ── Fake ViewModel ────────────────────────────────────────────────────────────

class _FakeTablesVM extends TablesViewModel {
  final TablesUiState _initialState;
  _FakeTablesVM(this._initialState);

  @override
  Future<TablesUiState> build() async => _initialState;

  @override
  Future<void> recalculate() async {}
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _kSpoiler = TablesSpoilerData(
  rifleName: 'Test Rifle',
  caliber: '7.62 mm',
);

const _kMainTable = FormattedTableData(
  distanceHeaders: ['100', '200', '300'],
  distanceUnit: 'm',
  rows: [
    FormattedRow(
      label: 'V',
      unitSymbol: 'm/s',
      cells: [
        FormattedCell(value: '790'),
        FormattedCell(value: '760'),
        FormattedCell(value: '730'),
      ],
    ),
  ],
);

Widget _scoped(TablesUiState state) => ProviderScope(
      overrides: [tablesVmProvider.overrideWith(() => _FakeTablesVM(state))],
      // TablesScreen lives inside a shell Scaffold in the real app;
      // wrap with Scaffold here so Material-dependent widgets (ListTile in
      // _DetailsSpoiler) have a valid Material ancestor.
      child: MaterialApp(home: Scaffold(body: TablesScreen())),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('TablesScreen — loading state', () {
    testWidgets('shows spinner for TablesUiLoading', (tester) async {
      await tester.pumpWidget(_scoped(const TablesUiLoading()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(TrajectoryTable), findsNothing);
    });

    testWidgets('shows spinner when vm state is null (AsyncLoading)', (tester) async {
      // Before build() resolves the provider emits AsyncLoading — vmState == null
      await tester.pumpWidget(_scoped(const TablesUiLoading()));
      // Don't pump — still in AsyncLoading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('TablesScreen — empty state', () {
    testWidgets('shows table_view icon for TablesUiEmpty', (tester) async {
      await tester.pumpWidget(_scoped(const TablesUiEmpty()));
      await tester.pump();

      expect(find.byIcon(Icons.table_view_outlined), findsOneWidget);
      expect(find.text('No data'), findsOneWidget);
      expect(find.byType(TrajectoryTable), findsNothing);
    });
  });

  group('TablesScreen — ready state', () {
    testWidgets('shows TrajectoryTable for TablesUiReady', (tester) async {
      await tester.pumpWidget(_scoped(const TablesUiReady(
        spoiler: _kSpoiler,
        mainTable: _kMainTable,
      )));
      await tester.pump();

      expect(find.byType(TrajectoryTable), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('TrajectoryTable receives correct mainTable data', (tester) async {
      await tester.pumpWidget(_scoped(const TablesUiReady(
        spoiler: _kSpoiler,
        mainTable: _kMainTable,
      )));
      await tester.pump();

      // Table header '100' and row label 'V' are rendered inside TrajectoryTable
      expect(find.text('100'), findsWidgets);
      expect(find.text('V'), findsOneWidget);
    });

    testWidgets('shows header title Tables', (tester) async {
      await tester.pumpWidget(_scoped(const TablesUiReady(
        spoiler: _kSpoiler,
        mainTable: _kMainTable,
      )));
      await tester.pump();

      expect(find.text('Tables'), findsOneWidget);
    });
  });

  group('TablesScreen — header', () {
    testWidgets('back button is present', (tester) async {
      await tester.pumpWidget(_scoped(const TablesUiLoading()));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('configure and export icon buttons are present', (tester) async {
      await tester.pumpWidget(_scoped(const TablesUiLoading()));
      await tester.pump();

      expect(find.byIcon(Icons.tune_outlined), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });
  });
}
