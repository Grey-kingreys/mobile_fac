import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/dashboard/domain/entities/kpi_entity.dart';
import 'package:djoulagest_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:djoulagest_mobile/features/dashboard/presentation/widgets/kpi_card.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(effectiveUserProvider);
    final dashAsync = ref.watch(dashboardProvider);

    return AppScaffold(
      title: 'Tableau de bord',
      showBottomNav: true,
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: dashAsync.when(
          loading: () => const _DashboardSkeleton(),
          error: (_, __) => _ErrorView(
            onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
          ),
          data: (data) => _DashboardBody(user: user, data: data),
        ),
      ),
    );
  }
}

// ─── Corps principal ──────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.user, required this.data});

  final UserEntity? user;
  final DashboardDataEntity data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingPage,
        AppSizes.md,
        AppSizes.paddingPage,
        AppSizes.xxl,
      ),
      children: [
        // Greeting
        _GreetingHeader(user: user),
        const SizedBox(height: AppSizes.md),

        // Alertes
        if (data.alerts.isNotEmpty) ...[
          _AlertsSection(alerts: data.alerts),
          const SizedBox(height: AppSizes.md),
        ],

        // KPIs
        if (data.kpis.isNotEmpty) ...[
          const _SectionTitle('Indicateurs clés'),
          const SizedBox(height: AppSizes.sm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSizes.sm,
            mainAxisSpacing: AppSizes.sm,
            childAspectRatio: 1.15,
            children: data.kpis
                .map((kpi) => KpiCard(
                      kpi: kpi,
                      onTap: kpi.route != null
                          ? () => context.go(kpi.route!)
                          : null,
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSizes.md),
        ],

        // Accès rapide
        if (user != null) ...[
          _ShortcutsGrid(role: user!.role),
        ],
      ],
    );
  }
}

// ─── Greeting ─────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.user});
  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    final firstName = user?.firstName ?? '';
    final companyName = user?.companyName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting${firstName.isNotEmpty ? ', $firstName' : ''} !',
          style: const TextStyle(
            fontSize: AppSizes.fontXl,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        if (companyName != null) ...[
          const SizedBox(height: 2),
          Text(
            companyName,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.gray500,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Alertes ──────────────────────────────────────────────────────────────────

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.alerts});
  final List<AlertEntity> alerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Alertes'),
        const SizedBox(height: AppSizes.xs),
        ...alerts.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.xs),
              child: _AlertTile(alert: a),
            )),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final AlertEntity alert;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (alert.level) {
      AlertLevel.danger => (
          AppColors.danger.withValues(alpha: 0.08),
          AppColors.danger,
          AppColors.danger.withValues(alpha: 0.2),
        ),
      AlertLevel.warning => (
          AppColors.accent.withValues(alpha: 0.08),
          AppColors.accent,
          AppColors.accent.withValues(alpha: 0.2),
        ),
      AlertLevel.info => (
          AppColors.info.withValues(alpha: 0.08),
          AppColors.info,
          AppColors.info.withValues(alpha: 0.2),
        ),
    };

    return GestureDetector(
      onTap: alert.route != null ? () => context.go(alert.route!) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(alert.icon, size: AppSizes.iconSm, color: fg),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                alert.message,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (alert.route != null)
              Icon(Icons.chevron_right_rounded, size: AppSizes.iconSm, color: fg),
          ],
        ),
      ),
    );
  }
}

// ─── Accès rapide ─────────────────────────────────────────────────────────────

class _ShortcutsGrid extends StatelessWidget {
  const _ShortcutsGrid({required this.role});
  final String role;

