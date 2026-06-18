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

/// Réinitialisation du mot de passe via le lien email.
///
/// Accepte les paramètres de l'URL : `?uid=...&token=...`
/// Si absents, l'utilisateur peut les saisir manuellement.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.token,
  });

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenCtrl;
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _done = false;

  bool get _hasPrefilledToken => widget.token?.isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController(text: widget.token ?? '');
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).resetPassword(
            token: _tokenCtrl.text.trim(),
            newPassword: _passCtrl.text,
            newPasswordConfirm: _confirmCtrl.text,
          );
      if (mounted) setState(() => _done = true);
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.gray700),
                    onPressed: () => context.go(AppRoutes.login),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSizes.xl),

                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: (_done ? AppColors.secondary : AppColors.primary)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _done
                            ? Icons.check_circle_rounded
                            : Icons.lock_outline_rounded,
                        size: 36,
                        color: _done ? AppColors.secondary : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  Center(
                    child: Text(
                      _done ? 'Mot de passe mis à jour !' : 'Nouveau mot de passe',
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
                      _done
                          ? 'Votre mot de passe a été modifié. Vous pouvez maintenant vous connecter.'
                          : 'Choisissez un nouveau mot de passe sécurisé.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        color: AppColors.gray500,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),

                  if (_done) ...[
                    AppButton(
                      label: 'Se connecter',
                      onPressed: () => context.go(AppRoutes.login),
                      gradient: true,
                    ),
                  ] else ...[
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
                            // Token (masqué si pré-rempli via URL)
                            if (!_hasPrefilledToken) ...[
                              AppTextField(
                                controller: _tokenCtrl,
                                label: 'Token de réinitialisation',
                                hint: 'Fourni dans le lien email',
                                prefixIcon: Icons.vpn_key_outlined,
                                enabled: !_loading,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Requis'
                                    : null,
                              ),
                              const SizedBox(height: AppSizes.md),
                            ],

                            // Nouveau mot de passe
                            AppTextField(
                              controller: _passCtrl,
                              label: 'Nouveau mot de passe',
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePass,
                              enabled: !_loading,
                              textInputAction: TextInputAction.next,
                              validator: AppValidators.password,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: AppSizes.iconMd,
                                  color: AppColors.gray400,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),

                            // Confirmer
                            AppTextField(
                              controller: _confirmCtrl,
                              label: 'Confirmer le mot de passe',
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscureConfirm,
                              enabled: !_loading,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) => AppValidators.confirmPassword(
                                  v, _passCtrl.text),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: AppSizes.iconMd,
                                  color: AppColors.gray400,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            const SizedBox(height: AppSizes.lg),

                            AppButton(
                              label: 'Réinitialiser le mot de passe',
                              onPressed: _loading ? null : _submit,
                              isLoading: _loading,
                              gradient: true,
                            ),
                          ],
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
