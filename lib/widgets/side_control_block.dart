import 'package:flutter/material.dart';

class SideControlBlock extends StatelessWidget {
  final IconData topIcon;
  final IconData bottomIcon;
  final List<(IconData, String)> infoRows;
  final VoidCallback onTopPressed;
  final VoidCallback onBottomPressed;

  const SideControlBlock({
    super.key,
    required this.topIcon,
    required this.bottomIcon,
    required this.infoRows,
    required this.onTopPressed,
    required this.onBottomPressed,
  });

  Widget _fab(BuildContext context, IconData icon, VoidCallback onPressed) {
    final cs = Theme.of(context).colorScheme;
    return FloatingActionButton.small(
      elevation: 1,
      heroTag: null,
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      onPressed: onPressed,
      child: Icon(icon, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        _fab(context, topIcon, onTopPressed),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < infoRows.length; i++) ...[
                Icon(infoRows[i].$1, size: 18, color: cs.onSurface.withValues(alpha: 0.65)),
                if (infoRows[i].$2.isNotEmpty)
                  Text(
                    infoRows[i].$2,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.85)),
                    textAlign: TextAlign.center,
                  ),
                if (i < infoRows.length - 1) const SizedBox(height: 4),
              ],
            ],
          ),
        ),
        _fab(context, bottomIcon, onBottomPressed),
      ],
    );
  }
}
