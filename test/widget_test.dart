import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kosfinder_device_demo/main.dart';

void main() {
  testWidgets('Kerangka KosFinder tampil dengan judul dan tombol sensor',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KosFinderDeviceApp());

    // Judul di AppBar.
    expect(find.text('KosFinder · Device Demo'), findsOneWidget);

    // Tombol navigasi ke halaman sensor.
    expect(find.byIcon(Icons.sensors), findsOneWidget);

    // Teks placeholder kerangka.
    expect(
      find.textContaining('Kerangka aplikasi siap'),
      findsOneWidget,
    );
  });
}