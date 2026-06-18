import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/auth/data/models/login_request_model.dart';
import 'package:djoulagest_mobile/features/auth/data/models/login_response_model.dart';
import 'package:djoulagest_mobile/features/auth/data/models/user_model.dart';

class AuthRemoteDatasource {
  final ApiClient _client;
  const AuthRemoteDatasource(this._client);

  Future<LoginResult> login(LoginRequestModel request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: request.toJson(),
    );
    return LoginResult.fromJson(response.data!);
  }

  Future<void> logout({String? refreshToken}) async {
    await _client.post<void>(
      ApiEndpoints.logout,
      data: refreshToken != null ? {'refresh': refreshToken} : null,
    );
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _client.get<Map<String, dynamic>>(ApiEndpoints.me);
    final data = response.data!;
    if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
      return UserModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    return UserModel.fromJson(data);
  }

  Future<void> forgotPassword(String email) async {
    await _client.post<void>(
      ApiEndpoints.passwordReset,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await _client.post<void>(
      ApiEndpoints.passwordResetConfirm,
      data: {
        'token': token,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      },
    );
  }

  Future<UserModel> firstLogin({
    required String token,
    required String password,
    required String passwordConfirm,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.firstLogin,
      data: {
        'token': token,
        'password': password,
        'password_confirm': passwordConfirm,
      },
    );
    final data = response.data!;
    final userData = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;
    return UserModel.fromJson(userData['user'] as Map<String, dynamic>? ?? userData);
  }

  // ── 2FA — Configuration (utilisateur connecté) ───────────────────────────

  /// Initie la configuration 2FA. Retourne QR code (TOTP) ou confirme l'envoi email.
  Future<Map<String, dynamic>> setup2fa(String method) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.twoFaSetup,
      data: {'method': method},
    );
    return response.data ?? {};
  }

  /// Confirme la configuration 2FA avec le code saisi.
  Future<void> verify2faSetup({
    required String method,
    required String code,
  }) async {
    await _client.post<void>(
      ApiEndpoints.twoFaSetupVerify,
      data: {'method': method, 'code': code},
    );
  }

  /// Désactive la 2FA (mot de passe requis).
  Future<void> disable2fa(String password) async {
    await _client.post<void>(
      ApiEndpoints.twoFaDisable,
      data: {'password': password},
    );
  }

  // ── 2FA — Vérification lors du login (AllowAny) ──────────────────────────

  /// Vérifie le code 2FA pendant le login. Retourne les tokens JWT.
  Future<UserModel> loginVerify2fa({
    required String tempToken,
    required String code,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.twoFaLoginVerify,
      data: {'temp_token': tempToken, 'code': code},
    );
    final data = response.data ?? {};
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Récupère aussi les tokens après vérification 2FA (pour les sauvegarder).
  Future<Map<String, dynamic>> loginVerify2faFull({
    required String tempToken,
    required String code,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.twoFaLoginVerify,
      data: {'temp_token': tempToken, 'code': code},
    );
    return response.data ?? {};
  }

  /// Renvoie un code par email (méthode email uniquement).
  Future<void> resend2faCode(String tempToken) async {
    await _client.post<void>(
      ApiEndpoints.twoFaResend,
      data: {'temp_token': tempToken},
    );
  }
}
