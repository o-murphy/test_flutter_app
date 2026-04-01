// Widget tests for TrajectoryTable (Phase 4).
//
// TrajectoryTable is now a ConsumerWidget that uses Riverpod.
// Use ProviderContainer to provide mocked data.
//   flutter test test/trajectory_table_test.dart

import 'package:eballistica/features/tables/details_table_mv.dart';
import 'package:eballistica/features/tables/widgets/details_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eballistica/shared/models/formatted_row.dart';
import 'package:eballistica/features/tables/trajectory_tables_vm.dart';
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

DetailsTableData _makeFullDetailstable() => const DetailsTableData(
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

/// Mock ViewModel that extends TrajectoryTablesViewModel
class _MockTrajectoryTablesViewModel extends TrajectoryTablesViewModel {
  final TrajectoryTablesUiState _state;

  _MockTrajectoryTablesViewModel(this._state);

  @override
  Future<TrajectoryTablesUiState> build() async => _state;

  @override
  Future<void> recalculate() async {
    // Do nothing in tests
  }
}

/// Wraps a widget with Riverpod ProviderScope and mocked providers
Widget _wrapWithRiverpod(
  Widget child, {
  TrajectoryTablesUiState? trajectoryState,
  DetailsTableData? detailsData,
}) {
  final container = ProviderContainer(
    overrides: [
      trajectoryTablesVmProvider.overrideWith(
        () => _MockTrajectoryTablesViewModel(
          trajectoryState ?? const TrajectoryTablesUiLoading(),
        ),
      ),
      detailsTableMvProvider.overrideWithValue(detailsData),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('TrajectoryTable — main table rendering', () {
    testWidgets('renders distance headers', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: null,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('100'), findsWidgets);
      expect(find.text('200'), findsWidgets);
      expect(find.text('300'), findsWidgets);
    });

    testWidgets('renders distance unit label', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: null,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Range, m'), findsWidgets);
    });

    testWidgets('renders row labels', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: null,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('V'), findsOneWidget);
      expect(find.text('Drop'), findsOneWidget);
    });

    testWidgets('renders row unit symbols', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: null,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('m/s'), findsOneWidget);
      expect(find.text('cm'), findsOneWidget);
    });

    testWidgets('renders cell values', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: null,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('790'), findsOneWidget);
      expect(find.text('-2.1'), findsOneWidget);
      expect(find.text('-8.5'), findsOneWidget);
    });

    testWidgets('always shows Trajectory section title', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: null,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('TRAJECTORY'), findsOneWidget);
    });
  });

  group('TrajectoryTable — loading state', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: const TrajectoryTablesUiLoading(),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('TrajectoryTable — empty state', () {
    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: const TrajectoryTablesUiEmpty(),
        ),
      );
      await tester.pump();

      expect(find.text('No data'), findsOneWidget);
    });
  });

  group('TrajectoryTable — error state', () {
    testWidgets('shows error message on error', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: const TrajectoryTablesUiError('Test error'),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Test error'), findsOneWidget);
    });
  });

  group('TrajectoryTable — zero crossings section', () {
    testWidgets('shows Zero Crossings title when provided', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: _makeTable(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ZERO CROSSINGS'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('Zero Crossings absent when null', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: null,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ZERO CROSSINGS'), findsNothing);
    });

    testWidgets('Zero Crossings absent when empty headers', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
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

      expect(find.text('ZERO CROSSINGS'), findsNothing);
    });
  });

  group('DetailsTable — rendering', () {
    testWidgets('renders all sections immediately', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const DetailsTable(),
          detailsData: _makeFullDetailstable(),
        ),
      );
      await tester.pump();

      expect(find.text('RIFLE'), findsOneWidget);
      expect(find.text('PROJECTILE'), findsOneWidget);
      expect(find.text('CONDITIONS'), findsOneWidget);
    });

    testWidgets('renders rifle details correctly', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const DetailsTable(),
          detailsData: _makeFullDetailstable(),
        ),
      );
      await tester.pump();

      expect(find.text('Test Rifle'), findsOneWidget);
      expect(find.text('7.62 mm'), findsOneWidget);
      expect(find.text('1:11"'), findsOneWidget);
    });

    testWidgets('renders projectile details correctly', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const DetailsTable(),
          detailsData: _makeFullDetailstable(),
        ),
      );
      await tester.pump();

      expect(find.text('G7'), findsOneWidget);
      expect(find.text('0.475 G7'), findsOneWidget);
    });

    testWidgets('renders atmosphere details correctly', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const DetailsTable(),
          detailsData: _makeFullDetailstable(),
        ),
      );
      await tester.pump();

      expect(find.text('20 °C'), findsOneWidget);
      expect(find.text('1013 hPa'), findsOneWidget);
      expect(find.text('3 m/s'), findsOneWidget);
      expect(find.text('90°'), findsOneWidget);
    });

    testWidgets('returns empty space if no data provided', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(const DetailsTable(), detailsData: null),
      );
      await tester.pump();

      expect(find.text('RIFLE'), findsNothing);
      expect(find.text('CONDITIONS'), findsNothing);
    });
  });

  group('TrajectoryTable — cell detail dialog', () {
    testWidgets('tapping a cell opens detail dialog', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: null,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('790').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('dialog title contains the distance header', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: null,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('790').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('100'), findsWidgets);
    });

    testWidgets('dialog lists all row labels with values', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: null,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('790').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('V'), findsWidgets);
      expect(find.textContaining('Drop'), findsWidgets);
      expect(find.text('790'), findsWidgets);
    });

    testWidgets('Close button dismisses dialog', (tester) async {
      await tester.pumpWidget(
        _wrapWithRiverpod(
          const TrajectoryTable(),
          trajectoryState: TrajectoryTablesUiReady(
            mainTable: _makeTable(),
            zeroCrossings: null,
          ),
        ),
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
