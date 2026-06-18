import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

abstract class AppTheme {
  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // ── ColorScheme ──────────────────────────────────────────────────────────
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: AppColors.primary,
            primaryContainer: AppColors.primaryDark,
            secondary: AppColors.secondary,
            secondaryContainer: AppColors.secondaryDark,
            surface: AppColors.surfaceDark,
            error: AppColors.danger,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onError: Colors.white,
            outline: AppColors.gray700,
          )
        : ColorScheme.light(
            primary: AppColors.primary,
            primaryContainer: const Color(0xFFDBEAFE),
            secondary: AppColors.secondary,
            secondaryContainer: const Color(0xFFD1FAE5),
            surface: AppColors.surfaceLight,
            error: AppColors.danger,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppColors.gray900,
            onError: Colors.white,
            outline: AppColors.gray300,
          );

    // ── Typographie (hiérarchie identique au front_fac / Tailwind) ───────────
    final textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 32, fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppColors.gray900,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : AppColors.gray900,
      ),
      displaySmall: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : AppColors.gray900,
      ),
      headlineLarge: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : AppColors.gray900,
      ),
      headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.gray900,
      ),
      headlineSmall: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.gray900,
      ),
      titleLarge: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.gray900,
      ),
      titleMedium: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : AppColors.gray900,
      ),
      titleSmall: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: isDark ? AppColors.gray300 : AppColors.gray700,
      ),
      bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: isDark ? AppColors.gray200 : AppColors.gray700,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: isDark ? AppColors.gray300 : AppColors.gray600,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: isDark ? AppColors.gray400 : AppColors.gray500,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.gray900,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: isDark ? AppColors.gray300 : AppColors.gray600,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: isDark ? AppColors.gray400 : AppColors.gray500,
        letterSpacing: 0.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // Fond général — #F4F6FA en clair (identique à front_fac background)
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,

      // ── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.gray200,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor: isDark ? Colors.white : AppColors.gray900,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: AppSizes.fontLg,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.gray900,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.gray700,
          size: AppSizes.iconLg,
        ),
        actionsIconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.gray700,
          size: AppSizes.iconLg,
        ),
        centerTitle: false,
      ),

      // ── Drawer ──────────────────────────────────────────────────────────
      // Fond blanc, identique au sidebar front_fac (bg-white border-r)
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppSizes.radiusLg),
            bottomRight: Radius.circular(AppSizes.radiusLg),
          ),
        ),
      ),

      // ── NavigationBar (M3 — utilisé par AppBottomNavBar) ────────────────
      // selected = primary blue, indicateur = primaryLight tint
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.gray200,
        elevation: 8,
        height: AppSizes.bottomNavHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
                color: AppColors.primary, size: AppSizes.iconLg);
          }
          return IconThemeData(
              color: isDark ? AppColors.gray500 : AppColors.gray400,
              size: AppSizes.iconLg);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return TextStyle(
            fontSize: AppSizes.fontXs,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.gray500 : AppColors.gray400,
          );
        }),
      ),

      // ── Card ────────────────────────────────────────────────────────────
      // Cartes blanches avec ombre légère — identique aux cards front_fac
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          side: BorderSide(
            color: isDark ? AppColors.gray800 : AppColors.gray100,
          ),
        ),
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
      ),

      // ── Bouton principal ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.gray200,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontMd,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // ── Bouton outlined ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontMd,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Bouton texte ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: AppSizes.fontMd,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Input ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.paddingInput,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.gray700 : AppColors.gray300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.gray700 : AppColors.gray200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.gray500 : AppColors.gray400,
          fontSize: AppSizes.fontMd,
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.gray400 : AppColors.gray600,
          fontSize: AppSizes.fontMd,
        ),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: AppSizes.fontXs,
        ),
      ),

      // ── ListTile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        titleTextStyle: TextStyle(
          fontSize: AppSizes.fontSm,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.gray900,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: AppSizes.fontXs,
          color: isDark ? AppColors.gray500 : AppColors.gray400,
        ),
        iconColor: isDark ? AppColors.gray400 : AppColors.gray500,
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.gray800 : AppColors.gray100,
        labelStyle: TextStyle(
          fontSize: AppSizes.fontSm,
          color: isDark ? AppColors.gray200 : AppColors.gray700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: 2,
        ),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        titleTextStyle: TextStyle(
          fontSize: AppSizes.fontLg,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.gray900,
        ),
        contentTextStyle: TextStyle(
          fontSize: AppSizes.fontSm,
          color: isDark ? AppColors.gray300 : AppColors.gray600,
          height: 1.5,
        ),
      ),

      // ── BottomSheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusXl),
            topRight: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        dragHandleColor: isDark ? AppColors.gray600 : AppColors.gray300,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.gray800 : AppColors.gray900,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: AppSizes.fontSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSizes.md),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.gray800 : AppColors.gray100,
        thickness: 1,
        space: 1,
      ),

      // ── PopupMenu ────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: TextStyle(
          fontSize: AppSizes.fontSm,
          color: isDark ? Colors.white : AppColors.gray900,
        ),
      ),

      // ── Switch ───────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? AppColors.gray500 : AppColors.gray400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.secondary;
          return isDark ? AppColors.gray700 : AppColors.gray300;
        }),
      ),
    );
  }
}
