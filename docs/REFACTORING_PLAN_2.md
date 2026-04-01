# REFACTORING_PLAN_2.md — Post-Refactoring Improvements

**Status:** Draft
**Prerequisite:** REFACTORING_PLAN.md (phases 0–5) — completed

---

## Table of Contents

1. [Feature-First Directory Restructure](#1-feature-first-directory-restructure)
2. [ShotDetailsViewModel — Legacy Provider Elimination](#2-shotdetailsviewmodel--legacy-provider-elimination)
3. [FFI Enum Wrappers](#3-ffi-enum-wrappers)
4. [ffigen Update](#4-ffigen-update)
5. [Execution Order](#5-execution-order)

---

## 1. Feature-First Directory Restructure

### 1.1 Problem

Current layout is **layer-first**: all screens in `screens/`, all widgets in `widgets/`, all providers in `providers/`. When working on a feature (e.g. Tables), files are scattered across 4+ directories. Feature-first groups related code together.

### 1.2 Current Structure

```
lib/
├── domain/                    # 1 file
├── formatting/                # 2 files
├── helpers/                   # 1 file
├── providers/                 # 8 files
├── screens/                   # 12 files
├── services/                  # 1 file
├── src/                       # models, solver, proto, a7p
├── storage/                   # 2 files
├── viewmodels/                # 3 VMs + shared/
├── widgets/                   # 14 files
├── main.dart
└── router.dart
```

### 1.3 Target Structure

```
lib/
├── features/
│   ├── home/
│   │   ├── home_screen.dart
│   │   ├── home_vm.dart
│   │   ├── widgets/
│   │   │   ├── home_chart_page.dart
│   │   │   ├── home_reticle_page.dart
│   │   │   ├── home_table_page.dart
│   │   │   ├── quick_actions_panel.dart
│   │   │   ├── side_control_block.dart
│   │   │   ├── trajectory_chart.dart
│   │   │   └── wind_indicator.dart
│   │   └── sub_screens/
│   │       ├── home_sub_screens.dart     # rifle/cart/sight stubs
│   │       └── shot_details_screen.dart
│   │
│   ├── conditions/
│   │   ├── conditions_screen.dart
│   │   ├── conditions_vm.dart
│   │   └── widgets/
│   │       ├── temperature_control.dart
│   │       └── unit_value_field.dart      # shared — see note below
│   │
│   ├── tables/
│   │   ├── tables_screen.dart
│   │   ├── tables_vm.dart
│   │   ├── tables_config_screen.dart      # was tables_sub_screens.dart
│   │   └── widgets/
│   │       └── trajectory_table.dart
│   │
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── settings_units_screen.dart
│   │   ├── settings_adjustment_screen.dart
│   │   └── widgets/
│   │       └── settings_helpers.dart
│   │
│   └── convertors/
│       └── convertor_screen.dart
│
├── shared/
│   ├── widgets/
│   │   ├── icon_value_button.dart
│   │   ├── section_header.dart
│   │   └── unit_value_field.dart          # used by conditions + home
│   ├── models/
│   │   ├── adjustment_data.dart           # was viewmodels/shared/
│   │   ├── chart_point.dart
│   │   └── formatted_row.dart
│   └── helpers/
│       └── is_desktop.dart
│
├── core/
│   ├── domain/
│   │   └── ballistics_service.dart
│   ├── services/
│   │   └── ballistics_service_impl.dart
│   ├── formatting/
│   │   ├── unit_formatter.dart
│   │   └── unit_formatter_impl.dart
│   ├── providers/
│   │   ├── formatter_provider.dart
│   │   ├── library_provider.dart
│   │   ├── recalc_coordinator.dart
│   │   ├── service_providers.dart
│   │   ├── settings_provider.dart
│   │   ├── shot_profile_provider.dart
│   │   └── storage_provider.dart
│   ├── storage/
│   │   ├── app_storage.dart
│   │   └── json_file_storage.dart
│   ├── models/                            # was src/models/
│   │   ├── _dim.dart
│   │   ├── app_settings.dart
│   │   ├── cartridge.dart
│   │   ├── field_constraints.dart
│   │   ├── projectile.dart
│   │   ├── rifle.dart
│   │   ├── seed_data.dart
│   │   ├── shot_profile.dart
│   │   ├── sight.dart
│   │   ├── table_config.dart
│   │   └── unit_settings.dart
│   ├── solver/                            # was src/solver/
│   │   ├── calculator.dart
│   │   ├── conditions.dart
│   │   ├── constants.dart
│   │   ├── drag_model.dart
│   │   ├── drag_tables.dart
│   │   ├── munition.dart
│   │   ├── shot.dart
│   │   ├── trajectory_data.dart
│   │   ├── unit.dart
│   │   ├── vector.dart
│   │   └── ffi/
│   │       ├── bclibc_bindings.g.dart
│   │       ├── bclibc_ffi.dart
│   │       └── bc_enums.dart              # Phase 3 — new
│   ├── a7p/                               # was src/a7p/
│   │   ├── a7p_parser.dart
│   │   └── a7p_validator.dart
│   └── proto/                             # was src/proto/ — auto-generated
│       ├── profedit.pb.dart
│       ├── profedit.pbenum.dart
│       └── profedit.pbjson.dart
│
├── main.dart
└── router.dart
```

### 1.4 Shared Widget Strategy

`unit_value_field.dart` is used by both `conditions_screen` and `home_screen` (via `quick_actions_panel`). Move to `shared/widgets/`. Same for `icon_value_button.dart` and `section_header.dart`.

`temperature_control.dart` is only used by `conditions_screen` — stays in `features/conditions/widgets/`.

### 1.5 Migration Rules

- Move files one feature at a time
- Update all imports after each feature move
- `flutter analyze` must pass after each move
- No logic changes — pure file moves + import updates
- Tests move in parallel: `test/viewmodels/home_vm_test.dart` → `test/features/home/home_vm_test.dart`

### 1.6 Migration Order

1. Create directory skeleton (`features/`, `shared/`, `core/`)
2. Move `src/models/` → `core/models/` (most imported, fix imports everywhere first)
3. Move `src/solver/` → `core/solver/`
4. Move `src/a7p/` → `core/a7p/`, `src/proto/` → `core/proto/`
5. Delete empty `src/`
6. Move `shared/` widgets + models (viewmodels/shared/ → shared/models/)
7. Move `core/` upper layers (providers, services, formatting, storage)
8. Move `features/settings/` (simplest feature, no VM)
9. Move `features/convertors/` (single file, no VM)
10. Move `features/conditions/`
11. Move `features/tables/`
12. Move `features/home/` (largest, move last)
13. Clean up empty old directories
14. Verify: `flutter analyze`, all tests pass

> **Note:** steps 2–5 (`src/` → `core/`) affect the most imports (~50+ files import from `src/`). Do these first so later moves don't need double-fixup. Use `git mv` + global find-replace on import paths.

---

## 2. ShotDetailsViewModel — Legacy Provider Elimination

### 2.1 Problem

`homeCalculationProvider` (`HomeCalculationNotifier`) exists only because `shot_details_screen.dart` reads raw `HitResult` and does inline unit conversions. This is the last screen not using the ViewModel pattern.

### 2.2 Solution

Create `ShotDetailsViewModel` following the same pattern as other VMs:
- Reads `shotProfileProvider`, `settingsProvider`, `ballisticsServiceProvider`, `unitFormatterProvider`
- Produces `ShotDetailsUiState` sealed class with formatted strings
- Screen becomes pure UI consumer

### 2.3 ShotDetailsUiState

```dart
sealed class ShotDetailsUiState {}
class ShotDetailsLoading extends ShotDetailsUiState {}
class ShotDetailsError extends ShotDetailsUiState { final String message; }
class ShotDetailsReady extends ShotDetailsUiState {
  // Velocity section
  final String currentMv;
  final String zeroMv;
  final String speedOfSound;
  final String velocityAtTarget;
  // Energy section
  final String energyAtMuzzle;
  final String energyAtTarget;
  // Stability section
  final String gyroscopicStability;  // "1.45" or "—"
  // Trajectory section
  final String shotDistance;
  final String heightAtTarget;
  final String maxHeightDistance;
  final String windage;
  final String timeToTarget;
}
```

### 2.4 After Completion

- Delete `lib/core/providers/home_calculation_provider.dart`
- Remove `homeCalculationProvider` from `recalc_coordinator.dart`
- Remove `homeCalculationProvider` override from `recalc_coordinator_test.dart`

---

## 3. FFI Enum Wrappers

### 3.1 Problem

FFI enums in `bclibc_bindings.g.dart` are raw `int` constants (e.g. `BCLIBCFFI_OK = 0`, `BC_TRAJ_FLAG_MACH = 4`). The Dart-side wrappers in `bclibc_ffi.dart` use strings and ad-hoc parsing. No type-safe Dart enums exist.

### 3.2 Current State

`bclibc_ffi.dart` defines value classes (`BcConfig`, `BcAtmosphere`, etc.) that map between Dart types and FFI structs. Error codes, trajectory flags, termination reasons, and interpolation keys are used as raw ints.

### 3.3 Proposal

Create typed Dart enums that wrap the generated int constants:

```dart
// lib/src/solver/ffi/bc_enums.dart

enum BcStatus {
  ok(BCLIBCFFI_OK),
  errSolverRuntime(BCLIBCFFI_ERR_SOLVER_RUNTIME),
  errOutOfRange(BCLIBCFFI_ERR_OUT_OF_RANGE),
  errZeroFinding(BCLIBCFFI_ERR_ZERO_FINDING),
  errInterception(BCLIBCFFI_ERR_INTERCEPTION),
  errGeneric(BCLIBCFFI_ERR_GENERIC);

  const BcStatus(this.value);
  final int value;

  static BcStatus fromValue(int v) =>
    values.firstWhere((e) => e.value == v, orElse: () => errGeneric);
}

enum BcTrajFlag {
  none(BC_TRAJ_FLAG_NONE),
  zeroUp(BC_TRAJ_FLAG_ZERO_UP),
  zeroDown(BC_TRAJ_FLAG_ZERO_DOWN),
  zero(BC_TRAJ_FLAG_ZERO),
  mach(BC_TRAJ_FLAG_MACH),
  range(BC_TRAJ_FLAG_RANGE),
  apex(BC_TRAJ_FLAG_APEX),
  all(BC_TRAJ_FLAG_ALL),
  mrt(BC_TRAJ_FLAG_MRT);

  const BcTrajFlag(this.value);
  final int value;
}

enum BcTerminationReason {
  noTerminate(BC_TERM_NO_TERMINATE),
  targetRangeReached(BC_TERM_TARGET_RANGE_REACHED),
  minimumVelocityReached(BC_TERM_MINIMUM_VELOCITY_REACHED),
  maximumDropReached(BC_TERM_MAXIMUM_DROP_REACHED),
  minimumAltitudeReached(BC_TERM_MINIMUM_ALTITUDE_REACHED),
  handlerRequestedStop(BC_TERM_HANDLER_REQUESTED_STOP);

  const BcTerminationReason(this.value);
  final int value;

  static BcTerminationReason fromValue(int v) =>
    values.firstWhere((e) => e.value == v, orElse: () => noTerminate);
}

enum BcInterpKey {
  time(BC_INTERP_KEY_TIME),
  mach(BC_INTERP_KEY_MACH),
  posX(BC_INTERP_KEY_POS_X),
  posY(BC_INTERP_KEY_POS_Y),
  posZ(BC_INTERP_KEY_POS_Z),
  velX(BC_INTERP_KEY_VEL_X),
  velY(BC_INTERP_KEY_VEL_Y),
  velZ(BC_INTERP_KEY_VEL_Z);

  const BcInterpKey(this.value);
  final int value;
}

enum BcIntegrationMethod {
  rk4(BC_INTEGRATION_RK4),
  euler(BC_INTEGRATION_EULER);

  const BcIntegrationMethod(this.value);
  final int value;
}
```

### 3.4 Migration

- Create `lib/core/solver/ffi/bc_enums.dart` (after Phase 1 moves `src/` → `core/`)
- Update `bclibc_ffi.dart` to use enums instead of raw ints
- Update `BcException` to use `BcStatus`
- Update `BcHitResult.terminationReason` to `BcTerminationReason`
- No external API changes — enums are internal to FFI layer

### 3.5 Note on Unit Generic — Strict Dimension Typing

**Проблема:** Dart сторона має один `Unit` enum (50 значень), `UnitCallable.call()` повертає `dynamic`, dispatch по ID ranges. Помилки типу `Unit.celsius(100).in_(Unit.meter)` ловляться тільки в рантаймі.

**Референс:** C++ сторона (`bclibc/unit.hpp`) вже реалізує type-safe підхід:

```cpp
// C++ — phantom DimTag + unit tag struct з factor/to_raw/from_raw
template<typename DimTag, typename Unit>
class Dimension { double _raw; ... };

template<typename Unit> using Distance    = Dimension<DistanceDimTag, Unit>;
template<typename Unit> using Velocity    = Dimension<VelocityDimTag, Unit>;
template<typename Unit> using Temperature = Dimension<TemperatureDimTag, Unit>;

// Compile-time safety:
Distance<Meter> d(100.0);
auto yd = d.to<Yard>();           // OK
// d.to<FPS>();                   // COMPILE ERROR — FPS is VelocityDimTag

// Arithmetic across units within same dimension:
Distance<Meter> sum = d + Distance<Yard>(50.0);  // OK, adds via raw
// Distance<Meter> x = d + Velocity<MPS>(10.0);  // COMPILE ERROR
```

**Dart mirror:** параметризувати `Dimension` другим type parameter `U` (unit enum):

```dart
// ═══ Крок 1: Окремі enum-и по вимірах (ID-сумісні з BCLIBC_Unit) ═══

enum DistanceUnit implements DimUnit {
  inch(10, 'inch', 1, 'inch', 1.0),
  foot(11, 'foot', 2, 'ft', 12.0),
  yard(12, 'yard', 1, 'yd', 36.0),
  meter(17, 'meter', 1, 'm', 1000.0 / 25.4),
  // ...
  ;
  const DistanceUnit(this.id, this.label, this.accuracy, this.symbol, this.factor);
  @override final int id;
  @override final String label;
  @override final int accuracy;
  @override final String symbol;
  final double factor;
}

enum VelocityUnit implements DimUnit { mps(60, ...), fps(62, ...), ... }
enum TemperatureUnit implements DimUnit { celsius(51, ...), fahrenheit(50, ...), ... }
// ... Angular, Pressure, Energy, Weight, Time

/// Спільний інтерфейс для всіх unit enum-ів (для серіалізації, UI)
abstract interface class DimUnit {
  int get id;
  String get label;
  int get accuracy;
  String get symbol;
}

// ═══ Крок 2: Dimension<T, U> — два type parameters ═══

abstract class Dimension<T extends Dimension<T, U>, U extends Enum> {
  late double _rawValue;
  final U _definedUnits;
  Dimension(double value, this._definedUnits) {
    _rawValue = toRaw(value, _definedUnits);
  }
  T _create(double value, U unit);       // тільки свій enum
  double in_(U unit);                   // тільки свій enum
  T to(U unit);                         // тільки свій enum
  double toRaw(double value, U unit);
  double fromRaw(double value, U unit);
  double get rawValue;
  U get units;
  Map<U, double> get conversionFactors;
  // ... решта як зараз, але U замість Unit
}

// ═══ Крок 3: Конкретні класи ═══

class Distance extends Dimension<Distance, DistanceUnit> {
  Distance(super.value, super.unit);

  static final _factors = {
    DistanceUnit.inch: 1.0,
    DistanceUnit.foot: 12.0,
    DistanceUnit.meter: 1000.0 / 25.4,
    // ...
  };

  @override
  Map<DistanceUnit, double> get conversionFactors => _factors;

  @override
  Distance create(double value, DistanceUnit unit) => Distance(value, unit);
}

class Temperature extends Dimension<Temperature, TemperatureUnit> {
  // affine override toRaw/fromRaw — як зараз, але switch по TemperatureUnit
}

// ═══ Compile-time safety ═══

Distance d = Distance(100, DistanceUnit.meter);
d.in_(DistanceUnit.yard);     // ✓ OK
d.in_(VelocityUnit.fps);      // ✗ COMPILE ERROR — VelocityUnit ≠ DistanceUnit

// FieldConstraints стає generic:
class FieldConstraints<U extends Enum> {
  final U rawUnit;
  final double minRaw, maxRaw, stepRaw;
  final int accuracy;
}
static const altitude = FieldConstraints<DistanceUnit>(
  rawUnit: DistanceUnit.meter, minRaw: -500, maxRaw: 15000, stepRaw: 10, accuracy: 0,
);
// altitude.rawUnit → DistanceUnit, не Unit

// UnitSettings — строго типізовані поля:
class UnitSettings {
  final DistanceUnit distance;
  final VelocityUnit velocity;
  final TemperatureUnit temperature;
  final AngularUnit angular;
  // ...
}
```

**Ключові відмінності Dart vs C++:**
- C++ використовує phantom `DimTag` + struct unit tags з `constexpr factor` → Dart використовує `Dimension<T, U>` де `U` це enum з полем `factor`
- C++ unit tags — окремі struct-и (`Meter`, `Foot`) → Dart — значення enum-у (`DistanceUnit.meter`, `.foot`)
- C++ `unit_from_enum<BCLIBC_Unit::Meter>::type` для FFI bridge → Dart не потребує (enum values мають `.id` що збігається з `BCLIBC_Unit`)
- Temperature: і C++ і Dart — affine `toRaw`/`fromRaw` без factor
- Sentinel units (`Unit.second` для dimensionless humidity/BC): замінити на `Dimensionless` enum або nullable `U?`

**Переваги:**
- Помилки конверсії ловляться компілятором, не рантаймом
- `UnitCallable.call()` і `as dynamic` зникають повністю
- Dart сторона стає дзеркалом C++ `unit.hpp` — єдина ментальна модель
- `FieldConstraints<U>` — неможливо передати неправильний тип unit
- ID enum values сумісні з `BCLIBC_Unit` — серіалізація через `int` id

**Трейдофи:**
- **Blast radius:** торкнеться solver, models, viewmodels, screens, tests — практично весь проект
- **`UnitSettings` серіалізація:** кожне поле свого типу, але спрощується через `.id` (int)
- **Crosscutting код:** `accuracyFor()` і подібні потребуватимуть або base interface, або окремі реалізації per dimension
- **Sentinel units:** `Unit.second` для dimensionless — потрібен `Dimensionless` тип або nullable

**Рішення:** Реалізувати як фазу 5, після завершення фаз 1–4. Пріоритет зростає якщо рантайм помилки unit mismatch стають проблемою.

---

## 4. ffigen Update

### 4.1 Current State

`ffigen: ^12.0.0` in `pubspec.yaml`. Current bindings (`bclibc_bindings.g.dart`) work correctly.

### 4.2 Target

`ffigen: ^20.0.0` — latest version with improved generation.

### 4.3 Known Issues

- ffigen ^20 has problems with `typedef enum` — generated as opaque types instead of `int`
- This affects all FFI enum constants (`BCLIBCFFIStatus`, `BCTrajFlag`, `BCTerminationReason`, etc.)
- Workaround: may need manual patching of generated file or config overrides

### 4.4 Strategy

1. Update `ffigen` to `^20.0.0` in `pubspec.yaml`
2. Regenerate bindings: `dart run ffigen`
3. Check if enum constants are still `int` — if not, apply workaround:
   - Option A: `ffigen` config `type-map` to force enum → int
   - Option B: Post-generation script to fix typedefs
   - Option C: Stay on ^12 until upstream fix
4. Verify all FFI tests pass
5. Verify `flutter analyze` passes

### 4.5 Risk

Low priority. Current ^12 works. Only update when the enum issue has an upstream fix or a clean workaround.

---

## 5. Execution Order

```
Phase   Task                                        Depends on   Risk
─────   ──────────────────────────────────────────   ──────────   ────
  1     Feature-first directory restructure          —            Low (pure moves)        ✅ DONE
  2     ShotDetailsViewModel                         1 (paths)    Low
  3     FFI enum wrappers (bc_enums.dart)            —            Low          ✅ DONE
  4     ffigen update to ^20                         3            Medium (enum issue) ✅ DONE
  5     Strict dimension typing (§3.5)               1            High (blast radius) ✅ DONE
  6     Safe JSON parsing loading                    —            not analyzed
```

### Phase 1 — Feature-first restructure ✅ DONE

**Result:** 72 files moved, all imports updated, 0 errors, 244 tests pass.
**Structure:** `lib/features/`, `lib/core/`, `lib/shared/`, `lib/main.dart`, `lib/router.dart`

### Phase 2 — ShotDetailsViewModel ✅ DONE

**Estimated scope:** 1 new file (VM) + 1 new test file + edit 2 existing files
**Verification:** `flutter test` + `flutter analyze`
**Risk:** Low — follows established pattern from REFACTORING_PLAN phases 2-4

### Phase 4 — ffigen update ✅ DONE

**Result:** Updated `ffigen: ^12.0.0` → `^20.0.0` (installed 20.1.1). Fixed `ffigen.yaml` output
path (`lib/src/` → `lib/core/`). Added `silence-enum-warning: true` for `BCIntegrationMethod`.
Bindings regenerated — ffigen ^20 now generates proper Dart `enum` types (with `.value` /
`fromValue()`) instead of `abstract class { static const int }`. Fixed downstream breakage in
`bclibc_ffi.dart`, `calculator.dart`, `ballistics_service_impl.dart`, `ffi_test.dart`.

### Phase 3 — FFI enum wrappers ✅ DONE (resolved by Phase 4)

**Result:** ffigen ^20 generates proper Dart enums directly — `BCLIBCFFIStatus`, `BCTrajFlag`,
`BCTerminationReason`, `BCBaseTrajInterpKey`, `BCIntegrationMethod` — each with `.value` and
`fromValue()`. No separate `bc_enums.dart` needed. Updated public API in `bclibc_ffi.dart`:
`BcHitResult.reason` → `BCTerminationReason`, `BcLibC.integrateAt` key → `BCBaseTrajInterpKey`,
`BcShotProps.method` → `BCIntegrationMethod`.

### Phase 5 — Strict dimension typing ✅ DONE (§3.5) 
> [!NOTE] IT IS MAYBE NOT REALLY NEEDED

**Goal:** Replace single `Unit` enum with per-dimension enums (`DistanceUnit`, `VelocityUnit`, etc.) and parameterize `Dimension<T, U>` — mirroring C++ `unit.hpp` architecture.
**Estimated scope:** ~30+ files (solver, models, viewmodels, screens, tests)
**Verification:** Full test suite + `flutter analyze`
**Risk:** High — touches entire codebase, but purely mechanical (type signature changes, no logic changes)
**Depends on:** Phase 1 (paths), benefits from Phase 3 (FFI enum alignment)

---

## Notes

- Each phase should be a separate commit/PR
- No new features during restructure
- `src/` merges into `core/` — all domain code lives under one roof
- `router.dart` stays at `lib/` root — it references all feature screens
- `main.dart` stays at `lib/` root
- After Phase 1, all imports use `package:eballistica/core/...` and `package:eballistica/features/...` prefixes — no more `src/`
