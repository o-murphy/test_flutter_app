# eBallistica — Refactoring Plan

**Мета:** Врятувати проект без переписування з нуля. Feature-first, покроково,
кожна фаза — окремий коміт що не ламає поточне.

**Принципи:**
- UI не знає про `Unit`, `Dimension`, `FC`, `Calculator`
- ViewModel — чистий Dart, без жодного Flutter імпорту
- Всі конвертації одиниць — в одному місці (`UnitFormatter`)
- Riverpod тільки як DI-контейнер і state holder, не як шина подій

---

## Що НЕ чіпаємо (залишаємо як є)

- `lib/src/solver/` — `Unit`, `Dimension`, всі subclasses, `Calculator`, FFI
- `lib/src/models/` — `ShotProfile`, `Rifle`, `Cartridge`, `Projectile`, `Sight`, `AppSettings`, `UnitSettings`, `TableConfig`
- `lib/storage/` — `AppStorage`, `JsonFileStorage`
- `lib/src/a7p/` — парсер/валідатор
- `lib/src/proto/` — згенерований код
- `lib/router.dart` — GoRouter
- `lib/main.dart` — мінімальні зміни

---

## Нова структура проекту

```
lib/
├── main.dart
├── router.dart
│
├── formatting/                          ← НОВИЙ ШАР (чистий Dart)
│   ├── unit_formatter.dart              ← abstract interface
│   └── unit_formatter_impl.dart         ← єдине місце всіх конвертацій
│
├── domain/                              ← НОВИЙ ШАР (чистий Dart, інтерфейси)
│   ├── ballistics_service.dart          ← abstract interface
│   ├── shot_profile_repository.dart     ← abstract interface
│   ├── settings_repository.dart         ← abstract interface
│   └── library_repository.dart          ← abstract interface
│
├── services/                            ← НОВИЙ ШАР (реалізації domain)
│   ├── ballistics_service_impl.dart     ← весь код з calculation_provider
│   └── library_repository_impl.dart     ← тонка обгортка над JsonFileStorage
│
├── viewmodels/                          ← НОВИЙ ШАР (чистий Dart!)
│   ├── home_vm.dart
│   ├── conditions_vm.dart
│   ├── tables_vm.dart
│   ├── settings_vm.dart
│   └── shared/
│       ├── adjustment_data.dart         ← data class (чистий Dart)
│       ├── chart_point.dart             ← data class
│       └── formatted_row.dart           ← data class
│
├── providers/                           ← тільки DI + тонкі bridge-провайдери
│   ├── formatter_provider.dart          ← unitFormatterProvider
│   ├── service_providers.dart           ← ballisticsServiceProvider тощо
│   ├── settings_provider.dart           ← залишаємо, мінімальні зміни
│   ├── shot_profile_provider.dart       ← залишаємо, мінімальні зміни
│   ├── storage_provider.dart            ← залишаємо
│   └── library_provider.dart            ← залишаємо
│
├── screens/                             ← тільки UI, без жодної логіки
│   ├── home_screen.dart
│   ├── conditions_screen.dart
│   ├── tables_screen.dart
│   ├── settings_screen.dart
│   └── ...
│
├── widgets/                             ← залишаємо, прибираємо конвертації
│   ├── trajectory_table.dart
│   ├── trajectory_chart.dart
│   ├── wind_indicator.dart
│   └── ...
│
├── helpers/                             ← ВИДАЛЯЄМО після рефакторингу
│   └── dimension_converter.dart         ← замінюється на UnitFormatter
│
└── src/                                 ← не чіпаємо
    ├── solver/
    ├── models/
    ├── a7p/
    └── proto/
```

---

## ФАЗА 0 — UnitFormatter (робити першим, дає найбільший профіт)

### Що робити

Створити єдине місце де відбуваються всі конвертації одиниць для відображення.
Замінює `dimension_converter.dart`, прямі виклики `.in_()` у віджетах, і `FC.*` у UI.

### Файли для створення

**`lib/formatting/unit_formatter.dart`**

```dart
// ЧИСТИЙ DART — без flutter імпортів
import '../src/solver/unit.dart';
import '../src/models/unit_settings.dart';

/// Єдиний контракт для форматування фізичних величин у рядки для UI.
/// ViewModel і Widget ніколи не викликають .in_() напряму.
abstract interface class UnitFormatter {
  // --- Форматовані рядки (з одиницею) ---
  String velocity(dynamic dim);        // "888 m/s"
  String distance(dynamic dim);        // "300 m"
  String shortDistance(dynamic dim);   // "300" (без символу, для compact UI)
  String temperature(dynamic dim);     // "15 °C"
  String pressure(dynamic dim);        // "1013 hPa"
  String drop(dynamic dim);            // "−12.5 cm"
  String windage(dynamic dim);         // "3.2 cm"
  String adjustment(dynamic dim);      // "3.45 MIL"
  String energy(dynamic dim);          // "4200 J"
  String weight(dynamic dim);          // "250 gr"
  String sightHeight(dynamic dim);     // "8.5 mm"
  String twist(dynamic dim);           // "1:10 inch"
  String humidity(double fraction);    // "50 %"
  String mach(double mach);            // "0.85 M"
  String time(double seconds);         // "1.234 s"
  String muzzleVelocity(dynamic dim);  // спеціальна точність для MV

  // --- Сирі числа (без одиниці, для слайдерів/полів вводу) ---
  double rawVelocity(dynamic dim);
  double rawDistance(dynamic dim);
  double rawTemperature(dynamic dim);
  double rawPressure(dynamic dim);
  double rawDrop(dynamic dim);
  double rawAdjustment(dynamic dim);
  double rawEnergy(dynamic dim);
  double rawWeight(dynamic dim);
  double rawSightHeight(dynamic dim);

  // --- Символи поточних одиниць ---
  String get velocitySymbol;
  String get distanceSymbol;
  String get temperatureSymbol;
  String get pressureSymbol;
  String get dropSymbol;
  String get adjustmentSymbol;
  String get energySymbol;
  String get weightSymbol;
  String get sightHeightSymbol;

  // --- Конвертація введення користувача назад у raw (для діалогів) ---
  /// Converts user input value (in display unit) back to raw storage unit (metres, celsius etc.)
  double inputToRaw(double displayValue, InputField field);
  double rawToInput(double rawValue, InputField field);
}

/// Позначає яке поле вводить користувач — для зворотної конвертації
enum InputField {
  velocity,
  distance,
  temperature,
  pressure,
  humidity,
  windVelocity,
  lookAngle,
  targetDistance,
  zeroDistance,
  sightHeight,
  twist,
  bulletWeight,
  bulletLength,
  bulletDiameter,
  bc,
}
```

