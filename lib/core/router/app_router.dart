import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/features/admin/presentation/screens/admin_screen.dart';
import 'package:djoulagest_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:djoulagest_mobile/features/reports/presentation/screens/reports_screen.dart';
import 'package:djoulagest_mobile/features/finance/presentation/screens/caisse_config_screen.dart';
import 'package:djoulagest_mobile/features/finance/presentation/screens/caisse_entreprise_config_screen.dart';
import 'package:djoulagest_mobile/features/finance/presentation/screens/caisses_screen.dart';
import 'package:djoulagest_mobile/features/finance/presentation/screens/cash_session_screen.dart';
import 'package:djoulagest_mobile/features/finance/presentation/screens/transactions_screen.dart';
import 'package:djoulagest_mobile/features/hr/presentation/screens/employees_screen.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/screens/barcode_scan_screen.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/screens/movements_screen.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/screens/stock_screen.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/screens/stock_entree_screen.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/screens/ajustements_screen.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/screens/inventaires_screen.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/screens/transfer_screen.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/screens/mission_detail_screen.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/screens/missions_screen.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/screens/qr_scan_screen.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/screens/vehicules_screen.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/screens/signature_screen.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/screens/logistics_sub_screens.dart';
import 'package:djoulagest_mobile/features/hr/presentation/screens/attendance_screen.dart';
import 'package:djoulagest_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:djoulagest_mobile/features/products/presentation/screens/categories_screen.dart';
import 'package:djoulagest_mobile/features/products/presentation/screens/product_detail_screen.dart';
import 'package:djoulagest_mobile/features/products/presentation/screens/products_list_screen.dart';
import 'package:djoulagest_mobile/features/products/presentation/screens/unites_screen.dart';
import 'package:djoulagest_mobile/features/sales/presentation/screens/clients_screen.dart';
import 'package:djoulagest_mobile/features/sales/presentation/screens/devis_screen.dart';
import 'package:djoulagest_mobile/features/sales/presentation/screens/new_sale_screen.dart';
import 'package:djoulagest_mobile/features/sales/presentation/screens/sales_list_screen.dart';
import 'package:djoulagest_mobile/features/finance/presentation/screens/depenses_screen.dart';
import 'package:djoulagest_mobile/features/finance/presentation/screens/mobile_money_screen.dart';
import 'package:djoulagest_mobile/features/suppliers/presentation/screens/supplier_detail_screen.dart';
import 'package:djoulagest_mobile/features/suppliers/presentation/screens/commandes_fournisseurs_screen.dart';
import 'package:djoulagest_mobile/features/suppliers/presentation/screens/suppliers_screen.dart';
import 'package:djoulagest_mobile/features/zones/presentation/screens/zones_screen.dart';
import 'package:djoulagest_mobile/features/depots/presentation/screens/depots_screen.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:djoulagest_mobile/features/auth/presentation/screens/first_login_screen.dart';
import 'package:djoulagest_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:djoulagest_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:djoulagest_mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:djoulagest_mobile/features/auth/presentation/screens/two_factor_screen.dart';
import 'package:djoulagest_mobile/features/auth/presentation/screens/two_factor_setup_screen.dart';
import 'package:djoulagest_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:djoulagest_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:djoulagest_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:djoulagest_mobile/features/audit/presentation/screens/audit_logs_screen.dart';
// ─── RouterNotifier — relie Riverpod auth state ↔ GoRouter ──────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(isAuthenticatedProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingDoneProvider, (_, __) => notifyListeners());
    _ref.listen(twoFactorPendingProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(isAuthenticatedProvider);
    final onboardingAsync = _ref.read(onboardingDoneProvider);

    // Attendre la fin du chargement initial
    if (authAsync.isLoading || onboardingAsync.isLoading) return null;

    final isLoggedIn = authAsync.valueOrNull ?? false;
    final isOnboardingDone = onboardingAsync.valueOrNull ?? false;
    final path = state.uri.path;

    // Premier lancement : montrer l'onboarding
    if (!isOnboardingDone && path != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }

    // 2FA en attente — rediriger vers l'écran de vérification
    final pending2fa = _ref.read(twoFactorPendingProvider);
    if (pending2fa != null && !isLoggedIn) {
      if (path != AppRoutes.twoFactor) return AppRoutes.twoFactor;
      return null;
    }

    const authRoutes = [
      AppRoutes.login,
      AppRoutes.forgotPassword,
      AppRoutes.resetPassword,
      AppRoutes.firstLogin,
      AppRoutes.twoFactor,
    ];
    final isPublicRoute = authRoutes.contains(path) || path == AppRoutes.onboarding;

    if (!isLoggedIn && !isPublicRoute) return AppRoutes.login;
    if (isLoggedIn && isPublicRoute) return AppRoutes.dashboard;
    return null;
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final routerNotifierProvider = ChangeNotifierProvider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Onboarding ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: AppRoutes.firstLogin,
        builder: (_, state) => FirstLoginScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: AppRoutes.twoFactor,
        builder: (_, __) => const TwoFactorScreen(),
      ),

      // ── App protégée ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, __) => const AdminScreen(),
      ),
      GoRoute(
        path: AppRoutes.zones,
        builder: (_, __) => const ZonesScreen(),
      ),
      GoRoute(
        path: AppRoutes.depots,
        builder: (_, __) => const DepotsScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (_, __) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: '2fa-setup',
            builder: (_, __) => const TwoFactorSetupScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),

      // ── Paramètres (hub) ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'audit-logs',
            builder: (_, __) => const AuditLogsScreen(),
          ),
        ],
      ),

      // ── Stocks ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.inventory,
        builder: (_, __) => const StockScreen(),
        routes: [
          GoRoute(
            path: 'entree',
            builder: (_, __) => const StockEntreeScreen(),
          ),
          GoRoute(
            path: 'movements',
            builder: (_, __) => const MovementsScreen(),
          ),
          GoRoute(
            path: 'scan',
            builder: (_, __) => const BarcodeScanScreen(),
          ),
          GoRoute(
            path: 'transfer',
            builder: (_, __) => const TransferScreen(),
          ),
          GoRoute(
            path: 'ajustements',
            builder: (_, __) => const AjustementsScreen(),
          ),
          GoRoute(
            path: 'inventaires',
            builder: (_, __) => const InventairesScreen(),
          ),
        ],
      ),

      // ── Ventes ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.sales,
        builder: (_, __) => const SalesListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const NewSaleScreen(),
          ),
          GoRoute(
            path: 'clients',
            builder: (_, __) => const ClientsScreen(),
          ),
          GoRoute(
            path: 'devis',
            builder: (_, __) => const DevisScreen(),
          ),
        ],
      ),

      // ── Finance ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.finance,
        builder: (_, __) => const CashSessionScreen(),
        routes: [
          GoRoute(
            path: 'transactions',
            builder: (_, __) => const TransactionsScreen(),
          ),
          GoRoute(
            path: 'depenses',
            builder: (_, __) => const DepensesScreen(),
          ),
          GoRoute(
            path: 'mobile-money',
            builder: (_, __) => const MobileMoneyScreen(),
          ),
          GoRoute(
            path: 'caisses',
            builder: (_, __) => const CaissesScreen(),
          ),
          GoRoute(
            path: 'configuration',
            builder: (_, __) => const CaisseConfigScreen(),
          ),
          GoRoute(
            path: 'caisse-entreprise',
            builder: (_, __) => const CaisseEntrepriseConfigScreen(),
          ),
          GoRoute(
            path: 'versement',
            builder: (_, __) => const _ComingSoonScreen(title: 'Versements'),
          ),
        ],
      ),

      // ── Fournisseurs ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.suppliers,
        builder: (_, __) => const SuppliersScreen(),
        routes: [
          GoRoute(
            path: 'commandes',
            builder: (_, __) => const CommandesFournisseursScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) => SupplierDetailScreen(
              supplierId:
                  int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
        ],
      ),

      // ── Logistique ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.logistics,
        builder: (_, __) => const MissionsScreen(),
        routes: [
          GoRoute(
            path: 'vehicules',
            builder: (_, __) => const VehiculesScreen(),
          ),
          GoRoute(
            path: 'qr-scan',
            builder: (_, __) => const QrScanScreen(),
          ),
          GoRoute(
            path: 'maintenances',
            builder: (_, __) => const MaintenancesScreen(),
          ),
          GoRoute(
            path: 'pannes',
            builder: (_, __) => const PannesScreen(),
          ),
          GoRoute(
            path: 'carburant',
            builder: (_, __) => const CarburantScreen(),
          ),
          GoRoute(
            path: 'documents-vehicule',
            builder: (_, __) => const DocumentsVehiculeScreen(),
          ),
          GoRoute(
            path: 'signature/:id',
            builder: (_, state) => SignatureScreen(
              missionId:
                  int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) => MissionDetailScreen(
              missionId:
                  int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
        ],
      ),

      // ── RH ───────────────────────────────────────────────────────────────
      // Gestion des comptes (= employés) : admin/superviseur.
      GoRoute(
        path: AppRoutes.hr,
        builder: (_, __) => const EmployeesScreen(),
      ),
      // Pointage de présence + congés (self-service) : route top-level distincte
      // pour ne pas instancier EmployeesScreen (/users/) en parent.
      GoRoute(
        path: AppRoutes.attendance,
        builder: (_, __) => const AttendanceScreen(),
      ),

      // ── Produits ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.products,
        builder: (_, __) => const ProductsListScreen(),
        routes: [
          GoRoute(
            path: 'categories',
            builder: (_, __) => const CategoriesScreen(),
          ),
          GoRoute(
            path: 'unites',
            builder: (_, __) => const UnitesScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) => ProductDetailScreen(
              productId:
                  int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
        ],
      ),
    ],
  );
});

// ─── Écran "coming soon" pour les routes non encore implémentées ─────────────

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '$title — bientôt disponible',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
