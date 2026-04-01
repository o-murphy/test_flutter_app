# Plan: Rifle Select Screen + Data Architecture Cleanup

## Context

The user is building the `rifle_select_screen.dart` feature and identified a fundamental architectural problem: the split between **zero data** (conditions when the rifle was zeroed, part of the stored ballistic profile) and **current data** (live shooting conditions, edited via Home/Conditions screens) is inconsistent.

**Root cause of inconsistency:**
- `Atmo zeroConditions` and `Atmo conditions` already correctly separate atmospheric data (temp, pressure, altitude, humidity, powder temp)
- But `Cartridge.usePowderSensitivity` and `Cartridge.powderSensitivity` are shared — a single flag/value used for BOTH zero and current calculations
- Result: `BallisticsServiceImpl` cannot independently enable/disable powder sensitivity for zero vs current shot velocity computation
- In `.a7p` format there is already a separate `c_t_coeff` for zero — but the model can't represent "use sensitivity at zero but not at current"

---

## Plan of Action

### Phase 1 — Fix Service Logic: Unify Powder Sensitivity Calculation

**Problem**: `cartridge.powderSensitivity` is a physical property of the ammo — it should remain shared. What's broken is that `BallisticsServiceImpl` likely doesn't pass `zeroConditions.powderTemp` through the same `getVelocityForTemp()` path it uses for current conditions.

**Design decisions:**
1. `powderSensitivity` coefficient stays in `Cartridge` — it's a physical ammo property, same for zero and current
2. `usePowderSensitivity` flag: stays in `Cartridge` for current shooting; add `zeroUsePowderSensitivity: bool?` to `ShotProfile` for independent control of zero calculation (`null` = inherit from cartridge)
3. `useDiffPowderTemp`: **remove from `Cartridge`**, add to `ShotProfile` as two separate flags:
   - `zeroUseDiffPowderTemp: bool` — for zero conditions (part of stored profile)
   - `useDiffPowderTemp: bool` — for current conditions (part of current shot state)
   - Not present in a7p format → defaults to `false` on import (powder temp = air temp)
   - When `false`: ballistics service uses `atmo.temperature` as powder temp for that context
   - When `true`: ballistics service uses `atmo.powderTemp` explicitly

**Changes:**

#### `lib/core/services/ballistics_service_impl.dart` (MAIN FIX)
- Zero velocity:
  - `effectivePowderTemp = zeroUseDiffPowderTemp ? zeroConditions.powderTemp : zeroConditions.temperature`
  - `useCorr = profile.zeroUsePowderSensitivity ?? cartridge.usePowderSensitivity`
  - call `ammo.getVelocityForTemp(effectivePowderTemp)` if `useCorr` else use `mv` as-is
- Current velocity (same pattern):
  - `effectivePowderTemp = useDiffPowderTemp ? conditions.powderTemp : conditions.temperature`
  - `useCorr = cartridge.usePowderSensitivity`
  - call `ammo.getVelocityForTemp(effectivePowderTemp)` if `useCorr` else use `mv` as-is
- Both paths now use identical logic — unified

#### `lib/core/models/shot_profile.dart`
- Add `zeroUsePowderSensitivity: bool?` (null = inherit from cartridge)
- Add `zeroUseDiffPowderTemp: bool` (default false — not in a7p)
- Add `useDiffPowderTemp: bool` (default false — moved from Cartridge)
- Update `toJson`/`fromJson`/`copyWith`

#### `lib/core/models/cartridge.dart`
- Remove `useDifferentPowderTemp` field — move to ShotProfile
- Update `toJson`/`fromJson`/`copyWith`

#### `lib/core/a7p/a7p_parser.dart`
- When importing `.a7p`: set `zeroUsePowderSensitivity = true` if `c_t_coeff != 0`

#### `lib/core/providers/shot_profile_provider.dart`
- Add `updateZeroUsePowderSensitivity(bool? value)` method
- Add `updateUseDiffPowderTemp(bool)` and `updateZeroUseDiffPowderTemp(bool)` methods

