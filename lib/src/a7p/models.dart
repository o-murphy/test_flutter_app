// Pure Dart data classes mirroring the profedit.proto schema.
// Naming follows camelCase Dart conventions (snake_case proto names mapped 1-to-1).

enum DType { value, idx }

enum GType { g1, g7, custom }

enum TwistDir { right, left }

class CoefRow {
  final int bcCd;
  final int mv;

  const CoefRow({this.bcCd = 0, this.mv = 0});

  @override
  String toString() => 'CoefRow(bcCd: $bcCd, mv: $mv)';
}

class SwPos {
  final int cIdx;
  final int reticleIdx;
  final int zoom;
  final int distance;
  final DType distanceFrom;

  const SwPos({
    this.cIdx = 0,
    this.reticleIdx = 0,
    this.zoom = 0,
    this.distance = 0,
    this.distanceFrom = DType.value,
  });

  @override
  String toString() =>
      'SwPos(cIdx: $cIdx, reticleIdx: $reticleIdx, zoom: $zoom, '
      'distance: $distance, distanceFrom: $distanceFrom)';
}

class Profile {
  // ── Descriptor ──────────────────────────────────────────────────────────────
  final String profileName;
  final String cartridgeName;
  final String bulletName;
  final String shortNameTop;
  final String shortNameBot;
  final String userNote;
  final String caliber;
  final String deviceUuid;

  // ── Zeroing ─────────────────────────────────────────────────────────────────
  final int zeroX;
  final int zeroY;

  // ── Rifle ───────────────────────────────────────────────────────────────────
  final int scHeight;
  final int rTwist;
  final TwistDir twistDir;

  // ── Cartridge ───────────────────────────────────────────────────────────────
  final int cMuzzleVelocity;
  final int cZeroTemperature;
  final int cTCoeff;

  // ── Zero conditions ─────────────────────────────────────────────────────────
  final int cZeroDistanceIdx;
  final int cZeroAirTemperature;
  final int cZeroAirPressure;
  final int cZeroAirHumidity;
  final int cZeroWPitch;
  final int cZeroPTemperature;

  // ── Bullet ──────────────────────────────────────────────────────────────────
  final int bDiameter;
  final int bWeight;
  final int bLength;

  // ── Drag model ──────────────────────────────────────────────────────────────
  final GType bcType;
  final List<CoefRow> coefRows;

  // ── Lists ───────────────────────────────────────────────────────────────────
  final List<SwPos> switches;
  final List<int> distances;

  const Profile({
    this.profileName = '',
    this.cartridgeName = '',
    this.bulletName = '',
    this.shortNameTop = '',
    this.shortNameBot = '',
    this.userNote = '',
    this.caliber = '',
    this.deviceUuid = '',
    this.zeroX = 0,
    this.zeroY = 0,
    this.scHeight = 0,
    this.rTwist = 0,
    this.twistDir = TwistDir.right,
    this.cMuzzleVelocity = 0,
    this.cZeroTemperature = 0,
    this.cTCoeff = 0,
    this.cZeroDistanceIdx = 0,
    this.cZeroAirTemperature = 0,
    this.cZeroAirPressure = 0,
    this.cZeroAirHumidity = 0,
    this.cZeroWPitch = 0,
    this.cZeroPTemperature = 0,
    this.bDiameter = 0,
    this.bWeight = 0,
    this.bLength = 0,
    this.bcType = GType.g1,
    this.coefRows = const [],
    this.switches = const [],
    this.distances = const [],
  });
}

class Payload {
  final Profile profile;
  const Payload({required this.profile});
}
