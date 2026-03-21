/// Base class for all a7p errors.
sealed class A7pException implements Exception {
  final String message;
  const A7pException(this.message);
  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when binary decoding fails (bad checksum, truncated data, etc.)
final class DecodeException extends A7pException {
  const DecodeException(super.message);
}

/// Thrown when encoding fails.
final class EncodeException extends A7pException {
  const EncodeException(super.message);
}

/// Thrown when the payload does not pass validation.
final class ValidationException extends A7pException {
  final List<String> errors;

  ValidationException(this.errors)
      : super('Validation failed: ${errors.join('; ')}');
}
