import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Palette principale — identique à front_fac/theme.ts ──────────────────
  static const Color primary     = Color(0xFF1A56A0); // blue institutionnel
  static const Color primaryLight = Color(0xFF2563EB); // blue-600 Tailwind
  static const Color primaryDark  = Color(0xFF1E3A5F); // blue foncé

  static const Color secondary     = Color(0xFF0E9F6E); // vert validation
  static const Color secondaryLight = Color(0xFF10B981); // emerald-500
  static const Color secondaryDark  = Color(0xFF065F46); // emerald-900

  static const Color accent  = Color(0xFFF59E0B); // ambre alertes
  static const Color purple  = Color(0xFF8B5CF6); // violet-500
  static const Color pink    = Color(0xFFEC4899); // pink-500
  static const Color cyan    = Color(0xFF06B6D4); // cyan-500

  // ── Sémantique ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF0E9F6E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // ── Arrière-plans — #F4F6FA identique à front_fac ────────────────────────
  static const Color backgroundLight = Color(0xFFF4F6FA);
  static const Color surfaceLight    = Color(0xFFFFFFFF);
  static const Color backgroundDark  = Color(0xFF0F1117);
  static const Color surfaceDark     = Color(0xFF1A1D27);
  static const Color cardDark        = Color(0xFF252836);

  // ── Teintes d'icônes (light bg pour les icon-containers des cards web) ───
  // Même logique que les variantes -50/-100 Tailwind utilisées dans front_fac
  static const Color primaryLightBg   = Color(0xFFEBF2FC); // blue-50 approx
  static const Color secondaryLightBg = Color(0xFFD1FAE5); // emerald-100
  static const Color accentLightBg    = Color(0xFFFEF3C7); // amber-100
  static const Color dangerLightBg    = Color(0xFFFEE2E2); // red-100
  static const Color infoLightBg      = Color(0xFFCFFAFE); // cyan-100
  static const Color purpleLightBg    = Color(0xFFEDE9FE); // violet-100
  static const Color pinkLightBg      = Color(0xFFFCE7F3); // pink-100
  static const Color orangeLightBg    = Color(0xFFFFF7ED); // orange-50

  // ── Auth screens ──────────────────────────────────────────────────────────
  // Dégradé blanc → bleu-50 → vert-50 (identique à login.html/forgot.html)
  static const Color authGradientStart  = Color(0xFFEFF6FF); // blue-50
  static const Color authGradientMiddle = Color(0xFFFFFFFF); // white
  static const Color authGradientEnd    = Color(0xFFECFDF5); // emerald-50
  static const Color authScaffoldBg     = Color(0xFFECFDF5); // scaffold fallback

  // ── Bordures ─────────────────────────────────────────────────────────────
  static const Color borderLight  = Color(0xFFE2E8F0); // slate-200
  static const Color borderMedium = Color(0xFFCBD5E1); // slate-300

  // ── Niveaux de gris ───────────────────────────────────────────────────────
  static const Color gray50  = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ── Mobile money (Guinée) ────────────────────────────────────────────────
  static const Color orangeMoney   = Color(0xFFF97316);
  static const Color orangeMoneyBg = Color(0xFFFFF7ED); // orange-50
  static const Color mtnMoney      = Color(0xFFEAB308);
  static const Color mtnMoneyBg    = Color(0xFFFFFBEB); // yellow-50

  // ── Utilitaires ──────────────────────────────────────────────────────────
  static const Color overlay         = Color(0x80000000);
  static const Color shimmerBase     = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color divider         = Color(0xFFE5E7EB);
}
