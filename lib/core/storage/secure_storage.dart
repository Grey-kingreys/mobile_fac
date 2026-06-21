import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<void> saveTokens({required String access, required String refresh}) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: access),
      _storage.write(key: _refreshTokenKey, value: refresh),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  /// Vérifie que l'access token existe ET que son champ `exp` (JWT) n'est pas expiré.
  Future<bool> hasValidToken() async {
    return _isJwtValid(await getAccessToken());
  }

  /// Vrai si une session est restaurable : access token encore valide **ou**
  /// refresh token encore valide. Dans ce dernier cas l'access expiré sera
  /// rafraîchi automatiquement au premier 401 (voir AuthInterceptor).
  ///
  /// À utiliser pour décider si l'utilisateur est « connecté » (démarrage,
  /// garde-fou du routeur) — sinon on déconnecte dès l'expiration de l'access
  /// (60 min) alors que le refresh token reste valide 7 jours.
  Future<bool> hasSession() async {
    if (await _isJwtValidAsync(getAccessToken())) return true;
    return _isJwtValidAsync(getRefreshToken());
  }

  Future<bool> _isJwtValidAsync(Future<String?> tokenFuture) async =>
      _isJwtValid(await tokenFuture);

  /// Décode un JWT (sans vérifier la signature — ça reste côté serveur) et
  /// renvoie true si son champ `exp` est dans le futur.
  bool _isJwtValid(String? token) {
    if (token == null || token.isEmpty) return false;
    try {
      // Un JWT = 3 parties séparées par des points : header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // Le payload est encodé en Base64Url (sans padding) — on normalise le padding
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> claims = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = claims['exp'];
      if (exp == null) return false;

      final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      return DateTime.now().isBefore(expiry);
    } catch (_) {
      // Token malformé → considéré invalide
      return false;
    }
  }
}
