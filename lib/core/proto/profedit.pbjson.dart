// This is a generated file - do not edit.
//
// Generated from profedit.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use dTypeDescriptor instead')
const DType$json = {
  '1': 'DType',
  '2': [
    {'1': 'VALUE', '2': 0},
    {'1': 'INDEX', '2': 1},
  ],
};

/// Descriptor for `DType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List dTypeDescriptor =
    $convert.base64Decode('CgVEVHlwZRIJCgVWQUxVRRAAEgkKBUlOREVYEAE=');

@$core.Deprecated('Use gTypeDescriptor instead')
const GType$json = {
  '1': 'GType',
  '2': [
    {'1': 'G1', '2': 0},
    {'1': 'G7', '2': 1},
    {'1': 'CUSTOM', '2': 2},
  ],
};

/// Descriptor for `GType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List gTypeDescriptor =
    $convert.base64Decode('CgVHVHlwZRIGCgJHMRAAEgYKAkc3EAESCgoGQ1VTVE9NEAI=');

@$core.Deprecated('Use twistDirDescriptor instead')
const TwistDir$json = {
  '1': 'TwistDir',
  '2': [
    {'1': 'RIGHT', '2': 0},
    {'1': 'LEFT', '2': 1},
  ],
};

/// Descriptor for `TwistDir`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List twistDirDescriptor =
    $convert.base64Decode('CghUd2lzdERpchIJCgVSSUdIVBAAEggKBExFRlQQAQ==');

@$core.Deprecated('Use payloadDescriptor instead')
const Payload$json = {
  '1': 'Payload',
  '2': [
    {
      '1': 'profile',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.profedit.Profile',
      '10': 'profile'
    },
  ],
};

/// Descriptor for `Payload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List payloadDescriptor = $convert.base64Decode(
    'CgdQYXlsb2FkEisKB3Byb2ZpbGUYASABKAsyES5wcm9mZWRpdC5Qcm9maWxlUgdwcm9maWxl');

@$core.Deprecated('Use coefRowDescriptor instead')
const CoefRow$json = {
  '1': 'CoefRow',
  '2': [
    {'1': 'bc_cd', '3': 1, '4': 1, '5': 5, '10': 'bcCd'},
    {'1': 'mv', '3': 2, '4': 1, '5': 5, '10': 'mv'},
  ],
};

/// Descriptor for `CoefRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List coefRowDescriptor = $convert.base64Decode(
    'CgdDb2VmUm93EhMKBWJjX2NkGAEgASgFUgRiY0NkEg4KAm12GAIgASgFUgJtdg==');

@$core.Deprecated('Use swPosDescriptor instead')
const SwPos$json = {
  '1': 'SwPos',
  '2': [
    {'1': 'c_idx', '3': 1, '4': 1, '5': 5, '10': 'cIdx'},
    {'1': 'reticle_idx', '3': 2, '4': 1, '5': 5, '10': 'reticleIdx'},
    {'1': 'zoom', '3': 3, '4': 1, '5': 5, '10': 'zoom'},
    {'1': 'distance', '3': 4, '4': 1, '5': 5, '10': 'distance'},
    {
      '1': 'distance_from',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.profedit.DType',
      '10': 'distanceFrom'
    },
  ],
};

/// Descriptor for `SwPos`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List swPosDescriptor = $convert.base64Decode(
    'CgVTd1BvcxITCgVjX2lkeBgBIAEoBVIEY0lkeBIfCgtyZXRpY2xlX2lkeBgCIAEoBVIKcmV0aW'
    'NsZUlkeBISCgR6b29tGAMgASgFUgR6b29tEhoKCGRpc3RhbmNlGAQgASgFUghkaXN0YW5jZRI0'
    'Cg1kaXN0YW5jZV9mcm9tGAUgASgOMg8ucHJvZmVkaXQuRFR5cGVSDGRpc3RhbmNlRnJvbQ==');

