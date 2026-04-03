import 'package:eballistica/features/convertors/generic_convertor_vm_field.dart';
import 'package:eballistica/features/convertors/pressure_convertor_vm.dart';
import 'package:eballistica/shared/widgets/unit_input_with_unit_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/info_tile.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';

class PressureConvertorScreen extends ConsumerWidget {
  const PressureConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pressureConvertorVmProvider);
    final notifier = ref.read(pressureConvertorVmProvider.notifier);

    return BaseScreen(
      title: 'Pressure Converter',
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
              Unit.mmHg,
              Unit.inHg,
              Unit.bar,
              Unit.hPa,
              Unit.psi,
              Unit.atm,
            ],
            hintText: 'Enter pressure',
          ),
          const Divider(height: 24),

          ListSectionTile('Common'),
          _buildInfoTile(state.atm),
          _buildInfoTile(state.hPa),
          _buildInfoTile(state.bar),

          ListSectionTile('Imperial'),
          _buildInfoTile(state.psi),
          _buildInfoTile(state.inHg),
          _buildInfoTile(state.mmHg),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoTile(GenericConvertorField field) {
    return InfoListTile(label: field.label, value: field.formattedValue);
  }
}
