import 'package:flutter/material.dart';

abstract class AppResponsive {
  static const double _tabletBreakpoint = 600.0;
  static const double _desktopBreakpoint = 1024.0;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _tabletBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= _tabletBreakpoint && w < _desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

  /// Retourne une valeur différente selon le type d'appareil.
  static T value<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? phone;
    if (isTablet(context)) return tablet ?? phone;
    return phone;
  }

  // ── Espacement adaptatif ────────────────────────────────────────────────────

  static double paddingPage(BuildContext context) =>
      value(context, phone: 16.0, tablet: 24.0, desktop: 32.0);

  static double paddingCard(BuildContext context) =>
      value(context, phone: 16.0, tablet: 20.0);

  // ── Grilles adaptatives ─────────────────────────────────────────────────────

  /// Nombre de colonnes pour GridView (ex : liste de produits, KPI cards)
  static int gridColumns(BuildContext context, {int phone = 2, int tablet = 3}) =>
      value(context, phone: phone, tablet: tablet, desktop: 4);

  // ── Typographie adaptive ────────────────────────────────────────────────────

  static double fontSize(
    BuildContext context, {
    required double phone,
    double? tablet,
  }) =>
      value(context, phone: phone, tablet: tablet ?? phone * 1.1);

  // ── Composants ──────────────────────────────────────────────────────────────

  static double buttonHeight(BuildContext context) =>
      value(context, phone: 52.0, tablet: 56.0);

  static double inputHeight(BuildContext context) =>
      value(context, phone: 52.0, tablet: 56.0);

  static double appBarHeight(BuildContext context) =>
      value(context, phone: 56.0, tablet: 64.0);

  static double drawerWidth(BuildContext context) =>
      value(context, phone: 280.0, tablet: 320.0);

  /// Largeur maximale du contenu (centré sur tablette/desktop)
  static double maxContentWidth(BuildContext context) =>
      value(context, phone: double.infinity, tablet: 600.0, desktop: 800.0);

  /// Wrapper qui centre et contraint le contenu sur tablette/desktop.
  static Widget constrain(BuildContext context, Widget child) {
    if (isPhone(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
        child: child,
      ),
    );
  }
}
