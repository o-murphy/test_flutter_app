// Unit tests for ConditionsViewModel (Phase 2).
//
// No FFI required — uses only Riverpod container with provider overrides.
//   flutter test test/viewmodels/conditions_vm_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_conditions_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/projectile.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/models/sight.dart';
import 'package:eballistica/core/models/unit_settings.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/features/conditions/conditions_vm.dart';

// ── Fixtures ────────────────────────────────────────────────────────────────

ShotProfile _makeProfile() {
  final projectile = Projectile(
    name: 'Test 175gr',
    dragType: DragModelType.g7,
    weight: Weight(175, Unit.grain),
    diameter: Distance(7.62, Unit.millimeter),
    length: Distance(31.0, Unit.millimeter),
    coefRows: [CoeficientRow(bcCd: 0.475, mv: 0.0)],
  );
  final cartridge = Cartridge(
    name: 'Test .308',
    projectile: projectile,
    mv: Velocity(800, Unit.mps),
    powderTemp: Temperature(15.0, Unit.celsius),
    powderSensitivity: Ratio(1.0, Unit.fraction),
    zeroConditions: Conditions.withDefaults(usePowderSensitivity: true),
  );
  final rifle = Rifle(
    name: 'Test Rifle',
    sightHeight: Distance(38.0, Unit.millimeter),
    twist: Distance(11.0, Unit.inch),
  );
  final sight = Sight(
    name: 'Test Scope',
    sightHeight: Distance(38.0, Unit.millimeter),
    zeroElevation: Angular(0, Unit.radian),
  );
  return ShotProfile(
    name: 'Test Shot',
    rifle: rifle,
    sight: sight,
    cartridge: cartridge,
  );
}

Conditions _makeConditions({
  double tempC = 20.0,
  double altM = 150.0,
  double pressHPa = 1013.25,
  double humidity = 0.50,
  double powderTempC = 20.0,
  bool usePowderSensitivity = false,
  bool useDiffPowderTemp = false,
}) {
  return Conditions(
    atmo: AtmoData(
      temperature: Temperature(tempC, Unit.celsius),
      altitude: Distance(altM, Unit.meter),
      pressure: Pressure(pressHPa, Unit.hPa),
      humidity: humidity,
      powderTemp: Temperature(powderTempC, Unit.celsius),
    ),
    lookAngle: Angular(0, Unit.degree),
    distance: Distance(300.0, Unit.meter),
    winds: [],
    usePowderSensitivity: usePowderSensitivity,
    useDiffPowderTemp: useDiffPowderTemp,
    useCoriolis: false,
    latitudeDeg: null,
    azimuthDeg: null,
  );
}

// ── Fake notifiers for provider overrides ────────────────────────────────────

class _FakeProfileNotifier extends ShotProfileNotifier {
  final ShotProfile _profile;
  _FakeProfileNotifier(this._profile);
  @override
  Future<ShotProfile> build() async => _profile;
}

class _FakeSettingsNotifier extends SettingsNotifier {
  final AppSettings _settings;
  _FakeSettingsNotifier(this._settings);
  @override
  Future<AppSettings> build() async => _settings;
}

class _FakeConditionsNotifier extends ShotConditionsNotifier {
  Conditions _conditions;
  _FakeConditionsNotifier(this._conditions);

  @override
  Future<Conditions> build() async => _conditions;

  // Не використовуємо update, замість цього робимо push метод
  void push(Conditions c) {
    _conditions = c;
    state = AsyncData(c);
  }

  Conditions get currentValue => _conditions;
}

/// Creates a ProviderContainer with the given profile, conditions and settings.
ProviderContainer _createContainer({
  required ShotProfile profile,
  required Conditions conditions,
  AppSettings settings = const AppSettings(),
}) {
  return ProviderContainer(
    overrides: [
      shotProfileProvider.overrideWith(() => _FakeProfileNotifier(profile)),
      settingsProvider.overrideWith(() => _FakeSettingsNotifier(settings)),
      shotConditionsProvider.overrideWith(
        () => _FakeConditionsNotifier(conditions),
      ),
    ],
  );
}

