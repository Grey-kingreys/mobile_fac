import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/products/domain/entities/product_entity.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});
  final ProductEntity product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
            // Icône catégorie
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: const Icon(Icons.inventory_2_rounded,
                  color: AppColors.primary, size: AppSizes.iconMd),
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
                          product.nom,
                          style: const TextStyle(
                            fontSize: AppSizes.fontSm,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppFormatters.gnf(product.prixVente),
                        style: const TextStyle(
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        product.reference,
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray400,
                        ),
                      ),
                      if (product.categorieNom != null) ...[
                        const Text(' · ',
                            style: TextStyle(color: AppColors.gray300)),
                        Expanded(
                          child: Text(
                            product.categorieNom!,
                            style: const TextStyle(
                              fontSize: AppSizes.fontXs,
                              color: AppColors.gray400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (product.uniteSymbole != null)
                        Text(
                          ' / ${product.uniteSymbole}',
                          style: const TextStyle(
                            fontSize: AppSizes.fontXs,
                            color: AppColors.gray400,
                          ),
                        ),
                    ],
                  ),
                  if (product.estPerimable) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: const Text(
                            'Périmable',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppSizes.xs),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.gray300, size: AppSizes.iconMd),
          ],
        ),
      ),
    );
  }
}
