import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/products/presentation/providers/products_provider.dart';
import 'package:djoulagest_mobile/features/products/presentation/widgets/product_card.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() =>
      _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  static const _canCreate = ['gestionnaire_stock', 'admin', 'superviseur'];

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(productsProvider.notifier).loadMore();
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _CreateProductSheet(
        onCreated: () => ref.read(productsProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final role = ref.watch(effectiveRoleProvider);
    final canCreate = _canCreate.contains(role);

    return AppScaffold(
      title: 'Catalogue produits',
      showBottomNav: true,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _showCreateSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter un produit'),
            )
          : null,
      body: Column(
        children: [
          // ─── Recherche ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, AppSizes.md,
                AppSizes.paddingPage, AppSizes.sm),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(productsProvider.notifier).search(v),
              decoration: InputDecoration(
                hintText: 'Rechercher un produit…',
                hintStyle: const TextStyle(
                    color: AppColors.gray400, fontSize: AppSizes.fontSm),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.gray400, size: AppSizes.iconMd),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: AppSizes.iconSm),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(productsProvider.notifier).search('');
                        },
                      )
                    : null,
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
            ),
          ),

          // ─── Liste ───────────────────────────────────────────────────
          Expanded(
            child: productsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    const Text('Impossible de charger les produits',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(productsProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_rounded,
                            size: AppSizes.iconXxl,
                            color: AppColors.gray200),
                        SizedBox(height: AppSizes.md),
                        Text('Aucun produit trouvé',
                            style: TextStyle(color: AppColors.gray500)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(productsProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingPage, 0,
                        AppSizes.paddingPage, AppSizes.xxl),
                    itemCount: state.products.length +
                        (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (ctx, i) {
                      if (i == state.products.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child: Center(
                              child: CircularProgressIndicator()),
                        );
                      }
                      final p = state.products[i];
                      return ProductCard(
                        product: p,
                        onTap: () => context.push('/products/${p.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulaire création produit ──────────────────────────────────────────────

class _CreateProductSheet extends ConsumerStatefulWidget {
  const _CreateProductSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateProductSheet> createState() =>
      _CreateProductSheetState();
}

class _CreateProductSheetState extends ConsumerState<_CreateProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _prixAchatCtrl = TextEditingController();
  final _prixVenteCtrl = TextEditingController();
  final _seuilCtrl = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _unites = [];
  int? _categorieId;
  int? _uniteId;
  double _tvaTaux = 0.0;
  bool _estPerimable = false;
  bool _loadingDropdowns = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _refCtrl.dispose();
    _prixAchatCtrl.dispose();
    _prixVenteCtrl.dispose();
    _seuilCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    try {
      final api = ref.read(apiClientProvider);
      final catRes = await api.get<Map<String, dynamic>>(
        ApiEndpoints.categories,
        queryParameters: {'page_size': 100, 'is_active': true},
      );
      final uniteRes = await api.get<Map<String, dynamic>>(
        ApiEndpoints.unites,
        queryParameters: {'page_size': 100},
      );
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(
            (catRes.data?['results'] ?? []) as List,
          );
          _unites = List<Map<String, dynamic>>.from(
            (uniteRes.data?['results'] ?? []) as List,
          );
          _loadingDropdowns = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDropdowns = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.produits,
        data: {
          'nom': _nomCtrl.text.trim(),
          'reference': _refCtrl.text.trim(),
          'prix_achat': double.parse(_prixAchatCtrl.text.replaceAll(',', '.')),
          'prix_vente': double.parse(_prixVenteCtrl.text.replaceAll(',', '.')),
          'categorie': _categorieId,
          'unite': _uniteId,
          'tva_taux': _tvaTaux,
          if (_seuilCtrl.text.isNotEmpty)
            'seuil_alerte': int.tryParse(_seuilCtrl.text),
          'est_perimable': _estPerimable,
        },
      );
      await ref.read(productsProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit créé avec succès'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingPage),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Ajouter un produit',
                    style: TextStyle(
                      fontSize: AppSizes.fontLg,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // ── Nom ───────────────────────────────────────────────────
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),

              // ── Référence ────────────────────────────────────────────
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Référence *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),

              // ── Catégorie ─────────────────────────────────────────────
              _loadingDropdowns
                  ? const SizedBox(
                      height: 56,
                      child: Center(child: LinearProgressIndicator()),
                    )
                  : DropdownButtonFormField<int>(
                      initialValue: _categorieId,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie *',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem<int>(
                                value: c['id'] as int,
                                child: Text(c['name'] as String),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _categorieId = v),
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
              const SizedBox(height: AppSizes.sm),

              // ── Unité ─────────────────────────────────────────────────
              _loadingDropdowns
                  ? const SizedBox(height: 56)
                  : DropdownButtonFormField<int>(
                      initialValue: _uniteId,
                      decoration: const InputDecoration(
                        labelText: 'Unité de mesure *',
                        border: OutlineInputBorder(),
                      ),
                      items: _unites
                          .map((u) => DropdownMenuItem<int>(
                                value: u['id'] as int,
                                child: Text('${u['name']} (${u['symbole']})'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _uniteId = v),
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
              const SizedBox(height: AppSizes.sm),

              // ── Prix achat / vente ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prixAchatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Prix achat *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) {
                          return 'Invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _prixVenteCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Prix vente *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) {
                          return 'Invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),

              // ── Taux TVA ──────────────────────────────────────────────
              DropdownButtonFormField<double>(
                initialValue: _tvaTaux,
                decoration: const InputDecoration(
                  labelText: 'Taux TVA',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 0.0, child: Text('0 % (exonéré)')),
                  DropdownMenuItem(value: 18.0, child: Text('18 %')),
                  DropdownMenuItem(value: 20.0, child: Text('20 %')),
                ],
                onChanged: (v) => setState(() => _tvaTaux = v ?? 0.0),
              ),
              const SizedBox(height: AppSizes.sm),

              // ── Seuil alerte ──────────────────────────────────────────
              TextFormField(
                controller: _seuilCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seuil d\'alerte stock',
                  hintText: 'Quantité minimale avant alerte',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.sm),

              // ── Périmable ─────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Produit périmable',
                      style: TextStyle(
                          color: AppColors.gray700,
                          fontSize: AppSizes.fontSm),
                    ),
                  ),
                  Switch(
                    value: _estPerimable,
                    onChanged: (v) => setState(() => _estPerimable = v),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.md),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Créer le produit'),
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}
