import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';

import 'package:kosfinder_device_demo/main.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  testWidgets('Kerangka KosFinder menampilkan form, kamera, dan tombol GPS',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KosFinderDeviceApp());
    await tester.pumpAndSettle();

    expect(find.text('KosFinder · Device Demo'), findsOneWidget);
    expect(find.byIcon(Icons.sensors), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Galeri'), findsOneWidget);
    expect(find.text('Simpan Draft Lokal'), findsOneWidget);
    expect(find.text('Ambil Koordinat GPS'), findsOneWidget);
    expect(find.textContaining('Koordinat: belum diisi'), findsOneWidget);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Draft lokal dipulihkan saat aplikasi dibuka kembali',
      (WidgetTester tester) async {
    // Seed SharedPreferences dengan draft yang sudah ada.
    final seed = InMemorySharedPreferencesAsync.withData({
      'kosfinder_device_demo_draft_v1': jsonEncode({
        'name': 'Kos Melati',
        'photoPath': null,
        'latitude': -8.65,
        'longitude': 115.216667,
      }),
    });
    SharedPreferencesAsyncPlatform.instance = seed;

    await tester.pumpWidget(const KosFinderDeviceApp());
    await tester.pumpAndSettle();

    // Nama kos terisi dari draft.
    expect(find.text('Kos Melati'), findsOneWidget);

    // Koordinat tampil dari draft.
    expect(find.textContaining('Lat: -8.650000'), findsOneWidget);
    expect(find.textContaining('Lng: 115.216667'), findsOneWidget);

    debugDefaultTargetPlatformOverride = null;
  });
}