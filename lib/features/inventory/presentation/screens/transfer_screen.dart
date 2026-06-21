import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/depots/presentation/providers/depots_provider.dart';
import 'package:djoulagest_mobile/features/inventory/domain/entities/stock_entity.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:djoulagest_mobile/features/products/presentation/providers/products_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

const _transferWriteRoles = {'admin', 'gestionnaire_stock'};

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  String? _currentStatut;

  static const _filters = [
    ('Tous', null),
    ('En attente', 'en_attente'),
    ('En transit', 'en_transit'),
    ('Reçus', 'recu'),
    ('Annulés', 'annule'),
  ];

  @override
  Widget build(BuildContext context) {
    final transfertsAsync = ref.watch(transfertsProvider(_currentStatut));
    final role = ref.watch(effectiveRoleProvider);
    final canCreate = _transferWriteRoles.contains(role);

    return AppScaffold(
      title: 'Transferts inter-dépôts',
      showBottomNav: true,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateSheet(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nouveau transfert',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Column(
        children: [
          // ─── Filtres statut ──────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingPage, vertical: 4),
              itemCount: _filters.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSizes.xs),
              itemBuilder: (ctx, i) {
                final (label, value) = _filters[i];
                final selected = _currentStatut == value;
                return GestureDetector(
                  onTap: () => setState(() => _currentStatut = value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.xs),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.gray100,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.gray200,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: AppSizes.fontXs,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.primary
                            : AppColors.gray500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ─── Contenu ─────────────────────────────────────────────────────
          Expanded(
            child: transfertsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    const Text('Impossible de charger les transferts',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(transfertsProvider(_currentStatut)),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (transferts) {
                if (transferts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swap_horiz_rounded,
                              size: AppSizes.iconXxl,
                              color: AppColors.gray200),
                          SizedBox(height: AppSizes.md),
                          Text('Aucun transfert',
                              style: TextStyle(color: AppColors.gray500)),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(transfertsProvider(_currentStatut)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingPage, 0, AppSizes.paddingPage,
                        AppSizes.xxl),
                    itemCount: transferts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (ctx, i) =>
                        _TransfertTile(transfert: transferts[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTransfertSheet(
        onCreated: () {
          ref.invalidate(transfertsProvider(_currentStatut));
        },
      ),
    );
  }
}

// ─── Formulaire création transfert ───────────────────────────────────────────

class _LigneState {
  int? produitId;
  String produitNom = '';
  final TextEditingController quantiteCtrl = TextEditingController();

  void dispose() => quantiteCtrl.dispose();
}

class _CreateTransfertSheet extends ConsumerStatefulWidget {
  const _CreateTransfertSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateTransfertSheet> createState() =>
      _CreateTransfertSheetState();
}

class _CreateTransfertSheetState
    extends ConsumerState<_CreateTransfertSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  int? _depotSourceId;
  int? _depotDestinationId;
  final List<_LigneState> _lignes = [_LigneState()];
  bool _loading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final l in _lignes) {
      l.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final depotsAsync = ref.watch(depotsProvider);
    final produitsAsync = ref.watch(productsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSizes.paddingPage, AppSizes.md, AppSizes.paddingPage, bottom + AppSizes.lg),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Nouveau transfert',
                style: TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Dépôt source
              _DropdownField<int>(
                label: 'Dépôt source *',
                selectedValue: _depotSourceId,
                items: depotsAsync.when(
                  data: (s) => s.depots
                      .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.nom, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  loading: () => [],
                  error: (_, __) => [],
                ),
                isLoading: depotsAsync.isLoading,
                onChanged: (v) => setState(() => _depotSourceId = v),
                validator: (v) =>
                    v == null ? 'Sélectionner le dépôt source' : null,
              ),
              const SizedBox(height: AppSizes.md),

              // Dépôt destination
              _DropdownField<int>(
                label: 'Dépôt destination *',
                selectedValue: _depotDestinationId,
                items: depotsAsync.when(
                  data: (s) => s.depots
                      .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.nom, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  loading: () => [],
                  error: (_, __) => [],
                ),
                isLoading: depotsAsync.isLoading,
                onChanged: (v) => setState(() => _depotDestinationId = v),
                validator: (v) =>
                    v == null ? 'Sélectionner le dépôt destination' : null,
              ),
              const SizedBox(height: AppSizes.md),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: _inputDeco('Notes (optionnel)'),
              ),
              const SizedBox(height: AppSizes.lg),

              // ─── Lignes ────────────────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Articles à transférer',
                    style: TextStyle(
                      fontSize: AppSizes.fontMd,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _lignes.add(_LigneState())),
                    icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                    label: const Text('Ajouter',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),

              ..._lignes.asMap().entries.map((entry) {
                final i = entry.key;
                final ligne = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Article ${i + 1}',
                              style: const TextStyle(
                                  fontSize: AppSizes.fontSm,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray700),
                            ),
                            const Spacer(),
                            if (_lignes.length > 1)
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 40, minHeight: 40),
                                icon: const Icon(Icons.close,
                                    size: 18, color: AppColors.gray400),
                                onPressed: () {
                                  setState(() {
                                    _lignes[i].dispose();
                                    _lignes.removeAt(i);
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xs),
                        _DropdownField<int>(
                          label: 'Produit *',
                          selectedValue: ligne.produitId,
                          items: produitsAsync.when(
                            data: (s) => s.products
                                .map((p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(
                                          '${p.reference} — ${p.nom}',
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            loading: () => [],
                            error: (_, __) => [],
                          ),
                          isLoading: produitsAsync.isLoading,
                          onChanged: (v) => setState(() => ligne.produitId = v),
                          validator: (v) =>
                              v == null ? 'Sélectionner un produit' : null,
                        ),
                        const SizedBox(height: AppSizes.xs),
                        TextFormField(
                          controller: ligne.quantiteCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDeco('Quantité *'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Obligatoire';
                            final n = num.tryParse(v.trim());
                            if (n == null || n <= 0) return 'Quantité invalide';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSizes.md),

              // Bouton soumettre
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Créer le transfert',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: AppSizes.fontMd),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final lignes = _lignes.map((l) => {
          'produit': l.produitId!,
          'quantite_envoyee': num.parse(l.quantiteCtrl.text.trim()),
        }).toList();

    try {
      await ref.read(inventoryRepositoryProvider).createTransfert(
            depotSource: _depotSourceId!,
            depotDestination: _depotDestinationId!,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            lignes: lignes,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfert créé avec succès'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Dropdown réutilisable ────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.selectedValue,
    required this.items,
    required this.isLoading,
    required this.onChanged,
    required this.validator,
  });

  final String label;
  final T? selectedValue;
  final List<DropdownMenuItem<T>> items;
  final bool isLoading;
  final void Function(T?) onChanged;
  final String? Function(T?) validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      isExpanded: true,
      hint: isLoading
          ? const Row(children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Chargement…'),
            ])
          : null,
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

// ─── Tuile transfert (inchangée) ─────────────────────────────────────────────

class _TransfertTile extends StatelessWidget {
  const _TransfertTile({required this.transfert});
  final TransfertEntity transfert;

  Color get _color {
    return switch (transfert.statut) {
      'en_attente' => AppColors.accent,
      'en_transit' => AppColors.primary,
      'recu' => AppColors.secondary,
      'annule' => AppColors.gray400,
      _ => AppColors.gray500,
    };
  }

  IconData get _icon {
    return switch (transfert.statut) {
      'en_attente' => Icons.schedule_rounded,
      'en_transit' => Icons.local_shipping_rounded,
      'recu' => Icons.check_circle_rounded,
      'annule' => Icons.cancel_rounded,
      _ => Icons.swap_horiz_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(_icon, color: color, size: AppSizes.iconMd),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      transfert.numero,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        transfert.statutLabel,
                        style: TextStyle(
                          fontSize: AppSizes.fontXs,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked_rounded,
                        size: 12, color: AppColors.gray400),
                    const SizedBox(width: 4),
                    Text(
                      transfert.depotSourceCode,
                      style: const TextStyle(
                          fontSize: AppSizes.fontXs, color: AppColors.gray500),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 12, color: AppColors.gray300),
                    ),
                    const Icon(Icons.location_on_rounded,
                        size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      transfert.depotDestinationCode,
                      style: const TextStyle(
                          fontSize: AppSizes.fontXs, color: AppColors.gray500),
                    ),
                    const Spacer(),
                    Text(
                      '${transfert.nbLignes} article${transfert.nbLignes > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: AppSizes.fontXs, color: AppColors.gray400),
                    ),
                  ],
                ),
                if (transfert.dateEnvoi != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Envoyé le ${AppFormatters.dateShort(transfert.dateEnvoi!)}',
                    style: const TextStyle(
                        fontSize: AppSizes.fontXs, color: AppColors.gray400),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
