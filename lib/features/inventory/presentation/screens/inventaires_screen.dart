import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

// ─── Entités inline ───────────────────────────────────────────────────────────

class _LigneInventaire {
  final int id;
  final int produitId;
  final String produitNom;
  final String produitReference;
  final double quantiteTheorique;
  double? quantiteComptee;
  double? get ecart =>
      quantiteComptee != null ? quantiteComptee! - quantiteTheorique : null;

  _LigneInventaire({
    required this.id,
    required this.produitId,
    required this.produitNom,
    required this.produitReference,
    required this.quantiteTheorique,
    this.quantiteComptee,
  });

  factory _LigneInventaire.fromJson(Map<String, dynamic> j) =>
      _LigneInventaire(
        id: j['id'] as int,
        produitId: j['produit'] as int,
        produitNom: j['produit_nom'] as String? ?? '',
        produitReference: j['produit_reference'] as String? ?? '',
        quantiteTheorique:
            double.tryParse(j['quantite_theorique'].toString()) ?? 0,
        quantiteComptee: j['quantite_comptee'] != null
            ? double.tryParse(j['quantite_comptee'].toString())
            : null,
      );
}

class _Inventaire {
  final int id;
  final String numero;
  final int depotId;
  final String depotCode;
  final String statut;
  final String statutLabel;
  final int nbLignes;
  final String createdAt;
  final String? valideLe;

  const _Inventaire({
    required this.id,
    required this.numero,
    required this.depotId,
    required this.depotCode,
    required this.statut,
    required this.statutLabel,
    required this.nbLignes,
    required this.createdAt,
    this.valideLe,
  });

  factory _Inventaire.fromJson(Map<String, dynamic> j) => _Inventaire(
        id: j['id'] as int,
        numero: j['numero'] as String? ?? '',
        depotId: j['depot'] as int? ?? 0,
        depotCode: j['depot_code'] as String? ?? '',
        statut: j['statut'] as String? ?? '',
        statutLabel: j['statut_label'] as String? ?? '',
        nbLignes: j['nb_lignes'] as int? ?? 0,
        createdAt: j['created_at'] as String? ?? '',
        valideLe: j['valide_le'] as String?,
      );

  bool get isEnCours => statut == 'en_cours';
}

// ─── State ────────────────────────────────────────────────────────────────────

class _InvState {
  final List<_Inventaire> items;
  final int total;
  final int page;
  final bool isLoadingMore;
  final String? statutFilter;

  const _InvState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
    this.statutFilter,
  });

  _InvState copyWith({
    List<_Inventaire>? items,
    int? total,
    int? page,
    bool? isLoadingMore,
    Object? statutFilter = _sentinel,
  }) {
    return _InvState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      statutFilter:
          statutFilter == _sentinel ? this.statutFilter : statutFilter as String?,
    );
  }
}

const _sentinel = Object();

// ─── Notifier ─────────────────────────────────────────────────────────────────

class _InvNotifier extends AutoDisposeAsyncNotifier<_InvState> {
  @override
  Future<_InvState> build() async => _fetch(page: 1, statut: null);

  Future<_InvState> _fetch({required int page, String? statut}) async {
    final api = ref.read(apiClientProvider);
    final params = <String, dynamic>{'page': page, 'page_size': 25};
    if (statut != null) params['statut'] = statut;
    final res = await api.get<Map<String, dynamic>>(
      ApiEndpoints.inventaires,
      queryParameters: params,
    );
    final data = res.data!;
    final results = (data['results'] as List)
        .map((e) => _Inventaire.fromJson(e as Map<String, dynamic>))
        .toList();
    return _InvState(
      items: results,
      total: data['count'] as int? ?? results.length,
      page: page,
      statutFilter: statut,
    );
  }

  Future<void> refresh() async {
    final cur = state.valueOrNull;
    state = AsyncData(await _fetch(page: 1, statut: cur?.statutFilter));
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || cur.isLoadingMore) return;
    if (cur.items.length >= cur.total) return;
    state = AsyncData(cur.copyWith(isLoadingMore: true));
    try {
      final next = await _fetch(page: cur.page + 1, statut: cur.statutFilter);
      state = AsyncData(next.copyWith(
        items: [...cur.items, ...next.items],
        page: cur.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(cur.copyWith(isLoadingMore: false));
    }
  }

  Future<void> filterByStatut(String? statut) async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch(page: 1, statut: statut));
  }
}

final _invProvider =
    AutoDisposeAsyncNotifierProvider<_InvNotifier, _InvState>(
  _InvNotifier.new,
);

// ─── Écran principal ──────────────────────────────────────────────────────────

class InventairesScreen extends ConsumerStatefulWidget {
  const InventairesScreen({super.key});

  @override
  ConsumerState<InventairesScreen> createState() => _InventairesScreenState();
}

