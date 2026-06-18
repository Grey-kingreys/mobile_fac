import 'package:djoulagest_mobile/core/storage/secure_storage.dart';
import 'package:djoulagest_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:djoulagest_mobile/features/auth/data/models/login_request_model.dart';
import 'package:djoulagest_mobile/features/auth/data/models/user_model.dart';
import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:djoulagest_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;
  final SecureStorageService _storage;

  const AuthRepositoryImpl(this._datasource, this._storage);

  @override
  Future<UserEntity> login(String email, String password) async {
    final result = await _datasource.login(
      LoginRequestModel(email: email, password: password),
    );
    if (result.requiresTwoFactor) {
      throw TwoFactorRequiredException(
        tempToken: result.tempToken!,
        method: result.method!,
        message: result.message,
      );
    }
    await _storage.saveTokens(access: result.access!, refresh: result.refresh!);
    return result.user!.toEntity();
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    try {
      await _datasource.logout(refreshToken: refreshToken);
    } finally {
      await _storage.clearTokens();
    }
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    final model = await _datasource.getCurrentUser();
    return model.toEntity();
  }

  @override
  Future<void> forgotPassword(String email) => _datasource.forgotPassword(email);

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  }) =>
      _datasource.resetPassword(
        token: token,
        newPassword: newPassword,
        newPasswordConfirm: newPasswordConfirm,
      );

  @override
  Future<UserEntity> firstLogin({
    required String token,
    required String password,
    required String passwordConfirm,
  }) async {
    final model = await _datasource.firstLogin(
      token: token,
      password: password,
      passwordConfirm: passwordConfirm,
    );
    return model.toEntity();
  }

  // ── 2FA ──────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> setup2fa(String method) =>
      _datasource.setup2fa(method);

  @override
  Future<void> verify2faSetup({required String method, required String code}) =>
      _datasource.verify2faSetup(method: method, code: code);

  @override
  Future<void> disable2fa(String password) =>
      _datasource.disable2fa(password);

  @override
  Future<UserEntity> loginVerify2fa({
    required String tempToken,
    required String code,
  }) async {
    final data = await _datasource.loginVerify2faFull(
      tempToken: tempToken,
      code: code,
    );
    // Sauvegarde des JWT
    final access = data['access'] as String?;
    final refresh = data['refresh'] as String?;
    if (access != null && refresh != null) {
      await _storage.saveTokens(access: access, refresh: refresh);
    }
    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson == null) throw Exception('Réponse invalide du serveur.');
    return UserModel.fromJson(userJson).toEntity();
  }

  @override
  Future<void> resend2faCode(String tempToken) =>
      _datasource.resend2faCode(tempToken);
}
