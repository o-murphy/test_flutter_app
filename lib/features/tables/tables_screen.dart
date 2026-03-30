import 'package:eballistica/features/tables/widgets/details_table.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eballistica/router.dart';
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
          children: [const TrajectoryTable(), const DetailsTable()],
        ),
      ),
    );
  }
}