#### `lib/features/conditions/conditions_vm.dart`
- Read `useDiffPowderTemp` from `ShotProfile` (not `Cartridge`)
- `setDiffPowderTemp(bool)` → `shotProfileProvider.notifier.updateUseDiffPowderTemp()`

---

### Phase 2 — Define Profile Architecture (Conceptual Split)

No new model is needed — clarify responsibilities in code comments and enforce via screen access:

| Data                             | Edited where               | Part of                                       |
| -------------------------------- | -------------------------- | --------------------------------------------- |
| name, rifle, cartridge           | rifle_select_screen wizard | ShotProfile (ballistic profile)               |
| zeroDistance                     | rifle_select_screen wizard | ShotProfile (ballistic profile)               |
| zeroConditions (Atmo)            | rifle_select_screen wizard | ShotProfile (ballistic profile)               |
| zeroUsePowderSensitivity         | rifle_select_screen wizard | ShotProfile (ballistic profile)               |
| zeroUseDiffPowderTemp            | rifle_select_screen wizard | ShotProfile (ballistic profile)               |
| conditions (Atmo)                | Conditions screen          | ShotProfile (runtime state)                   |
| powderTemp (current)             | Conditions screen          | ShotProfile.conditions.powderTemp             |
| useDiffPowderTemp                | Conditions screen          | ShotProfile (runtime state, was in Cartridge) |
| winds, lookAngle, targetDistance | Home screen                | ShotProfile (runtime state)                   |

**Profile library**: each saved `ShotProfile` is stored as a "profile template" — when selected, it sets all ballistic profile fields while preserving current conditions.

---

### Phase 3 — Profile Library Provider

**New file: `lib/core/providers/profile_library_provider.dart`**
- `profileLibraryNotifier` — `AsyncNotifier<List<ShotProfile>>`
- CRUD: `addProfile`, `updateProfile`, `deleteProfile`, `loadAll`
- Persistence: same JSON storage pattern as `rifleLibraryProvider`, `cartridgeLibraryProvider` in `lib/core/providers/library_provider.dart`
- Key: store only the "ballistic" fields (not runtime conditions)

---

### Phase 4 — Rifle Select Screen (ViewModel + View)

#### `lib/features/home/sub_screens/rifle_select/rifle_select_vm.dart`
- `AsyncNotifier<RifleSelectUiState>` with sealed state:
  - `RifleSelectLoading`
  - `RifleSelectReady { List<ShotProfile> profiles, String? activeProfileId }`
- Actions: `selectProfile(id)`, `deleteProfile(id)`, `importFromA7p(file)`
- Add `moveToFirst(id)` to `ProfileLibraryNotifier` — re-orders the persisted list

#### `lib/features/home/sub_screens/rifle_select_screen.dart`
- Replace mock data with real `profileLibraryProvider`
- FAB actions:
  - **Add** → `Routes.profileAdd`
  - **Import** → file picker for `.a7p` → `a7p_parser.dart` → save to library
  - **Export** → serialize current profile → share
  - **Delete** → confirm dialog → `deleteProfile`
- `PageView` initial page = index of `activeProfileId` in the list (not always 0)

#### Profile card layout

```
┌──────────────────────────────────────┐
│  ↑ scrollable ──────────────────── ↑ │
│  ┌──────────────────────────────┐    │
│  │  [Select/replace sight  ↗]  │    │  ← floating button top-right overlay
│  │                              │    │
│  │    <rifle image (future)>    │    │  ← placeholder AspectRatio box
│  │                              │    │
│  │  [Select/replace cart  ↙]   │    │  ← floating button bottom-left overlay
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │ Rifle             [edit btn] │    │
│  │  name / sight height / twist │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │ Cartridge         [edit btn] │    │
│  │  name / MV / BC / weight     │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │ Sight             [edit btn] │    │
│  │  name / manufacturer         │    │
│  └──────────────────────────────┘    │
│  ↓ scrollable end ──────────────── ↓ │
├──────────────────────────────────────┤
│  [Select]          ← if !isActive    │  → selectProfile + moveToFirst + scroll to 0
│  [Go to Calculations] ← if isActive  │  → Navigator.pop()
└──────────────────────────────────────┘
```

