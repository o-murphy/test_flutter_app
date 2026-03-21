# eBallistica — Master Project Document

**Version:** 1.0  
**Status:** Working Document  
**Stack:** Flutter · Dart · Riverpod · FFI (bclibc C++)

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Global UI Rules](#2-global-ui-rules)
3. [Navigation Model](#3-navigation-model)
4. [Primary Screens](#4-primary-screens)
5. [Additional Screens & Components](#5-additional-screens--components)
6. [State Architecture](#6-state-architecture)
7. [Open Questions](#7-open-questions)
8. [Current Codebase Status](#8-current-codebase-status)
9. [Implementation Phases](#9-implementation-phases)
10. [Dependencies](#10-dependencies)
11. [Execution Order](#11-execution-order)

---

## 1. Product Overview

Mobile application for ballistic calculations. Provides a shooter with tools to calculate trajectory, scope adjustments, ballistic tables, and unit conversions.

All state is stored **locally** — no cloud synchronization planned.

---

## 2. Global UI Rules

### 2.1 Units of Measurement

All value displays and input fields use the units selected by the user in **Settings**. No hardcoded units anywhere in the UI.

### 2.2 Value Input

| Input type | Method |
|------------|--------|
| Ruler selectors (wind speed, look angle, target distance) | Touch drag **and** keyboard (both) |
| All other value selectors | Keyboard only |

### 2.3 Screen Headers

All screens **except Home** have a top header with:
- Screen title centered
- Back button (←) on the left

**Home** has no header.

---

## 3. Navigation Model

### 3.1 Primary Navigation

The app has **5 primary screens** switched via a **Bottom Navigation Bar**:

| # | ID | Name | Description |
|---|----|------|-------------|
| 1 | `home` | Home | Current shot |
| 2 | `conditions` | Conditions | Environmental conditions |
| 3 | `tables` | Tables | Current shot trajectory table |
| 4 | `convertors` | Convertors | Unit converters |
| 5 | `settings` | Settings | App settings |

### 3.2 Stack Model

Each primary screen has its **own independent navigation stack**. Sub-screens are pushed onto the stack of the screen that opened them.

**The Bottom Navigation Bar is always visible** — including inside any sub-screen. Tapping a nav bar item:
- Clears the entire current stack
- Navigates to the selected primary screen (or returns to it if already active)

### 3.3 Stacks per Screen

| Primary screen | Sub-screen stack |
|----------------|-----------------|
| **Home** | → Rifle Selection → (Sight / Cartridge / Library / Create) |
| **Home** | → Projectile Selection → (Library / Create) |
| **Home** | → Shot Details (Info screen) |
| **Settings** | → Units of Measurement |
| **Tables** | → Table Configuration |
| **Convertors** | → Convertor Screen (individual converter) |

### 3.4 Back Button Behavior

| Situation | Action |
|-----------|--------|
| Inside a sub-screen | Pop stack → previous screen |
| On a primary screen (not Home) | Navigate to **Home** |
| Tap on nav bar | Clears entire stack → navigates to selected primary screen |

### 3.5 GoRouter Route Map

```
/ (ShellRoute — bottom nav always visible)
├── /home
│   ├── /home/rifle-select
│   │   ├── /home/rifle-select/rifle-edit
│   │   ├── /home/rifle-select/sight-select
│   │   └── /home/rifle-select/cartridge
│   │       └── /home/rifle-select/cartridge/edit
│   ├── /home/projectile-select
│   │   └── /home/projectile-select/edit
│   └── /home/shot-details
├── /conditions
├── /tables
│   └── /tables/configure
├── /convertors
│   └── /convertors/:type
└── /settings
    └── /settings/units
```

---

## 4. Primary Screens

---

### 4.1 Home Screen

> **Purpose:** Main working screen. Displays current shot parameters and calculated data.

The screen is split vertically into **two blocks**:

```
┌──────────────────────────┐
│   Current Shot Props     │  (top ~55%)
├──────────────────────────┤
│   Current Shot Data      │  (bottom, 3 pages)
└──────────────────────────┘
```

#### 4.1.1 Block: Current Shot Props

Control panel for shot parameters.

**Selectors:**

| Element | Action |
|---------|--------|
| Rifle selection button | Opens Rifle Selection screen (stack push) |
| Projectile selection button | Opens Projectile Selection screen (stack push) |

**Navigation buttons:**

| Element | Action |
|---------|--------|
| Shot details button | Pushes Info screen |
| New note button | Creates a note for the shot |
| Help button | Shows all-in-one help overlay |
| More button | Pushes Tools screen |

**Read-only indicators** (values from Conditions screen):

| Element | Value |
|---------|-------|
| Temperature sign | Current temperature |
| Altitude sign | Current altitude |
| Humidity sign | Current humidity |
| Pressure sign | Current pressure |

**Wind Direction Wheel:** Interactive element for selecting wind direction. Displays the current set direction.

**Quick action buttons** (each opens a ruler-like selector overlay):

| Button | Parameter |
|--------|-----------|
| Wind speed | Wind velocity |
| Look angle | Shot inclination angle |
| Target distance | Distance to target |

#### 4.1.2 Block: Current Shot Data — 3 Pages

Switched by swipe or tabs.

**Page 1: Reticle + Adjustments**

```
┌─────────────────────────────┐
│  [small reticle preview]    │  → tap → full Reticle screen
│                             │
│  ↑ 2.34 MIL   → 0.12 MIL   │
│  (multiple units shown)     │
└─────────────────────────────┘
```

Data source: `calculationProvider` → `HitResult.getAtDistance(targetDistance)` → `dropAngle`, `windageAngle` converted to selected adjustment units.

**Page 2: Table of Adjustments**

Table for distances closest to the target distance (±3 rows).

| Column | Content |
|--------|---------|
| Distance | Range |
| Drop | Bullet drop |
| Adjustment | Scope correction |
| Velocity | Bullet speed |
| Time of flight | Flight time |
| Energy | Kinetic energy |

**Page 3: Trajectory Chart**

Vertical trajectory curve. Tap/drag on curve shows details for the selected point.

---

### 4.2 Conditions Screen

> **Purpose:** Input and editing of environmental parameters.

**Input fields** (keyboard input, units from Settings):

| Parameter | Type |
|-----------|------|
| Temperature | Numeric input with units |
| Altitude | Numeric input with units |
| Humidity | Numeric input, % |
| Pressure | Numeric input with units |

**Switches:**

| Switch | Description |
|--------|-------------|
| Coriolis effect | Account for Coriolis effect |
| Powder temperature sensitivity | Charge temperature dependency |
| Derivation | Bullet spin drift |
| Aerodynamic jump | Aerodynamic jump effect |
| Pressure depends on altitude | Auto-calculate pressure from altitude |

---

### 4.3 Tables Screen

> **Purpose:** Full trajectory table for the current shot.

| Element | Description |
|---------|-------------|
| **Spoiler / accordion** | Collapsible panel with details: rifle, bullet, sight, atmospheric conditions |
| **Zero crossing table** | Table of zero crossing points |
| **Full trajectory table** | Complete trajectory table for all distances |
| **Configure button** | Pushes Table Configuration screen |
| **Export / Share button** | Exports table via share sheet (PDF or HTML, TBD) |

---

### 4.4 Convertors Screen

> **Purpose:** Collection of unit converters.

**Layout:** 2-column scrollable grid. Each tile — square card with rounded corners:
- Large icon centered
- Converter name below
- Tap → pushes Convertor Screen onto Convertors stack

**Converters (8 total):**

| # | route type | Name | Icon |
|---|------------|------|------|
| 1 | `target-distance` | Target Distance | — |
| 2 | `velocity` | Velocity | — |
| 3 | `length` | Length | Ruler |
| 4 | `weight` | Weight | Scales |
| 5 | `pressure` | Pressure | Gauge |
| 6 | `temperature` | Temperature | Thermometer |
| 7 | `mil-moa` | MIL and MOA at Distance | MIL/MOA text + ruler |
| 8 | `torque` | Torque | Screwdriver |

---

### 4.5 Settings Screen

> **Purpose:** Global app settings.

| Section | Content |
|---------|---------|
| **Language** | Interface language |
| **Units** | Pushes Units screen (list of categories with selectors) |
| **Theme** | Light / Dark / System |
| **Adjustment units** | Display units for scope corrections (MOA, MIL, click, etc.) |
| **Table step** | Distance step for trajectory tables |
| **Switches** | Additional options (full list TBD) |
| **Data** | Import / Export app state and config (local backup, ZIP archive — no cloud) |
| **About** | Version, license, external links |

---

## 5. Additional Screens & Components

---

### 5.1 Info Screen

> Opened from **Shot details** button on Home.

Full read-only list of all current shot parameters (`ShotProfile`). No editing.

---

### 5.2 Reticle Screen

> Opened from the small reticle preview on Home → Page 1.

Full-screen display of the scope reticle with calculated adjustments overlaid. Details TBD.

---

### 5.3 Tools Screen

> Opened from **More** button on Home.

Additional shot setup tools. Contains at minimum three ruler-like selectors:

| Tool | Description |
|------|-------------|
| Wind speed selector | Ruler-based wind speed selection |
| Look angle selector | Ruler-based inclination angle selection |
| Target distance selector | Ruler-based target distance selection |

---

### 5.4 Help Overlay

> Opened from **Help** button on Home.

All-in-one overlay that **simultaneously highlights all** key UI elements with short labels. Not a step-by-step tour — everything shown at once.

Implementation: `Stack` + positioned coach mark widgets over `HomeScreen`.

---

### 5.5 Ruler-like Selector (reusable component)

`lib/widgets/ruler_selector.dart` — reusable overlay component for numeric value selection.

Used for: wind speed, look angle, target distance.

- Displayed as a **vertical** ruler (touch scroll)
- Two input methods: **touch drag** on the ruler and **direct keyboard input**
- Shows current value and units

---

### 5.6 Units Screen

> Opened from **Settings → Units**.

List of unit categories. Each category has an inline selector (radio / segmented control) for choosing the specific unit.

Categories: distance, velocity, weight, temperature, pressure, angular adjustment units, energy, time, etc.

---

### 5.7 Rifle Selection Screen

> Opened from **Rifle selection** button on Home.

| Element | Description |
|---------|-------------|
| Library list | Select existing rifle |
| Create manually button | Pushes Rifle Edit screen |

After selecting a rifle, also available in the same flow:

| Element | Description |
|---------|-------------|
| Sight selection | Select or create a sight for the rifle |
| Cartridge button | Pushes Cartridge screen |

---

### 5.8 Projectile Selection Screen

> Opened from **Projectile selection** button on Home.

| Element | Description |
|---------|-------------|
| Library list | Select existing projectile |
| Create manually button | Pushes Projectile Edit screen |

---

### 5.9 Cartridge Screen

> Opened from the cartridge button inside Rifle Selection Screen.

Three actions on one screen:

| Element | Description |
|---------|-------------|
| Select from library | Replace current cartridge |
| Create manually | Push Cartridge Edit screen |
| Current cartridge settings | Edit parameters of the already selected cartridge |

---

### 5.10 Table Configuration Screen

> Opened from **Configure** button on Tables screen.

Configure visible columns and distance step for the trajectory table. Saved in `AppSettings`.

---

### 5.11 Convertor Screen

> Opened from any tile on Convertors screen.

Two input fields with keyboard + unit labels. Real-time recalculation using the existing `Unit`/`Dimension` system.

---

## 6. State Architecture

### 6.1 Layer Diagram

```
┌─────────────────────────────────────────┐
│           UI (screens / widgets)         │
│    reads UnitSettings via Riverpod       │
│    passes explicit Unit to domain        │
├─────────────────────────────────────────┤
│           Riverpod providers             │
│  ShotProfileNotifier · SettingsNotifier  │
│  LibraryNotifier · CalculationNotifier   │
├─────────────────────────────────────────┤
│           Domain models                  │
│  Rifle · Sight · Cartridge · Projectile  │
│  Shot · Atmo · Wind · HitResult          │
│  (NO global unit state — explicit Unit)  │
├─────────────────────────────────────────┤
│           Infrastructure                 │
│  JsonFileStorage · ProfileSerializer     │
│  Calculator (FFI mapper)                 │
├─────────────────────────────────────────┤
│              FFI / C++                   │
│         bclibc ballistics engine         │
└─────────────────────────────────────────┘
```

### 6.2 Unit System Approach

**`PreferredUnits` (existing static class) is removed entirely from the domain.**

Domain classes (`Weapon`, `Ammo`, `Atmo`, `Wind`) receive **explicit `Unit` parameters** in their constructors. No global unit state in the domain layer.

`UnitSettings` is a UI-only immutable value class, managed by `SettingsNotifier` and accessed via `unitSettingsProvider`. The domain never sees it.

### 6.3 Domain Models

#### `UnitSettings` — `lib/src/models/unit_settings.dart`

UI-only immutable class, replaces `PreferredUnits`:

```dart
class UnitSettings {
  final Unit angular;
  final Unit distance;
  final Unit velocity;
  final Unit pressure;
  final Unit temperature;
  final Unit diameter;
  final Unit length;
  final Unit weight;
  final Unit adjustment;
  final Unit drop;
  final Unit energy;
  final Unit ogw;
  final Unit sightHeight;
  final Unit twist;
  final Unit time;

  const UnitSettings({ /* all fields with metric defaults */ });

  UnitSettings copyWith({...});
  Map<String, dynamic> toJson();
  factory UnitSettings.fromJson(Map<String, dynamic> json);
}
```

#### `AppSettings` — `lib/src/models/app_settings.dart`

```dart
class AppSettings {
  final UnitSettings units;
  final String       languageCode;            // 'uk', 'en'
  final ThemeMode    themeMode;               // system / light / dark
  final double       tableDistanceStep;       // in units.distance
  final bool         enableCoriolis;
  final bool         enablePowderSensitivity;
  final bool         enableDerivation;
  final bool         enableAerodynamicJump;
  final bool         pressureDependsOnAltitude;

  const AppSettings({ /* defaults */ });
  AppSettings copyWith({...});
  Map<String, dynamic> toJson();
  factory AppSettings.fromJson(Map<String, dynamic> json);
}
```

#### `Rifle` — `lib/src/models/rifle.dart`

```dart
class Rifle {
  final String   id;           // UUID
  final String   name;
  final String?  description;
  final Weapon   weapon;       // existing class — sight height, twist, zeroElevation
  final String?  notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson();
  factory Rifle.fromJson(Map<String, dynamic> json);
}
```

#### `Sight` — `lib/src/models/sight.dart`

```dart
class Sight {
  final String    id;
  final String    name;
  final String?   manufacturer;
  final Angular   zeroElevation;
  final Distance  sightHeight;
  final String?   notes;

  Map<String, dynamic> toJson();
  factory Sight.fromJson(Map<String, dynamic> json);
}
```

#### `Projectile` — `lib/src/models/projectile.dart`

```dart
class Projectile {
  final String    id;
  final String    name;
  final String?   manufacturer;
  final DragModel dm;
  final String?   notes;

  Map<String, dynamic> toJson();
  factory Projectile.fromJson(Map<String, dynamic> json);
}
```

#### `Cartridge` — `lib/src/models/cartridge.dart`

```dart
class Cartridge {
  final String      id;
  final String      name;
  final Projectile  projectile;
  final Velocity    mv;
  final Temperature powderTemp;
  final double      tempModifier;
  final bool        usePowderSensitivity;
  final String?     notes;

  Ammo toAmmo();   // converts to existing Ammo for Calculator
  Map<String, dynamic> toJson();
  factory Cartridge.fromJson(Map<String, dynamic> json);
}
```

#### `ShotProfile` — `lib/src/models/shot_profile.dart`

```dart
class ShotProfile {
  final String     id;
  final String     name;
  final Rifle      rifle;
  final Sight      sight;
  final Cartridge  cartridge;
  final Atmo       conditions;
  final List<Wind> winds;
  final Angular    lookAngle;
  final double?    latitudeDeg;
  final double?    azimuthDeg;

  Shot toShot();   // converts to existing Shot for Calculator
  Map<String, dynamic> toJson();
  factory ShotProfile.fromJson(Map<String, dynamic> json);
}
```

**Serialization rule for `Dimension` types:** store as `{"value": 9.0, "unit": "inch"}`.

### 6.4 Riverpod Providers

#### `lib/providers/settings_provider.dart`

```dart
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return await ref.read(appStorageProvider).loadSettings()
        ?? const AppSettings();
  }

  Future<void> setUnit(String key, Unit unit) async { ... }
  Future<void> setThemeMode(ThemeMode mode) async { ... }
  Future<void> setLanguage(String code) async { ... }
  Future<void> setSwitch(String key, bool value) async { ... }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// Synchronous access — returns defaults while loading
final unitSettingsProvider = Provider<UnitSettings>((ref) {
  return ref.watch(settingsProvider).valueOrNull?.units
      ?? const UnitSettings();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).valueOrNull?.themeMode
      ?? ThemeMode.system;
});
```

#### `lib/providers/shot_profile_provider.dart`

```dart
class ShotProfileNotifier extends AsyncNotifier<ShotProfile> {
  @override
  Future<ShotProfile> build(); // loads from storage

  Future<void> selectRifle(Rifle r);
  Future<void> selectSight(Sight s);
  Future<void> selectCartridge(Cartridge c);
  Future<void> updateConditions(Atmo atmo);
  Future<void> updateWinds(List<Wind> winds);
  Future<void> updateLookAngle(Angular angle);
  Future<void> updateTargetDistance(Distance d);
  Future<void> loadFromFile(String path);   // import individual profile
}

final shotProfileProvider =
    AsyncNotifierProvider<ShotProfileNotifier, ShotProfile>(ShotProfileNotifier.new);
```

#### `lib/providers/library_provider.dart`

```dart
final rifleLibraryProvider =
    AsyncNotifierProvider<RifleLibraryNotifier, List<Rifle>>(...);
final cartridgeLibraryProvider = ...;
final sightLibraryProvider = ...;
```

#### `lib/providers/calculation_provider.dart`

```dart
// Reactive calculation — recalculates only when profile changes
// Runs Calculator in an isolate via compute()
// Caches the last HitResult
final calculationProvider = FutureProvider<HitResult?>((ref) async {
  final profile = ref.watch(shotProfileProvider).valueOrNull;
  if (profile == null) return null;
  return compute(_runCalculation, profile);
});
```

### 6.5 Storage

#### Interface — `lib/storage/app_storage.dart`

```dart
abstract interface class AppStorage {
  Future<AppSettings?> loadSettings();
  Future<void> saveSettings(AppSettings s);

  Future<ShotProfile?> loadCurrentProfile();
  Future<void> saveCurrentProfile(ShotProfile p);

  Future<List<Rifle>> loadRifles();
  Future<void> saveRifle(Rifle r);
  Future<void> deleteRifle(String id);

  Future<List<Cartridge>> loadCartridges();
  Future<void> saveCartridge(Cartridge c);
  Future<void> deleteCartridge(String id);

  Future<List<Sight>> loadSights();
  Future<void> saveSight(Sight s);
  Future<void> deleteSight(String id);

  Future<Map<String, dynamic>> exportAll();
  Future<void> importAll(Map<String, dynamic> data);
}
```

#### First implementation — `JsonFileStorage`

Simple implementation using `dart:io` + JSON files in app documents directory. Export archive structure:

```
eballistica_backup.zip
├── settings.json
├── profile.json
├── rifles.json
├── cartridges.json
└── sights.json
```

Isar may be added later as an alternative implementation behind the same interface — no domain changes required.

---

## 7. Open Questions

| # | Question | Status |
|---|----------|--------|
| 1 | Storage engine: Isar / Hive / JSON files? | ⏳ JSON first, Isar later maybe |
| 2 | Table export format: PDF or HTML? | ⏳ TBD |
| 3 | Reticle screen — static display or interactive? | ⏳ TBD |
| 4 | Full list of switches in Settings | ⏳ TBD |
| 5 | Localizations: UK + EN only or more? | ⏳ TBD |
| 6 | Metronome in QuickActionsPanel — what is it, how does it work? | ⏳ TBD |

---

## 8. Current Codebase Status

### 8.1 Already Implemented ✅

| File | Contents |
|------|----------|
| `src/unit.dart` | Full unit system: `Unit` enum, `Dimension`, all typed classes (`Angular`, `Distance`, `Velocity`, `Pressure`, `Temperature`, `Weight`, `Energy`, `Time`), `PreferredUnits` **(to be removed in Phase 2)** |
| `src/conditions.dart` | `Atmo`, `Vacuum`, `Wind`, `Coriolis` |
| `src/munition.dart` | `Weapon`, `Ammo` (no id/name yet) |
| `src/drag_model.dart` | `DragModel`, `BCPoint`, `createDragModelMultiBC` |
| `src/drag_tables.dart` | Standard tables G1, G7, G2, G5, G6, G8, GI, GS, RA4 |
| `src/shot.dart` | `Shot` with full ballistic geometry |
| `src/trajectory_data.dart` | `TrajectoryData`, `HitResult`, `TrajFlag` |
| `src/calculator.dart` | `Calculator` — maps `Shot` → `BcShotProps` → FFI → `HitResult` |
| `src/constants.dart` | `BallisticConstants` |
| `src/vector.dart` | `Vector` |
| `src/ffi/bclibc_ffi.dart` | Dart wrapper over C FFI: `BcLibC`, all value types |
| `src/ffi/bclibc_bindings.g.dart` | Auto-generated FFI bindings |
| `screens/home_screen.dart` | Top block (stateless), bottom block — stubs |
| `screens/tables_screen.dart` | Working calculation and display (hardcoded params) |
| `widgets/wind_indicator.dart` | `WindIndicator` — interactive wind direction wheel |
| `widgets/side_control_block.dart` | `SideControlBlock` |
| `widgets/quick_actions_panel.dart` | `QuickActionsPanel` |
| `widgets/trajectory_chart.dart` | `TrajectoryChart` (CustomPainter) |
| `widgets/trajectory_table.dart` | `TrajectoryTable` |
| `main.dart` | `ProviderScope`, bottom nav (index setState — to be replaced), `window_manager` |

### 8.2 Issues to Resolve ⚠️

| Issue | Where | Impact |
|-------|-------|--------|
| `PreferredUnits` — global static mutable | `unit.dart` | Not reactive — **removed entirely in Phase 2** |
| `Weapon`/`Ammo` without id/name | `munition.dart` | Cannot store in library |
| Hardcoded calculation parameters | `tables_screen.dart` | Temporary — replace with provider |
| Navigation via `setState` index | `main.dart` | No stack support — replace with GoRouter |
| No persistence | — | Storage not connected |

---

## 9. Implementation Phases

---

### Phase 1 — Library Domain Models

> **Goal:** Add named library entities on top of existing ballistic classes.  
> **Do not touch:** `Weapon`, `Ammo`, `Shot`, `Calculator` — only add wrappers.

**Tasks:**
1. Create `lib/src/models/rifle.dart` — `Rifle` with id, name, `Weapon`, serialization
2. Create `lib/src/models/sight.dart` — `Sight` with id, name, `Angular`/`Distance`, serialization
3. Create `lib/src/models/projectile.dart` — `Projectile` with id, name, `DragModel`, serialization
4. Create `lib/src/models/cartridge.dart` — `Cartridge` with `toAmmo()`, serialization
5. Create `lib/src/models/shot_profile.dart` — `ShotProfile` with `toShot()`, serialization
6. Serialization convention for `Dimension` types: `{"value": 9.0, "unit": "inch"}`

---

### Phase 2 — Remove `PreferredUnits`, Add Reactive `UnitSettings`

> **Goal:** Completely remove `PreferredUnits` from the domain. Domain receives explicit `Unit` everywhere. UI reads units via Riverpod.  
> **Approach C:** `PreferredUnits` is a UI-only concept. Domain classes have zero dependency on any global unit state.

**2.1 What to remove from `unit.dart`:**
- Delete `abstract final class PreferredUnits` entirely — all static fields, setters, `restoreDefaults()`, `set()`, `info`
- Keep: `Unit` enum, `Dimension`, all typed dimension classes — they are clean

**2.2 Refactor domain constructors:**

```dart
// Before — implicit dependency on global state
class Weapon {
  Weapon({Object? sightHeight})
    : sightHeight = PreferredUnits.sightHeight(sightHeight ?? 0);
}

// After — explicit Unit, no global state
class Weapon {
  final Distance sightHeight;
  final Distance twist;
  final Angular  zeroElevation;

  Weapon({
    double sightHeight       = 0.0,
    Unit   sightHeightUnit   = Unit.inch,
    double twist             = 0.0,
    Unit   twistUnit         = Unit.inch,
    double zeroElevation     = 0.0,
    Unit   zeroElevationUnit = Unit.radian,
  })  : sightHeight   = Distance(sightHeight, sightHeightUnit),
        twist         = Distance(twist, twistUnit),
        zeroElevation = Angular(zeroElevation, zeroElevationUnit);
}
```

Same for `Ammo`, `Atmo`, `Wind`. Typed objects (`Distance`, `Velocity` etc.) are still accepted directly.

**2.3 Tasks:**
1. Write `UnitSettings` — `copyWith`, `toJson`, `fromJson`
2. Write `AppSettings` — serialization, all switches
3. Refactor `Weapon` — explicit Unit params, remove `PreferredUnits`
4. Refactor `Ammo` — same
5. Refactor `Atmo` — same
6. Refactor `Wind` — same
7. Delete `PreferredUnits` from `unit.dart`
8. Write `SettingsNotifier`, `unitSettingsProvider`, `themeModeProvider`
9. Wire theme in `MyApp` via `themeModeProvider`
10. Verify `tables_screen.dart` and `calculator.dart` still compile

**2.4 Usage in UI:**

```dart
class ConditionsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitSettingsProvider);

    // Format for display — domain stores rawValue, UI converts
    final tempStr = atmo.temperature
        .in_(units.temperature)
        .toStringAsFixed(units.temperature.accuracy);

    // Create domain object — explicit units from UI state
    final newAtmo = Atmo(
      altitude:        altValue,
      altitudeUnit:    units.distance,
      temperature:     tempValue,
      temperatureUnit: units.temperature,
    );
  }
}
```

**2.5 `Calculator` — no changes needed.** It receives a ready `Shot` from `ShotProfileNotifier` where all values are already typed. The FFI mapper calls `.in_(Unit.foot)` / `.in_(Unit.fps)` explicitly — already the case.

---

### Phase 3 — Storage

> **Goal:** Single local storage. Start with JSON files. Isar can be swapped in later without touching the interface or domain.

**Tasks:**
1. Define `AppStorage` interface (`lib/storage/app_storage.dart`)
2. Implement `JsonFileStorage` using `dart:io` + `path_provider`
3. Register `appStorageProvider` in Riverpod
4. Export archive as ZIP with 5 JSON files via `archive` package

---

### Phase 4 — Riverpod Providers

**Tasks:**
1. `RifleLibraryNotifier` — CRUD over `AppStorage`
2. `CartridgeLibraryNotifier` — same
3. `SightLibraryNotifier` — same
4. `ShotProfileNotifier` — load/save, all `select*` and `update*` methods, `loadFromFile`
5. `calculationProvider` — reactive `FutureProvider`, runs `Calculator` in isolate via `compute()`, caches last `HitResult`

---

### Phase 5 — Navigation (GoRouter)

**Tasks:**
1. Add `go_router` dependency
2. Implement `ScaffoldWithNavBar` shell — bottom nav always visible
3. Define all routes per section 3.5
4. Implement nav bar tap behavior: `go()` to switch tabs (clears stack), `push()` for sub-screens
5. Replace current `setState` index navigation in `main.dart`
6. Wire `MaterialApp.router` with `themeModeProvider`

---

### Phase 6 — Home Screen (bottom block)

**Tasks:**
1. Connect top block to providers: rifle name, cartridge name, conditions indicators, wind, quick actions
2. **Page 1:** Reticle preview widget + adjustments in selected units from `calculationProvider`
3. **Page 2:** Adjustments table — ±3 distances around target distance
4. **Page 3:** Connect existing `TrajectoryChart` to `calculationProvider`, add tap-to-select-point

---

### Phase 7 — Conditions Screen

Connect to `ShotProfileNotifier.updateConditions()`. All fields — keyboard input in units from `unitSettingsProvider`. Switches — read/write `AppSettings` via `SettingsNotifier`.

---

### Phase 8 — Tables Screen

- Connect to `calculationProvider` (remove hardcoded calculation)
- Add spoiler with shot profile details
- Add zero crossing table
- Wire Configure button → `/tables/configure`
- Wire Export button → share sheet (PDF or HTML, TBD)

---

### Phase 9 — Convertors Screen

- Grid of 8 tiles, each pushes `/convertors/:type`
- Individual `ConvertorScreen`: two keyboard input fields, real-time conversion using `Unit`/`Dimension`

---

### Phase 10 — Settings Screen

- Language selector
- Units → `/settings/units` (list of categories, segmented selectors, reads/writes `unitSettingsProvider`)
- Theme → Light / Dark / System
- All switches from `AppSettings`
- Table distance step
- Import / Export (ZIP archive, 5 files)
- Version / License / Links

---

### Phase 11 — Rifle / Cartridge / Sight Selection Screens

- `RifleSelectionScreen` — searchable list from `rifleLibraryProvider`, FAB to create, tap to select + show sight/cartridge flow
- `RifleEditScreen` — form: name, sight height, twist, zero elevation, notes
- `SightSelectionScreen` — list from `sightLibraryProvider`
- `CartridgeScreen` — three sections: select / create / edit current
- `ProjectileSelectionScreen` — list from `cartridgeLibraryProvider`
- `CartridgeEditScreen` — full projectile + ammo parameters form

---

### Phase 12 — Additional Screens

- `InfoScreen` — read-only full `ShotProfile` display
- `ReticleScreen` — full-screen reticle with adjustments (details TBD)
- `TableConfigScreen` — column visibility + distance step, saved to `AppSettings`
- **Help Overlay** — `Stack` + positioned coach mark widgets, all-in-one
- **Ruler Selector** (`lib/widgets/ruler_selector.dart`) — vertical ruler overlay, touch drag + keyboard

---

### Phase 13 — Polish & Export

- Dark/light theme — basic already in `main.dart`
- Localization (ARB files, `flutter_localizations`)
- Table export — PDF or HTML via share sheet (TBD)
- Profile import from file via `file_picker`
- iOS bundling of C++ library

---

## 10. Dependencies

### Currently in use

```yaml
flutter_riverpod: # existing
window_manager:   # existing
ffi:              # existing
```

### To add

```yaml
go_router: ^14.0.0           # navigation
uuid: ^4.0.0                 # ID generation
path_provider: ^2.0.0        # app documents directory
archive: ^3.0.0              # ZIP for export
file_picker: ^8.0.0          # file import
share_plus: ^9.0.0           # share sheet for table export
flutter_localizations: sdk   # localization
intl: ^0.19.0                # formatting
```

### Optional (storage upgrade)

```yaml
isar: ^3.0.0                 # if Isar is chosen later
isar_flutter_libs: ^3.0.0
```

---

## 11. Execution Order

```
Phase 1  → Domain models (Rifle, Sight, Cartridge, ShotProfile + serialization)
Phase 2  → Remove PreferredUnits, add UnitSettings + SettingsNotifier
Phase 3  → JsonFileStorage
Phase 4  → All Riverpod providers (library, profile, calculation)
Phase 5  → GoRouter (navigation skeleton)
Phase 6  → Home Screen bottom block
Phase 7  → Conditions Screen
Phase 8  → Tables Screen (refactor)
Phase 9  → Convertors Screen
Phase 10 → Settings Screen + Units Screen
Phase 11 → Rifle / Cartridge / Sight Selection Screens
Phase 12 → Additional screens (Info, Reticle, Config, Help, Ruler)
Phase 13 → Polish, localization, export
```

---

*Document is updated as implementation progresses.*
