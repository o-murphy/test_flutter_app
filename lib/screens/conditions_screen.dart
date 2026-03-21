// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

class ConditionsScreen extends StatelessWidget {
  const ConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TODO: remove this block when complete
          const Icon(Icons.cloud, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Conditions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('There will be shooting conditions'),
          // endblock

          // Card
          Card.filled(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => print("t Down"),
                  icon: Icon(Icons.arrow_downward_outlined),
                ),
                Text("<Temperature value>"),
                IconButton(
                  onPressed: () => print("t Up"),
                  icon: Icon(Icons.arrow_upward_outlined),
                ),
              ],
            ),
          ),
          Row(
            children: [
              FloatingActionButton(
                onPressed: () => print("Altitude"),
                child: Icon(Icons.terrain_outlined),
              ),
              FloatingActionButton(
                onPressed: () => print("Humidity"),
                child: Icon(Icons.water_drop_outlined),
              ),
              FloatingActionButton(
                onPressed: () => print("Pressure"),
                child: Icon(Icons.speed_outlined),
              ),
            ],
          ),
          Row(
            children: [
              Text("Enable Pressure dependency from alt"),
              Switch(
                value: false,
                onChanged: (value) =>
                    print("Enable pressure dep from alt $value"),
              ),
            ],
          ),
          Row(
            children: [
              Text("Enable derivation"),
              Switch(
                value: false,
                onChanged: (value) => print("Enable derivation $value"),
              ),
            ],
          ),
          Row(
            children: [
              Text("Enable coriolis"),
              Switch(
                value: false,
                onChanged: (value) => print("Enable coriolis $value"),
              ),
            ],
          ),
          // TODO: There should be hiden Coriolis params
          Row(
            children: [
              Text("Enable aerodynamic jump"),
              Switch(
                value: false,
                onChanged: (value) => print("Enable aerodynamic jump $value"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
