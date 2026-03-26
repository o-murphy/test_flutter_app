import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/formatting/unit_formatter_impl.dart';
import 'package:eballistica/core/providers/settings_provider.dart';

final unitFormatterProvider = Provider<UnitFormatter>((ref) {
  final units = ref.watch(unitSettingsProvider);
  return UnitFormatterImpl(units);
});