**`lib/formatting/unit_formatter_impl.dart`**

```dart
// ЧИСТИЙ DART — без flutter імпортів
import 'dart:math';
import '../src/solver/unit.dart';
import '../src/models/unit_settings.dart';
import '../src/models/field_constraints.dart';
import 'unit_formatter.dart';

class UnitFormatterImpl implements UnitFormatter {
  final UnitSettings _u;

  const UnitFormatterImpl(this._u);

  // --- Helpers ---

  double _conv(dynamic dim, Unit rawUnit, Unit dispUnit) {
    if (rawUnit == dispUnit) return (dim as dynamic).in_(rawUnit) as double;
    final raw = (dim as dynamic).in_(rawUnit) as double;
    return (rawUnit(raw) as dynamic).in_(dispUnit) as double;
  }

  int _acc(FieldConstraints fc, Unit displayUnit) {
    if (fc.rawUnit == displayUnit) return fc.accuracy;
    final lo = (fc.rawUnit(fc.minRaw) as dynamic).in_(displayUnit) as double;
    final hi = (fc.rawUnit(fc.minRaw + fc.stepRaw) as dynamic).in_(displayUnit) as double;
    final step = (hi - lo).abs();
    if (step <= 0) return fc.accuracy;
    final d = (-log(step) / ln10).ceil();
    return d < 0 ? 0 : d;
  }

  // --- Formatted strings ---

  @override
  String velocity(dynamic dim) {
    final v = _conv(dim, Unit.mps, _u.velocity);
    return '${v.toStringAsFixed(_acc(FC.muzzleVelocity, _u.velocity))} ${_u.velocity.symbol}';
  }

  @override
  String muzzleVelocity(dynamic dim) => velocity(dim); // alias з правильною точністю

  @override
  String distance(dynamic dim) {
    final v = _conv(dim, Unit.meter, _u.distance);
    return '${v.toStringAsFixed(_acc(FC.targetDistance, _u.distance))} ${_u.distance.symbol}';
  }

  @override
  String shortDistance(dynamic dim) {
    final v = _conv(dim, Unit.meter, _u.distance);
    return v.toStringAsFixed(_acc(FC.targetDistance, _u.distance));
  }

  @override
  String temperature(dynamic dim) {
    final v = _conv(dim, Unit.celsius, _u.temperature);
    return '${v.toStringAsFixed(FC.temperature.accuracy)} ${_u.temperature.symbol}';
  }

  @override
  String pressure(dynamic dim) {
    final v = _conv(dim, Unit.hPa, _u.pressure);
    return '${v.toStringAsFixed(_acc(FC.pressure, _u.pressure))} ${_u.pressure.symbol}';
  }

  @override
  String drop(dynamic dim) {
    final v = _conv(dim, Unit.foot, _u.drop);
    return '${v.toStringAsFixed(_acc(FC.drop, _u.drop))} ${_u.drop.symbol}';
  }

  @override
  String windage(dynamic dim) => drop(dim);

  @override
  String adjustment(dynamic dim) {
    final v = _conv(dim, Unit.mil, _u.adjustment);
    return '${v.toStringAsFixed(_acc(FC.adjustment, _u.adjustment))} ${_u.adjustment.symbol}';
  }

  @override
  String energy(dynamic dim) {
    final v = _conv(dim, Unit.footPound, _u.energy);
    return '${v.toStringAsFixed(_acc(FC.energy, _u.energy))} ${_u.energy.symbol}';
  }

  @override
  String weight(dynamic dim) {
    final v = _conv(dim, Unit.grain, _u.weight);
    return '${v.toStringAsFixed(_acc(FC.bulletWeight, _u.weight))} ${_u.weight.symbol}';
  }

  @override
  String sightHeight(dynamic dim) {
    final v = _conv(dim, Unit.millimeter, _u.sightHeight);
    return '${v.toStringAsFixed(_acc(FC.sightHeight, _u.sightHeight))} ${_u.sightHeight.symbol}';
  }

  @override
  String twist(dynamic dim) {
    final v = _conv(dim, Unit.inch, _u.twist);
    return '1:${v.toStringAsFixed(_acc(FC.twistRate, _u.twist))} ${_u.twist.symbol}';
  }

  @override
  String humidity(double fraction) =>
      '${(fraction * 100).toStringAsFixed(0)} %';

  @override
  String mach(double m) => '${m.toStringAsFixed(2)} M';

  @override
  String time(double seconds) => '${seconds.toStringAsFixed(3)} s';

  // --- Raw numbers ---

  @override double rawVelocity(dynamic dim) => _conv(dim, Unit.mps, _u.velocity);
  @override double rawDistance(dynamic dim) => _conv(dim, Unit.meter, _u.distance);
  @override double rawTemperature(dynamic dim) => _conv(dim, Unit.celsius, _u.temperature);
  @override double rawPressure(dynamic dim) => _conv(dim, Unit.hPa, _u.pressure);
  @override double rawDrop(dynamic dim) => _conv(dim, Unit.foot, _u.drop);
  @override double rawAdjustment(dynamic dim) => _conv(dim, Unit.mil, _u.adjustment);
  @override double rawEnergy(dynamic dim) => _conv(dim, Unit.footPound, _u.energy);
  @override double rawWeight(dynamic dim) => _conv(dim, Unit.grain, _u.weight);
  @override double rawSightHeight(dynamic dim) => _conv(dim, Unit.millimeter, _u.sightHeight);

  // --- Symbols ---

  @override String get velocitySymbol    => _u.velocity.symbol;
  @override String get distanceSymbol    => _u.distance.symbol;
  @override String get temperatureSymbol => _u.temperature.symbol;
  @override String get pressureSymbol    => _u.pressure.symbol;
  @override String get dropSymbol        => _u.drop.symbol;
  @override String get adjustmentSymbol  => _u.adjustment.symbol;
  @override String get energySymbol      => _u.energy.symbol;
  @override String get weightSymbol      => _u.weight.symbol;
  @override String get sightHeightSymbol => _u.sightHeight.symbol;

  // --- Input conversion (для діалогів вводу) ---

  @override
  double inputToRaw(double displayValue, InputField field) {
    return switch (field) {
      InputField.velocity      => Velocity(displayValue, _u.velocity).in_(Unit.mps),
      InputField.distance      => Distance(displayValue, _u.distance).in_(Unit.meter),
      InputField.targetDistance => Distance(displayValue, _u.distance).in_(Unit.meter),
      InputField.zeroDistance  => Distance(displayValue, _u.distance).in_(Unit.meter),
      InputField.temperature   => Temperature(displayValue, _u.temperature).in_(Unit.celsius),
      InputField.pressure      => Pressure(displayValue, _u.pressure).in_(Unit.hPa),
      InputField.humidity      => displayValue / 100.0,
      InputField.windVelocity  => Velocity(displayValue, _u.velocity).in_(Unit.mps),
      InputField.lookAngle     => displayValue, // завжди degrees
      InputField.sightHeight   => Distance(displayValue, _u.sightHeight).in_(Unit.millimeter),
      InputField.twist         => Distance(displayValue, _u.twist).in_(Unit.inch),
      InputField.bulletWeight  => Weight(displayValue, _u.weight).in_(Unit.grain),
      InputField.bulletLength  => Distance(displayValue, _u.length).in_(Unit.millimeter),
      InputField.bulletDiameter => Distance(displayValue, _u.diameter).in_(Unit.millimeter),
      InputField.bc            => displayValue, // dimensionless
    };
  }

  @override
  double rawToInput(double rawValue, InputField field) {
    return switch (field) {
      InputField.velocity      => Velocity(rawValue, Unit.mps).in_(_u.velocity),
      InputField.distance      => Distance(rawValue, Unit.meter).in_(_u.distance),
      InputField.targetDistance => Distance(rawValue, Unit.meter).in_(_u.distance),
      InputField.zeroDistance  => Distance(rawValue, Unit.meter).in_(_u.distance),
      InputField.temperature   => Temperature(rawValue, Unit.celsius).in_(_u.temperature),
      InputField.pressure      => Pressure(rawValue, Unit.hPa).in_(_u.pressure),
      InputField.humidity      => rawValue * 100.0,
      InputField.windVelocity  => Velocity(rawValue, Unit.mps).in_(_u.velocity),
      InputField.lookAngle     => rawValue,
      InputField.sightHeight   => Distance(rawValue, Unit.millimeter).in_(_u.sightHeight),
      InputField.twist         => Distance(rawValue, Unit.inch).in_(_u.twist),
      InputField.bulletWeight  => Weight(rawValue, Unit.grain).in_(_u.weight),
      InputField.bulletLength  => Distance(rawValue, Unit.millimeter).in_(_u.length),
      InputField.bulletDiameter => Distance(rawValue, Unit.millimeter).in_(_u.diameter),
      InputField.bc            => rawValue,
    };
  }
}
```

