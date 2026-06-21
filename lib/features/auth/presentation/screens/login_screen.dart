import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/errors/app_exception.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/constants/app_strings.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/core/utils/validators.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.hasError) {
      _showError(_errorMessage(authState.error));
    }
    // Si succès, le routeur redirige automatiquement via le redirect GoRouter
  }

  String _errorMessage(Object? error) {
    // L'erreur remontée est un DioException dont `.error` porte l'AppException
    // parsée par l'ErrorInterceptor.
    final parsed = error is DioException ? error.error : error;

    if (parsed is UnauthorizedException) {
      // 401 sur /auth/login/ = identifiants incorrects.
      return 'Email ou mot de passe incorrect.';
    }
    if (parsed is ForbiddenException) {
      // 403 = compte désactivé ou bloqué après trop de tentatives.
      return parsed.message;
    }
    if (parsed is ValidationException) {
      return parsed.message;
    }
    if (parsed is NetworkException || parsed is TimeoutException) {
      return AppStrings.errorNetwork;
    }

    final msg = error?.toString() ?? '';
    if (msg.contains('401') || msg.contains('credentials') || msg.contains('password')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (msg.contains('network') || msg.contains('Network') || msg.contains('SocketException')) {
      return AppStrings.errorNetwork;
    }
    return 'Connexion impossible. Réessayez.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSizes.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.authScaffoldBg,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.authGradientStart, AppColors.authGradientMiddle, AppColors.authGradientEnd],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingPage),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSizes.xxl),
                      _Header(),
                      const SizedBox(height: AppSizes.xxl),
                      _LoginCard(
                        formKey: _formKey,
                        emailCtrl: _emailCtrl,
                        passwordCtrl: _passwordCtrl,
                        obscurePassword: _obscurePassword,
                        onTogglePassword: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        isLoading: isLoading,
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: AppSizes.lg),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        child: const Text(
                          AppStrings.forgotPassword,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: AppSizes.fontSm,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _Footer(),
                      const SizedBox(height: AppSizes.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        Image.asset(
          'assets/images/logo.png',
          width: 80,
          height: 80,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: AppSizes.md),
        // Nom "Djoula" + "Gest" en gradient bleu→vert
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: AppSizes.fontXxl,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            children: [
              const TextSpan(
                text: 'Djoula',
                style: TextStyle(color: AppColors.gray900),
              ),
              WidgetSpan(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.secondaryLight],
                  ).createShader(bounds),
                  child: const Text(
                    'Gest',
                    style: TextStyle(
                      fontSize: AppSizes.fontXxl,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        const Text(
          AppStrings.appTagline,
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

// ─── Formulaire de connexion ──────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.login,
              style: TextStyle(
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            const Text(
              'Connectez-vous à votre espace',
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Champ email
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: AppStrings.email,
                hintText: 'votre@email.com',
                prefixIcon: Icon(Icons.email_outlined, size: AppSizes.iconMd),
              ),
              validator: AppValidators.email,
            ),
            const SizedBox(height: AppSizes.md),

            // Champ mot de passe
            TextFormField(
              controller: passwordCtrl,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              enabled: !isLoading,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: AppStrings.password,
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: AppSizes.iconMd),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: AppSizes.iconMd,
                    color: AppColors.gray400,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: AppValidators.password,
            ),
            const SizedBox(height: AppSizes.xl),

            // Bouton connexion — gradient bleu→vert comme le frontend
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isLoading
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.secondaryLight],
                        ),
                  color: isLoading ? AppColors.gray300 : null,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: isLoading
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
                    onTap: isLoading ? null : onSubmit,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              AppStrings.loginButton,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: AppSizes.fontMd,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Badges Mobile Money
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Badge(
              color: AppColors.orangeMoney,
              label: 'Orange Money',
            ),
            const SizedBox(width: AppSizes.sm),
            _Badge(
              color: AppColors.mtnMoney,
              label: 'MTN Money',
            ),
            const SizedBox(width: AppSizes.sm),
            _Badge(
              color: AppColors.secondary,
              label: 'GNF',
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        const Text(
          '© 2026 DjoulaGest',
          style: TextStyle(
            fontSize: AppSizes.fontXs,
            color: AppColors.gray400,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
