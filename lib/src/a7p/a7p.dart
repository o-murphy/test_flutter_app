// A7P file codec — decodes and encodes `.a7p` ballistic profile files.
//
// File format:
//   • Bytes 0–31 : MD5 checksum of the protobuf payload (ASCII hex, 32 bytes)
//   • Bytes 32+  : protobuf-encoded Payload message
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import 'errors.dart';
import 'models.dart';
import 'proto.dart';
import 'validator.dart';

export 'errors.dart';
export 'models.dart';
export 'validator.dart' show validate;

// ─── MD5 ─────────────────────────────────────────────────────────────────────

String _md5hex(Uint8List bytes) => crypto.md5.convert(bytes).toString();

// ─── Public API ──────────────────────────────────────────────────────────────

/// Decodes an `.a7p` byte buffer into a validated [Payload].
///
/// Throws [DecodeException] on checksum mismatch or parse errors.
/// Throws [ValidationException] if the profile data is out of range.
Payload decode(Uint8List bytes) {
  if (bytes.length < 32) {
    throw const DecodeException('Buffer too short to contain MD5 checksum');
  }

  final checksumBytes  = bytes.sublist(0, 32);
  final protoBytes     = bytes.sublist(32);

  final storedChecksum   = String.fromCharCodes(checksumBytes);
  final computedChecksum = _md5hex(protoBytes);

  if (storedChecksum != computedChecksum) {
    throw DecodeException(
      'Checksum mismatch: stored=$storedChecksum computed=$computedChecksum',
    );
  }

  final payload = parsePayload(protoBytes);
  validate(payload);
  return payload;
}

/// Encodes a [Payload] into an `.a7p` byte buffer.
///
/// Throws [ValidationException] if the payload is invalid.
/// Throws [EncodeException] on serialization errors.
Uint8List encode(Payload payload) {
  validate(payload);

  final Uint8List protoBytes;
  try {
    protoBytes = serializePayload(payload);
  } catch (e) {
    throw EncodeException('Serialization failed: $e');
  }

  final checksum      = _md5hex(protoBytes);
  final checksumBytes = Uint8List.fromList(checksum.codeUnits); // 32 ASCII bytes

  final result = Uint8List(checksumBytes.length + protoBytes.length);
  result.setAll(0, checksumBytes);
  result.setAll(checksumBytes.length, protoBytes);
  return result;
}
