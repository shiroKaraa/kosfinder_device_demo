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

  testWidgets('Kerangka KosFinder menampilkan form & tombol dasar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KosFinderDeviceApp());
    await tester.pumpAndSettle();

    expect(find.text('KosFinder · Device Demo'), findsOneWidget);
    expect(find.byIcon(Icons.sensors), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Galeri'), findsOneWidget);
    expect(find.text('Simpan Draft Lokal'), findsOneWidget);

    // Key: reset at the end of the test body
    debugDefaultTargetPlatformOverride = null;
  });
}