  static const Map<String, List<(String, IconData, String)>> _roleShortcuts = {
    'superadmin': [
      ('Entreprises', Icons.business_rounded, '/admin'),
      ('Notifications', Icons.notifications_rounded, '/notifications'),
    ],
    'admin': [
      ('Caisse', Icons.point_of_sale_rounded, '/finance'),
      ('Stocks', Icons.inventory_2_rounded, '/inventory'),
      ('Équipe', Icons.people_rounded, '/hr'),
      ('Ventes', Icons.shopping_cart_rounded, '/sales'),
      ('Notifications', Icons.notifications_rounded, '/notifications'),
    ],
    'superviseur': [
      ('Finance', Icons.account_balance_rounded, '/finance'),
      ('Stocks', Icons.inventory_2_rounded, '/inventory'),
      ('Missions', Icons.local_shipping_rounded, '/logistics'),
      ('Notifications', Icons.notifications_rounded, '/notifications'),
    ],
    'gestionnaire_stock': [
      ('Stocks', Icons.inventory_2_rounded, '/inventory'),
      ('Mouvements', Icons.compare_arrows_rounded, '/inventory/movements'),
      ('Transferts', Icons.swap_horiz_rounded, '/inventory/transfer'),
      ('Scanner', Icons.qr_code_scanner_rounded, '/inventory/scan'),
    ],
    'caissier': [
      ('Caisse', Icons.point_of_sale_rounded, '/finance'),
      ('Nouvelle vente', Icons.add_shopping_cart_rounded, '/sales/new'),
      ('Transactions', Icons.receipt_long_rounded, '/finance/transactions'),
      ('Clients', Icons.people_rounded, '/sales/clients'),
    ],
    'chauffeur': [
      ('Missions', Icons.local_shipping_rounded, '/logistics'),
      ('Scanner QR', Icons.qr_code_scanner_rounded, '/logistics/qr-scan'),
      ('Notifications', Icons.notifications_rounded, '/notifications'),
    ],
    'maintenancier': [
      ('Flotte', Icons.directions_car_rounded, '/logistics'),
      ('Maintenance', Icons.build_rounded, '/logistics'),
      ('Notifications', Icons.notifications_rounded, '/notifications'),
    ],
    'commercial': [
      ('Ventes', Icons.shopping_cart_rounded, '/sales'),
      ('Clients', Icons.people_rounded, '/sales/clients'),
      ('Nouvelle vente', Icons.add_shopping_cart_rounded, '/sales/new'),
      ('Produits', Icons.category_rounded, '/products'),
    ],
  };

  // Route prefix → (iconColor, iconBg)
  static (Color, Color) _routeColor(String route) {
    if (route.startsWith('/finance')) return (AppColors.purple, AppColors.purpleLightBg);
    if (route.startsWith('/inventory/scan') || route.startsWith('/logistics/qr')) {
      return (AppColors.cyan, AppColors.infoLightBg);
    }
    if (route.startsWith('/inventory')) return (AppColors.primary, AppColors.primaryLightBg);
    if (route.startsWith('/sales')) return (AppColors.secondary, AppColors.secondaryLightBg);
    if (route.startsWith('/hr')) return (AppColors.pink, AppColors.pinkLightBg);
    if (route.startsWith('/logistics')) return (AppColors.accent, AppColors.accentLightBg);
    if (route.startsWith('/notifications')) return (AppColors.info, AppColors.infoLightBg);
    if (route.startsWith('/products')) return (AppColors.purple, AppColors.purpleLightBg);
    if (route.startsWith('/admin')) return (AppColors.primary, AppColors.primaryLightBg);
    return (AppColors.primary, AppColors.primaryLightBg);
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = _roleShortcuts[role] ??
        [('Notifications', Icons.notifications_rounded, '/notifications')];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accès rapide',
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSizes.xs,
            crossAxisSpacing: AppSizes.xs,
            childAspectRatio: 1.1,
            children: shortcuts
                .map((s) => _ShortcutItem(label: s.$1, icon: s.$2, route: s.$3))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  const _ShortcutItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    final (iconColor, iconBg) = _ShortcutsGrid._routeColor(route);

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xs, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppSizes.fontXs,
                color: AppColors.gray700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Titre de section ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppSizes.fontMd,
        fontWeight: FontWeight.w600,
        color: AppColors.gray800,
      ),
    );
  }
}

// ─── Skeleton loading ─────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingPage),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _Shimmer(height: 80, radius: AppSizes.radiusLg),
        const SizedBox(height: AppSizes.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSizes.sm,
          mainAxisSpacing: AppSizes.sm,
          childAspectRatio: 1.15,
          children: List.generate(
            4,
            (_) => const _Shimmer(height: 0, radius: AppSizes.radiusMd),
          ),
        ),
      ],
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.height, required this.radius});
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height > 0 ? height : null,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Vue d'erreur ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: AppSizes.iconXxl,
              color: AppColors.gray300,
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Impossible de charger le tableau de bord',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray500),
            ),
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
