# eBallistica — Master Project Document

**Version:** 1.1
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
| All other value selectors | Keyboard only via dialog |

### 2.3 Screen Headers

All screens **except Home** have a top header with:
- Screen title centered
- Back button (←) on the left
- Optional action buttons on the right

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
| **Settings** | → Adjustment Display |
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
    ├── /settings/units
    └── /settings/adjustment
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
| New note button | Creates a note for the shot (stub → Phase 12) |
| Help button | Shows all-in-one help overlay (stub → Phase 12) |
| More button | Pushes Tools screen (stub → Phase 12) |

**Read-only indicators** (values from Conditions screen):

| Element | Value |
|---------|-------|
| Temperature sign | Current temperature |
| Altitude sign | Current altitude |
| Humidity sign | Current humidity |
| Pressure sign | Current pressure |

**Wind Direction Wheel:** Interactive element for selecting wind direction. Displays current direction. Double-tap resets to 0°.

**Quick action buttons** (each opens a ruler-like selector overlay):

| Button | Parameter |
|--------|-----------|
| Wind speed | Wind velocity |
| Look angle | Shot inclination angle |
| Target distance | Distance to target |

#### 4.1.2 Block: Current Shot Data — 3 Pages

Switched by swipe.

**Page 1: Reticle + Adjustments**

```
┌──────────────────────────────────────┐
│  [reticle placeholder]  │  ↑ 2.34   │
│                         │  MIL      │
│                         │  0.98 MOA │
│                         │  ─────────│
│                         │  → 0.12   │
│                         │  MIL      │
└──────────────────────────────────────┘
```

- Left half: rounded square placeholder for future reticle widget
- Right half: two rows (drop / windage), each showing adjustment value in multiple units (cm/100m, in/100yd, MOA, MIL, MRAD) based on Adjustment Display settings
- Data source: `calculationProvider` → `HitResult.getAtDistance(targetDistance)` → `dropAngle`, `windageAngle`

**Page 2: Adjustment Tables**

Vertically scrollable set of compact tables. Each table: header row with distances (target ± 2 steps), value row. Tables:

| Table | Unit |
|-------|------|
| Height | `units.drop` |
| Slant Height | `units.drop` |
| Drop angle | `units.adjustment` |
| Windage angle | `units.adjustment` |
| Velocity | `units.velocity` |
| Energy | `units.energy` |
| Time | seconds |

**Page 3: Trajectory Chart**

- Above chart: info grid with currently selected point values
  - Left column: Trajectory label, Velocity, Energy, Time
  - Right column: Height, Drop, Windage, Distance
- Chart: trajectory curve + velocity curve only (no barrel/sight lines)
- Default selected point: start of trajectory
- Tap on chart → highlights nearest point, updates info grid above

---

### 4.2 Conditions Screen

> **Purpose:** Input and editing of environmental parameters.

**Input fields** (units from `unitSettingsProvider`):

Layout per field: `[−]  value  unit  [+]` — the +/− buttons are adjacent to the value, not at the edges of the row. Tapping the value itself opens a keyboard dialog for direct numeric entry.

| Parameter | Unit |
|-----------|------|
| Temperature | `units.temperature` |
| Altitude | `units.distance` |
| Humidity | % |
| Pressure | `units.pressure` |

**Switches** (read/write `AppSettings` via `SettingsNotifier`):

| Switch | Note |
|--------|------|
| Coriolis effect | |
| Powder temperature sensitivity | |
| Derivation | |
| Aerodynamic jump | Always ON, control disabled (engine limitation) |
| Pressure depends on altitude | Always ON, control disabled (engine limitation) |

---

### 4.3 Tables Screen

> **Purpose:** Full trajectory table for the current shot.

Layout (top to bottom):

| Element | Description |
|---------|-------------|
| **Header** | Back button, "Tables" title, Configure + Export buttons |
| **Spoiler / accordion** | Collapsible panel: rifle, cartridge, sight, atmospheric conditions summary |
| **Zero crossing table** | Small table showing zero-crossing points (from `HitResult.zeros`) |
| **Full trajectory table** | Complete trajectory for all distances; zero-distance row highlighted |
| **Configure button** | Pushes `/tables/configure` |
| **Export / Share button** | Exports table via share sheet (PDF or HTML, TBD) |

