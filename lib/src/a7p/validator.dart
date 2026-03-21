import 'errors.dart';
import 'profedit.pb.dart';
import 'profedit.pbenum.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

void _str(List<String> e, String field, String v, {required int max, bool req = false}) {
  if (req && v.isEmpty) e.add('$field is required');
  if (v.length > max)   e.add('$field must be ≤ $max chars (got ${v.length})');
}

void _int(List<String> e, String field, int v, {required int min, required int max}) {
  if (v < min || v > max) e.add('$field must be $min–$max (got $v)');
}

// ─── CoefRow schemas ─────────────────────────────────────────────────────────

void _coefRowsStandard(List<String> e, List<CoefRow> rows) {
  if (rows.isEmpty || rows.length > 5) {
    e.add('coefRows: G1/G7 requires 1–5 items (got ${rows.length})');
  }
  for (var i = 0; i < rows.length; i++) {
    _int(e, 'coefRows[$i].bcCd', rows[i].bcCd, min: 0, max: 10000);
    _int(e, 'coefRows[$i].mv',   rows[i].mv,   min: 0, max: 30000);
  }
  _uniqueMv(e, rows);
}

void _coefRowsCustom(List<String> e, List<CoefRow> rows) {
  if (rows.isEmpty || rows.length > 200) {
    e.add('coefRows: CUSTOM requires 1–200 items (got ${rows.length})');
  }
  for (var i = 0; i < rows.length; i++) {
    _int(e, 'coefRows[$i].bcCd', rows[i].bcCd, min: 0, max: 10000);
    _int(e, 'coefRows[$i].mv',   rows[i].mv,   min: 0, max: 10000);
  }
  _uniqueMv(e, rows);
}

void _uniqueMv(List<String> e, List<CoefRow> rows) {
  final nonZero = rows.map((r) => r.mv).where((mv) => mv != 0).toList();
  if (nonZero.toSet().length != nonZero.length) {
    e.add('coefRows: mv values must be unique (except 0)');
  }
}

// ─── Public API ──────────────────────────────────────────────────────────────

/// Validates [payload] against all schema rules.
/// Throws [ValidationException] with the full list of errors if invalid.
void validate(Payload payload, {bool abortEarly = false}) {
  final e = <String>[];
  final p = payload.profile;

  void add(String msg) {
    e.add(msg);
    if (abortEarly) throw ValidationException(e);
  }

  void str(String f, String v, {required int max, bool req = false}) {
    final tmp = <String>[];
    _str(tmp, f, v, max: max, req: req);
    tmp.forEach(add);
  }

  void checkInt(String f, int v, {required int min, required int max}) {
    final tmp = <String>[];
    _int(tmp, f, v, min: min, max: max);
    tmp.forEach(add);
  }

  // ── Descriptor ──────────────────────────────────────────────────────────────
  str('profileName',   p.profileName,   max: 50,   req: true);
  str('cartridgeName', p.cartridgeName, max: 50,   req: true);
  str('bulletName',    p.bulletName,    max: 50,   req: true);
  str('shortNameTop',  p.shortNameTop,  max: 8,    req: true);
  str('shortNameBot',  p.shortNameBot,  max: 8,    req: true);
  str('caliber',       p.caliber,       max: 50,   req: true);
  str('deviceUuid',    p.deviceUuid,    max: 50);
  str('userNote',      p.userNote,      max: 1024);

  // ── Zeroing ─────────────────────────────────────────────────────────────────
  checkInt('zeroX', p.zeroX, min: -200000, max: 200000);
  checkInt('zeroY', p.zeroY, min: -200000, max: 200000);

  // ── Rifle ───────────────────────────────────────────────────────────────────
  checkInt('scHeight', p.scHeight, min: -5000,  max: 5000);
  checkInt('rTwist',   p.rTwist,   min: 0,      max: 10000);

  // ── Cartridge ───────────────────────────────────────────────────────────────
  checkInt('cMuzzleVelocity',  p.cMuzzleVelocity,  min: 100,  max: 30000);
  checkInt('cZeroTemperature', p.cZeroTemperature, min: -100, max: 100);
  checkInt('cTCoeff',          p.cTCoeff,          min: 0,    max: 5000);

  // ── Zero conditions ─────────────────────────────────────────────────────────
  checkInt('cZeroDistanceIdx',    p.cZeroDistanceIdx,    min: 0,    max: 255);
  checkInt('cZeroAirTemperature', p.cZeroAirTemperature, min: -100, max: 100);
  checkInt('cZeroAirPressure',    p.cZeroAirPressure,    min: 3000, max: 15000);
  checkInt('cZeroAirHumidity',    p.cZeroAirHumidity,    min: 0,    max: 100);
  checkInt('cZeroWPitch',         p.cZeroWPitch,         min: -90,  max: 90);
  checkInt('cZeroPTemperature',   p.cZeroPTemperature,   min: -100, max: 100);

  // ── Bullet ──────────────────────────────────────────────────────────────────
  checkInt('bDiameter', p.bDiameter, min: 1,  max: 50000);
  checkInt('bWeight',   p.bWeight,   min: 10, max: 65535);
  checkInt('bLength',   p.bLength,   min: 1,  max: 200000);

  // ── Distances ───────────────────────────────────────────────────────────────
  if (p.distances.isEmpty || p.distances.length > 200) {
    add('distances must have 1–200 items (got ${p.distances.length})');
  }
  for (var i = 0; i < p.distances.length; i++) {
    _int(e, 'distances[$i]', p.distances[i], min: 100, max: 300000);
  }

  // ── Switches ────────────────────────────────────────────────────────────────
  if (p.switches.length < 4) {
    add('switches must have ≥ 4 items (got ${p.switches.length})');
  }
  for (var i = 0; i < p.switches.length; i++) {
    final s   = p.switches[i];
    final pfx = 'switches[$i]';
    _int(e, '$pfx.cIdx',       s.cIdx,       min: 0, max: 255);
    _int(e, '$pfx.reticleIdx', s.reticleIdx, min: 0, max: 255);
    _int(e, '$pfx.zoom',       s.zoom,       min: 0, max: 255);
    final byValue = s.distanceFrom == DType.VALUE;
    _int(e, '$pfx.distance', s.distance,
      min: byValue ? 100 : 0,
      max: byValue ? 300000 : 255,
    );
  }

  // ── Drag model ──────────────────────────────────────────────────────────────
  final coefErrors = <String>[];
  if (p.bcType == GType.CUSTOM) {
    _coefRowsCustom(coefErrors, p.coefRows);
  } else {
    _coefRowsStandard(coefErrors, p.coefRows); // G1 and G7
  }
  coefErrors.forEach(add);

  if (e.isNotEmpty) throw ValidationException(e);
}
