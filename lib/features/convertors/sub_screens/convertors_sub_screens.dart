export 'package:eballistica/features/convertors/sub_screens/length_convertor_screen.dart';
export 'package:eballistica/features/convertors/sub_screens/weight_convertor_screen.dart';
export 'package:eballistica/features/convertors/sub_screens/pressure_convertor_screen.dart';

import 'package:eballistica/shared/widgets/_stub_screen.dart';
import 'package:flutter/material.dart';

class DistanceConvertorScreen extends StatelessWidget {
  const DistanceConvertorScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Distance Convertor');
}

class VelocityConvertorScreen extends StatelessWidget {
  const VelocityConvertorScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Velocity Convertor');
}

class TemperatureConvertorScreen extends StatelessWidget {
  const TemperatureConvertorScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Temperature Convertor');
}

class MilMoaConvertorScreen extends StatelessWidget {
  const MilMoaConvertorScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'MIL / MOA Convertor');
}

class TorqueConvertorScreen extends StatelessWidget {
  const TorqueConvertorScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Torque Convertor');
}
