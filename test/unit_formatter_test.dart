import 'package:test/test.dart';
import 'package:eballistica/formatting/unit_formatter.dart';
import 'package:eballistica/formatting/unit_formatter_impl.dart';
import 'package:eballistica/src/models/unit_settings.dart';
import 'package:eballistica/src/solver/unit.dart';

void main() {
  group('UnitFormatterImpl — metric defaults', () {
    // Default UnitSettings: meter, mps, celsius, hPa, cm (drop), mil, joule, grain, mm (sightHeight)
    late UnitFormatter fmt;

    setUp(() {
      fmt = UnitFormatterImpl(const UnitSettings());
    });

    // ── Formatted strings ──────────────────────────────────────────────────

    test('velocity() formats m/s', () {
      final v = Velocity(800.0, Unit.mps);
      final s = fmt.velocity(v);
      expect(s, contains('m/s'));
      expect(s, contains('800'));
    });

    test('muzzleVelocity() formats m/s with MV precision', () {
      final v = Velocity(850.5, Unit.mps);
      final s = fmt.muzzleVelocity(v);
      expect(s, contains('m/s'));
      // MV rawUnit is mps, display is mps — accuracyFor returns accuracy (0)
      expect(s, contains('851') /* rounded to 0 decimals */);
    });

    test('distance() formats meters', () {
      final d = Distance(300.0, Unit.meter);
      final s = fmt.distance(d);
      expect(s, contains('m'));
      expect(s, contains('300'));
    });

    test('shortDistance() returns value only (no unit)', () {
      final d = Distance(500.0, Unit.meter);
      final s = fmt.shortDistance(d);
      expect(s, isNot(contains('m')));
      expect(s, contains('500'));
    });

    test('temperature() formats celsius', () {
      final t = Temperature(15.0, Unit.celsius);
      final s = fmt.temperature(t);
      expect(s, contains('°C'));
      expect(s, contains('15'));
    });

    test('temperature() converts from fahrenheit', () {
      final t = Temperature(32.0, Unit.fahrenheit);
      final s = fmt.temperature(t);
      // 32°F = 0°C
      expect(s, contains('0'));
      expect(s, contains('°C'));
    });

    test('pressure() formats hPa', () {
      final p = Pressure(1013.25, Unit.hPa);
      final s = fmt.pressure(p);
      expect(s, contains('hPa'));
      expect(s, contains('1013'));
    });

    test('drop() formats centimeters', () {
      final d = Distance(-0.5, Unit.foot);
      final s = fmt.drop(d);
      expect(s, contains('cm'));
    });

    test('windage() delegates to drop()', () {
      final d = Distance(0.3, Unit.foot);
      expect(fmt.windage(d), equals(fmt.drop(d)));
    });

    test('adjustment() formats MIL', () {
      final a = Angular(1.5, Unit.mil);
      final s = fmt.adjustment(a);
      expect(s, contains('MIL'));
      expect(s, contains('1.5'));
    });

    test('energy() formats joules', () {
      final e = Energy(3000.0, Unit.joule);
      final s = fmt.energy(e);
      expect(s, contains('J'));
      expect(s, contains('3000'));
    });

    test('weight() formats grains', () {
      final w = Weight(175.0, Unit.grain);
      final s = fmt.weight(w);
      expect(s, contains('gr'));
      expect(s, contains('175'));
    });

    test('sightHeight() formats millimeters', () {
      final d = Distance(38.0, Unit.millimeter);
      final s = fmt.sightHeight(d);
      expect(s, contains('mm'));
      expect(s, contains('38'));
    });

    test('twist() formats with 1: prefix', () {
      final d = Distance(10.0, Unit.inch);
      final s = fmt.twist(d);
      expect(s, startsWith('1:'));
      expect(s, contains('in'));
    });

    test('humidity() formats percentage from fraction', () {
      expect(fmt.humidity(0.5), '50 %');
      expect(fmt.humidity(1.0), '100 %');
      expect(fmt.humidity(0.0), '0 %');
    });

    test('mach() formats with 2 decimals', () {
      expect(fmt.mach(0.85), '0.85 M');
      expect(fmt.mach(1.0), '1.00 M');
    });

    test('time() formats with 3 decimals', () {
      expect(fmt.time(1.234), '1.234 s');
      expect(fmt.time(0.0), '0.000 s');
    });

    // ── Raw numbers ────────────────────────────────────────────────────────

    test('rawVelocity() returns value in display unit', () {
      final v = Velocity(800.0, Unit.mps);
      expect(fmt.rawVelocity(v), closeTo(800.0, 1e-6));
    });

    test('rawDistance() returns value in display unit', () {
      final d = Distance(1.0, Unit.yard);
      // 1 yard ≈ 0.9144 m
      expect(fmt.rawDistance(d), closeTo(0.9144, 1e-3));
    });

    test('rawTemperature() returns celsius', () {
      final t = Temperature(32.0, Unit.fahrenheit);
      expect(fmt.rawTemperature(t), closeTo(0.0, 1e-6));
    });

    test('rawPressure() returns hPa', () {
      final p = Pressure(29.92, Unit.inHg);
      expect(fmt.rawPressure(p), closeTo(1013.25, 0.5));
    });

    test('rawDrop() returns centimeters', () {
      final d = Distance(1.0, Unit.foot);
      // 1 ft = 30.48 cm
      expect(fmt.rawDrop(d), closeTo(30.48, 0.01));
    });

    test('rawAdjustment() returns MIL', () {
      final a = Angular(3.438, Unit.moa);
      // 1 MOA ≈ 0.2909 MIL
      expect(fmt.rawAdjustment(a), closeTo(1.0, 0.02));
    });

    test('rawEnergy() returns joules', () {
      final e = Energy(1000.0, Unit.footPound);
      // 1 ft·lbf ≈ 1.3558 J
      expect(fmt.rawEnergy(e), closeTo(1355.8, 1.0));
    });

    test('rawWeight() returns grains', () {
      final w = Weight(10.0, Unit.gram);
      // 1 gram ≈ 15.432 grains
      expect(fmt.rawWeight(w), closeTo(154.32, 0.5));
    });

    test('rawSightHeight() returns millimeters', () {
      final d = Distance(1.5, Unit.inch);
      // 1 inch = 25.4 mm
      expect(fmt.rawSightHeight(d), closeTo(38.1, 0.01));
    });

    // ── Symbols ────────────────────────────────────────────────────────────

    test('symbols return correct unit symbols', () {
      expect(fmt.velocitySymbol, Unit.mps.symbol);
      expect(fmt.distanceSymbol, Unit.meter.symbol);
      expect(fmt.temperatureSymbol, Unit.celsius.symbol);
      expect(fmt.pressureSymbol, Unit.hPa.symbol);
      expect(fmt.dropSymbol, Unit.centimeter.symbol);
      expect(fmt.adjustmentSymbol, Unit.mil.symbol);
      expect(fmt.energySymbol, Unit.joule.symbol);
      expect(fmt.weightSymbol, Unit.grain.symbol);
      expect(fmt.sightHeightSymbol, Unit.millimeter.symbol);
    });
  });

  // ── Imperial settings ──────────────────────────────────────────────────────

  group('UnitFormatterImpl — imperial settings', () {
    late UnitFormatter fmt;

    setUp(() {
      fmt = UnitFormatterImpl(const UnitSettings(
        velocity: Unit.fps,
        distance: Unit.yard,
        temperature: Unit.fahrenheit,
        pressure: Unit.inHg,
        drop: Unit.inch,
        adjustment: Unit.moa,
        energy: Unit.footPound,
        weight: Unit.gram,
        sightHeight: Unit.inch,
        twist: Unit.inch,
      ));
    });

    test('velocity() formats fps', () {
      final v = Velocity(800.0, Unit.mps);
      final s = fmt.velocity(v);
      expect(s, contains('ft/s'));
    });

    test('distance() formats yards', () {
      final d = Distance(100.0, Unit.meter);
      final s = fmt.distance(d);
      expect(s, contains('yd'));
    });

    test('temperature() formats fahrenheit', () {
      final t = Temperature(0.0, Unit.celsius);
      final s = fmt.temperature(t);
      expect(s, contains('°F'));
      expect(s, contains('32'));
    });

    test('pressure() formats inHg', () {
      final p = Pressure(1013.25, Unit.hPa);
      final s = fmt.pressure(p);
      expect(s, contains('inHg'));
    });

    test('drop() formats inches', () {
      final d = Distance(1.0, Unit.foot);
      final s = fmt.drop(d);
      expect(s, contains('in'));
    });

    test('adjustment() formats MOA', () {
      final a = Angular(1.0, Unit.mil);
      final s = fmt.adjustment(a);
      expect(s, contains('MOA'));
    });

    test('energy() formats foot-pounds', () {
      final e = Energy(1000.0, Unit.joule);
      final s = fmt.energy(e);
      expect(s, contains('ft·lb'));
    });

    test('rawVelocity() returns fps', () {
      final v = Velocity(100.0, Unit.mps);
      // 100 m/s ≈ 328.08 fps
      expect(fmt.rawVelocity(v), closeTo(328.08, 0.5));
    });

    test('symbols reflect imperial settings', () {
      expect(fmt.velocitySymbol, Unit.fps.symbol);
      expect(fmt.distanceSymbol, Unit.yard.symbol);
      expect(fmt.temperatureSymbol, Unit.fahrenheit.symbol);
      expect(fmt.pressureSymbol, Unit.inHg.symbol);
      expect(fmt.dropSymbol, Unit.inch.symbol);
      expect(fmt.adjustmentSymbol, Unit.moa.symbol);
    });
  });

  // ── Input conversion ───────────────────────────────────────────────────────

  group('UnitFormatterImpl — inputToRaw / rawToInput', () {
    late UnitFormatterImpl fmt;

    setUp(() {
      fmt = UnitFormatterImpl(const UnitSettings());
    });

    test('velocity: round-trip mps → raw → mps', () {
      const display = 800.0;
      final raw = fmt.inputToRaw(display, InputField.velocity);
      final back = fmt.rawToInput(raw, InputField.velocity);
      expect(back, closeTo(display, 1e-6));
    });

    test('distance: round-trip meter → raw → meter', () {
      const display = 300.0;
      final raw = fmt.inputToRaw(display, InputField.distance);
      final back = fmt.rawToInput(raw, InputField.distance);
      expect(back, closeTo(display, 1e-6));
    });

    test('temperature: round-trip celsius → raw → celsius', () {
      const display = 25.0;
      final raw = fmt.inputToRaw(display, InputField.temperature);
      final back = fmt.rawToInput(raw, InputField.temperature);
      expect(back, closeTo(display, 1e-6));
    });

    test('pressure: round-trip hPa → raw → hPa', () {
      const display = 1013.0;
      final raw = fmt.inputToRaw(display, InputField.pressure);
      final back = fmt.rawToInput(raw, InputField.pressure);
      expect(back, closeTo(display, 1e-6));
    });

    test('humidity: display 50% → raw 0.5', () {
      expect(fmt.inputToRaw(50.0, InputField.humidity), 0.5);
      expect(fmt.rawToInput(0.5, InputField.humidity), 50.0);
    });

    test('bc: passthrough (dimensionless)', () {
      expect(fmt.inputToRaw(0.308, InputField.bc), 0.308);
      expect(fmt.rawToInput(0.308, InputField.bc), 0.308);
    });

    test('lookAngle: passthrough (always degrees)', () {
      expect(fmt.inputToRaw(5.0, InputField.lookAngle), 5.0);
      expect(fmt.rawToInput(5.0, InputField.lookAngle), 5.0);
    });

    test('targetDistance: same as distance round-trip', () {
      const display = 500.0;
      final raw = fmt.inputToRaw(display, InputField.targetDistance);
      final back = fmt.rawToInput(raw, InputField.targetDistance);
      expect(back, closeTo(display, 1e-6));
    });

    test('zeroDistance: same as distance round-trip', () {
      const display = 100.0;
      final raw = fmt.inputToRaw(display, InputField.zeroDistance);
      final back = fmt.rawToInput(raw, InputField.zeroDistance);
      expect(back, closeTo(display, 1e-6));
    });

    test('sightHeight: mm round-trip', () {
      const display = 38.0;
      final raw = fmt.inputToRaw(display, InputField.sightHeight);
      // raw is in millimeters (same as display unit for default settings)
      expect(raw, closeTo(38.0, 1e-6));
      expect(fmt.rawToInput(raw, InputField.sightHeight), closeTo(display, 1e-6));
    });

    test('twist: inch round-trip', () {
      const display = 10.0;
      final raw = fmt.inputToRaw(display, InputField.twist);
      expect(raw, closeTo(10.0, 1e-6));
      expect(fmt.rawToInput(raw, InputField.twist), closeTo(display, 1e-6));
    });

    test('bulletWeight: grain round-trip', () {
      const display = 175.0;
      final raw = fmt.inputToRaw(display, InputField.bulletWeight);
      expect(raw, closeTo(175.0, 1e-6));
      expect(fmt.rawToInput(raw, InputField.bulletWeight), closeTo(display, 1e-6));
    });
  });

  // ── Imperial input conversion ──────────────────────────────────────────────

  group('UnitFormatterImpl — imperial inputToRaw / rawToInput', () {
    late UnitFormatterImpl fmt;

    setUp(() {
      fmt = UnitFormatterImpl(const UnitSettings(
        velocity: Unit.fps,
        distance: Unit.yard,
        temperature: Unit.fahrenheit,
        pressure: Unit.inHg,
        sightHeight: Unit.inch,
      ));
    });

    test('velocity: fps display → mps raw', () {
      // 3280.84 fps ≈ 1000 m/s
      final raw = fmt.inputToRaw(3280.84, InputField.velocity);
      expect(raw, closeTo(1000.0, 0.1));
    });

    test('distance: yards display → meters raw', () {
      // 109.36 yd ≈ 100 m
      final raw = fmt.inputToRaw(109.36, InputField.distance);
      expect(raw, closeTo(100.0, 0.1));
    });

    test('temperature: fahrenheit display → celsius raw', () {
      final raw = fmt.inputToRaw(68.0, InputField.temperature);
      expect(raw, closeTo(20.0, 0.1));
    });

    test('pressure: inHg display → hPa raw', () {
      final raw = fmt.inputToRaw(29.92, InputField.pressure);
      expect(raw, closeTo(1013.21, 0.5));
    });

    test('sightHeight: inch display → mm raw', () {
      final raw = fmt.inputToRaw(1.5, InputField.sightHeight);
      // 1.5 in = 38.1 mm
      expect(raw, closeTo(38.1, 0.1));
    });

    test('round-trip for all imperial fields', () {
      for (final field in [
        InputField.velocity,
        InputField.distance,
        InputField.temperature,
        InputField.pressure,
        InputField.sightHeight,
      ]) {
        final display = 100.0;
        final raw = fmt.inputToRaw(display, field);
        final back = fmt.rawToInput(raw, field);
        expect(back, closeTo(display, 1e-4),
            reason: 'Round-trip failed for $field');
      }
    });
  });

  // ── Edge cases ─────────────────────────────────────────────────────────────

  group('UnitFormatterImpl — edge cases', () {
    late UnitFormatter fmt;

    setUp(() {
      fmt = UnitFormatterImpl(const UnitSettings());
    });

    test('zero values format correctly', () {
      expect(fmt.velocity(Velocity(0, Unit.mps)), contains('0'));
      expect(fmt.distance(Distance(0, Unit.meter)), contains('0'));
      expect(fmt.energy(Energy(0, Unit.joule)), contains('0'));
    });

    test('negative drop formats correctly', () {
      final d = Distance(-2.0, Unit.foot);
      final s = fmt.drop(d);
      expect(s, contains('-'));
      expect(s, contains('cm'));
    });

    test('const constructor works', () {
      const formatter = UnitFormatterImpl(UnitSettings());
      expect(formatter.velocitySymbol, Unit.mps.symbol);
    });
  });
}
