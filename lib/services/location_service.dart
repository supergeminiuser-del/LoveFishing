import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Обёртка над нативным GPS устройства. Работает полностью офлайн —
/// используется только встроенный модуль геолокации телефона.
class LocationService {
  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LatLng?> getCurrentPosition() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) return null;
    final serviceEnabled = await isServiceEnabled();
    if (!serviceEnabled) return null;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  Stream<LatLng> watchPosition({int distanceFilterMeters = 5}) {
    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );
    return Geolocator.getPositionStream(locationSettings: settings)
        .map((p) => LatLng(p.latitude, p.longitude));
  }

  double distanceMeters(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  double totalDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (var i = 0; i < points.length - 1; i++) {
      total += distanceMeters(points[i], points[i + 1]);
    }
    return total / 1000;
  }
}
