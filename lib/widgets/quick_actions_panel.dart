import 'package:flutter/material.dart';

import 'icon_value_button.dart';

class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return IconValueButtonRow(
      
      height: 104,
      items: [
        IconValueButton(
          icon: Icons.air_outlined,
          value: '5.4 m/s',
          label: 'Wind speed',
          onTap: () {},
          heroTag: 'qa-wind',
        ),
        IconValueButton(
          icon: Icons.square_foot,
          value: '0°',
          label: 'Look angle',
          onTap: () {},
          heroTag: 'qa-angle',
        ),
        IconValueButton(
          icon: Icons.flag_outlined,
          value: '420 m',
          label: 'Target range',
          onTap: () {},
          heroTag: 'qa-range',
        ),
      ],
    );
  }
}
