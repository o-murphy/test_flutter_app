import 'package:eballistica/features/tables/widgets/details_table.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eballistica/router.dart';
import 'package:eballistica/features/tables/tables_vm.dart';
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
    final vmAsync = ref.watch(tablesVmProvider);
    final vmState = vmAsync.value;

    Widget tablesTab;
    Widget detailsTab;
    if (vmState is TablesUiLoading || vmState == null) {
      tablesTab = detailsTab = const Center(child: CircularProgressIndicator());
    } else if (vmState is TablesUiEmpty) {
      tablesTab = detailsTab = const EmptyStatePlaceholder();
    } else if (vmState is TablesUiReady) {
      tablesTab = TrajectoryTable(
        mainTable: vmState.mainTable,
        zeroCrossings: vmState.zeroCrossings,
      );
      detailsTab = DetailsTable(details: vmState.details);
    } else {
      tablesTab = detailsTab = const EmptyStatePlaceholder();
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
          children: [tablesTab, detailsTab],
        ),
      ),
    );
  }
}
