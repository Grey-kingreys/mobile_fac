import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/features/dashboard/domain/entities/kpi_entity.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.kpi, this.onTap});

  final KpiEntity kpi;
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
              color: AppColors.gray900.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône + trend/chevron
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: kpi.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(kpi.icon, color: kpi.color, size: AppSizes.iconMd),
                ),
                if (kpi.trendPercent != null)
                  _TrendBadge(kpi: kpi)
                else if (kpi.route != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: AppSizes.iconSm,
                    color: AppColors.gray300,
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),

            // Titre
            Text(
              kpi.title,
              style: const TextStyle(
                fontSize: AppSizes.fontXs,
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Valeur
            Text(
              kpi.value,
              style: TextStyle(
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.w700,
                color: kpi.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            if (kpi.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                kpi.subtitle!,
                style: const TextStyle(
                  fontSize: AppSizes.fontXs,
                  color: AppColors.gray400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.kpi});
  final KpiEntity kpi;

  @override
  Widget build(BuildContext context) {
    final pct = kpi.trendPercent!;
    final isUp = pct >= 0;
    final isGood = kpi.higherIsBetter ? isUp : !isUp;
    final color = isGood ? AppColors.secondary : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${pct.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
