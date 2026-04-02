# Plan: Profiles Screen + Data Architecture

## Context

Profiles screen для вибору та керування балістичними профілями. Архітектура вирішує кілька проблем:

1. **Порошкова чутливість** — zero vs current обчислювались непослідовно
2. **Runtime стан** — кожен профіль зберігає свій власний runtime стан (conditions, winds, lookAngle, targetDistance); при перемиканні — відновлюється
3. **Єдиний файл** — `profiles.json` є єдиним джерелом правди; окремий `profile.json` видалено

---

## Storage Architecture

### `~/.eBalistyka/profiles.json` — єдиний файл для профілів

```json
{
  "activeProfileId": "some-uuid",
  "profiles": [
    {
      "id": "...",
      "name": "...",
      "rifle": { ... },
      "cartridge": { ... },
      "sight": { ... },
      "conditions": { ... },
      "winds": [...],
      "lookAngle": 0.0,
      "targetDistance": 100.0,
      "zeroConditions": { ... },
      ...
    }
  ]
}
```

- `activeProfileId` — ID поточного активного профілю
- `profiles` — повний список профілів, кожен зі своїм runtime станом
- Перший профіль у списку = той що відображається першим у PageView
- **Зворотня сумісність**: якщо файл містить plain array `[...]` (старий формат) — читається як список без activeProfileId

### Видалено
- `profile.json` — більше не існує

### Глобальні файли (НЕ прив'язані до профілю)
- `~/.eBalistyka/settings.json` — `AppSettings` (одиниці, теми)
- `~/.eBalistyka/table_settings.json` — `TableSettings`
- `~/.eBalistyka/rifles.json` — колекція rifle
- `~/.eBalistyka/cartridges.json` — колекція cartridge
- `~/.eBalistyka/sights.json` — колекція sight

---

## Data Ownership

| Data | Belongs to | Edited where |
|---|---|---|
| name, rifle, cartridge, sight | `ShotProfile` (ballistic) | Profiles wizard |
| zeroDistance, zeroConditions | `ShotProfile` (ballistic) | Profiles wizard |
| zeroUsePowderSensitivity, zeroUseDiffPowderTemp | `ShotProfile` (ballistic) | Profiles wizard |
| conditions (Atmo) | `ShotProfile` (runtime, **per-profile**) | Conditions screen |
| useDiffPowderTemp | `ShotProfile` (runtime, **per-profile**) | Conditions screen |
| winds, lookAngle, targetDistance | `ShotProfile` (runtime, **per-profile**) | Home screen |
| AppSettings, TableSettings | Global | Settings screen |

---

## Implemented Phases

### ✅ Phase 1 — Fix Service Logic: Powder Sensitivity

**Проблема**: zero та current velocity не мали незалежного контролю порошкової чутливості.

**Рішення**:
1. `powderSensitivity` залишається в `Cartridge` — фізична властивість патрону
2. Додано до `ShotProfile`:
   - `zeroUsePowderSensitivity: bool?` (null = inherit from cartridge)
   - `zeroUseDiffPowderTemp: bool` (default `false`)
   - `useDiffPowderTemp: bool` (default `false`, перенесено з `Cartridge`)
3. `useDifferentPowderTemp` видалено з `Cartridge`

**Файли**:
- `lib/core/models/shot_profile.dart` — нові поля, `copyWith`/`toJson`/`fromJson`
- `lib/core/models/cartridge.dart` — видалено `useDifferentPowderTemp`
- `lib/core/services/ballistics_service_impl.dart` — уніфікована логіка для zero vs current
- `lib/core/providers/shot_profile_provider.dart` — `updateZeroUsePowderSensitivity`, `updateUseDiffPowderTemp`, `updateZeroUseDiffPowderTemp`
- `lib/features/conditions/conditions_vm.dart` — читає `useDiffPowderTemp` з `ShotProfile`
- `lib/core/a7p/a7p_parser.dart` — встановлює `zeroUsePowderSensitivity = true` при `c_t_coeff != 0`

---

### ✅ Phase 2 — Profile Architecture (Conceptual Split)

Межі відповідальності задокументовані в таблиці вище і відображені в UI через розмежування екранів.

---

### ✅ Phase 3 — Profile Library Provider + Storage Refactor

**`lib/core/storage/app_storage.dart`** — інтерфейс:
- Видалено: `loadCurrentProfile`, `saveCurrentProfile`
- Додано: `loadActiveProfileId()`, `saveActiveProfileId(String id)`
- Додано: `saveProfilesOrdered(List<ShotProfile>)` — для `moveToFirst`
- Без змін: `loadProfiles()`, `saveProfile(p)`, `deleteProfile(id)`

