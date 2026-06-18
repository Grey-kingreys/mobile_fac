import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

enum AppButtonVariant { primary, secondary, outline, danger, ghost }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.gradient = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final bool gradient;

  double get _height => switch (size) {
        AppButtonSize.sm => AppSizes.buttonHeightSm,
        AppButtonSize.md => AppSizes.buttonHeight,
        AppButtonSize.lg => AppSizes.buttonHeight + 8,
      };

  double get _fontSize => switch (size) {
        AppButtonSize.sm => AppSizes.fontSm,
        AppButtonSize.md => AppSizes.fontMd,
        AppButtonSize.lg => AppSizes.fontLg,
      };

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final child = _buildLabel();

    if (gradient && variant == AppButtonVariant.primary) {
      return _GradientButton(
        onPressed: disabled ? null : onPressed,
        height: _height,
        fullWidth: fullWidth,
        child: child,
      );
    }

    return switch (variant) {
      AppButtonVariant.primary => _elevated(child, disabled, AppColors.primary),
      AppButtonVariant.secondary => _elevated(child, disabled, AppColors.secondary),
      AppButtonVariant.danger => _elevated(child, disabled, AppColors.danger),
      AppButtonVariant.outline => _outlined(child, disabled),
      AppButtonVariant.ghost => _ghost(child, disabled),
    };
  }

  Widget _buildLabel() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: variant == AppButtonVariant.outline || variant == AppButtonVariant.ghost
              ? AppColors.primary
              : Colors.white,
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconMd),
          const SizedBox(width: AppSizes.sm),
          Text(label),
        ],
      );
    }
    return Text(label);
  }

  SizedBox _sized(Widget button) => SizedBox(
        width: fullWidth ? double.infinity : null,
        height: _height,
        child: button,
      );

  Widget _elevated(Widget child, bool disabled, Color color) => _sized(
        ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.gray200,
            textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600),
          ),
          child: child,
        ),
      );

  Widget _outlined(Widget child, bool disabled) => _sized(
        OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600),
          ),
          child: child,
        ),
      );

  Widget _ghost(Widget child, bool disabled) => _sized(
        TextButton(
          onPressed: disabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500),
          ),
          child: child,
        ),
      );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.height,
    required this.fullWidth,
    required this.child,
  });

  final VoidCallback? onPressed;
  final double height;
  final bool fullWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.secondaryLight],
                ),
          color: disabled ? AppColors.gray200 : null,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Center(
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSizes.fontMd,
                ),
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
