# Profiles & Selection Architecture

> Об'єднаний документ (замінює `RIFLE_SELECT_PLAN.md` і `plan_profile_select_architecture.md`)

---

## Поточний стан

### Реалізовано (Phase 1–4)
- Phase 1 ✅ — Powder sensitivity: `zeroUsePowderSensitivity`, `zeroUseDiffPowderTemp`, `useDiffPowderTemp` у `ShotProfile`
- Phase 2 ✅ — Data ownership: межі відповідальності між ballistic / runtime / global даними
- Phase 3 ✅ — Profile Library Provider + Storage refactor: `profiles.json` як `{activeProfileId, profiles:[...]}`, `moveToFirst`, backward-compat
- Phase 4 ✅ — Profiles Screen: `ProfilesVm`, `ProfilesScreen`, `ProfileCardData`, `profile_card.dart`
- `rifle_wizard_screen.dart` ✅ — повністю реалізований
- `home_sub_screens.dart` 🔲 — всі під-екрани як заглушки (`StubScreen`)
- Phase 5 ✅ - Зроблено, але: Один тест ламається - виправити! Цей документ окумент не оновлено - перед фазою 6 оновити!
---

## Storage Architecture

### Файли

```
~/.eBalistyka/
  data.json          ← всі юзерські дані (профілі, патрони, прицілі)
  settings.json      ← AppSettings (одиниці, теми)
  collection.json    ← вбудована колекція (кеш з мережі або assets fallback)
```

> `rifles.json`, `bullets.json`, `cartridges.json`, `sights.json`, `profiles.json` — **не існують** як окремі файли. Все зберігається в `data.json`. Rifle — embedded у профіль. Bullet — cartridge з `type: bullet`.

---

### `data.json`

```json
{
  "activeProfileId": "some-uuid",
  "profiles": [
    {
      "id": "...",
      "name": "...",
      "rifle": { "id": "...", "name": "...", "sightHeight": 8.5, "twist": 10.0, "caliberDiameter": 0.338, ... },
      "cartridgeId": "some-uuid-or-null",
      "sightId": "some-uuid-or-null",
      "conditions": { ... },
      "winds": [...],
      "lookAngle": 0.0,
      "targetDistance": 100.0,
      "usePowderSensitivity": false,
      "useDiffPowderTemp": false
    }
  ],
  "cartridges": [
    {
      "id": "...",
      "type": "cartridge",
      "name": "...",
      "projectile": { ... },
      "mv": 888.0,
      "powderTemp": 15.0,
      "powderSensitivity": 0.02,
      "usePowderSensitivity": true,
      "zeroDistance": 100.0,
      "zeroConditions": { "temperature": 15.0, "pressure": 1000.0, "humidity": 0.47, "powderTemp": 15.0 },
      "zeroUsePowderSensitivity": true,
      "zeroUseDiffPowderTemp": false
    },
    {
      "id": "...",
      "type": "bullet",
      "name": "...",
      "projectile": { ... },
      "mv": 850.0,
      "zeroDistance": 100.0,
      "zeroConditions": { ... }
    }
  ],
  "sights": [
    {
      "id": "...",
      "name": "...",
      "sightHeight": 50.0,
      "zeroElevation": 0.0
    }
  ]
}
```