**`lib/core/storage/json_file_storage.dart`** — реалізація:
- `_readProfilesFile()` — читає `profiles.json` як map `{activeProfileId, profiles}`; backward-compat зі старим array форматом
- `_writeProfilesFile(profiles, activeId)` — пише в новому форматі
- `exportAll` / `importAll` оновлені під новий формат

**`lib/core/providers/profile_library_provider.dart`**:
- `ProfileLibraryNotifier` — `AsyncNotifier<List<ShotProfile>>`
- `save(p)` — upsert в список + persist
- `delete(id)` — видалення
- `moveToFirst(id)` — переміщує профіль на першу позицію, персистить новий порядок
- Seed: 3 профілі при першому запуску (`seedShotProfiles` з `seed_data.dart`)

---

### ✅ Phase 4 — Profiles Screen (ViewModel + View)

**Файли** (відрізняються від початкового плану):

| Плановий шлях | Фактичний шлях |
|---|---|
| `profile_select/profile_select_vm.dart` | `profiles/profiles_vm.dart` |
| `profile_select_screen.dart` | `profiles_screen.dart` |

**`lib/core/providers/shot_profile_provider.dart`** — повністю переписано:
- `build()`: читає `activeProfileId` → знаходить профіль у `profiles.json` → повертає його
- `selectProfile(ShotProfile)`: відновлює **повний** збережений стан профілю (включно з runtime); зберігає `activeProfileId`
- `_update(fn)`: зберігає runtime зміни назад у `profiles.json` через `saveProfile(updated)` — **runtime стан персистується на рівні кожного профілю**

**`lib/features/home/sub_screens/profiles/profiles_vm.dart`**:
- `ProfileCardData` — display model з усіма форматованими рядками (будується у ViewModel через `UnitFormatter`, не у widget)
- `ProfilesUiState` sealed: `ProfilesLoading` | `ProfilesReady { List<ProfileCardData>, activeProfileId }`
- `build()`: використовує `ref.read` (не `watch`) для `shotProfileProvider` — уникає async rebuild cascade при зміні активного профілю
- `selectProfile(id)`: → `shotProfileProvider.selectProfile` → `profileLibraryProvider.moveToFirst` → оновлює стан ViewModel напряму (без повного rebuild)
- Provider: `rifleSelectVmProvider`

**`lib/features/home/sub_screens/profiles_screen.dart`**:
- `ConsumerStatefulWidget` підключений до `rifleSelectVmProvider`
- FAB: Add / Remove (з confirm dialog) / Import / Export
- `PageView` + dot indicator
- `_onSelect` використовує `context.pop()` (go_router)

**`lib/features/home/sub_screens/profiles/widgets/profile_card.dart`**:
- `StatelessWidget`, приймає `ProfileCardData` — нуль форматування у widget
- `_ProfileControlTile(profileId)` — унікальний `heroTag` per профіль (`'sight_btn_$profileId'`, `'cartridge_btn_$profileId'`) — виправлено фліккер при PageView scroll

**`lib/core/models/seed_data.dart`**:
- `seedShotProfiles` — список з 3 профілів: UKROP 250GR SMK, Hornady 250GR BTHP, Lapua 300GR SMK

---

### 🔲 Phase 5 — Profile Creation Wizard

**`lib/features/home/sub_screens/profiles/profile_wizard.dart`** — не реалізовано

Multi-step route або Dialog (4 кроки):

**Крок 1: Джерело**
- "Створити вручну" vs "Імпортувати з .a7p"
- Якщо `.a7p`: file picker → parser → pre-fill наступних кроків

**Крок 2: Rifle & Optics**
- Name, sight height, barrel twist (`UnitValueField`)

**Крок 3: Cartridge / Ammo**
- MV, weight, diameter, length (`UnitValueField`)
- Drag type (G1/G7/custom) + BC
- Порошкова temp + чутливість + toggle

**Крок 4: Zero Settings**
- Zero distance (`UnitValueField`)
- Zero атмосфера: temp, pressure, altitude, humidity
- Zero powder temp + `zeroUsePowderSensitivity` switch

---

## Route Architecture

### Navigation Tree

```
Profiles  (/home/rifle-select)
│  PageView — кожна сторінка = один профіль
│
├── Profile Add  (/home/rifle-select/profile-add)       FAB → Add
│   ├── Create Rifle Wizard  (.../rifle-create)
│   └── Select Rifle from Collection  (.../rifle-collection)
│
├── Cartridge Select  (/home/rifle-select/cartridge-select)   card → Select Cartridge
│   ├── Create Cartridge Wizard  (.../create)
│   ├── Select Cartridge from Collection  (.../collection)
│   └── [future] Projectile Select  (.../projectile-select)
│
├── Sight Select  (/home/rifle-select/sight-select)     card → Select Sight
│   ├── Create Sight Wizard  (.../create)
│   └── Select Sight from Collection  (.../collection)
│
├── Profile Edit Rifle  (/home/rifle-select/rifle-edit)
├── Profile Edit Cartridge  (/home/rifle-select/cartridge-edit)
└── Profile Edit Sight  (/home/rifle-select/sight-edit)
```

