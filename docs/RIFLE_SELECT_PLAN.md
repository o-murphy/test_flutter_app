# Rifle Select Screen — Design & Implementation Plan

## Поточний стан

Вже реалізовано:
- `rifle_select_screen.dart` — скелет: PageView, FAB speed-dial, картка профілю (мінімальна)
- `rifle_select_vm.dart` — ViewModel з CRUD + `selectProfile` / `deleteProfile`
- `profileLibraryProvider` — CRUD + persistence через `JsonFileStorage`
- `library_provider.dart` — окремі провайдери для Rifle / Cartridge / Sight бібліотек
- `app_storage.dart` + `json_file_storage.dart` — повний I/O шар (JSON файли у `~/.eBalistyka/`)
- Seed data: 1 гвинтівка + 4 патрони в `seed_data.dart`
- Phase 1–3 з `plan_rifle_select_architecture.md` — виконано

---

## Концепція екрану

### Структура картки (прокручувана, одна на гвинтівку)

```
┌──────────────────────────────────────┐
│                                      │
│   [Placeholder / фото гвинтівки]     │  ← фіксована висота ~160px
│       (future: image asset)          │     по краях: назва профілю
│                                      │
├──────────────────────────────────────┤
│  🔫 Cartridge   [назва патрону  ›]   │  ← tap → CartridgePickerScreen
│  🔭 Sight       [назва прицілу  ›]   │  ← tap → SightPickerScreen (пізніше)
├──────────────────────────────────────┤
│  ── Rifle ──────────────────────     │
│  Sight height   8.5 mm               │
│  Twist          1:10 inch            │
│                     [Edit Rifle ›]   │
├──────────────────────────────────────┤
│  ── Cartridge ──────────────────     │
│  MV             888 m/s              │
│  Bullet         250 gr · .338"       │
│  Drag model     G7 · BC 0.314        │
│  Powder temp    29°C                 │
│                  [Edit Cartridge ›]  │
├──────────────────────────────────────┤
│  ── Zero ───────────────────────     │
│  Distance       100 m                │
│  Temperature    15°C · 1000 hPa      │
│                     [Edit Zero ›]    │
├──────────────────────────────────────┤
│              [  Select  ]            │  ← відображається тільки якщо
│                                      │     профіль НЕ активний
└──────────────────────────────────────┘
```

- Якщо профіль **активний** — кнопка "Select" замінюється на `✓ Active` + підсвічування картки
- Скролиться вся картка у межах сторінки, FAB + dots indicator фіксовані поверх

---

## Концепція "builtin" / user даних

### Дві колекції — різні точки доступу

**Вбудована колекція** (`builtin: true`) — набір профілів, патронів і прицілів, який
наповнює розробник і поставляється разом із додатком.
**Ніде не відображається напряму** в основних екранах.
Доступна виключно через точки входу "Add from library" — окремий `LibraryBrowserScreen`
для кожного типу сутності. При виборі запис **копіюється** у бібліотеку юзера
(`builtin: false`, новий UUID).

**Бібліотека юзера** (`builtin: false`) — все що юзер створив, імпортував, або скопіював
з вбудованої колекції. Саме ця бібліотека відображається скрізь у додатку.

```
Rifle Select Screen                   Built-in Collection (hidden)
─────────────────────────────         ──────────────────────────────────────
 [My .338LM UKROP]   ←copy──────────  🔒 .338LM UKROP 250GR SMK  (profile)
 [Hornady 285 copy]  ←copy──────────  🔒 Hornady 285GR ELD-M     (profile)
 [Imported from .a7p]                 🔒 ...
                                      🔒 Hornady 250GR BTHP       (cartridge)
  FAB → "Add from library" ────────►  🔒 Lapua 300GR SMK          (cartridge)
  (ProfileLibraryBrowserScreen)       🔒 ...

Cartridge Picker (у картці профілю)   🔒 NF ATACR 5-25x56         (sight, майбутнє)
 [My .338LM UKROP cart]               🔒 ...
 "Add from library" ──────────────►
  (CartridgeLibraryBrowserScreen)

Sight Picker (майбутнє)
 "Add from library" ──────────────►
  (SightLibraryBrowserScreen)
```

### Дві окремі схеми даних

**Вбудована колекція** зберігає мінімальний набір балістичних даних — по суті a7p-формат
плюс небагато метаданих (виробник, калібр, посилання). Немає runtime-стану.
Модель: `BuiltinProfile` (або просто парсується як `ShotProfile` без runtime полів при імпорті).

**Бібліотека юзера** зберігає повний `ShotProfile` з ширшим набором параметрів:
- всі балістичні дані (rifle, cartridge, sight, zero)
- runtime-стан: `conditions`, `winds`, `lookAngle`, `targetDistance`
- майбутнє: мітки, нотатки, дата останнього використання, тощо

