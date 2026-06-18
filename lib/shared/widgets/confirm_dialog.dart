import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

/// Dialog de confirmation réutilisable.
///
/// Usage :
///   final confirmed = await ConfirmDialog.show(
///     context,
///     title: 'Fermer la caisse',
///     message: 'Cette action est irréversible.',
///     confirmLabel: 'Fermer',
///     isDanger: true,
///   );
///   if (confirmed == true) { ... }
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmer',
    this.cancelLabel = 'Annuler',
    this.isDanger = false,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;
  final IconData? icon;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    bool isDanger = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmColor = isDanger ? AppColors.danger : AppColors.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      contentPadding: const EdgeInsets.all(AppSizes.lg),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: confirmColor,
              size: AppSizes.iconLg,
            ),
            const SizedBox(width: AppSizes.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w700,
                color: isDanger ? AppColors.danger : AppColors.gray900,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: AppSizes.fontMd,
          color: AppColors.gray600,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: AppColors.gray500),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