**`lib/providers/formatter_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../formatting/unit_formatter.dart';
import '../formatting/unit_formatter_impl.dart';
import 'settings_provider.dart';

final unitFormatterProvider = Provider<UnitFormatter>((ref) {
  final units = ref.watch(unitSettingsProvider);
  return UnitFormatterImpl(units);
});
```

### Що видалити після Фази 0

- `lib/helpers/dimension_converter.dart` — повністю
- Всі `import '../helpers/dimension_converter.dart'` замінити на formatter

---

## ФАЗА 1 — BallisticsService

### Чому

Зараз `calculation_provider.dart` містить: бізнес-логіку розрахунку, кешування,
рішення "коли рахувати", побудову `Shot`. Це неможливо тестувати і важко змінювати.

### Файли для створення

**`lib/domain/ballistics_service.dart`**

```dart
// ЧИСТИЙ DART
import '../src/models/shot_profile.dart';
import '../src/solver/trajectory_data.dart';
import '../src/solver/unit.dart';

class TableCalcOptions {
  final double startM;
  final double endM;
  final double stepM;
  final bool usePowderSensitivity;

  const TableCalcOptions({
    this.startM = 0,
    this.endM = 2000,
    this.stepM = 100,
    this.usePowderSensitivity = false,
  });
}

class TargetCalcOptions {
  final double targetDistM;
  final double chartStepM;
  final bool usePowderSensitivity;

  const TargetCalcOptions({
    required this.targetDistM,
    this.chartStepM = 10,
    this.usePowderSensitivity = false,
  });
}

class BallisticsResult {
  final HitResult hitResult;
  final double zeroElevationRad; // кешований нуль

  const BallisticsResult({
    required this.hitResult,
    required this.zeroElevationRad,
  });
}

abstract interface class BallisticsService {
  Future<BallisticsResult> calculateTable(
    ShotProfile profile,
    TableCalcOptions opts, {
    double? cachedZeroElevRad,
  });

  Future<BallisticsResult> calculateForTarget(
    ShotProfile profile,
    TargetCalcOptions opts, {
    double? cachedZeroElevRad,
  });
}
```

**`lib/services/ballistics_service_impl.dart`**