---

### 4.4 Convertors Screen

> **Purpose:** Collection of unit converters. Sub-screens are placeholders for now.

**Layout:** 2-column scrollable grid. Each tile — square card with rounded corners, large icon, name below.

**Converters (8 total):**

| # | Route type | Name |
|---|------------|------|
| 1 | `target-distance` | Target Distance |
| 2 | `velocity` | Velocity |
| 3 | `length` | Length |
| 4 | `weight` | Weight |
| 5 | `pressure` | Pressure |
| 6 | `temperature` | Temperature |
| 7 | `mil-moa` | MIL / MOA at Distance |
| 8 | `torque` | Torque |

---

### 4.5 Settings Screen

> **Purpose:** Global app settings.

| Section | Element | Status |
|---------|---------|--------|
| **Language** | Tap → dialog to select language | ⏳ dialog pending |
| **Appearance** | Theme — SegmentedButton (System/Light/Dark) | ✅ |
| **Appearance** | Units of Measurement → `/settings/units` | ⏳ screen pending |
| **Ballistics** | Adjustment Display → `/settings/adjustment` | ⏳ screen pending |
| **Ballistics** | Subsonic transition switch | ✅ |
| **Ballistics** | Table distance step (dialog) | ✅ |
| **Ballistics** | Chart distance step (dialog) | ✅ |
| **Data** | Export / Import buttons | ⏳ stub |
| **About** | Version, links (GitHub, Privacy, Terms, Changelog) | ✅ (links stub) |

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

Contains at minimum three ruler-like selectors:

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

### 5.5 Value Input Widgets (reusable)

Two reusable input patterns:

**Ruler Selector** (`lib/widgets/ruler_selector.dart`):
- Modal dialog/popup with vertical layout
- Float/int input field with POS-terminal-style behavior (digits enter from right)
- Touchable vertical ruler with tick marks; center tick = selected value
- Touch drag + keyboard input

**Spin Box Selector** (`lib/widgets/spin_box_selector.dart`):
- Modal dialog/popup
- Float/int input with POS-terminal-style behavior
- Up/Down buttons flanking the input field, change value by configured step

Reference implementations (TypeScript originals):
- `doubleSpinBox.tsx`, `valueDialog.tsx`, `ruler.tsx`, `numericField.tsx` in `ebalistyka-web`

Input accuracy logic follows the referenced components.

Used for: wind speed, look angle, target distance, conditions fields.

---

### 5.6 Units Screen (`/settings/units`)

> Opened from **Settings → Units of Measurement**.

List of unit categories, each with an inline chip/dropdown selector.

| Category | Options |
|----------|---------|
| Velocity | fps / m/s |
| Distance | meters / yards / feet |
| Sight height | inches / cm |
| Pressure | mmHg / inHg / hPa / PSI |
| Temperature | Celsius / Fahrenheit |
| Drop / Windage | meters / feet / cm / inches |
| Drop / Windage angle | MIL / MOA / MRAD / cm/100m / in/100yd |
| Energy | joules / foot-pounds |
| Bullet weight | grams / grains |
| OGW | pounds / kg |
| Bullet length | mm / cm / inches |

---

### 5.7 Adjustment Display Screen (`/settings/adjustment`)

> Opened from **Settings → Adjustment Display**.

| Setting | Options |
|---------|---------|
| Adjustment format | Arrows ↑↓ / Signs +− / Letters UD |
| Show MRAD | switch |
| Show MOA | switch |
| Show MIL | switch |
| Show cm/100m | switch |
| Show in/100yd | switch |
| Table distance step | (later) |
| Chart distance step | (later) |

Stored as flat fields directly in `AppSettings` (no nested model).

---

### 5.8 Rifle Selection Screen

> Opened from **Rifle selection** button on Home.

| Element | Description |
|---------|-------------|
| Library list | Select existing rifle |
| Create manually button | Pushes Rifle Edit screen |
| Sight selection | Select or create a sight for the rifle |
| Cartridge button | Pushes Cartridge screen |

---

### 5.9 Projectile Selection Screen

> Opened from **Projectile selection** button on Home.

