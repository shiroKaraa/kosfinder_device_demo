enum LocationFailureType { serviceDisabled, denied, deniedForever }

class LocationFailure implements Exception {
  const LocationFailure(this.type, this.message);
  final LocationFailureType type;
  final String message;

  @override
  String toString() => message;
}

class DeviceLocationService {
  DeviceLocationService();
}