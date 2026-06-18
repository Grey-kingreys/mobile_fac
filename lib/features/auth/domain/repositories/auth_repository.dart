import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<void> logout();
  Future<UserEntity> getCurrentUser();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  });
  Future<UserEntity> firstLogin({
    required String token,
    required String password,
    required String passwordConfirm,
  });

  // ── 2FA ──────────────────────────────────────────────────────────────────

  /// Lance la configuration 2FA. Retourne {'qr_code', 'secret', 'message'} pour TOTP
  /// ou {'message'} pour email.
  Future<Map<String, dynamic>> setup2fa(String method);

  /// Confirme la configuration avec le code saisi.
  Future<void> verify2faSetup({required String method, required String code});

  /// Désactive la 2FA (mot de passe requis).
  Future<void> disable2fa(String password);

  /// Vérifie le code 2FA lors du login. Sauvegarde les JWT et retourne l'utilisateur.
  Future<UserEntity> loginVerify2fa({
    required String tempToken,
    required String code,
  });

  /// Renvoie le code par email (méthode email uniquement).
  Future<void> resend2faCode(String tempToken);
}

/// Exception levée quand le login nécessite une 2FA.
class TwoFactorRequiredException implements Exception {
  final String tempToken;
  final String method; // 'totp' ou 'email'
  final String? message;

  const TwoFactorRequiredException({
    required this.tempToken,
    required this.method,
    this.message,
  });

  @override
  String toString() => 'TwoFactorRequiredException(method: $method)';
}
