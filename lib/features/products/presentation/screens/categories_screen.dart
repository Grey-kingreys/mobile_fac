import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/products/data/models/category_model.dart';
import 'package:djoulagest_mobile/features/products/domain/entities/category_entity.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class _CatState {
  const _CatState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
  });

  final List<CategoryEntity> items;
  final int total;
  final int page;
  final bool isLoadingMore;

  bool get hasMore => items.length < total;

  _CatState copyWith({
    List<CategoryEntity>? items,
    int? total,
    int? page,
    bool? isLoadingMore,
  }) =>
      _CatState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class _CategoriesNotifier extends AsyncNotifier<_CatState> {
  static const _pageSize = 25;

  @override
  Future<_CatState> build() => _load(page: 1);

  Future<_CatState> _load({required int page}) async {
    final api = ref.read(apiClientProvider);
    final resp = await api.get<Map<String, dynamic>>(
      '/categories/',
      queryParameters: {'page': '$page', 'page_size': '$_pageSize'},
    );
    final data = resp.data ?? {};
    final results = _list(data).map(CategoryModel.fromJson).toList();
    final prev =
        page > 1 ? (state.valueOrNull?.items ?? []) : <CategoryEntity>[];
    return _CatState(
      items: [...prev, ...results],
      total: data['count'] as int? ?? 0,
      page: page,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get<Map<String, dynamic>>(
        '/categories/',
        queryParameters: {
          'page': '${current.page + 1}',
          'page_size': '$_pageSize',
        },
      );
      final data = resp.data ?? {};
      final results = _list(data).map(CategoryModel.fromJson).toList();
      state = AsyncData(current.copyWith(
        items: [...current.items, ...results],
        total: data['count'] as int? ?? 0,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> create(Map<String, dynamic> body) async {
    final api = ref.read(apiClientProvider);
    await api.post<Map<String, dynamic>>('/categories/', data: body);
    await refresh();
  }

  Future<void> updateCategorie(int id, Map<String, dynamic> body) async {
    final api = ref.read(apiClientProvider);
    await api.patch<Map<String, dynamic>>('/categories/$id/', data: body);
    await refresh();
  }

  Future<void> delete(int id) async {
    final api = ref.read(apiClientProvider);
    await api.delete<void>('/categories/$id/');
    await refresh();
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic>? data) {
    if (data == null) return [];
    final r = data['results'];
    if (r is List) return r.cast<Map<String, dynamic>>();
    return [];
  }
}

final _categoriesProvider =
    AsyncNotifierProvider<_CategoriesNotifier, _CatState>(
        _CategoriesNotifier.new);

// ─── Écran ────────────────────────────────────────────────────────────────────

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  late final ScrollController _scrollController;

  static const _canEdit = ['admin', 'gestionnaire_stock'];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          ref.read(_categoriesProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _parseCouleur(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primary;
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
      builder: (_) => _CategorieFormSheet(
        onSaved: () => ref.read(_categoriesProvider.notifier).refresh(),
      ),
    );
  }

  void _showEditSheet(CategoryEntity cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _CategorieFormSheet(
        categorie: cat,
        onSaved: () => ref.read(_categoriesProvider.notifier).refresh(),
        onDeleted: () => ref.read(_categoriesProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(effectiveRoleProvider);
    final catsAsync = ref.watch(_categoriesProvider);
    final canEdit = _canEdit.contains(role);

    return AppScaffold(
      title: 'Catégories',
      showBottomNav: true,
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: _showCreateSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter'),
            )
          : null,
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: AppSizes.iconXxl, color: AppColors.gray300),
              const SizedBox(height: AppSizes.md),
              const Text('Impossible de charger les catégories',
                  style: TextStyle(color: AppColors.gray500)),
              const SizedBox(height: AppSizes.sm),
              TextButton(
                onPressed: () =>
                    ref.read(_categoriesProvider.notifier).refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (s) {
          if (s.items.isEmpty) {
            return const Center(
              child: Text('Aucune catégorie enregistrée',
                  style: TextStyle(color: AppColors.gray500)),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(_categoriesProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(AppSizes.paddingPage,
                  AppSizes.md, AppSizes.paddingPage, AppSizes.xxl),
              itemCount: s.items.length + (s.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSizes.xs),
              itemBuilder: (_, i) {
                if (i == s.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final cat = s.items[i];
                final couleur = _parseCouleur(cat.couleur);
                return GestureDetector(
                  onTap: canEdit ? () => _showEditSheet(cat) : null,
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.gray100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: couleur,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              cat.name.isNotEmpty
                                  ? cat.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: const TextStyle(
                                  fontSize: AppSizes.fontSm,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray900,
                                ),
                              ),
                              if (cat.description.isNotEmpty)
                                Text(
                                  cat.description,
                                  style: const TextStyle(
                                    fontSize: AppSizes.fontXs,
                                    color: AppColors.gray400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'TVA ${cat.tvaTaux.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: AppSizes.fontXs,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${cat.nombreProduits} produit${cat.nombreProduits > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: AppSizes.fontXs,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Formulaire création / édition ────────────────────────────────────────────

class _CategorieFormSheet extends ConsumerStatefulWidget {
  const _CategorieFormSheet({
    this.categorie,
    required this.onSaved,
    this.onDeleted,
  });

  final CategoryEntity? categorie;
  final VoidCallback onSaved;
  final VoidCallback? onDeleted;

  @override
  ConsumerState<_CategorieFormSheet> createState() =>
      _CategorieFormSheetState();
}

class _CategorieFormSheetState extends ConsumerState<_CategorieFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _tvaCtrl;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEdit => widget.categorie != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.categorie;
    _nameCtrl = TextEditingController(text: cat?.name ?? '');
    _descCtrl = TextEditingController(text: cat?.description ?? '');
    _tvaCtrl = TextEditingController(
        text: cat != null ? cat.tvaTaux.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _tvaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
        'tva_taux': double.tryParse(
                _tvaCtrl.text.replaceAll(',', '.')) ??
            0.0,
      };
      if (_isEdit) {
        await ref
            .read(_categoriesProvider.notifier)
            .updateCategorie(widget.categorie!.id, body);
      } else {
        await ref.read(_categoriesProvider.notifier).create(body);
      }
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Catégorie mise à jour'
                : 'Catégorie créée'),
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la catégorie ?'),
        content: Text(
            'Voulez-vous vraiment supprimer "${widget.categorie!.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isDeleting = true);
    try {
      await ref
          .read(_categoriesProvider.notifier)
          .delete(widget.categorie!.id);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDeleted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catégorie supprimée'),
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
      if (mounted) setState(() => _isDeleting = false);
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
                  Text(
                    _isEdit ? 'Modifier la catégorie' : 'Nouvelle catégorie',
                    style: const TextStyle(
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
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _tvaCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Taux TVA (%)',
                  border: OutlineInputBorder(),
                ),
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
                      : Text(_isEdit ? 'Enregistrer' : 'Créer'),
                ),
              ),
              if (_isEdit) ...[
                const SizedBox(height: AppSizes.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isDeleting ? null : _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSizes.md),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd)),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.danger),
                          )
                        : const Text('Supprimer'),
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}
