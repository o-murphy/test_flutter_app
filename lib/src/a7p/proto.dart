// Low-level protobuf binary encoder / decoder.
//
// Supports only the wire types used by profedit.proto:
//   • Wire type 0 — varint  (int32, enum)
//   • Wire type 2 — length-delimited (string, embedded message, packed repeated)

import 'dart:convert';
import 'dart:typed_data';

import 'errors.dart';
import 'models.dart';

// ─── Wire types ──────────────────────────────────────────────────────────────

const _wtVarint = 0;
const _wtLen    = 2;

// ─── Reader ──────────────────────────────────────────────────────────────────

class _Reader {
  final Uint8List _buf;
  int _pos = 0;

  _Reader(this._buf);

  bool get hasMore => _pos < _buf.length;

  /// Reads an unsigned varint (up to 64-bit; Dart int is int64).
  int varint() {
    int result = 0;
    int shift  = 0;
    while (true) {
      if (_pos >= _buf.length) throw const DecodeException('Unexpected end of buffer');
      final b = _buf[_pos++];
      result |= (b & 0x7F) << shift;
      if (b & 0x80 == 0) return result;
      shift += 7;
    }
  }

  /// Returns (fieldNumber, wireType).
  (int, int) tag() {
    final t = varint();
    return (t >> 3, t & 0x7);
  }

  /// Reads a length-prefixed byte blob.
  Uint8List bytes() {
    final len = varint();
    if (_pos + len > _buf.length) throw const DecodeException('Truncated length-delimited field');
    final data = Uint8List.sublistView(_buf, _pos, _pos + len);
    _pos += len;
    return data;
  }

  String str() => utf8.decode(bytes());

  /// Reads a packed repeated int32 field.
  List<int> packedInt32() {
    final raw = bytes();
    final inner = _Reader(raw);
    final result = <int>[];
    while (inner.hasMore) {
      result.add(inner.varint());
    }
    return result;
  }

  /// Skips an unknown field.
  void skip(int wireType) {
    switch (wireType) {
      case _wtVarint: varint();
      case _wtLen:    final len = varint(); _pos += len;
      default: throw DecodeException('Unknown wire type $wireType');
    }
  }
}

// ─── Writer ──────────────────────────────────────────────────────────────────

class _Writer {
  final List<int> _buf = [];

  /// Writes an unsigned varint using unsigned right-shift (>>>).
  void varint(int value) {
    do {
      var byte = value & 0x7F;
      value = value >>> 7;
      if (value != 0) byte |= 0x80;
      _buf.add(byte);
    } while (value != 0);
  }

  void _tag(int fieldNum, int wireType) => varint((fieldNum << 3) | wireType);

  /// Writes a varint field (int32 or enum). Skips if value == 0 (proto3 default).
  void int32(int fieldNum, int value) {
    if (value == 0) return;
    _tag(fieldNum, _wtVarint);
    // Negative int32 must be encoded as 64-bit (10-byte) varint.
    // Dart int is already 64-bit signed, so varint() handles it correctly via >>>.
    varint(value);
  }

  void str(int fieldNum, String value) {
    if (value.isEmpty) return;
    final encoded = utf8.encode(value);
    _tag(fieldNum, _wtLen);
    varint(encoded.length);
    _buf.addAll(encoded);
  }

  void enumVal(int fieldNum, int value) => int32(fieldNum, value);

  void message(int fieldNum, _Writer nested) {
    final bytes = nested.toBytes();
    _tag(fieldNum, _wtLen);
    varint(bytes.length);
    _buf.addAll(bytes);
  }

  /// Writes a packed repeated int32 field.
  void packedInt32(int fieldNum, List<int> values) {
    if (values.isEmpty) return;
    final inner = _Writer();
    for (final v in values) {
      inner.varint(v);
    }
    message(fieldNum, inner);
  }

  Uint8List toBytes() => Uint8List.fromList(_buf);
}

// ─── Enum helpers ─────────────────────────────────────────────────────────────

DType   _decodeDType(int v)   => v == 1 ? DType.idx : DType.value;
GType   _decodeGType(int v)   => GType.values[v.clamp(0, GType.values.length - 1)];
TwistDir _decodeTwist(int v)  => v == 1 ? TwistDir.left : TwistDir.right;

