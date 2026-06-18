import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';

/// Écran de vérification 2FA — deuxième étape du login.
/// Affiché automatiquement par le router quand twoFactorPendingProvider != null.
class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();
  bool get _codeComplete => _code.length == 6 && _code.split('').every((c) => RegExp(r'\d').hasMatch(c));

  Future<void> _submit() async {
    if (!_codeComplete || _loading) return;
    setState(() => _loading = true);

    final error = await ref
        .read(authProvider.notifier)
        .verify2faLogin(code: _code);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showError(error);
      _clearCode();
    }
    // Si succès, le router redirige automatiquement vers /dashboard
  }

  Future<void> _resend() async {
    if (_resending || _resendCooldown > 0) return;
    setState(() => _resending = true);

    final error = await ref.read(authProvider.notifier).resend2faCode();

    if (!mounted) return;
    setState(() => _resending = false);

    if (error != null) {
      _showError(error);
    } else {
      _showSuccess('Nouveau code envoyé.');
      _startCooldown();
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  void _clearCode() {
    for (final c in _ctrls) {
      c.clear();
    }
    _nodes.first.requestFocus();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppSizes.md),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.secondary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppSizes.md),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(twoFactorPendingProvider);
    final isEmail = pending?.method == 'email';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
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
              child: Column(
                children: [
                  const SizedBox(height: AppSizes.xxl),
                  // Icône
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  const Text(
                    'Vérification en deux étapes',
                    style: TextStyle(
                      fontSize: AppSizes.fontXl,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    isEmail
                        ? 'Entrez le code à 6 chiffres envoyé à votre adresse email.'
                        : 'Ouvrez votre application Authy et entrez le code affiché.',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSm,
                      color: AppColors.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.xxl),

                  // Saisie 6 chiffres
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
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (i) => _OtpBox(
                            controller: _ctrls[i],
                            focusNode: _nodes[i],
                            onChanged: (v) {
                              if (v.isNotEmpty && i < 5) {
                                _nodes[i + 1].requestFocus();
                              }
                              if (v.isEmpty && i > 0) {
                                _nodes[i - 1].requestFocus();
                              }
                              setState(() {});
                              if (_codeComplete) _submit();
                            },
                          )),
                        ),
                        const SizedBox(height: AppSizes.xl),
                        SizedBox(
                          width: double.infinity,
                          height: AppSizes.buttonHeight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: (_loading || !_codeComplete)
                                  ? null
                                  : const LinearGradient(
                                      colors: [AppColors.primaryLight, AppColors.secondaryLight],
                                    ),
                              color: (_loading || !_codeComplete) ? AppColors.gray300 : null,
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              child: InkWell(
                                onTap: (_loading || !_codeComplete) ? null : _submit,
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Vérifier',
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

                  if (isEmail) ...[
                    const SizedBox(height: AppSizes.lg),
                    _resendCooldown > 0
                        ? Text(
                            'Renvoyer dans $_resendCooldown s',
                            style: const TextStyle(
                              color: AppColors.gray400,
                              fontSize: AppSizes.fontSm,
                            ),
                          )
                        : TextButton(
                            onPressed: _resending ? null : _resend,
                            child: _resending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    'Renvoyer le code par email',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: AppSizes.fontSm,
                                    ),
                                  ),
                          ),
                  ],
                  const SizedBox(height: AppSizes.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.gray900,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.gray50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: BorderSide(color: AppColors.gray200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