#### Navigation from card buttons
| Button | Route |
|---|---|
| Select/replace sight | `Routes.sightSelect` |
| Select/replace cartridge | `Routes.cartridgeSelect` |
| Edit rifle section | `Routes.profileEditRifle` |
| Edit cartridge section | `Routes.profileEditCartridge` |
| Edit sight section | `Routes.profileEditSight` |

#### `ProfileLibraryNotifier.moveToFirst(String id)`
Moves the selected profile to index 0 in the list and persists the new order. Called after `selectProfile` so the active profile is always on the first page next time the screen opens.

---

### Phase 5 — Profile Creation Wizard

**New file: `lib/features/home/sub_screens/rifle_select/profile_wizard.dart`**

Multi-step `Dialog` or pushed route (4 steps):

**Step 1: Source**
- "Create manually" vs "Import from .a7p"
- If `.a7p`: file picker → parse → pre-fill remaining steps

**Step 2: Rifle & Optics**
- Name (text field)
- Sight height (UnitValueField)
- Barrel twist (UnitValueField)
- (Sight selection optional)

**Step 3: Cartridge / Ammo**
- Muzzle velocity (UnitValueField)
- Bullet weight, diameter, length (UnitValueField)
- Drag type (G1/G7/custom) + BC
- Reference powder temp + sensitivity + useSensitivity toggle

**Step 4: Zero Settings**
- Zero distance (UnitValueField)
- Zero atmosphere: temp, pressure, altitude, humidity
- Zero powder temp (UnitValueField) — from `zeroConditions.powderTemp`
- `zeroUsePowderSensitivity` switch (only shown if differs from cartridge default, or as advanced option)

---

### Phase 6 — Conditions Screen: Fix useDiffPowderTemp

Move `useDiffPowderTemp` from `Cartridge` to `ShotProfile.useDiffPowderTemp`:
- Conditions screen reads the flag from `ShotProfile` (not `Cartridge`)
- When user toggles OFF → set `conditions.powderTemp = conditions.temperature` AND persist `useDiffPowderTemp = false`
- When user toggles ON → show powder temp field, persist `useDiffPowderTemp = true`
- Zero wizard uses `zeroUseDiffPowderTemp` independently (same pattern)

---

---

## Route Architecture

### Navigation Tree

```
Profile  (/home/rifle-select)
│  Paging view — each page = one user profile; card shows [Select Cartridge, Select Sight] buttons
│
├── Profile Add  (/home/rifle-select/profile-add)          FAB → Add
│   │  List of user's rifles; buttons [Create, Select from collection]
│   ├── Create Rifle Wizard  (.../rifle-create)
│   └── Select Rifle from Collection  (.../rifle-collection)
│
├── Cartridge Select  (/home/rifle-select/cartridge-select)   card → Select Cartridge
│   │  List of user's cartridges; buttons [Create, Select from collection]
│   ├── Create Cartridge Wizard  (.../create)
│   ├── Select Cartridge from Collection  (.../collection)
│   └── [future] Projectile Select  (.../projectile-select)
│       ├── Create Projectile Wizard  (.../create)
│       └── Select Projectile from Collection  (.../collection)
│
├── Sight Select  (/home/rifle-select/sight-select)           card → Select Sight
│   │  List of user's sights; buttons [Create, Select from collection]
│   ├── Create Sight Wizard  (.../create)
│   └── Select Sight from Collection  (.../collection)
│
├── Profile Edit Rifle  (/home/rifle-select/rifle-edit)       card → Edit Rifle
├── Profile Edit Cartridge  (/home/rifle-select/cartridge-edit)  card → Edit Cartridge
└── Profile Edit Sight  (/home/rifle-select/sight-edit)       card → Edit Sight
```

