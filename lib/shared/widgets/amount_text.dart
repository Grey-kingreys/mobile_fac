import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';

/// Affiche un montant formaté en GNF (ou autre devise).
/// Usage : AmountText(amount: 1500000) → "1 500 000 GNF"
class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.amount,
    this.currency = 'GNF',
    this.style,
    this.color,
    this.large = false,
    this.positive,
  });

  final num amount;
  final String currency;
  final TextStyle? style;
  final Color? color;

  /// Si true, affiche plus grand (pour les cartes KPI).
  final bool large;

  /// null = neutre, true = vert (recette), false = rouge (dépense)
  final bool? positive;

  Color get _color {
    if (color != null) return color!;
    if (positive == null) return AppColors.gray900;
    return positive! ? AppColors.secondary : AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: large ? AppSizes.fontXxl : AppSizes.fontMd,
      fontWeight: FontWeight.w700,
      color: _color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Text(
      currency == 'GNF'
          ? AppFormatters.gnf(amount)
          : AppFormatters.currency(amount, currency),
      style: style ?? defaultStyle,
    );
  }
}

/// Montant avec libellé au-dessus (pour les cartes KPI du dashboard).
class KpiAmountCard extends StatelessWidget {
  const KpiAmountCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.positive,
    this.currency = 'GNF',
  });

  final String label;
  final num amount;
  final IconData icon;
  final Color iconColor;
  final bool? positive;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppSizes.fontXs,
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            AmountText(
              amount: amount,
              currency: currency,
              large: true,
              positive: positive,
            ),
          ],
        ),
      ),
    );
  }
}
