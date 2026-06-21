import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/inventory/domain/entities/stock_entity.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final _searchCtrl = TextEditingController();
  bool _alertsOnly = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    const canEntree = ['admin', 'gestionnaire_stock'];
    final showEntree = canEntree.contains(ref.watch(effectiveRoleProvider));

    return AppScaffold(
      title: 'Stocks',
      showBottomNav: true,
      floatingActionButton: showEntree
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/inventory/entree'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Entrée de stock'),
            )
          : null,
      additionalActions: [
        IconButton(
          icon: const Icon(Icons.compare_arrows_rounded),
          tooltip: 'Mouvements',
          onPressed: () => context.go('/inventory/movements'),
        ),
        IconButton(
          icon: const Icon(Icons.swap_horiz_rounded),
          tooltip: 'Transferts',
          onPressed: () => context.go('/inventory/transfer'),
        ),
      ],
      body: Column(
        children: [
          // ─── Barre recherche + filtre alerte ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, AppSizes.md, AppSizes.paddingPage, 0),
            child: Column(
              children: [
                // Recherche
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      ref.read(inventoryProvider.notifier).search(v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit ou dépôt…',
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
                              ref.read(inventoryProvider.notifier).search('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.gray200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.gray200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                // Filtre alertes
                Row(
                  children: [
                    _FilterChip(
                      label: 'Tous les stocks',
                      selected: !_alertsOnly,
                      onTap: () {
                        setState(() => _alertsOnly = false);
                        ref
                            .read(inventoryProvider.notifier)
                            .filterAlerts(false);
                      },
                    ),
                    const SizedBox(width: AppSizes.sm),
                    _FilterChip(
                      label: 'En alerte',
                      icon: Icons.warning_amber_rounded,
                      selected: _alertsOnly,
                      color: AppColors.danger,
                      onTap: () {
                        setState(() => _alertsOnly = true);
                        ref
                            .read(inventoryProvider.notifier)
                            .filterAlerts(true);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Liste stocks ──────────────────────────────────────────────
          Expanded(
            child: inventoryAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => _ErrorView(
                onRetry: () =>
                    ref.read(inventoryProvider.notifier).refresh(),
              ),
              data: (state) {
                if (state.stocks.isEmpty) {
                  return _EmptyState(alertsOnly: state.alertsOnly);
                }
                return _StockList(state: state);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Liste ────────────────────────────────────────────────────────────────────

class _StockList extends ConsumerWidget {
  const _StockList({required this.state});
  final InventoryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ScrollController();
    controller.addListener(() {
      if (controller.position.pixels >=
          controller.position.maxScrollExtent - 200) {
        ref.read(inventoryProvider.notifier).loadMore();
      }
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
      child: ListView.separated(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingPage,
          AppSizes.md,
          AppSizes.paddingPage,
          AppSizes.xxl,
        ),
        itemCount: state.stocks.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.xs),
        itemBuilder: (ctx, i) {
          if (i == state.stocks.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _StockTile(stock: state.stocks[i]);
        },
      ),
    );
  }
}

// ─── Tuile stock ──────────────────────────────────────────────────────────────

class _StockTile extends StatelessWidget {
  const _StockTile({required this.stock});
  final StockEntity stock;

  @override
  Widget build(BuildContext context) {
    final isAlert = stock.enAlerte;
    final alertColor = isAlert ? AppColors.danger : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isAlert
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.gray100,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône produit
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              isAlert
                  ? Icons.warning_amber_rounded
                  : Icons.inventory_2_rounded,
              color: alertColor,
              size: AppSizes.iconMd,
            ),
          ),
          const SizedBox(width: AppSizes.sm),

          // Infos produit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.produitNom,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: AppColors.gray400),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        [
                          stock.depotCode,
                          if (stock.zoneNom != null) stock.zoneNom!,
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (isAlert && stock.seuilAlerte != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Seuil : ${AppFormatters.number(stock.seuilAlerte!)} ${stock.uniteSymbole ?? ''}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Quantité
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.number(stock.quantite, decimals: 0),
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w700,
                  color: alertColor,
                ),
              ),
              if (stock.uniteSymbole != null)
                Text(
                  stock.uniteSymbole!,
                  style: const TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.gray400,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color = AppColors.primary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm + 4, vertical: AppSizes.xs + 2),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.gray100,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.4) : AppColors.gray200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: AppSizes.iconSm - 2,
                  color: selected ? color : AppColors.gray400),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontXs,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.alertsOnly});
  final bool alertsOnly;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              alertsOnly
                  ? Icons.check_circle_rounded
                  : Icons.inventory_2_rounded,
              size: AppSizes.iconXxl,
              color: alertsOnly ? AppColors.secondary : AppColors.gray200,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              alertsOnly ? 'Aucun stock en alerte' : 'Aucun stock trouvé',
              style: const TextStyle(
                  color: AppColors.gray500, fontWeight: FontWeight.w500),
            ),
            if (alertsOnly)
              const Padding(
                padding: EdgeInsets.only(top: AppSizes.xs),
                child: Text(
                  'Tous les stocks sont au-dessus du seuil minimum.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.gray400, fontSize: AppSizes.fontSm),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
            const Icon(Icons.wifi_off_rounded,
                size: AppSizes.iconXxl, color: AppColors.gray300),
            const SizedBox(height: AppSizes.md),
            const Text('Impossible de charger les stocks',
                style: TextStyle(color: AppColors.gray500)),
            const SizedBox(height: AppSizes.sm),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
