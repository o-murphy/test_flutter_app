import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/storage/app_storage.dart';
import 'package:eballistica/core/storage/json_file_storage.dart';

final appStorageProvider = Provider<AppStorage>(
  (_) => JsonFileStorage.instance,
);
