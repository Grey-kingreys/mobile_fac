import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/providers/logistics_provider.dart';

class SignatureScreen extends ConsumerStatefulWidget {
  const SignatureScreen({super.key, required this.missionId});
  final int missionId;

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  late final SignatureController _sigController;
  final _motifController = TextEditingController();
  bool _hasLitige = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _sigController = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.gray900,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _sigController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Refus de signature → motif OBLIGATOIRE (règles universelles §2 + §7)
    if (_hasLitige) {
      if (_motifController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Le motif du litige est obligatoire (règle anti-fraude §2).'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      setState(() => _isSubmitting = true);
      try {
        await ref.read(logisticsRepositoryProvider).signatureArrivee(
              widget.missionId,
              refusSignature: true,
              motifLitige: _motifController.text.trim(),
            );

        await ref.read(missionsProvider.notifier).refresh();
        ref.invalidate(missionDetailProvider(widget.missionId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Litige déclaré — mission en statut Litige.'),
              backgroundColor: AppColors.danger,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }

    // Signature normale → canvas obligatoire
    if (!_sigController.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez apposer une signature avant de confirmer.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bytes = await _sigController.toPngBytes();
      if (bytes == null) throw Exception('Signature vide');
      final base64Sig = base64Encode(bytes);

      await ref.read(logisticsRepositoryProvider).signatureArrivee(
            widget.missionId,
            refusSignature: false,
            signatureBase64: base64Sig,
          );

      await ref.read(missionsProvider.notifier).refresh();
      ref.invalidate(missionDetailProvider(widget.missionId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arrivée confirmée avec signature.'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.gray200,
        foregroundColor: AppColors.gray700,
        title: const Text(
          'Signature d\'arrivée',
          style: TextStyle(
            color: AppColors.gray900,
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.fontLg,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Zone de signature (masquée en cas de refus) ────────────────
            if (!_hasLitige) ...[
              const Text(
                'Signature du destinataire',
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: Signature(
                    controller: _sigController,
                    height: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _sigController.clear(),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: AppSizes.iconSm),
                  label: const Text('Effacer'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gray500,
                    textStyle: const TextStyle(fontSize: AppSizes.fontSm),
                  ),
                ),
              ),
            ],

            // ─── Litige ─────────────────────────────────────────────────────
            const SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.gray100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _hasLitige,
                        onChanged: (v) => setState(() => _hasLitige = v),
                        thumbColor: WidgetStateProperty.resolveWith<Color?>(
                          (states) => states.contains(WidgetState.selected)
                              ? AppColors.danger
                              : null,
                        ),
                        trackColor: WidgetStateProperty.resolveWith<Color?>(
                          (states) => states.contains(WidgetState.selected)
                              ? AppColors.danger.withValues(alpha: 0.4)
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSizes.xs),
                      const Text(
                        'Signaler un litige',
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                  if (_hasLitige) ...[
                    const SizedBox(height: AppSizes.sm),
                    TextField(
                      controller: _motifController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Motif du litige *',
                        hintText: 'Ex: Colis endommagé, quantité manquante…',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                          borderSide:
                              const BorderSide(color: AppColors.gray200),
                        ),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ─── Bouton confirmer ────────────────────────────────────────────
            const SizedBox(height: AppSizes.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_isSubmitting
                    ? 'Envoi…'
                    : _hasLitige
                        ? 'Déclarer le litige'
                        : 'Confirmer l\'arrivée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _hasLitige ? AppColors.danger : AppColors.secondary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.secondary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.md + 2),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd)),
                  textStyle: const TextStyle(
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.w600,
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
