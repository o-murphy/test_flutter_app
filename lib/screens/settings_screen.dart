import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_provider.dart';
import '../router.dart';
import '../src/models/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();

    final notifier = ref.read(settingsProvider.notifier);
    final tt       = Theme.of(context).textTheme;

    return Column(
      children: [
        _Header(),
        Expanded(
          child: ListView(
            children: [

              // ── Language ───────────────────────────────────────────────────
              _SectionHeader('Language'),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(_languageName(settings.languageCode)),
                trailing: const Icon(Icons.chevron_right),
                dense: true,
                onTap: () => _showLanguageDialog(context, settings.languageCode, notifier.setLanguage),
              ),
              const Divider(height: 1),

              // ── Appearance ─────────────────────────────────────────────────
              _SectionHeader('Appearance'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _ThemeSelector(
                  current: settings.themeMode,
                  onChanged: notifier.setThemeMode,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.straighten_outlined),
                title: const Text('Units of Measurement'),
                trailing: const Icon(Icons.chevron_right),
                dense: true,
                onTap: () => context.push(Routes.settingsUnits),
              ),
              const Divider(height: 1),

              // ── Ballistics ─────────────────────────────────────────────────
              _SectionHeader('Ballistics'),
              ListTile(
                leading: const Icon(Icons.tune_outlined),
                title: const Text('Adjustment Display'),
                trailing: const Icon(Icons.chevron_right),
                dense: true,
                onTap: () => context.push(Routes.settingsAdjustment),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.speed_outlined),
                title: const Text('Show subsonic transition', style: TextStyle(fontSize: 14)),
                value: settings.showSubsonicTransition,
                onChanged: (v) => notifier.setSwitch('subsonicTransition', v),
                dense: true,
              ),
              _StepTile(
                icon: Icons.table_rows_outlined,
                label: 'Table distance step',
                value: settings.tableDistanceStep,
                unit: 'm',
                onConfirm: notifier.setTableDistanceStep,
              ),
              _StepTile(
                icon: Icons.show_chart_outlined,
                label: 'Chart distance step',
                value: settings.chartDistanceStep,
                unit: 'm',
                onConfirm: notifier.setChartDistanceStep,
              ),
              const Divider(height: 1),

              // ── Profiles ───────────────────────────────────────────────────
              _SectionHeader('Profiles'),
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
              _SectionHeader('Links'),
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
              _SectionHeader('About'),
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
  _    => 'English',
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
          if (v != null) { onSelect(v); Navigator.pop(ctx); }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs.map((l) => RadioListTile<String>(
            value: l.$1,
            title: Text(l.$2),
          )).toList(),
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
          child: Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: cs.primary,
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
        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('System')),
        ButtonSegment(value: ThemeMode.light,  icon: Icon(Icons.light_mode_outlined),      label: Text('Light')),
        ButtonSegment(value: ThemeMode.dark,   icon: Icon(Icons.dark_mode_outlined),       label: Text('Dark')),
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

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.onConfirm,
  });

  final IconData               icon;
  final String                 label;
  final double                 value;
  final String                 unit;
  final ValueChanged<double>   onConfirm;

  @override
  Widget build(BuildContext context) {
    final display = value % 1 == 0 ? '${value.toInt()} $unit' : '$value $unit';
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(display, style: Theme.of(context).textTheme.bodyMedium),
      dense: true,
      onTap: () => _showDialog(context),
    );
  }

  void _showDialog(BuildContext context) {
    final controller = TextEditingController(text: value % 1 == 0 ? '${value.toInt()}' : '$value');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(suffixText: unit),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) onConfirm(v);
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
