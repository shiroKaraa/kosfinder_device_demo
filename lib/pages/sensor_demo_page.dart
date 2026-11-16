import 'package:flutter/material.dart';

class SensorDemoPage extends StatelessWidget {
  const SensorDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Sensor')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Halaman demo accelerometer akan diimplementasikan '
            'pada tahap pengayaan.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}