| Element | Description |
|---------|-------------|
| Library list | Select existing projectile |
| Create manually button | Pushes Projectile Edit screen |

---

### 5.10 Cartridge Screen

Three actions on one screen:

| Element | Description |
|---------|-------------|
| Select from library | Replace current cartridge |
| Create manually | Push Cartridge Edit screen |
| Current cartridge settings | Edit parameters of already selected cartridge |

---

### 5.11 Table Configuration Screen (`/tables/configure`)

> Opened from **Configure** button on Tables screen.

Configure visible columns and distance step for the trajectory table. Saved in `AppSettings`.

---

### 5.12 Convertor Screen (`/convertors/:type`)

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

### 6.2 Unit System

`PreferredUnits` removed from domain. Domain classes use explicit `Unit` parameters. UI reads units via `unitSettingsProvider`.

### 6.3 Domain Models

#### `UnitSettings` — `lib/src/models/unit_settings.dart`

```dart
class UnitSettings {
  final Unit velocity;      // fps / mps
  final Unit distance;      // meter / yard / foot
  final Unit sightHeight;   // inch / centimeter
  final Unit pressure;      // mmHg / inHg / hPa / psi
  final Unit temperature;   // celsius / fahrenheit
  final Unit drop;          // meter / foot / centimeter / inch
  final Unit adjustment;    // mil / moa / mrad / cmPer100m / inPer100yd
  final Unit energy;        // joule / footPound
  final Unit weight;        // gram / grain
  final Unit ogw;           // pound / kilogram
  final Unit length;        // millimeter / centimeter / inch
  // internal / less-visible
  final Unit angular;       // degree / radian / mil / moa
  final Unit diameter;      // inch
  final Unit twist;         // inch
  final Unit time;          // second
}
```

#### `AppSettings` — `lib/src/models/app_settings.dart`

Adjustment display fields added directly (no nested model):

```dart
enum AdjustmentFormat { arrows, signs, letters }

class AppSettings {
  final UnitSettings units;
  final String     languageCode;
  final ThemeMode  themeMode;
  final double     tableDistanceStep;
  final double     chartDistanceStep;
  final bool       showSubsonicTransition;
  final bool       enableCoriolis;
  final bool       enablePowderSensitivity;
  final bool       enableDerivation;
  final bool       enableAerodynamicJump;
  final bool       pressureDependsOnAltitude;
  // Adjustment display (Phase 10.3)
  final AdjustmentFormat adjustmentFormat;  // ↑↓ / +− / UD
  final bool showMrad;
  final bool showMoa;
  final bool showMil;
  final bool showCmPer100m;
  final bool showInPer100yd;
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
  final Distance   zeroDistance;   // ← needed (currently hardcoded 100 m)
  final double?    latitudeDeg;
  final double?    azimuthDeg;

  Shot toShot();
}
```

### 6.4 Riverpod Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `settingsProvider` | `AsyncNotifierProvider<SettingsNotifier, AppSettings>` | All app settings |
| `unitSettingsProvider` | `Provider<UnitSettings>` | Sync unit access |
| `themeModeProvider` | `Provider<ThemeMode>` | Sync theme access |
| `shotProfileProvider` | `AsyncNotifierProvider<ShotProfileNotifier, ShotProfile>` | Current shot profile |
| `calculationProvider` | `AsyncNotifierProvider<CalculationNotifier, HitResult?>` | Lazy ballistic calculation |
| `rifleLibraryProvider` | `AsyncNotifierProvider` | Rifle CRUD |
| `cartridgeLibraryProvider` | `AsyncNotifierProvider` | Cartridge CRUD |
| `sightLibraryProvider` | `AsyncNotifierProvider` | Sight CRUD |
| `appStorageProvider` | `Provider<AppStorage>` | Storage singleton |

**Calculation architecture:** `CalculationNotifier` is lazy with `_dirty` flag. `build()` returns null immediately. `markDirty()` called from `_ScaffoldWithNavState` via `ref.listen(shotProfileProvider)`. `recalculateIfNeeded()` triggered only on Home (tab 0) and Tables (tab 2) tab activation. Runs in isolate via `compute()`.

### 6.5 Storage

