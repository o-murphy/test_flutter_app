# eBallistica — Master Project Document

**Version:** 2.0
**Status:** Working Document
**Stack:** Flutter · Dart · Riverpod · FFI (bclibc C++)
**Package:** `eballistica` · Bundle ID: `com.ballistics.eballistica`

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

| Input type                                                | Method                             |
| --------------------------------------------------------- | ---------------------------------- |
| Ruler selectors (wind speed, look angle, target distance) | Touch drag **and** keyboard (both) |
| All other value selectors                                 | Keyboard only via dialog           |

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

| #   | ID           | Name       | Description                   |
| --- | ------------ | ---------- | ----------------------------- |
| 1   | `home`       | Home       | Current shot                  |
| 2   | `conditions` | Conditions | Environmental conditions      |
| 3   | `tables`     | Tables     | Current shot trajectory table |
| 4   | `convertors` | Convertors | Unit converters               |
| 5   | `settings`   | Settings   | App settings                  |

### 3.2 Stack Model

Each primary screen has its **own independent navigation stack**. Sub-screens are pushed onto the stack of the screen that opened them.

**The Bottom Navigation Bar is always visible** — including inside any sub-screen. Tapping a nav bar item:
- Clears the entire current stack
- Navigates to the selected primary screen (or returns to it if already active)

### 3.3 Stacks per Screen

| Primary screen | Sub-screen stack                                           |
| -------------- | ---------------------------------------------------------- |
| **Home**       | → Rifle Selection → (Sight / Cartridge / Library / Create) |
| **Home**       | → Projectile Selection → (Library / Create)                |
| **Home**       | → Shot Details (Info screen)                               |
| **Settings**   | → Units of Measurement                                     |
| **Settings**   | → Adjustment Display                                       |
| **Tables**     | → Table Configuration                                      |
| **Convertors** | → Convertor Screen (individual converter)                  |

### 3.4 Back Button Behavior

| Situation                      | Action                                                     |
| ------------------------------ | ---------------------------------------------------------- |
| Inside a sub-screen            | Pop stack → previous screen                                |
| On a primary screen (not Home) | Navigate to **Home**                                       |
| Tap on nav bar                 | Clears entire stack → navigates to selected primary screen |

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

| Element                     | Action                                         |
| --------------------------- | ---------------------------------------------- |
| Rifle selection button      | Opens Rifle Selection screen (stack push)      |
| Projectile selection button | Opens Projectile Selection screen (stack push) |

**Navigation buttons:**

| Element             | Action                                          |
| ------------------- | ----------------------------------------------- |
| Shot details button | Pushes Info screen                              |
| New note button     | Creates a note for the shot (stub → Phase 12)   |
| Help button         | Shows all-in-one help overlay (stub → Phase 12) |
| More button         | Pushes Tools screen (stub → Phase 12)           |

**Read-only indicators** (values from Conditions screen):

| Element          | Value               |
| ---------------- | ------------------- |
| Temperature sign | Current temperature |
| Altitude sign    | Current altitude    |
| Humidity sign    | Current humidity    |
| Pressure sign    | Current pressure    |

**Wind Direction Wheel:** Interactive element for selecting wind direction. Displays current direction. Double-tap resets to 0°.

**Quick action buttons** (each opens a ruler-like selector overlay):

| Button          | Parameter              |
| --------------- | ---------------------- |
| Wind speed      | Wind velocity          |
| Look angle      | Shot inclination angle |
| Target distance | Distance to target     |

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
- Data source: `homeVmProvider` → `HomeUiReady.reticleData` → drop/windage adjustments per enabled unit

**Page 2: Adjustment Tables**

Vertically scrollable set of compact tables. Each table: header row with distances (target ± 2 steps), value row. Tables:

| Table            | Unit                        |
| ---------------- | --------------------------- |
| Height           | `units.drop`                |
| Slant Height     | `units.drop`                |
| Angle (MIL)      | mil                         |
| Angle (MOA)      | moa                         |
| Drop (MIL)       | mil                         |
| Drop (MOA)       | moa                         |
| Windage (MIL)    | mil                         |
| Windage (MOA)    | moa                         |
| Velocity         | `units.velocity`            |
| Energy           | `units.energy`              |
| Time             | seconds                     |

**Page 3: Trajectory Chart**

- Above chart: info grid with currently selected point values
  - Left column: Trajectory label, Velocity, Energy, Time
  - Right column: Height, Drop, Windage, Distance
- Chart: trajectory curve + velocity curve only (no barrel/sight lines)
- Default selected point: start of trajectory
- Pan on chart → highlights nearest point, updates info grid above
- Axis labels removed; numeric tick labels only, right-aligned to chart edges
---

### 4.2 Conditions Screen

