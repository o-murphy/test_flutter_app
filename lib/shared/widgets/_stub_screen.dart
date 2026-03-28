import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart';

/// Reusable stub for screens that are not yet implemented.
/// All screens except Home have a back button + centered title header.
class StubScreen extends StatelessWidget {
  const StubScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: title,
      isSubscreen: true,
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
