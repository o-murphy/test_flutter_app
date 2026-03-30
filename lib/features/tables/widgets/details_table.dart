import 'package:eballistica/features/tables/details_table_mv.dart';
import 'package:eballistica/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailsTable extends ConsumerWidget {
  const DetailsTable({super.key}); // ← прибрали required this.details

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(detailsTableMvProvider);

    // Якщо даних немає - показуємо empty state
    if (details == null) {
      return const EmptyStatePlaceholder();
    }

    return _DetailsTable(details: details);
  }
}

class _DetailsTable extends StatelessWidget {
  const _DetailsTable({required this.details});

  final DetailsTableData details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      color: cs.onSurface,
    );
    final sectionStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text(value, style: valueStyle),
        ],
      ),
    );

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Text(title.toUpperCase(), style: sectionStyle),
    );

    final items = <Widget>[];

    // Rifle
    final hasRifle = details.caliber != null || details.twist != null;
    if (hasRifle) {
      items.add(section('Rifle'));
      items.add(row('Name', details.rifleName));
      if (details.caliber != null) items.add(row('Caliber', details.caliber!));
      if (details.twist != null) items.add(row('Twist', details.twist!));
    }

    // Projectile
    final hasProj =
        details.dragModel != null ||
        details.bc != null ||
        details.zeroMv != null ||
        details.currentMv != null ||
        details.zeroDist != null ||
        details.bulletLen != null ||
        details.bulletDiam != null ||
        details.bulletWeight != null ||
        details.formFactor != null ||
        details.sectionalDensity != null ||
        details.gyroStability != null;
    if (hasProj) {
      items.add(section('Projectile'));
      if (details.dragModel != null) {
        items.add(row('Drag model', details.dragModel!));
      }
      if (details.bc != null) items.add(row('BC', details.bc!));
      if (details.zeroMv != null) items.add(row('Zero MV', details.zeroMv!));
      if (details.currentMv != null) {
        items.add(row('Current MV', details.currentMv!));
      }
      if (details.zeroDist != null) {
        items.add(row('Zero distance', details.zeroDist!));
      }
      if (details.bulletLen != null) {
        items.add(row('Length', details.bulletLen!));
      }
      if (details.bulletDiam != null) {
        items.add(row('Diameter', details.bulletDiam!));
      }
      if (details.bulletWeight != null) {
        items.add(row('Weight', details.bulletWeight!));
      }
      if (details.formFactor != null) {
        items.add(row('Form factor', details.formFactor!));
      }
      if (details.sectionalDensity != null) {
        items.add(row('Sectional density', details.sectionalDensity!));
      }
      if (details.gyroStability != null) {
        items.add(row('Gyrostability (Sg)', details.gyroStability!));
      }
    }

    // Atmosphere
    final hasAtmo =
        details.temperature != null ||
        details.humidity != null ||
        details.pressure != null ||
        details.windSpeed != null ||
        details.windDir != null;
    if (hasAtmo) {
      items.add(section('Atmosphere'));
      if (details.temperature != null) {
        items.add(row('Temperature', details.temperature!));
      }
      if (details.humidity != null) {
        items.add(row('Humidity', details.humidity!));
      }
      if (details.pressure != null) {
        items.add(row('Pressure', details.pressure!));
      }
      if (details.windSpeed != null) {
        items.add(row('Wind speed', details.windSpeed!));
      }
      if (details.windDir != null) {
        items.add(row('Wind direction', details.windDir!));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(children: items);
  }
}
