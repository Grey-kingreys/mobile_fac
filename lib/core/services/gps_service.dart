import 'package:geolocator/geolocator.dart';

class GpsService {
  /// Demande la permission GPS. Retourne `true` si accordée.
  static Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Obtient la position courante. Retourne `null` en cas d'échec.
  static Future<Position?> getCurrentPosition() async {
    try {
      final granted = await requestPermission();
      if (!granted) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }

  /// Stream de positions toutes les [intervalSeconds] secondes.
  static Stream<Position?> positionStream({int intervalSeconds = 60}) async* {
    while (true) {
      yield await getCurrentPosition();
      await Future.delayed(Duration(seconds: intervalSeconds));
    }
  }
}