> **Purpose:** Input and editing of environmental parameters.

**Input fields** (units from `unitSettingsProvider`):

Layout per field: `[−]  value  unit  [+]` — the +/− buttons are adjacent to the value, not at the edges of the row. Tapping the value itself opens a keyboard dialog for direct numeric entry.

| Parameter   | Unit                |
| ----------- | ------------------- |
| Temperature | `units.temperature` |
| Altitude    | `units.distance`    |
| Humidity    | %                   |
| Pressure    | `units.pressure`    |

**Switches** (read/write `AppSettings` via `SettingsNotifier`):

| Switch                                        | Note                                                            |
| --------------------------------------------- | --------------------------------------------------------------- |
| Coriolis effect                               |                                                                 |
| Powder temperature sensitivity                | When ON — reveals sub-switch + readonly fields (see below)      |
| ↳ Use different powder temperature            | Sub-switch; when ON — shows editable `Powder temperature` field |
| ↳ *(readonly)* Muzzle velocity at powder temp | Calculated via `Ammo.getVelocityForTemp(currentPowderTemp)`     |
| ↳ *(readonly)* Powder sensitivity             | `Cartridge.tempModifier` formatted as `%/15°C`                  |
| Derivation                                    |                                                                 |
| Aerodynamic jump                              | Always ON, control disabled (engine limitation)                 |
| Pressure depends on altitude                  | Always ON, control disabled (engine limitation)                 |

Powder temperature field appears in the **switch section** (not atmospheric fields), below the sub-switch, only when `useDiffPowderTemperature` is ON.

---

### 4.3 Tables Screen

> **Purpose:** Full trajectory table for the current shot.

Layout (top to bottom):

| Element                   | Description                                                                |
| ------------------------- | -------------------------------------------------------------------------- |
| **Header**                | Back button, "Tables" title, Configure + Export buttons                    |
| **Spoiler / accordion**   | Collapsible panel: rifle, cartridge, sight, atmospheric conditions summary |
| **Zero crossing table**   | Small table showing zero-crossing points (from `HitResult.zeros`)          |
| **Full trajectory table** | Complete trajectory for all distances; zero-distance row highlighted       |
| **Configure button**      | Pushes `/tables/configure`                                                 |
| **Export / Share button** | Exports table via share sheet (PDF or HTML, TBD)                           |

All values that has no overloads in table configuration - FC-based
Should use a behaviour from it's configuration for step start/end, not from app settings 

---

### 4.4 Convertors Screen

> **Purpose:** Collection of unit converters. Sub-screens are placeholders for now.

**Layout:** Responsive scrollable grid — tile count per row adapts to screen width (`SliverGrid.extent` with `maxCrossAxisExtent ≈ 160 dp`). Each tile — square card with rounded corners, large icon, name below.

**Converters (8 total):**

| #   | Route type        | Name                  |
| --- | ----------------- | --------------------- |
| 1   | `target-distance` | Target Distance       |
| 2   | `velocity`        | Velocity              |
| 3   | `length`          | Length                |
| 4   | `weight`          | Weight                |
| 5   | `pressure`        | Pressure              |
| 6   | `temperature`     | Temperature           |
| 7   | `mil-moa`         | MIL / MOA at Distance |
| 8   | `torque`          | Torque                |

---

### 4.5 Settings Screen

> **Purpose:** Global app settings.

| Section        | Element                                              | Status         |
| -------------- | ---------------------------------------------------- | -------------- |
| **Language**   | Tap → AlertDialog radio uk/en, calls `setLanguage()` | ✅              |
| **Appearance** | Theme — SegmentedButton (System/Light/Dark)          | ✅              |
| **Appearance** | Units of Measurement → `/settings/units`             | ✅              |
| **Ballistics** | Adjustment Display → `/settings/adjustment`          | ✅              |
| **Ballistics** | Subsonic transition switch                           | ✅              |
| **Ballistics** | Table distance step (dialog)                         | ✅              | Affects Home bottom block Page 2 only. Tables screen will have its own per-screen step setting. |
| **Ballistics** | Chart distance step (dialog)                         | ✅              |
| **Data**       | Export / Import buttons                              | ⏳ stub         |
| **About**      | Version, links (GitHub, Privacy, Terms, Changelog)   | ✅ (links stub) |

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

| Tool                     | Description                             |
| ------------------------ | --------------------------------------- |
| Wind speed selector      | Ruler-based wind speed selection        |
| Look angle selector      | Ruler-based inclination angle selection |
| Target distance selector | Ruler-based target distance selection   |

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

