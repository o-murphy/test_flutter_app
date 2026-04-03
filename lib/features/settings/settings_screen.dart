import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/unit_constrained_input_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/router.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();

    final notifier = ref.read(settingsProvider.notifier);
    final tt = Theme.of(context).textTheme;

    final distanceUnit = ref.watch(unitSettingsProvider).distance;

    return BaseScreen(
      title: 'Settings',
      body: ListView(
        children: [
          // ── Language ───────────────────────────────────────────────────
          ListSectionTile('Language'),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(_languageName(settings.languageCode)),
            trailing: const Icon(Icons.chevron_right),
            dense: true,
            onTap: () => _showLanguageDialog(
              context,
              settings.languageCode,
              notifier.setLanguage,
            ),
          ),
          // const Divider(height: 1),

          // ── Appearance ─────────────────────────────────────────────────
          ListSectionTile('Appearance'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _ThemeSelector(
              current: settings.themeMode,
              onChanged: notifier.setThemeMode,
            ),
          ),

          const Divider(height: 1),

          // ── Display settings ─────────────────────────────────────────────────
          ListSectionTile('Display settings'),
          ListTile(
            leading: const Icon(Icons.straighten_outlined),
            title: const Text('Units of Measurement'),
            trailing: const Icon(Icons.chevron_right),
            dense: true,
            onTap: () => context.push(Routes.settingsUnits),
          ),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('Adjustment Display'),
            trailing: const Icon(Icons.chevron_right),
            dense: true,
            onTap: () => context.push(Routes.settingsAdjustment),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.speed_outlined),
            title: const Text('Show subsonic transition'),
            value: settings.showSubsonicTransition,
            onChanged: (v) => notifier.setSwitch('subsonicTransition', v),
            dense: true,
          ),
          const Divider(height: 1),

          // ── Home screen props ─────────────────────────────────────────────────
          ListSectionTile('Main screen'),

          UnitValueFieldTile(
            icon: Icons.table_rows_outlined,
            label: 'Table distance step',
            rawValue: settings.homeTableStep,
            constraints: FC.distanceStep,
            displayUnit: distanceUnit,
            onChanged: (v) => notifier.setHomeTableStep(v),
          ),
          UnitValueFieldTile(
            icon: Icons.show_chart_outlined,
            label: 'Chart distance step',
            rawValue: settings.chartDistanceStep,
            constraints: FC.distanceStep,
            displayUnit: distanceUnit,
            onChanged: (v) => notifier.setChartDistanceStep(v),
          ),

          const Divider(height: 1),

          // ── Profiles ───────────────────────────────────────────────────
          ListSectionTile('Profiles'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.upload_outlined),
                    label: const Text('Export profiles'),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Import profiles'),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Links ──────────────────────────────────────────────────────
          ListSectionTile('Links'),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('GitHub'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            dense: true,
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            dense: true,
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Terms of Use'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            dense: true,
            onTap: () {},
          ),

          const Divider(height: 1),

          // ── About ──────────────────────────────────────────────────────
          ListSectionTile('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: Text('1.0.0', style: tt.bodySmall),
            dense: true,
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('Changelog'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            dense: true,
            onTap: () {},
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Language helpers ─────────────────────────────────────────────────────────

String _languageName(String code) => switch (code) {
  'uk' => 'Українська',
  _ => 'English',
};

void _showLanguageDialog(
  BuildContext context,
  String current,
  Future<void> Function(String) onSelect,
) {
  const langs = [('en', 'English'), ('uk', 'Українська')];
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Language'),
      content: RadioGroup<String>(
        groupValue: current,
        onChanged: (v) {
          if (v != null) {
            onSelect(v);
            Navigator.pop(ctx);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs
              .map((l) => RadioListTile<String>(value: l.$1, title: Text(l.$2)))
              .toList(),
        ),
      ),
    ),
  );
}

// ─── Theme selector ───────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current, required this.onChanged});
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_outlined),
          label: Text('System'),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_outlined),
          label: Text('Light'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_outlined),
          label: Text('Dark'),
        ),
      ],
      selected: {current},
      onSelectionChanged: (s) => onChanged(s.first),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