### Routes constants (`lib/router.dart`)

| Константа | Шлях |
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

| Файл | Статус | Опис |
|---|---|---|
| `lib/core/models/shot_profile.dart` | ✅ | `zeroUsePowderSensitivity`, `zeroUseDiffPowderTemp`, `useDiffPowderTemp` |
| `lib/core/models/cartridge.dart` | ✅ | Видалено `useDifferentPowderTemp` |
| `lib/core/models/seed_data.dart` | ✅ | 3 seed-профілі у `seedShotProfiles` |
| `lib/core/services/ballistics_service_impl.dart` | ✅ | Уніфікована логіка порошкової чутливості |
| `lib/core/a7p/a7p_parser.dart` | ✅ | `zeroUsePowderSensitivity` при імпорті |
| `lib/core/storage/app_storage.dart` | ✅ | Новий інтерфейс: `loadActiveProfileId`, `saveActiveProfileId`, `saveProfilesOrdered` |
| `lib/core/storage/json_file_storage.dart` | ✅ | `profiles.json` як `{activeProfileId, profiles:[...]}`, backward-compat |
| `lib/core/providers/shot_profile_provider.dart` | ✅ | `build` з бібліотеки за ID; `_update` → `saveProfile`; `selectProfile` відновлює повний стан |
| `lib/core/providers/profile_library_provider.dart` | ✅ | CRUD + `moveToFirst` + seed 3 профілі |
| `lib/features/conditions/conditions_vm.dart` | ✅ | `useDiffPowderTemp` з `ShotProfile` |
| `lib/features/home/sub_screens/profiles/profiles_vm.dart` | ✅ | `ProfileCardData`, sealed state, без rebuild cascade |
| `lib/features/home/sub_screens/profiles_screen.dart` | ✅ | PageView, FAB, `context.pop()` |
| `lib/features/home/sub_screens/profiles/widgets/profile_card.dart` | ✅ | Pure widget, унікальні heroTag |
| `lib/features/home/sub_screens/home_sub_screens.dart` | 🔲 Stubs | Всі під-екрани — `StubScreen` |
| `lib/router.dart` | ✅ | Повне дерево маршрутів |
| `lib/features/home/sub_screens/profiles/profile_wizard.dart` | 🔲 TODO | Phase 5 |

---

## Pending Items (черга)

### Phase 4 — залишок
1. `ProfilesScreen` — початкова сторінка `PageView` = індекс активного профілю (зараз завжди 0)

### Phase 5 — Profile Creation Wizard
2. FAB "Add" → wizard (4 кроки)
3. FAB "Import" → file picker `.a7p` → `a7p_parser` → `saveProfile`
4. FAB "Export" → serialize + share

### Edit screens
5. `RifleEditScreen` — редагування rifle в профілі
6. `CartridgeEditScreen` — редагування cartridge в профілі
7. `SightEditScreen` — редагування sight в профілі
8. `CartridgeSelectScreen` — вибір/створення cartridge
9. `SightSelectScreen` — вибір/створення sight

---

## Migration Note

При оновленні на нову архітектуру зберігання:
```bash
rm ~/.eBalistyka/profile.json ~/.eBalistyka/profiles.json
```
Застосунок автоматично seed-ує 3 профілі при наступному запуску.

---

## Reusable Patterns

- `showUnitEditDialog()` в `lib/shared/widgets/unit_value_field.dart` — для wizard
- `UnitValueField` — для wizard steps
- `BaseScreen` + `ScreenTopBar` — для wizard як route
- Display model pattern (`ProfileCardData`) — форматування у ViewModel, widget лише відображає

---

## Verification

1. ✅ Імпорт `.a7p` → `zeroUsePowderSensitivity` встановлюється коректно
2. ✅ Вибір профілю → Home screen показує rifle/cartridge/sight обраного профілю
3. ✅ Зміна conditions на одному профілі → при поверненні до нього відновлюється
4. ✅ Умови Conditions screen НЕ перезаписують zero conditions
5. ✅ Балістичний розрахунок: уніфікована логіка порошкової чутливості
6. ✅ Видалення профілю → бібліотека оновлюється
7. ✅ Select профілю → `moveToFirst` → наступного разу активний профіль перший
8. ✅ Фліккер при PageView scroll — виправлено унікальними `heroTag`
9. 🔲 Створення профілю вручну → wizard → валідний `ShotProfile`
10. 🔲 Edit rifle/cartridge/sight → зміни персистуються