| Category             | Options                               |
| -------------------- | ------------------------------------- |
| Velocity             | fps / m/s                             |
| Distance             | meters / yards / feet                 |
| Sight height         | inches / cm                           |
| Pressure             | mmHg / inHg / hPa / PSI               |
| Temperature          | Celsius / Fahrenheit                  |
| Drop / Windage       | meters / feet / cm / inches           |
| Drop / Windage angle | MIL / MOA / MRAD / cm/100m / in/100yd |
| Energy               | joules / foot-pounds                  |
| Bullet weight        | grams / grains                        |
| OGW                  | pounds / kg                           |
| Bullet length        | mm / cm / inches                      |

---

### 5.7 Adjustment Display Screen (`/settings/adjustment`)

> Opened from **Settings → Adjustment Display**.

| Setting             | Options                           |
| ------------------- | --------------------------------- |
| Adjustment format   | Arrows ↑↓ / Signs +− / Letters UD |
| Show MRAD           | switch                            |
| Show MOA            | switch                            |
| Show MIL            | switch                            |
| Show cm/100m        | switch                            |
| Show in/100yd       | switch                            |
| Table distance step | (later)                           |
| Chart distance step | (later)                           |

Stored as flat fields directly in `AppSettings` (no nested model).

---

### 5.8 Rifle Selection Screen

> Opened from **Rifle selection** button on Home.

| Element                | Description                            |
| ---------------------- | -------------------------------------- |
| Library list           | Select existing rifle                  |
| Create manually button | Pushes Rifle Edit screen               |
| Sight selection        | Select or create a sight for the rifle |
| Cartridge button       | Pushes Cartridge screen                |

---

### 5.9 Projectile Selection Screen

> Opened from **Projectile selection** button on Home.

| Element                | Description                   |
| ---------------------- | ----------------------------- |
| Library list           | Select existing projectile    |
| Create manually button | Pushes Projectile Edit screen |

---

### 5.10 Cartridge Screen

Three actions on one screen:

| Element                    | Description                                   |
| -------------------------- | --------------------------------------------- |
| Select from library        | Replace current cartridge                     |
| Create manually            | Push Cartridge Edit screen                    |
| Current cartridge settings | Edit parameters of already selected cartridge |

---

### 5.11 Table Configuration Screen (`/tables/configure`)

> Opened from **Configure** button on Tables screen.

Configure visible columns and distance step for the trajectory table. Saved in `AppSettings`.

All values that has no overloads in table configuration - FC-based

* Start distance
* End distance
* Distance step
* Display two zeros switch - enables additional small table with 2 zero crossing points
* Details spoiler settings (check what to display):
    * Rifle section switch
      * Caliber switch
      * Twist switch
      * Twist direction switch
    * Projectile switch
      * Drag-Model type switch
      * BC switch
      * Zero Muzzle Velocity
      * Curr Muzzle Velocity
      * Zero Distance
      * Bullet len
      * Bullet diameter
      * Bullet Weight
      * Gyrostability
    * Sight section switch - for now adding to document not implementing
      * Scope? x1-x20????
      * Focal plane: FFC SFC LWIR switch
      * Reticle name switch
      * Hor click switch
      * Ver click switch
      * Hor click units switch
      * Ver click units switch
    * Atmosphere section switch
      * Curr Temperature
      * Curr Humidity
      * Curr Pressure
      * Wind speed
      * Wind direction

* Table columns section (switches check what to display):
    * Time
    * Range
    * Velocity
    * Height
    * Drop
    * Drop Adjustment
    * Windage
    * Windage Drop Adjustment
    * Display adjustment in current units or in all adjusment units checked? - will display column for each selected
    * Drop / Windage units (uses this, and not global)
    * Mach
    * Drag
    * Energy


---

### 5.12 Convertor Screen (`/convertors/:type`)

> Opened from any tile on Convertors screen.

Two input fields with keyboard + unit labels. Real-time recalculation using the existing `Unit`/`Dimension` system.

---

### 5.13

The wind direction wheel and value input should use step from the FC
So create special wind_direction FC role 

### 5.14

Shot details screen - add GSF (gyrostability) ✅

### 5.15

Home screen - Page 1 - add GSF to title after dragmodel ✅

## 6. State Architecture

### 6.1 Layer Diagram

