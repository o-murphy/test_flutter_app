// This is a generated file - do not edit.
//
// Generated from profedit.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'profedit.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'profedit.pbenum.dart';

class Payload extends $pb.GeneratedMessage {
  factory Payload({
    Profile? profile,
  }) {
    final result = create();
    if (profile != null) result.profile = profile;
    return result;
  }

  Payload._();

  factory Payload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Payload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Payload',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'profedit'),
      createEmptyInstance: create)
    ..aOM<Profile>(1, _omitFieldNames ? '' : 'profile',
        subBuilder: Profile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Payload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Payload copyWith(void Function(Payload) updates) =>
      super.copyWith((message) => updates(message as Payload)) as Payload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Payload create() => Payload._();
  @$core.override
  Payload createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Payload getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Payload>(create);
  static Payload? _defaultInstance;

  @$pb.TagNumber(1)
  Profile get profile => $_getN(0);
  @$pb.TagNumber(1)
  set profile(Profile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProfile() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfile() => $_clearField(1);
  @$pb.TagNumber(1)
  Profile ensureProfile() => $_ensure(0);
}

class CoefRow extends $pb.GeneratedMessage {
  factory CoefRow({
    $core.int? bcCd,
    $core.int? mv,
  }) {
    final result = create();
    if (bcCd != null) result.bcCd = bcCd;
    if (mv != null) result.mv = mv;
    return result;
  }

  CoefRow._();

  factory CoefRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CoefRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CoefRow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'profedit'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'bcCd')
    ..aI(2, _omitFieldNames ? '' : 'mv')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CoefRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CoefRow copyWith(void Function(CoefRow) updates) =>
      super.copyWith((message) => updates(message as CoefRow)) as CoefRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CoefRow create() => CoefRow._();
  @$core.override
  CoefRow createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CoefRow getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CoefRow>(create);
  static CoefRow? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get bcCd => $_getIZ(0);
  @$pb.TagNumber(1)
  set bcCd($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBcCd() => $_has(0);
  @$pb.TagNumber(1)
  void clearBcCd() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get mv => $_getIZ(1);
  @$pb.TagNumber(2)
  set mv($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMv() => $_has(1);
  @$pb.TagNumber(2)
  void clearMv() => $_clearField(2);
}

class SwPos extends $pb.GeneratedMessage {
  factory SwPos({
    $core.int? cIdx,
    $core.int? reticleIdx,
    $core.int? zoom,
    $core.int? distance,
    DType? distanceFrom,
  }) {
    final result = create();
    if (cIdx != null) result.cIdx = cIdx;
    if (reticleIdx != null) result.reticleIdx = reticleIdx;
    if (zoom != null) result.zoom = zoom;
    if (distance != null) result.distance = distance;
    if (distanceFrom != null) result.distanceFrom = distanceFrom;
    return result;
  }

  SwPos._();

  factory SwPos.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SwPos.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SwPos',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'profedit'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'cIdx')
    ..aI(2, _omitFieldNames ? '' : 'reticleIdx')
    ..aI(3, _omitFieldNames ? '' : 'zoom')
    ..aI(4, _omitFieldNames ? '' : 'distance')
    ..aE<DType>(5, _omitFieldNames ? '' : 'distanceFrom',
        enumValues: DType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SwPos clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SwPos copyWith(void Function(SwPos) updates) =>
      super.copyWith((message) => updates(message as SwPos)) as SwPos;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SwPos create() => SwPos._();
  @$core.override
  SwPos createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SwPos getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SwPos>(create);
  static SwPos? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get cIdx => $_getIZ(0);
  @$pb.TagNumber(1)
  set cIdx($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCIdx() => $_has(0);
  @$pb.TagNumber(1)
  void clearCIdx() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get reticleIdx => $_getIZ(1);
  @$pb.TagNumber(2)
  set reticleIdx($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReticleIdx() => $_has(1);
  @$pb.TagNumber(2)
  void clearReticleIdx() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get zoom => $_getIZ(2);
  @$pb.TagNumber(3)
  set zoom($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasZoom() => $_has(2);
  @$pb.TagNumber(3)
  void clearZoom() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get distance => $_getIZ(3);
  @$pb.TagNumber(4)
  set distance($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDistance() => $_has(3);
  @$pb.TagNumber(4)
  void clearDistance() => $_clearField(4);

  @$pb.TagNumber(5)
  DType get distanceFrom => $_getN(4);
  @$pb.TagNumber(5)
  set distanceFrom(DType value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDistanceFrom() => $_has(4);
  @$pb.TagNumber(5)
  void clearDistanceFrom() => $_clearField(5);
}

class Profile extends $pb.GeneratedMessage {
  factory Profile({
    $core.String? profileName,
    $core.String? cartridgeName,
    $core.String? bulletName,
    $core.String? shortNameTop,
    $core.String? shortNameBot,
    $core.String? userNote,
    $core.int? zeroX,
    $core.int? zeroY,
    $core.int? scHeight,
    $core.int? rTwist,
    $core.int? cMuzzleVelocity,
    $core.int? cZeroTemperature,
    $core.int? cTCoeff,
    $core.int? cZeroDistanceIdx,
    $core.int? cZeroAirTemperature,
    $core.int? cZeroAirPressure,
    $core.int? cZeroAirHumidity,
    $core.int? cZeroWPitch,
    $core.int? cZeroPTemperature,
    $core.int? bDiameter,
    $core.int? bWeight,
    $core.int? bLength,
    TwistDir? twistDir,
    GType? bcType,
    $core.Iterable<SwPos>? switches,
    $core.Iterable<$core.int>? distances,
    $core.Iterable<CoefRow>? coefRows,
    $core.String? caliber,
    $core.String? deviceUuid,
  }) {
    final result = create();
    if (profileName != null) result.profileName = profileName;
    if (cartridgeName != null) result.cartridgeName = cartridgeName;
    if (bulletName != null) result.bulletName = bulletName;
    if (shortNameTop != null) result.shortNameTop = shortNameTop;
    if (shortNameBot != null) result.shortNameBot = shortNameBot;
    if (userNote != null) result.userNote = userNote;
    if (zeroX != null) result.zeroX = zeroX;
    if (zeroY != null) result.zeroY = zeroY;
    if (scHeight != null) result.scHeight = scHeight;
    if (rTwist != null) result.rTwist = rTwist;
    if (cMuzzleVelocity != null) result.cMuzzleVelocity = cMuzzleVelocity;
    if (cZeroTemperature != null) result.cZeroTemperature = cZeroTemperature;
    if (cTCoeff != null) result.cTCoeff = cTCoeff;
    if (cZeroDistanceIdx != null) result.cZeroDistanceIdx = cZeroDistanceIdx;
    if (cZeroAirTemperature != null)
      result.cZeroAirTemperature = cZeroAirTemperature;
    if (cZeroAirPressure != null) result.cZeroAirPressure = cZeroAirPressure;
    if (cZeroAirHumidity != null) result.cZeroAirHumidity = cZeroAirHumidity;
    if (cZeroWPitch != null) result.cZeroWPitch = cZeroWPitch;
    if (cZeroPTemperature != null) result.cZeroPTemperature = cZeroPTemperature;
    if (bDiameter != null) result.bDiameter = bDiameter;
    if (bWeight != null) result.bWeight = bWeight;
    if (bLength != null) result.bLength = bLength;
    if (twistDir != null) result.twistDir = twistDir;
    if (bcType != null) result.bcType = bcType;
    if (switches != null) result.switches.addAll(switches);
    if (distances != null) result.distances.addAll(distances);
    if (coefRows != null) result.coefRows.addAll(coefRows);
    if (caliber != null) result.caliber = caliber;
    if (deviceUuid != null) result.deviceUuid = deviceUuid;
    return result;
  }

  Profile._();

  factory Profile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Profile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Profile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'profedit'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileName')
    ..aOS(2, _omitFieldNames ? '' : 'cartridgeName')
    ..aOS(3, _omitFieldNames ? '' : 'bulletName')
    ..aOS(4, _omitFieldNames ? '' : 'shortNameTop')
    ..aOS(5, _omitFieldNames ? '' : 'shortNameBot')
    ..aOS(6, _omitFieldNames ? '' : 'userNote')
    ..aI(7, _omitFieldNames ? '' : 'zeroX')
    ..aI(8, _omitFieldNames ? '' : 'zeroY')
    ..aI(9, _omitFieldNames ? '' : 'scHeight')
    ..aI(10, _omitFieldNames ? '' : 'rTwist')
    ..aI(11, _omitFieldNames ? '' : 'cMuzzleVelocity')
    ..aI(12, _omitFieldNames ? '' : 'cZeroTemperature')
    ..aI(13, _omitFieldNames ? '' : 'cTCoeff')
    ..aI(14, _omitFieldNames ? '' : 'cZeroDistanceIdx')
    ..aI(15, _omitFieldNames ? '' : 'cZeroAirTemperature')
    ..aI(16, _omitFieldNames ? '' : 'cZeroAirPressure')
    ..aI(17, _omitFieldNames ? '' : 'cZeroAirHumidity')
    ..aI(18, _omitFieldNames ? '' : 'cZeroWPitch')
    ..aI(19, _omitFieldNames ? '' : 'cZeroPTemperature')
    ..aI(20, _omitFieldNames ? '' : 'bDiameter')
    ..aI(21, _omitFieldNames ? '' : 'bWeight')
    ..aI(22, _omitFieldNames ? '' : 'bLength')
    ..aE<TwistDir>(23, _omitFieldNames ? '' : 'twistDir',
        enumValues: TwistDir.values)
    ..aE<GType>(24, _omitFieldNames ? '' : 'bcType', enumValues: GType.values)
    ..pPM<SwPos>(25, _omitFieldNames ? '' : 'switches',
        subBuilder: SwPos.create)
    ..p<$core.int>(26, _omitFieldNames ? '' : 'distances', $pb.PbFieldType.K3)
    ..pPM<CoefRow>(27, _omitFieldNames ? '' : 'coefRows',
        subBuilder: CoefRow.create)
    ..aOS(28, _omitFieldNames ? '' : 'caliber')
    ..aOS(29, _omitFieldNames ? '' : 'deviceUuid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Profile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Profile copyWith(void Function(Profile) updates) =>
      super.copyWith((message) => updates(message as Profile)) as Profile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Profile create() => Profile._();
  @$core.override
  Profile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Profile getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Profile>(create);
  static Profile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileName => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileName() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get cartridgeName => $_getSZ(1);
  @$pb.TagNumber(2)
  set cartridgeName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCartridgeName() => $_has(1);
  @$pb.TagNumber(2)
  void clearCartridgeName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get bulletName => $_getSZ(2);
  @$pb.TagNumber(3)
  set bulletName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBulletName() => $_has(2);
  @$pb.TagNumber(3)
  void clearBulletName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get shortNameTop => $_getSZ(3);
  @$pb.TagNumber(4)
  set shortNameTop($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasShortNameTop() => $_has(3);
  @$pb.TagNumber(4)
  void clearShortNameTop() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get shortNameBot => $_getSZ(4);
  @$pb.TagNumber(5)
  set shortNameBot($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasShortNameBot() => $_has(4);
  @$pb.TagNumber(5)
  void clearShortNameBot() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get userNote => $_getSZ(5);
  @$pb.TagNumber(6)
  set userNote($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUserNote() => $_has(5);
  @$pb.TagNumber(6)
  void clearUserNote() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get zeroX => $_getIZ(6);
  @$pb.TagNumber(7)
  set zeroX($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasZeroX() => $_has(6);
  @$pb.TagNumber(7)
  void clearZeroX() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get zeroY => $_getIZ(7);
  @$pb.TagNumber(8)
  set zeroY($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasZeroY() => $_has(7);
  @$pb.TagNumber(8)
  void clearZeroY() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get scHeight => $_getIZ(8);
  @$pb.TagNumber(9)
  set scHeight($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasScHeight() => $_has(8);
  @$pb.TagNumber(9)
  void clearScHeight() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get rTwist => $_getIZ(9);
  @$pb.TagNumber(10)
  set rTwist($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRTwist() => $_has(9);
  @$pb.TagNumber(10)
  void clearRTwist() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get cMuzzleVelocity => $_getIZ(10);
  @$pb.TagNumber(11)
  set cMuzzleVelocity($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCMuzzleVelocity() => $_has(10);
  @$pb.TagNumber(11)
  void clearCMuzzleVelocity() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get cZeroTemperature => $_getIZ(11);
  @$pb.TagNumber(12)
  set cZeroTemperature($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCZeroTemperature() => $_has(11);
  @$pb.TagNumber(12)
  void clearCZeroTemperature() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get cTCoeff => $_getIZ(12);
  @$pb.TagNumber(13)
  set cTCoeff($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCTCoeff() => $_has(12);
  @$pb.TagNumber(13)
  void clearCTCoeff() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get cZeroDistanceIdx => $_getIZ(13);
  @$pb.TagNumber(14)
  set cZeroDistanceIdx($core.int value) => $_setSignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCZeroDistanceIdx() => $_has(13);
  @$pb.TagNumber(14)
  void clearCZeroDistanceIdx() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.int get cZeroAirTemperature => $_getIZ(14);
  @$pb.TagNumber(15)
  set cZeroAirTemperature($core.int value) => $_setSignedInt32(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCZeroAirTemperature() => $_has(14);
  @$pb.TagNumber(15)
  void clearCZeroAirTemperature() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.int get cZeroAirPressure => $_getIZ(15);
  @$pb.TagNumber(16)
  set cZeroAirPressure($core.int value) => $_setSignedInt32(15, value);
  @$pb.TagNumber(16)
  $core.bool hasCZeroAirPressure() => $_has(15);
  @$pb.TagNumber(16)
  void clearCZeroAirPressure() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.int get cZeroAirHumidity => $_getIZ(16);
  @$pb.TagNumber(17)
  set cZeroAirHumidity($core.int value) => $_setSignedInt32(16, value);
  @$pb.TagNumber(17)
  $core.bool hasCZeroAirHumidity() => $_has(16);
  @$pb.TagNumber(17)
  void clearCZeroAirHumidity() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.int get cZeroWPitch => $_getIZ(17);
  @$pb.TagNumber(18)
  set cZeroWPitch($core.int value) => $_setSignedInt32(17, value);
  @$pb.TagNumber(18)
  $core.bool hasCZeroWPitch() => $_has(17);
  @$pb.TagNumber(18)
  void clearCZeroWPitch() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.int get cZeroPTemperature => $_getIZ(18);
  @$pb.TagNumber(19)
  set cZeroPTemperature($core.int value) => $_setSignedInt32(18, value);
  @$pb.TagNumber(19)
  $core.bool hasCZeroPTemperature() => $_has(18);
  @$pb.TagNumber(19)
  void clearCZeroPTemperature() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.int get bDiameter => $_getIZ(19);
  @$pb.TagNumber(20)
  set bDiameter($core.int value) => $_setSignedInt32(19, value);
  @$pb.TagNumber(20)
  $core.bool hasBDiameter() => $_has(19);
  @$pb.TagNumber(20)
  void clearBDiameter() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.int get bWeight => $_getIZ(20);
  @$pb.TagNumber(21)
  set bWeight($core.int value) => $_setSignedInt32(20, value);
  @$pb.TagNumber(21)
  $core.bool hasBWeight() => $_has(20);
  @$pb.TagNumber(21)
  void clearBWeight() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.int get bLength => $_getIZ(21);
  @$pb.TagNumber(22)
  set bLength($core.int value) => $_setSignedInt32(21, value);
  @$pb.TagNumber(22)
  $core.bool hasBLength() => $_has(21);
  @$pb.TagNumber(22)
  void clearBLength() => $_clearField(22);

  @$pb.TagNumber(23)
  TwistDir get twistDir => $_getN(22);
  @$pb.TagNumber(23)
  set twistDir(TwistDir value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasTwistDir() => $_has(22);
  @$pb.TagNumber(23)
  void clearTwistDir() => $_clearField(23);

  @$pb.TagNumber(24)
  GType get bcType => $_getN(23);
  @$pb.TagNumber(24)
  set bcType(GType value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasBcType() => $_has(23);
  @$pb.TagNumber(24)
  void clearBcType() => $_clearField(24);

  @$pb.TagNumber(25)
  $pb.PbList<SwPos> get switches => $_getList(24);

  @$pb.TagNumber(26)
  $pb.PbList<$core.int> get distances => $_getList(25);

  @$pb.TagNumber(27)
  $pb.PbList<CoefRow> get coefRows => $_getList(26);

  @$pb.TagNumber(28)
  $core.String get caliber => $_getSZ(27);
  @$pb.TagNumber(28)
  set caliber($core.String value) => $_setString(27, value);
  @$pb.TagNumber(28)
  $core.bool hasCaliber() => $_has(27);
  @$pb.TagNumber(28)
  void clearCaliber() => $_clearField(28);

  @$pb.TagNumber(29)
  $core.String get deviceUuid => $_getSZ(28);
  @$pb.TagNumber(29)
  set deviceUuid($core.String value) => $_setString(28, value);
  @$pb.TagNumber(29)
  $core.bool hasDeviceUuid() => $_has(28);
  @$pb.TagNumber(29)
  void clearDeviceUuid() => $_clearField(29);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
