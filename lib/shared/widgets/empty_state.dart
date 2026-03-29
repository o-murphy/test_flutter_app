import 'package:flutter/material.dart';

class EmptyStatePlaceholder extends StatelessWidget {
  final String message;

  const EmptyStatePlaceholder({super.key, this.message = 'No data'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