```dart
// ЧИСТИЙ DART
import 'package:flutter/foundation.dart' show compute;
import '../domain/ballistics_service.dart';
import '../src/models/shot_profile.dart';
import '../src/solver/calculator.dart';
import '../src/solver/conditions.dart';
import '../src/solver/ffi/bclibc_bindings.g.dart';
import '../src/solver/munition.dart';
import '../src/solver/shot.dart';
import '../src/solver/trajectory_data.dart';
import '../src/solver/unit.dart';

// --- Isolate функції (top-level, як і зараз) ---

typedef _TableArgs = (ShotProfile, TableCalcOptions, double?);
typedef _TableResult = (HitResult?, double?);

_TableResult _runTable(_TableArgs args) {
  final (profile, opts, cachedZeroElevRad) = args;
  // ... весь код з _runTableCalculation перенести сюди без змін
}

typedef _TargetArgs = (ShotProfile, TargetCalcOptions, double?);
typedef _TargetResult = (HitResult?, double?);

_TargetResult _runTarget(_TargetArgs args) {
  final (profile, opts, cachedZeroElevRad) = args;
  // ... весь код з _runHomeCalculation перенести сюди без змін
}

// --- Реалізація ---

class BallisticsServiceImpl implements BallisticsService {
  @override
  Future<BallisticsResult> calculateTable(
    ShotProfile profile,
    TableCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    final (hit, freshZero) = await compute(
      _runTable,
      (profile, opts, cachedZeroElevRad),
    );
    if (hit == null) throw StateError('Table calculation returned null');
    return BallisticsResult(
      hitResult: hit,
      zeroElevationRad: freshZero ?? cachedZeroElevRad ?? 0.0,
    );
  }

  @override
  Future<BallisticsResult> calculateForTarget(
    ShotProfile profile,
    TargetCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    final (hit, freshZero) = await compute(
      _runTarget,
      (profile, opts, cachedZeroElevRad),
    );
    if (hit == null) throw StateError('Target calculation returned null');
    return BallisticsResult(
      hitResult: hit,
      zeroElevationRad: freshZero ?? cachedZeroElevRad ?? 0.0,
    );
  }
}
```

**`lib/providers/service_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ballistics_service.dart';
import '../services/ballistics_service_impl.dart';

final ballisticsServiceProvider = Provider<BallisticsService>((ref) {
  return BallisticsServiceImpl();
});
```

---

## ФАЗА 2 — ViewModels (чистий Dart)

### Загальні правила для КОЖНОГО ViewModel

```
✅ import 'dart:async';
✅ import 'package:flutter_riverpod/flutter_riverpod.dart';
✅ import '../domain/...';
✅ import '../formatting/unit_formatter.dart';
✅ import '../src/models/...';
✅ import '../src/solver/unit.dart';

❌ import 'package:flutter/material.dart';
❌ import 'package:flutter/widgets.dart';
❌ import 'package:flutter/foundation.dart';  // тільки compute — і то краще в service
❌ Color, Widget, BuildContext, IconData, TextStyle — ЗАБОРОНЕНІ
```

### Shared data classes

**`lib/viewmodels/shared/adjustment_data.dart`**

```dart
// ЧИСТИЙ DART

class AdjustmentValue {
  final double absValue;   // абсолютне значення
  final bool isPositive;   // напрямок
  final String symbol;     // "MIL", "MOA" тощо
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
  final List<AdjustmentValue> elevation;  // список по всім обраним одиницям
  final List<AdjustmentValue> windage;

  const AdjustmentData({
    required this.elevation,
    required this.windage,
  });

  static const empty = AdjustmentData(elevation: [], windage: []);
}
```

**`lib/viewmodels/shared/chart_point.dart`**

```dart
// ЧИСТИЙ DART

class ChartPoint {
  final double distanceM;
  final double heightCm;
  final double velocityMps;
  final double mach;
  final bool isZeroCrossing;
  final bool isSubsonic;

  const ChartPoint({
    required this.distanceM,
    required this.heightCm,
    required this.velocityMps,
    required this.mach,
    this.isZeroCrossing = false,
    this.isSubsonic = false,
  });
}

class ChartData {
  final List<ChartPoint> points;
  final double snapDistM;

  const ChartData({required this.points, required this.snapDistM});

  ChartPoint? pointAt(int index) =>
      (index >= 0 && index < points.length) ? points[index] : null;
}
```

**`lib/viewmodels/shared/formatted_row.dart`**

```dart
// ЧИСТИЙ DART — для trajectory table

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
  final List<String> distanceHeaders;  // ["200", "300", "400", ...]
  final List<FormattedRow> rows;
  final String distanceUnit;

  const FormattedTableData({
    required this.distanceHeaders,
    required this.rows,
    required this.distanceUnit,
  });
}
```

### HomeViewModel

**`lib/viewmodels/home_vm.dart`**

