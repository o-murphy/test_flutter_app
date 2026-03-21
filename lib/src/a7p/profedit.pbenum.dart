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

class DType extends $pb.ProtobufEnum {
  static const DType VALUE = DType._(0, _omitEnumNames ? '' : 'VALUE');
  static const DType INDEX = DType._(1, _omitEnumNames ? '' : 'INDEX');

  static const $core.List<DType> values = <DType>[
    VALUE,
    INDEX,
  ];

  static final $core.List<DType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static DType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DType._(super.value, super.name);
}

class GType extends $pb.ProtobufEnum {
  static const GType G1 = GType._(0, _omitEnumNames ? '' : 'G1');
  static const GType G7 = GType._(1, _omitEnumNames ? '' : 'G7');
  static const GType CUSTOM = GType._(2, _omitEnumNames ? '' : 'CUSTOM');

  static const $core.List<GType> values = <GType>[
    G1,
    G7,
    CUSTOM,
  ];

  static final $core.List<GType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static GType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GType._(super.value, super.name);
}

class TwistDir extends $pb.ProtobufEnum {
  static const TwistDir RIGHT = TwistDir._(0, _omitEnumNames ? '' : 'RIGHT');
  static const TwistDir LEFT = TwistDir._(1, _omitEnumNames ? '' : 'LEFT');

  static const $core.List<TwistDir> values = <TwistDir>[
    RIGHT,
    LEFT,
  ];

  static final $core.List<TwistDir?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static TwistDir? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TwistDir._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
