import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

/// Badge de statut générique (mission, caisse, commande, etc.)
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.small = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool small;

  // ── Constructeurs sémantiques ───────────────────────────────────────────────

  factory StatusBadge.missionStatus(String status) {
    // Slugs exacts retournés par Mission.Statut (back_fac/apps/logistique/models.py)
    return switch (status) {
      'planifiee' => StatusBadge(
          label: 'Planifiée',
          color: AppColors.info,
          icon: Icons.schedule,
        ),
      'chargement' => StatusBadge(
          label: 'Chargement',
          color: AppColors.accent,
          icon: Icons.inventory_2_outlined,
        ),
      'en_transit' => StatusBadge(
          label: 'En route',
          color: AppColors.primary,
          icon: Icons.local_shipping_outlined,
        ),
      'arrivee' => StatusBadge(
          label: 'Arrivée',
          color: AppColors.secondary,
          icon: Icons.location_on_outlined,
        ),
      'litige' => StatusBadge(
          label: 'Litige',
          color: AppColors.danger,
          icon: Icons.warning_amber_outlined,
        ),
      'terminee' => StatusBadge(
          label: 'Terminée',
          color: AppColors.gray500,
          icon: Icons.check_circle_outline,
        ),
      'annulee' => StatusBadge(
          label: 'Annulée',
          color: AppColors.gray400,
          icon: Icons.cancel_outlined,
        ),
      _ => StatusBadge(label: status, color: AppColors.gray400),
    };
  }

  factory StatusBadge.cashStatus(bool isOpen) => StatusBadge(
        label: isOpen ? 'Ouverte' : 'Fermée',
        color: isOpen ? AppColors.secondary : AppColors.gray400,
        icon: isOpen ? Icons.lock_open_outlined : Icons.lock_outlined,
      );

  factory StatusBadge.stockAlert(bool isCritical) => StatusBadge(
        label: isCritical ? 'Rupture' : 'Stock OK',
        color: isCritical ? AppColors.danger : AppColors.secondary,
        icon: isCritical ? Icons.warning_amber_outlined : Icons.check_circle_outline,
        small: true,
      );

  @override
  Widget build(BuildContext context) {
    final fontSize = small ? AppSizes.fontXs : AppSizes.fontXs + 1;
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 10 : 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
