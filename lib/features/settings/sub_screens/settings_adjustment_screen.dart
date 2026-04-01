import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';

// ─── Adjustment Display Screen ────────────────────────────────────────────────

class AdjustmentDisplayScreen extends ConsumerWidget {
  const AdjustmentDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);

    return BaseScreen(
      title: 'Adjustment Display',
      isSubscreen: true,
      body: ListView(
        children: [
          const ListSectionTile('Format'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<AdjustmentFormat>(
              segments: const [
                ButtonSegment(
                  value: AdjustmentFormat.arrows,
                  label: Text('↑/↓'),
                ),
                ButtonSegment(
                  value: AdjustmentFormat.signs,
                  label: Text('+/−'),
                ),
                ButtonSegment(
                  value: AdjustmentFormat.letters,
                  label: Text('U/D'),
                ),
              ],
              selected: {settings.adjustmentFormat},
              onSelectionChanged: (s) => notifier.setAdjustmentFormat(s.first),
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const Divider(height: 1),
          const ListSectionTile('Show units'),
          SwitchListTile(
            title: const Text('MRAD', style: TextStyle(fontSize: 14)),
            value: settings.showMrad,
            onChanged: (v) => notifier.setAdjustmentToggle('showMrad', v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('MOA', style: TextStyle(fontSize: 14)),
            value: settings.showMoa,
            onChanged: (v) => notifier.setAdjustmentToggle('showMoa', v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('MIL', style: TextStyle(fontSize: 14)),
            value: settings.showMil,
            onChanged: (v) => notifier.setAdjustmentToggle('showMil', v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('cm / 100m', style: TextStyle(fontSize: 14)),
            value: settings.showCmPer100m,
            onChanged: (v) => notifier.setAdjustmentToggle('showCmPer100m', v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('in / 100yd', style: TextStyle(fontSize: 14)),
            value: settings.showInPer100yd,
            onChanged: (v) => notifier.setAdjustmentToggle('showInPer100yd', v),
            dense: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
