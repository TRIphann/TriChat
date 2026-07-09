// Stub for web - geolocator not available
class Geolocator {
  static Future<LocationPermission> checkPermission() async {
    return LocationPermission.denied;
  }

  static Future<LocationPermission> requestPermission() async {
    return LocationPermission.denied;
  }

  static Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
  }) async {
    throw UnimplementedError('Geolocator not available on web');
  }
}

enum LocationPermission {
  denied,
  deniedForever,
  always,
  whileInUse,
}

enum LocationAccuracy {
  high,
  medium,
  low,
  best,
}

class Position {
  final double latitude;
  final double longitude;

  Position({required this.latitude, required this.longitude});
}
