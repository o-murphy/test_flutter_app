import 'package:flutter/material.dart';

/// A small all-caps section header used in list screens.
class ListSectionTile extends StatelessWidget {
  const ListSectionTile(this.title, {this.trailing, super.key});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.primary,
          letterSpacing: 0.8,
        ),
      ),
      dense: true,
      trailing: trailing,
      // style: ListTileStyle.list, // робить більш компактним
    );
  }
}
