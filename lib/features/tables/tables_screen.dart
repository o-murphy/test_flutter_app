import 'package:eballistica/shared/widgets/screen_headers.dart';
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

    Widget body;
    if (vmState is TablesUiLoading || vmState == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (vmState is TablesUiEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.table_view_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 12),
            const Text('No data'),
          ],
        ),
      );
    } else if (vmState is TablesUiReady) {
      body = TrajectoryTable(
        mainTable: vmState.mainTable,
        zeroCrossings: vmState.zeroCrossings,
        spoiler: vmState.spoiler,
      );
    } else {
      body = const Center(child: Text('No data'));
    }

    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: TableScreenAppBar(
          title: 'Tables',
          actions: _buildActions(context),
        ),
        body: TabBarView(
          children: [
            body,
            const Center(child: Text("Details Tab")),
          ],
        ),
      ),
    );
  }
}

class TableScreenAppBar extends ScreenAppBar {
  const TableScreenAppBar({required super.title, super.actions, super.key});

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final appBar = super.build(context) as AppBar;

    return AppBar(
      leading: appBar.leading,
      title: appBar.title,
      centerTitle: appBar.centerTitle,
      actions: appBar.actions,
      bottom: const TabBar(
        tabs: [
          Tab(text: "Table"),
          Tab(text: "Details"),
        ],
      ),
    );
  }
}
