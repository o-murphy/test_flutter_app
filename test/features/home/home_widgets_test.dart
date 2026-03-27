// Widget tests for HomeChartPage, HomeTablePage, HomeReticlePage (Phase 4).
//
// Uses homeVmProvider overrides — no FFI, no real ballistics.
//   flutter test test/home_widgets_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eballistica/core/models/app_settings.dart' show AdjustmentFormat;
import 'package:eballistica/features/home/home_vm.dart';
import 'package:eballistica/shared/models/adjustment_data.dart';
import 'package:eballistica/shared/models/chart_point.dart';
import 'package:eballistica/shared/models/formatted_row.dart';
import 'package:eballistica/features/home/widgets/home_chart_page.dart';
import 'package:eballistica/features/home/widgets/home_reticle_page.dart';
import 'package:eballistica/features/home/widgets/home_table_page.dart';
import 'package:eballistica/features/home/widgets/trajectory_chart.dart';

// ── Fake ViewModel ────────────────────────────────────────────────────────────

class _FakeHomeVM extends HomeViewModel {
  final HomeUiState _initialState;
  _FakeHomeVM(this._initialState);

  @override
  Future<HomeUiState> build() async => _initialState;

  @override
  Future<void> recalculate() async {}

  @override
  void selectChartPoint(int index) {} // no-op; tested separately in home_vm_test
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _kDefaultInfo = HomeChartPointInfo(
  distance: '300 m',
  velocity: '680 m/s',
  energy: '2100 J',
  time: '0.40 s',
  height: '-20.0 cm',
  drop: '-1.50 MRAD',
  windage: '0.30 MRAD',
  mach: '2.00',
);

const _kDefaultPoints = [
  ChartPoint(distanceM: 0,   heightCm: 0,    velocityMps: 800, mach: 2.3, energyJ: 3000, time: 0,     dropAngleMil: 0,    windageAngleMil: 0),
  ChartPoint(distanceM: 100, heightCm: 2.5,  velocityMps: 760, mach: 2.2, energyJ: 2700, time: 0.125, dropAngleMil: 0.5,  windageAngleMil: 0.1),
  ChartPoint(distanceM: 300, heightCm: -20,  velocityMps: 680, mach: 2.0, energyJ: 2100, time: 0.4,   dropAngleMil: -1.5, windageAngleMil: 0.3),
];

const _kDefaultTableData = FormattedTableData(
  distanceHeaders: ['100', '200', '300', '400', '500'],
  distanceUnit: 'm',
  rows: [
    FormattedRow(
      label: 'V',
      unitSymbol: 'm/s',
      cells: [
        FormattedCell(value: '790'),
        FormattedCell(value: '760'),
        FormattedCell(value: '730', isTargetColumn: true),
        FormattedCell(value: '700'),
        FormattedCell(value: '670'),
      ],
    ),
    FormattedRow(
      label: 'Drop',
      unitSymbol: 'cm',
      cells: [
        FormattedCell(value: '-2.1'),
        FormattedCell(value: '-8.5'),
        FormattedCell(value: '-19.2'),
        FormattedCell(value: '-35.0'),
        FormattedCell(value: '-56.0'),
      ],
    ),
  ],
);

HomeUiReady _makeReady({
  AdjustmentData? adjustment,
  AdjustmentFormat fmt = AdjustmentFormat.arrows,
  String cartridgeInfoLine = 'Test 175gr · G7 · 800 m/s',
  List<ChartPoint> chartPoints = _kDefaultPoints,
  HomeChartPointInfo? selectedPointInfo = _kDefaultInfo,
  int? selectedChartIndex = 2,
  FormattedTableData tableData = _kDefaultTableData,
}) {
  return HomeUiReady(
    rifleName: 'Test Rifle',
    cartridgeName: 'Test .308',
    windAngleDeg: 90.0,
    tempDisplay: '20 °C',
    altDisplay: '150 m',
    pressDisplay: '1013 hPa',
    humidDisplay: '50 %',
    windSpeedDisplay: '5 m/s',
    windSpeedMps: 5.0,
    lookAngleDisplay: '0°',
    lookAngleDeg: 0.0,
    targetDistanceDisplay: '300 m',
    targetDistanceM: 300.0,
    cartridgeInfoLine: cartridgeInfoLine,
    adjustment: adjustment ??
        const AdjustmentData(
          elevation: [
            AdjustmentValue(absValue: 2.5, isPositive: true,  symbol: 'MRAD', decimals: 2),
          ],
          windage: [
            AdjustmentValue(absValue: 1.2, isPositive: false, symbol: 'MRAD', decimals: 2),
          ],
        ),
    adjustmentFormat: fmt,
    tableData: tableData,
    chartData: ChartData(points: chartPoints, snapDistM: 100),
    selectedPointInfo: selectedPointInfo,
    selectedChartIndex: selectedChartIndex,
  );
}

Widget _scoped(HomeUiState state, Widget child) => ProviderScope(
      overrides: [homeVmProvider.overrideWith(() => _FakeHomeVM(state))],
      child: MaterialApp(home: Scaffold(body: child)),
    );

// ── HomeChartPage ─────────────────────────────────────────────────────────────

void main() {
  group('HomeChartPage — non-ready states', () {
    testWidgets('shows spinner when state is HomeUiLoading', (tester) async {
      await tester.pumpWidget(_scoped(const HomeUiLoading(), const HomeChartPage()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(TrajectoryChart), findsNothing);
    });

    testWidgets('shows spinner for HomeUiError', (tester) async {
      await tester.pumpWidget(
          _scoped(const HomeUiError('oops'), const HomeChartPage()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows No data when chart has no points', (tester) async {
      final state = _makeReady(chartPoints: []);
      await tester.pumpWidget(_scoped(state, const HomeChartPage()));
      await tester.pump();

      expect(find.text('No data'), findsOneWidget);
      expect(find.byType(TrajectoryChart), findsNothing);
    });
  });

  group('HomeChartPage — ready state', () {
    testWidgets('shows TrajectoryChart when ready with points', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeChartPage()));
      await tester.pump();

      expect(find.byType(TrajectoryChart), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('info grid shows pre-formatted distance', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeChartPage()));
      await tester.pump();

      expect(find.text('300 m'), findsOneWidget);
    });

    testWidgets('info grid shows pre-formatted velocity', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeChartPage()));
      await tester.pump();

      expect(find.text('680 m/s'), findsOneWidget);
    });

