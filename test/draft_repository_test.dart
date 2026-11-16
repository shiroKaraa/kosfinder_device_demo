import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kosfinder_device_demo/services/draft_repository.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DraftRepository repo;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    tempDir = await Directory.systemTemp.createTemp('ws10_test');
    repo = DraftRepository();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('savePermanentPhoto menolak file > 5 MB', () async {
    final bigFile = File('${tempDir.path}/big.png');
    await bigFile.writeAsBytes(Uint8List(6 * 1024 * 1024)); // 6 MB

    expect(
      () => repo.savePermanentPhoto(XFile(bigFile.path)),
      throwsA(isA<FormatException>()),
    );
  });

  test('savePermanentPhoto menolak format selain JPG/JPEG/PNG', () async {
    final gifFile = File('${tempDir.path}/animasi.gif');
    await gifFile.writeAsBytes(Uint8List(1024));

    expect(
      () => repo.savePermanentPhoto(XFile(gifFile.path)),
      throwsA(isA<FormatException>()),
    );
  });
}