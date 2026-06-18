import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

/// Écran de configuration 2FA — accessible depuis le profil.
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  // Étapes : 'select' → 'verify'
  String _step = 'select';
  String _selectedMethod = 'totp';

  // Données TOTP (retournées par le backend)
  String? _qrCode;     // data:image/png;base64,...
  String? _totpSecret; // clé manuelle

  // Saisie du code de vérification
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();
  bool get _codeComplete =>
      _code.length == 6 &&
      _code.split('').every((c) => RegExp(r'\d').hasMatch(c));

  Future<void> _initSetup() async {
    setState(() => _loading = true);

    final result =
        await ref.read(authProvider.notifier).setup2fa(_selectedMethod);

    setState(() => _loading = false);

    if (!mounted) return;

    if (result.error != null) {
      _showError(result.error!);
      return;
    }

    final data = result.data ?? {};
    setState(() {
      _qrCode = data['qr_code'] as String?;
      _totpSecret = data['secret'] as String?;
      _step = 'verify';
    });
  }

  Future<void> _confirmSetup() async {
    if (!_codeComplete || _loading) return;
    setState(() => _loading = true);

    final error = await ref.read(authProvider.notifier).verify2faSetup(
          method: _selectedMethod,
          code: _code,
        );

    setState(() => _loading = false);

    if (!mounted) return;

    if (error != null) {
      _showError(error);
      _clearCode();
    } else {
      _showSuccess('2FA activée avec succès !');
      context.pop();
    }
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
    return AppScaffold(
      title: 'Configurer la 2FA',
      showBottomNav: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: _step == 'select' ? _buildSelectStep() : _buildVerifyStep(),
      ),
    );
  }

  // ── Étape 1 : Choisir la méthode ─────────────────────────────────────────

  Widget _buildSelectStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSizes.md),
        _InfoCard(
          icon: Icons.security_outlined,
          title: 'Authentification à double facteur',
          body: 'Ajoutez une couche de sécurité supplémentaire à votre compte. '
              'Choisissez votre méthode préférée.',
        ),
        const SizedBox(height: AppSizes.lg),
        const Text(
          'Choisissez votre méthode',
          style: TextStyle(
            fontSize: AppSizes.fontLg,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Carte TOTP
        _MethodCard(
          selected: _selectedMethod == 'totp',
          icon: Icons.qr_code_outlined,
          title: 'Application Authy',
          subtitle: 'Code généré par l\'application — fonctionne même hors connexion.',
          onTap: () => setState(() => _selectedMethod = 'totp'),
          recommended: true,
        ),
        const SizedBox(height: AppSizes.sm),

        // Carte Email
        _MethodCard(
          selected: _selectedMethod == 'email',
          icon: Icons.email_outlined,
          title: 'Code par email',
          subtitle: 'Un code à 6 chiffres vous est envoyé à chaque connexion.',
          onTap: () => setState(() => _selectedMethod = 'email'),
        ),
        const SizedBox(height: AppSizes.xl),

        _GradientButton(
          label: 'Continuer',
          loading: _loading,
          onTap: _initSetup,
        ),
      ],
    );
  }

  // ── Étape 2 : Scanner le QR / saisir le code ─────────────────────────────

  Widget _buildVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSizes.md),

        if (_selectedMethod == 'totp') ...[
          const Text(
            'Scannez le QR code',
            style: TextStyle(
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'Ouvrez Authy (ou Google Authenticator) et scannez ce QR code.',
            style: TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
          ),
          const SizedBox(height: AppSizes.lg),

          // QR code
          if (_qrCode != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Image.memory(
                  Uri.parse(_qrCode!).data!.contentAsBytes(),
                  width: 200,
                  height: 200,
                ),
              ),
            ),

          if (_totpSecret != null) ...[
            const SizedBox(height: AppSizes.md),
            const Text(
              'Ou saisissez manuellement la clé :',
              style: TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xs),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _totpSecret!));
                _showSuccess('Clé copiée dans le presse-papier.');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _totpSecret!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: AppSizes.fontSm,
                        color: AppColors.gray700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    const Icon(Icons.copy_outlined, size: 16, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.xl),
          const Text(
            'Entrez le code affiché dans Authy pour confirmer :',
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          const Text(
            'Vérifiez votre email',
            style: TextStyle(
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'Un code à 6 chiffres a été envoyé à votre adresse email. Saisissez-le pour confirmer.',
            style: TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
          ),
        ],

        const SizedBox(height: AppSizes.lg),

        // Saisie OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (i) => _OtpSetupBox(
              controller: _ctrls[i],
              focusNode: _nodes[i],
              onChanged: (v) {
                if (v.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
                if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                setState(() {});
                if (_codeComplete) _confirmSetup();
              },
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xl),

        _GradientButton(
          label: 'Activer la 2FA',
          loading: _loading,
          enabled: _codeComplete,
          onTap: _confirmSetup,
        ),
        const SizedBox(height: AppSizes.sm),
        TextButton(
          onPressed: () => setState(() {
            _step = 'select';
            _qrCode = null;
            _totpSecret = null;
            _clearCode();
          }),
          child: const Text(
            'Changer de méthode',
            style: TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
          ),
        ),
      ],
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLightBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontSize: AppSizes.fontSm,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.gray600,
                    fontSize: AppSizes.fontXs,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.recommended = false,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLightBg : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.gray200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.gray400,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppSizes.fontMd,
                          color: selected ? AppColors.primary : AppColors.gray900,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: AppSizes.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: const Text(
                            'Recommandé',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: AppSizes.fontXs,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    return SizedBox(
      height: AppSizes.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.secondaryLight])
              : null,
          color: active ? null : AppColors.gray300,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: InkWell(
            onTap: active ? onTap : null,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: AppSizes.fontMd,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpSetupBox extends StatelessWidget {
  const _OtpSetupBox({
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
            borderSide: const BorderSide(color: AppColors.gray200),
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
