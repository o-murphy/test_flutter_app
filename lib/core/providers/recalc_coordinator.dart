import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/providers/home_calculation_provider.dart';
import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/features/home/home_vm.dart';
import 'package:eballistica/features/tables/tables_vm.dart';

/// Centralises all recalculation triggers.
///
/// Listens to [shotProfileProvider] and [settingsProvider] and triggers
/// the new ViewModels and the old [homeCalculationProvider] (still used by
/// shot_details_screen.dart).
class RecalcCoordinator extends Notifier<void> {
  @override
  void build() {
    ref.listen(shotProfileProvider, (_, next) {
      if (next.hasValue) _triggerAll();
    });

    ref.listen<AsyncValue<AppSettings>>(settingsProvider, (prev, next) {
      if (!next.hasValue) return;
      if (_needsRecalc(prev?.value, next.value!)) _triggerAll();
    });
  }

  /// Called from router/shell when a tab is activated.
  void onTabActivated(int tabIndex) {
    if (tabIndex == 0) {
      ref.read(homeVmProvider.notifier).recalculate();
      ref.read(homeCalculationProvider.notifier).recalculateIfNeeded();
    }
    if (tabIndex == 2) {
      ref.read(tablesVmProvider.notifier).recalculate();
    }
  }

  void _triggerAll() {
    ref.read(homeVmProvider.notifier).recalculate();
    ref.read(tablesVmProvider.notifier).recalculate();
    // homeCalculationProvider still used by shot_details_screen
    ref.read(homeCalculationProvider.notifier).markDirty();
    ref.read(homeCalculationProvider.notifier).recalculateIfNeeded();
  }

  bool _needsRecalc(AppSettings? prev, AppSettings next) {
    if (prev == null) return true;
    return prev.enablePowderSensitivity != next.enablePowderSensitivity ||
        prev.useDifferentPowderTemperature !=
            next.useDifferentPowderTemperature ||
        prev.chartDistanceStep != next.chartDistanceStep ||
        prev.homeTableStep != next.homeTableStep ||
        prev.units != next.units ||
        prev.showMrad != next.showMrad ||
        prev.showMoa != next.showMoa ||
        prev.showMil != next.showMil ||
        prev.showCmPer100m != next.showCmPer100m ||
        prev.showInPer100yd != next.showInPer100yd ||
        // Any tableConfig change — identity check works because
        // AppSettings.copyWith reuses the same reference when tableConfig
        // is not passed.
        !identical(prev.tableConfig, next.tableConfig);
  }
}

final recalcCoordinatorProvider =
    NotifierProvider<RecalcCoordinator, void>(RecalcCoordinator.new);
