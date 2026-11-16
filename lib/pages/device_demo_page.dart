import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cloud_config.dart';
import '../services/device_location_service.dart';
import '../services/draft_repository.dart';
import '../services/photo_upload_service.dart';
import 'sensor_demo_page.dart';

class DeviceDemoPage extends StatefulWidget {
  const DeviceDemoPage({super.key});

  @override
  State<DeviceDemoPage> createState() => _DeviceDemoPageState();
}

class _DeviceDemoPageState extends State<DeviceDemoPage> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  final _drafts = DraftRepository();
  final _location = DeviceLocationService();
  final _uploader = PhotoUploadService();

  String? _photoPath;
  String? _storagePath;
  String? _publicUrl;
  double? _latitude;
  double? _longitude;
  LocationFailureType? _locationError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _restoreLocalDraft();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _restoreLocalDraft() async {
    try {
      final draft = await _drafts.load();
      if (!mounted) return;

      final storedPhoto = draft['photoPath'] as String?;
      final photoFileExists =
          storedPhoto != null && File(storedPhoto).existsSync();

      setState(() {
        _nameController.text = draft['name'] as String? ?? '';
        _photoPath = photoFileExists ? storedPhoto : null;
        _storagePath = draft['storagePath'] as String?;
        _publicUrl = draft['publicUrl'] as String?;
        final lat = draft['latitude'];
        final lng = draft['longitude'];
        _latitude = lat is num ? lat.toDouble() : null;
        _longitude = lng is num ? lng.toDouble() : null;
      });

      if (storedPhoto != null && !photoFileExists) {
        _notice('File foto draft tidak ditemukan; silakan pilih ulang.');
      }

      await _recoverInterruptedPicker();
    } catch (error) {
      _notice('Draft lokal belum dapat dibaca: $error');
    }
  }

  Future<void> _recoverInterruptedPicker() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final lost = await _picker.retrieveLostData();
    if (lost.isEmpty) return;
    if (lost.files != null && lost.files!.isNotEmpty) {
      await _acceptPhoto(lost.files!.first);
      _notice('Foto dari proses kamera/galeri yang terputus dipulihkan.');
    } else if (lost.exception != null) {
      _notice('Pemulihan foto gagal: ${lost.exception}');
    }
  }

  Future<void> _saveDraft({bool showMessage = true}) async {
    await _drafts.save({
      'name': _nameController.text.trim(),
      'photoPath': _photoPath,
      'latitude': _latitude,
      'longitude': _longitude,
      'storagePath': _storagePath,
      'publicUrl': _publicUrl,
    });
    if (showMessage) _notice('Draft berhasil disimpan di perangkat.');
  }

  Future<void> _acceptPhoto(XFile picked) async {
    final permanentPath = await _drafts.savePermanentPhoto(picked);
    if (!mounted) return;
    setState(() {
      _photoPath = permanentPath;
      _storagePath = null;
      _publicUrl = null;
    });
    await _saveDraft(showMessage: false);
  }

  Future<void> _choosePhoto(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked == null) {
        _notice('Pemilihan foto dibatalkan; draft tidak berubah.');
        return;
      }
      await _acceptPhoto(picked);
      _notice('Foto disalin ke penyimpanan permanen aplikasi.');
    } on PlatformException catch (error) {
      _notice(
        'Kamera/galeri tidak tersedia (${error.code}). Cek izin perangkat.',
      );
    } on FormatException catch (error) {
      _notice(error.message);
    } catch (error) {
      _notice('Gagal memilih foto: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _getLocation() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _locationError = null;
    });
    try {
      final position = await _location.getPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      await _saveDraft(showMessage: false);
      _notice('Koordinat berhasil diambil dan tersimpan dalam draft.');
    } on LocationFailure catch (error) {
      if (!mounted) return;
      setState(() => _locationError = error.type);
      _notice(error.message);
    } on TimeoutException {
      _notice('Waktu mencari GPS habis. Coba dekat jendela/area terbuka.');
    } catch (error) {
      _notice('Lokasi tidak dapat diambil: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    if (_busy || !CloudConfig.enabled) return;
    if (_nameController.text.trim().isEmpty) {
      _notice('Isi nama kos sebelum mengunggah foto.');
      return;
    }
    final path = _photoPath;
    if (path == null || !File(path).existsSync()) {
      _notice('Ambil/pilih foto terlebih dahulu.');
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await _uploader.upload(File(path));
      if (!mounted) return;
      setState(() {
        _storagePath = result.storagePath;
        _publicUrl = result.publicUrl;
      });
      await _saveDraft(showMessage: false);
      _notice('Berhasil! Foto tersedia pada Supabase Storage.');
    } on AuthException catch (error) {
      _notice('Login anonymous Supabase gagal: ${error.message}');
    } on StorageException catch (error) {
      _notice('Upload ditolak Storage: ${error.message}');
    } catch (error) {
      _notice('Gagal upload: $error. Draft lokal tetap ada.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmClearDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus draft lokal?'),
        content: const Text(
          'Nama, foto, dan koordinat yang tersimpan akan dihapus. '
          'File foto lama tetap berada di penyimpanan aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _drafts.clear();
    if (!mounted) return;
    setState(() {
      _nameController.clear();
      _photoPath = null;
      _storagePath = null;
      _publicUrl = null;
      _latitude = null;
      _longitude = null;
      _locationError = null;
    });
    _notice('Draft berhasil dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoExists = _photoPath != null && File(_photoPath!).existsSync();

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
          IconButton(
            tooltip: 'Hapus draft lokal',
            icon: const Icon(Icons.delete_outline),
            onPressed: _busy ? null : _confirmClearDraft,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ModeHeader(),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.storefront_outlined,
              title: 'Info Kos',
              child: TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama kos',
                  hintText: 'Contoh: Kos Melati',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.photo_camera_outlined,
              title: 'Foto Kos',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _choosePhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Kamera'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _choosePhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galeri'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PhotoPreview(photoPath: photoExists ? _photoPath : null),
                  const SizedBox(height: 8),
                  Text(
                    'Format JPG/JPEG/PNG, maksimal 5 MB.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.place_outlined,
              title: 'Lokasi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _busy ? null : _getLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Ambil Koordinat GPS'),
                  ),
                  const SizedBox(height: 10),
                  _LocationInfo(
                    latitude: _latitude,
                    longitude: _longitude,
                  ),
                  if (_locationError ==
                      LocationFailureType.serviceDisabled)
                    TextButton.icon(
                      onPressed: () => Geolocator.openLocationSettings(),
                      icon: const Icon(Icons.settings),
                      label:
                          const Text('Buka pengaturan layanan lokasi'),
                    ),
                  if (_locationError ==
                      LocationFailureType.deniedForever)
                    TextButton.icon(
                      onPressed: () => Geolocator.openAppSettings(),
                      icon: const Icon(Icons.settings_applications),
                      label: const Text('Buka pengaturan izin aplikasi'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.save_outlined,
              title: 'Simpan & Sinkronisasi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            try {
                              await _saveDraft();
                            } catch (error) {
                              _notice('Gagal menyimpan draft: $error');
                            }
                          },
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Draft Lokal'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed:
                        _busy || !CloudConfig.enabled ? null : _upload,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Upload Foto ke Supabase'),
                  ),
                  if (!CloudConfig.enabled) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Aktifkan dengan --dart-define (lihat README) '
                      'untuk mengunggah ke Supabase.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_storagePath != null) ...[
                    const SizedBox(height: 14),
                    const Text('Lokasi objek Storage:'),
                    SelectableText(_storagePath!),
                  ],
                  if (_publicUrl != null) ...[
                    const SizedBox(height: 8),
                    const Text('URL foto publik:'),
                    SelectableText(_publicUrl!),
                  ],
                ],
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 20),
            const _FooterNote(),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ */
/* Widget kecil (presentational) — dipisah agar build() tetap ringkas */
/* ------------------------------------------------------------------ */

class _ModeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = CloudConfig.enabled;
    final color = online ? Colors.teal : theme.colorScheme.onSurfaceVariant;
    final icon = online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined;
    final label = online ? 'Lokal + Supabase' : 'Mode lokal/offline';

    return Container(
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
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Icon(Icons.home_work_outlined,
                color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KosFinder Device Demo',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Praktikum fitur perangkat standalone',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photoPath});

  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (photoPath == null) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined,
                  size: 32, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(
                'Belum ada foto',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(photoPath!),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _LocationInfo extends StatelessWidget {
  const _LocationInfo({required this.latitude, required this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation = latitude != null && longitude != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Row(
        children: [
          Icon(Icons.gps_fixed,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasLocation
                  ? 'Lat: ${latitude!.toStringAsFixed(6)}, '
                      'Lng: ${longitude!.toStringAsFixed(6)}'
                  : 'Koordinat: belum diisi (opsional)',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 18, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'GPS menunjukkan posisi ponsel, bukan otomatis posisi kos. '
              'Jangan unggah foto orang atau informasi pribadi untuk demo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}