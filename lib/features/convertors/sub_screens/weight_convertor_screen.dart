import 'package:eballistica/features/convertors/generic_convertor_vm_field.dart';
import 'package:eballistica/features/convertors/weight_convertor_vm.dart';
import 'package:eballistica/shared/widgets/unit_input_with_unit_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/info_tile.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';

class WeightConvertorScreen extends ConsumerWidget {
  const WeightConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weightConvertorVmProvider);
    final notifier = ref.read(weightConvertorVmProvider.notifier);

    return BaseScreen(
      title: 'Weight Converter',
      isSubscreen: true,
      body: ListView(
        children: [
          UnitInputWithPicker(
            value: state.rawValue,
            constraints: notifier.getConstraintsForUnit(state.inputUnit),
            displayUnit: state.inputUnit,
            onChanged: notifier.updateRawValue,
            onUnitChanged: notifier.changeInputUnit,
            options: const [
              Unit.gram,
              Unit.kilogram,
              Unit.grain,
              Unit.pound,
              Unit.ounce,
            ],
            hintText: 'Enter weight',
          ),
          const Divider(height: 24),

          ListSectionTile('Metric'),
          _buildInfoTile(state.grams),
          _buildInfoTile(state.kilograms),

          ListSectionTile('Imperial'),
          _buildInfoTile(state.grains),
          _buildInfoTile(state.pounds),
          _buildInfoTile(state.ounces),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoTile(GenericConvertorField field) {
    return InfoListTile(label: field.label, value: field.formattedValue);
  }
}
