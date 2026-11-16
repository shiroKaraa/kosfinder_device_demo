import 'package:geolocator/geolocator.dart';

enum LocationFailureType { serviceDisabled, denied, deniedForever }

class LocationFailure implements Exception {
  const LocationFailure(this.type, this.message);

  final LocationFailureType type;
  final String message;

  @override
  String toString() => message;
}

class DeviceLocationService {
  /// Ambil posisi saat ini. Lempar [LocationFailure] untuk kondisi izin/layanan,
  /// dan lempar [TimeoutException] (dari geolocator) bila timeLimit terlewati.
  Future<Position> getPosition() async {
    // 1) Pastikan layanan lokasi perangkat aktif.
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        LocationFailureType.serviceDisabled,
        'GPS/lokasi perangkat tidak aktif. Nyalakan melalui Settings.',
      );
    }

    // 2) Cek status izin saat ini.
    var permission = await Geolocator.checkPermission();

    // 3) Minta izin bila belum pernah diberikan.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 4) Tangani hasil penolakan.
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        LocationFailureType.denied,
        'Izin lokasi ditolak. Foto dan draft tetap dapat digunakan.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureType.deniedForever,
        'Izin lokasi ditolak permanen. Ubah di Settings aplikasi.',
      );
    }

    // 5) Ambil posisi dengan batas waktu.
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }
}