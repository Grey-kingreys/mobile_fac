import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/core/services/connectivity_service.dart';
import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_drawer.dart';
import 'package:djoulagest_mobile/shared/layout/bottom_nav_bar.dart';

/// Shell principal de l'application protégée.
///
/// - AppBar : hamburger + titre + bouton simulation (admin/superadmin uniquement) + cloche.
/// - Profil/rôle : uniquement dans le drawer (une seule fois).
/// - Bannière ambre : affichée en haut du body quand une simulation est active.
class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBottomNav = true,
    this.floatingActionButton,
    this.additionalActions = const [],
  });

  final String title;
  final Widget body;
  final bool showBottomNav;
  final Widget? floatingActionButton;
  final List<Widget> additionalActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSimulating = ref.watch(isSimulatingProvider);
    final canSimulate = ref.watch(canSimulateProvider);
    final effectiveUser = ref.watch(effectiveUserProvider);
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.gray200,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.gray700),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.gray900,
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.fontLg,
          ),
        ),
        actions: [
          // Bouton de simulation — visible uniquement pour admin et superadmin.
          if (canSimulate)
            IconButton(
              icon: Icon(
                isSimulating
                    ? Icons.manage_accounts
                    : Icons.manage_accounts_outlined,
                color: isSimulating ? AppColors.accent : AppColors.gray500,
              ),
              tooltip: isSimulating ? 'Simulation active' : 'Simuler un utilisateur',
              onPressed: () => _showUserPicker(context),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.gray500,
            tooltip: 'Notifications',
            onPressed: () => context.go(AppRoutes.notifications),
          ),
          if (additionalActions.isNotEmpty) ...[
            const SizedBox(width: AppSizes.xs),
            ...additionalActions,
          ],
          const SizedBox(width: AppSizes.xs),
        ],
      ),
      drawer: AppDrawer(currentLocation: location),
      body: Column(
        children: [
          // Bannière rouge "Hors ligne" quand pas de connectivité.
          ref.watch(isOnlineProvider).when(
            data: (online) => online
                ? const SizedBox.shrink()
                : const _OfflineBanner(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Bannière ambre affichée quand une simulation est active.
          if (isSimulating && effectiveUser != null)
            _SimulationBanner(
              simulatedUser: effectiveUser,
              onStop: () {
                ref.read(simulationProvider.notifier).stop();
                context.go(AppRoutes.dashboard);
              },
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: showBottomNav
          ? AppBottomNavBar(currentLocation: location)
          : null,
      floatingActionButton: floatingActionButton,
    );
  }

  void _showUserPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (_) => const _UserPickerSheet(),
    );
  }
}

// ─── Bannière de simulation ──────────────────────────────────────────────────

class _SimulationBanner extends StatelessWidget {
  const _SimulationBanner({
    required this.simulatedUser,
    required this.onStop,
  });

  final UserEntity simulatedUser;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final roleLabel = roleLabels[simulatedUser.role] ?? simulatedUser.role;
    return Material(
      color: AppColors.accent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: 6,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.manage_accounts_rounded,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Simulation · ${simulatedUser.fullName} ($roleLabel)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppSizes.fontXs,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onStop,
                child: const Text(
                  'Arrêter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppSizes.fontXs,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bannière hors ligne ─────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.danger,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Hors ligne — vérifiez votre connexion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppSizes.fontXs,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Picker d'utilisateurs (bottom sheet) ───────────────────────────────────

class _UserPickerSheet extends ConsumerWidget {
  const _UserPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(simulatorUsersProvider);
    final realUser = ref.watch(realUserProvider);
    final effectiveUser = ref.watch(effectiveUserProvider);
    final isSimulating = ref.watch(isSimulatingProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle + header — non scrollable
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md,
                AppSizes.md,
                AppSizes.md,
                0,
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.gray300,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                    ),
                  ),
                  // Titre
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.xs),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: const Icon(
                          Icons.manage_accounts_rounded,
                          color: AppColors.accent,
                          size: AppSizes.iconMd,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Simuler un utilisateur',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: AppSizes.fontLg,
                              color: AppColors.gray900,
                            ),
                          ),
                          Text(
                            'Naviguez à la place d\'un membre de l\'équipe',
                            style: TextStyle(
                              fontSize: AppSizes.fontXs,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  const Divider(),
                ],
              ),
            ),

            // Liste scrollable
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.xl),
                    child: Text(
                      'Impossible de charger les utilisateurs',
                      style: const TextStyle(color: AppColors.gray500),
                    ),
                  ),
                ),
                data: (users) {
                  // Exclure le user réellement connecté de la liste
                  final others = users
                      .where((u) => u.id != realUser?.id)
                      .toList();

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(
                      top: AppSizes.xs,
                      bottom: AppSizes.lg,
                    ),
                    children: [
                      // Bouton "Revenir à mon compte" affiché si simulation active
                      if (isSimulating) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: 1,
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            tileColor: AppColors.primary.withValues(alpha: 0.06),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                realUser?.initials ?? '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              realUser?.fullName ?? '',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: AppSizes.fontSm,
                              ),
                            ),
                            subtitle: const Text(
                              'Revenir à mon compte',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: AppSizes.fontXs,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.logout_rounded,
                              color: AppColors.primary,
                              size: AppSizes.iconMd,
                            ),
                            onTap: () {
                              ref.read(simulationProvider.notifier).stop();
                              Navigator.of(context).pop();
                              context.go(AppRoutes.dashboard);
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.xs,
                          ),
                          child: Divider(),
                        ),
                      ],

                      // Liste des membres de l'équipe
                      if (others.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSizes.xl),
                          child: Center(
                            child: Text(
                              'Aucun autre utilisateur dans l\'équipe',
                              style: TextStyle(color: AppColors.gray400),
                            ),
                          ),
                        )
                      else
                        ...others.map((user) {
                          final isSelected = user.id == effectiveUser?.id;
                          final color = roleColors[user.role] ?? AppColors.primary;
                          final label = roleLabels[user.role] ?? user.role;
                          final subtitle = [
                            label,
                            if (user.depotName != null) user.depotName!,
                          ].join(' · ');

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm,
                              vertical: 1,
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              tileColor: isSelected
                                  ? color.withValues(alpha: 0.08)
                                  : null,
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: color.withValues(alpha: 0.15),
                                backgroundImage: user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(
                                        user.initials,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                user.fullName,
                                style: TextStyle(
                                  color: isSelected ? color : AppColors.gray800,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: AppSizes.fontSm,
                                ),
                              ),
                              subtitle: Text(
                                subtitle,
                                style: TextStyle(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.8)
                                      : AppColors.gray400,
                                  fontSize: AppSizes.fontXs,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: color,
                                      size: AppSizes.iconMd,
                                    )
                                  : null,
                              onTap: () {
                                if (realUser == null) return;
                                ref.read(simulationProvider.notifier).start(
                                      realUser,
                                      user,
                                    );
                                Navigator.of(context).pop();
                                context.go(AppRoutes.dashboard);
                              },
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