```dart
// ЧИСТИЙ DART — 0 flutter імпортів
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ballistics_service.dart';
import '../formatting/unit_formatter.dart';
import '../providers/formatter_provider.dart';
import '../providers/service_providers.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../src/models/app_settings.dart';
import '../src/solver/unit.dart';
import 'shared/adjustment_data.dart';
import 'shared/chart_point.dart';
import 'shared/formatted_row.dart';

// --- State ---

sealed class HomeUiState {
  const HomeUiState();
}

class HomeUiLoading extends HomeUiState {
  const HomeUiLoading();
}

class HomeUiReady extends HomeUiState {
  // Top block
  final String rifleName;
  final String cartridgeName;
  final double windAngleDeg;

  // Info tiles
  final String tempDisplay;
  final String altDisplay;
  final String pressDisplay;
  final String humidDisplay;

  // Bottom block — Page 1 (Reticle)
  final String cartridgeInfoLine;   // "UKROP 250GR; 888 m/s; G7 0.314; Sg 1.42"
  final AdjustmentData adjustment;

  // Bottom block — Page 2 (Table)
  final FormattedTableData tableData;

  // Bottom block — Page 3 (Chart)
  final ChartData chartData;
  final HomeChartPointInfo? selectedPointInfo;

  const HomeUiReady({
    required this.rifleName,
    required this.cartridgeName,
    required this.windAngleDeg,
    required this.tempDisplay,
    required this.altDisplay,
    required this.pressDisplay,
    required this.humidDisplay,
    required this.cartridgeInfoLine,
    required this.adjustment,
    required this.tableData,
    required this.chartData,
    this.selectedPointInfo,
  });
}

class HomeUiError extends HomeUiState {
  final String message;
  const HomeUiError(this.message);
}

class HomeChartPointInfo {
  final String distance;
  final String velocity;
  final String energy;
  final String time;
  final String height;
  final String drop;
  final String windage;
  final String mach;

  const HomeChartPointInfo({
    required this.distance,
    required this.velocity,
    required this.energy,
    required this.time,
    required this.height,
    required this.drop,
    required this.windage,
    required this.mach,
  });
}

// --- ViewModel ---

class HomeViewModel extends AsyncNotifier<HomeUiState> {
  // Zero cache (не стейт UI — внутрішній деталь)
  double? _cachedZeroElevRad;
  List<double>? _lastZeroKey;

  @override
  Future<HomeUiState> build() async {
    return const HomeUiLoading();
  }

  Future<void> recalculate() async {
    final profile = ref.read(shotProfileProvider).value;
    final settings = ref.read(settingsProvider).value;
    final formatter = ref.read(unitFormatterProvider);

    if (profile == null || settings == null) return;

    state = const AsyncData(HomeUiLoading());

    try {
      final opts = TargetCalcOptions(
        targetDistM: profile.targetDistance.in_(Unit.meter),
        chartStepM: settings.chartDistanceStep,
        usePowderSensitivity: settings.enablePowderSensitivity,
      );

      final zeroKey = _buildZeroKey(profile, settings.enablePowderSensitivity);
      final useCache = _listEquals(zeroKey, _lastZeroKey);

      final result = await ref.read(ballisticsServiceProvider).calculateForTarget(
        profile,
        opts,
        cachedZeroElevRad: useCache ? _cachedZeroElevRad : null,
      );

      _cachedZeroElevRad = result.zeroElevationRad;
      _lastZeroKey = zeroKey;

      final uiState = _buildReadyState(
        profile: profile,
        settings: settings,
        formatter: formatter,
        result: result,
      );

      state = AsyncData(uiState);
    } catch (e, st) {
      state = AsyncData(HomeUiError(e.toString()));
    }
  }

  void selectChartPoint(int index) {
    final current = state.value;
    if (current is! HomeUiReady) return;
    final point = current.chartData.pointAt(index);
    if (point == null) return;

    final formatter = ref.read(unitFormatterProvider);
    final info = _buildPointInfo(point, formatter);
    state = AsyncData(HomeUiReady(
      rifleName: current.rifleName,
      cartridgeName: current.cartridgeName,
      windAngleDeg: current.windAngleDeg,
      tempDisplay: current.tempDisplay,
      altDisplay: current.altDisplay,
      pressDisplay: current.pressDisplay,
      humidDisplay: current.humidDisplay,
      cartridgeInfoLine: current.cartridgeInfoLine,
      adjustment: current.adjustment,
      tableData: current.tableData,
      chartData: current.chartData,
      selectedPointInfo: info,
    ));
  }

  Future<void> updateWindDirection(double degrees) async {
    // ... делегує до shotProfileProvider
  }

  Future<void> updateWindSpeed(double rawMps) async {
    // ...
  }

  Future<void> updateLookAngle(double degrees) async {
    // ...
  }

  Future<void> updateTargetDistance(double meters) async {
    // ...
  }

  // --- Private builders ---

  HomeUiReady _buildReadyState({
    required profile,
    required settings,
    required UnitFormatter formatter,
    required BallisticsResult result,
  }) {
    // Вся логіка формування UI state з HitResult
    // Жодного flutter коду — тільки рядки і числа
    final traj = result.hitResult.trajectory;
    // ... будуємо adjustment, tableData, chartData
    throw UnimplementedError(); // placeholder
  }

  HomeChartPointInfo _buildPointInfo(ChartPoint point, UnitFormatter formatter) {
    return HomeChartPointInfo(
      distance: '${point.distanceM.toStringAsFixed(0)} ${formatter.distanceSymbol}',
      velocity: '${Velocity(point.velocityMps, Unit.mps).in_(formatter.velocitySymbol == 'm/s' ? Unit.mps : Unit.fps).toStringAsFixed(0)} ${formatter.velocitySymbol}',
      energy: '—', // TODO: потрібен energy у ChartPoint
      time: '—',
      height: '${point.heightCm.toStringAsFixed(1)} cm',
      drop: '—',
      windage: '—',
      mach: point.mach.toStringAsFixed(2),
    );
  }

  // Zero key (перенесено з calculation_provider)
  List<double> _buildZeroKey(profile, bool usePowderSens) {
    // ... точна копія _buildZeroKey з calculation_provider.dart
    throw UnimplementedError();
  }

  bool _listEquals(List<double>? a, List<double>? b) {
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final homeVmProvider = AsyncNotifierProvider<HomeViewModel, HomeUiState>(
  HomeViewModel.new,
);
```

### ConditionsViewModel

**`lib/viewmodels/conditions_vm.dart`**

