import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';

// ─── Modèles internes ───────────────────────────────────────────────────────

class _DrawerItem {
  final IconData icon;
  final String label;
  final String route;

  const _DrawerItem({required this.icon, required this.label, required this.route});
}

class _DrawerSection {
  final String? title;
  final List<_DrawerItem> items;

  const _DrawerSection({this.title, required this.items});
}

// ─── Sections par rôle ──────────────────────────────────────────────────────

const Map<String, List<_DrawerSection>> _roleSections = {
  // Superadmin = opérateur SaaS. Il gère les entreprises clientes, pas leurs opérations internes.
  // NE PEUT PAS : zones, dépôts, utilisateurs opérationnels — périmètre de l'admin d'entreprise.
  'superadmin': [
    _DrawerSection(title: 'Vue globale', items: [
      _DrawerItem(icon: Icons.dashboard_outlined, label: 'Tableau de bord', route: AppRoutes.dashboard),
    ]),
    _DrawerSection(title: 'Plateforme SaaS', items: [
      _DrawerItem(icon: Icons.business_outlined, label: 'Entreprises', route: AppRoutes.admin),
    ]),
    _DrawerSection(title: 'Compte', items: [
      _DrawerItem(icon: Icons.notifications_outlined, label: 'Notifications', route: AppRoutes.notifications),
      _DrawerItem(icon: Icons.person_outline, label: 'Mon profil', route: AppRoutes.profile),
    ]),
  ],
  'admin': [
    _DrawerSection(title: null, items: [
      _DrawerItem(icon: Icons.dashboard_outlined, label: 'Tableau de bord', route: AppRoutes.dashboard),
    ]),
    _DrawerSection(title: 'Opérations', items: [
      _DrawerItem(icon: Icons.inventory_2_outlined, label: 'Stocks', route: AppRoutes.inventory),
      _DrawerItem(icon: Icons.swap_horiz, label: 'Transferts inter-dépôts', route: AppRoutes.inventoryTransfer),
      _DrawerItem(icon: Icons.tune_outlined, label: 'Ajustements stock', route: AppRoutes.inventoryAjustements),
      _DrawerItem(icon: Icons.assignment_outlined, label: 'Inventaires', route: AppRoutes.inventoryInventaires),
      _DrawerItem(icon: Icons.account_balance_wallet_outlined, label: 'Finance', route: AppRoutes.finance),
      _DrawerItem(icon: Icons.account_balance_outlined, label: 'Gestion des caisses', route: AppRoutes.financeCaisses),
      _DrawerItem(icon: Icons.tune_rounded, label: 'Config. caisses', route: AppRoutes.financeConfig),
      _DrawerItem(icon: Icons.receipt_long_outlined, label: 'Dépenses', route: AppRoutes.financeDepenses),
      _DrawerItem(icon: Icons.phone_android_rounded, label: 'Mobile Money', route: AppRoutes.financeMobileMoney),
      _DrawerItem(icon: Icons.point_of_sale_outlined, label: 'Ventes', route: AppRoutes.sales),
      _DrawerItem(icon: Icons.local_shipping_outlined, label: 'Logistique', route: AppRoutes.logistics),
      _DrawerItem(icon: Icons.build_outlined, label: 'Maintenances', route: AppRoutes.maintenances),
      _DrawerItem(icon: Icons.warning_amber_rounded, label: 'Pannes', route: AppRoutes.pannes),
      _DrawerItem(icon: Icons.local_gas_station_rounded, label: 'Carburant', route: AppRoutes.carburant),
      _DrawerItem(icon: Icons.folder_outlined, label: 'Documents véhicule', route: AppRoutes.documentsVehicule),
      _DrawerItem(icon: Icons.category_outlined, label: 'Produits', route: AppRoutes.products),
      _DrawerItem(icon: Icons.label_outline, label: 'Catégories', route: AppRoutes.categories),
      _DrawerItem(icon: Icons.straighten_outlined, label: 'Unités', route: AppRoutes.unites),
      _DrawerItem(icon: Icons.handshake_outlined, label: 'Fournisseurs', route: AppRoutes.suppliers),
    ]),
    _DrawerSection(title: 'Administration', items: [
      _DrawerItem(icon: Icons.people_outline, label: 'Ressources Humaines', route: AppRoutes.hr),
    ]),
    _DrawerSection(title: 'Configuration', items: [
      _DrawerItem(icon: Icons.location_on_outlined, label: 'Zones', route: AppRoutes.zones),
      _DrawerItem(icon: Icons.warehouse_outlined, label: 'Dépôts', route: AppRoutes.depots),
    ]),
    _DrawerSection(title: 'Compte', items: [
      _DrawerItem(icon: Icons.notifications_outlined, label: 'Notifications', route: AppRoutes.notifications),
      _DrawerItem(icon: Icons.person_outline, label: 'Mon profil', route: AppRoutes.profile),
    ]),
  ],
  'superviseur': [
    _DrawerSection(title: null, items: [
      _DrawerItem(icon: Icons.dashboard_outlined, label: 'Tableau de bord', route: AppRoutes.dashboard),
    ]),
    _DrawerSection(title: 'Opérations', items: [
      _DrawerItem(icon: Icons.inventory_2_outlined, label: 'Stocks', route: AppRoutes.inventory),
      _DrawerItem(icon: Icons.swap_horiz, label: 'Transferts inter-dépôts', route: AppRoutes.inventoryTransfer),
      _DrawerItem(icon: Icons.tune_outlined, label: 'Ajustements stock', route: AppRoutes.inventoryAjustements),
      _DrawerItem(icon: Icons.assignment_outlined, label: 'Inventaires', route: AppRoutes.inventoryInventaires),
      _DrawerItem(icon: Icons.account_balance_wallet_outlined, label: 'Finance', route: AppRoutes.finance),
      _DrawerItem(icon: Icons.receipt_long_outlined, label: 'Dépenses', route: AppRoutes.financeDepenses),
      _DrawerItem(icon: Icons.phone_android_rounded, label: 'Mobile Money', route: AppRoutes.financeMobileMoney),
      _DrawerItem(icon: Icons.point_of_sale_outlined, label: 'Ventes', route: AppRoutes.sales),
      _DrawerItem(icon: Icons.local_shipping_outlined, label: 'Logistique', route: AppRoutes.logistics),
      _DrawerItem(icon: Icons.build_outlined, label: 'Maintenances', route: AppRoutes.maintenances),
      _DrawerItem(icon: Icons.warning_amber_rounded, label: 'Pannes', route: AppRoutes.pannes),
      _DrawerItem(icon: Icons.local_gas_station_rounded, label: 'Carburant', route: AppRoutes.carburant),
      _DrawerItem(icon: Icons.folder_outlined, label: 'Documents véhicule', route: AppRoutes.documentsVehicule),
      _DrawerItem(icon: Icons.handshake_outlined, label: 'Fournisseurs', route: AppRoutes.suppliers),
      _DrawerItem(icon: Icons.people_outline, label: 'Ressources Humaines', route: AppRoutes.hr),
    ]),
    _DrawerSection(title: 'Configuration', items: [
      _DrawerItem(icon: Icons.location_on_outlined, label: 'Zones', route: AppRoutes.zones),
      _DrawerItem(icon: Icons.warehouse_outlined, label: 'Dépôts', route: AppRoutes.depots),
    ]),
    _DrawerSection(title: 'Compte', items: [
      _DrawerItem(icon: Icons.notifications_outlined, label: 'Notifications', route: AppRoutes.notifications),
      _DrawerItem(icon: Icons.person_outline, label: 'Mon profil', route: AppRoutes.profile),
    ]),
  ],
  'gestionnaire_stock': [
    _DrawerSection(title: 'Stock', items: [
      _DrawerItem(icon: Icons.dashboard_outlined, label: 'Tableau de bord', route: AppRoutes.dashboard),
      _DrawerItem(icon: Icons.inventory_2_outlined, label: 'Stocks', route: AppRoutes.inventory),
      _DrawerItem(icon: Icons.category_outlined, label: 'Produits', route: AppRoutes.products),
      _DrawerItem(icon: Icons.label_outline, label: 'Catégories', route: AppRoutes.categories),
      _DrawerItem(icon: Icons.straighten_outlined, label: 'Unités', route: AppRoutes.unites),
      _DrawerItem(icon: Icons.handshake_outlined, label: 'Fournisseurs', route: AppRoutes.suppliers),
      _DrawerItem(icon: Icons.add_shopping_cart_rounded, label: 'Commandes fournisseurs', route: AppRoutes.commandesFournisseurs),
      _DrawerItem(icon: Icons.swap_horiz, label: 'Transferts inter-dépôts', route: AppRoutes.inventoryTransfer),
      _DrawerItem(icon: Icons.tune_outlined, label: 'Ajustements stock', route: AppRoutes.inventoryAjustements),
      _DrawerItem(icon: Icons.assignment_outlined, label: 'Inventaires', route: AppRoutes.inventoryInventaires),
      _DrawerItem(icon: Icons.qr_code_scanner, label: 'Scanner code-barres', route: AppRoutes.inventoryBarcode),
    ]),
    _DrawerSection(title: 'Logistique', items: [
      _DrawerItem(icon: Icons.local_shipping_outlined, label: 'Missions', route: AppRoutes.logistics),
    ]),
    _DrawerSection(title: 'Compte', items: [
      _DrawerItem(icon: Icons.notifications_outlined, label: 'Notifications', route: AppRoutes.notifications),
      _DrawerItem(icon: Icons.person_outline, label: 'Mon profil', route: AppRoutes.profile),
    ]),
  ],
  'caissier': [
    _DrawerSection(title: 'Finance', items: [
      _DrawerItem(icon: Icons.account_balance_wallet_outlined, label: 'Caisse & Sessions', route: AppRoutes.finance),
      _DrawerItem(icon: Icons.receipt_long_outlined, label: 'Transactions', route: AppRoutes.financeTransactions),
      _DrawerItem(icon: Icons.money_off_rounded, label: 'Dépenses', route: AppRoutes.financeDepenses),
      _DrawerItem(icon: Icons.phone_android_rounded, label: 'Mobile Money', route: AppRoutes.financeMobileMoney),
      _DrawerItem(icon: Icons.point_of_sale_outlined, label: 'Ventes', route: AppRoutes.sales),
    ]),
    _DrawerSection(title: 'Compte', items: [
      _DrawerItem(icon: Icons.notifications_outlined, label: 'Notifications', route: AppRoutes.notifications),
      _DrawerItem(icon: Icons.person_outline, label: 'Mon profil', route: AppRoutes.profile),
    ]),
  ],
  'chauffeur': [
    _DrawerSection(title: 'Logistique', items: [
      _DrawerItem(icon: Icons.local_shipping_outlined, label: 'Mes missions', route: AppRoutes.logistics),
      _DrawerItem(icon: Icons.qr_code_scanner, label: 'Scanner QR mission', route: AppRoutes.qrScan),
      _DrawerItem(icon: Icons.warning_amber_rounded, label: 'Pannes', route: AppRoutes.pannes),
      _DrawerItem(icon: Icons.local_gas_station_rounded, label: 'Carburant', route: AppRoutes.carburant),
    ]),
    _DrawerSection(title: 'Compte', items: [
      _DrawerItem(icon: Icons.notifications_outlined, label: 'Notifications', route: AppRoutes.notifications),
      _DrawerItem(icon: Icons.person_outline, label: 'Mon profil', route: AppRoutes.profile),
    ]),
  ],
  'maintenancier': [
    _DrawerSection(title: 'Maintenance', items: [
      _DrawerItem(icon: Icons.dashboard_outlined, label: 'Tableau de bord', route: AppRoutes.dashboard),
      _DrawerItem(icon: Icons.local_shipping_outlined, label: 'Flotte & Véhicules', route: AppRoutes.logistics),
      _DrawerItem(icon: Icons.build_outlined, label: 'Maintenances', route: AppRoutes.maintenances),
      _DrawerItem(icon: Icons.warning_amber_rounded, label: 'Pannes', route: AppRoutes.pannes),
      _DrawerItem(icon: Icons.folder_outlined, label: 'Documents véhicule', route: AppRoutes.documentsVehicule),
    ]),
    _DrawerSection(title: 'Compte', items: [
      _DrawerItem(icon: Icons.notifications_outlined, label: 'Notifications', route: AppRoutes.notifications),
      _DrawerItem(icon: Icons.person_outline, label: 'Mon profil', route: AppRoutes.profile),
    ]),
  ],
  'commercial': [
    _DrawerSection(title: 'Commerce', items: [
      _DrawerItem(icon: Icons.dashboard_outlined, label: 'Tableau de bord', route: AppRoutes.dashboard),
      _DrawerItem(icon: Icons.point_of_sale_outlined, label: 'Ventes', route: AppRoutes.sales),
      _DrawerItem(icon: Icons.people_outline, label: 'Clients', route: AppRoutes.clients),
      _DrawerItem(icon: Icons.description_outlined, label: 'Devis', route: AppRoutes.devis),
    ]),
    _DrawerSection(title: 'Compte', items: [
      _DrawerItem(icon: Icons.notifications_outlined, label: 'Notifications', route: AppRoutes.notifications),
      _DrawerItem(icon: Icons.person_outline, label: 'Mon profil', route: AppRoutes.profile),
    ]),
  ],
};

