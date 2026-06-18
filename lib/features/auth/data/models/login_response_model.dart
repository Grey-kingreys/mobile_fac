import 'package:djoulagest_mobile/features/auth/data/models/user_model.dart';

/// Résultat du login — soit une connexion directe, soit une 2FA en attente.
class LoginResult {
  final bool requiresTwoFactor;

  // Présents quand requiresTwoFactor = false
  final String? access;
  final String? refresh;
  final UserModel? user;

  // Présents quand requiresTwoFactor = true
  final String? tempToken;
  final String? method; // 'totp' ou 'email'
  final String? message;

  const LoginResult({
    required this.requiresTwoFactor,
    this.access,
    this.refresh,
    this.user,
    this.tempToken,
    this.method,
    this.message,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    if (data['requires_2fa'] == true) {
      return LoginResult(
        requiresTwoFactor: true,
        tempToken: data['temp_token'] as String?,
        method: data['method'] as String?,
        message: data['message'] as String?,
      );
    }

    return LoginResult(
      requiresTwoFactor: false,
      access: data['access'] as String,
      refresh: data['refresh'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}

/// Conservé pour compatibilité — utiliser LoginResult dans le nouveau code.
@Deprecated('Utiliser LoginResult')
class LoginResponseModel {
  final String access;
  final String refresh;
  final UserModel user;

  const LoginResponseModel({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return LoginResponseModel(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