```dart
// ЧИСТИЙ DART
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../formatting/unit_formatter.dart';
import '../providers/formatter_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../src/solver/unit.dart';
import '../src/solver/conditions.dart' as solver;

class ConditionsField {
  final String label;
  final double displayValue;    // вже в display unit
  final double rawValue;        // в storage unit (для збереження)
  final String symbol;
  final double displayMin;
  final double displayMax;
  final double displayStep;
  final int decimals;
  final InputField inputField;

  const ConditionsField({
    required this.label,
    required this.displayValue,
    required this.rawValue,
    required this.symbol,
    required this.displayMin,
    required this.displayMax,
    required this.displayStep,
    required this.decimals,
    required this.inputField,
  });
}

class ConditionsUiState {
  final ConditionsField temperature;
  final ConditionsField altitude;
  final ConditionsField humidity;
  final ConditionsField pressure;
  final ConditionsField? powderTemperature;  // null якщо не потрібно

  // Switches
  final bool powderSensOn;
  final bool useDiffPowderTemp;
  final bool coriolisOn;
  final bool derivationOn;

  // Readonly computed
  final String? mvAtPowderTemp;     // "888 m/s" або null
  final String? powderSensitivity;  // "2.00 %/15°C" або null

  const ConditionsUiState({
    required this.temperature,
    required this.altitude,
    required this.humidity,
    required this.pressure,
    this.powderTemperature,
    required this.powderSensOn,
    required this.useDiffPowderTemp,
    required this.coriolisOn,
    required this.derivationOn,
    this.mvAtPowderTemp,
    this.powderSensitivity,
  });
}

class ConditionsViewModel extends AsyncNotifier<ConditionsUiState> {
  @override
  Future<ConditionsUiState> build() async {
    final profile = ref.watch(shotProfileProvider).value;
    final settings = ref.watch(settingsProvider).value;
    final formatter = ref.watch(unitFormatterProvider);

    if (profile == null || settings == null) {
      return _emptyState(formatter, settings);
    }

    return _buildState(profile, settings, formatter);
  }

  Future<void> updateTemperature(double rawCelsius) async {
    await ref.read(shotProfileProvider.notifier).updateConditions(
      _mutateAtmo(tempC: rawCelsius),
    );
  }

  Future<void> updateAltitude(double rawMeters) async {
    await ref.read(shotProfileProvider.notifier).updateConditions(
      _mutateAtmo(altM: rawMeters),
    );
  }

  Future<void> updateHumidity(double rawPercent) async {
    await ref.read(shotProfileProvider.notifier).updateConditions(
      _mutateAtmo(humPct: rawPercent),
    );
  }

  Future<void> updatePressure(double rawHPa) async {
    await ref.read(shotProfileProvider.notifier).updateConditions(
      _mutateAtmo(pressHPa: rawHPa),
    );
  }

  Future<void> updatePowderTemp(double rawCelsius) async {
    await ref.read(shotProfileProvider.notifier).updateConditions(
      _mutateAtmo(powderTempC: rawCelsius),
    );
  }

  Future<void> setPowderSensitivity(bool value) async {
    await ref.read(settingsProvider.notifier).setSwitch('powderSensitivity', value);
  }

  Future<void> setDiffPowderTemp(bool value) async {
    await ref.read(settingsProvider.notifier).setSwitch('diffPowderTemperature', value);
  }

  Future<void> setCoriolis(bool value) async {
    await ref.read(settingsProvider.notifier).setSwitch('coriolis', value);
  }

  Future<void> setDerivation(bool value) async {
    await ref.read(settingsProvider.notifier).setSwitch('derivation', value);
  }

  // --- Private ---

  solver.Atmo _mutateAtmo({
    double? tempC,
    double? altM,
    double? humPct,
    double? pressHPa,
    double? powderTempC,
  }) {
    final profile = ref.read(shotProfileProvider).value!;
    final atmo = profile.conditions;
    final settings = ref.read(settingsProvider).value!;
    final newTempC = tempC ?? atmo.temperature.in_(Unit.celsius);
    final useDiffTemp = settings.enablePowderSensitivity &&
        settings.useDifferentPowderTemperature;

    return solver.Atmo(
      temperature: Temperature(newTempC, Unit.celsius),
      altitude: Distance(altM ?? atmo.altitude.in_(Unit.meter), Unit.meter),
      pressure: Pressure(pressHPa ?? atmo.pressure.in_(Unit.hPa), Unit.hPa),
      humidity: (humPct ?? atmo.humidity * 100) / 100,
      powderTemperature: Temperature(
        useDiffTemp ? (powderTempC ?? atmo.powderTemp.in_(Unit.celsius)) : newTempC,
        Unit.celsius,
      ),
    );
  }

  ConditionsUiState _buildState(profile, settings, UnitFormatter formatter) {
    // Вся логіка форматування — тут, не у Screen
    throw UnimplementedError(); // реалізувати
  }

  ConditionsUiState _emptyState(UnitFormatter formatter, settings) {
    throw UnimplementedError();
  }
}

final conditionsVmProvider =
    AsyncNotifierProvider<ConditionsViewModel, ConditionsUiState>(
  ConditionsViewModel.new,
);
```

### TablesViewModel

**`lib/viewmodels/tables_vm.dart`**

```dart
// ЧИСТИЙ DART
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ballistics_service.dart';
import '../formatting/unit_formatter.dart';
import '../providers/formatter_provider.dart';
import '../providers/service_providers.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../src/solver/unit.dart';
import 'shared/formatted_row.dart';

class TablesSpoilerData {
  final String rifleName;
  final String? caliber;
  final String? twist;
  final String? dragModel;
  final String? bc;
  final String? zeroMv;
  final String? currentMv;
  final String? zeroDist;
  final String? bulletLen;
  final String? bulletDiam;
  final String? bulletWeight;
  final String? formFactor;
  final String? sectionalDensity;
  final String? gyroStability;
  final String? temperature;
  final String? humidity;
  final String? pressure;
  final String? windSpeed;
  final String? windDir;

  const TablesSpoilerData({required this.rifleName, ...});
}

sealed class TablesUiState {
  const TablesUiState();
}

class TablesUiLoading extends TablesUiState { const TablesUiLoading(); }
class TablesUiEmpty extends TablesUiState { const TablesUiEmpty(); }

class TablesUiReady extends TablesUiState {
  final TablesSpoilerData spoiler;
  final FormattedTableData? zeroCrossings;
  final FormattedTableData mainTable;

  const TablesUiReady({
    required this.spoiler,
    this.zeroCrossings,
    required this.mainTable,
  });
}

class TablesUiError extends TablesUiState {
  final String message;
  const TablesUiError(this.message);
}

class TablesViewModel extends AsyncNotifier<TablesUiState> {
  double? _cachedZeroElevRad;
  List<double>? _lastZeroKey;

  @override
  Future<TablesUiState> build() async => const TablesUiLoading();

  Future<void> recalculate() async {
    final profile = ref.read(shotProfileProvider).value;
    final settings = ref.read(settingsProvider).value;
    final formatter = ref.read(unitFormatterProvider);

    if (profile == null || settings == null) {
      state = const AsyncData(TablesUiEmpty());
      return;
    }

    state = const AsyncData(TablesUiLoading());

    try {
      final cfg = settings.tableConfig;
      final opts = TableCalcOptions(
        startM: cfg.startM,
        endM: cfg.endM,
        stepM: cfg.stepM < 1.0 ? cfg.stepM : 1.0, // internal step
        usePowderSensitivity: settings.enablePowderSensitivity,
      );

      final result = await ref.read(ballisticsServiceProvider).calculateTable(
        profile,
        opts,
        cachedZeroElevRad: _cachedZeroElevRad,
      );

      _cachedZeroElevRad = result.zeroElevationRad;

      final uiState = _buildReadyState(
        profile: profile,
        settings: settings,
        formatter: formatter,
        result: result,
      );

      state = AsyncData(uiState);
    } catch (e, st) {
      state = AsyncData(TablesUiError(e.toString()));
    }
  }

  TablesUiReady _buildReadyState({...}) {
    // Форматуємо все тут — Screen тільки рендерить
    throw UnimplementedError();
  }
}

final tablesVmProvider =
    AsyncNotifierProvider<TablesViewModel, TablesUiState>(TablesViewModel.new);
```