/// Waits for async dependencies to resolve, then reads the VM state.
Future<ConditionsUiState> _waitForConditions(
  ProviderContainer container,
) async {
  await container.read(shotProfileProvider.future);
  await container.read(settingsProvider.future);
  await container.read(shotConditionsProvider.future);
  await Future<void>.delayed(Duration.zero);
  return container.read(conditionsVmProvider.future);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ConditionsViewModel — metric units (defaults)', () {
    late ProviderContainer container;
    late ConditionsUiState state;

    setUp(() async {
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(
          tempC: 20.0,
          altM: 150.0,
          pressHPa: 1013.25,
          humidity: 0.50,
        ),
      );
      state = await _waitForConditions(container);
    });

    tearDown(() => container.dispose());

    test('temperature displays in Celsius', () {
      expect(state.temperature.displayValue, closeTo(20.0, 0.01));
      expect(state.temperature.symbol, '°C');
      expect(state.temperature.rawValue, closeTo(20.0, 0.01));
    });

    test('altitude displays in meters', () {
      expect(state.altitude.displayValue, closeTo(150.0, 0.1));
      expect(state.altitude.symbol, 'm');
    });

    test('pressure displays in hPa', () {
      expect(state.pressure.displayValue, closeTo(1013.25, 0.5));
      expect(state.pressure.symbol, 'hPa');
    });

    test('humidity displays as percentage', () {
      expect(state.humidity.displayValue, closeTo(50.0, 0.1));
      expect(state.humidity.symbol, '%');
    });

    test('temperature constraints are correct', () {
      expect(state.temperature.displayMin, -100.0);
      expect(state.temperature.displayMax, 100.0);
      expect(state.temperature.displayStep, 1.0);
      expect(state.temperature.decimals, 0);
    });

    test('altitude constraints are correct for metric', () {
      expect(state.altitude.displayMin, closeTo(-500.0, 0.1));
      expect(state.altitude.displayMax, closeTo(15000.0, 0.1));
    });

    test('powder sensitivity is off by default', () {
      expect(state.powderSensOn, false);
      expect(state.useDiffPowderTemp, false);
      expect(state.powderTemperature, isNull);
      expect(state.mvAtPowderTemp, isNull);
      expect(state.powderSensitivity, isNull);
    });

    test('coriolis and derivation are off by default', () {
      expect(state.coriolisOn, false);
      expect(state.derivationOn, false);
    });
  });

  group('ConditionsViewModel — imperial units', () {
    late ProviderContainer container;
    late ConditionsUiState state;

    setUp(() async {
      const imperial = UnitSettings(
        temperature: Unit.fahrenheit,
        distance: Unit.yard,
        velocity: Unit.fps,
        pressure: Unit.mmHg,
      );
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(
          tempC: 20.0,
          altM: 150.0,
          pressHPa: 1013.25,
        ),
        settings: const AppSettings(units: imperial),
      );
      state = await _waitForConditions(container);
    });

    tearDown(() => container.dispose());

    test('temperature converts to Fahrenheit', () {
      expect(state.temperature.displayValue, closeTo(68.0, 0.5));
      expect(state.temperature.symbol, '°F');
    });

    test('altitude converts to yards', () {
      expect(state.altitude.displayValue, closeTo(164.0, 1.0));
      expect(state.altitude.symbol, 'yd');
    });

    test('pressure converts to mmHg', () {
      expect(state.pressure.displayValue, closeTo(760.0, 1.0));
      expect(state.pressure.symbol, 'mmHg');
    });

    test('temperature constraints convert properly', () {
      expect(state.temperature.displayMin, closeTo(-148.0, 1.0));
      expect(state.temperature.displayMax, closeTo(212.0, 1.0));
    });
  });

  group('ConditionsViewModel — powder sensitivity', () {
    late ProviderContainer container;
    late ConditionsUiState state;

    setUp(() async {
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(
          tempC: 25.0,
          powderTempC: 25.0,
          usePowderSensitivity: true,
          useDiffPowderTemp: false,
        ),
      );
      state = await _waitForConditions(container);
    });

    tearDown(() => container.dispose());

    test('powderSensOn reflects settings', () {
      expect(state.powderSensOn, true);
    });

    test('MV at powder temp is computed', () {
      expect(state.mvAtPowderTemp, isNotNull);
      expect(state.mvAtPowderTemp, contains('m/s'));
    });

    test('powder sensitivity string is shown', () {
      expect(state.powderSensitivity, isNotNull);
      expect(state.powderSensitivity, contains('%'));
    });

    test('separate powder temp field is null when useDiffPowderTemp=false', () {
      expect(state.useDiffPowderTemp, false);
      expect(state.powderTemperature, isNull);
    });
  });

  group('ConditionsViewModel — separate powder temperature', () {
    late ProviderContainer container;
    late ConditionsUiState state;

    setUp(() async {
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(
          tempC: 25.0,
          powderTempC: 30.0,
          usePowderSensitivity: true,
          useDiffPowderTemp: true,
        ),
      );
      state = await _waitForConditions(container);
    });

    tearDown(() => container.dispose());

    test('separate powder temp field is shown', () {
      expect(state.useDiffPowderTemp, true);
      expect(state.powderTemperature, isNotNull);
    });

    test('powder temp has correct value', () {
      expect(state.powderTemperature!.displayValue, closeTo(30.0, 0.5));
      expect(state.powderTemperature!.symbol, '°C');
    });
  });

  group('ConditionsViewModel — empty state', () {
    test('provides default values when conditions not loaded', () async {
      // Використовуємо реальний notifier з null значенням
      final container = ProviderContainer(
        overrides: [
          shotProfileProvider.overrideWith(
            () => _FakeProfileNotifier(_makeProfile()),
          ),
          settingsProvider.overrideWith(
            () => _FakeSettingsNotifier(const AppSettings()),
          ),
          // Не оверрайдимо shotConditionsProvider - він сам завантажиться
        ],
      );
      addTearDown(container.dispose);

      // Чекаємо тільки settings і profile
      await container.read(settingsProvider.future);
      await container.read(shotProfileProvider.future);

      // Даємо час для VM
      await Future<void>.delayed(Duration.zero);

      // Отримуємо стан VM
      final state = await container.read(conditionsVmProvider.future);
      expect(state.temperature.label, 'Temperature');
      expect(state.humidity.label, 'Humidity');
      expect(state.powderSensOn, false);
    });
  });

  group('ConditionsViewModel — inputField types', () {
    test('each field has correct inputField', () async {
      final container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
      );
      addTearDown(container.dispose);
      final state = await _waitForConditions(container);

      expect(state.temperature.inputField, InputField.temperature);
      expect(state.altitude.inputField, InputField.distance);
      expect(state.humidity.inputField, InputField.humidity);
      expect(state.pressure.inputField, InputField.pressure);
    });
  });

  group('ConditionsField — data class', () {
    test('stores all values correctly', () {
      const f = ConditionsField(
        label: 'Test',
        displayValue: 42.0,
        rawValue: 315.15,
        symbol: 'K',
        displayMin: 0,
        displayMax: 500,
        displayStep: 1,
        decimals: 2,
        inputField: InputField.temperature,
        displayUnit: Unit.celsius,
      );
      expect(f.label, 'Test');
      expect(f.displayValue, 42.0);
      expect(f.rawValue, 315.15);
      expect(f.symbol, 'K');
      expect(f.displayMin, 0);
      expect(f.displayMax, 500);
      expect(f.displayStep, 1);
      expect(f.decimals, 2);
      expect(f.inputField, InputField.temperature);
    });
  });
}

// /// Profile notifier that never completes — simulates "still loading" state.
// class _PendingProfileNotifier extends ShotProfileNotifier {
//   @override
//   Future<ShotProfile> build() => Completer<ShotProfile>().future;
// }

// /// Conditions notifier that never completes — simulates "still loading" state.
// class _PendingConditionsNotifier extends ShotConditionsNotifier {
//   @override
//   Future<Conditions> build() => Completer<Conditions>().future;
// }
