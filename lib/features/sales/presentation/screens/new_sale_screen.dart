import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/sales/domain/entities/client_entity.dart';
import 'package:djoulagest_mobile/features/sales/presentation/providers/sales_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

// ─── Modèle local d'une ligne de vente ───────────────────────────────────────

class _LigneVente {
  _LigneVente({
    required this.produitId,
    required this.produitNom,
    required this.prixUnitaire,
    required this.quantite,
    this.uniteSymbole,
  });

  final int produitId;
  final String produitNom;
  final num prixUnitaire;
  num quantite;
  final String? uniteSymbole;

  num get total => prixUnitaire * quantite;
}

// ─── Écran principal ──────────────────────────────────────────────────────────

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  ClientEntity? _selectedClient;
  final List<_LigneVente> _lignes = [];
  String _modePaiement = 'especes';
  final _remiseCtrl = TextEditingController(text: '0');
  final _montantPayeCtrl = TextEditingController();
  final _referencePaymentCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  static const _modesAvecReference = {'orange_money', 'mtn_money', 'virement'};

  static const _modes = [
    ('Espèces', 'especes', Icons.payments_rounded),
    ('Orange Money', 'orange_money', Icons.phone_android_rounded),
    ('MTN Money', 'mtn_money', Icons.smartphone_rounded),
    ('Virement', 'virement', Icons.account_balance_rounded),
  ];

  @override
  void dispose() {
    _remiseCtrl.dispose();
    _montantPayeCtrl.dispose();
    _referencePaymentCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  num get _sousTotal =>
      _lignes.fold<num>(0, (sum, l) => sum + l.total);

  num get _remise => num.tryParse(_remiseCtrl.text) ?? 0;

  num get _total => (_sousTotal - _remise).clamp(0, double.infinity);

  Future<void> _choisirClient() async {
    final client = await showModalBottomSheet<ClientEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ClientPickerSheet(),
    );
    if (client != null && mounted) {
      setState(() => _selectedClient = client);
    }
  }

  Future<void> _ajouterProduit() async {
    final produit = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProductPickerSheet(),
    );
    if (produit == null || !mounted) return;
    final existing = _lignes
        .where((l) => l.produitId == (produit['id'] as int))
        .firstOrNull;
    if (existing != null) {
      setState(() => existing.quantite += 1);
    } else {
      setState(() => _lignes.add(_LigneVente(
            produitId: produit['id'] as int,
            produitNom: produit['nom'] as String,
            prixUnitaire: produit['prix_vente'] as num,
            quantite: 1,
            uniteSymbole: produit['unite_symbole'] as String?,
          )));
    }
    _montantPayeCtrl.text = _total.toStringAsFixed(0);
  }

  Future<void> _valider() async {
    final user = ref.read(effectiveUserProvider);
    final depotId = user?.depotId;

    if (depotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Impossible de créer une vente : aucun dépôt associé'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    if (_lignes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ajoutez au moins un produit'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    final montantPaye = num.tryParse(_montantPayeCtrl.text) ?? 0;
    final needsRef = _modesAvecReference.contains(_modePaiement);
    final referenceVal = _referencePaymentCtrl.text.trim();

    if (needsRef && referenceVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La référence de transaction est obligatoire pour ce mode de paiement'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(salesRepositoryProvider).createSale(
            depot: depotId,
            client: _selectedClient?.id,
            modePaiement: _modePaiement,
            modePaiementInitial: _modePaiement,
            lignes: _lignes
                .map((l) => {
                      'produit': l.produitId,
                      'quantite': l.quantite,
                      'prix_unitaire_ht': l.prixUnitaire,
                    })
                .toList(),
            remise: _remise,
            montantPaye: montantPaye,
            referencePaiement: needsRef ? referenceVal : null,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );

      ref.read(salesProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vente créée avec succès'),
          backgroundColor: AppColors.secondary,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nouvelle vente',
      showBottomNav: false,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingPage, AppSizes.md,
                  AppSizes.paddingPage, AppSizes.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Client (optionnel) ──────────────────────────────
                  const _SectionTitle(title: 'Client (optionnel)'),
                  const SizedBox(height: AppSizes.xs),
                  GestureDetector(
                    onTap: _choisirClient,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedClient != null
                                ? Icons.person_rounded
                                : Icons.person_add_rounded,
                            color: _selectedClient != null
                                ? AppColors.primary
                                : AppColors.gray400,
                            size: AppSizes.iconMd,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text(
                              _selectedClient?.nomComplet ??
                                  'Choisir un client…',
                              style: TextStyle(
                                color: _selectedClient != null
                                    ? AppColors.gray900
                                    : AppColors.gray400,
                                fontSize: AppSizes.fontSm,
                              ),
                            ),
                          ),
                          if (_selectedClient != null)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedClient = null),
                              child: const Icon(Icons.close_rounded,
                                  size: AppSizes.iconSm,
                                  color: AppColors.gray400),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // ─── Produits ────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                          child: _SectionTitle(title: 'Produits')),
                      TextButton.icon(
                        onPressed: _ajouterProduit,
                        icon: const Icon(Icons.add_rounded,
                            size: AppSizes.iconSm),
                        label: const Text('Ajouter'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xs),

                  if (_lignes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: const Center(
                        child: Text(
                          'Aucun produit ajouté',
                          style: TextStyle(
                              color: AppColors.gray400,
                              fontSize: AppSizes.fontSm),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_lignes.length, (i) {
                      final ligne = _lignes[i];
                      return Container(
                        margin:
                            const EdgeInsets.only(bottom: AppSizes.xs),
                        padding: const EdgeInsets.all(AppSizes.sm + 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(color: AppColors.gray100),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ligne.produitNom,
                                    style: const TextStyle(
                                      fontSize: AppSizes.fontSm,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray900,
                                    ),
                                  ),
                                  Text(
                                    AppFormatters.gnf(ligne.prixUnitaire),
                                    style: const TextStyle(
                                        fontSize: AppSizes.fontXs,
                                        color: AppColors.gray500),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (ligne.quantite <= 1) {
                                      setState(
                                          () => _lignes.removeAt(i));
                                    } else {
                                      setState(
                                          () => ligne.quantite -= 1);
                                    }
                                    _montantPayeCtrl.text =
                                        _total.toStringAsFixed(0);
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.gray100,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                        Icons.remove_rounded,
                                        size: 16,
                                        color: AppColors.gray600),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.sm),
                                  child: Text(
                                    '${ligne.quantite.toInt()}',
                                    style: const TextStyle(
                                      fontSize: AppSizes.fontSm,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.gray900,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => ligne.quantite += 1);
                                    _montantPayeCtrl.text =
                                        _total.toStringAsFixed(0);
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.add_rounded,
                                        size: 16,
                                        color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              AppFormatters.gnf(ligne.total),
                              style: const TextStyle(
                                fontSize: AppSizes.fontSm,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: AppSizes.lg),

                  // ─── Mode de paiement ────────────────────────────────
                  const _SectionTitle(title: 'Mode de paiement'),
                  const SizedBox(height: AppSizes.xs),
                  Wrap(
                    spacing: AppSizes.xs,
                    runSpacing: AppSizes.xs,
                    children: _modes.map((m) {
                      final (label, value, icon) = m;
                      final selected = _modePaiement == value;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _modePaiement = value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm + 4,
                              vertical: AppSizes.xs + 2),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.gray200,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon,
                                  size: 14,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.gray400),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: AppSizes.fontXs,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.gray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // ─── Référence de transaction (Orange Money / MTN / Virement) ─
                  if (_modesAvecReference.contains(_modePaiement)) ...[
                    const SizedBox(height: AppSizes.sm),
                    TextField(
                      controller: _referencePaymentCtrl,
                      decoration: InputDecoration(
                        labelText: 'Référence de transaction *',
                        hintText: 'ID opérateur (obligatoire)',
                        labelStyle: const TextStyle(
                            fontSize: AppSizes.fontXs, color: AppColors.gray500),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            borderSide: const BorderSide(color: AppColors.danger)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            borderSide: const BorderSide(color: AppColors.danger)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            borderSide: const BorderSide(color: AppColors.primary)),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.lg),

                  // ─── Remise + Montant payé ───────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _NumericField(
                          controller: _remiseCtrl,
                          label: 'Remise (GNF)',
                          onChanged: (_) => setState(() {
                            _montantPayeCtrl.text =
                                _total.toStringAsFixed(0);
                          }),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: _NumericField(
                          controller: _montantPayeCtrl,
                          label: 'Montant payé (GNF)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // ─── Notes ──────────────────────────────────────────
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Notes (optionnel)',
                      hintStyle: const TextStyle(
                          color: AppColors.gray400,
                          fontSize: AppSizes.fontSm),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(AppSizes.md),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide:
                              const BorderSide(color: AppColors.gray200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide:
                              const BorderSide(color: AppColors.gray200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide:
                              const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // ─── Récapitulatif ──────────────────────────────────
                  if (_lignes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primary.withValues(alpha: 0.05),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                            color: AppColors.primary
                                .withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          _RecapRow(
                              label: 'Sous-total',
                              value:
                                  AppFormatters.gnf(_sousTotal)),
                          if (_remise > 0) ...[
                            const SizedBox(height: AppSizes.xs),
                            _RecapRow(
                                label: 'Remise',
                                value:
                                    '− ${AppFormatters.gnf(_remise)}',
                                valueColor: AppColors.danger),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: AppSizes.xs),
                            child: Divider(color: AppColors.gray200),
                          ),
                          _RecapRow(
                            label: 'Total TTC',
                            value: AppFormatters.gnf(_total),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Bouton Valider ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, AppSizes.sm,
                AppSizes.paddingPage, AppSizes.md),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _valider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.gray200,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.md),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppSizes.radiusMd)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _lignes.isEmpty
                            ? 'Valider la vente'
                            : 'Valider — ${AppFormatters.gnf(_total)}',
                        style: const TextStyle(
                            fontSize: AppSizes.fontMd,
                            fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sélecteur client (modal) ─────────────────────────────────────────────────

class _ClientPickerSheet extends ConsumerStatefulWidget {
  const _ClientPickerSheet();

  @override
  ConsumerState<_ClientPickerSheet> createState() =>
      _ClientPickerSheetState();
}

class _ClientPickerSheetState extends ConsumerState<_ClientPickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: AppSizes.sm),
              child: _SheetHandle(),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingPage),
              child: Column(
                children: [
                  const Text('Choisir un client',
                      style: TextStyle(
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900)),
                  const SizedBox(height: AppSizes.sm),
                  TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (v) =>
                        ref.read(clientsProvider.notifier).search(v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher…',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.gray400),
                      filled: true,
                      fillColor: AppColors.gray100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.sm),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: clientsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                    child: Text('Erreur de chargement',
                        style: TextStyle(color: AppColors.gray500))),
                data: (state) => ListView.builder(
                  controller: scrollCtrl,
                  itemCount: state.clients.length,
                  itemBuilder: (ctx, i) {
                    final c = state.clients[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.secondary.withValues(alpha: 0.1),
                        child: Text(
                          c.nomComplet.isNotEmpty
                              ? c.nomComplet[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(c.nomComplet,
                          style: const TextStyle(
                              fontSize: AppSizes.fontSm,
                              fontWeight: FontWeight.w600)),
                      subtitle: c.telephone != null
                          ? Text(c.telephone!,
                              style: const TextStyle(
                                  fontSize: AppSizes.fontXs,
                                  color: AppColors.gray500))
                          : null,
                      onTap: () => Navigator.of(context).pop(c),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sélecteur produit (modal) ────────────────────────────────────────────────

class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet();

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState
    extends ConsumerState<_ProductPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsSearchProvider(_search));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: AppSizes.sm),
              child: _SheetHandle(),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingPage),
              child: Column(
                children: [
                  const Text('Choisir un produit',
                      style: TextStyle(
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900)),
                  const SizedBox(height: AppSizes.sm),
                  TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit…',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.gray400),
                      filled: true,
                      fillColor: AppColors.gray100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.sm),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: productsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                    child: Text('Erreur de chargement',
                        style: TextStyle(color: AppColors.gray500))),
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(
                        child: Text('Aucun produit trouvé',
                            style:
                                TextStyle(color: AppColors.gray500)));
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    itemCount: products.length,
                    itemBuilder: (ctx, i) {
                      final p = products[i];
                      final nom = p['nom'] as String? ?? '';
                      final ref2 = p['reference'] as String? ?? '';
                      final prix = p['prix_vente'] as num? ?? 0;
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm),
                          ),
                          child: const Icon(Icons.inventory_2_rounded,
                              color: AppColors.primary,
                              size: AppSizes.iconSm),
                        ),
                        title: Text(nom,
                            style: const TextStyle(
                                fontSize: AppSizes.fontSm,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray900)),
                        subtitle: Text(
                            '$ref2 · ${AppFormatters.gnf(prix)}',
                            style: const TextStyle(
                                fontSize: AppSizes.fontXs,
                                color: AppColors.gray500)),
                        onTap: () => Navigator.of(context).pop(p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets helper ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.gray400,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    required this.label,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontSize: AppSizes.fontXs, color: AppColors.gray500),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: const BorderSide(color: AppColors.gray200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  const _RecapRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: bold ? AppColors.gray900 : AppColors.gray500,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.normal)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize:
                    bold ? AppSizes.fontMd : AppSizes.fontSm,
                color: valueColor ??
                    (bold ? AppColors.gray900 : AppColors.gray700),
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
