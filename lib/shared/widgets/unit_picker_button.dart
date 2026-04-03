import 'package:eballistica/core/solver/unit.dart';
import 'package:flutter/material.dart';

/// Віджет для вибору одиниці виміру з BottomSheet
class UnitPickerButton extends StatelessWidget {
  const UnitPickerButton({
    required this.current,
    required this.onChanged,
    required this.options,
    this.label = 'Select Unit',
    this.width = 60, // додаємо параметр ширини
    super.key,
  });

  final Unit current;
  final ValueChanged<Unit> onChanged;
  final List<Unit> options;
  final String label;
  final double width; // фіксована ширина

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => _showPicker(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  current.symbol,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1),
            ...options.map(
              (unit) => ListTile(
                title: Text('${unit.label} (${unit.symbol})'),
                trailing: current == unit ? const Icon(Icons.check) : null,
                onTap: () {
                  onChanged(unit);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