Юзер **ніколи не записує** нічого у вбудовану колекцію — вона read-only з його точки зору.
Імпорт, створення, копіювання з builtin — все йде тільки у бібліотеку юзера.

### Сховище — фізично окремі файли

```
~/.eBalistyka/
  profiles.json          ← бібліотека юзера (повний ShotProfile)
  cartridges.json        ← бібліотека юзера (повний Cartridge)
  rifles.json            ← бібліотека юзера (повний Rifle)
  sights.json            ← бібліотека юзера (повний Sight)
  profile.json           ← поточний активний профіль

assets/ (або завантажений по тегу)
  builtin/
    profiles.json        ← вбудована колекція (a7p-like + metadata)
    cartridges.json      ← вбудована колекція патронів
```

`AppStorage` interface залишається без змін — додається окремий `BuiltinLibrarySource`
(або `BuiltinStorage`) для читання вбудованих даних. Запис у builtin — недоступний з коду додатку.

### Поведінка
| Дія                              | Вбудована колекція                                         | Бібліотека юзера                 |
|----------------------------------|------------------------------------------------------------|----------------------------------|
| Відображення на Rifle Select     | ❌ Не відображається                                       | ✅ Відображається                 |
| Відображення у LibraryBrowser    | ✅ Відображається (з 🔒 icon)                              | ❌ Не відображається              |
| "Add from library"               | → конвертується у повний `ShotProfile`, зберігається у бібліотеці юзера | —          |
| Видалити                         | Неможливо (read-only файл)                                 | Дозволено                        |
| Редагувати                       | Неможливо                                                  | Редагує напряму                  |
| Запис нових записів              | Тільки розробником (assets / оновлення по тегу)            | Юзером (create / import / copy)  |

---

## MVP — Мінімальний набір для функціонального екрану

### MVP не включає:
- Wizard для ручного створення профілю
- Редагування окремих полів rifle / cartridge / zero через форму
- Sight picker
- Export

### MVP включає:

**1. Seed profiles (2 × ShotProfile у profiles.json)**
- `.338LM UKROP 250GR` — seedRifle + seedCartridgeUkrop250 + seedZeroConditions
- `.338LM Hornady 285GR ELD-M` — seedRifle + seedCartridgeSts285EldM + seedZeroConditions
- Обидва `builtin: true`

**2. Картка профілю — повний layout** (за специфікацією вище)
- Scrollable Card
- Hero area (placeholder box)
- Cartridge selector row (tap → CartridgePickerScreen)
- Rifle / Cartridge / Zero секції з деталями
- Select / Active кнопка

**3. CartridgePickerScreen**
- Список патронів з `cartridgeLibraryProvider`
- Tap → оновлює cartridge у профілі через `rifleSelectVmProvider.notifier.swapCartridge(profileId, cartridge)`
- Builtin позначки; пошук по назві

**4. Import .a7p → збереження як новий профіль**
- `file_picker` пакет (вже в TODO на екрані)
- `A7pParser.fromPayload(...)` → `ShotProfile`
- Зберігається у `profileLibraryProvider` з `builtin: false`

**5. Delete профілю**
- Вже реалізовано у VM та screen
- Тільки якщо `!profile.builtin`

---

## Реалізація — Кроки

### Крок 1 — Поле `builtin` у моделях
**Файли:** `rifle.dart`, `cartridge.dart`, `shot_profile.dart`, `sight.dart`
- Додати `final bool builtin` (default `false`)
- `toJson` / `fromJson`: `'builtin': builtin` — optional field, default false
- `copyWith`: параметр `bool? builtin`
- `seed_data.dart`: виставити `builtin: true` для всіх seed записів

### Крок 2 — Seed profiles
**Файл:** `seed_data.dart`
- Додати 2 `ShotProfile` константи (`seedProfile338Ukrop`, `seedProfile338StsEldM`)
- `ProfileLibraryNotifier.build()`: якщо порожньо — завантажити обидва seed профілі

### Крок 3 — Повний layout картки
**Файли:** `rifle_select_screen.dart`
- Замінити `_ProfileCard` на scrollable варіант
- `_HeroArea` widget (placeholder + назва)
- `_SelectorRow` (Cartridge picker, Sight picker заглушка)
- `_RifleSection`, `_CartridgeSection`, `_ZeroSection` — info rows + Edit кнопки (заглушки)
- Логіка `isActive` → `Active` vs `Select` кнопка

### Крок 4 — CartridgePickerScreen
**Нові файли:**
- `lib/features/home/sub_screens/cartridge_picker/cartridge_picker_screen.dart`
- `lib/features/home/sub_screens/cartridge_picker/cartridge_picker_vm.dart`

