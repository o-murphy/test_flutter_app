import '../proto/profedit.pb.dart';

/// Validation error for a single field.
class A7pFieldError {
  final String field;
  final String message;
  const A7pFieldError(this.field, this.message);

  @override
  String toString() => '$field: $message';
}

/// Thrown when [A7pValidator.validate] finds errors.
class A7pValidationException implements Exception {
  final List<A7pFieldError> errors;
  const A7pValidationException(this.errors);

  @override
  String toString() => 'A7P validation failed:\n${errors.join('\n')}';
}

class A7pValidator {
  /// Validates [payload] and throws [A7pValidationException] if invalid.
  static void validate(Payload payload) {
    final errors = <A7pFieldError>[];
    if (!payload.hasProfile()) {
      errors.add(const A7pFieldError('payload', 'missing profile'));
      throw A7pValidationException(errors);
    }
    _validateProfile(payload.profile, errors);
    if (errors.isNotEmpty) throw A7pValidationException(errors);
  }

  static void _validateProfile(Profile p, List<A7pFieldError> errors) {
    // ── String fields ─────────────────────────────────────────────────────────
    _requireString(errors, 'profile_name', p.profileName, maxLen: 50);
    _requireString(errors, 'cartridge_name', p.cartridgeName, maxLen: 50);
    _requireString(errors, 'bullet_name', p.bulletName, maxLen: 50);
    _requireString(errors, 'caliber', p.caliber, maxLen: 50);
    _requireString(errors, 'short_name_top', p.shortNameTop, maxLen: 8);
    _requireString(errors, 'short_name_bot', p.shortNameBot, maxLen: 8);

    // user_note and device_uuid are optional strings — no range check needed.

    // ── Weapon / sight ────────────────────────────────────────────────────────
    _checkRange(errors, 'sc_height', p.scHeight, -5000, 5000); // mm ×1
    _checkRange(errors, 'r_twist', p.rTwist, 0, 10000); // inch ×100
    _checkRange(errors, 'zero_x', p.zeroX, -200000, 200000);
    _checkRange(errors, 'zero_y', p.zeroY, -200000, 200000);

    // ── Cartridge ─────────────────────────────────────────────────────────────
    _checkRange(
      errors,
      'c_muzzle_velocity',
      p.cMuzzleVelocity,
      10,
      30000,
    ); // m/s ×10
    _checkRange(
      errors,
      'c_zero_temperature',
      p.cZeroTemperature,
      -100,
      100,
    ); // °C
    _checkRange(errors, 'c_t_coeff', p.cTCoeff, 0, 5000); // %/15°C ×1000
    _checkRange(
      errors,
      'c_zero_p_temperature',
      p.cZeroPTemperature,
      -100,
      100,
    ); // °C

    // ── Zero conditions ───────────────────────────────────────────────────────
    _checkRange(
      errors,
      'c_zero_air_temperature',
      p.cZeroAirTemperature,
      -100,
      100,
    ); // °C
    _checkRange(
      errors,
      'c_zero_air_pressure',
      p.cZeroAirPressure,
      3000,
      15000,
    ); // hPa ×10
    _checkRange(errors, 'c_zero_air_humidity', p.cZeroAirHumidity, 0, 100); // %

    // ── Bullet ────────────────────────────────────────────────────────────────
    _checkRange(errors, 'b_diameter', p.bDiameter, 1, 50000); // inch ×1000
    _checkRange(errors, 'b_weight', p.bWeight, 1, 65535); // grain ×10
    _checkRange(errors, 'b_length', p.bLength, 0, 200000); // inch ×1000

    // ── Distances ─────────────────────────────────────────────────────────────
    final dists = p.distances;
    if (dists.isEmpty || dists.length > 200) {
      errors.add(
        A7pFieldError(
          'distances',
          'must have 1–200 items, got ${dists.length}',
        ),
      );
    } else {
      for (var i = 0; i < dists.length; i++) {
        _checkRange(errors, 'distances[$i]', dists[i], 100, 300000);
      }
      // zero_distance_idx must be a valid index
      _checkRange(
        errors,
        'c_zero_distance_idx',
        p.cZeroDistanceIdx,
        0,
        dists.length - 1,
      );
    }

    // ── Switches ──────────────────────────────────────────────────────────────
    if (p.switches.length < 4) {
      errors.add(
        A7pFieldError(
          'switches',
          'must have at least 4 items, got ${p.switches.length}',
        ),
      );
    } else {
      for (var i = 0; i < p.switches.length; i++) {
        _validateSwPos(p.switches[i], i, errors);
      }
    }

    // ── coef_rows (drag model) ────────────────────────────────────────────────
    _validateCoefRows(p.coefRows, p.bcType, errors);
  }

  static void _validateSwPos(SwPos sw, int idx, List<A7pFieldError> errors) {
    _checkRange(errors, 'switches[$idx].reticle_idx', sw.reticleIdx, 0, 255);
    _checkRange(errors, 'switches[$idx].zoom', sw.zoom, 1, 6);
    if (sw.distanceFrom == DType.VALUE) {
      _checkRange(errors, 'switches[$idx].distance', sw.distance, 100, 300000);
    } else {
      // INDEX type: distance is an index (0–255)
      _checkRange(errors, 'switches[$idx].distance', sw.distance, 0, 255);
    }
    _checkRange(errors, 'switches[$idx].c_idx', sw.cIdx, 0, 255);
  }

  static void _validateCoefRows(
    List<CoefRow> rows,
    GType bcType,
    List<A7pFieldError> errors,
  ) {
    final isCustom = bcType == GType.CUSTOM;
    final maxItems = isCustom ? 200 : 5;
    final maxMv = isCustom ? 10000 : 30000;

    if (rows.isEmpty || rows.length > maxItems) {
      errors.add(
        A7pFieldError(
          'coef_rows',
          'must have 1–$maxItems items for $bcType, got ${rows.length}',
        ),
      );
      return;
    }

    final seenMv = <int>{};
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      _checkRange(errors, 'coef_rows[$i].bc_cd', r.bcCd, 0, 10000);
      _checkRange(errors, 'coef_rows[$i].mv', r.mv, 0, maxMv);

      // mv == 0 is the "single-BC" sentinel — allowed to repeat (only one row
      // should have mv == 0, but multi-BC tables use non-zero mv values that
      // must be unique)
      if (r.mv != 0) {
        if (!seenMv.add(r.mv)) {
          errors.add(
            A7pFieldError('coef_rows[$i].mv', 'duplicate mv value ${r.mv}'),
          );
        }
      }
    }
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  static void _requireString(
    List<A7pFieldError> errors,
    String field,
    String value, {
    required int maxLen,
  }) {
    if (value.isEmpty) {
      errors.add(A7pFieldError(field, 'required'));
    } else if (value.length > maxLen) {
      errors.add(
        A7pFieldError(field, 'max $maxLen chars, got ${value.length}'),
      );
    }
  }

  static void _checkRange(
    List<A7pFieldError> errors,
    String field,
    int value,
    int min,
    int max,
  ) {
    if (value < min || value > max) {
      errors.add(A7pFieldError(field, 'must be $min–$max, got $value'));
    }
  }
}