> Bullet = cartridge з `type: bullet`. MV **завжди required** у wizard (навіть для bullet з вбудованої колекції де MV = null — юзер зобов'язаний заповнити).

Backward-compat: при читанні старого формату (`profiles.json` як окремий файл або plain array) — мігруємо автоматично.

---

## Data Ownership

| Дані                                            | Належить                         | Редагується де                    |
| ----------------------------------------------- | -------------------------------- | --------------------------------- |
| name, rifle                                     | `ShotProfile`                    | Profile wizard                    |
| cartridgeId, sightId                            | `ShotProfile`                    | Profile card (вибір з бібліотеки) |
| conditions (Atmo)                               | `ShotProfile` (runtime, per-app) | Conditions screen                 |
| usePowderSensitivity, useDiffPowderTemp         | `ShotProfile` (runtime, per-app) | Conditions screen                 |
| winds, lookAngle, targetDistance                | `ShotProfile` (runtime, per-app) | Home screen                       |
| zeroDistance, zeroConditions                    | `Cartridge`                      | Cartridge wizard                  |
| zeroUsePowderSensitivity, zeroUseDiffPowderTemp | `Cartridge`                      | Cartridge wizard                  |
| Rifle (вся модель)                              | embedded у `ShotProfile`         | Rifle wizard (з profile card)     |
| Cartridge (вся модель)                          | `cartridges.json`                | Cartridge wizard                  |
| Sight (вся модель)                              | `sights.json`                    | Sight wizard                      |
| AppSettings                                     | Global                           | Settings screen                   |

---

## ShotProfile Model

Три категорії полів з різною стратегією зберігання:

```dart
class ShotProfile {
  final String id;
  final String name;

  // ── Embedded у JSON профілю ───────────────────────────────────────────────
  // Зберігаються як вкладені об'єкти у profiles.json.
  // Відновлюються при перезапуску / зміні профілю.

  final Rifle rifle;              // гвинтівка — завжди belongs to profile
  final AtmoData conditions;      // поточні умови стрільби
  final List<WindData> winds;
  final Angular lookAngle;
  final Distance targetDistance;
  final bool usePowderSensitivity; // поточний постріл
  final bool useDiffPowderTemp;    // поточний постріл

  // ── References до бібліотек (тільки id у JSON) ────────────────────────────
  // Зберігаються як рядок-ідентифікатор у profiles.json.
  // null = не вибрано.

  final String? cartridgeId;
  final String? sightId;

  // ── Resolved об'єкти (НЕ зберігаються в JSON) ────────────────────────────
  // Заповнюються тільки для активного профілю через shotProfileProvider.
  // profileLibraryProvider зберігає профілі без resolve (cartridge == null).

  final Cartridge? cartridge;
  final Sight? sight;
}
```

**Cartridge model** додатково містить zero-related поля — все що стосується
пристрілювання належить патрону, не профілю:

```dart
class Cartridge {
  // ... існуючі поля ...
  final CartridgeType type;            // cartridge | bullet
  final Distance zeroDistance;
  final AtmoData zeroConditions;
  final bool zeroUsePowderSensitivity;
  final bool zeroUseDiffPowderTemp;
}

enum CartridgeType { cartridge, bullet }
```

**Cartridge model** додатково містить zero-related поля:
```dart
class Cartridge {
  // ... існуючі поля ...
  final Distance zeroDistance;
  final AtmoData zeroConditions;
  final bool zeroUsePowderSensitivity;
  final bool zeroUseDiffPowderTemp;
  final CartridgeType type; // cartridge | bullet
}

enum CartridgeType { cartridge, bullet }
```

---

## Resolve Strategy

**Тільки активний профіль резолвиться повністю.**

`shotProfileProvider` при завантаженні / зміні активного профілю:
1. Читає `ShotProfile` з `profileLibraryProvider` (має `cartridgeId`, `sightId`, але `cartridge == null`, `sight == null`)
2. Lookup в `cartridgeLibraryProvider` по `cartridgeId`
3. Lookup в `sightLibraryProvider` по `sightId`
4. Повертає `ShotProfile` з заповненими `cartridge?` і `sight?`

`profileLibraryProvider` — зберігає список профілів **без** resolve (тільки ids).

**Broken reference handling:**
- `cartridgeId` не знайдено в бібліотеці → обнуляємо `cartridgeId` в профілі → toast з помилкою "Cartridge not found, please select again"
- `sightId` не знайдено → аналогічно

---

## isReadyForCalculation

```dart
bool get isReadyForCalculation =>
  cartridge != null &&
  cartridge!.mv.raw > 0 &&
  cartridge!.projectile.coefRows.isNotEmpty &&
  cartridge!.projectile.diameter.raw > 0 &&
  cartridge!.projectile.weight.raw > 0 &&
  rifle.twist.raw != 0;
```

Sight — необов'язковий для розрахунку (sightHeight в rifle використовується як fallback = 0 якщо sight не вибрано або не має sightHeight).

Якщо `!isReadyForCalculation` → Home / Conditions / Tables показують `IncompleteBanner` з посиланням на ProfilesScreen.

---

## Вбудована vs Користувацька колекції

### Дві точки доступу

**Вбудована колекція** (`builtin: true`) — поставляється з додатком (assets або тег git). Доступна виключно через "From Collection" → `CollectionBrowserScreen`. При виборі — запис **копіюється** у бібліотеку юзера (новий UUID, `builtin: false`), і одразу прив'язується до профілю.

**Бібліотека юзера** (`builtin: false`) — все що юзер створив, імпортував, або скопіював з вбудованої колекції.

```
My Cartridges / My Sights              Built-in Collection (hidden)
─────────────────────────────          ──────────────────────────────
 [.338LM UKROP 250GR SMK]  ←copy────   🔒 .338LM UKROP 250GR SMK
 [Hornady 285 copy]        ←copy────   🔒 Hornady 285GR ELD-M
 [My custom load]                      🔒 ...

  "From Collection" btn ─────────────► CollectionBrowserScreen
```

---

## Wizard Screen — Концепція

### RifleWizardScreen

Приймає `Rifle?` (null = новий вручну). Повертає `Rifle` через `Navigator.pop(rifle)`.

| Поле            | Новий вручну           | Copy from collection   | Edit existing          |
| --------------- | ---------------------- | ---------------------- | ---------------------- |
| name            | редагується            | редагується            | редагується            |
| caliberDiameter | редагується            | **readonly**           | **readonly**           |
| sightHeight     | редагується            | редагується            | редагується            |
| twist           | редагується            | редагується            | редагується            |
| twistDirection  | редагується            | редагується            | редагується            |
| barrelLength    | редагується (optional) | редагується (optional) | редагується (optional) |

> Twist direction: позитивне значення = правий твіст, від'ємне = лівий. Це стосується як вбудованої колекції так і користувацьких записів.

### CartridgeWizardScreen

Приймає `Cartridge?` + `CartridgeType`. MV — **завжди required** (навіть для `type: bullet`). Повертає `Cartridge` через `Navigator.pop(cartridge)`.

Секції wizard:
- Ballistics (dragType, BC / multi-BC / custom table, bullet weight/diameter/length)
- Muzzle velocity (mv, powderTemp, powderSensitivity)
- Zero (zeroDistance, zeroConditions, zeroUsePowderSensitivity, zeroUseDiffPowderTemp)

**Wizard не знає контексту виклику** — просто редагує і повертає результат. Логіка збереження — у caller.

Після збереження у wizard → зберігається в `cartridges.json` (My Cartridges) → автоматично прив'язується до профілю через `cartridgeId`.

### SightWizardScreen

Аналогічно, повертає `Sight`. Після збереження → `sights.json` → прив'язується до профілю.

---

## Flow Branches

### Flow 1: Новий профіль

```
ProfilesScreen
  └─ FAB → "Add"
      └─ Enter profile name dialog
          └─ ProfileAddScreen
              └─ Вибір rifle:
                  ├─ "From Collection" → RifleCollectionScreen
                  │     └─ Select → RifleWizardScreen (pre-filled, caliberDiameter readonly)
                  │           └─ Save → rifle embedded у новий ShotProfile
                  └─ "Create manually" → RifleWizardScreen (порожній, всі поля редагуються)
                        └─ Save → rifle embedded у новий ShotProfile
```

Профіль створюється з rifle, але **без** cartridge і sight (cartridgeId = null, sightId = null).

### Flow 2: Вибір / зміна Cartridge з ProfileCard

```
ProfileCard
  └─ "Select Cartridge" btn
      └─ CartridgeSelectScreen
          ├─ My Cartridges list
          │   ├─ Select item → прив'язати cartridgeId до профілю
          │   └─ Cog → Edit / Duplicate / Delete
          ├─ "Create Cartridge" btn → CartridgeWizardScreen (порожній, type: cartridge)
          │     └─ Save → зберегти в cartridges.json → прив'язати до профілю
          ├─ "Create Bullet" btn → CartridgeWizardScreen (порожній, type: bullet)
          │     └─ Save → зберегти в cartridges.json → прив'язати до профілю
          └─ "From Collection" btn → CartridgeCollectionScreen
                └─ Select → CartridgeWizardScreen (pre-filled)
                      └─ Save → copy до cartridges.json → прив'язати до профілю
```

### Flow 3: Вибір / зміна Sight з ProfileCard

```
ProfileCard
  └─ "Select Sight" btn
      └─ SightSelectScreen
          ├─ My Sights list
          │   ├─ Select item → прив'язати sightId до профілю
          │   └─ Cog → Edit / Duplicate / Delete
          ├─ "Create Sight" btn → SightWizardScreen (порожній)
          │     └─ Save → зберегти в sights.json → прив'язати до профілю
          └─ "From Collection" btn → SightCollectionScreen
                └─ Select → SightWizardScreen (pre-filled)
                      └─ Save → copy до sights.json → прив'язати до профілю
```

### Flow 4: Edit Rifle з ProfileCard

```
ProfileCard
  └─ "Edit Rifle" btn
      └─ RifleWizardScreen (pre-filled, caliberDiameter readonly)
          └─ Save → оновити rifle embedded у ShotProfile
```

### Flow 5: Duplicate Profile

```
ProfilesScreen
  └─ FAB → "Duplicate"
      └─ Enter new profile name dialog
          └─ Копія поточного профілю з новим UUID
             (rifle копіюється embedded, cartridgeId/sightId — ті самі references)
```

---

## Shared UI Components

### Tile поведінка

```
ItemListView (generic, reusable)
  └─ CartridgeTile  ← reusable tile для Cartridge/Bullet
  └─ SightTile      ← reusable tile для Sight
```

- Якщо `builtin: true` → **без cog btn**, є кнопка **Select**
- Якщо `builtin: false` (user data) → є **cog btn** (⚙️) для Edit / Duplicate / Delete, є кнопка **Select**
- Tap на tile → нічого (тільки кнопка Select виконує дію)

---

## Картка профілю (ProfileCard layout)

```
┌──────────────────────────────────────┐
│                                      │
│   [Placeholder / фото гвинтівки]     │  ← ~160px, назва профілю по краях
│                                      │
├──────────────────────────────────────┤
│  🔫 Cartridge   [назва патрону  ›]   │  ← tap → CartridgeSelectScreen
│  🔭 Sight       [назва прицілу  ›]   │  ← tap → SightSelectScreen
├──────────────────────────────────────┤
│  ── Rifle ─────────────────────      │
│  Caliber        .338"                │
│  Sight height   8.5 mm               │
│  Twist          1:10 inch            │
│                     [Edit Rifle ›]   │  ← → Flow 4
├──────────────────────────────────────┤
│  ── Cartridge ─────────────────      │
│  MV             888 m/s              │
│  Bullet         250 gr · .338"       │
│  Drag model     G7 · BC 0.314        │
│  Zero dist      100 m                │
│              [Edit Cartridge ›]      │  ← → CartridgeWizardScreen
├──────────────────────────────────────┤
│  ── Sight ──────────────────────     │
│  [назва або "Not selected"]          │
│                  [Edit Sight ›]      │  ← → SightWizardScreen
├──────────────────────────────────────┤
│              [  Select  ]            │  ← тільки якщо не активний
└──────────────────────────────────────┘
```

Якщо cartridge або sight не вибрано → показуємо "Not selected" + кнопку вибору.
Активний профіль: кнопка "Select" → `✓ Active` + підсвічування картки.

---

## IncompleteBanner

Показується на Home / Conditions / Tables якщо `!profile.isReadyForCalculation`:

```
⚠ Profile incomplete — cartridge not selected.
  [Go to Profiles]
```

Розрахунок не запускається поки профіль не повний.

---

## Route Architecture

```
ProfilesScreen  (/home/profiles)
│  PageView — кожна сторінка = один профіль
│
├── ProfileAddScreen  (/home/profiles/profile-add)
│   ├── "From Collection" → RifleCollectionScreen  (.../rifle-collection)
│   └── "Create manually" → RifleWizardScreen      (.../rifle-create)
│
├── RifleWizardScreen  (/home/profiles/rifle-edit)   [Flow 4 — edit]
│
├── CartridgeSelectScreen  (/home/profiles/cartridge-select)
│   ├─ My Cartridges + My Bullets list
│   ├─ "Create Cartridge" → CartridgeWizardScreen   (.../cartridge-create)
│   ├─ "Create Bullet"    → CartridgeWizardScreen   (.../bullet-create)
│   └─ "From Collection"  → CartridgeCollectionScreen (.../cartridge-collection)
│         └─ Select → CartridgeWizardScreen          (.../cartridge-wizard)
│
├── CartridgeWizardScreen  (/home/profiles/cartridge-edit)  [edit flow]
│
├── SightSelectScreen  (/home/profiles/sight-select)
│   ├─ My Sights list
│   ├─ "Create Sight"    → SightWizardScreen         (.../sight-create)
│   └─ "From Collection" → SightCollectionScreen     (.../sight-collection)
│         └─ Select → SightWizardScreen              (.../sight-wizard)
│
└── SightWizardScreen  (/home/profiles/sight-edit)   [edit flow]
```

### Routes constants

| Константа                    | Шлях                                                   |
| ---------------------------- | ------------------------------------------------------ |
| `Routes.profiles`            | `/home/profiles`                                       |
| `Routes.profileAdd`          | `/home/profiles/profile-add`                           |
| `Routes.rifleCreate`         | `/home/profiles/profile-add/rifle-create`              |
| `Routes.rifleCollection`     | `/home/profiles/profile-add/rifle-collection`          |
| `Routes.rifleEdit`           | `/home/profiles/rifle-edit`                            |
| `Routes.cartridgeSelect`     | `/home/profiles/cartridge-select`                      |
| `Routes.cartridgeCreate`     | `/home/profiles/cartridge-select/cartridge-create`     |
| `Routes.bulletCreate`        | `/home/profiles/cartridge-select/bullet-create`        |
| `Routes.cartridgeCollection` | `/home/profiles/cartridge-select/cartridge-collection` |
| `Routes.cartridgeWizard`     | `/home/profiles/cartridge-select/cartridge-wizard`     |
| `Routes.cartridgeEdit`       | `/home/profiles/cartridge-edit`                        |
| `Routes.sightSelect`         | `/home/profiles/sight-select`                          |
| `Routes.sightCreate`         | `/home/profiles/sight-select/sight-create`             |
| `Routes.sightCollection`     | `/home/profiles/sight-select/sight-collection`         |
| `Routes.sightWizard`         | `/home/profiles/sight-select/sight-wizard`             |
| `Routes.sightEdit`           | `/home/profiles/sight-edit`                            |

---

## Built-in Collection Asset

Файл: `assets/json/collection.json` (зареєстрований у `pubspec.yaml`)

Структура:
```
{
  "calibers": [...],      // список калібрів (id, diameter, caliberName)
  "weapon": [...],        // built-in rifles
  "cartridges": [...],    // built-in cartridges (повна балістична модель + zeroConditions)
  "projectiles": [...],   // built-in bullets (muzzleVelocity: null — юзер заповнює у wizard)
  "sights": [...]         // built-in sights
}
```

> Секція `"units"` існує лише у dev-файлі як довідка. В остаточній колекції її не буде.

**Twist direction:** позитивне `rTwist` = правий твіст, від'ємне = лівий. Стосується всіх записів.

**Стратегія завантаження:**
1. `~/.eBalistyka/collection.json` — оновлена версія з мережі (якщо є)
2. `assets/json/collection.json` — бандл (завжди доступний, fallback)

---

## Critical Files

| Файл                                                               | Статус                  | Опис                                                                                                                                                      |
| ------------------------------------------------------------------ | ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/core/models/shot_profile.dart`                                | 🔧 потребує рефакторингу | Додати `cartridgeId?`, `sightId?`, `cartridge?`, `sight?`; видалити `zeroDistance`, `zeroConditions`, `zeroUsePowderSensitivity`, `zeroUseDiffPowderTemp` |
| `lib/core/models/cartridge.dart`                                   | 🔧 потребує рефакторингу | Додати `CartridgeType`, `zeroDistance`, `zeroConditions`, `zeroUsePowderSensitivity`, `zeroUseDiffPowderTemp`                                             |
| `lib/core/models/rifle.dart`                                       | ✅                       | `caliberDiameter?`, `barrelLength?`, getter `isRightHandTwist`                                                                                            |
| `lib/core/models/sight.dart`                                       | ✅                       | Базова модель                                                                                                                                             |
| `lib/core/models/projectile.dart`                                  | ✅                       | Модель кулі                                                                                                                                               |
| `lib/core/models/field_constraints.dart`                           | ✅                       | `FC.barrelLength`                                                                                                                                         |
| `lib/core/models/unit_settings.dart`                               | ✅                       | `barrelLength: Unit`                                                                                                                                      |
| `lib/core/models/seed_data.dart`                                   | 🔧 потребує рефакторингу | Оновити seed профілі під нову структуру                                                                                                                   |
| `lib/core/formatting/unit_formatter.dart`                          | ✅                       | `barrelLength()`                                                                                                                                          |
| `lib/core/services/ballistics_service_impl.dart`                   | 🔧 потребує рефакторингу | Zero дані тепер з `cartridge`, не з `profile`                                                                                                             |
| `lib/core/a7p/a7p_parser.dart`                                     | 🔧 потребує рефакторингу | Zero дані → `Cartridge`                                                                                                                                   |
| `lib/core/storage/app_storage.dart`                                | 🔧 потребує рефакторингу | Перейти на `data.json`; видалити rifles CRUD; об'єднати profiles/cartridges/sights в один файл                                                            |
| `lib/core/storage/json_file_storage.dart`                          | 🔧 потребує рефакторингу | Аналогічно; backward-compat міграція зі старих окремих файлів                                                                                             |
| `lib/core/collection/collection_parser.dart`                       | 🔧 потребує рефакторингу | `CartridgeType`, zero дані в cartridge                                                                                                                    |
| `lib/core/providers/shot_profile_provider.dart`                    | 🔧 потребує рефакторингу | Resolve cartridge/sight при завантаженні активного профілю                                                                                                |
| `lib/core/providers/profile_library_provider.dart`                 | ✅                       | CRUD + `moveToFirst` + seed                                                                                                                               |
| `lib/core/providers/library_provider.dart`                         | 🔧 потребує рефакторингу | Видалити `rifleLibraryProvider`; залишити `cartridgeLibraryProvider`, `sightLibraryProvider`                                                              |
| `lib/core/providers/builtin_collection_provider.dart`              | ✅                       | assets → fallback                                                                                                                                         |
| `lib/features/home/sub_screens/profiles/profiles_vm.dart`          | 🔧 потребує рефакторингу | `ProfileCardData` під нову структуру                                                                                                                      |
| `lib/features/home/sub_screens/profiles_screen.dart`               | ✅                       | PageView, FAB                                                                                                                                             |
| `lib/features/home/sub_screens/profiles/widgets/profile_card.dart` | 🔧 потребує рефакторингу | Навігація через callbacks, не `context.go` у widget                                                                                                       |
| `lib/features/home/sub_screens/rifle_wizard_screen.dart`           | ✅                       | Повністю реалізований                                                                                                                                     |
| `lib/features/home/sub_screens/home_sub_screens.dart`              | 🔲 stubs                 | Всі під-екрани — `StubScreen`                                                                                                                             |
| `lib/router.dart`                                                  | 🔧 потребує оновлення    | Нові routes константи                                                                                                                                     |
| `assets/json/collection.json`                                      | ✅                       | Вбудована колекція                                                                                                                                        |

---

## Phases — Що залишилось

### Phase 5 — Рефакторинг моделей і провайдерів 

**Мета:** привести моделі і провайдери у відповідність до нової архітектури перед реалізацією UI.

- `Cartridge` model: додати `CartridgeType`, `zeroDistance`, `zeroConditions`, `zeroUsePowderSensitivity`, `zeroUseDiffPowderTemp`; оновити `toJson`/`fromJson`; backward-compat
- `ShotProfile` model: додати `cartridgeId?`, `sightId?`, `cartridge?`, `sight?`; видалити zero-related поля; оновити `toJson`/`fromJson`; backward-compat
- `shotProfileProvider`: resolve cartridge/sight при завантаженні активного профілю; broken ref handling (обнулити id + toast)
- `library_provider.dart`: видалити `rifleLibraryProvider`
- `app_storage.dart` + `json_file_storage.dart`: видалити rifle CRUD
- `ballistics_service_impl.dart`: zero дані брати з `profile.cartridge`, не з `profile`
- `a7p_parser.dart`: zero дані → `Cartridge`
- `collection_parser.dart`: парсити `CartridgeType`, zero дані в cartridge
- `seed_data.dart`: оновити під нову структуру
- `isReadyForCalculation` геттер у `ShotProfile`

---

### Phase 6 — Profile Add Screen + Rifle Selection

**`ProfileAddScreen`** — вибір джерела rifle:
- "From Collection" btn → `RifleCollectionScreen`
- "Create manually" btn → `RifleWizardScreen` (порожній, всі поля редагуються)

**`RifleCollectionScreen`** — список builtin rifle (з 🔒 і кнопкою Select):
- Select → `RifleWizardScreen` (pre-filled, caliberDiameter readonly)
- Save → rifle embedded у новий `ShotProfile`

**Shared components:**
- `RifleTile` widget (reusable, кнопка Select, без cog для builtin)

---

### Phase 7 — CartridgeSelectScreen + CartridgeWizardScreen

- `CartridgeSelectScreen`: My Cartridges + My Bullets в одному списку (або tabs), filtered by `CartridgeType`
- `CartridgeCollectionScreen`: builtin cartridges + projectiles (з 🔒)
- `CartridgeWizardScreen`: повна реалізація з секціями Ballistics / MV / Zero; параметр `CartridgeType`
- `CartridgeTile` (reusable, cog для user data, Select btn)
- Після Save → `cartridges.json` → прив'язати `cartridgeId` до профілю

---

### Phase 8 — SightSelectScreen + SightWizardScreen

- Аналогічно Phase 7 для Sight
- `SightTile` (reusable)
- Після Save → `sights.json` → прив'язати `sightId` до профілю

---

### Phase 9 — IncompleteBanner + ProfileCard навігація

- `IncompleteBanner` widget на Home / Conditions / Tables
- `RecalcCoordinator` блокує перерахунок якщо `!isReadyForCalculation`
- `ProfileCard`: навігація через callbacks у `ProfilesScreen`, не `context.go` у widget
- `ProfileCardData`: оновити під нову структуру (cartridge name, sight name або "Not selected")

---

### Phase 10 — Duplicate Profile + FAB меню

- "Duplicate" у FAB меню `ProfilesScreen`
- Dialog для введення нової назви
- Копія профілю з новим UUID; rifle копіюється embedded; `cartridgeId`/`sightId` — ті самі references

---

### Phase 11 — Edit Flows (Flow 4)

- "Edit Rifle ›" у ProfileCard → `RifleWizardScreen` з поточними даними (caliberDiameter readonly)
- "Edit Cartridge ›" → `CartridgeWizardScreen` з поточними даними
- "Edit Sight ›" → `SightWizardScreen` з поточними даними

---

### Phase 12 — Built-in Collection Update (майбутнє)

Колекція — офлайн за замовчуванням (assets). Оновлення в додатку:
1. Перевірити останній тег `a7p-lib`
2. Порівняти з локально збереженим
3. Запропонувати оновлення (або тихо у фоні)
4. Нові builtin **додаються**, наявні — **не перезаписуються**

---

## Verification Checklist

| #   | Перевірка                                                                               | Статус |
| --- | --------------------------------------------------------------------------------------- | ------ |
| 1   | Імпорт `.a7p` → zero дані зберігаються в `Cartridge`                                    | 🔲      |
| 2   | Вибір профілю → Home показує rifle/cartridge/sight обраного профілю                     | ✅      |
| 3   | Зміна conditions/winds → відновлюється при поверненні до профілю                        | ✅      |
| 4   | Conditions screen не перезаписує zero conditions                                        | ✅      |
| 5   | Балістичний розрахунок: zero дані беруться з `cartridge`, не з `profile`                | 🔲      |
| 6   | Видалення профілю → бібліотека оновлюється                                              | ✅      |
| 7   | Select профілю → `moveToFirst` → наступного разу активний перший                        | ✅      |
| 8   | Фліккер при PageView scroll — виправлено унікальними `heroTag`                          | ✅      |
| 9   | `collection.json` парситься у `BuiltinCollection`                                       | ✅      |
| 10  | `builtinCollectionProvider`: пріоритет `~/.eBalistyka/collection.json`, fallback assets | ✅      |
| 11  | `Rifle.caliberDiameter` — зберігається/відновлюється, backward-compat                   | ✅      |
| 12  | `Rifle.barrelLength` — optional, backward-compat                                        | ✅      |
| 13  | `Rifle.isRightHandTwist` — getter від знаку `twist.raw`                                 | ✅      |
| 14  | Broken ref cartridgeId → обнулення + toast                                              | 🔲      |
| 15  | Broken ref sightId → обнулення + toast                                                  | 🔲      |
| 16  | `isReadyForCalculation` — блокує розрахунок, показує `IncompleteBanner`                 | 🔲      |
| 17  | Flow 1: новий профіль → rifle wizard → профіль без cartridge/sight                      | 🔲      |
| 18  | Flow 2: вибір cartridge → прив'язується до профілю                                      | 🔲      |
| 19  | Flow 3: вибір sight → прив'язується до профілю                                          | 🔲      |
| 20  | Flow 4: edit rifle → оновлюється embedded у профілі                                     | 🔲      |
| 21  | Flow 5: duplicate profile → новий UUID, rifle копіюється, ids ті самі                   | 🔲      |
| 22  | Bullet `type: bullet` → MV required у wizard                                            | 🔲      |
| 23  | Cartridge list фільтрується по `caliberDiameter` rifle (optional)                       | 🔲      |

---

## Reusable Patterns

- `showUnitEditDialog()` / `UnitValueField` — для wizard
- `BaseScreen` + `ScreenTopBar` — для wizard як route
- Display model pattern (`ProfileCardData`) — форматування у ViewModel, widget лише відображає
- `ItemListView<T>` + typed Tile widgets — для всіх списків (My Items + Collection Browser)
- `IncompleteBanner` — shared widget для Home / Conditions / Tables