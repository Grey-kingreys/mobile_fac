import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/finance/domain/entities/depense_entity.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

class _DepensesState {
  const _DepensesState({
    this.depenses = const [],
    this.total = 0,
    this.page = 1,
    this.categorie = '',
    this.isLoadingMore = false,
  });

  final List<DepenseEntity> depenses;
  final int total;
  final int page;
  final String categorie;
  final bool isLoadingMore;

  bool get hasMore => depenses.length < total;

  _DepensesState copyWith({
    List<DepenseEntity>? depenses,
    int? total,
    int? page,
    String? categorie,
    bool? isLoadingMore,
  }) =>
      _DepensesState(
        depenses: depenses ?? this.depenses,
        total: total ?? this.total,
        page: page ?? this.page,
        categorie: categorie ?? this.categorie,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class _DepensesNotifier extends AsyncNotifier<_DepensesState> {
  static const _pageSize = 25;

  @override
  Future<_DepensesState> build() => _load(page: 1, categorie: '');

  Future<_DepensesState> _load(
      {required int page, required String categorie}) async {
    final api = ref.read(apiClientProvider);
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$_pageSize',
      'ordering': '-date_depense',
      if (categorie.isNotEmpty) 'categorie': categorie,
    };
    final resp = await api.get<Map<String, dynamic>>(
      ApiEndpoints.depenses,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    final results = _list(data).map(DepenseEntity.fromJson).toList();
    final prev =
        page > 1 ? (state.valueOrNull?.depenses ?? []) : <DepenseEntity>[];
    return _DepensesState(
      depenses: [...prev, ...results],
      total: data['count'] as int? ?? 0,
      page: page,
      categorie: categorie,
    );
  }

  Future<void> refresh() async {
    final s = state.valueOrNull?.categorie ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1, categorie: s));
  }

  Future<void> filterCategorie(String cat) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1, categorie: cat));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get<Map<String, dynamic>>(
        ApiEndpoints.depenses,
        queryParameters: {
          'page': '${current.page + 1}',
          'page_size': '$_pageSize',
          'ordering': '-date_depense',
          if (current.categorie.isNotEmpty) 'categorie': current.categorie,
        },
      );
      final data = resp.data ?? {};
      final results = _list(data).map(DepenseEntity.fromJson).toList();
      state = AsyncData(current.copyWith(
        depenses: [...current.depenses, ...results],
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
    await api.post<Map<String, dynamic>>(ApiEndpoints.depenses, data: body);
    await refresh();
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic>? data) {
    if (data == null) return [];
    final r = data['results'];
    if (r is List) return r.cast<Map<String, dynamic>>();
    return [];
  }
}

final _depensesProvider =
    AsyncNotifierProvider<_DepensesNotifier, _DepensesState>(
        _DepensesNotifier.new);

// ─── Écran ────────────────────────────────────────────────────────────────────

class DepensesScreen extends ConsumerStatefulWidget {
  const DepensesScreen({super.key});

  @override
  ConsumerState<DepensesScreen> createState() => _DepensesScreenState();
}

class _DepensesScreenState extends ConsumerState<DepensesScreen> {
  String _categorie = '';
  late final ScrollController _scrollController;

