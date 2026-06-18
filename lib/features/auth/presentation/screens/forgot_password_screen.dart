import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/core/utils/validators.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:djoulagest_mobile/shared/widgets/app_button.dart';
import 'package:djoulagest_mobile/shared/widgets/app_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .forgotPassword(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSizes.md),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.authScaffoldBg,
        body: Container(
          constraints: const BoxConstraints.expand(),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.md),
                  // Bouton retour
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.gray700),
                    onPressed: () => context.go(AppRoutes.login),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Icône
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Titre
                  Center(
                    child: Text(
                      _sent ? 'Email envoyé !' : 'Mot de passe oublié',
                      style: const TextStyle(
                        fontSize: AppSizes.fontXl,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Center(
                    child: Text(
                      _sent
                          ? 'Vérifiez votre boîte mail et suivez le lien pour réinitialiser votre mot de passe.'
                          : 'Entrez votre email et nous vous enverrons un lien de réinitialisation.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        color: AppColors.gray500,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),

                  if (_sent) ...[
                    // État succès
                    Container(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.secondary, size: 24),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text(
                              'Email envoyé à ${_emailCtrl.text.trim()}',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500,
                                fontSize: AppSizes.fontSm,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    AppButton(
                      label: 'Retour à la connexion',
                      onPressed: () => context.go(AppRoutes.login),
                      variant: AppButtonVariant.outline,
                    ),
                  ] else ...[
                    // Formulaire
                    Container(
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
                        key: _formKey,
                        child: Column(
                          children: [
                            AppTextField(
                              controller: _emailCtrl,
                              label: 'Adresse email',
                              hint: 'votre@email.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: AppValidators.email,
                              enabled: !_loading,
                            ),
                            const SizedBox(height: AppSizes.lg),
                            AppButton(
                              label: 'Envoyer le lien',
                              onPressed: _loading ? null : _submit,
                              isLoading: _loading,
                              gradient: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text(
                          'Retour à la connexion',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: AppSizes.fontSm,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
