// ─── Page dots indicator with navigation arrows ──────────────────────────────

import 'package:flutter/material.dart';

class PageDotsIndicator extends StatelessWidget {
  const PageDotsIndicator({
    required this.current,
    required this.count,
    required this.onPageChanged,
    super.key,
  });

  final int current;
  final int count;
  final void Function(int page) onPageChanged;

  void _previousPage() {
    if (current > 0) onPageChanged(current - 1);
  }

  void _nextPage() {
    if (current < count - 1) onPageChanged(current + 1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canGoPrev = current > 0;
    final canGoNext = current < count - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left arrow
        IconButton(
          onPressed: canGoPrev ? _previousPage : null,
          icon: Icon(Icons.chevron_left, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),

        // Dots
        ...List.generate(count, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? cs.primary : cs.onSurface.withAlpha(60),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),

        // Right arrow
        IconButton(
          onPressed: canGoNext ? _nextPage : null,
          icon: Icon(Icons.chevron_right, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}