```
┌─────────────────────────────────────────┐
│           UI (screens / widgets)         │
│    ref.watch(xxxVmProvider)              │
│    receives ready-to-display strings     │
├─────────────────────────────────────────┤
│           ViewModels                     │
│  HomeViewModel · ConditionsViewModel     │
│  TablesViewModel                         │
│  (sealed UiState classes, formatted)     │
├─────────────────────────────────────────┤
│        Formatting / UnitFormatter        │
│  UnitFormatter · UnitFormatterImpl       │
│  (Dimension/double → String)             │
├─────────────────────────────────────────┤
│           Riverpod providers             │
│  ShotProfileNotifier · SettingsNotifier  │
│  RecalcCoordinator · HomeCalcNotifier    │
├─────────────────────────────────────────┤
│         Domain / Services                │
│  BallisticsService (interface)           │
│  BallisticsServiceImpl (FFI bridge)      │
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

**UnitFormatter** (`lib/formatting/`): Stateless formatter that converts between raw domain values and display strings. Takes `UnitSettings` at construction, provides `format(FieldRole, value)`, `inputToRaw(FieldRole, displayValue)`, `rawToInput(FieldRole, rawValue)`. Testable with `dart test` (no Flutter dependency).

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
  final bool       enablePowderSensitivity;         // UI toggle — show/use powder sens
  final bool       useDiffPowderTemperature;   // Use separate powder temp vs atmo temp
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

#### `Cartridge` — `lib/src/models/cartridge.dart`

Stores ammunition + powder sensitivity data:

```dart
class Cartridge {
  final dynamic mv;                   // Velocity — reference MV (at powderTemp)
  final dynamic powderTemp;           // Temperature — reference powder temp for mv
  final double  tempModifier;         // Powder sensitivity coefficient (%/15°C)
  final bool    usePowderSensitivity; // Whether engine uses powder sensitivity
  // ...
}
```

`mv` is always the MV measured at `powderTemp`. To get MV at another temperature, use `Ammo.getVelocityForTemp(currentTemp)`.

#### `ShotProfile` — `lib/src/models/shot_profile.dart`

```dart
class ShotProfile {
  final String     id;
  final String     name;
  final Rifle      rifle;
  final Sight      sight;
  final Cartridge  cartridge;
  final Atmo       conditions;      // Current atmospheric conditions
  final Atmo?      zeroConditions;  // Atmo at time of zeroing; null → use conditions
  final Distance   zeroDistance;    // Distance at which zero was set (default 100 m)
  final Distance   targetDistance;  // Current target range (used by QuickActionsPanel)
  final List<Wind> winds;
  final Angular    lookAngle;
  final double?    latitudeDeg;
  final double?    azimuthDeg;

}
```

`zeroConditions` is optional (null = use current `conditions`). `zeroDistance` is used by `calculation_provider.dart` instead of the previous hardcoded 100 m. `targetDistance` is the quick-action target range (default 300 m).

### 6.4 Riverpod Providers

#### Data providers

| Provider                   | Type                                                          | Purpose                                                                        |
| -------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `settingsProvider`         | `AsyncNotifierProvider<SettingsNotifier, AppSettings>`        | All app settings                                                               |
| `unitSettingsProvider`     | `Provider<UnitSettings>`                                      | Sync unit access                                                               |
| `themeModeProvider`        | `Provider<ThemeMode>`                                         | Sync theme access                                                              |
| `shotProfileProvider`      | `AsyncNotifierProvider<ShotProfileNotifier, ShotProfile>`     | Current shot profile                                                           |
| `rifleLibraryProvider`     | `AsyncNotifierProvider`                                       | Rifle CRUD                                                                     |
| `cartridgeLibraryProvider` | `AsyncNotifierProvider`                                       | Cartridge CRUD                                                                 |
| `sightLibraryProvider`     | `AsyncNotifierProvider`                                       | Sight CRUD                                                                     |
| `appStorageProvider`       | `Provider<AppStorage>`                                        | Storage singleton                                                              |

#### Service providers

| Provider                   | Type                                                          | Purpose                                                                        |
| -------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `ballisticsServiceProvider`| `Provider<BallisticsService>`                                 | FFI-backed calculation service                                                 |
| `unitFormatterProvider`    | `Provider<UnitFormatter>`                                     | Unit formatting (depends on unitSettingsProvider)                              |

#### ViewModel providers

| Provider                   | Type                                                          | Purpose                                                                        |
| -------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `homeVmProvider`           | `AsyncNotifierProvider<HomeViewModel, HomeUiState>`           | Home screen state (sealed: Loading/Ready/Error)                                |
| `conditionsVmProvider`     | `AsyncNotifierProvider<ConditionsViewModel, ConditionsUiState>` | Conditions screen state                                                      |
| `tablesVmProvider`         | `AsyncNotifierProvider<TablesViewModel, TablesUiState>`       | Tables screen state                                                            |

#### Coordination providers

| Provider                   | Type                                                          | Purpose                                                                        |
| -------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `recalcCoordinatorProvider`| `NotifierProvider<RecalcCoordinator, void>`                   | Centralises recalculation triggers on profile/settings changes and tab switches |

**Calculation architecture (after refactoring):**

`RecalcCoordinator` listens to `shotProfileProvider` and `settingsProvider`. On change, it triggers:
- `homeVmProvider.notifier.recalculate()`
- `tablesVmProvider.notifier.recalculate()`
- `homeCalculationProvider.notifier.markDirty()` + `recalculateIfNeeded()`

On tab activation (from router):
- Tab 0 (Home): triggers `homeVmProvider` + `homeCalculationProvider`
- Tab 2 (Tables): triggers `tablesVmProvider`

**BallisticsService** (`lib/domain/ballistics_service.dart` + `lib/services/ballistics_service_impl.dart`):
- Interface: `calculateForTarget(profile, options, cachedZeroElevRad?)`
- Returns `BallisticsCalcResult { hitResult, zeroElevationRad }`
- ViewModels call it via `ref.read(ballisticsServiceProvider)`
- Zero elevation caching done per-VM via `_buildZeroKey()` fingerprint

> Note: `zeroConditions` defaults to null in the seed (= use `conditions`). A dedicated Zero Conditions UI screen is pending (Phase 8.8 follow-up).

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

| #   | Question                                                         | Status            |
| --- | ---------------------------------------------------------------- | ----------------- |
| 1   | Table export format: PDF or HTML?                                | ⏳ TBD             |
| 2   | Reticle screen — static or interactive?                          | ⏳ TBD             |
| 3   | Localizations: UK + EN only or more?                             | ⏳ UK + EN for now |
| 4   | cm/100m and in/100yd — are these `Unit` enum values or computed? | ✅ `Unit.cmPer100m` / `Unit.inchesPer100Yd` — повноцінні enum-значення з конверсійними факторами |

---

## 8. Current Codebase Status

### 8.1 Implemented ✅

#### Infrastructure

| Area | File(s) | Notes |
| ---- | ------- | ----- |
| **App name / Bundle ID** | platform configs | `eBallistica` · `com.ballistics.eballistica` — all platforms updated |
| **bclibc submodule** | `external/bclibc` | Replaces former `native/` and `py-ballisticcalc` dirs; pinned at v1.0.0 |
| **Solver (FFI)** | `src/solver/` | Full unit system, conditions, munition, drag tables, shot, trajectory, calculator, FFI to bclibc |
| **Domain models** | `src/models/` | Rifle, Sight, Projectile, Cartridge, ShotProfile, AppSettings, UnitSettings, TableConfig, seed data |
| **Storage** | `storage/` | AppStorage interface + JsonFileStorage (JSON files in app documents dir) |
| **Providers** | `providers/` | Settings, ShotProfile, Library (Rifle/Sight/Cartridge), Calculation, Storage |
| **Navigation** | `router.dart` | GoRouter + StatefulShellRoute; all routes; tab switch resets branch stack |
| **Main** | `main.dart` | ProviderScope, MaterialApp.router, static ThemeData, themeModeProvider, global scroll behavior |

#### Screens

| Screen | File | Status |
| ------ | ---- | ------ |
| Home | `screens/home_screen.dart` | ✅ Top block (rifle/projectile selectors, wind wheel, SideControlBlock, QuickActionsPanel); 3-page bottom block. ⚠️ SideControlBlock: Shot Details button wired; Note/Help/More buttons are `() {}` stubs |
| Home — Page 1 | `widgets/home_reticle_page.dart` | ✅ Reticle placeholder (CustomPainter) + Drop/Windage panel with direction indicators per enabled unit; bullet/MV/drag info row |
| Home — Page 2 | `widgets/home_table_page.dart` | ✅ Compact 5-col table (target ± 2 steps), 11 rows, target column highlighted, FC-based accuracy |
| Home — Page 3 | `widgets/home_chart_page.dart` | ✅ Chart (trajectory + velocity curves) + info grid + tap/drag point selection + page persistence |
| Conditions | `screens/conditions_screen.dart` | ✅ All fields; TempControl; powder sensitivity full flow (sub-switch + powder temp field + readonly MV); Coriolis/derivation/AJ/pressure switches |
| Tables | `screens/tables_screen.dart` | ✅ Spinner; frozen header; zero-row highlight; zero-crossings table; row tap → detail dialog; details spoiler (rifle/projectile/atmosphere); Configure button. ⚠️ Export button is `() {}` stub |
| Tables → Configure | `screens/tables_sub_screens.dart` | ✅ Range/step; showZeros/showSubsonic; spoiler section switches (20+ toggles); column visibility (11 columns); adjAllUnits; dropUnit/adjUnit overrides; start < end cross-validation |
| Settings | `screens/settings_screen.dart` | ✅ Theme; language; distance steps (unit-aware); subsonic switch. ⚠️ Export/Import profile buttons, GitHub/Privacy/Terms/Changelog links — all `() {}` stubs |
| Settings → Units | `screens/settings_units_screen.dart` | ✅ 11 unit categories, dialog picker, wired to SettingsNotifier |
| Settings → Adjustment Display | `screens/settings_adjustment_screen.dart` | ✅ AdjustmentFormat SegmentedButton + 5 unit switches |
| Convertors | `screens/convertor_screen.dart` | ✅ 8-tile grid (target distance, velocity, length, weight, pressure, temperature, MIL/MOA, energy) — each tile navigates to `/convertors/:type` |
| Convertors → Individual | `screens/convertor_screen.dart` | ⚠️ Route exists, screen is stub |
| Shot Details | `screens/shot_details_screen.dart` | ✅ 4 sections: Velocity, Energy, Stability (Miller Sg), Trajectory; all values unit-aware |
| Rifle/Projectile/Cartridge/Sight screens | `screens/home_sub_screens.dart` | ⛔ All 7 screens are stubs (`StubScreen`) |

#### Widgets & shared components

| Widget | File | Notes |
| ------ | ---- | ----- |
| `TrajectoryTable` | `widgets/trajectory_table.dart` | Sticky header, bidirectional h-scroll sync, FC-based accuracy, subsonic highlight ✅ |
| `TrajectoryChart` | `widgets/trajectory_chart.dart` | CustomPainter, dual axis, subsonic line, tap/pan snap ✅ |
| `WindIndicator` | `widgets/wind_indicator.dart` | Pan + tap + double-tap reset; clock-face display ✅ |
| `QuickActionsPanel` | `widgets/quick_actions_panel.dart` | Wind speed, look angle, target distance; `showUnitEditDialog` ✅ |
| `UnitValueField` | `widgets/unit_value_field.dart` | `[icon label value ✎]` tappable row + `showUnitEditDialog()` top-level fn ✅ |
| `TempControl` | `widgets/temperature_control.dart` | Big centred ± widget + dialog ✅ |
| `SideControlBlock` | `widgets/side_control_block.dart` | FAB pair + info rows ✅ |
| `IconValueButton` | `widgets/icon_value_button.dart` | FAB-style selector buttons ✅ |
| `SectionHeader` | `widgets/section_header.dart` | Reusable all-caps section label ✅ |
| Settings helpers | `widgets/settings_helpers.dart` | `SettingsHeader`, `SettingsSectionLabel`, `SettingsUnitTile` ✅ |

#### Calculation engine

| Feature | Notes |
| ------- | ----- |
| BallisticsService | Single service interface; `HomeViewModel` and `TablesViewModel` call it via provider |
| RecalcCoordinator | Centralises all recalculation triggers (profile/settings changes + tab activation) |
| ViewModels | `HomeViewModel`, `TablesViewModel` — produce sealed UiState with formatted strings |
| ShotDetailsViewModel | Replaced legacy homeCalculationProvider; provides formatted data for Shot Info screen |
| Zero uses zeroConditions | Always uses `profile.zeroConditions ?? profile.conditions` |
| Zero elevation cache | `_buildZeroKey` (19-field flat list, `listEquals`) — zero phase skipped when zero-relevant inputs unchanged |
| Powder sensitivity | Engine handles `getVelocityForTemp` internally; `usePowderSensitivity` flag propagated correctly |
| Coriolis / spin drift | Passed via `latitudeDeg` / `azimuthDeg` / settings flags |

#### Proto / A7P

| Item | Status |
| ---- | ------ |
| `proto/profedit.proto` | ✅ Schema present (stripped of buf/validate) |
| `src/proto/profedit.pb.dart` | ✅ Generated (Dart protobuf classes) |
| `src/a7p/` directory | ✅ `a7p_parser.dart` (213 lines) + `a7p_validator.dart` (157 lines) implemented |
| A7P import UI | ⛔ Not started |
| A7P export UI | ⛔ Not started |

---

### 8.2 Pending ⚠️

#### 🔴 High priority

| Area | Notes | Phase |
| ---- | ----- | ----- |
| **A7P parser** | `Profile` proto → `ShotProfile` domain; scale-factor conversion; validation | A7P |
| **A7P writer** | `ShotProfile` → `Profile` proto → `.a7p` bytes | A7P |
| **A7P validation** | Port Python yupy schema to Dart; G1/G7 coef_rows ≤ 5, CUSTOM ≤ 200; unique mv | A7P |
| **A7P import UI** | `file_picker` → parse → load into profile | A7P |
| **A7P export UI** | serialize → `share_plus` | A7P |
| **Zero Conditions UI** | Screen to edit `zeroConditions` separately from current `conditions` | 8.8 follow-up |

#### 🟠 Medium priority

| Area | Notes | Phase |
| ---- | ----- | ----- |
| Rifle Selection screen | List from `rifleLibraryProvider` + FAB to create | 11 |
| Rifle Edit screen | Form: name, sight height, twist, caliber | 11 |
| Sight Selection screen | List from `sightLibraryProvider` | 11 |
| Cartridge screen | Select / create / edit current cartridge | 11 |
| Projectile Selection screen | List from `cartridgeLibraryProvider` | 11 |
| Cartridge/Projectile Edit screen | Full ammo + projectile form | 11 |
| Individual Convertor screen | Two fields + real-time conversion via `Unit`/`Dimension` | 9 |

#### 🔵 Lower priority

| Area | Notes | Phase |
| ---- | ----- | ----- |
| Table export | PDF/HTML + share sheet | 13 |
| Profile import | `file_picker` + ZIP restore | 13 |
| Localization uk/en | ARB + flutter_localizations | 13 |
| iOS C++ bundling | `.a` static lib in Xcode | 13 |
| RulerSelector widget | Touch-drag ruler; replaces `showUnitEditDialog` in QuickActionsPanel (SpinBox вже є як `showUnitEditDialog`) | 5.5 |
| Reticle screen | Full-screen reticle (TBD) | 12 |
| Help Overlay | Coach marks | 12 |
| Tools Screen | Placeholder | 12 |


---

## 9. Implementation Phases

### Phase 1–5 ✅ — Foundation

Domain models, storage, providers, navigation. **Done.**

---

### Architecture Refactoring ✅ — MVVM + Service Layer

Full refactoring per `REFACTORING_PLAN.md` (5 phases):
- **Phase 0:** UnitFormatter interface + implementation (57 tests, `dart test`)
- **Phase 1:** BallisticsService interface + FFI-backed implementation
- **Phase 2:** HomeViewModel, ConditionsViewModel, TablesViewModel — sealed UiState, 70 tests
- **Phase 3:** RecalcCoordinator — centralised recalculation triggers, 18 tests
- **Phase 4:** Screens wired to ViewModels (home, conditions, tables)
- **Phase 5:** Cleanup — deleted `dimension_converter.dart`, `calculation_provider.dart`; extracted `HomeCalculationNotifier` to `home_calculation_provider.dart`

**Total: 145 non-FFI tests passing.**

---

### Phase 5.5 — Value Input Widgets

**MVP ✅:** `showUnitEditDialog()` — reusable `[−] field [+]` dialog; used by `UnitValueField`, `QuickActionsPanel`, `TempControl`.

**Remaining (low priority):**

- **RulerSelector** (`lib/widgets/ruler_selector.dart`): modal with vertical touch-drag ruler + POS digit input. Will replace `showUnitEditDialog` in QuickActionsPanel.
- **SpinBoxSelector** ✅ — реалізований як `showUnitEditDialog()` (`[−] field [+]` + validation + OK/Cancel). Окремий виджет не потрібен.

---

### Phase 6 ✅ — Home Screen Bottom Block

All three pages done. Extracted to `home_reticle_page.dart`, `home_table_page.dart`, `home_chart_page.dart`.

**Stubs remaining in Home top block (Phase 12):**
- "New note" button — `onBottomPressed: () {}`
- "Help" button — `() {}`
- "More" button — `() {}`

---

### Phase 7 ✅ — Conditions Screen

All fields, all switches, powder sensitivity full flow. Done.

---

### Phase 8 ✅ — Tables Screen

Frozen header, zero-crossings table, row detail dialog, details spoiler, TableConfig screen. `zeroDistance` + `zeroConditions?` + `targetDistance` in `ShotProfile`. Hardcoded 100 m removed.

**Pending:**
- **8.7** Export button (stub)
- **8.8 follow-up** Zero Conditions UI

---

### Phase 9 — Convertors Screen

Grid ✅. Individual convertor screen (`/convertors/:type`) — **not implemented**.

---

### Phase 10 ✅ — Settings Screen

Theme, language, distance steps, units (11 categories), Adjustment Display (format + 5 toggles). Done.

**Stubs remaining (Phase 13):**
- Export / Import profile buttons — `() {}`
- GitHub / Privacy Policy / Terms of Use / Changelog links — `() {}`

---

### Phase 11 — Rifle / Cartridge / Sight Selection

All 7 screens are stubs. To implement:
- `RifleSelectionScreen` — list + FAB create
- `RifleEditScreen` — name, sight height, twist, caliber form
- `SightSelectionScreen` — list from `sightLibraryProvider`
- `CartridgeScreen` — select / create / edit current
- `ProjectileSelectionScreen` — list from `cartridgeLibraryProvider`
- `CartridgeEditScreen` + `ProjectileEditScreen` — full ammo + projectile form

---

### Phase A7P — .a7p File Support 🔴🔴

Proto generated (`src/proto/profedit.pb.dart`). Validator and parser implemented.

**Status:**
1. `lib/src/a7p/a7p_validator.dart` — ✅ implemented
2. `lib/src/a7p/a7p_parser.dart` — ✅ implemented (`Profile` → `ShotProfile` with scale-factor conversion)
3. `lib/src/a7p/a7p_writer.dart` — ⛔ not started (`ShotProfile` → `Payload` bytes)
4. Add deps: `file_picker`, `share_plus`, `archive`

**Scale factors** (from proto comments):
| Field | Raw unit | Scale |
| ----- | -------- | ----- |
| `sc_height` | mm | ×1 |
| `r_twist` | inch | ×100 |
| `c_muzzle_velocity` | m/s | ×10 |
| `c_zero_temperature` | °C | ×1 |
| `c_t_coeff` | %/15°C | ×1000 |
| `c_zero_air_pressure` | hPa | ×10 |
| `b_diameter` | inch | ×1000 |
| `b_weight` | grain | ×10 |
| `b_length` | inch | ×1000 |
| `distances[]` | m | ×100 |
| `coef_rows.bc_cd` | BC or Cd | ×10000 |
| `coef_rows.mv` | m/s | ×10 |
| `zero_x` / `zero_y` | clicks | ×−1000 / ×1000 |

**Validation rules** (from Python schema):
- `profile_name`, `cartridge_name`, `bullet_name`, `caliber` — required, max 50 chars
- `short_name_top`, `short_name_bot` — required, max 8 chars
- `distances[]` — 1–200 items, each 100–300000
- `switches[]` — min 4 items; VALUE type: distance 100–300000; INDEX type: distance 0–255
- G1/G7 `coef_rows`: 1–5 items, bc_cd 0–10000, mv 0–30000, mv values unique (except 0)
- CUSTOM `coef_rows`: 1–200 items, bc_cd 0–10000, mv 0–10000, mv unique (except 0)

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
protobuf: ^6.0.0
uuid: ^4.0.0
path_provider: ^2.1.0
window_manager:
sticky_headers:
crypto: ^3.0.3
```

