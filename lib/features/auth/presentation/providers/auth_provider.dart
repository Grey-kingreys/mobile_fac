import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:djoulagest_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:djoulagest_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:djoulagest_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:djoulagest_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:djoulagest_mobile/features/auth/domain/usecases/forgot_password_usecase.dart';

// ─── État 2FA en attente ──────────────────────────────────────────────────────

class TwoFactorPending {
  final String tempToken;
  final String method; // 'totp' ou 'email'
  final String? message;

  const TwoFactorPending({
    required this.tempToken,
    required this.method,
    this.message,
  });
}

final twoFactorPendingProvider = StateProvider<TwoFactorPending?>((ref) => null);

// ─── Dépendances ─────────────────────────────────────────────────────────────

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.read(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(authRemoteDatasourceProvider),
    ref.read(secureStorageProvider),
  );
});

// ─── Notifier principal ───────────────────────────────────────────────────────

final authProvider = AsyncNotifierProvider<AuthNotifier, UserEntity?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserEntity?> {
  late LoginUseCase _login;
  late LogoutUseCase _logout;
  late ForgotPasswordUseCase _forgotPassword;

  @override
  Future<UserEntity?> build() async {
    final repo = ref.read(authRepositoryProvider);
    _login = LoginUseCase(repo);
    _logout = LogoutUseCase(repo);
    _forgotPassword = ForgotPasswordUseCase(repo);

    final storage = ref.read(secureStorageProvider);
    final hasToken = await storage.hasValidToken();
    if (!hasToken) return null;

    try {
      return await repo.getCurrentUser();
    } catch (_) {
      await storage.clearTokens();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _login(email, password);
      state = AsyncData(user);
      ref.invalidate(isAuthenticatedProvider);
    } on TwoFactorRequiredException catch (e) {
      // Stocker l'état 2FA en attente — le router redirige vers /two-factor
      ref.read(twoFactorPendingProvider.notifier).state = TwoFactorPending(
        tempToken: e.tempToken,
        method: e.method,
        message: e.message,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Vérifie le code 2FA lors du login. Retourne null si succès, message d'erreur sinon.
  Future<String?> verify2faLogin({required String code}) async {
    final pending = ref.read(twoFactorPendingProvider);
    if (pending == null) return 'Session 2FA expirée. Reconnectez-vous.';

    try {
      final user = await ref.read(authRepositoryProvider).loginVerify2fa(
        tempToken: pending.tempToken,
        code: code,
      );
      ref.read(twoFactorPendingProvider.notifier).state = null;
      state = AsyncData(user);
      ref.invalidate(isAuthenticatedProvider);
      return null;
    } catch (e) {
      return _extractMessage(e);
    }
  }

  /// Renvoie le code 2FA par email.
  Future<String?> resend2faCode() async {
    final pending = ref.read(twoFactorPendingProvider);
    if (pending == null) return 'Session expirée.';
    try {
      await ref.read(authRepositoryProvider).resend2faCode(pending.tempToken);
      return null;
    } catch (e) {
      return _extractMessage(e);
    }
  }

  /// Initie la configuration 2FA depuis le profil.
  Future<({String? error, Map<String, dynamic>? data})> setup2fa(
      String method) async {
    try {
      final data =
          await ref.read(authRepositoryProvider).setup2fa(method);
      return (error: null, data: data);
    } catch (e) {
      return (error: _extractMessage(e), data: null);
    }
  }

  /// Confirme la configuration 2FA avec le code.
  Future<String?> verify2faSetup({
    required String method,
    required String code,
  }) async {
    try {
      await ref
          .read(authRepositoryProvider)
          .verify2faSetup(method: method, code: code);
      // Recharger le profil pour mettre à jour two_factor_enabled
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      state = AsyncData(user);
      ref.invalidate(isAuthenticatedProvider);
      return null;
    } catch (e) {
      return _extractMessage(e);
    }
  }

  /// Désactive la 2FA.
  Future<String?> disable2fa(String password) async {
    try {
      await ref.read(authRepositoryProvider).disable2fa(password);
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      state = AsyncData(user);
      return null;
    } catch (e) {
      return _extractMessage(e);
    }
  }

  Future<void> logout() async {
    try {
      await _logout();
    } catch (_) {}
    ref.read(twoFactorPendingProvider.notifier).state = null;
    state = const AsyncData(null);
    ref.invalidate(isAuthenticatedProvider);
  }

  Future<void> forgotPassword(String email) async {
    await _forgotPassword(email);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.resetPassword(
      token: token,
      newPassword: newPassword,
      newPasswordConfirm: newPasswordConfirm,
    );
  }

  Future<void> firstLogin({
    required String token,
    required String password,
    required String passwordConfirm,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.firstLogin(
      token: token,
      password: password,
      passwordConfirm: passwordConfirm,
    );
  }

  UserEntity? get currentUser => state.valueOrNull;
  bool get isLoggedIn => state.valueOrNull != null;

  String _extractMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('400') || msg.contains('invalide') || msg.contains('invalid')) {
      return 'Code invalide. Vérifiez et réessayez.';
    }
    if (msg.contains('401') || msg.contains('expiré') || msg.contains('expired')) {
      return 'Session expirée. Reconnectez-vous.';
    }
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Erreur réseau. Vérifiez votre connexion.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }
}
