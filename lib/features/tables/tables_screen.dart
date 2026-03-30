import 'package:eballistica/features/tables/widgets/details_table.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eballistica/router.dart';
import 'package:eballistica/features/tables/trajectory_tables_vm.dart';
import 'package:eballistica/features/tables/widgets/trajectory_table.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  List<Widget> _buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.tune_outlined),
        onPressed: () => context.push(Routes.tableConfig),
        tooltip: 'Configure',
      ),
      IconButton(
        icon: const Icon(Icons.share_outlined),
        onPressed: () {}, // Логіка експорту
        tooltip: 'Export',
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmTrajectoryAsync = ref.watch(trajectoryTablesVmProvider);
    final vmTrajectoryState = vmTrajectoryAsync.value;

    Widget tablesTab;
    if (vmTrajectoryState is TrajectoryTablesUiLoading ||
        vmTrajectoryState == null) {
      tablesTab = const Center(child: CircularProgressIndicator());
    } else if (vmTrajectoryState is TrajectoryTablesUiEmpty) {
      tablesTab = const EmptyStatePlaceholder();
    } else if (vmTrajectoryState is TrajectoryTablesUiReady) {
      tablesTab = TrajectoryTable(
        mainTable: vmTrajectoryState.mainTable,
        zeroCrossings: vmTrajectoryState.zeroCrossings,
      );
    } else {
      tablesTab = const EmptyStatePlaceholder();
    }

    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: BaseScreen(
        title: 'Tables',
        actions: _buildActions(context),
        withTabs: [
          Tab(text: "Table"),
          Tab(text: "Details"),
        ],
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [tablesTab, const DetailsTable()],
        ),
      ),
    );
  }
}