int _encodeDType(DType v)    => v == DType.idx ? 1 : 0;
int _encodeGType(GType v)    => v.index;
int _encodeTwist(TwistDir v) => v == TwistDir.left ? 1 : 0;

// ─── CoefRow ─────────────────────────────────────────────────────────────────

CoefRow _decodeCoefRow(Uint8List buf) {
  final r = _Reader(buf);
  int bcCd = 0, mv = 0;
  while (r.hasMore) {
    final (field, wt) = r.tag();
    switch (field) {
      case 1: bcCd = r.varint();
      case 2: mv   = r.varint();
      default: r.skip(wt);
    }
  }
  return CoefRow(bcCd: bcCd, mv: mv);
}

Uint8List _encodeCoefRow(CoefRow c) {
  final w = _Writer();
  w.int32(1, c.bcCd);
  w.int32(2, c.mv);
  return w.toBytes();
}

// ─── SwPos ───────────────────────────────────────────────────────────────────

SwPos _decodeSwPos(Uint8List buf) {
  final r = _Reader(buf);
  int cIdx = 0, reticleIdx = 0, zoom = 0, distance = 0;
  DType distanceFrom = DType.value;
  while (r.hasMore) {
    final (field, wt) = r.tag();
    switch (field) {
      case 1: cIdx         = r.varint();
      case 2: reticleIdx   = r.varint();
      case 3: zoom         = r.varint();
      case 4: distance     = r.varint();
      case 5: distanceFrom = _decodeDType(r.varint());
      default: r.skip(wt);
    }
  }
  return SwPos(
    cIdx: cIdx,
    reticleIdx: reticleIdx,
    zoom: zoom,
    distance: distance,
    distanceFrom: distanceFrom,
  );
}

Uint8List _encodeSwPos(SwPos s) {
  final w = _Writer();
  w.int32(1, s.cIdx);
  w.int32(2, s.reticleIdx);
  w.int32(3, s.zoom);
  w.int32(4, s.distance);
  w.enumVal(5, _encodeDType(s.distanceFrom));
  return w.toBytes();
}

// ─── Profile ─────────────────────────────────────────────────────────────────

Profile _decodeProfile(Uint8List buf) {
  final r = _Reader(buf);

  String profileName = '', cartridgeName = '', bulletName = '';
  String shortNameTop = '', shortNameBot = '', userNote = '';
  String caliber = '', deviceUuid = '';
  int zeroX = 0, zeroY = 0;
  int scHeight = 0, rTwist = 0;
  int cMuzzleVelocity = 0, cZeroTemperature = 0, cTCoeff = 0;
  int cZeroDistanceIdx = 0, cZeroAirTemperature = 0;
  int cZeroAirPressure = 0, cZeroAirHumidity = 0;
  int cZeroWPitch = 0, cZeroPTemperature = 0;
  int bDiameter = 0, bWeight = 0, bLength = 0;
  TwistDir twistDir = TwistDir.right;
  GType bcType = GType.g1;
  final switches  = <SwPos>[];
  final distances = <int>[];
  final coefRows  = <CoefRow>[];

  while (r.hasMore) {
    final (field, wt) = r.tag();
    switch (field) {
      case 1:  profileName         = r.str();
      case 2:  cartridgeName       = r.str();
      case 3:  bulletName          = r.str();
      case 4:  shortNameTop        = r.str();
      case 5:  shortNameBot        = r.str();
      case 6:  userNote            = r.str();
      case 7:  zeroX               = r.varint();
      case 8:  zeroY               = r.varint();
      case 9:  scHeight            = r.varint();
      case 10: rTwist              = r.varint();
      case 11: cMuzzleVelocity     = r.varint();
      case 12: cZeroTemperature    = r.varint();
      case 13: cTCoeff             = r.varint();
      case 14: cZeroDistanceIdx    = r.varint();
      case 15: cZeroAirTemperature = r.varint();
      case 16: cZeroAirPressure    = r.varint();
      case 17: cZeroAirHumidity    = r.varint();
      case 18: cZeroWPitch         = r.varint();
      case 19: cZeroPTemperature   = r.varint();
      case 20: bDiameter           = r.varint();
      case 21: bWeight             = r.varint();
      case 22: bLength             = r.varint();
      case 23: twistDir            = _decodeTwist(r.varint());
      case 24: bcType              = _decodeGType(r.varint());
      case 25: switches.add(_decodeSwPos(r.bytes()));
      case 26: distances.addAll(r.packedInt32());
      case 27: coefRows.add(_decodeCoefRow(r.bytes()));
      case 28: caliber             = r.str();
      case 29: deviceUuid          = r.str();
      default: r.skip(wt);
    }
  }

  return Profile(
    profileName: profileName,
    cartridgeName: cartridgeName,
    bulletName: bulletName,
    shortNameTop: shortNameTop,
    shortNameBot: shortNameBot,
    userNote: userNote,
    caliber: caliber,
    deviceUuid: deviceUuid,
    zeroX: zeroX,
    zeroY: zeroY,
    scHeight: scHeight,
    rTwist: rTwist,
    twistDir: twistDir,
    cMuzzleVelocity: cMuzzleVelocity,
    cZeroTemperature: cZeroTemperature,
    cTCoeff: cTCoeff,
    cZeroDistanceIdx: cZeroDistanceIdx,
    cZeroAirTemperature: cZeroAirTemperature,
    cZeroAirPressure: cZeroAirPressure,
    cZeroAirHumidity: cZeroAirHumidity,
    cZeroWPitch: cZeroWPitch,
    cZeroPTemperature: cZeroPTemperature,
    bDiameter: bDiameter,
    bWeight: bWeight,
    bLength: bLength,
    bcType: bcType,
    coefRows: coefRows,
    switches: switches,
    distances: distances,
  );
}

