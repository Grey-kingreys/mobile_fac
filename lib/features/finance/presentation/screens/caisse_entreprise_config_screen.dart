import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/errors/app_exception.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_button.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';
import 'package:djoulagest_mobile/shared/widgets/app_text_field.dart';

/// Configuration de la caisse de l'entreprise (niveau racine de la hiérarchie).
/// Réservé admin. La caisse est créée à la volée si elle n'existe pas encore
/// (cas des entreprises créées avant l'auto-création).
class CaisseEntrepriseConfigScreen extends ConsumerStatefulWidget {
  const CaisseEntrepriseConfigScreen({super.key});

  @override
  ConsumerState<CaisseEntrepriseConfigScreen> createState() =>
      _CaisseEntrepriseConfigScreenState();
}

class _CaisseEntrepriseConfigScreenState
    extends ConsumerState<CaisseEntrepriseConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  String _devise = 'GNF';
  num? _solde;
  bool _loading = true;
  bool _saving = false;

  static const _devises = ['GNF', 'USD', 'EUR'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get<Map<String, dynamic>>(
        ApiEndpoints.caisseEntrepriseMe,
      );
      final data = res.data ?? {};
      _nomCtrl.text = data['nom'] as String? ?? '';
      _devise = data['devise'] as String? ?? 'GNF';
      _solde = num.tryParse('${data['solde_actuel'] ?? ''}');
    } catch (_) {
      // 404 = pas encore de caisse (elle sera créée à la 1ʳᵉ sauvegarde).
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch<Map<String, dynamic>>(
        ApiEndpoints.caisseEntrepriseConfigurer,
        data: {'nom': _nomCtrl.text.trim(), 'devise': _devise},
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'Caisse entreprise configurée');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) AppSnackbar.error(context, _err(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _err(Object e) {
    if (e is DioException) {
      final inner = e.error;
      if (inner is ValidationException && inner.fieldErrors.isNotEmpty) {
        return inner.fieldErrors.values.first.first;
      }
      if (inner is AppException) return inner.message;
    }
    return 'Enregistrement impossible. Réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Caisse de l\'entreprise',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingPage),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: AppColors.infoLightBg,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
                          SizedBox(width: AppSizes.xs),
                          Expanded(
                            child: Text(
                              'La caisse de l\'entreprise est le niveau racine (permanente, '
                              'jamais fermée). Définissez son intitulé et sa devise.',
                              style: TextStyle(color: AppColors.gray700, fontSize: AppSizes.fontXs),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    AppTextField(
                      controller: _nomCtrl,
                      label: 'Intitulé de la caisse *',
                      hint: 'Ex : Caisse centrale',
                      prefixIcon: Icons.account_balance_outlined,
                      enabled: !_saving,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Intitulé requis' : null,
                    ),
                    const SizedBox(height: AppSizes.md),
                    DropdownButtonFormField<String>(
                      initialValue: _devise,
                      decoration: InputDecoration(
                        labelText: 'Devise *',
                        prefixIcon: const Icon(Icons.payments_outlined, size: AppSizes.iconMd),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                      items: _devises
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: _saving ? null : (v) => setState(() => _devise = v ?? 'GNF'),
                    ),
                    if (_solde != null) ...[
                      const SizedBox(height: AppSizes.md),
                      Text(
                        'Solde actuel : $_solde $_devise',
                        style: const TextStyle(
                            color: AppColors.gray500, fontSize: AppSizes.fontXs),
                      ),
                    ],
                    const SizedBox(height: AppSizes.xl),
                    AppButton(
                      label: 'Enregistrer',
                      onPressed: _saving ? null : _save,
                      isLoading: _saving,
                      gradient: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
