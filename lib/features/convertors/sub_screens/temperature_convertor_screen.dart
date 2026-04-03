import 'package:eballistica/features/convertors/generic_convertor_vm_field.dart';
import 'package:eballistica/features/convertors/temperature_convertor_vm.dart';
import 'package:eballistica/shared/widgets/unit_constrained_input_with_unit_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/info_tile.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';

class TemperatureConvertorScreen extends ConsumerWidget {
  const TemperatureConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(temperatureConvertorVmProvider);
    final notifier = ref.read(temperatureConvertorVmProvider.notifier);

    return BaseScreen(
      title: 'Temperature Converter',
      isSubscreen: true,
      body: ListView(
        children: [
          UnitInputWithPicker(
            value: state.rawValue,
            constraints: notifier.getConstraintsForUnit(state.inputUnit),
            displayUnit: state.inputUnit,
            onChanged: notifier.updateRawValue,
            onUnitChanged: notifier.changeInputUnit,
            options: const [Unit.celsius, Unit.fahrenheit],
            hintText: 'Enter temperature',
          ),
          const Divider(height: 24),

          ListSectionTile('Metric'),
          _buildInfoTile(state.celsius),
          ListSectionTile('Imperial'),
          _buildInfoTile(state.fahrenheit),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoTile(GenericConvertorField field) {
    return InfoListTile(label: field.label, value: field.formattedValue);
  }
}
