import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/errors/app_exception.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/depots/presentation/providers/depots_provider.dart';
import 'package:djoulagest_mobile/features/zones/presentation/providers/zones_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

// ─── Helpers erreurs API ──────────────────────────────────────────────────────

String _apiError(dynamic e) {
  if (e is DioException && e.error is AppException) {
    final ex = e.error as AppException;
    if (ex is ValidationException && ex.fieldErrors.isNotEmpty) {
      final entry = ex.fieldErrors.entries.first;
      return '${_fieldLabel(entry.key)} : ${entry.value.first}';
    }
    return ex.message;
  }
  return e.toString();
}

String _fieldLabel(String key) => switch (key) {
      'email' => 'Email',
      'password' => 'Mot de passe',
      'zone_id' => 'Zone',
      'depot_id' => 'Dépôt',
      'role' => 'Rôle',
      'first_name' => 'Prénom',
      'last_name' => 'Nom',
      'phone' => 'Téléphone',
      'is_active' => 'Statut',
      _ => key,
    };

// ─── Constantes rôles ─────────────────────────────────────────────────────────

const _roleLabels = {
  'superadmin': 'Super Admin',
  'admin': 'Admin',
  'superviseur': 'Superviseur',
  'gestionnaire_stock': 'Gest. Stock',
  'caissier': 'Caissier',
  'chauffeur': 'Chauffeur',
  'maintenancier': 'Maintenancier',
  'commercial': 'Commercial',
};

Color _roleColor(String role) => switch (role) {
      'superadmin' => AppColors.danger,
      'admin' => AppColors.primary,
      'superviseur' => const Color(0xFF7C3AED),
      'gestionnaire_stock' => AppColors.secondary,
      'caissier' => AppColors.accent,
      'chauffeur' => AppColors.gray500,
      'maintenancier' => AppColors.orangeMoney,
      'commercial' => const Color(0xFF0891B2),
      _ => AppColors.gray400,
    };

// ─── Entité locale ────────────────────────────────────────────────────────────

class _UserItem {
  const _UserItem({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.phone,
    this.depotId,
    this.depotName,
    this.zoneId,
    this.zoneName,
  });

  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final bool isActive;
  final int? depotId;
  final String? depotName;
  final int? zoneId;
  final String? zoneName;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  factory _UserItem.fromJson(Map<String, dynamic> j) {
    return _UserItem(
      id: j['id'] as int,
      email: j['email'] as String? ?? '',
      fullName: j['full_name'] as String? ??
          '${j['first_name'] ?? ''} ${j['last_name'] ?? ''}'.trim(),
      phone: j['phone'] as String?,
      role: j['role'] as String? ?? '',
      isActive: j['is_active'] as bool? ?? true,
      depotId: j['depot_id'] as int?,
      depotName: j['depot_name'] as String?,
      zoneId: j['zone_id'] as int?,
      zoneName: j['zone_name'] as String?,
    );
  }
}

// ─── State ────────────────────────────────────────────────────────────────────

class _UsersState {
  const _UsersState({
    this.users = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.isLoadingMore = false,
  });

  final List<_UserItem> users;
  final int total;
  final int page;
  final String search;
  final bool isLoadingMore;

  bool get hasMore => users.length < total;

