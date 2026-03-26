import 'package:flutter/material.dart';

/// FAB-style button with icon + value on the button and a label below.
/// Must be used inside a bounded-height parent (e.g. [IconValueButtonRow]).
class IconValueButton extends StatelessWidget {
  const IconValueButton({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    this.heroTag,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: SizedBox.expand(
            child: FloatingActionButton(
              heroTag: heroTag,
              onPressed: onTap,
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              elevation: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Row of [IconValueButton]s with equal flex and a fixed total height.
class IconValueButtonRow extends StatelessWidget {
  const IconValueButtonRow({
    super.key,
    required this.items,
    this.height = 100,
    this.spacing = 8.0,
  });

  final List<IconValueButton> items;
  final double height;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(child: items[i]),
          ],
        ],
      ),
    );
  }
}