Uint8List _encodeProfile(Profile p) {
  final w = _Writer();
  w.str(1, p.profileName);
  w.str(2, p.cartridgeName);
  w.str(3, p.bulletName);
  w.str(4, p.shortNameTop);
  w.str(5, p.shortNameBot);
  w.str(6, p.userNote);
  w.int32(7, p.zeroX);
  w.int32(8, p.zeroY);
  w.int32(9, p.scHeight);
  w.int32(10, p.rTwist);
  w.int32(11, p.cMuzzleVelocity);
  w.int32(12, p.cZeroTemperature);
  w.int32(13, p.cTCoeff);
  w.int32(14, p.cZeroDistanceIdx);
  w.int32(15, p.cZeroAirTemperature);
  w.int32(16, p.cZeroAirPressure);
  w.int32(17, p.cZeroAirHumidity);
  w.int32(18, p.cZeroWPitch);
  w.int32(19, p.cZeroPTemperature);
  w.int32(20, p.bDiameter);
  w.int32(21, p.bWeight);
  w.int32(22, p.bLength);
  w.enumVal(23, _encodeTwist(p.twistDir));
  w.enumVal(24, _encodeGType(p.bcType));
  for (final s in p.switches) {
    final bytes = _encodeSwPos(s);
    w._tag(25, _wtLen);
    w.varint(bytes.length);
    w._buf.addAll(bytes);
  }
  w.packedInt32(26, p.distances);
  for (final c in p.coefRows) {
    final bytes = _encodeCoefRow(c);
    w._tag(27, _wtLen);
    w.varint(bytes.length);
    w._buf.addAll(bytes);
  }
  w.str(28, p.caliber);
  w.str(29, p.deviceUuid);
  return w.toBytes();
}

// ─── Payload ─────────────────────────────────────────────────────────────────

/// Deserializes a raw protobuf buffer into [Payload].
Payload parsePayload(Uint8List buf) {
  final r = _Reader(buf);
  Profile? profile;
  while (r.hasMore) {
    final (field, wt) = r.tag();
    switch (field) {
      case 1: profile = _decodeProfile(r.bytes());
      default: r.skip(wt);
    }
  }
  if (profile == null) throw const DecodeException('Missing required field: profile');
  return Payload(profile: profile);
}

/// Serializes a [Payload] into a raw protobuf buffer.
Uint8List serializePayload(Payload payload) {
  final profileBytes = _encodeProfile(payload.profile);
  final w = _Writer();
  w._tag(1, _wtLen);
  w.varint(profileBytes.length);
  w._buf.addAll(profileBytes);
  return w.toBytes();
}