  _UsersState copyWith({
    List<_UserItem>? users,
    int? total,
    int? page,
    String? search,
    bool? isLoadingMore,
  }) {
    return _UsersState(
      users: users ?? this.users,
      total: total ?? this.total,
      page: page ?? this.page,
      search: search ?? this.search,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class _UsersNotifier extends AsyncNotifier<_UsersState> {
  static const _pageSize = 25;

  @override
  Future<_UsersState> build() => _fetch(page: 1, search: '');

  Future<_UsersState> _fetch({required int page, required String search}) async {
    final api = ref.read(apiClientProvider);
    final params = <String, dynamic>{
      'page': page,
      'page_size': _pageSize,
      if (search.isNotEmpty) 'search': search,
    };
    final res = await api.get<Map<String, dynamic>>(
      ApiEndpoints.users,
      queryParameters: params,
    );
    final data = res.data ?? {};
    final count = data['count'] as int? ?? 0;
    final raw = (data['results'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final prev = page > 1 ? (state.valueOrNull?.users ?? []) : <_UserItem>[];
    return _UsersState(
      users: [...prev, ...raw.map(_UserItem.fromJson)],
      total: count,
      page: page,
      search: search,
    );
  }

  Future<void> refresh() async {
    final search = state.valueOrNull?.search ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, search: search));
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, search: query));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get<Map<String, dynamic>>(
        ApiEndpoints.users,
        queryParameters: {
          'page': current.page + 1,
          'page_size': _pageSize,
          if (current.search.isNotEmpty) 'search': current.search,
        },
      );
      final data = res.data ?? {};
      final raw = (data['results'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      state = AsyncData(current.copyWith(
        users: [...current.users, ...raw.map(_UserItem.fromJson)],
        total: data['count'] as int? ?? current.total,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<String?> updateUser(int id, Map<String, dynamic> body) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch<Map<String, dynamic>>(ApiEndpoints.userDetail(id), data: body);
      await refresh();
      return null;
    } catch (e) {
      return _apiError(e);
    }
  }

  /// Désactivation (soft) — DELETE /users/{id}/ → is_active=False.
  Future<String?> deleteUser(int id) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete<void>(ApiEndpoints.userDetail(id));
      await refresh();
      return null;
    } catch (e) {
      return _apiError(e);
    }
  }

  /// Suppression — DELETE /users/{id}/supprimer/ → purge réelle si aucun
  /// historique, sinon archivage (tombstone). Dans les deux cas l'utilisateur
  /// disparaît des listes.
  ///
  /// Retourne : `error` (message si échec), `archived` (true = archivé/historique
  /// conservé, false = supprimé physiquement), `message` (détail renvoyé par le backend).
  Future<({String? error, bool archived, String? message})> purgeUser(int id) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.delete<Map<String, dynamic>>(
        ApiEndpoints.userSupprimer(id),
      );
      await refresh();
      final data = res.data ?? const {};
      return (
        error: null,
        archived: data['archived'] == true,
        message: data['detail'] as String?,
      );
    } catch (e) {
      // La route /supprimer/ n'est pas encore déployée → 404. Message clair en
      // attendant la mise à jour du serveur (la désactivation, elle, fonctionne).
      if (e is DioException && e.response?.statusCode == 404) {
        return (
          error: 'La suppression sera disponible après la mise à jour du serveur. '
              'En attendant, vous pouvez désactiver le compte.',
          archived: false,
          message: null,
        );
      }
      return (error: _apiError(e), archived: false, message: null);
    }
  }
}

final _usersProvider =
    AsyncNotifierProvider<_UsersNotifier, _UsersState>(_UsersNotifier.new);