ViewModel: `AsyncNotifier<CartridgePickerUiState>` — завантажує `cartridgeLibraryProvider`
Screen: `BaseScreen` + `ListView` + пошуковий рядок + tap → `Navigator.pop(cartridge)`

`RifleSelectViewModel.swapCartridge(String profileId, Cartridge c)`:
```dart
Future<void> swapCartridge(String profileId, Cartridge c) async {
  final profiles = ref.read(profileLibraryProvider).value ?? [];
  final profile = profiles.firstWhere((p) => p.id == profileId);
  final updated = profile.copyWith(cartridge: c);
  await ref.read(profileLibraryProvider.notifier).save(updated);
}
```

### Крок 5 — Import .a7p
**Файл:** `rifle_select_screen.dart`
- `_onImport()`: `FilePicker.platform.pickFiles(type: FileType.any)` → читає bytes
- Парсить через `A7pParser.fromPayload(...)` (вже є)
- Зберігає через `rifleSelectVmProvider.notifier.saveProfile(parsed)`
- Помилки — `SnackBar`

**`pubspec.yaml`:** додати `file_picker: ^8.x`

### Крок 6 — Заборона видалення builtin
**Файли:** `rifle_select_screen.dart`, `rifle_select_vm.dart`
- `deleteProfile`: перевіряти `profile.builtin` — якщо true, показувати `SnackBar("Built-in profiles cannot be deleted")`
- FAB `Delete` action: `enabled: !profile.builtin`

---

## Майбутні фази (після MVP)

| Фаза | Що                                      | Залежить від          |
|------|-----------------------------------------|-----------------------|
| 6    | Edit Rifle form (1-page, Accept/Decline)| Крок 3 (картка)       |
| 7    | Edit Cartridge form                     | Крок 3                |
| 8    | Edit Zero Settings form                 | Крок 3                |
| 9    | Profile Creation Wizard (покроковий)    | Фази 6-8              |
| 10   | Sight Picker + Edit Sight               | Крок 3                |
| 11   | Export .a7p                             | Крок 5                |
| 12   | Оновлення вбудованої колекції           | Крок 1 (builtin flag)  |

### Оновлення вбудованої колекції (майбутнє)
Колекція — **офлайн за замовчуванням**, поставляється з додатком як початковий seed.
Оновлення відбувається **всередині додатку**: додаток сам завантажує нову версію бібліотеки
по git-тегу з репозиторію `a7p-lib` (бібліотека легка — лише JSON індекс + `.a7p` файли).

Флоу оновлення:
1. Додаток перевіряє останній тег `a7p-lib` (наприклад, `GET .../releases/latest`)
2. Порівнює з локально збереженим тегом
3. Якщо є новіший — пропонує юзеру оновити вбудовану колекцію (або тихо у фоні)
4. Завантажує `profiles.json` → парсить → оновлює builtin записи локально

Формат джерела — `a7p-lib` репозиторій:
- `profiles.json` — індекс: id, діаметр, вага, калібр, постачальник
- `gallery/<caliber>/<name>.a7p` — бінарні файли профілів
- `gallery/<caliber>/<name>.meta.json` — метадані (drag model, виробник тощо)

При оновленні: нові builtin записи **додаються**, наявні — **не перезаписуються**
(щоб не зламати вибір юзера). Видалені з колекції — **залишаються** у юзера.

---

## Файловий план (нові файли)

```
lib/
  core/
    models/
      rifle.dart           ← + builtin field
      cartridge.dart       ← + builtin field
      shot_profile.dart    ← + builtin field
      seed_data.dart       ← builtin: true + 2 seed profiles
  features/
    home/
      sub_screens/
        rifle_select_screen.dart        ← повний layout картки
        rifle_select/
          rifle_select_vm.dart          ← + swapCartridge()
        cartridge_picker/
          cartridge_picker_screen.dart  ← новий
          cartridge_picker_vm.dart      ← новий
```

---

## Ключові рішення

| Питання                            | Рішення                                                              |
|------------------------------------|----------------------------------------------------------------------|
| Де зберігається `builtin`?         | У моделі як поле, serialized у JSON                                  |
| Builtin + user в одному файлі?     | Так, поки що в одному `profiles.json`                                |
| Картка → tap = select?             | Ні, тільки кнопка "Select" внизу картки                              |
| Скролл картки vs PageView?         | PageView скролиться горизонтально, картка — вертикально всередині    |
| NoSQL / JSON для сховища?          | JSON поки що достатньо; `AppStorage` interface дозволяє поміняти     |
| Cartridge в профілі vs бібліотеці? | Профіль зберігає повний snapshot cartridge; зміна через picker → нова версія snapshot |
