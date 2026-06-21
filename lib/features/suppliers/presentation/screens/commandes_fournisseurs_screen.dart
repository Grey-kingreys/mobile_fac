import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/depots/presentation/providers/depots_provider.dart';
import 'package:djoulagest_mobile/features/suppliers/data/datasources/suppliers_remote_datasource.dart';
import 'package:djoulagest_mobile/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:djoulagest_mobile/features/sales/presentation/providers/sales_provider.dart';
import 'package:djoulagest_mobile/features/suppliers/presentation/providers/suppliers_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final _cfDatasourceProvider = Provider<SuppliersRemoteDatasource>(
  (ref) => SuppliersRemoteDatasource(ref.read(apiClientProvider)),
);

class _CfState {
  const _CfState({
    this.orders = const [],
    this.total = 0,
    this.page = 1,
    this.filterStatut,
    this.isLoadingMore = false,
  });
  final List<SupplierOrderEntity> orders;
  final int total;
  final int page;
  final String? filterStatut;
  final bool isLoadingMore;

  _CfState copyWith({
    List<SupplierOrderEntity>? orders,
    int? total,
    int? page,
    String? filterStatut,
    bool? clearStatut,
    bool? isLoadingMore,
  }) =>
      _CfState(
        orders: orders ?? this.orders,
        total: total ?? this.total,
        page: page ?? this.page,
        filterStatut: clearStatut == true ? null : filterStatut ?? this.filterStatut,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class _CfNotifier extends AsyncNotifier<_CfState> {
  @override
  Future<_CfState> build() => _fetch(1, null);

  Future<_CfState> _fetch(int page, String? statut) async {
    final result = await ref.read(_cfDatasourceProvider).getAllCommandesFournisseurs(
          page: page,
          statut: statut,
        );
    return _CfState(
      orders: result.orders,
      total: result.count,
      page: page,
      filterStatut: statut,
    );
  }

  Future<void> refresh() async {
    final cur = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(1, cur?.filterStatut));
  }

  Future<void> setStatut(String? statut) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(1, statut));
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || cur.isLoadingMore || cur.orders.length >= cur.total) return;
    state = AsyncData(cur.copyWith(isLoadingMore: true));
    try {
      final next = await _fetch(cur.page + 1, cur.filterStatut);
      state = AsyncData(next.copyWith(
        orders: [...cur.orders, ...next.orders],
        page: cur.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(cur.copyWith(isLoadingMore: false));
    }
  }

  Future<String?> createCommande({
    required int fournisseur,
    required int depotDestination,
    required List<Map<String, dynamic>> lignes,
    String? dateLivraisonPrevue,
    String? notes,
  }) async {
    try {
      await ref.read(_cfDatasourceProvider).createCommandeFournisseur(
            fournisseur: fournisseur,
            depotDestination: depotDestination,
            lignes: lignes,
            dateLivraisonPrevue: dateLivraisonPrevue,
            notes: notes,
          );
      await refresh();
      return null;
    } catch (e) {
      final s = e.toString();
      return s.startsWith('Exception: ') ? s.substring(11) : s;
    }
  }

  Future<String?> recevoirCommande(int id, List<Map<String, dynamic>> lignes) async {
    try {
      await ref.read(_cfDatasourceProvider).recevoirCommandeFournisseur(
            id: id,
            lignes: lignes,
          );
      await refresh();
      return null;
    } catch (e) {
      final s = e.toString();
      return s.startsWith('Exception: ') ? s.substring(11) : s;
    }
  }
}

final _cfProvider =
    AsyncNotifierProvider<_CfNotifier, _CfState>(_CfNotifier.new);

// ─── Écran principal ─────────────────────────────────────────────────────────

class CommandesFournisseursScreen extends ConsumerStatefulWidget {
  const CommandesFournisseursScreen({super.key});

  @override
  ConsumerState<CommandesFournisseursScreen> createState() =>
      _CommandesFournisseursScreenState();
}