@$core.Deprecated('Use profileDescriptor instead')
const Profile$json = {
  '1': 'Profile',
  '2': [
    {'1': 'profile_name', '3': 1, '4': 1, '5': 9, '10': 'profileName'},
    {'1': 'cartridge_name', '3': 2, '4': 1, '5': 9, '10': 'cartridgeName'},
    {'1': 'bullet_name', '3': 3, '4': 1, '5': 9, '10': 'bulletName'},
    {'1': 'short_name_top', '3': 4, '4': 1, '5': 9, '10': 'shortNameTop'},
    {'1': 'short_name_bot', '3': 5, '4': 1, '5': 9, '10': 'shortNameBot'},
    {'1': 'user_note', '3': 6, '4': 1, '5': 9, '10': 'userNote'},
    {'1': 'zero_x', '3': 7, '4': 1, '5': 5, '10': 'zeroX'},
    {'1': 'zero_y', '3': 8, '4': 1, '5': 5, '10': 'zeroY'},
    {'1': 'sc_height', '3': 9, '4': 1, '5': 5, '10': 'scHeight'},
    {'1': 'r_twist', '3': 10, '4': 1, '5': 5, '10': 'rTwist'},
    {
      '1': 'c_muzzle_velocity',
      '3': 11,
      '4': 1,
      '5': 5,
      '10': 'cMuzzleVelocity'
    },
    {
      '1': 'c_zero_temperature',
      '3': 12,
      '4': 1,
      '5': 5,
      '10': 'cZeroTemperature'
    },
    {'1': 'c_t_coeff', '3': 13, '4': 1, '5': 5, '10': 'cTCoeff'},
    {
      '1': 'c_zero_distance_idx',
      '3': 14,
      '4': 1,
      '5': 5,
      '10': 'cZeroDistanceIdx'
    },
    {
      '1': 'c_zero_air_temperature',
      '3': 15,
      '4': 1,
      '5': 5,
      '10': 'cZeroAirTemperature'
    },
    {
      '1': 'c_zero_air_pressure',
      '3': 16,
      '4': 1,
      '5': 5,
      '10': 'cZeroAirPressure'
    },
    {
      '1': 'c_zero_air_humidity',
      '3': 17,
      '4': 1,
      '5': 5,
      '10': 'cZeroAirHumidity'
    },
    {'1': 'c_zero_w_pitch', '3': 18, '4': 1, '5': 5, '10': 'cZeroWPitch'},
    {
      '1': 'c_zero_p_temperature',
      '3': 19,
      '4': 1,
      '5': 5,
      '10': 'cZeroPTemperature'
    },
    {'1': 'b_diameter', '3': 20, '4': 1, '5': 5, '10': 'bDiameter'},
    {'1': 'b_weight', '3': 21, '4': 1, '5': 5, '10': 'bWeight'},
    {'1': 'b_length', '3': 22, '4': 1, '5': 5, '10': 'bLength'},
    {
      '1': 'twist_dir',
      '3': 23,
      '4': 1,
      '5': 14,
      '6': '.profedit.TwistDir',
      '10': 'twistDir'
    },
    {
      '1': 'bc_type',
      '3': 24,
      '4': 1,
      '5': 14,
      '6': '.profedit.GType',
      '10': 'bcType'
    },
    {
      '1': 'switches',
      '3': 25,
      '4': 3,
      '5': 11,
      '6': '.profedit.SwPos',
      '10': 'switches'
    },
    {'1': 'distances', '3': 26, '4': 3, '5': 5, '10': 'distances'},
    {
      '1': 'coef_rows',
      '3': 27,
      '4': 3,
      '5': 11,
      '6': '.profedit.CoefRow',
      '10': 'coefRows'
    },
    {'1': 'caliber', '3': 28, '4': 1, '5': 9, '10': 'caliber'},
    {'1': 'device_uuid', '3': 29, '4': 1, '5': 9, '10': 'deviceUuid'},
  ],
};

/// Descriptor for `Profile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDescriptor = $convert.base64Decode(
    'CgdQcm9maWxlEiEKDHByb2ZpbGVfbmFtZRgBIAEoCVILcHJvZmlsZU5hbWUSJQoOY2FydHJpZG'
    'dlX25hbWUYAiABKAlSDWNhcnRyaWRnZU5hbWUSHwoLYnVsbGV0X25hbWUYAyABKAlSCmJ1bGxl'
    'dE5hbWUSJAoOc2hvcnRfbmFtZV90b3AYBCABKAlSDHNob3J0TmFtZVRvcBIkCg5zaG9ydF9uYW'
    '1lX2JvdBgFIAEoCVIMc2hvcnROYW1lQm90EhsKCXVzZXJfbm90ZRgGIAEoCVIIdXNlck5vdGUS'
    'FQoGemVyb194GAcgASgFUgV6ZXJvWBIVCgZ6ZXJvX3kYCCABKAVSBXplcm9ZEhsKCXNjX2hlaW'
    'dodBgJIAEoBVIIc2NIZWlnaHQSFwoHcl90d2lzdBgKIAEoBVIGclR3aXN0EioKEWNfbXV6emxl'
    'X3ZlbG9jaXR5GAsgASgFUg9jTXV6emxlVmVsb2NpdHkSLAoSY196ZXJvX3RlbXBlcmF0dXJlGA'
    'wgASgFUhBjWmVyb1RlbXBlcmF0dXJlEhoKCWNfdF9jb2VmZhgNIAEoBVIHY1RDb2VmZhItChNj'
    'X3plcm9fZGlzdGFuY2VfaWR4GA4gASgFUhBjWmVyb0Rpc3RhbmNlSWR4EjMKFmNfemVyb19haX'
    'JfdGVtcGVyYXR1cmUYDyABKAVSE2NaZXJvQWlyVGVtcGVyYXR1cmUSLQoTY196ZXJvX2Fpcl9w'
    'cmVzc3VyZRgQIAEoBVIQY1plcm9BaXJQcmVzc3VyZRItChNjX3plcm9fYWlyX2h1bWlkaXR5GB'
    'EgASgFUhBjWmVyb0Fpckh1bWlkaXR5EiMKDmNfemVyb193X3BpdGNoGBIgASgFUgtjWmVyb1dQ'
    'aXRjaBIvChRjX3plcm9fcF90ZW1wZXJhdHVyZRgTIAEoBVIRY1plcm9QVGVtcGVyYXR1cmUSHQ'
    'oKYl9kaWFtZXRlchgUIAEoBVIJYkRpYW1ldGVyEhkKCGJfd2VpZ2h0GBUgASgFUgdiV2VpZ2h0'
    'EhkKCGJfbGVuZ3RoGBYgASgFUgdiTGVuZ3RoEi8KCXR3aXN0X2RpchgXIAEoDjISLnByb2ZlZG'
    'l0LlR3aXN0RGlyUgh0d2lzdERpchIoCgdiY190eXBlGBggASgOMg8ucHJvZmVkaXQuR1R5cGVS'
    'BmJjVHlwZRIrCghzd2l0Y2hlcxgZIAMoCzIPLnByb2ZlZGl0LlN3UG9zUghzd2l0Y2hlcxIcCg'
    'lkaXN0YW5jZXMYGiADKAVSCWRpc3RhbmNlcxIuCgljb2VmX3Jvd3MYGyADKAsyES5wcm9mZWRp'
    'dC5Db2VmUm93Ughjb2VmUm93cxIYCgdjYWxpYmVyGBwgASgJUgdjYWxpYmVyEh8KC2RldmljZV'
    '91dWlkGB0gASgJUgpkZXZpY2VVdWlk');
