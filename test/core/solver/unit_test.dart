import 'package:test/test.dart';
import 'package:eballistica/core/solver/unit.dart';

void main() {
  group('Angular normalization', () {
    test('normalization (-pi, pi]', () {
      expect(Angular(181, Unit.degree).in_(Unit.degree), closeTo(-179, 1e-9));
      expect(Angular(360, Unit.degree).in_(Unit.degree), closeTo(0, 1e-9));
      expect(Angular(-180, Unit.degree).in_(Unit.degree), closeTo(180, 1e-9));
    });
  });

  group('Arithmetic Operators (+, -, *, /)', () {
    test('Add same dimensions', () {
      final d1 = Distance(1, Unit.yard);
      final d2 = Distance(1, Unit.foot);
      final result = d1 + d2;

      expect(result, isA<Distance>());

      expect(result.rawValue, closeTo(48.0, 1e-9));
      expect(result.in_(Unit.yard), closeTo(1.333333, 1e-5));
    });

    test('Add scalar (Distance)', () {
      final d = Distance(1, Unit.yard);
      final result = d + 2;
      expect(result.in_(Unit.yard), 3.0);
    });

    test('Multiply/Divide by scalar', () {
      final w = Weight(100, Unit.grain);
      expect((w * 2).in_(Unit.grain), 200.0);
      expect((w / 4).in_(Unit.grain), 25.0);
    });

    test('Ratio (Dimension / Dimension)', () {
      final d1 = Distance(10, Unit.meter);
      final d2 = Distance(2, Unit.meter);
      final ratio = d1 / d2;

      expect(ratio, isA<double>());
      expect(ratio, 5.0);
    });
  });

  group('Temperature (Non-linear & Delta logic)', () {
    test('Basic conversion', () {
      final c = Temperature(0, Unit.celsius);
      expect(c.in_(Unit.fahrenheit), 32.0);
      expect(c.in_(Unit.kelvin), 273.15);
    });

    test('Temperature scalar addition (Delta)', () {
      final t = Temperature(20, Unit.celsius);

      final warmer = t + 10;
      expect(warmer.in_(Unit.celsius), 30.0);
    });

    test('Temperature scalar subtraction', () {
      final t = Temperature(32, Unit.fahrenheit);

      final colder = t - 2;
      expect(colder.in_(Unit.fahrenheit), 30.0);
    });
  });

  group('Error Handling', () {
    test('Division by zero throws', () {
      final v = Velocity(100, Unit.mps);
      expect(() => v / 0, throwsArgumentError);
    });

    test('Unsupported unit throws', () {
      final d = Distance(1, Unit.meter);
      expect(() => d.in_(Unit.joule), throwsException);
    });

    test('Incompatible types addition throws', () {
      final d = Distance(1, Unit.meter);
      final w = Weight(1, Unit.gram);
      expect(() => d + w, throwsArgumentError);
    });
  });

  group('Utility methods', () {
    test('toDouble() returns value in current units', () {
      final p = Pressure(30, Unit.inHg);
      expect(p.toDouble(), 30.0);
    });

    test('toString() uses accuracy from Unit enum', () {
      final v = Velocity(123.456, Unit.kmh); // accuracy = 1
      expect(v.toString(), "123.5km/h");
    });
  });
}
