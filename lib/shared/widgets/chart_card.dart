import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

/// Conteneur réutilisable pour héberger un graphique (fl_chart) sur les
/// tableaux de bord. Style aligné sur les cartes existantes
/// (fond blanc, bordure gris clair, ombre légère).
///
/// [legend] permet d'afficher une liste de pastilles couleur + libellé sous
/// le graphique (utile pour les camemberts/donuts).
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.height = 200,
    this.legend = const [],
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final double height;
  final List<ChartLegendItem> legend;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
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
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(height: height, child: child),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: AppSizes.md),
            Wrap(
              spacing: AppSizes.md,
              runSpacing: AppSizes.xs,
              children: legend.map((l) => _LegendChip(item: l)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class ChartLegendItem {
  const ChartLegendItem(this.label, this.color, {this.value});
  final String label;
  final Color color;
  final String? value;
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.item});
  final ChartLegendItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          item.value != null ? '${item.label} · ${item.value}' : item.label,
          style: const TextStyle(
            fontSize: AppSizes.fontXs,
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
