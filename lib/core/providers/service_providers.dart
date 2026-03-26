import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/domain/ballistics_service.dart';
import 'package:eballistica/core/services/ballistics_service_impl.dart';

final ballisticsServiceProvider = Provider<BallisticsService>((ref) {
  return BallisticsServiceImpl();
});
