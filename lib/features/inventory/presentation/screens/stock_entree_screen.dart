import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/errors/app_exception.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_button.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';
import 'package:djoulagest_mobile/shared/widgets/app_text_field.dart';

/// Entrée de stock (approvisionnement) — ajoute une quantité à un produit dans
/// un dépôt. Pour un produit périmable, un lot (n° + date d'expiration) est créé
/// pour la gestion FEFO. Réservé gestionnaire_stock / admin (le backend filtre).
class StockEntreeScreen extends ConsumerStatefulWidget {
  const StockEntreeScreen({super.key});

  @override
  ConsumerState<StockEntreeScreen> createState() => _StockEntreeScreenState();
}

class _StockEntreeScreenState extends ConsumerState<StockEntreeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _numeroLotCtrl = TextEditingController();

  List<Map<String, dynamic>> _depots = [];
  List<Map<String, dynamic>> _produits = [];
  int? _depotId;
  int? _produitId;
  DateTime? _dateExpiration;
  bool _loadingData = true;
  bool _saving = false;

  bool get _produitPerimable {
    final p = _produits.firstWhere(
      (e) => e['id'] == _produitId,
      orElse: () => const {},
    );
    return p['est_perimable'] == true;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _quantiteCtrl.dispose();
    _referenceCtrl.dispose();
    _numeroLotCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final api = ref.read(apiClientProvider);
      final depotsRes = await api.get<Map<String, dynamic>>(
        ApiEndpoints.depots,
        queryParameters: {'page_size': 100, 'is_active': true},
      );
      final produitsRes = await api.get<Map<String, dynamic>>(
        ApiEndpoints.produits,
        queryParameters: {'page_size': 100},
      );
      if (!mounted) return;
      setState(() {
        _depots = List<Map<String, dynamic>>.from(
          (depotsRes.data?['results'] ?? []) as List,
        );
        _produits = List<Map<String, dynamic>>.from(
          (produitsRes.data?['results'] ?? []) as List,
        );
        _loadingData = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateExpiration ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) setState(() => _dateExpiration = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_depotId == null) {
      AppSnackbar.error(context, 'Sélectionnez un dépôt');
      return;
    }
    if (_produitId == null) {
      AppSnackbar.error(context, 'Sélectionnez un produit');
      return;
    }
    // Pour un produit périmable, le lot (n° + date) est nécessaire pour la FEFO.
    if (_produitPerimable &&
        (_numeroLotCtrl.text.trim().isEmpty || _dateExpiration == null)) {
      AppSnackbar.error(
        context,
        'Produit périmable : renseignez le n° de lot et la date d\'expiration.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final quantite = num.parse(_quantiteCtrl.text.replaceAll(',', '.'));
      await ref.read(inventoryRepositoryProvider).stockEntree(
            depot: _depotId!,
            produit: _produitId!,
            quantite: quantite,
            referenceDoc: _referenceCtrl.text.trim(),
            numeroLot: _produitPerimable ? _numeroLotCtrl.text.trim() : null,
            dateExpiration: _produitPerimable && _dateExpiration != null
                ? _fmtDate(_dateExpiration!)
                : null,
          );
      // Rafraîchir la liste des stocks.
      ref.invalidate(inventoryProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackbar.success(context, 'Entrée de stock enregistrée');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, _apiError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _apiError(Object e) {
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
      title: 'Entrée de stock',
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingPage),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Dépôt *'),
                    DropdownButtonFormField<int>(
                      initialValue: _depotId,
                      hint: const Text('Choisir un dépôt'),
                      decoration: _dec(Icons.warehouse_outlined),
                      items: _depots
                          .map((d) => DropdownMenuItem(
                                value: d['id'] as int,
                                child: Text(d['name'] as String? ?? '—'),
                              ))
                          .toList(),
                      onChanged: _saving ? null : (v) => setState(() => _depotId = v),
                      validator: (v) => v == null ? 'Dépôt requis' : null,
                    ),
                    const SizedBox(height: AppSizes.md),

                    _label('Produit *'),
                    DropdownButtonFormField<int>(
                      initialValue: _produitId,
                      isExpanded: true,
                      hint: const Text('Choisir un produit'),
                      decoration: _dec(Icons.inventory_2_outlined),
                      items: _produits
                          .map((p) => DropdownMenuItem(
                                value: p['id'] as int,
                                child: Text(
                                  '${p['nom'] ?? ''}${p['est_perimable'] == true ? ' (périmable)' : ''}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) => setState(() {
                                _produitId = v;
                                // Réinitialiser le lot si le nouveau produit n'est pas périmable.
                                if (!_produitPerimable) {
                                  _numeroLotCtrl.clear();
                                  _dateExpiration = null;
                                }
                              }),
                      validator: (v) => v == null ? 'Produit requis' : null,
                    ),
                    const SizedBox(height: AppSizes.md),

                    AppTextField(
                      controller: _quantiteCtrl,
                      label: 'Quantité *',
                      hint: 'Quantité reçue',
                      prefixIcon: Icons.add_box_outlined,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final q = num.tryParse((v ?? '').replaceAll(',', '.'));
                        if (q == null) return 'Quantité invalide';
                        if (q <= 0) return 'La quantité doit être positive';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.md),

                    AppTextField(
                      controller: _referenceCtrl,
                      label: 'Référence document (optionnel)',
                      hint: 'N° bon de réception, facture…',
                      prefixIcon: Icons.receipt_long_outlined,
                      enabled: !_saving,
                    ),

                    // ── Lot + expiration (produits périmables / FEFO) ─────────
                    if (_produitPerimable) ...[
                      const SizedBox(height: AppSizes.md),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.sm),
                        decoration: BoxDecoration(
                          color: AppColors.accentLightBg,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.event_busy_outlined, size: 16, color: AppColors.accent),
                            SizedBox(width: AppSizes.xs),
                            Expanded(
                              child: Text(
                                'Produit périmable : renseignez le lot et la date d\'expiration (FEFO).',
                                style: TextStyle(color: AppColors.gray700, fontSize: AppSizes.fontXs),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      AppTextField(
                        controller: _numeroLotCtrl,
                        label: 'N° de lot *',
                        hint: 'Ex : LOT-2026-001',
                        prefixIcon: Icons.tag_outlined,
                        enabled: !_saving,
                      ),
                      const SizedBox(height: AppSizes.md),
                      _label('Date d\'expiration *'),
                      InkWell(
                        onTap: _saving ? null : _pickDate,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        child: InputDecorator(
                          decoration: _dec(Icons.calendar_today_outlined),
                          child: Text(
                            _dateExpiration == null
                                ? 'Choisir une date'
                                : AppFormatters.dateLong(_dateExpiration!),
                            style: TextStyle(
                              color: _dateExpiration == null
                                  ? AppColors.gray400
                                  : AppColors.gray900,
                              fontSize: AppSizes.fontSm,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSizes.xl),
                    AppButton(
                      label: 'Enregistrer l\'entrée',
                      onPressed: _saving ? null : _save,
                      isLoading: _saving,
                      gradient: true,
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.xs),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w500,
            color: AppColors.gray700,
          ),
        ),
      );

  InputDecoration _dec(IconData icon) => InputDecoration(
        prefixIcon: Icon(icon, size: AppSizes.iconMd),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
      );
}
