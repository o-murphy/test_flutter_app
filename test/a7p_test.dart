import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:test_app/src/a7p/a7p.dart';

void main() {
  // ─── Fixtures ─────────────────────────────────────────────────────────────

  Uint8List loadExample() {
    final file = File('test/example.a7p');
    if (!file.existsSync()) {
      throw StateError('test/example.a7p not found — add it to the test folder');
    }
    return file.readAsBytesSync();
  }

  // ─── decode ───────────────────────────────────────────────────────────────

  group('decode', () {
    test('decodes example.a7p without throwing', () {
      final payload = decode(loadExample());
      expect(payload.profile, isNotNull);
    });

    test('profile strings are non-empty', () {
      final p = decode(loadExample()).profile;
      expect(p.profileName,   isNotEmpty);
      expect(p.cartridgeName, isNotEmpty);
      expect(p.bulletName,    isNotEmpty);
      expect(p.caliber,       isNotEmpty);
    });

    test('has at least 4 switches', () {
      final p = decode(loadExample()).profile;
      expect(p.switches.length, greaterThanOrEqualTo(4));
    });

    test('has at least 1 distance', () {
      final p = decode(loadExample()).profile;
      expect(p.distances, isNotEmpty);
    });

    test('has at least 1 coefRow', () {
      final p = decode(loadExample()).profile;
      expect(p.coefRows, isNotEmpty);
    });

    test('throws DecodeException on tampered checksum', () {
      final bytes = loadExample();
      // Flip one byte in the checksum region
      final tampered = Uint8List.fromList(bytes);
      tampered[0] = tampered[0] ^ 0xFF;
      expect(() => decode(tampered), throwsA(isA<DecodeException>()));
    });

    test('throws DecodeException on truncated buffer', () {
      expect(() => decode(Uint8List(10)), throwsA(isA<DecodeException>()));
    });

    test('throws DecodeException on empty buffer', () {
      expect(() => decode(Uint8List(0)), throwsA(isA<DecodeException>()));
    });
  });

  // ─── encode → decode round-trip ───────────────────────────────────────────

  group('round-trip', () {
    test('encode(decode(bytes)) equals original bytes', () {
      final original = loadExample();
      final payload  = decode(original);
      final reencoded = encode(payload);
      expect(reencoded, equals(original));
    });

    test('decoded payload survives a second encode/decode cycle', () {
      final payload1 = decode(loadExample());
      final payload2 = decode(encode(payload1));

      final p1 = payload1.profile;
      final p2 = payload2.profile;

      expect(p2.profileName,   equals(p1.profileName));
      expect(p2.cartridgeName, equals(p1.cartridgeName));
      expect(p2.bulletName,    equals(p1.bulletName));
      expect(p2.caliber,       equals(p1.caliber));
      expect(p2.bcType,        equals(p1.bcType));
      expect(p2.twistDir,      equals(p1.twistDir));
      expect(p2.zeroX,         equals(p1.zeroX));
      expect(p2.zeroY,         equals(p1.zeroY));
      expect(p2.distances,     equals(p1.distances));
      expect(p2.coefRows.length, equals(p1.coefRows.length));
      expect(p2.switches.length, equals(p1.switches.length));
    });
  });

  // ─── validate ─────────────────────────────────────────────────────────────

  group('validate', () {
    // Helper: rebuild profile with one field overridden.
    Profile withField(Profile p, {
      String? profileName,
      String? cartridgeName,
      String? bulletName,
      String? shortNameTop,
      String? shortNameBot,
      String? caliber,
      int? zeroX,
      int? zeroY,
      int? scHeight,
      int? rTwist,
      int? cMuzzleVelocity,
      int? cZeroTemperature,
      int? cTCoeff,
      int? cZeroDistanceIdx,
      int? cZeroAirTemperature,
      int? cZeroAirPressure,
      int? cZeroAirHumidity,
      int? cZeroWPitch,
      int? cZeroPTemperature,
      int? bDiameter,
      int? bWeight,
      int? bLength,
      GType? bcType,
      List<CoefRow>? coefRows,
      List<SwPos>? switches,
      List<int>? distances,
    }) => Profile(
      profileName:         profileName         ?? p.profileName,
      cartridgeName:       cartridgeName       ?? p.cartridgeName,
      bulletName:          bulletName          ?? p.bulletName,
      shortNameTop:        shortNameTop        ?? p.shortNameTop,
      shortNameBot:        shortNameBot        ?? p.shortNameBot,
      userNote:            p.userNote,
      caliber:             caliber             ?? p.caliber,
      deviceUuid:          p.deviceUuid,
      zeroX:               zeroX               ?? p.zeroX,
      zeroY:               zeroY               ?? p.zeroY,
      scHeight:            scHeight            ?? p.scHeight,
      rTwist:              rTwist              ?? p.rTwist,
      twistDir:            p.twistDir,
      cMuzzleVelocity:     cMuzzleVelocity     ?? p.cMuzzleVelocity,
      cZeroTemperature:    cZeroTemperature    ?? p.cZeroTemperature,
      cTCoeff:             cTCoeff             ?? p.cTCoeff,
      cZeroDistanceIdx:    cZeroDistanceIdx    ?? p.cZeroDistanceIdx,
      cZeroAirTemperature: cZeroAirTemperature ?? p.cZeroAirTemperature,
      cZeroAirPressure:    cZeroAirPressure    ?? p.cZeroAirPressure,
      cZeroAirHumidity:    cZeroAirHumidity    ?? p.cZeroAirHumidity,
      cZeroWPitch:         cZeroWPitch         ?? p.cZeroWPitch,
      cZeroPTemperature:   cZeroPTemperature   ?? p.cZeroPTemperature,
      bDiameter:           bDiameter           ?? p.bDiameter,
      bWeight:             bWeight             ?? p.bWeight,
      bLength:             bLength             ?? p.bLength,
      bcType:              bcType              ?? p.bcType,
      coefRows:            coefRows            ?? p.coefRows,
      switches:            switches            ?? p.switches,
      distances:           distances           ?? p.distances,
    );

    late Profile good;

    setUpAll(() {
      good = decode(loadExample()).profile;
    });

    test('valid example passes validation', () {
      expect(() => validate(Payload(profile: good)), returnsNormally);
    });

    test('empty profileName fails', () {
      final bad = withField(good, profileName: '');
      expect(
        () => validate(Payload(profile: bad)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('profileName > 50 chars fails', () {
      final bad = withField(good, profileName: 'x' * 51);
      expect(
        () => validate(Payload(profile: bad)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('zeroX out of range fails', () {
      final bad = withField(good, zeroX: 999999);
      expect(
        () => validate(Payload(profile: bad)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('cMuzzleVelocity below min fails', () {
      final bad = withField(good, cMuzzleVelocity: 50);
      expect(
        () => validate(Payload(profile: bad)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('cZeroWPitch out of range fails', () {
      final bad = withField(good, cZeroWPitch: 91);
      expect(
        () => validate(Payload(profile: bad)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('empty distances fails', () {
      final bad = withField(good, distances: []);
      expect(
        () => validate(Payload(profile: bad)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('fewer than 4 switches fails', () {
      final bad = withField(good, switches: good.switches.take(2).toList());
      expect(
        () => validate(Payload(profile: bad)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('G1/G7: more than 5 coefRows fails', () {
      if (good.bcType == GType.custom) return; // skip for CUSTOM profiles
      final bad = withField(
        good,
        coefRows: List.generate(6, (i) => CoefRow(bcCd: i + 1, mv: i * 100)),
      );
      expect(
        () => validate(Payload(profile: bad)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('duplicate mv values (non-zero) fail', () {
      if (good.bcType == GType.custom) return;
      final bad = withField(
        good,
        coefRows: [
          const CoefRow(bcCd: 300, mv: 900),
          const CoefRow(bcCd: 310, mv: 900), // duplicate
        ],
      );
      expect(
        () => validate(Payload(profile: bad)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('ValidationException contains error messages', () {
      final bad = withField(good, profileName: '', cartridgeName: '');
      try {
        validate(Payload(profile: bad));
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.errors, hasLength(greaterThanOrEqualTo(2)));
        expect(e.errors.any((s) => s.contains('profileName')), isTrue);
        expect(e.errors.any((s) => s.contains('cartridgeName')), isTrue);
      }
    });
  });
}