---

## ФАЗА 3 — RecalcCoordinator (прибрати ефект доміно)

**`lib/providers/recalc_coordinator.dart`**

```dart
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../src/models/app_settings.dart';
import '../viewmodels/home_vm.dart';
import '../viewmodels/tables_vm.dart';

class RecalcCoordinator extends Notifier<void> {
  @override
  void build() {
    // Єдине місце де слухаємо зміни і тригеримо перерахунок
    ref.listen(shotProfileProvider, (_, next) {
      if (next.hasValue) _triggerAll();
    });

    ref.listen<AsyncValue<AppSettings>>(settingsProvider, (prev, next) {
      if (!next.hasValue) return;
      if (_needsRecalc(prev?.value, next.value!)) _triggerAll();
    });
  }

  /// Викликається з router/shell при активації вкладки
  void onTabActivated(int tabIndex) {
    if (tabIndex == 0) {
      ref.read(homeVmProvider.notifier).recalculate();
    }
    if (tabIndex == 2) {
      ref.read(tablesVmProvider.notifier).recalculate();
    }
  }

  void _triggerAll() {
    ref.read(homeVmProvider.notifier).recalculate();
    ref.read(tablesVmProvider.notifier).recalculate();
  }

  bool _needsRecalc(AppSettings? prev, AppSettings next) {
    if (prev == null) return true;
    return prev.enablePowderSensitivity != next.enablePowderSensitivity ||
        prev.useDifferentPowderTemperature != next.useDifferentPowderTemperature ||
        prev.chartDistanceStep != next.chartDistanceStep ||
        prev.tableConfig.stepM != next.tableConfig.stepM;
  }
}

final recalcCoordinatorProvider =
    NotifierProvider<RecalcCoordinator, void>(RecalcCoordinator.new);
```

### Зміни в `router.dart`

```dart
// Замінити в _ScaffoldWithNavState:

// БУЛО:
ref.listen(shotProfileProvider, (_, next) {
  if (next.hasValue) _markAndRecalc();
});
ref.listen<AsyncValue<AppSettings>>(settingsProvider, (prev, next) { ... });

// СТАЛО:
// Ініціалізуємо координатор (він сам підписується)
ref.watch(recalcCoordinatorProvider);

// В _onTabSelected:
void _onTabSelected(int i) {
  widget.shell.goBranch(i, initialLocation: true);
  ref.read(recalcCoordinatorProvider.notifier).onTabActivated(i);
}
```

---

## ФАЗА 4 — Оновлення Screens (видалити логіку з UI)

### Патерн для кожного Screen після рефакторингу

```dart
// Було (HomeScreen — 200+ рядків логіки у build()):
String dimStr(dynamic dim, Unit rawUnit, Unit dispUnit, {int dec = 0}) { ... }
final raw = (dim as dynamic).in_(rawUnit) as double;
final disp = (rawUnit(raw) as dynamic).in_(dispUnit) as double;

// Стало (HomeScreen — тільки UI):
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(homeVmProvider).value ?? const HomeUiLoading();

  return switch (state) {
    HomeUiLoading() => const Center(child: CircularProgressIndicator()),
    HomeUiError(:final message) => Center(child: Text(message)),
    HomeUiReady() => _HomeReadyView(state: state),
  };
}
```

### Зміни у `widgets/unit_value_field.dart`

Зараз `UnitValueField` сам рахує конвертацію. Після рефакторингу він приймає вже готові значення:

```dart
// Новий конструктор (більш простий):
class UnitValueField extends StatelessWidget {
  const UnitValueField({
    required this.label,
    required this.displayValue,  // вже відформатований рядок або double
    required this.symbol,
    required this.onChanged,     // повертає display value (VM конвертує в raw)
    this.icon,
  });
  // ...
  // Без FieldConstraints, без Unit, без конвертацій
}
```

### Зміни у `widgets/trajectory_table.dart`

```dart
// Було: TrajectoryTable(traj: traj, zeros: zeros, displayStepM: stepM, ...)
// + вся логіка форматування всередині

// Стало: TrajectoryTable приймає вже відформатовані дані з VM
class TrajectoryTable extends StatelessWidget {
  const TrajectoryTable({
    required this.tableData,     // FormattedTableData з ViewModel
    required this.spoilerData,   // TablesSpoilerData з ViewModel
  });
  // build() — тільки рендеринг, жодних конвертацій
}
```

---

## ФАЗА 5 — Cleanup

### Файли що ВИДАЛЯЮТЬСЯ

```
lib/helpers/dimension_converter.dart          ← замінено UnitFormatter
lib/providers/calculation_provider.dart       ← замінено BallisticsService + ViewModels
```

### Файли що СПРОЩУЮТЬСЯ до мінімуму

```
lib/providers/settings_provider.dart         ← залишається, без змін
lib/providers/shot_profile_provider.dart      ← залишається, без змін
lib/widgets/unit_value_field.dart             ← спрощується (без Unit/FC)
lib/widgets/trajectory_table.dart             ← спрощується (приймає FormattedTableData)
lib/widgets/home_chart_page.dart              ← прибрати конвертації
lib/widgets/home_table_page.dart              ← прибрати конвертації
lib/widgets/home_reticle_page.dart            ← прибрати конвертації
lib/screens/home_screen.dart                  ← прибрати всю логіку
lib/screens/conditions_screen.dart            ← прибрати всю логіку
lib/screens/tables_screen.dart                ← спрощується до мінімуму
lib/screens/shot_details_screen.dart          ← буде ShotDetailsViewModel
```