    testWidgets('info grid shows energy and time', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeChartPage()));
      await tester.pump();

      expect(find.text('2100 J'), findsOneWidget);
      expect(find.text('0.40 s'), findsOneWidget);
    });

    testWidgets('info grid shows drop and windage angles', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeChartPage()));
      await tester.pump();

      expect(find.text('-1.50 MRAD'), findsOneWidget);
      expect(find.text('0.30 MRAD'), findsOneWidget);
    });

    testWidgets('info grid shows mach number', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeChartPage()));
      await tester.pump();

      expect(find.text('2.00'), findsOneWidget);
    });

    testWidgets('empty SizedBox shown when selectedPointInfo is null', (tester) async {
      final state = _makeReady(selectedPointInfo: null, selectedChartIndex: null);
      await tester.pumpWidget(_scoped(state, const HomeChartPage()));
      await tester.pump();

      // No info text — only the chart is shown
      expect(find.text('300 m'), findsNothing);
      expect(find.byType(TrajectoryChart), findsOneWidget);
    });
  });

  // ── HomeTablePage ──────────────────────────────────────────────────────────

  group('HomeTablePage — non-ready states', () {
    testWidgets('shows spinner when state is HomeUiLoading', (tester) async {
      await tester.pumpWidget(_scoped(const HomeUiLoading(), const HomeTablePage()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows No data when table is empty', (tester) async {
      final state = _makeReady(tableData: FormattedTableData.empty);
      await tester.pumpWidget(_scoped(state, const HomeTablePage()));
      await tester.pump();

      expect(find.text('No data'), findsOneWidget);
    });
  });

  group('HomeTablePage — ready state', () {
    testWidgets('shows distance headers', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeTablePage()));
      await tester.pump();

      expect(find.text('100'), findsWidgets);
      expect(find.text('200'), findsWidgets);
      expect(find.text('500'), findsWidgets);
    });

    testWidgets('shows distance unit in header row', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeTablePage()));
      await tester.pump();

      expect(find.text('m'), findsWidgets);
    });

    testWidgets('shows row label V', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeTablePage()));
      await tester.pump();

      expect(find.text('V'), findsOneWidget);
    });

    testWidgets('shows row unit symbol m/s', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeTablePage()));
      await tester.pump();

      expect(find.text('m/s'), findsOneWidget);
    });

    testWidgets('shows cell values', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeTablePage()));
      await tester.pump();

      expect(find.text('790'), findsOneWidget);
      expect(find.text('730'), findsOneWidget);
    });

    testWidgets('shows second row label Drop', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeTablePage()));
      await tester.pump();

      expect(find.text('Drop'), findsOneWidget);
      expect(find.text('cm'), findsOneWidget);
    });
  });

  // ── HomeReticlePage ────────────────────────────────────────────────────────

  group('HomeReticlePage — non-ready states', () {
    testWidgets('shows spinner when state is HomeUiLoading', (tester) async {
      await tester.pumpWidget(
          _scoped(const HomeUiLoading(), const HomeReticlePage()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HomeReticlePage — ready state content', () {
    testWidgets('shows cartridgeInfoLine text', (tester) async {
      await tester.pumpWidget(_scoped(
        _makeReady(cartridgeInfoLine: 'Test 175gr · G7 · 800 m/s'),
        const HomeReticlePage(),
      ));
      await tester.pump();

      expect(find.text('Test 175gr · G7 · 800 m/s'), findsOneWidget);
    });

    testWidgets('shows adjustment values', (tester) async {
      await tester.pumpWidget(_scoped(_makeReady(), const HomeReticlePage()));
      await tester.pump();

      expect(find.text('2.50'), findsOneWidget); // absValue with 2 decimals
      expect(find.text('1.20'), findsOneWidget);
      expect(find.textContaining('MRAD'), findsWidgets);
    });

    testWidgets('shows Enable units message when elevation is empty', (tester) async {
      final state = _makeReady(adjustment: AdjustmentData.empty);
      await tester.pumpWidget(_scoped(state, const HomeReticlePage()));
      await tester.pump();

      expect(find.textContaining('Enable units'), findsOneWidget);
    });
  });

  group('HomeReticlePage — AdjustmentFormat direction indicators', () {
    testWidgets('arrows format: positive elevation shows ↑', (tester) async {
      final state = _makeReady(
        fmt: AdjustmentFormat.arrows,
        adjustment: const AdjustmentData(
          elevation: [AdjustmentValue(absValue: 2.5, isPositive: true,  symbol: 'MRAD', decimals: 2)],
          windage:   [AdjustmentValue(absValue: 1.2, isPositive: true,  symbol: 'MRAD', decimals: 2)],
        ),
      );
      await tester.pumpWidget(_scoped(state, const HomeReticlePage()));
      await tester.pump();

      expect(find.text('↑'), findsOneWidget);
      expect(find.text('→'), findsOneWidget);
    });

    testWidgets('arrows format: negative elevation shows ↓', (tester) async {
      final state = _makeReady(
        fmt: AdjustmentFormat.arrows,
        adjustment: const AdjustmentData(
          elevation: [AdjustmentValue(absValue: 2.5, isPositive: false, symbol: 'MRAD', decimals: 2)],
          windage:   [AdjustmentValue(absValue: 1.2, isPositive: false, symbol: 'MRAD', decimals: 2)],
        ),
      );
      await tester.pumpWidget(_scoped(state, const HomeReticlePage()));
      await tester.pump();

      expect(find.text('↓'), findsOneWidget);
      expect(find.text('←'), findsOneWidget);
    });

    testWidgets('signs format: positive shows +', (tester) async {
      final state = _makeReady(
        fmt: AdjustmentFormat.signs,
        adjustment: const AdjustmentData(
          elevation: [AdjustmentValue(absValue: 2.5, isPositive: true,  symbol: 'MRAD', decimals: 2)],
          windage:   [AdjustmentValue(absValue: 1.2, isPositive: false, symbol: 'MRAD', decimals: 2)],
        ),
      );
      await tester.pumpWidget(_scoped(state, const HomeReticlePage()));
      await tester.pump();

      expect(find.text('+'), findsOneWidget);
      expect(find.text('−'), findsOneWidget);
    });

    testWidgets('letters format: positive elevation shows U, R', (tester) async {
      final state = _makeReady(
        fmt: AdjustmentFormat.letters,
        adjustment: const AdjustmentData(
          elevation: [AdjustmentValue(absValue: 2.5, isPositive: true,  symbol: 'MRAD', decimals: 2)],
          windage:   [AdjustmentValue(absValue: 1.2, isPositive: true,  symbol: 'MRAD', decimals: 2)],
        ),
      );
      await tester.pumpWidget(_scoped(state, const HomeReticlePage()));
      await tester.pump();

      expect(find.text('U'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
    });

    testWidgets('letters format: negative elevation shows D, L', (tester) async {
      final state = _makeReady(
        fmt: AdjustmentFormat.letters,
        adjustment: const AdjustmentData(
          elevation: [AdjustmentValue(absValue: 2.5, isPositive: false, symbol: 'MRAD', decimals: 2)],
          windage:   [AdjustmentValue(absValue: 1.2, isPositive: false, symbol: 'MRAD', decimals: 2)],
        ),
      );
      await tester.pumpWidget(_scoped(state, const HomeReticlePage()));
      await tester.pump();

      expect(find.text('D'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
    });
  });
}
