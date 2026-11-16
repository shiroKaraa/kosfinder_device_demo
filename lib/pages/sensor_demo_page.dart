import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorDemoPage extends StatefulWidget {
  const SensorDemoPage({super.key});

  @override
  State<SensorDemoPage> createState() => _SensorDemoPageState();
}

class _SensorDemoPageState extends State<SensorDemoPage> {
  StreamSubscription<UserAccelerometerEvent>? _sub;

  double? _x;
  double? _y;
  double? _z;
  bool _sensorAvailable = true;
  bool _receivedFirstEvent = false;

  Timer? _availabilityTimer;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _availabilityTimer = Timer(const Duration(seconds: 3), () {
      if (!_receivedFirstEvent && mounted) {
        setState(() => _sensorAvailable = false);
      }
    });

    _sub = userAccelerometerEventStream().listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _receivedFirstEvent = true;
          _sensorAvailable = true;
          _x = event.x;
          _y = event.y;
          _z = event.z;
        });
        _availabilityTimer?.cancel();
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _sensorAvailable = false);
        _availabilityTimer?.cancel();
      },
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _availabilityTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Sensor')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.sensors, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'User Accelerometer (tanpa gravitasi)\n'
                      'Nilai berubah saat perangkat digerakkan.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_sensorAvailable)
              Card(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sensor accelerometer tidak tersedia pada perangkat ini.\n'
                          'Android Emulator default tidak menyimulasikan sensor. '
                          'Coba pada HP fisik atau aktifkan virtual sensors '
                          '(Extended Controls → Virtual sensors) jika emulator mendukung.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _AxisCard(
                label: 'Sumbu X',
                value: _x,
                icon: Icons.east,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 10),
              _AxisCard(
                label: 'Sumbu Y',
                value: _y,
                icon: Icons.north,
                color: Colors.green,
              ),
              const SizedBox(height: 10),
              _AxisCard(
                label: 'Sumbu Z',
                value: _z,
                icon: Icons.north_east,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'Satuan: m/s². Nilai mendekati 0 saat perangkat diam.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AxisCard extends StatelessWidget {
  const _AxisCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final double? value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value == null
        ? '—'
        : value!.toStringAsFixed(3).padLeft(7, ' ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              text,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text('m/s²', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}