### `lib/src/models/field_constraints.dart`

`FC` залишається — але тільки для `UnitFormatterImpl` і `BallisticsServiceImpl`.
З UI він зникає повністю.

---

## Порядок виконання для Claude Code

```
1. ФАЗА 0 — UnitFormatter
   a) Створити lib/formatting/unit_formatter.dart
   b) Створити lib/formatting/unit_formatter_impl.dart
   c) Створити lib/providers/formatter_provider.dart
   d) Переконатись що компілюється
   e) НЕ видаляти dimension_converter.dart поки

2. ФАЗА 1 — BallisticsService
   a) Створити lib/domain/ballistics_service.dart
   b) Створити lib/services/ballistics_service_impl.dart
      — скопіювати _runTableCalculation і _runHomeCalculation БЕЗ ЗМІН
   c) Створити lib/providers/service_providers.dart
   d) Переконатись що компілюється

3. ФАЗА 2 — Shared data classes
   a) Створити lib/viewmodels/shared/adjustment_data.dart
   b) Створити lib/viewmodels/shared/chart_point.dart
   c) Створити lib/viewmodels/shared/formatted_row.dart

4. ФАЗА 2 — HomeViewModel
   a) Створити lib/viewmodels/home_vm.dart
   b) Реалізувати _buildReadyState повністю
   c) Підключити до homeVmProvider
   d) Переконатись що компілюється

5. ФАЗА 2 — ConditionsViewModel
   a) Створити lib/viewmodels/conditions_vm.dart
   b) Реалізувати _buildState повністю
   c) Переконатись що компілюється

6. ФАЗА 2 — TablesViewModel
   a) Створити lib/viewmodels/tables_vm.dart
   b) Реалізувати _buildReadyState повністю
   c) Переконатись що компілюється
   d) Написати юніттести для фази 2 — DONE (70 тестів: conditions=22, home=20, tables=28)

7. ФАЗА 3 — RecalcCoordinator — DONE
   a) Створити lib/providers/recalc_coordinator.dart — DONE
   b) Оновити router.dart — DONE
   c) Видалити ref.listen з _ScaffoldWithNavState — DONE

8. ФАЗА 4 — Оновити HomeScreen — DONE
   a) Прибрати всю логіку з home_screen.dart — DONE
   b) Підключити до homeVmProvider — DONE
   c) Прибрати всю логіку з home_reticle_page.dart — DONE
   d) Прибрати всю логіку з home_table_page.dart — DONE
   e) Прибрати всю логіку з home_chart_page.dart — DONE

9. ФАЗА 4 — Оновити ConditionsScreen — DONE
   a) Прибрати всю логіку з conditions_screen.dart — DONE
   b) Підключити до conditionsVmProvider — DONE

10. ФАЗА 4 — Оновити TablesScreen — DONE
    a) Прибрати всю логіку з tables_screen.dart — DONE
    b) Оновити trajectory_table.dart щоб приймав FormattedTableData — DONE
    c) Підключити до tablesVmProvider — DONE
    d) Видалити tableCalculationProvider з RecalcCoordinator — DONE
    e) Виджет-тести для фази 4 — DONE (54 тести: trajectory_table=20, home_widgets=24, tables_screen=10)

11. ФАЗА 5 — Cleanup
    a) Видалити lib/helpers/dimension_converter.dart
    b) Видалити lib/providers/calculation_provider.dart
    c) Перевірити що немає orphan імпортів
    d) flutter analyze — 0 errors
```

---

## Контракт: як Screen спілкується з ViewModel

```
Screen/Widget:
  - ref.watch(someVmProvider)           → читає стан (тільки sealed/data класи)
  - ref.read(someVmProvider.notifier)   → викликає методи (updateX, setY)
  - НІКОЛИ не викликає ref.read(shotProfileProvider) напряму
  - НІКОЛИ не викликає ref.read(settingsProvider) напряму
  - НІКОЛИ не робить конвертації одиниць

ViewModel:
  - Читає провайдери через ref.watch/read
  - Повертає sealed class з готовими рядками
  - НІКОЛИ не імпортує flutter/material.dart
  - НІКОЛИ не повертає Color, Widget, IconData

UnitFormatter:
  - Приймає Dimension або double
  - Повертає String або double
  - НІКОЛИ не знає про UI
  - Тестується через dart test без flutter

BallisticsService:
  - Приймає ShotProfile + options
  - Повертає BallisticsResult
  - НІКОЛИ не знає про UI
  - Тестується через dart test без flutter
```

---

## Тести (після рефакторингу)

```
test/
├── formatting/
│   └── unit_formatter_test.dart    ← dart test, без flutter
├── viewmodels/
│   ├── home_vm_test.dart           ← dart test, без flutter
│   ├── conditions_vm_test.dart
│   └── tables_vm_test.dart
└── services/
    └── ballistics_service_test.dart
```

Якщо тест вимагає `flutter test` замість `dart test` — десь протікла UI залежність.

---

## Чого НЕ робити під час рефакторингу

- Не переписувати `Unit`/`Dimension`/solver
- Не змінювати `ShotProfile`, `Rifle`, `Cartridge` та інші моделі
- Не чіпати `GoRouter`
- Не видаляти старий код поки новий не компілюється і не працює
- Не робити все одразу — одна фаза = один PR = одна перевірка
- Не додавати нові фічі під час рефакторингу

## Після рефакторингу

- Провести повторний аналіз коду, він має бути більш правильно і надійно структурований
відрефакторити дерево проекту - стратегія feature-first та feature-driven
(наприклад весь ui перенестив окрему теку)
- ffigen версія застаріла, трбе аоновити до ^20, але нова має проблеми з tyedef Enum які не генеруються як int
- окремі enums для init.dart з їх параметризацією в measurable або навіть взагалі прибрати дженерик, можливо він зайвий і використовувати експлісіт типи для надійності

- Повністю переписати MasterProject.md - з врахуванням змін зроблених під час рефакторингу, переписати специфікацію і оновити список не реалізованих і не працюючих речей

- За необхідності написати REFACTOING_PLAN_2.md


