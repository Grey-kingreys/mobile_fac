import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

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
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppSizes.iconXxl,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: AppColors.gray500,
                ),
              ),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: AppSizes.lg),
              OutlinedButton.icon(
                onPressed: action,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
