import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/logistics/domain/entities/mission_entity.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.mission,
    this.onTap,
  });

  final MissionEntity mission;
  final VoidCallback? onTap;

  Color get _statutColor {
    return switch (mission.statut) {
      'planifiee' => AppColors.gray500,
      'chargement_en_cours' => AppColors.accent,
      'transport_en_cours' => AppColors.primary,
      'arrive_destination' => AppColors.secondary,
      'litige' => AppColors.danger,
      'terminee' => AppColors.secondary,
      'annulee' => AppColors.gray400,
      _ => AppColors.gray400,
    };
  }

  IconData get _statutIcon {
    return switch (mission.statut) {
      'planifiee' => Icons.schedule_rounded,
      'chargement_en_cours' => Icons.inventory_rounded,
      'transport_en_cours' => Icons.local_shipping_rounded,
      'arrive_destination' => Icons.location_on_rounded,
      'litige' => Icons.warning_amber_rounded,
      'terminee' => Icons.check_circle_rounded,
      'annulee' => Icons.cancel_rounded,
      _ => Icons.local_shipping_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _statutColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: mission.isLitige
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : numéro + statut
            Row(
              children: [
                Text(
                  mission.numero,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statutIcon, size: 11, color: color),
                      const SizedBox(width: 4),
                      Text(
                        mission.statutLabel,
                        style: TextStyle(
                          fontSize: AppSizes.fontXs,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),

            // Trajet
            Row(
              children: [
                const Icon(Icons.radio_button_checked_rounded,
                    size: 12, color: AppColors.gray400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mission.depotDepartNom ?? 'Dépôt départ',
                    style: const TextStyle(
                        fontSize: AppSizes.fontXs, color: AppColors.gray600),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Container(
                  width: 2, height: 10, color: AppColors.gray200),
            ),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mission.depotArriveeNom ?? 'Dépôt arrivée',
                    style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),

            // Véhicule + chauffeur + date
            Row(
              children: [
                if (mission.vehiculeImmat != null) ...[
                  const Icon(Icons.directions_car_rounded,
                      size: 12, color: AppColors.gray400),
                  const SizedBox(width: 4),
                  Text(
                    mission.vehiculeImmat!,
                    style: const TextStyle(
                        fontSize: AppSizes.fontXs, color: AppColors.gray500),
                  ),
                  const SizedBox(width: AppSizes.sm),
                ],
                const Spacer(),
                Text(
                  AppFormatters.dateShort(mission.createdAt),
                  style: const TextStyle(
                      fontSize: AppSizes.fontXs, color: AppColors.gray400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
