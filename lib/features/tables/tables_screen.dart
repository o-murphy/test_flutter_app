import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eballistica/router.dart';
import 'package:eballistica/features/tables/tables_vm.dart';
import 'package:eballistica/features/tables/widgets/trajectory_table.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

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
            Icon(Icons.table_view_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            const Text('No data'),
          ],
        ),
      );
    } else if (vmState is TablesUiReady) {
      body = TrajectoryTable(
        mainTable:      vmState.mainTable,
        zeroCrossings:  vmState.zeroCrossings,
        spoiler:        vmState.spoiler,
      );
    } else {
      body = const Center(child: Text('No data'));
    }

    return Column(
      children: [
        const _Header(),
        Expanded(child: body),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(Routes.home),
              ),
            ),
            Text('Tables', style: Theme.of(context).textTheme.titleLarge),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_outlined),
                    onPressed: () => context.push(Routes.tableConfig),
                    tooltip: 'Configure',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {},
                    tooltip: 'Export',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
