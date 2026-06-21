import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';

// ─── Modèle ─────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

// ─── Items par rôle ─────────────────────────────────────────────────────────

const Map<String, List<_NavItem>> _roleNavItems = {
  // Superadmin = opérateur SaaS : gère les entreprises clientes, pas leurs opérations internes.
  'superadmin': [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Tableau', route: AppRoutes.dashboard),
    _NavItem(icon: Icons.business_outlined, activeIcon: Icons.business, label: 'Entreprises', route: AppRoutes.admin),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alertes', route: AppRoutes.notifications),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Paramètres', route: AppRoutes.settings),
  ],
  'admin': [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Tableau', route: AppRoutes.dashboard),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Stocks', route: AppRoutes.inventory),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Finance', route: AppRoutes.finance),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'RH', route: AppRoutes.hr),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Paramètres', route: AppRoutes.settings),
  ],
  'superviseur': [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Tableau', route: AppRoutes.dashboard),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Stocks', route: AppRoutes.inventory),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Finance', route: AppRoutes.finance),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'RH', route: AppRoutes.hr),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Paramètres', route: AppRoutes.settings),
  ],
  'gestionnaire_stock': [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Tableau', route: AppRoutes.dashboard),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Stocks', route: AppRoutes.inventory),
    _NavItem(icon: Icons.category_outlined, activeIcon: Icons.category, label: 'Produits', route: AppRoutes.products),
    _NavItem(icon: Icons.swap_horiz, activeIcon: Icons.swap_horiz, label: 'Transferts', route: AppRoutes.inventoryTransfer),
    _NavItem(icon: Icons.event_available_outlined, activeIcon: Icons.event_available, label: 'Présence', route: AppRoutes.attendance),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Paramètres', route: AppRoutes.settings),
  ],
  'caissier': [
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Caisse', route: AppRoutes.finance),
    _NavItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale, label: 'Ventes', route: AppRoutes.sales),
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Tableau', route: AppRoutes.dashboard),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alertes', route: AppRoutes.notifications),
    _NavItem(icon: Icons.event_available_outlined, activeIcon: Icons.event_available, label: 'Présence', route: AppRoutes.attendance),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Paramètres', route: AppRoutes.settings),
  ],
  'chauffeur': [
    _NavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Missions', route: AppRoutes.logistics),
    _NavItem(icon: Icons.qr_code_scanner, activeIcon: Icons.qr_code_scanner, label: 'Scanner', route: AppRoutes.qrScan),
    _NavItem(icon: Icons.event_available_outlined, activeIcon: Icons.event_available, label: 'Présence', route: AppRoutes.attendance),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alertes', route: AppRoutes.notifications),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Paramètres', route: AppRoutes.settings),
  ],
  'maintenancier': [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Tableau', route: AppRoutes.dashboard),
    _NavItem(icon: Icons.build_outlined, activeIcon: Icons.build, label: 'Flotte', route: AppRoutes.logistics),
    _NavItem(icon: Icons.event_available_outlined, activeIcon: Icons.event_available, label: 'Présence', route: AppRoutes.attendance),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alertes', route: AppRoutes.notifications),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Paramètres', route: AppRoutes.settings),
  ],
  'commercial': [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Tableau', route: AppRoutes.dashboard),
    _NavItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale, label: 'Ventes', route: AppRoutes.sales),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Clients', route: AppRoutes.clients),
    _NavItem(icon: Icons.event_available_outlined, activeIcon: Icons.event_available, label: 'Présence', route: AppRoutes.attendance),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alertes', route: AppRoutes.notifications),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Paramètres', route: AppRoutes.settings),
  ],
};

// ─── Widget ─────────────────────────────────────────────────────────────────

class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key, required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(effectiveRoleProvider);
    final items = _roleNavItems[role] ?? _roleNavItems['caissier']!;

    // Sélectionne l'item avec le préfixe de route le plus long (le plus spécifique).
    int selectedIndex = 0;
    int bestLen = 0;
    for (int i = 0; i < items.length; i++) {
      final r = items[i].route;
      if (currentLocation.startsWith(r) && r.length > bestLen) {
        selectedIndex = i;
        bestLen = r.length;
      }
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) => context.go(items[i].route),
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon, color: AppColors.gray500),
              selectedIcon: Icon(item.activeIcon, color: AppColors.primary),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