**Interface:** `lib/storage/app_storage.dart`
**Implementation:** `JsonFileStorage` — JSON files in app documents directory.

Export archive:
```
eballistica_backup.zip
├── settings.json
├── profile.json
├── rifles.json
├── cartridges.json
└── sights.json
```

---

## 7. Open Questions

| # | Question | Status |
|---|----------|--------|
| 1 | Table export format: PDF or HTML? | ⏳ TBD |
| 2 | Reticle screen — static or interactive? | ⏳ TBD |
| 3 | Localizations: UK + EN only or more? | ⏳ UK + EN for now |
| 4 | cm/100m and in/100yd — are these `Unit` enum values or computed? | ⏳ TBD |

---

## 8. Current Codebase Status

### 8.1 Implemented ✅

| Area | File(s) | Notes |
|------|---------|-------|
| **Solver** | `src/solver/` | Full unit system, conditions, munition, drag tables, shot, trajectory, calculator, FFI |
| **Domain models** | `src/models/` | Rifle, Sight, Projectile, Cartridge, ShotProfile, AppSettings, UnitSettings, seed data |
| **Storage** | `storage/` | AppStorage interface + JsonFileStorage |
| **Providers** | `providers/` | Settings, ShotProfile, Library, Calculation, Storage |
| **Navigation** | `router.dart` | GoRouter with StatefulShellRoute, all routes, _ScaffoldWithNav |
| **Main** | `main.dart` | ProviderScope, MaterialApp.router, static ThemeData, themeModeProvider |
| **Home screen** | `screens/home_screen.dart` | Top block connected; bottom block: Page 3 (chart) ✅, Pages 1–2 stubs |
| **Tables screen** | `screens/tables_screen.dart` | Connected to calculationProvider, spinner, topbar |
| **TrajectoryTable** | `widgets/trajectory_table.dart` | Domain types, zero-row highlighting by distance |
| **TrajectoryChart** | `widgets/trajectory_chart.dart` | CustomPainter, domain types |
| **Settings screen** | `screens/settings_screen.dart` | Theme ✅, subsonic switch ✅, distance steps ✅, links ✅; language/units/adjustment — stubs |
| **Wind indicator** | `widgets/wind_indicator.dart` | Pan + tap + double-tap reset; commits only on gesture end |

### 8.2 Partially Done / Pending ⚠️

| Area | Status | Phase |
|------|--------|-------|
| Settings → Language dialog | Stub tile | 10 |
| Settings → Units screen | Stub screen | 10 |
| Settings → Adjustment Display screen | Stub screen | 10 |
| Adjustment display fields in `AppSettings` | Not added | 10 |
| `ShotProfile.zeroDistance` field | Hardcoded 100 m | 8.8 |
| Tables — frozen header | Not implemented | 8.1 |
| Tables — zero crossing table | Not implemented | 8.2 |
| Tables — row tap detail dialog | Not implemented | 8.3 |
| Tables — details spoiler | Not implemented | 8.4 |
| Tables — Configure wired | Stub | 8.6 |
| Tables — Export wired | Stub | 8.7 |
| Home — Page 1 (reticle + adjustments) | Stub | 6 |
| Home — Page 2 (adjustment tables) | Stub | 6 |
| Home — Page 3 (details and interactivity)
| Conditions screen | Stub | 7 |
| Convertors screen | Grid stub | 9 |
| Rifle/Cartridge/Sight selection | Stubs | 11 |

---

## 9. Implementation Phases

---

### Phase 1–5 ✅ — Foundation

Domain models, storage, providers, navigation. **Done.**

---

### Phase 5.5 — Value Input Widgets

Reusable input components used across multiple screens.

**Ruler Selector:**
- Modal with vertical ruler (touch drag)
- POS-terminal digit input
- Reference: `ruler.tsx`, `valueDialog.tsx`, `numericField.tsx`

**Spin Box Selector:**
- Modal with up/down step buttons + POS-terminal input
- Reference: `doubleSpinBox.tsx`

---

### Phase 6 — Home Screen Bottom Block

