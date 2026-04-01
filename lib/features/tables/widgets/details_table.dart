import 'package:eballistica/features/tables/details_table_mv.dart';
import 'package:eballistica/shared/widgets/empty_state.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailsTable extends ConsumerWidget {
  const DetailsTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(detailsTableMvProvider);

    if (details == null) {
      return const EmptyStatePlaceholder();
    }

    return DetailsTableContent(details: details);
  }
}

class DetailsTableContent extends StatelessWidget {
  const DetailsTableContent({required this.details, super.key});

  final DetailsTableData details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget row(String label, String value) => ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          color: cs.onSurface,
        ),
      ),
    );

    Widget section(String title) => ListSectionTile(title);

    final items = <Widget>[];

    // Rifle
    if (items.isNotEmpty) items.add(const Divider(height: 1));
    items.add(section('Rifle'));
    items.add(row('Name', details.rifleName));
    if (details.caliber != null) items.add(row('Caliber', details.caliber!));
    if (details.twist != null) items.add(row('Twist', details.twist!));
    if (details.zeroDist != null) {
      items.add(row('Zero distance', details.zeroDist!));
    }

    // Cartridge
    final hasCart = details.zeroMv != null || details.currentMv != null;
    if (hasCart) {
      if (items.isNotEmpty) items.add(const Divider(height: 1));
      items.add(section('Cartridge'));
      if (details.zeroMv != null) items.add(row('Zero MV', details.zeroMv!));
      if (details.currentMv != null) {
        items.add(row('Current MV', details.currentMv!));
      }
    }

    // Projectile
    final hasProj =
        details.dragModel != null ||
        details.bc != null ||
        details.bulletLen != null ||
        details.bulletDiam != null ||
        details.bulletWeight != null ||
        details.formFactor != null ||
        details.sectionalDensity != null ||
        details.gyroStability != null;
    if (hasProj) {
      if (items.isNotEmpty) items.add(const Divider(height: 1));
      items.add(section('Projectile'));
      if (details.dragModel != null) {
        items.add(row('Drag model', details.dragModel!));
      }
      if (details.bc != null) items.add(row('BC', details.bc!));
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

    // Conditions
    final hasCond =
        details.temperature != null ||
        details.humidity != null ||
        details.pressure != null ||
        details.windSpeed != null ||
        details.windDir != null;
    if (hasCond) {
      if (items.isNotEmpty) items.add(const Divider(height: 1));
      items.add(section('Conditions'));
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

    return ListView(children: items);
  }
}
