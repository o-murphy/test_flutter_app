import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../helpers/dimension_converter.dart';
import '../providers/settings_provider.dart';
import '../router.dart';
import '../src/models/app_settings.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/unit.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();

    final notifier = ref.read(settingsProvider.notifier);
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        _Header(),
        Expanded(
          child: ListView(
            children: [
              // ── Language ───────────────────────────────────────────────────
              SectionHeader('Language'),
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
              SectionHeader('Appearance'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _ThemeSelector(
                  current: settings.themeMode,
                  onChanged: notifier.setThemeMode,
                ),
              ),

              const Divider(height: 1),

              // ── Display settings ─────────────────────────────────────────────────
              SectionHeader('Display settings'),
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
                title: const Text(
                  'Show subsonic transition',
                  style: TextStyle(fontSize: 14),
                ),
                value: settings.showSubsonicTransition,
                onChanged: (v) => notifier.setSwitch('subsonicTransition', v),
                dense: true,
              ),
              const Divider(height: 1),

              // ── Home screen props ─────────────────────────────────────────────────
              SectionHeader('Main screen'),

              _StepTile(
                icon: Icons.table_rows_outlined,
                label: 'Table distance step',
                valueM: settings.tableConfig.stepM,
                onConfirm: (v) => notifier.updateTableConfig(
                    settings.tableConfig.copyWith(stepM: v)),
              ),
              _StepTile(
                icon: Icons.show_chart_outlined,
                label: 'Chart distance step',
                valueM: settings.chartDistanceStep,
                onConfirm: notifier.setChartDistanceStep,
              ),
              const Divider(height: 1),

              // ── Profiles ───────────────────────────────────────────────────
              SectionHeader('Profiles'),
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
              SectionHeader('Links'),
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
              SectionHeader('About'),
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
        ),
      ],
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

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
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

// ─── Distance step tile ───────────────────────────────────────────────────────

class _StepTile extends ConsumerWidget {
  const _StepTile({
    required this.icon,
    required this.label,
    required this.valueM,   // stored in metres
    required this.onConfirm, // receives metres
  });

  final IconData    icon;
  final String      label;
  final double      valueM;
  final ValueChanged<double> onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distUnit = ref.watch(unitSettingsProvider).distance;
    final acc      = FC.targetDistance.accuracyFor(distUnit);
    final dispVal  = Unit.meter(valueM).in_(distUnit);
    final display  = '${dispVal.toStringAsFixed(acc)} ${distUnit.symbol}';

    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(display, style: Theme.of(context).textTheme.bodyMedium),
      dense: true,
      onTap: () => _showDialog(context, distUnit, acc),
    );
  }

  void _showDialog(BuildContext context, Unit distUnit, int acc) {
    final dispVal    = Unit.meter(valueM).in_(distUnit);
    final controller = TextEditingController(text: dispVal.toStringAsFixed(acc));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(suffixText: distUnit.symbol),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) {
                // convert display unit → metres
                final metres = valueInUnit(v, distUnit, Unit.meter);
                onConfirm(metres);
              }
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
