import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';

// Palette identique au front_fac (login.html, home.html)
const _kBg = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.authGradientStart, AppColors.authGradientMiddle, AppColors.authGradientEnd],
  stops: [0.0, 0.5, 1.0],
);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  static const int _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    ref.invalidate(onboardingDoneProvider);
    if (mounted) context.go(AppRoutes.login);
  }

  void _next() {
    if (_currentPage < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authScaffoldBg,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(gradient: _kBg),
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: const [
                _Page1(),
                _Page2(),
                _Page3(),
              ],
            ),
            // Bouton "Passer" en haut à droite
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSizes.sm,
              right: AppSizes.md,
              child: AnimatedOpacity(
                opacity: _currentPage < _pageCount - 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gray500,
                    textStyle: const TextStyle(fontSize: AppSizes.fontSm),
                  ),
                  child: const Text('Passer'),
                ),
              ),
            ),
            // Bas : dots + bouton
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomBar(
                currentPage: _currentPage,
                pageCount: _pageCount,
                onNext: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentPage,
    required this.pageCount,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == pageCount - 1;
    final bottomPadding = MediaQuery.of(context).padding.bottom + AppSizes.lg;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.lg,
        AppSizes.lg,
        bottomPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicateurs de page
          Row(
            children: List.generate(pageCount, (i) {
              final isActive = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: isActive ? 24.0 : 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.gray200,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              );
            }),
          ),
          // Bouton gradient bleu → vert (identique au CTA du front_fac)
          GestureDetector(
            onTap: onNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                horizontal: isLast ? AppSizes.xl : AppSizes.md,
                vertical: AppSizes.sm + 4,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLast ? 'Commencer' : 'Suivant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.fontMd,
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: AppSizes.iconMd),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 1 — Bienvenue ───────────────────────────────────────────────────────

class _Page1 extends StatelessWidget {
  const _Page1();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Logo dans un cercle blanc avec ombre
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            // Badge "ERP Multi-Sites" — identique au front_fac home
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.xs + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Gestion d\'Entreprise Multi-Sites',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: AppSizes.fontXs,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            // Titre avec texte gradient — comme "Djoula**Gest**" dans le web
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Bienvenue sur\nDjoula',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray900,
                      height: 1.25,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Gest',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.25,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'La solution ERP multi-sites conçue pour les entreprises guinéennes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontMd,
                color: AppColors.gray500,
                height: 1.5,
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

// ─── Page 2 — Fonctionnalités ─────────────────────────────────────────────────

class _Page2 extends StatelessWidget {
  const _Page2();

  static const _features = [
    (Icons.inventory_2_outlined, AppColors.primary, AppColors.primaryLightBg, 'Stocks'),
    (Icons.point_of_sale_outlined, AppColors.secondary, AppColors.secondaryLightBg, 'Ventes'),
    (Icons.account_balance_wallet_outlined, AppColors.accent, AppColors.accentLightBg, 'Finance'),
    (Icons.local_shipping_outlined, AppColors.purple, AppColors.purpleLightBg, 'Logistique'),
    (Icons.people_outline, AppColors.pink, AppColors.pinkLightBg, 'RH'),
    (Icons.bar_chart_rounded, AppColors.cyan, AppColors.infoLightBg, 'Rapports'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
        child: Column(
          children: [
            const Spacer(flex: 1),
            // Titre
            const Text(
              'Tout sous contrôle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.gray900,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            const Text(
              'Stocks, ventes, finance, logistique et RH dans votre poche.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.gray500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            // Grille de fonctionnalités — cartes blanches avec ombre (style web)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: AppSizes.md,
              crossAxisSpacing: AppSizes.md,
              childAspectRatio: 1.1,
              children: _features.map((f) {
                return _FeatureCard(
                  icon: f.$1,
                  iconColor: f.$2,
                  iconBg: f.$3,
                  label: f.$4,
                );
              }).toList(),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd - 2),
            ),
            child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.gray700,
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 3 — Fait pour la Guinée ────────────────────────────────────────────

class _Page3 extends StatelessWidget {
  const _Page3();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Cartes de paiement mobile — style web (cartes blanches)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PaymentCard(
                  color: AppColors.orangeMoney,
                  bgColor: AppColors.orangeMoneyBg,
                  icon: Icons.phone_android_outlined,
                  label: 'Orange\nMoney',
                ),
                const SizedBox(width: AppSizes.md),
                // Badge GNF central
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'GNF',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                _PaymentCard(
                  color: AppColors.mtnMoney,
                  bgColor: AppColors.mtnMoneyBg,
                  icon: Icons.phone_android_outlined,
                  label: 'MTN\nMoney',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xl),
            // Badge multi-sites — style web
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined,
                      color: AppColors.primary, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Multi-sites · Multi-dépôts · Multi-zones',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppSizes.fontXs,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            // Titre
            const Text(
              'Fait pour la Guinée',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.gray900,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'GNF, Orange Money, MTN Money.\nVotre réalité, notre priorité.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontMd,
                color: AppColors.gray500,
                height: 1.6,
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.label,
  });

  final Color color;
  final Color bgColor;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconMd),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
