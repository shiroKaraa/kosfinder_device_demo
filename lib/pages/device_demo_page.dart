import 'package:flutter/material.dart';

import 'sensor_demo_page.dart';

class DeviceDemoPage extends StatelessWidget {
  const DeviceDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KosFinder · Device Demo'),
        actions: [
          IconButton(
            tooltip: 'Demo sensor',
            icon: const Icon(Icons.sensors),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SensorDemoPage()),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Kerangka aplikasi siap.\n'
            'Fitur kamera, GPS, dan draft lokal akan ditambahkan '
            'pada tahap berikutnya.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}