class _CommandesFournisseursScreenState
    extends ConsumerState<CommandesFournisseursScreen> {
  late final ScrollController _scrollCtrl;

  static const _canCreate = ['gestionnaire_stock', 'admin', 'superviseur'];
  static const _filters = [
    (label: 'Toutes', value: null),
    (label: 'En attente', value: 'en_attente'),
    (label: 'Partiellement reçue', value: 'partiellement_recue'),
    (label: 'Reçue', value: 'recue'),
    (label: 'Annulée', value: 'annulee'),
  ];

  String? _selectedStatut;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()
      ..addListener(() {
        if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200) {
          ref.read(_cfProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
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
      builder: (_) => _CreateCommandeSheet(
        onCreated: () => ref.read(_cfProvider.notifier).refresh(),
      ),
    );
  }

  void _showDetail(SupplierOrderEntity order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _CommandeDetailSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_cfProvider);
    final role = ref.watch(effectiveRoleProvider);

    return AppScaffold(
      title: 'Commandes fournisseurs',
      showBottomNav: false,
      floatingActionButton: _canCreate.contains(role)
          ? FloatingActionButton.extended(
              onPressed: _showCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Commande'),
            )
          : null,
      body: Column(
        children: [
          _FilterBar(
            filters: _filters,
            selected: _selectedStatut,
            onChanged: (v) {
              setState(() => _selectedStatut = v);
              ref.read(_cfProvider.notifier).setStatut(v);
            },
          ),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Impossible de charger les commandes'),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(_cfProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.orders.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune commande fournisseur',
                      style: TextStyle(color: AppColors.gray500),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(_cfProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingPage, AppSizes.sm,
                        AppSizes.paddingPage, AppSizes.xxl),
                    itemCount:
                        state.orders.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (ctx, i) {
                      if (i == state.orders.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child:
                              Center(child: CircularProgressIndicator()),
                        );
                      }
                      final o = state.orders[i];
                      return _CommandeTile(
                        order: o,
                        onTap: () => _showDetail(o),
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

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.onChanged,
  });
  final List<({String label, String? value})> filters;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingPage),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.xs),
        itemBuilder: (_, i) {
          final f = filters[i];
          final active = selected == f.value;
          return ChoiceChip(
            label: Text(f.label),
            selected: active,
            onSelected: (_) => onChanged(f.value),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: active ? Colors.white : AppColors.gray700,
              fontSize: AppSizes.fontSm,
            ),
          );
        },
      ),
    );
  }
}

class _CommandeTile extends StatelessWidget {
  const _CommandeTile({required this.order, required this.onTap});
  final SupplierOrderEntity order;
  final VoidCallback onTap;

