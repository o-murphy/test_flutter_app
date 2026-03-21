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
          const Icon(Icons.cloud, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Conditions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('There will be shooting conditions'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => print("Calculating..."),
            child: const Text("Start Calculation"),
          ),
        ],
      ),
    );
  }
}
