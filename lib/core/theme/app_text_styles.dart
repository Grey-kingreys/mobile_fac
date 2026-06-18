import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

abstract class AppTextStyles {
  // Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: AppSizes.fontDisplay,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.gray900,
  );

  // Titres
  static const TextStyle h1 = TextStyle(
    fontSize: AppSizes.fontXxl,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
    color: AppColors.gray900,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: AppSizes.fontXl,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.gray900,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: AppSizes.fontLg,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.gray800,
  );
  static const TextStyle h4 = TextStyle(
    fontSize: AppSizes.fontMd,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.gray800,
  );

  // Corps
  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppSizes.fontMd,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.gray700,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppSizes.fontSm,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.gray600,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: AppSizes.fontXs,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.gray500,
  );

  // Labels & boutons
  static const TextStyle labelLarge = TextStyle(
    fontSize: AppSizes.fontMd,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
    color: AppColors.gray800,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: AppSizes.fontSm,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.gray700,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: AppSizes.fontXs,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.gray600,
  );

  // Montants (GNF)
  static const TextStyle amount = TextStyle(
    fontSize: AppSizes.fontXl,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.primary,
  );
  static const TextStyle amountSmall = TextStyle(
    fontSize: AppSizes.fontMd,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.primary,
  );

  // Bouton
  static const TextStyle button = TextStyle(
    fontSize: AppSizes.fontMd,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
  );

  // Input
  static const TextStyle input = TextStyle(
    fontSize: AppSizes.fontMd,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.gray900,
  );
  static const TextStyle inputHint = TextStyle(
    fontSize: AppSizes.fontMd,
    fontWeight: FontWeight.w400,
    color: AppColors.gray400,
  );

  // Utilitaires
  static const TextStyle caption = TextStyle(
    fontSize: AppSizes.fontXs,
    fontWeight: FontWeight.w400,
    color: AppColors.gray500,
  );
  static const TextStyle overline = TextStyle(
    fontSize: AppSizes.fontXs,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.gray500,
  );
}