  static const _canCreate = ['caissier', 'admin', 'superviseur'];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          ref.read(_depensesProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const _categories = [
    ('Toutes', ''),
    ('Carburant', 'carburant'),
    ('Maintenance', 'maintenance'),
    ('Salaires', 'salaires'),
    ('Loyer', 'loyer'),
    ('Fournitures', 'fournitures'),
    ('Transport', 'transport'),
    ('Autre', 'autre'),
  ];

  static const _catIcons = {
    'carburant': Icons.local_gas_station_rounded,
    'maintenance': Icons.build_rounded,
    'salaires': Icons.people_rounded,
    'loyer': Icons.home_rounded,
    'fournitures': Icons.inventory_2_rounded,
    'transport': Icons.directions_car_rounded,
    'autre': Icons.receipt_long_rounded,
  };

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _CreateDepenseSheet(
        onCreated: () => ref.read(_depensesProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(effectiveRoleProvider);
    final depensesAsync = ref.watch(_depensesProvider);
    final canCreate = _canCreate.contains(role);

    return AppScaffold(
      title: 'Dépenses opérationnelles',
      showBottomNav: true,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _showCreateSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter'),
            )
          : null,
      body: Column(
        children: [
          // ─── Filtres catégorie ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, AppSizes.md, AppSizes.paddingPage, 0),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((c) {
                  final (label, value) = c;
                  final selected = _categorie == value;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSizes.xs),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _categorie = value);
                        ref
                            .read(_depensesProvider.notifier)
                            .filterCategorie(value);
                      },
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
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xs),

          // ─── Liste ─────────────────────────────────────────────────────
          Expanded(
            child: depensesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    const Text('Impossible de charger les dépenses',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(_depensesProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.depenses.isEmpty) {
                  return const Center(
                    child: Text('Aucune dépense enregistrée',
                        style: TextStyle(color: AppColors.gray500)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(_depensesProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(AppSizes.paddingPage,
                        AppSizes.sm, AppSizes.paddingPage, AppSizes.xxl),
                    itemCount: state.depenses.length +
                        (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (_, i) {
                      if (i == state.depenses.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child:
                              Center(child: CircularProgressIndicator()),
                        );
                      }
                      final d = state.depenses[i];
                      final icon = _catIcons[d.categorie] ??
                          Icons.receipt_long_rounded;
                      return Container(
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
                                color: AppColors.danger
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(icon,
                                  color: AppColors.danger,
                                  size: AppSizes.iconSm),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.description,
                                    style: const TextStyle(
                                      fontSize: AppSizes.fontSm,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    [
                                      d.dateDepense,
                                      if (d.depotNom != null) d.depotNom!,
                                    ].join(' · '),
                                    style: const TextStyle(
                                        fontSize: AppSizes.fontXs,
                                        color: AppColors.gray400),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.gnf(d.montant),
                              style: const TextStyle(
                                fontSize: AppSizes.fontSm,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
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

// ─── Formulaire création ──────────────────────────────────────────────────────

class _CreateDepenseSheet extends ConsumerStatefulWidget {
  const _CreateDepenseSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateDepenseSheet> createState() =>
      _CreateDepenseSheetState();
}

class _CreateDepenseSheetState extends ConsumerState<_CreateDepenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String _categorie = 'autre';
  bool _isSaving = false;

  static const _categories = [
    ('Carburant', 'carburant'),
    ('Maintenance', 'maintenance'),
    ('Salaires', 'salaires'),
    ('Loyer', 'loyer'),
    ('Fournitures', 'fournitures'),
    ('Transport', 'transport'),
    ('Autre', 'autre'),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _montantCtrl.dispose();
    _refCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(_depensesProvider.notifier).create({
        'categorie': _categorie,
        'montant': double.parse(_montantCtrl.text.replaceAll(',', '.')),
        'description': _descCtrl.text.trim(),
        'date_depense': _dateCtrl.text,
        if (_refCtrl.text.isNotEmpty) 'reference': _refCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dépense enregistrée'),
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
                    'Enregistrer une dépense',
                    style: TextStyle(
                        fontSize: AppSizes.fontLg,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900),
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
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _montantCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant (GNF) *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                'Catégorie',
                style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700),
              ),
              const SizedBox(height: AppSizes.xs),
              Wrap(
                spacing: AppSizes.xs,
                runSpacing: AppSizes.xs,
                children: _categories.map((c) {
                  final (label, value) = c;
                  final sel = _categorie == value;
                  return GestureDetector(
                    onTap: () => setState(() => _categorie = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.xs),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.gray100,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(
                            color: sel
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.gray200),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                            fontSize: AppSizes.fontXs,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? AppColors.primary
                                : AppColors.gray500),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_rounded),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        _dateCtrl.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Référence (optionnel)',
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
                      : const Text('Enregistrer'),
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