// ─── Écran principal ──────────────────────────────────────────────────────────

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  static const _canCreate = ['admin'];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(_usersProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(_usersProvider.notifier).search(query);
    });
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateUserSheet(
        onCreated: () => ref.read(_usersProvider.notifier).refresh(),
      ),
    );
  }

  void _showDetail(BuildContext ctx, _UserItem user) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(
        user: user,
        onRefresh: () => ref.read(_usersProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(_usersProvider);
    final role = ref.watch(effectiveRoleProvider);
    final canCreate = _canCreate.contains(role);

    return AppScaffold(
      title: 'Employés',
      showBottomNav: true,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _showCreateSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Créer un employé'),
            )
          : null,
      body: Column(
        children: [
          // Recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, AppSizes.md, AppSizes.paddingPage, AppSizes.sm),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher un employé…',
                hintStyle: const TextStyle(
                    color: AppColors.gray400, fontSize: AppSizes.fontSm),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.gray400, size: AppSizes.iconMd),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: AppSizes.iconSm),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(_usersProvider.notifier).search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(color: AppColors.gray200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(color: AppColors.gray200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ),

          // Compteur
          if (asyncState.valueOrNull != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingPage),
              child: Row(
                children: [
                  Text(
                    '${asyncState.value!.total} employé(s)',
                    style: const TextStyle(
                        fontSize: AppSizes.fontXs, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSizes.xs),

          // Liste
          Expanded(
            child: asyncState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    Text(_apiError(e),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(_usersProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: AppSizes.iconXxl, color: AppColors.gray200),
                        SizedBox(height: AppSizes.md),
                        Text('Aucun employé trouvé',
                            style: TextStyle(color: AppColors.gray500)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(_usersProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingPage, 0, AppSizes.paddingPage, AppSizes.xxl),
                    itemCount: state.users.length +
                        (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (ctx, i) {
                      if (i == state.users.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _UserTile(
                        user: state.users[i],
                        onTap: () => _showDetail(context, state.users[i]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tuile utilisateur ────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});
  final _UserItem user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);
    final roleLabel = _roleLabels[user.role] ?? user.role;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar initiales
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(
                  user.initials,
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: AppSizes.fontSm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName : user.email,
                          style: const TextStyle(
                            fontSize: AppSizes.fontSm,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Badge rôle
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          border: Border.all(
                              color: roleColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          size: 11, color: AppColors.gray400),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          user.email,
                          style: const TextStyle(
                              fontSize: AppSizes.fontXs,
                              color: AppColors.gray400),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.depotName != null) ...[
                        const SizedBox(width: AppSizes.sm),
                        const Icon(Icons.warehouse_outlined,
                            size: 11, color: AppColors.gray400),
                        const SizedBox(width: 3),
                        Text(
                          user.depotName!,
                          style: const TextStyle(
                              fontSize: AppSizes.fontXs,
                              color: AppColors.gray400),
                        ),
                      ] else if (user.zoneName != null) ...[
                        const SizedBox(width: AppSizes.sm),
                        const Icon(Icons.map_outlined,
                            size: 11, color: AppColors.gray400),
                        const SizedBox(width: 3),
                        Text(
                          user.zoneName!,
                          style: const TextStyle(
                              fontSize: AppSizes.fontXs,
                              color: AppColors.gray400),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Chevron + badge actif
            const SizedBox(width: AppSizes.xs),
            Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: user.isActive ? AppColors.secondary : AppColors.gray300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.gray300),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fiche détail employé ─────────────────────────────────────────────────────

class _UserDetailSheet extends ConsumerWidget {
  const _UserDetailSheet({required this.user, required this.onRefresh});
  final _UserItem user;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(effectiveRoleProvider);
    final isAdmin = currentRole == 'admin';
    final roleColor = _roleColor(user.role);
    final roleLabel = _roleLabels[user.role] ?? user.role;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.sm, bottom: AppSizes.xs),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),

            // Avatar + nom + rôle
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.md),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.initials,
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 26,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: user.isActive
                              ? AppColors.secondary
                              : AppColors.gray300,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    user.fullName.isNotEmpty ? user.fullName : user.email,
                    style: const TextStyle(
                      fontSize: AppSizes.fontXl,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                      border:
                          Border.all(color: roleColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: AppSizes.fontXs,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    user.isActive ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: user.isActive ? AppColors.secondary : AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.gray100),

            // Lignes d'info
            _InfoRow(Icons.email_outlined, 'Email', user.email),
            if (user.phone != null && user.phone!.isNotEmpty)
              _InfoRow(Icons.phone_outlined, 'Téléphone', user.phone!),
            if (user.zoneName != null)
              _InfoRow(Icons.map_outlined, 'Zone', user.zoneName!),
            if (user.depotName != null)
              _InfoRow(Icons.warehouse_outlined, 'Dépôt', user.depotName!),

            // Boutons admin
            if (isAdmin) ...[
              const Divider(height: 1, color: AppColors.gray100),
              Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _EditUserSheet(
                              user: user,
                              onSaved: onRefresh,
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Modifier'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: user.isActive
                          ? OutlinedButton.icon(
                              onPressed: () => _confirmDeactivate(context, ref),
                              icon: const Icon(Icons.block_rounded, size: 18),
                              label: const Text('Désactiver'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: () => _reactivate(context, ref),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: const Text('Réactiver'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                                side: const BorderSide(color: AppColors.secondary),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                    ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _confirmPurge(context, ref),
                        icon: const Icon(Icons.delete_forever_outlined, size: 18),
                        label: const Text('Supprimer'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver ce compte ?'),
        content: Text(
          '${user.fullName.isNotEmpty ? user.fullName : user.email} ne pourra plus se connecter. '
          'Ses données et son historique sont conservés, et vous pourrez le réactiver à tout moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    final error = await ref.read(_usersProvider.notifier).deleteUser(user.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Compte désactivé.'),
        backgroundColor: error != null ? AppColors.danger : AppColors.secondary,
      ),
    );
  }

  Future<void> _reactivate(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    final error = await ref
        .read(_usersProvider.notifier)
        .updateUser(user.id, {'is_active': true});
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Compte réactivé.'),
        backgroundColor: error != null ? AppColors.danger : AppColors.secondary,
      ),
    );
  }

  Future<void> _confirmPurge(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce compte ?'),
        content: Text(
          '${user.fullName.isNotEmpty ? user.fullName : user.email} disparaîtra de la liste. '
          "S'il a déjà effectué des opérations, son nom et son email restent visibles "
          "dans l'historique (traçabilité) ; sinon le compte est supprimé définitivement.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    final result = await ref.read(_usersProvider.notifier).purgeUser(user.id);

    final String message;
    if (result.error != null) {
      message = result.error!;
    } else if (result.message != null && result.message!.isNotEmpty) {
      // Détail renvoyé par le backend (déjà adapté : supprimé / archivé).
      message = result.message!;
    } else if (result.archived) {
      message = 'Utilisateur supprimé — historique (nom et email) conservé.';
    } else {
      message = 'Utilisateur supprimé définitivement.';
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result.error != null ? AppColors.danger : AppColors.secondary,
        duration: result.error == null && result.archived
            ? const Duration(seconds: 5)
            : const Duration(seconds: 4),
      ),
    );
  }
}

// Ligne d'info réutilisable dans la fiche
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg, vertical: AppSizes.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gray400),
          const SizedBox(width: AppSizes.sm),
          Text(
            '$label :',
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSizes.xs),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.gray900,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulaire édition employé ───────────────────────────────────────────────

class _EditUserSheet extends ConsumerStatefulWidget {
  const _EditUserSheet({required this.user, required this.onSaved});
  final _UserItem user;
  final VoidCallback onSaved;

  @override
  ConsumerState<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends ConsumerState<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _nomCtrl;
  late final TextEditingController _telCtrl;

  late String _selectedRole;
  late bool _isActive;
  int? _selectedDepotId;
  int? _selectedZoneId;
  bool _isSaving = false;

  bool get _isSuperviseur => _selectedRole == 'superviseur';

  /// Rôles opérationnels obligatoirement rattachés à un dépôt (CDC §0).
  static const _depotRoles = {
    'caissier',
    'commercial',
    'chauffeur',
    'gestionnaire_stock',
    'maintenancier',
  };

  bool get _needsDepot => !_isSuperviseur && _depotRoles.contains(_selectedRole);

  static const _roles = [
    ('admin', 'Administrateur'),
    ('superviseur', 'Superviseur'),
    ('gestionnaire_stock', 'Gestionnaire de Stock'),
    ('caissier', 'Caissier'),
    ('chauffeur', 'Chauffeur'),
    ('maintenancier', 'Maintenancier'),
    ('commercial', 'Commercial'),
  ];

  @override
  void initState() {
    super.initState();
    final parts = widget.user.fullName.trim().split(RegExp(r'\s+'));
    _prenomCtrl = TextEditingController(
        text: parts.isNotEmpty ? parts.first : '');
    _nomCtrl = TextEditingController(
        text: parts.length > 1 ? parts.skip(1).join(' ') : '');
    _telCtrl = TextEditingController(text: widget.user.phone ?? '');
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
    _selectedDepotId = widget.user.depotId;
    _selectedZoneId = widget.user.zoneId;
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final body = <String, dynamic>{
      'first_name': _prenomCtrl.text.trim(),
      'last_name': _nomCtrl.text.trim(),
      'role': _selectedRole,
      'is_active': _isActive,
      if (_telCtrl.text.isNotEmpty) 'phone': _telCtrl.text.trim()
      else 'phone': null,
      if (_isSuperviseur && _selectedZoneId != null)
        'zone_id': _selectedZoneId
      else if (!_isSuperviseur && _selectedDepotId != null)
        'depot_id': _selectedDepotId
      else if (!_isSuperviseur)
        'depot_id': null,
    };

    final error = await ref.read(_usersProvider.notifier).updateUser(
          widget.user.id,
          body,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    } else {
      Navigator.of(context).pop();
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employé modifié avec succès'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final depotsAsync = ref.watch(depotsProvider);
    final depots = depotsAsync.valueOrNull?.depots ?? [];
    final zonesAsync = ref.watch(zonesProvider);
    final zones = zonesAsync.valueOrNull?.zones ?? [];
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Modifier ${widget.user.fullName.isNotEmpty ? widget.user.fullName : widget.user.email}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                // Statut actif/inactif
                SwitchListTile.adaptive(
                  value: _isActive,
                  onChanged: _isSaving ? null : (v) => setState(() => _isActive = v),
                  title: const Text('Compte actif',
                      style: TextStyle(
                          fontSize: AppSizes.fontSm, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    _isActive
                        ? 'L\'employé peut se connecter'
                        : 'Accès bloqué',
                    style: TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: _isActive ? AppColors.secondary : AppColors.danger),
                  ),
                  activeTrackColor: AppColors.secondary,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 1, color: AppColors.gray100),
                const SizedBox(height: AppSizes.sm),

                // Prénom + Nom
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prenomCtrl,
                        enabled: !_isSaving,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Prénom *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _nomCtrl,
                        enabled: !_isSaving,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),

                // Téléphone
                TextFormField(
                  controller: _telCtrl,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),

                // Rôle
                const Text(
                  'Rôle *',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: _roleColor(_selectedRole),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.sm),
                  ),
                  items: _roles
                      .map((r) => DropdownMenuItem(
                            value: r.$1,
                            child: Text(r.$2),
                          ))
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (v) {
                          if (v != null) {
                            setState(() {
                              _selectedRole = v;
                              // Réinitialiser l'affectation si le rôle change de superviseur ↔ autre
                              if (v == 'superviseur') {
                                _selectedDepotId = null;
                              } else {
                                _selectedZoneId = null;
                              }
                            });
                          }
                        },
                ),
                const SizedBox(height: AppSizes.sm),

                // Affectation conditionnelle
                if (_isSuperviseur) ...[
                  const Text(
                    'Zone de supervision *',
                    style: TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedZoneId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      prefixIcon: const Icon(Icons.map_outlined,
                          color: Color(0xFF7C3AED)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.sm),
                    ),
                    hint: const Text('Sélectionner une zone',
                        style: TextStyle(color: AppColors.gray400)),
                    items: zones
                        .map((z) => DropdownMenuItem<int?>(
                              value: z.id,
                              child: Text(z.name,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (v) => setState(() => _selectedZoneId = v),
                    validator: (v) => v == null
                        ? 'La zone est obligatoire pour un superviseur'
                        : null,
                  ),
                ] else ...[
                  const Text(
                    'Dépôt',
                    style: TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedDepotId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      prefixIcon: const Icon(Icons.warehouse_outlined,
                          color: AppColors.gray400),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.sm),
                    ),
                    items: [
                      if (!_needsDepot)
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Aucun dépôt',
                              style: TextStyle(color: AppColors.gray400)),
                        ),
                      ...depots.map((d) => DropdownMenuItem<int?>(
                            value: d.id,
                            child: Text(d.nom,
                                overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    validator: (v) => (_needsDepot && v == null)
                        ? 'Le dépôt est obligatoire pour ce rôle'
                        : null,
                    onChanged: _isSaving
                        ? null
                        : (v) => setState(() => _selectedDepotId = v),
                  ),
                ],
                const SizedBox(height: AppSizes.xl),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSizes.md),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Formulaire création utilisateur/employé ──────────────────────────────────

class _CreateUserSheet extends ConsumerStatefulWidget {
  const _CreateUserSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = 'commercial';
  int? _selectedDepotId;
  int? _selectedZoneId;
  bool _obscurePassword = true;
  bool _isSaving = false;

  bool get _isSuperviseur => _selectedRole == 'superviseur';

  /// Rôles opérationnels obligatoirement rattachés à un dépôt (CDC §0).
  static const _depotRoles = {
    'caissier',
    'commercial',
    'chauffeur',
    'gestionnaire_stock',
    'maintenancier',
  };

  bool get _needsDepot => !_isSuperviseur && _depotRoles.contains(_selectedRole);

  static const _roles = [
    ('admin', 'Administrateur'),
    ('superviseur', 'Superviseur'),
    ('gestionnaire_stock', 'Gestionnaire de Stock'),
    ('caissier', 'Caissier'),
    ('chauffeur', 'Chauffeur'),
    ('maintenancier', 'Maintenancier'),
    ('commercial', 'Commercial'),
  ];

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.users,
        data: {
          'first_name': _prenomCtrl.text.trim(),
          'last_name': _nomCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'role': _selectedRole,
          'password': _passwordCtrl.text,
          if (_telCtrl.text.isNotEmpty) 'phone': _telCtrl.text.trim(),
          if (_isSuperviseur && _selectedZoneId != null)
            'zone_id': _selectedZoneId
          else if (!_isSuperviseur)
            'depot_id': _selectedDepotId,
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employé créé avec succès'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_apiError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final depotsAsync = ref.watch(depotsProvider);
    final depots = depotsAsync.valueOrNull?.depots ?? [];
    final zonesAsync = ref.watch(zonesProvider);
    final zones = zonesAsync.valueOrNull?.zones ?? [];
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    const Text(
                      'Créer un employé',
                      style: TextStyle(
                        fontSize: AppSizes.fontLg,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                // Prénom + Nom
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prenomCtrl,
                        enabled: !_isSaving,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Prénom *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _nomCtrl,
                        enabled: !_isSaving,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.sm),

                // Téléphone
                TextFormField(
                  controller: _telCtrl,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),

                // Rôle
                const Text(
                  'Rôle *',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: _roleColor(_selectedRole),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.sm),
                  ),
                  items: _roles
                      .map((r) => DropdownMenuItem(
                            value: r.$1,
                            child: Text(r.$2),
                          ))
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _selectedRole = v);
                        },
                ),
                const SizedBox(height: AppSizes.sm),

                // Affectation conditionnelle
                if (_isSuperviseur) ...[
                  const Text(
                    'Zone de supervision *',
                    style: TextStyle(
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedZoneId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      prefixIcon: const Icon(Icons.map_outlined,
                          color: Color(0xFF7C3AED)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.sm),
                    ),
                    hint: const Text('Sélectionner une zone',
                        style: TextStyle(color: AppColors.gray400)),
                    items: zones
                        .map((z) => DropdownMenuItem<int?>(
                              value: z.id,
                              child: Text(z.name,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (v) => setState(() => _selectedZoneId = v),
                    validator: (v) => v == null
                        ? 'La zone est obligatoire pour un superviseur'
                        : null,
                  ),
                ] else ...[
                  const Text(
                    'Dépôt',
                    style: TextStyle(
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedDepotId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      prefixIcon: const Icon(Icons.warehouse_outlined,
                          color: AppColors.gray400),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.sm),
                    ),
                    items: [
                      if (!_needsDepot)
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Aucun dépôt',
                              style: TextStyle(color: AppColors.gray400)),
                        ),
                      ...depots.map((d) => DropdownMenuItem<int?>(
                            value: d.id,
                            child: Text(
                              d.nom,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    validator: (v) => (_needsDepot && v == null)
                        ? 'Le dépôt est obligatoire pour ce rôle'
                        : null,
                    onChanged: _isSaving
                        ? null
                        : (v) => setState(() => _selectedDepotId = v),
                  ),
                ],
                const SizedBox(height: AppSizes.sm),

                // Mot de passe temporaire
                TextFormField(
                  controller: _passwordCtrl,
                  enabled: !_isSaving,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe temporaire *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    helperText:
                        'L\'employé devra le changer à la première connexion',
                    helperStyle: const TextStyle(
                        fontSize: AppSizes.fontXs, color: AppColors.gray400),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v.length < 8) return 'Min. 8 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.xl),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.person_add_rounded),
                    label: const Text('Créer l\'employé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSizes.md),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
