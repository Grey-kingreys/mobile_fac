import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/inventory/domain/entities/stock_entity.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

class MovementsScreen extends ConsumerWidget {
  const MovementsScreen({super.key});

  static const _filters = [
    ('Tous', ''),
    ('Entrées', 'entree'),
    ('Sorties', 'sortie'),
    ('Transferts', 'transfert'),
    ('Ajustements', 'ajustement'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(movementsProvider);
    final currentFilter = movementsAsync.valueOrNull?.filter ?? '';

    return AppScaffold(
      title: 'Mouvements de stock',
      body: Column(
        children: [
          // ─── Filtres ────────────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingPage, vertical: 4),
              itemCount: _filters.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSizes.sm),
              itemBuilder: (ctx, i) {
                final (label, value) = _filters[i];
                final selected = currentFilter == value;
                return _FilterChip(
                  label: label,
                  selected: selected,
                  onTap: () => ref
                      .read(movementsProvider.notifier)
                      .setFilter(value),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ─── Liste mouvements ────────────────────────────────────────────
          Expanded(
            child: movementsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    const Text('Impossible de charger les mouvements',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(movementsProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.movements.isEmpty) {
                  return const _EmptyState();
                }
                return _MovementsList(state: state);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Liste ────────────────────────────────────────────────────────────────────

class _MovementsList extends ConsumerWidget {
  const _MovementsList({required this.state});
  final MovementsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ScrollController();
    controller.addListener(() {
      if (controller.position.pixels >=
          controller.position.maxScrollExtent - 200) {
        ref.read(movementsProvider.notifier).loadMore();
      }
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(movementsProvider.notifier).refresh(),
      child: ListView.separated(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingPage, 0, AppSizes.paddingPage, AppSizes.xxl),
        itemCount:
            state.movements.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.xs),
        itemBuilder: (ctx, i) {
          if (i == state.movements.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _MovementTile(movement: state.movements[i]);
        },
      ),
    );
  }
}

// ─── Tuile mouvement ──────────────────────────────────────────────────────────

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});
  final MovementEntity movement;

  Color get _color {
    return switch (movement.typeMouvement) {
      'entree' => AppColors.secondary,
      'sortie' => AppColors.danger,
      'transfert' => AppColors.primary,
      'ajustement' => AppColors.accent,
      _ => AppColors.gray500,
    };
  }

  IconData get _icon {
    return switch (movement.typeMouvement) {
      'entree' => Icons.arrow_downward_rounded,
      'sortie' => Icons.arrow_upward_rounded,
      'transfert' => Icons.swap_horiz_rounded,
      'ajustement' => Icons.tune_rounded,
      'inventaire' => Icons.fact_check_outlined,
      _ => Icons.compare_arrows_rounded,
    };
  }

  String get _sign {
    return switch (movement.typeMouvement) {
      'entree' => '+',
      'sortie' => '-',
      _ => '±',
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
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
          // Icône
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(_icon, color: color, size: AppSizes.iconMd),
          ),
          const SizedBox(width: AppSizes.sm),

          // Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.produitNom,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        movement.typeLabel.isNotEmpty
                            ? movement.typeLabel
                            : movement.typeMouvement,
                        style: TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Expanded(
                      child: Text(
                        movement.depotCode,
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
                if (movement.motif != null &&
                    movement.motif!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    movement.motif!,
                    style: const TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: AppColors.gray400,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Quantité + date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_sign${AppFormatters.number(movement.quantite, decimals: 0)}',
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                AppFormatters.timeAgo(movement.createdAt),
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

// ─── Filtre chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.xs),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.gray100,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontXs,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.gray500,
          ),
        ),
      ),
    );
  }
}

// ─── État vide ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows_rounded,
                size: AppSizes.iconXxl, color: AppColors.gray200),
            SizedBox(height: AppSizes.md),
            Text(
              'Aucun mouvement trouvé',
              style: TextStyle(
                  color: AppColors.gray500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
