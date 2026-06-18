import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/products/domain/entities/product_entity.dart';
import 'package:djoulagest_mobile/features/products/presentation/providers/products_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return AppScaffold(
      title: 'Fiche produit',
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: AppSizes.iconXxl, color: AppColors.gray300),
              const SizedBox(height: AppSizes.md),
              const Text('Produit introuvable',
                  style: TextStyle(color: AppColors.gray500)),
              const SizedBox(height: AppSizes.sm),
              TextButton(
                onPressed: () =>
                    ref.invalidate(productDetailProvider(productId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (product) => _ProductBody(product: product),
      ),
    );
  }
}

class _ProductBody extends StatelessWidget {
  const _ProductBody({required this.product});
  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingPage, AppSizes.md,
          AppSizes.paddingPage, AppSizes.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── En-tête ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: AppColors.primary, size: 30),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nom,
                        style: const TextStyle(
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.reference,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSm,
                          color: AppColors.gray500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (product.estPerimable) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: const Text(
                            'Périmable — FEFO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ─── Prix ────────────────────────────────────────────────────
          _Section(
            title: 'Prix',
            child: Row(
              children: [
                Expanded(
                  child: _PriceBox(
                    label: 'Prix d\'achat',
                    value: AppFormatters.gnf(product.prixAchat),
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _PriceBox(
                    label: 'Prix de vente',
                    value: AppFormatters.gnf(product.prixVente),
                    color: AppColors.primary,
                    highlighted: true,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _PriceBox(
                    label: 'Marge',
                    value:
                        '${AppFormatters.number(product.marge, decimals: 1)} %',
                    color: product.marge >= 0
                        ? AppColors.secondary
                        : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ─── Informations ────────────────────────────────────────────
          _Section(
            title: 'Informations',
            child: Column(
              children: [
                if (product.categorieNom != null)
                  _InfoRow(
                    icon: Icons.category_rounded,
                    label: 'Catégorie',
                    value: product.categorieNom!,
                  ),
                if (product.uniteNom != null || product.uniteSymbole != null)
                  _InfoRow(
                    icon: Icons.scale_rounded,
                    label: 'Unité',
                    value:
                        '${product.uniteNom ?? ''} (${product.uniteSymbole ?? '—'})'
                            .trim(),
                  ),
                if (product.fournisseurNom != null)
                  _InfoRow(
                    icon: Icons.business_rounded,
                    label: 'Fournisseur',
                    value: product.fournisseurNom!,
                  ),
                if (product.tvaTaux != null)
                  _InfoRow(
                    icon: Icons.percent_rounded,
                    label: 'TVA',
                    value: '${product.tvaTaux} %',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ─── Seuils de stock ─────────────────────────────────────────
          _Section(
            title: 'Seuils de stock',
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.warning_amber_rounded,
                  label: 'Seuil d\'alerte',
                  value: product.seuilAlerte != null
                      ? AppFormatters.number(product.seuilAlerte!, decimals: 0)
                      : '—',
                  iconColor: AppColors.accent,
                ),
                if (product.seuilMax != null)
                  _InfoRow(
                    icon: Icons.vertical_align_top_rounded,
                    label: 'Seuil maximum',
                    value: AppFormatters.number(product.seuilMax!,
                        decimals: 0),
                  ),
              ],
            ),
          ),

          // ─── Description ─────────────────────────────────────────────
          if (product.description != null &&
              product.description!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.md),
            _Section(
              title: 'Description',
              child: Text(
                product.description!,
                style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: AppColors.gray600,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // ─── Dates ───────────────────────────────────────────────────
          const SizedBox(height: AppSizes.md),
          _Section(
            title: 'Dates',
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Créé le',
                  value: AppFormatters.dateLong(product.createdAt),
                ),
                if (product.updatedAt != null)
                  _InfoRow(
                    icon: Icons.edit_rounded,
                    label: 'Modifié le',
                    value: AppFormatters.dateLong(product.updatedAt!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets helper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.gray400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.gray400,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: iconColor),
          const SizedBox(width: AppSizes.xs),
          Text('$label : ',
              style: const TextStyle(
                  fontSize: AppSizes.fontSm, color: AppColors.gray400)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                fontWeight: FontWeight.w600,
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

class _PriceBox extends StatelessWidget {
  const _PriceBox({
    required this.label,
    required this.value,
    required this.color,
    this.highlighted = false,
  });
  final String label;
  final String value;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: highlighted
            ? color.withValues(alpha: 0.06)
            : AppColors.gray100,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: highlighted
            ? Border.all(color: color.withValues(alpha: 0.2))
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.gray400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
