import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Émet `true` quand l'appareil est connecté, `false` sinon.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) =>
        results.isNotEmpty && !results.contains(ConnectivityResult.none),
  );
});

/// Lecture ponctuelle (non-stream) de la connectivité.
final connectivityProvider = FutureProvider<bool>((ref) async {
  final results = await Connectivity().checkConnectivity();
  return results.isNotEmpty && !results.contains(ConnectivityResult.none);
});
