import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

abstract class AppSnackbar {
  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.secondary, Icons.check_circle_outline);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.danger, Icons.error_outline);

  static void warning(BuildContext context, String message) =>
      _show(context, message, AppColors.accent, Icons.warning_amber_outlined);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppColors.info, Icons.info_outline);

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: AppSizes.iconMd),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSizes.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
