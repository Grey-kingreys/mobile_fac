import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';

// ─── État de simulation ──────────────────────────────────────────────────────

/// Snapshot de la session de simulation : qui simule → qui est simulé.
class SimulationState {
  final UserEntity realUser;
  final UserEntity simulatedUser;

  const SimulationState({
    required this.realUser,
    required this.simulatedUser,
  });
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class SimulationNotifier extends Notifier<SimulationState?> {
  @override
  SimulationState? build() {
    // Réinitialiser automatiquement à la déconnexion.
    ref.listen(authProvider, (_, next) {
      if (next.valueOrNull == null) state = null;
    });
    return null;
  }

  void start(UserEntity realUser, UserEntity target) {
    state = SimulationState(realUser: realUser, simulatedUser: target);
  }

  void stop() => state = null;
}

final simulationProvider = NotifierProvider<SimulationNotifier, SimulationState?>(
  SimulationNotifier.new,
);

// ─── Providers dérivés ───────────────────────────────────────────────────────

/// Utilisateur effectif : simulé si actif, sinon utilisateur réellement connecté.
final effectiveUserProvider = Provider<UserEntity?>((ref) {
  final sim = ref.watch(simulationProvider);
  return sim?.simulatedUser ?? ref.watch(authProvider).valueOrNull;
});

/// Toujours l'utilisateur réellement connecté (non influencé par la simulation).
final realUserProvider = Provider<UserEntity?>((ref) {
  final sim = ref.watch(simulationProvider);
  return sim?.realUser ?? ref.watch(authProvider).valueOrNull;
});

/// Rôle effectif (simulé ou réel).
/// Fail-safe : en l'absence de rôle connu, on retombe sur le périmètre le moins
/// privilégié (commercial — pas d'accès finance/caisse) plutôt qu'un rôle financier.
final effectiveRoleProvider = Provider<String>((ref) {
  return ref.watch(effectiveUserProvider)?.role ?? 'commercial';
});

final isSimulatingProvider = Provider<bool>((ref) {
  return ref.watch(simulationProvider) != null;
});

/// Vrai si le vrai utilisateur connecté peut activer la simulation (admin uniquement).
final canSimulateProvider = Provider<bool>((ref) {
  final real = ref.watch(realUserProvider);
  return real?.role == 'admin';
});

// ─── Chargement des utilisateurs pour le simulateur ─────────────────────────

/// Parse un JSON de l'endpoint /users/ vers un UserEntity.
UserEntity _userFromJson(Map<String, dynamic> json) => UserEntity(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      depotId: json['depot_id'] as int?,
      depotName: json['depot_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
    );

/// Liste des utilisateurs actifs chargée depuis l'API (lazy, auto-disposée).
/// Utilisée uniquement quand le panneau de simulation est ouvert.
final simulatorUsersProvider = FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>(
    ApiEndpoints.users,
    queryParameters: {'is_active': 'true', 'page_size': '100'},
  );
  final data = response.data ?? {};
  final results = data['results'] as List<dynamic>? ?? [];
  return results
      .map((e) => _userFromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Constantes UI partagées ─────────────────────────────────────────────────

const Map<String, String> roleLabels = {
  'superadmin': 'Super Admin',
  'admin': 'Admin',
  'superviseur': 'Superviseur',
  'gestionnaire_stock': 'Gest. Stock',
  'caissier': 'Caissier',
  'chauffeur': 'Chauffeur',
  'maintenancier': 'Maintenance',
  'commercial': 'Commercial',
};

const Map<String, Color> roleColors = {
  'superadmin': AppColors.primaryDark,
  'admin': AppColors.primary,
  'superviseur': AppColors.info,
  'gestionnaire_stock': AppColors.accent,
  'caissier': AppColors.secondary,
  'chauffeur': AppColors.orangeMoney,
  'maintenancier': AppColors.gray600,
  'commercial': AppColors.mtnMoney,
};
