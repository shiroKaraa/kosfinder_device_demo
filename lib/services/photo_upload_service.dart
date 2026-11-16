import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoUploadResult {
  const PhotoUploadResult(this.storagePath, this.publicUrl);

  final String storagePath;
  final String publicUrl;
}

class PhotoUploadService {
  static const _bucket = 'kosfinder-demo';

  Future<PhotoUploadResult> upload(File file) async {
    final supabase = Supabase.instance.client;

    if (supabase.auth.currentSession == null) {
      await supabase.auth.signInAnonymously();
    }

    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      throw const AuthException(
        'Sesi Supabase tidak tersedia setelah sign-in anonymous.',
      );
    }

    final ext = file.path.split('.').last.toLowerCase();
    final filename = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    final objectPath = '$uid/$filename';

    await supabase.storage.from(_bucket).upload(objectPath, file);

    final publicUrl =
        supabase.storage.from(_bucket).getPublicUrl(objectPath);

    return PhotoUploadResult(objectPath, publicUrl);
  }
}