// ─── Drawer principal ───────────────────────────────────────────────────────

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Affiche les infos du user simulé quand simulation active.
    final user = ref.watch(effectiveUserProvider);
    final role = ref.watch(effectiveRoleProvider);
    final sections = _roleSections[role] ?? _roleSections['caissier']!;
    final roleColor = roleColors[role] ?? AppColors.primary;
    final roleLabel = roleLabels[role] ?? role;

    return Drawer(
      width: AppSizes.drawerWidth,
      child: Column(
        children: [
          _Header(
            user: user,
            roleLabel: roleLabel,
            roleColor: roleColor,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: AppSizes.xs, bottom: AppSizes.md),
              children: sections
                  .map(
                    (section) => _SectionWidget(
                      section: section,
                      currentLocation: currentLocation,
                      onItemTap: (route) {
                        Navigator.of(context).pop();
                        context.go(route);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: const Text(
              'Déconnexion',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
                fontSize: AppSizes.fontSm,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSizes.xs),
        ],
      ),
    );
  }
}

// ─── Header du drawer ───────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.roleLabel,
    required this.roleColor,
  });

  final UserEntity? user;
  final String roleLabel;
  final Color roleColor;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo bar (identique au header du sidebar web) ─────────────────
          Container(
            height: topPad + 64,
            padding: EdgeInsets.only(
              top: topPad,
              left: AppSizes.md,
              right: AppSizes.md,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', width: 36, height: 36),
                const SizedBox(width: AppSizes.sm),
                // "Djoula" + "Gest" en gradient bleu→vert (copie exacte du web)
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Djoula',
                        style: TextStyle(
                          color: AppColors.gray900,
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextSpan(
                        text: 'Gest',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Utilisateur connecté ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm + 4,
            ),
            child: Row(
              children: [
                _DrawerAvatar(user: user),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName
                            : user?.email ?? '…',
                        style: const TextStyle(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w600,
                          fontSize: AppSizes.fontSm,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user?.companyName != null || user?.depotName != null)
                        Text(
                          [user?.companyName, user?.depotName]
                              .whereType<String>()
                              .join(' · '),
                          style: const TextStyle(
                            color: AppColors.gray400,
                            fontSize: AppSizes.fontXs,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Badge rôle compact
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border:
                        Border.all(color: roleColor.withValues(alpha: 0.4)),
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
          const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
        ],
      ),
    );
  }
}

// ─── Section du drawer ──────────────────────────────────────────────────────

class _SectionWidget extends StatelessWidget {
  const _SectionWidget({
    required this.section,
    required this.currentLocation,
    required this.onItemTap,
  });

  final _DrawerSection section;
  final String currentLocation;
  final void Function(String route) onItemTap;

  bool _isActive(String route) {
    // Même logique que le bottom nav : préfixe le plus long.
    return currentLocation == route || currentLocation.startsWith('$route/');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.md,
              right: AppSizes.md,
              top: AppSizes.md,
              bottom: AppSizes.xs,
            ),
            child: Text(
              section.title!.toUpperCase(),
              style: const TextStyle(
                color: AppColors.gray400,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ...section.items.map((item) {
          final active = _isActive(item.route);
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: 1,
            ),
            child: ListTile(
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                side: active
                    ? BorderSide(
                        color: AppColors.secondary.withValues(alpha: 0.3))
                    : BorderSide.none,
              ),
              tileColor: active
                  ? AppColors.secondary.withValues(alpha: 0.07)
                  : null,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: active ? Colors.white : AppColors.gray100,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  item.icon,
                  size: 18,
                  color: active ? AppColors.secondary : AppColors.gray500,
                ),
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  color: active ? AppColors.secondary : AppColors.gray700,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  fontSize: AppSizes.fontSm,
                ),
              ),
              trailing: active
                  ? Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
              onTap: () => onItemTap(item.route),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Avatar dans le drawer ──────────────────────────────────────────────────

class _DrawerAvatar extends StatelessWidget {
  const _DrawerAvatar({required this.user});

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    if (user?.avatarUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Image.network(
          user!.avatarUrl!,
          width: 40, height: 40,
          fit: BoxFit.cover,
        ),
      );
    }
    // Gradient square avatar — identique au web
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Center(
        child: Text(
          user?.initials ?? '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
