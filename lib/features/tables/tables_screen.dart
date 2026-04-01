import 'package:eballistica/features/tables/details_table_mv.dart';
import 'package:eballistica/features/tables/table_html_exporter.dart';
import 'package:eballistica/features/tables/trajectory_tables_vm.dart';
import 'package:eballistica/features/tables/widgets/details_table.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eballistica/router.dart';
import 'package:eballistica/features/tables/widgets/trajectory_table.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          return AnimatedBuilder(
            animation: tabController,
            builder: (context, _) => BaseScreen(
              title: 'Tables',
              actions: [
                if (tabController.index == 0)
                  IconButton(
                    icon: const Icon(Icons.tune_outlined),
                    onPressed: () => context.push(Routes.tableConfig),
                    tooltip: 'Configure',
                  ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _onShare(ref),
                  tooltip: 'Share',
                ),
              ],
              withTabs: const [
                Tab(text: "Trajectory"),
                Tab(text: "Details"),
              ],
              body: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: const [TrajectoryTable(), DetailsTable()],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onShare(WidgetRef ref) async {
    final vmState = ref.read(trajectoryTablesVmProvider).value;
    if (vmState is! TrajectoryTablesUiReady) return;
    final details = ref.read(detailsTableMvProvider);
    await TableHtmlExporter.share(details: details, tables: vmState);
  }
}