**Profile selection rule**: a profile can only be activated if both a rifle and a cartridge are bound. If the cartridge is deleted, the profile is disabled until a replacement is selected.

Each select screen (Cartridge Select, Sight Select) also allows editing existing items in the user's collection.

### Routes constants (`lib/router.dart`)

| Constant | Path |
|---|---|
| `Routes.profiles` | `/home/rifle-select` |
| `Routes.profileAdd` | `/home/rifle-select/profile-add` |
| `Routes.profileAddRifleCreate` | `/home/rifle-select/profile-add/rifle-create` |
| `Routes.profileAddRifleCollection` | `/home/rifle-select/profile-add/rifle-collection` |
| `Routes.cartridgeSelect` | `/home/rifle-select/cartridge-select` |
| `Routes.cartridgeCreate` | `/home/rifle-select/cartridge-select/create` |
| `Routes.cartridgeCollection` | `/home/rifle-select/cartridge-select/collection` |
| `Routes.projectileSelect` | `/home/rifle-select/cartridge-select/projectile-select` |
| `Routes.sightSelect` | `/home/rifle-select/sight-select` |
| `Routes.sightCreate` | `/home/rifle-select/sight-select/create` |
| `Routes.sightCollection` | `/home/rifle-select/sight-select/collection` |
| `Routes.profileEditRifle` | `/home/rifle-select/rifle-edit` |
| `Routes.profileEditCartridge` | `/home/rifle-select/cartridge-edit` |
| `Routes.profileEditSight` | `/home/rifle-select/sight-edit` |

---

## Critical Files

| File                                                              | Change                                                                              |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `lib/core/models/shot_profile.dart`                               | Add `zeroUsePowderSensitivity: bool?`, `zeroUseDiffPowderTemp`, `useDiffPowderTemp` |
| `lib/core/models/cartridge.dart`                                  | Remove `useDifferentPowderTemp` (moved to ShotProfile)                              |
| `lib/core/services/ballistics_service_impl.dart`                  | Unified powder sensitivity logic for zero vs current                                |
| `lib/core/a7p/a7p_parser.dart`                                    | Set `zeroUsePowderSensitivity` on import                                            |
| `lib/core/providers/shot_profile_provider.dart`                   | New update methods                                                                  |
| `lib/features/conditions/conditions_vm.dart`                      | Read `useDiffPowderTemp` from `ShotProfile`, not `Cartridge`                        |
| `lib/core/providers/profile_library_provider.dart`                | **NEW** — profile CRUD + persistence                                                |
| `lib/features/home/sub_screens/rifle_select_screen.dart`          | Wire to real data; profile paging                                                   |
| `lib/features/home/sub_screens/rifle_select/rifle_select_vm.dart` | **NEW** — ViewModel                                                                 |
| `lib/features/home/sub_screens/home_sub_screens.dart`             | Stub screens for all new routes                                                     |
| `lib/router.dart`                                                 | Restructured home branch per new route tree                                         |

## Reusable Patterns

- `showUnitEditDialog()` in `lib/shared/widgets/unit_value_field.dart` — reuse for all field editing in wizard
- `UnitValueField` widget — reuse in wizard steps
- Library provider pattern from `lib/core/providers/library_provider.dart` — replicate for profiles
- `BaseScreen` + `ScreenTopBar` — use for wizard as a route if dialog feels cramped

## Verification

1. Import `.a7p` → check `zeroUsePowderSensitivity` is set correctly
2. Create profile manually → wizard produces valid `ShotProfile`
3. Select profile → Home screen shows updated rifle/cartridge name
4. Conditions screen edits do NOT overwrite zero conditions
5. Ballistics recalculation: same powder sensitivity logic path for zero and current velocity
6. Delete/edit profile → library updates and active profile handles gracefully
