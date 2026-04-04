import 'package:eballistica/core/models/conditions_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShotConditionsNotifier extends AsyncNotifier<Conditions> {
  @override
  Future<Conditions> build() async {
    // final storage = ref.read(appStorageProvider);

    return Conditions();
  }
}
