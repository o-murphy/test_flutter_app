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
          InfoListTile(
            label: '${state.atm.label} (${state.atm.symbol})',
            value: state.atm.formattedValue,
            icon: null,
          ),
          InfoListTile(
            label: '${state.hPa.label} (${state.hPa.symbol})',
            value: state.hPa.formattedValue,
            icon: null,
          ),
          InfoListTile(
            label: '${state.bar.label} (${state.bar.symbol})',
            value: state.bar.formattedValue,
            icon: null,
          ),

          ListSectionTile('Imperial'),
          InfoListTile(
            label: '${state.psi.label} (${state.psi.symbol})',
            value: state.psi.formattedValue,
            icon: null,
          ),
          InfoListTile(
            label: '${state.inHg.label} (${state.inHg.symbol})',
            value: state.inHg.formattedValue,
            icon: null,
          ),
          InfoListTile(
            label: '${state.mmHg.label} (${state.mmHg.symbol})',
            value: state.mmHg.formattedValue,
            icon: null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
