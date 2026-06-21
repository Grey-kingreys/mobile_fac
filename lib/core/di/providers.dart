import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/storage/local_storage.dart';
import 'package:djoulagest_mobile/core/storage/secure_storage.dart';

// ─── Stockage ──────────────────────────────────────────────────────────────

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final localStorageProvider = FutureProvider<LocalStorageService>((ref) async {
  return LocalStorageService().init();
});

// ─── Réseau ────────────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiClient(storage, onLogout: () async {
    // Invalide isAuthenticatedProvider → le router redirige vers /login.
    // authProvider (features/auth) n'est pas importé ici pour éviter le
    // cycle — on invalide uniquement le provider de routing.
    ref.invalidate(isAuthenticatedProvider);
  });
});

// ─── Auth state (léger — vérifie juste la présence du token) ───────────────
// Le AuthNotifier complet est dans features/auth/presentation/providers/
// Ce provider sert uniquement au router pour le redirect initial.

final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final storage = ref.read(secureStorageProvider);
  // hasSession() : connecté tant qu'un refresh token valide existe (l'access
  // expiré sera rafraîchi au 1er 401) — évite la déconnexion toutes les 60 min.
  return storage.hasSession();
});

// ─── Onboarding ────────────────────────────────────────────────────────────
// true = l'utilisateur a déjà vu les écrans d'onboarding

final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_done') ?? false;
});
