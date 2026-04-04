import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/providers/shot_conditions_provider.dart'; // ← додати
import 'package:eballistica/core/providers/shot_profile_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/features/home/home_vm.dart';
import 'package:eballistica/features/home/shot_details_vm.dart';
import 'package:eballistica/features/tables/trajectory_tables_vm.dart';

/// Centralises all recalculation triggers.
///
/// Listens to [shotProfileProvider], [shotConditionsProvider] and [settingsProvider]
/// and triggers the ViewModels for the active features.
class RecalcCoordinator extends Notifier<void> {
  @override
  void build() {
    // Слухаємо зміни профілю
    ref.listen(shotProfileProvider, (_, next) {
      if (next.hasValue) _triggerAll();
    });

    // Слухаємо зміни умов (це те, чого не вистачало!)
    ref.listen(shotConditionsProvider, (_, next) {
      if (next.hasValue) _triggerAll();
    });

    // Слухаємо зміни налаштувань
    ref.listen<AsyncValue<AppSettings>>(settingsProvider, (prev, next) {
      if (!next.hasValue) return;
      if (_needsRecalc(prev?.value, next.value!)) _triggerAll();
    });
  }

  /// Called from router/shell when a tab is activated.
  void onTabActivated(int tabIndex) {
    if (tabIndex == 0) {
      ref.read(homeVmProvider.notifier).recalculate();
      ref.read(shotDetailsVmProvider.notifier).recalculate();
    }
    if (tabIndex == 2) {
      ref.read(trajectoryTablesVmProvider.notifier).recalculate();
    }
  }

  void _triggerAll() {
    ref.read(homeVmProvider.notifier).recalculate();
    ref.read(trajectoryTablesVmProvider.notifier).recalculate();
    ref.read(shotDetailsVmProvider.notifier).recalculate();
  }

  bool _needsRecalc(AppSettings? prev, AppSettings next) {
    if (prev == null) return true;
    return prev.chartDistanceStep != next.chartDistanceStep ||
        prev.homeTableStep != next.homeTableStep ||
        prev.units != next.units ||
        prev.showMrad != next.showMrad ||
        prev.showMoa != next.showMoa ||
        prev.showMil != next.showMil ||
        prev.showCmPer100m != next.showCmPer100m ||
        prev.showInPer100yd != next.showInPer100yd ||
        !identical(prev.tableConfig, next.tableConfig);
  }
}

final recalcCoordinatorProvider = NotifierProvider<RecalcCoordinator, void>(
  RecalcCoordinator.new,
);
