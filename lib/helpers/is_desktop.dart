import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}