  Color get _statutColor {
    switch (order.statut) {
      case 'en_attente':
        return AppColors.accent;
      case 'partiellement_recue':
        return AppColors.primary;
      case 'recue':
        return AppColors.secondary;
      case 'annulee':
        return AppColors.gray400;
      default:
        return AppColors.gray400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: const Icon(Icons.receipt_long_outlined,
              color: AppColors.primary, size: 20),
        ),
        title: Text(
          order.numero,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.fontSm,
            color: AppColors.gray900,
          ),
        ),
        subtitle: Text(
          order.fournisseurNom +
              (order.depotNom != null ? ' → ${order.depotNom}' : ''),
          style: const TextStyle(
              fontSize: AppSizes.fontXs, color: AppColors.gray500),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm, vertical: AppSizes.xs),
          decoration: BoxDecoration(
            color: _statutColor.withValues(alpha: 0.1),
            borderRadius:
                BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(
            order.statutLabel,
            style: TextStyle(
              color: _statutColor,
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Détail commande ─────────────────────────────────────────────────────────

class _CommandeDetailSheet extends ConsumerStatefulWidget {
  const _CommandeDetailSheet({required this.order});
  final SupplierOrderEntity order;

  @override
  ConsumerState<_CommandeDetailSheet> createState() =>
      _CommandeDetailSheetState();
}

class _CommandeDetailSheetState
    extends ConsumerState<_CommandeDetailSheet> {
  SupplierOrderEntity? _detailOrder;
  bool _loading = true;
  bool _receiving = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final ds = ref.read(_cfDatasourceProvider);
      final detail =
          await ds.getCommandeFournisseurDetail(widget.order.id);
      if (mounted) {
        setState(() {
          _detailOrder = detail;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recevoir() async {
    final order = _detailOrder ?? widget.order;
    if (order.lignes == null || order.lignes!.isEmpty) return;

    final controllers = {
      for (final l in order.lignes!)
        l.id: TextEditingController(
            text: l.quantiteCommandee.toStringAsFixed(0))
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réceptionner la commande'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Saisissez les quantités réellement reçues :',
                style: TextStyle(fontSize: AppSizes.fontSm),
              ),
              const SizedBox(height: AppSizes.md),
              ...order.lignes!.map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.produitNom,
                          style: const TextStyle(
                              fontSize: AppSizes.fontSm,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: controllers[l.id],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Qté',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white),
            child: const Text('Confirmer réception'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _receiving = true);
    final lignesData = (order.lignes ?? [])
        .map((l) => {
              'ligne_id': l.id,
              'quantite_recue':
                  double.tryParse(controllers[l.id]?.text ?? '') ??
                      l.quantiteCommandee,
            })
        .toList();

    final err = await ref
        .read(_cfProvider.notifier)
        .recevoirCommande(order.id, lignesData);
    if (!mounted) return;
    setState(() => _receiving = false);
    Navigator.of(context).pop();
    if (err != null) {
      AppSnackbar.error(context, err);
    } else {
      AppSnackbar.success(context, 'Commande réceptionnée avec succès');
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _detailOrder ?? widget.order;
    final role = ref.watch(effectiveRoleProvider);
    final canReceive = ['gestionnaire_stock', 'admin'].contains(role);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusXl)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.numero,
                            style: const TextStyle(
                              fontSize: AppSizes.fontLg,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                          Text(
                            order.fournisseurNom,
                            style: const TextStyle(
                                color: AppColors.gray500,
                                fontSize: AppSizes.fontSm),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm, vertical: AppSizes.xs),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull),
                      ),
                      child: Text(
                        order.statutLabel,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: AppSizes.fontXs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.all(AppSizes.lg),
                    children: [
                      if (order.depotNom != null)
                        _InfoRow(
                            label: 'Dépôt de réception',
                            value: order.depotNom!),
                      if (order.dateLivraisonPrevue != null)
                        _InfoRow(
                          label: 'Livraison prévue',
                          value: AppFormatters.dateShort(order.dateLivraisonPrevue!),
                        ),
                      const SizedBox(height: AppSizes.md),
                      const Text(
                        'Lignes de commande',
                        style: TextStyle(
                          fontSize: AppSizes.fontMd,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      if (order.lignes == null || order.lignes!.isEmpty)
                        const Text('Aucune ligne disponible',
                            style: TextStyle(color: AppColors.gray500))
                      else
                        ...order.lignes!.map(
                          (l) => Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: AppSizes.sm),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              side: const BorderSide(color: AppColors.gray200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.produitNom,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray900,
                                    ),
                                  ),
                                  Text(
                                    l.produitReference,
                                    style: const TextStyle(
                                        fontSize: AppSizes.fontXs,
                                        color: AppColors.gray500),
                                  ),
                                  const SizedBox(height: AppSizes.xs),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _InfoRow(
                                            label: 'Qté commandée',
                                            value: l.quantiteCommandee.toStringAsFixed(0)),
                                      ),
                                      Expanded(
                                        child: _InfoRow(
                                            label: 'Qté reçue',
                                            value: l.quantiteRecue.toStringAsFixed(0)),
                                      ),
                                    ],
                                  ),
                                  _InfoRow(
                                    label: 'Prix unitaire',
                                    value: AppFormatters.gnf(l.prixUnitaire),
                                  ),
                                  _InfoRow(
                                    label: 'Total',
                                    value: AppFormatters.gnf(l.montantTotal),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSizes.xl),
                      if (canReceive && order.isPending)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _receiving ? null : _recevoir,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.md),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMd)),
                            ),
                            icon: _receiving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_outline_rounded),
                            label: const Text('Réceptionner la commande'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label : ',
            style: const TextStyle(
                fontSize: AppSizes.fontSm, color: AppColors.gray500),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray900),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulaire de création ───────────────────────────────────────────────────

class _LigneProduit {
  int? produitId;
  String produitNom = '';
  double quantite = 1;
  double prixUnitaire = 0;
}

class _CreateCommandeSheet extends ConsumerStatefulWidget {
  const _CreateCommandeSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateCommandeSheet> createState() =>
      _CreateCommandeSheetState();
}

class _CreateCommandeSheetState
    extends ConsumerState<_CreateCommandeSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _fournisseurId;
  int? _depotId;
  String? _dateLivraison;
  final _notesCtrl = TextEditingController();
  final List<_LigneProduit> _lignes = [_LigneProduit()];
  bool _isSaving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fournisseurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sélectionnez un fournisseur'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    if (_depotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sélectionnez un dépôt de réception'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    if (_lignes.any((l) => l.produitId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sélectionnez un produit pour chaque ligne'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    setState(() => _isSaving = true);
    final err = await ref.read(_cfProvider.notifier).createCommande(
          fournisseur: _fournisseurId!,
          depotDestination: _depotId!,
          lignes: _lignes
              .map((l) => {
                    'produit': l.produitId,
                    'quantite_commandee': l.quantite.toString(),
                    'prix_unitaire': l.prixUnitaire.toString(),
                  })
              .toList(),
          dateLivraisonPrevue: _dateLivraison,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (err != null) {
      AppSnackbar.error(context, err);
    } else {
      Navigator.of(context).pop();
      widget.onCreated();
      AppSnackbar.success(context, 'Commande créée avec succès');
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final depotsAsync = ref.watch(depotsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => Form(
          key: _formKey,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Nouvelle commande fournisseur',
                style: TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Fournisseur
              suppliersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) =>
                    const Text('Fournisseurs indisponibles',
                        style: TextStyle(color: AppColors.danger)),
                data: (state) => DropdownButtonFormField<int>(
                  initialValue: _fournisseurId,
                  decoration: const InputDecoration(
                    labelText: 'Fournisseur *',
                    prefixIcon: Icon(Icons.handshake_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: state.suppliers
                      .map((s) => DropdownMenuItem(
                          value: s.id, child: Text(s.nom)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _fournisseurId = v),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Dépôt de réception
              depotsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) =>
                    const Text('Dépôts indisponibles',
                        style: TextStyle(color: AppColors.danger)),
                data: (state) => DropdownButtonFormField<int>(
                  initialValue: _depotId,
                  decoration: const InputDecoration(
                    labelText: 'Dépôt de réception *',
                    prefixIcon: Icon(Icons.warehouse_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: state.depots
                      .map((d) => DropdownMenuItem(
                          value: d.id, child: Text(d.nom)))
                      .toList(),
                  onChanged: (v) => setState(() => _depotId = v),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Date livraison prévue
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date livraison prévue (optionnel)',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: const OutlineInputBorder(),
                  hintText: _dateLivraison ?? 'Choisir une date',
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now.add(const Duration(days: 7)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (picked != null && mounted) {
                    setState(() {
                      _dateLivraison =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
              const SizedBox(height: AppSizes.lg),

              // Lignes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Produits à commander',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _lignes.add(_LigneProduit())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              ..._lignes.asMap().entries.map(
                    (entry) => _LigneRow(
                      index: entry.key,
                      ligne: entry.value,
                      canRemove: _lignes.length > 1,
                      onRemove: () =>
                          setState(() => _lignes.removeAt(entry.key)),
                      onChanged: () => setState(() {}),
                    ),
                  ),
              const SizedBox(height: AppSizes.md),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.md),
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
                      : const Text('Passer la commande'),
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

class _LigneRow extends ConsumerStatefulWidget {
  const _LigneRow({
    required this.index,
    required this.ligne,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });
  final int index;
  final _LigneProduit ligne;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  ConsumerState<_LigneRow> createState() => _LigneRowState();
}

class _LigneRowState extends ConsumerState<_LigneRow> {
  late final TextEditingController _qteCtrl;
  late final TextEditingController _prixCtrl;

  @override
  void initState() {
    super.initState();
    _qteCtrl = TextEditingController(
        text: widget.ligne.quantite.toStringAsFixed(0));
    _prixCtrl = TextEditingController(
        text: widget.ligne.prixUnitaire > 0
            ? widget.ligne.prixUnitaire.toStringAsFixed(0)
            : '');
  }

  @override
  void dispose() {
    _qteCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  void _pickProduit() async {
    // ⚠️ `productsSearchProvider` est un FutureProvider.autoDispose qui n'est
    // watché nulle part dans cet écran. Un simple `ref.read(...).valueOrNull`
    // renvoyait `null` (état AsyncLoading au 1ᵉʳ tap) → liste vide → le dialogue
    // ne s'ouvrait jamais. On AWAIT le `.future` pour réellement charger la liste.
    final List<Map<String, dynamic>> all;
    try {
      all = await ref.read(productsSearchProvider('').future);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Impossible de charger les produits.')));
      }
      return;
    }
    if (!mounted) return;
    if (all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aucun produit disponible. Créez d\'abord un produit.')));
      return;
    }

    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        var query = '';
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final q = query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? all
                : all.where((p) {
                    final nom = (p['nom'] as String? ?? '').toLowerCase();
                    final reference =
                        (p['reference'] as String? ?? '').toLowerCase();
                    return nom.contains(q) || reference.contains(q);
                  }).toList();
            return AlertDialog(
              title: const Text('Choisir un produit'),
              content: SizedBox(
                width: double.maxFinite,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un produit…',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setLocal(() => query = v),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('Aucun produit trouvé',
                                  style: TextStyle(color: AppColors.gray500)))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final p = filtered[i];
                                return ListTile(
                                  title: Text(p['nom'] as String? ?? ''),
                                  subtitle: Text(p['reference'] as String? ?? ''),
                                  onTap: () => Navigator.of(ctx).pop(p),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        widget.ligne.produitId = picked['id'] as int?;
        widget.ligne.produitNom = picked['nom'] as String? ?? '';
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickProduit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm, vertical: AppSizes.xs),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray300),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Text(
                        widget.ligne.produitNom.isNotEmpty
                            ? widget.ligne.produitNom
                            : 'Choisir un produit *',
                        style: TextStyle(
                          color: widget.ligne.produitNom.isNotEmpty
                              ? AppColors.gray900
                              : AppColors.gray400,
                          fontSize: AppSizes.fontSm,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.canRemove)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18,
                        color: AppColors.danger),
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.xs),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qteCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantité *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    onChanged: (v) {
                      widget.ligne.quantite =
                          double.tryParse(v) ?? widget.ligne.quantite;
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      if ((double.tryParse(v) ?? 0) <= 0) {
                        return '> 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: TextFormField(
                    controller: _prixCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prix unit. (GNF) *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    onChanged: (v) {
                      widget.ligne.prixUnitaire =
                          double.tryParse(v) ?? widget.ligne.prixUnitaire;
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      if ((double.tryParse(v) ?? 0) <= 0) {
                        return '> 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
