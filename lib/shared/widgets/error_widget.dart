import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.message = 'Une erreur est survenue.',
    this.onRetry,
    this.isNetwork = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool isNetwork;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetwork ? Icons.wifi_off_outlined : Icons.error_outline,
                size: AppSizes.iconXxl,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              isNetwork ? 'Pas de connexion' : 'Oups !',
              style: const TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.gray500,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
