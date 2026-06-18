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

/// Écran de première connexion.
///
/// L'admin crée le compte, génère un `first_login_token` et l'envoie à
/// l'utilisateur. Celui-ci saisit ce token + son nouveau mot de passe ici.
/// Accepte `?token=...` comme query param (deep link depuis l'email).
class FirstLoginScreen extends ConsumerStatefulWidget {
  const FirstLoginScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<FirstLoginScreen> createState() => _FirstLoginScreenState();
}

class _FirstLoginScreenState extends ConsumerState<FirstLoginScreen> {
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
      await ref.read(authProvider.notifier).firstLogin(
            token: _tokenCtrl.text.trim(),
            password: _passCtrl.text,
            passwordConfirm: _confirmCtrl.text,
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.xxl),

                  // Icône + titre
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryLight, AppColors.secondaryLight],
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  Text(
                    _done ? 'Mot de passe défini !' : 'Bienvenue sur DjoulaGest',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppSizes.fontXl,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    _done
                        ? 'Votre compte est prêt. Connectez-vous avec votre email et votre nouveau mot de passe.'
                        : 'Votre administrateur vous a envoyé un token d\'activation. Définissez votre mot de passe pour commencer.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSm,
                      color: AppColors.gray500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),

                  if (_done) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: AppColors.secondary, size: 24),
                          SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text(
                              'Compte activé avec succès',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                                fontSize: AppSizes.fontSm,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Activation du compte',
                              style: TextStyle(
                                fontSize: AppSizes.fontMd,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                            const SizedBox(height: AppSizes.xs),
                            const Text(
                              'Saisissez le token reçu et choisissez votre mot de passe.',
                              style: TextStyle(
                                fontSize: AppSizes.fontSm,
                                color: AppColors.gray500,
                              ),
                            ),
                            const SizedBox(height: AppSizes.lg),

                            // Token (masqué si pré-rempli)
                            if (!_hasPrefilledToken) ...[
                              AppTextField(
                                controller: _tokenCtrl,
                                label: 'Token d\'activation',
                                hint: 'Token fourni par votre administrateur',
                                prefixIcon: Icons.vpn_key_outlined,
                                enabled: !_loading,
                                textInputAction: TextInputAction.next,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Le token est requis'
                                    : null,
                              ),
                              const SizedBox(height: AppSizes.md),
                            ] else ...[
                              // Confirmation visuelle que le token est chargé
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.md, vertical: AppSizes.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusSm),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.vpn_key_outlined,
                                        size: 16, color: AppColors.primary),
                                    const SizedBox(width: AppSizes.xs),
                                    const Text(
                                      'Token d\'activation chargé',
                                      style: TextStyle(
                                        fontSize: AppSizes.fontSm,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.check_circle_rounded,
                                        size: 16, color: AppColors.primary),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSizes.md),
                            ],

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
                            const SizedBox(height: AppSizes.xl),

                            AppButton(
                              label: 'Activer mon compte',
                              onPressed: _loading ? null : _submit,
                              isLoading: _loading,
                              gradient: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text(
                          'Retour à la connexion',
                          style: TextStyle(
                            color: AppColors.gray500,
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