1. **Page 1:** Left — reticle placeholder (rounded square). Right — drop/windage in multiple units from `adjustmentDisplay` settings.
2. **Page 2:** Scrollable set of compact tables (Height, Slant Height, Drop angle, Windage angle, Velocity, Energy, Time), each ±2 steps around target distance.
3. **Page 3:** Chart connected to `calculationProvider` ✅ + tap-to-select-point.
4. Also: placeholder sub-screens for New Note and More buttons.

---

### Phase 7 — Conditions Screen

Connect all fields to `ShotProfileNotifier.updateConditions()`. Units from `unitSettingsProvider`. Switches from `SettingsNotifier`. Aerodynamic jump and pressure-from-altitude: always ON, controls visible but disabled.

---

### Phase 8 — Tables Screen

**Done:** calculationProvider connected, topbar, spinner, domain types, zero-row highlight.

**Pending:**
- **8.1** Frozen header (column/unit rows fixed, only data rows scroll)
- **8.2** Zero crossing table above main table (from `HitResult.zeros`)
- **8.3** Row tap → detail dialog
- **8.4** Details spoiler (rifle, cartridge, conditions summary)
- **8.6** Wire Configure button
- **8.7** Wire Export button
- **8.8** Add `zeroDistance` to `ShotProfile`, remove hardcoded 100 m

---

### Phase 9 — Convertors Screen

Grid of 8 tiles → each pushes `/convertors/:type` placeholder. Individual converter screen: two input fields, real-time conversion via `Unit`/`Dimension`.

---

### Phase 10 — Settings Screen (completion)

**Done:** theme, subsonic switch, distance steps, links/about.

**Pending:**
- **10.1** Language tile → `AlertDialog` with radio list (uk/en), calls `SettingsNotifier.setLanguage()`
- **10.2** Units Screen — implement `/settings/units`:
  - Each category: label + chip group or dropdown → calls `SettingsNotifier.setUnit(key, unit)`
  - Categories per §5.6
- **10.3** Adjustment Display Screen — implement `/settings/adjustment`:
  - Format selector (arrows/signs/letters)
  - Toggles for MRAD, MOA, MIL, cm/100m, in/100yd
  - Add `adjustmentFormat`, `showMrad/Moa/Mil/CmPer100m/InPer100yd` flat fields to `AppSettings`, wire to `SettingsNotifier`

---

### Phase 11 — Rifle / Cartridge / Sight Selection

- `RifleSelectionScreen` — list from `rifleLibraryProvider`, FAB to create
- `RifleEditScreen` — form: name, sight height, twist, zero elevation
- `SightSelectionScreen` — list from `sightLibraryProvider`
- `CartridgeScreen` — select / create / edit current
- `ProjectileSelectionScreen` — list from `cartridgeLibraryProvider`
- `CartridgeEditScreen` — full projectile + ammo form

---

### Phase 12 — Additional Screens

- `InfoScreen` — read-only ShotProfile display
- `ReticleScreen` — full-screen reticle (TBD)
- `TableConfigScreen` — column visibility + step
- **Help Overlay** — all-in-one coach marks
- **Tools Screen** — ruler selectors for wind/angle/distance

---

### Phase 13 — Polish & Export

- Localization (ARB, flutter_localizations, uk + en)
- Table export — PDF or HTML via share sheet
- Profile import via `file_picker`
- iOS C++ library bundling

---

## 10. Dependencies

### In use

```yaml
flutter_riverpod:
go_router:
ffi:
uuid:
path_provider:
window_manager:
```

### To add

```yaml
archive: ^3.0.0          # ZIP export
file_picker: ^8.0.0      # profile import
share_plus: ^9.0.0       # table export share sheet
flutter_localizations: sdk
intl: ^0.19.0
```

---

## 11. Execution Order

```
Phase 1–5   ✅  Foundation (domain, storage, providers, navigation)
Phase 10       Settings completion (language dialog, units screen, adjustment screen)
Phase 7        Conditions Screen
Phase 8        Tables Screen (frozen header, zero table, spoiler, zeroDistance)
Phase 6        Home Screen bottom block (pages 1 & 2)
Phase 5.5      Value input widgets (ruler + spin box)
Phase 9        Convertors Screen
Phase 11       Rifle / Cartridge / Sight Selection
Phase 12       Additional Screens
Phase 13       Polish & Export
```

---

*Document updated as implementation progresses.*
