import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/confirm_dialog.dart';

// ─── Modèle de section ───────────────────────────────────────────────────────

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.route,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final String route;
  final String? subtitle;
}

class _SettingsSection {
  const _SettingsSection({required this.title, required this.items});
  final String title;
  final List<_SettingsItem> items;
}

// ─── Sections par rôle ──────────────────────────────────────────────────────
//
// Tous les rôles accèdent à la page Paramètres ; seules les sections autorisées
// s'affichent. La section « Sécurité & traçabilité » (journaux d'audit/connexion)
// n'apparaît que pour admin et superadmin — c'est le blocage côté frontend, en
// cohérence avec le backend qui renvoie 403 aux autres rôles.

const _configEntreprise = _SettingsSection(
  title: 'Configuration entreprise',
  items: [
    _SettingsItem(icon: Icons.location_on_outlined, label: 'Zones', route: AppRoutes.zones),
    _SettingsItem(icon: Icons.warehouse_outlined, label: 'Dépôts', route: AppRoutes.depots),
  ],
);

const _configCaisse = _SettingsSection(
  title: 'Finance',
  items: [
    _SettingsItem(
      icon: Icons.account_balance_outlined,
      label: 'Caisse de l\'entreprise',
      route: AppRoutes.caisseEntrepriseConfig,
      subtitle: 'Intitulé et devise (niveau racine)',
    ),
    _SettingsItem(
      icon: Icons.tune_rounded,
      label: 'Configuration des caisses',
      route: AppRoutes.financeConfig,
      subtitle: 'Durées des périodes de caisse',
    ),
  ],
);

const _catalogue = _SettingsSection(
  title: 'Catalogue',
  items: [
    _SettingsItem(
      icon: Icons.label_outline,
      label: 'Catégories',
      route: AppRoutes.categories,
      subtitle: 'Taux de TVA configuré par catégorie',
    ),
    _SettingsItem(icon: Icons.straighten_outlined, label: 'Unités de mesure', route: AppRoutes.unites),
  ],
);

const _securite = _SettingsSection(
  title: 'Sécurité & traçabilité',
  items: [
    _SettingsItem(
      icon: Icons.fact_check_outlined,
      label: 'Journaux d\'audit & connexion',
      route: AppRoutes.auditLogs,
      subtitle: 'Historique des actions et des connexions',
    ),
  ],
);

const _compte = _SettingsSection(
  title: 'Compte',
  items: [
    _SettingsItem(icon: Icons.notifications_outlined, label: 'Notifications', route: AppRoutes.notifications),
  ],
);

const Map<String, List<_SettingsSection>> _roleSections = {
  'superadmin': [_securite, _compte],
  'admin': [_configEntreprise, _configCaisse, _catalogue, _securite, _compte],
  'superviseur': [_configEntreprise, _compte],
  'gestionnaire_stock': [_catalogue, _compte],
  'caissier': [_compte],
  'chauffeur': [_compte],
  'maintenancier': [_compte],
  'commercial': [_compte],
};

// ─── Écran ────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(effectiveUserProvider);
    final role = ref.watch(effectiveRoleProvider);
    final sections = _roleSections[role] ?? [_compte];

    return AppScaffold(
      title: 'Paramètres',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingPage, AppSizes.md, AppSizes.paddingPage, AppSizes.xxl,
        ),
        children: [
          _ProfileCard(user: user, role: role),
          const SizedBox(height: AppSizes.lg),
          ...sections.map((s) => _SectionWidget(section: s)),
          const SizedBox(height: AppSizes.sm),
          _LogoutButton(
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Déconnexion',
      message: 'Voulez-vous vraiment vous déconnecter ?',
      confirmLabel: 'Déconnexion',
      isDanger: true,
    );
    if (confirmed == true) {
      ref.read(authProvider.notifier).logout();
    }
  }
}

// ─── Carte profil ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.role});
  final UserEntity? user;
  final String role;

  @override
  Widget build(BuildContext context) {
    final roleColor = roleColors[role] ?? AppColors.primary;
    final roleLabel = roleLabels[role] ?? role;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: () => context.go(AppRoutes.profile),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.gray100),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Center(
                  child: Text(
                    user?.initials ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName
                          : user?.email ?? '…',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                        fontSize: AppSizes.fontMd,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: AppColors.gray500,
                        fontSize: AppSizes.fontXs,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section ────────────────────────────────────────────────────────────────

class _SectionWidget extends StatelessWidget {
  const _SectionWidget({required this.section});
  final _SettingsSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.xs, top: AppSizes.sm, bottom: AppSizes.xs,
          ),
          child: Text(
            section.title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.gray400,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.gray100),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < section.items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 56, color: AppColors.borderLight),
                _ItemTile(item: section.items[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});
  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLightBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(item.icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: AppColors.gray800,
                      fontWeight: FontWeight.w500,
                      fontSize: AppSizes.fontSm,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      item.subtitle!,
                      style: const TextStyle(
                        color: AppColors.gray400,
                        fontSize: AppSizes.fontXs,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gray300, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dangerLightBg,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout_rounded, color: AppColors.danger, size: AppSizes.iconMd),
              SizedBox(width: AppSizes.sm),
              Text(
                'Déconnexion',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSizes.fontSm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