### To add (A7P phase)

```yaml
file_picker: ^8.0.0      # .a7p import + profile import
share_plus: ^9.0.0       # .a7p export + table export share sheet
archive: ^3.0.0          # ZIP backup export
flutter_localizations: sdk
intl: ^0.19.0
```

### protoc toolchain (dev, not in pubspec)

```bash
dart pub global activate protoc_plugin
# then: protoc --dart_out=lib/src/proto proto/profedit.proto
```

---

## 11. Execution Order

```
Phase 1–5   ✅  Foundation
Phase 10    ✅  Settings
Phase 7     ✅  Conditions Screen
Phase 8     ✅  Tables Screen
Phase 8.8   ✅  ShotProfile zero fields; hardcoded 100 m removed
Phase 5.5   ✅  QuickActionsPanel MVP
Phase 6     ✅  Home Screen bottom block; files extracted
Refactor    ✅  home_screen, settings screens split into widget files
Rename      ✅  eBallistica / com.ballistics.eballistica
Zero cache  ✅  _buildZeroKey + Phase 1 skip when zero inputs unchanged

─── Architecture Refactoring (REFACTORING_PLAN.md) ───
Refactor 0  ✅  UnitFormatter interface + implementation + 57 tests
Refactor 1  ✅  BallisticsService interface + FFI implementation
Refactor 2  ✅  HomeViewModel + ConditionsViewModel + TablesViewModel (70 tests)
Refactor 3  ✅  RecalcCoordinator (18 tests); router.dart updated
Refactor 4  ✅  Screens wired to ViewModels (home, conditions, tables)
Refactor 5  ✅  Cleanup: deleted dimension_converter.dart, calculation_provider.dart;
                extracted HomeCalculationNotifier → home_calculation_provider.dart
Tests reorg ✅  Tests moved to test/formatting/, test/viewmodels/, test/services/

─── Remaining ───
A7P         🔴  writer → import/export UI (validator + parser done; add file_picker, share_plus, archive)
Zero Cond   🔴  Zero Conditions UI — screen to edit zeroConditions separately from current conditions
Phase 11        Rifle / Cartridge / Sight / Projectile selection + edit screens (7 stubs)
Phase 9         Individual Convertor screen (/convertors/:type stub)
8.7             Tables Export button
Phase 13        Settings: Export/Import profile buttons; GitHub/Privacy/Terms/Changelog links
Phase 13        l10n uk/en, PDF table export, iOS C++ bundling
Phase 12        Home: Note / Help / More buttons
Phase 5.5 ⏳    RulerSelector widget — touch-drag ruler для QuickActionsPanel (lower priority)
                SpinBoxSelector = showUnitEditDialog ✅ (вже реалізований як [−] field [+] діалог)
```