class _InventairesScreenState extends ConsumerState<InventairesScreen> {
  late final ScrollController _scrollController;
  static const _canCreate = ['admin', 'gestionnaire_stock'];
  static const _canValider = ['admin', 'superviseur'];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          ref.read(_invProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCreate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _CreateInventaireSheet(
        onCreated: () => ref.read(_invProvider.notifier).refresh(),
      ),
    );
  }

  void _showDetail(_Inventaire inv, String role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _InventaireDetailSheet(
        inventaire: inv,
        canValider: _canValider.contains(role) && inv.isEnCours,
        onValidated: () => ref.read(_invProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invAsync = ref.watch(_invProvider);
    final role = ref.watch(effectiveRoleProvider);
    final canCreate = _canCreate.contains(role);

    return AppScaffold(
      title: 'Inventaires',
      showBottomNav: true,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _showCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouvel inventaire'),
            )
          : null,
      body: Column(
        children: [
          // ── Filtres statut ────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, AppSizes.sm,
                AppSizes.paddingPage, AppSizes.sm),
            child: invAsync.maybeWhen(
              data: (state) => Row(
                children: [
                  _FilterChip(
                    label: 'Tous',
                    active: state.statutFilter == null,
                    onTap: () =>
                        ref.read(_invProvider.notifier).filterByStatut(null),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  _FilterChip(
                    label: 'En cours',
                    active: state.statutFilter == 'en_cours',
                    color: AppColors.accent,
                    onTap: () => ref
                        .read(_invProvider.notifier)
                        .filterByStatut('en_cours'),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  _FilterChip(
                    label: 'Validés',
                    active: state.statutFilter == 'valide',
                    color: AppColors.secondary,
                    onTap: () => ref
                        .read(_invProvider.notifier)
                        .filterByStatut('valide'),
                  ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),

          // ── Liste ─────────────────────────────────────────────────────────
          Expanded(
            child: invAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    const Text('Impossible de charger les inventaires',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(_invProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: AppSizes.iconXxl, color: AppColors.gray200),
                        SizedBox(height: AppSizes.md),
                        Text('Aucun inventaire trouvé',
                            style: TextStyle(color: AppColors.gray500)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(_invProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingPage, 0,
                        AppSizes.paddingPage, AppSizes.xxl),
                    itemCount:
                        state.items.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (ctx, i) {
                      if (i == state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _InventaireTile(
                        inv: state.items[i],
                        onTap: () => _showDetail(state.items[i], role),
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

// ─── Chip filtre ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm + 4, vertical: AppSizes.xs + 2),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.12) : AppColors.gray100,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
              color: active ? c : AppColors.gray200, width: active ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? c : AppColors.gray500,
            fontSize: AppSizes.fontXs,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Tuile inventaire ─────────────────────────────────────────────────────────

class _InventaireTile extends StatelessWidget {
  const _InventaireTile({required this.inv, required this.onTap});
  final _Inventaire inv;
  final VoidCallback onTap;

  Color get _statusColor =>
      inv.isEnCours ? AppColors.accent : AppColors.secondary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Icône
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                inv.isEnCours
                    ? Icons.assignment_outlined
                    : Icons.assignment_turned_in_outlined,
                color: _statusColor,
                size: AppSizes.iconMd,
              ),
            ),
            const SizedBox(width: AppSizes.sm),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inv.numero,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.fontSm,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dépôt ${inv.depotCode} · ${inv.nbLignes} produit${inv.nbLignes > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: AppColors.gray400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.dateShort(
                        DateTime.tryParse(inv.createdAt) ?? DateTime.now()),
                    style: const TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),

            // Badge statut
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                inv.statutLabel,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.xs),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.gray300, size: AppSizes.iconSm),
          ],
        ),
      ),
    );
  }
}

// ─── Formulaire création inventaire ──────────────────────────────────────────

class _CreateInventaireSheet extends ConsumerStatefulWidget {
  const _CreateInventaireSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateInventaireSheet> createState() =>
      _CreateInventaireSheetState();
}

class _CreateInventaireSheetState
    extends ConsumerState<_CreateInventaireSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  List<Map<String, dynamic>> _depots = [];
  int? _depotId;
  bool _loadingDepots = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDepots();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDepots() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get<Map<String, dynamic>>(
        '/depots/',
        queryParameters: {'page_size': 100},
      );
      if (mounted) {
        setState(() {
          _depots = List<Map<String, dynamic>>.from(
            (res.data?['results'] ?? []) as List,
          );
          // Pré-sélectionner le dépôt de l'utilisateur connecté
          final userDepotId =
              ref.read(authProvider).valueOrNull?.depotId;
          if (userDepotId != null &&
              _depots.any((d) => d['id'] == userDepotId)) {
            _depotId = userDepotId;
          }
          _loadingDepots = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDepots = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.inventaires,
        data: {
          'depot': _depotId,
          if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventaire créé avec succès'),
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
                    'Nouvel inventaire',
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
              const SizedBox(height: AppSizes.xs),
              const Text(
                'Un inventaire liste tous les produits du dépôt avec leur stock théorique. Vous saisirez les quantités comptées dans un second temps.',
                style:
                    TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontXs),
              ),
              const SizedBox(height: AppSizes.md),

              // ── Dépôt ─────────────────────────────────────────────────
              _loadingDepots
                  ? const SizedBox(
                      height: 56,
                      child: Center(child: LinearProgressIndicator()),
                    )
                  : DropdownButtonFormField<int>(
                      initialValue: _depotId,
                      decoration: const InputDecoration(
                        labelText: 'Dépôt *',
                        border: OutlineInputBorder(),
                      ),
                      items: _depots
                          .map((d) => DropdownMenuItem<int>(
                                value: d['id'] as int,
                                child: Text(
                                    '${d['name']} (${d['code']})'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _depotId = v),
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
              const SizedBox(height: AppSizes.sm),

              // ── Notes ─────────────────────────────────────────────────
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
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
                      : const Text('Créer l\'inventaire'),
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

// ─── Détail inventaire + saisie comptage ─────────────────────────────────────

class _InventaireDetailSheet extends ConsumerStatefulWidget {
  const _InventaireDetailSheet({
    required this.inventaire,
    required this.canValider,
    required this.onValidated,
  });
  final _Inventaire inventaire;
  final bool canValider;
  final VoidCallback onValidated;

  @override
  ConsumerState<_InventaireDetailSheet> createState() =>
      _InventaireDetailSheetState();
}

class _InventaireDetailSheetState
    extends ConsumerState<_InventaireDetailSheet> {
  List<_LigneInventaire> _lignes = [];
  Map<int, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get<Map<String, dynamic>>(
        ApiEndpoints.inventaireDetail(widget.inventaire.id),
      );
      final data = res.data!;
      final lignes = (data['lignes'] as List)
          .map((e) => _LigneInventaire.fromJson(e as Map<String, dynamic>))
          .toList();

      // Créer un controller pour chaque ligne
      final controllers = <int, TextEditingController>{};
      for (final ligne in lignes) {
        controllers[ligne.id] = TextEditingController(
          text: ligne.quantiteComptee?.toString() ?? '',
        );
      }

      if (mounted) {
        setState(() {
          _lignes = lignes;
          _controllers = controllers;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _valider() async {
    // Vérifier que toutes les lignes ont une quantité saisie
    final lignesData = <Map<String, dynamic>>[];
    for (final ligne in _lignes) {
      final ctrl = _controllers[ligne.id];
      final val = double.tryParse(ctrl?.text.replaceAll(',', '.') ?? '');
      if (val == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Quantité manquante pour "${ligne.produitNom}". Tous les champs sont obligatoires.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      lignesData.add({'ligne_id': ligne.id, 'quantite_comptee': val});
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.inventaireValider(widget.inventaire.id),
        data: {'lignes': lignesData},
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onValidated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventaire validé — stock mis à jour'),
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.inventaire;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSizes.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, AppSizes.md,
                AppSizes.paddingPage, AppSizes.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.numero,
                        style: const TextStyle(
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        'Dépôt ${inv.depotCode} · ${inv.statutLabel}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Corps
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppColors.danger)))
                    : _lignes.isEmpty
                        ? const Center(
                            child: Text('Aucun produit dans ce dépôt',
                                style: TextStyle(
                                    color: AppColors.gray400)))
                        : ListView.separated(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(
                                AppSizes.paddingPage, AppSizes.sm,
                                AppSizes.paddingPage, AppSizes.xxl),
                            itemCount: _lignes.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final ligne = _lignes[i];
                              return _LigneTile(
                                ligne: ligne,
                                controller: _controllers[ligne.id]!,
                                editable: widget.canValider,
                              );
                            },
                          ),
          ),

          // Bouton valider
          if (widget.canValider)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingPage),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _valider,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.md),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Valider l\'inventaire'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tuile ligne inventaire ───────────────────────────────────────────────────

class _LigneTile extends StatelessWidget {
  const _LigneTile({
    required this.ligne,
    required this.controller,
    required this.editable,
  });
  final _LigneInventaire ligne;
  final TextEditingController controller;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Produit info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ligne.produitNom,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  '${ligne.produitReference} · Théorique : ${ligne.quantiteTheorique}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),

          // Quantité comptée (saisie si éditable)
          editable
              ? SizedBox(
                  width: 80,
                  child: TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: const TextStyle(color: AppColors.gray300),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.xs, vertical: AppSizes.xs),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                          borderSide:
                              const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ligne.quantiteComptee?.toString() ?? '—',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    if (ligne.ecart != null)
                      Text(
                        ligne.ecart! >= 0
                            ? '+${ligne.ecart}'
                            : '${ligne.ecart}',
                        style: TextStyle(
                          fontSize: AppSizes.fontXs,
                          fontWeight: FontWeight.w600,
                          color: ligne.ecart! < 0
                              ? AppColors.danger
                              : AppColors.secondary,
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }
}
