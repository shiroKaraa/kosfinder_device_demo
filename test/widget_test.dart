import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';

import 'package:kosfinder_device_demo/main.dart';

void main() {
  const testViewport = Size(1080, 2400);

  Future<void Function()> _prepare(WidgetTester tester) async {
    tester.view.physicalSize = testViewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    return () => debugDefaultTargetPlatformOverride = null;
  }

  testWidgets('Halaman utama menampilkan section dan tombol utama',
      (WidgetTester tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    final restore = await _prepare(tester);
    try {
      await tester.pumpWidget(const KosFinderDeviceApp());
      await tester.pumpAndSettle();

      // AppBar
      expect(find.text('KosFinder · Device Demo'), findsOneWidget);
      expect(find.byIcon(Icons.sensors), findsOneWidget);

      // Header & section
      expect(find.text('KosFinder Device Demo'), findsOneWidget);
      expect(find.text('Info Kos'), findsOneWidget);
      expect(find.text('Foto Kos'), findsOneWidget);
      expect(find.text('Lokasi'), findsOneWidget);
      expect(find.text('Simpan & Sinkronisasi'), findsOneWidget);

      // Tombol fungsional
      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Galeri'), findsOneWidget);
      expect(find.text('Ambil Koordinat GPS'), findsOneWidget);
      expect(find.text('Simpan Draft Lokal'), findsOneWidget);

      // Upload disabled saat offline
      final uploadButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Upload Foto ke Supabase'),
      );
      expect(uploadButton.onPressed, isNull);

      // Badge mode offline
      expect(find.text('Mode lokal/offline'), findsOneWidget);
    } finally {
      restore();
    }
  });

  testWidgets('Draft lokal dipulihkan saat aplikasi dibuka kembali',
      (WidgetTester tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
      'kosfinder_device_demo_draft_v1': jsonEncode({
        'name': 'Kos Melati',
        'photoPath': null,
        'latitude': -8.65,
        'longitude': 115.216667,
      }),
    });

    final restore = await _prepare(tester);
    try {
      await tester.pumpWidget(const KosFinderDeviceApp());
      await tester.pumpAndSettle();

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.textContaining('Lat: -8.650000'), findsOneWidget);
      expect(find.textContaining('Lng: 115.216667'), findsOneWidget);
    } finally {
      restore();
    }
  });
}