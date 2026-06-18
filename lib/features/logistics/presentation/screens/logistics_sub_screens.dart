/// Sous-écrans logistique : Maintenances, Pannes, Carburant, Documents véhicule
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/providers/logistics_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MAINTENANCES
// ══════════════════════════════════════════════════════════════════════════════

class _Maintenance {
  final int id;
  final int vehiculeId;
  final String vehiculeImmat;
  final String typeMaintenance;
  final String typeLabel;
  final String statut;
  final String statutLabel;
  final String description;
  final double? cout;
  final String? datePlanifiee;
  final String? dateReelle;

  const _Maintenance({
    required this.id,
    required this.vehiculeId,
    required this.vehiculeImmat,
    required this.typeMaintenance,
    required this.typeLabel,
    required this.statut,
    required this.statutLabel,
    required this.description,
    this.cout,
    this.datePlanifiee,
    this.dateReelle,
  });

  factory _Maintenance.fromJson(Map<String, dynamic> j) => _Maintenance(
        id: j['id'] as int,
        vehiculeId: j['vehicule'] as int? ?? 0,
        vehiculeImmat: j['vehicule_immat'] as String? ?? '',
        typeMaintenance: j['type_maintenance'] as String? ?? '',
        typeLabel: j['type_label'] as String? ?? '',
        statut: j['statut'] as String? ?? '',
        statutLabel: j['statut_label'] as String? ?? '',
        description: j['description'] as String? ?? '',
        cout: j['cout'] != null
            ? double.tryParse(j['cout'].toString())
            : null,
        datePlanifiee: j['date_planifiee'] as String?,
        dateReelle: j['date_reelle'] as String?,
      );

  Color get statusColor {
    switch (statut) {
      case 'planifiee':
        return AppColors.accent;
      case 'en_cours':
        return AppColors.primary;
      case 'terminee':
        return AppColors.secondary;
      default:
        return AppColors.gray400;
    }
  }
}

class _MaintState {
  final List<_Maintenance> items;
  final int total;
  final int page;
  final bool isLoadingMore;

  const _MaintState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
  });

  _MaintState copyWith({
    List<_Maintenance>? items,
    int? total,
    int? page,
    bool? isLoadingMore,
  }) =>
      _MaintState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class _MaintNotifier extends AutoDisposeAsyncNotifier<_MaintState> {
  @override
  Future<_MaintState> build() async => _fetch(1);

  Future<_MaintState> _fetch(int page) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>(
      ApiEndpoints.maintenances,
      queryParameters: {'page': page, 'page_size': 25},
    );
    final data = res.data!;
    final results = (data['results'] as List)
        .map((e) => _Maintenance.fromJson(e as Map<String, dynamic>))
        .toList();
    return _MaintState(
      items: results,
      total: data['count'] as int? ?? results.length,
      page: page,
    );
  }

  Future<void> refresh() async => state = AsyncData(await _fetch(1));

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || cur.isLoadingMore || cur.items.length >= cur.total) {
      return;
    }
    state = AsyncData(cur.copyWith(isLoadingMore: true));
    try {
      final next = await _fetch(cur.page + 1);
      state = AsyncData(next.copyWith(
        items: [...cur.items, ...next.items],
        page: cur.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(cur.copyWith(isLoadingMore: false));
    }
  }
}

final _maintProvider =
    AutoDisposeAsyncNotifierProvider<_MaintNotifier, _MaintState>(
        _MaintNotifier.new);

class MaintenancesScreen extends ConsumerStatefulWidget {
  const MaintenancesScreen({super.key});

  @override
  ConsumerState<MaintenancesScreen> createState() => _MaintenancesScreenState();
}

class _MaintenancesScreenState extends ConsumerState<MaintenancesScreen> {
  late final ScrollController _scrollCtrl;
  static const _canCreate = ['admin', 'superviseur', 'maintenancier'];

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()
      ..addListener(() {
        if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200) {
          ref.read(_maintProvider.notifier).loadMore();
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
      builder: (_) => _MaintCreateSheet(
        onCreated: () => ref.read(_maintProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_maintProvider);
    final role = ref.watch(effectiveRoleProvider);

    return AppScaffold(
      title: 'Maintenances',
      showBottomNav: false,
      floatingActionButton: _canCreate.contains(role)
          ? FloatingActionButton.extended(
              onPressed: _showCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Planifier'),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorRetry(
          message: 'Impossible de charger les maintenances',
          onRetry: () => ref.read(_maintProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return const _EmptyState(
                icon: Icons.build_outlined, label: 'Aucune maintenance');
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(_maintProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingPage, AppSizes.md,
                  AppSizes.paddingPage, AppSizes.xxl),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.xs),
              itemBuilder: (ctx, i) {
                if (i == state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final m = state.items[i];
                return _InfoTile(
                  icon: Icons.build_outlined,
                  iconColor: m.statusColor,
                  title: '${m.typeLabel} — ${m.vehiculeImmat}',
                  subtitle: m.description,
                  trailing: _StatusBadge(label: m.statutLabel, color: m.statusColor),
                  detail: m.datePlanifiee != null
                      ? 'Planifiée : ${m.datePlanifiee}'
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MaintCreateSheet extends ConsumerStatefulWidget {
  const _MaintCreateSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_MaintCreateSheet> createState() => _MaintCreateSheetState();
}

class _MaintCreateSheetState extends ConsumerState<_MaintCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _coutCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int? _vehiculeId;
  String _type = 'preventive';
  bool _isSaving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _coutCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      _dateCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.maintenances,
        data: {
          'vehicule': _vehiculeId,
          'type_maintenance': _type,
          'description': _descCtrl.text.trim(),
          if (_coutCtrl.text.isNotEmpty)
            'cout': double.tryParse(_coutCtrl.text.replaceAll(',', '.')),
          'date_planifiee': _dateCtrl.text,
          if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Maintenance planifiée'),
          backgroundColor: AppColors.secondary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur : $e'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculesAsync = ref.watch(vehiculesSimpleProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingPage),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHeader(
                  title: 'Planifier une maintenance',
                  onClose: () => Navigator.of(context).pop()),
              const SizedBox(height: AppSizes.md),
              vehiculesAsync.when(
                loading: () =>
                    const SizedBox(height: 56, child: Center(child: LinearProgressIndicator())),
                error: (_, __) => const Text('Impossible de charger les véhicules',
                    style: TextStyle(color: AppColors.danger)),
                data: (vehicules) => DropdownButtonFormField<int>(
                  initialValue: _vehiculeId,
                  decoration: const InputDecoration(
                      labelText: 'Véhicule *', border: OutlineInputBorder()),
                  items: vehicules
                      .map((v) => DropdownMenuItem(
                          value: v.id, child: Text(v.immatriculation)))
                      .toList(),
                  onChanged: (v) => setState(() => _vehiculeId = v),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                    labelText: 'Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'preventive', child: Text('Préventive')),
                  DropdownMenuItem(value: 'corrective', child: Text('Corrective')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'preventive'),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Description *', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coutCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Coût estimé (GNF)',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _dateCtrl,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Date planifiée *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Notes', border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSizes.lg),
              _SaveButton(isSaving: _isSaving, label: 'Planifier', onTap: _save),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PANNES
// ══════════════════════════════════════════════════════════════════════════════

class _Panne {
  final int id;
  final int vehiculeId;
  final String vehiculeImmat;
  final String description;
  final String statut;
  final String statutLabel;
  final String dateDeclaration;
  final double? coutReparation;

  const _Panne({
    required this.id,
    required this.vehiculeId,
    required this.vehiculeImmat,
    required this.description,
    required this.statut,
    required this.statutLabel,
    required this.dateDeclaration,
    this.coutReparation,
  });

  factory _Panne.fromJson(Map<String, dynamic> j) => _Panne(
        id: j['id'] as int,
        vehiculeId: j['vehicule'] as int? ?? 0,
        vehiculeImmat: j['vehicule_immat'] as String? ?? '',
        description: j['description'] as String? ?? '',
        statut: j['statut'] as String? ?? '',
        statutLabel: j['statut_label'] as String? ?? '',
        dateDeclaration: j['date_declaration'] as String? ?? '',
        coutReparation: j['cout_reparation'] != null
            ? double.tryParse(j['cout_reparation'].toString())
            : null,
      );

  bool get isResolue => statut == 'resolue';
  Color get statusColor => isResolue ? AppColors.secondary : AppColors.danger;
}

class _PanneState {
  final List<_Panne> items;
  final int total;
  final int page;
  final bool isLoadingMore;

  const _PanneState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
  });

  _PanneState copyWith({
    List<_Panne>? items,
    int? total,
    int? page,
    bool? isLoadingMore,
  }) =>
      _PanneState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class _PanneNotifier extends AutoDisposeAsyncNotifier<_PanneState> {
  @override
  Future<_PanneState> build() async => _fetch(1);

  Future<_PanneState> _fetch(int page) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>(
      ApiEndpoints.pannes,
      queryParameters: {'page': page, 'page_size': 25},
    );
    final data = res.data!;
    final results = (data['results'] as List)
        .map((e) => _Panne.fromJson(e as Map<String, dynamic>))
        .toList();
    return _PanneState(
      items: results,
      total: data['count'] as int? ?? results.length,
      page: page,
    );
  }

  Future<void> refresh() async => state = AsyncData(await _fetch(1));

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || cur.isLoadingMore || cur.items.length >= cur.total) {
      return;
    }
    state = AsyncData(cur.copyWith(isLoadingMore: true));
    try {
      final next = await _fetch(cur.page + 1);
      state = AsyncData(next.copyWith(
        items: [...cur.items, ...next.items],
        page: cur.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(cur.copyWith(isLoadingMore: false));
    }
  }
}

final _panneProvider =
    AutoDisposeAsyncNotifierProvider<_PanneNotifier, _PanneState>(
        _PanneNotifier.new);

class PannesScreen extends ConsumerStatefulWidget {
  const PannesScreen({super.key});

  @override
  ConsumerState<PannesScreen> createState() => _PannesScreenState();
}

class _PannesScreenState extends ConsumerState<PannesScreen> {
  late final ScrollController _scrollCtrl;
  static const _canCreate = ['chauffeur', 'maintenancier', 'admin', 'superviseur'];
  static const _canResolve = ['maintenancier', 'admin', 'superviseur'];

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()
      ..addListener(() {
        if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200) {
          ref.read(_panneProvider.notifier).loadMore();
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
      builder: (_) => _PanneCreateSheet(
        onCreated: () => ref.read(_panneProvider.notifier).refresh(),
      ),
    );
  }

  Future<void> _resoudre(_Panne panne) async {
    final coutCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Résoudre la panne'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Véhicule : ${panne.vehiculeImmat}'),
            const SizedBox(height: 12),
            TextField(
              controller: coutCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Coût de réparation (GNF)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.panneResoudre(panne.id),
        data: {
          if (coutCtrl.text.isNotEmpty)
            'cout_reparation':
                double.tryParse(coutCtrl.text.replaceAll(',', '.')),
        },
      );
      ref.read(_panneProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Panne résolue'),
          backgroundColor: AppColors.secondary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur : $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_panneProvider);
    final role = ref.watch(effectiveRoleProvider);

    return AppScaffold(
      title: 'Pannes',
      showBottomNav: false,
      floatingActionButton: _canCreate.contains(role)
          ? FloatingActionButton.extended(
              onPressed: _showCreate,
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Déclarer'),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorRetry(
          message: 'Impossible de charger les pannes',
          onRetry: () => ref.read(_panneProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return const _EmptyState(
                icon: Icons.check_circle_outline_rounded,
                label: 'Aucune panne déclarée');
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(_panneProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingPage, AppSizes.md,
                  AppSizes.paddingPage, AppSizes.xxl),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.xs),
              itemBuilder: (ctx, i) {
                if (i == state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final p = state.items[i];
                return _InfoTile(
                  icon: Icons.warning_amber_rounded,
                  iconColor: p.statusColor,
                  title: p.vehiculeImmat,
                  subtitle: p.description,
                  trailing: _StatusBadge(
                      label: p.statutLabel, color: p.statusColor),
                  detail: p.coutReparation != null
                      ? 'Réparation : ${AppFormatters.gnf(p.coutReparation!)}'
                      : null,
                  action: (!p.isResolue && _canResolve.contains(role))
                      ? TextButton(
                          onPressed: () => _resoudre(p),
                          child: const Text('Résoudre',
                              style: TextStyle(color: AppColors.secondary)),
                        )
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PanneCreateSheet extends ConsumerStatefulWidget {
  const _PanneCreateSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_PanneCreateSheet> createState() => _PanneCreateSheetState();
}

class _PanneCreateSheetState extends ConsumerState<_PanneCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  int? _vehiculeId;
  bool _isSaving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.pannes,
        data: {
          'vehicule': _vehiculeId,
          'description': _descCtrl.text.trim(),
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Panne déclarée'),
          backgroundColor: AppColors.secondary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur : $e'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculesAsync = ref.watch(vehiculesSimpleProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingPage),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHeader(
                  title: 'Déclarer une panne',
                  onClose: () => Navigator.of(context).pop()),
              const SizedBox(height: AppSizes.md),
              vehiculesAsync.when(
                loading: () => const SizedBox(
                    height: 56,
                    child: Center(child: LinearProgressIndicator())),
                error: (_, __) => const Text('Véhicules indisponibles',
                    style: TextStyle(color: AppColors.danger)),
                data: (vehicules) => DropdownButtonFormField<int>(
                  initialValue: _vehiculeId,
                  decoration: const InputDecoration(
                      labelText: 'Véhicule *', border: OutlineInputBorder()),
                  items: vehicules
                      .map((v) => DropdownMenuItem(
                          value: v.id, child: Text(v.immatriculation)))
                      .toList(),
                  onChanged: (v) => setState(() => _vehiculeId = v),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description de la panne *',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.lg),
              _SaveButton(
                  isSaving: _isSaving, label: 'Déclarer la panne', onTap: _save),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CARBURANT
// ══════════════════════════════════════════════════════════════════════════════

class _Carburant {
  final int id;
  final int vehiculeId;
  final String vehiculeImmat;
  final String typeCarburant;
  final double quantiteLitres;
  final double prixParLitre;
  final double montantTotal;
  final int? kilometrage;
  final String datePlein;
  final String? station;

  const _Carburant({
    required this.id,
    required this.vehiculeId,
    required this.vehiculeImmat,
    required this.typeCarburant,
    required this.quantiteLitres,
    required this.prixParLitre,
    required this.montantTotal,
    this.kilometrage,
    required this.datePlein,
    this.station,
  });

  factory _Carburant.fromJson(Map<String, dynamic> j) => _Carburant(
        id: j['id'] as int,
        vehiculeId: j['vehicule'] as int? ?? 0,
        vehiculeImmat: j['vehicule_immat'] as String? ?? '',
        typeCarburant: j['type_carburant'] as String? ?? '',
        quantiteLitres:
            double.tryParse(j['quantite_litres'].toString()) ?? 0,
        prixParLitre:
            double.tryParse(j['prix_par_litre'].toString()) ?? 0,
        montantTotal:
            double.tryParse(j['montant_total'].toString()) ?? 0,
        kilometrage: j['kilometrage'] as int?,
        datePlein: j['date_plein'] as String? ?? '',
        station: j['station'] as String?,
      );
}

class _CarburantState {
  final List<_Carburant> items;
  final int total;
  final int page;
  final bool isLoadingMore;

  const _CarburantState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
  });

  _CarburantState copyWith({
    List<_Carburant>? items,
    int? total,
    int? page,
    bool? isLoadingMore,
  }) =>
      _CarburantState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class _CarburantNotifier
    extends AutoDisposeAsyncNotifier<_CarburantState> {
  @override
  Future<_CarburantState> build() async => _fetch(1);

  Future<_CarburantState> _fetch(int page) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>(
      ApiEndpoints.carburant,
      queryParameters: {'page': page, 'page_size': 25},
    );
    final data = res.data!;
    final results = (data['results'] as List)
        .map((e) => _Carburant.fromJson(e as Map<String, dynamic>))
        .toList();
    return _CarburantState(
      items: results,
      total: data['count'] as int? ?? results.length,
      page: page,
    );
  }

  Future<void> refresh() async => state = AsyncData(await _fetch(1));

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || cur.isLoadingMore || cur.items.length >= cur.total) {
      return;
    }
    state = AsyncData(cur.copyWith(isLoadingMore: true));
    try {
      final next = await _fetch(cur.page + 1);
      state = AsyncData(next.copyWith(
        items: [...cur.items, ...next.items],
        page: cur.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(cur.copyWith(isLoadingMore: false));
    }
  }
}

final _carburantProvider =
    AutoDisposeAsyncNotifierProvider<_CarburantNotifier, _CarburantState>(
        _CarburantNotifier.new);

class CarburantScreen extends ConsumerStatefulWidget {
  const CarburantScreen({super.key});

  @override
  ConsumerState<CarburantScreen> createState() => _CarburantScreenState();
}

class _CarburantScreenState extends ConsumerState<CarburantScreen> {
  late final ScrollController _scrollCtrl;
  static const _canCreate = ['chauffeur', 'maintenancier', 'admin'];

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()
      ..addListener(() {
        if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200) {
          ref.read(_carburantProvider.notifier).loadMore();
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
      builder: (_) => _CarburantCreateSheet(
        onCreated: () => ref.read(_carburantProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_carburantProvider);
    final role = ref.watch(effectiveRoleProvider);

    return AppScaffold(
      title: 'Consommation carburant',
      showBottomNav: false,
      floatingActionButton: _canCreate.contains(role)
          ? FloatingActionButton.extended(
              onPressed: _showCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.local_gas_station_rounded),
              label: const Text('Plein'),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorRetry(
          message: 'Impossible de charger les consommations',
          onRetry: () => ref.read(_carburantProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return const _EmptyState(
                icon: Icons.local_gas_station_outlined,
                label: 'Aucune consommation enregistrée');
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(_carburantProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingPage, AppSizes.md,
                  AppSizes.paddingPage, AppSizes.xxl),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.xs),
              itemBuilder: (ctx, i) {
                if (i == state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final c = state.items[i];
                return _InfoTile(
                  icon: Icons.local_gas_station_rounded,
                  iconColor: AppColors.accent,
                  title: '${c.vehiculeImmat} — ${c.typeCarburant.toUpperCase()}',
                  subtitle:
                      '${c.quantiteLitres} L × ${AppFormatters.gnf(c.prixParLitre)}/L',
                  trailing: Text(
                    AppFormatters.gnf(c.montantTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.fontSm,
                      color: AppColors.gray900,
                    ),
                  ),
                  detail: c.station != null
                      ? '${c.datePlein} · ${c.station}'
                      : c.datePlein,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CarburantCreateSheet extends ConsumerStatefulWidget {
  const _CarburantCreateSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CarburantCreateSheet> createState() =>
      _CarburantCreateSheetState();
}

class _CarburantCreateSheetState
    extends ConsumerState<_CarburantCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _qteCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  int? _vehiculeId;
  String _typeCarburant = 'gasoil';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _qteCtrl.dispose();
    _prixCtrl.dispose();
    _kmCtrl.dispose();
    _stationCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) {
      _dateCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.carburant,
        data: {
          'vehicule': _vehiculeId,
          'type_carburant': _typeCarburant,
          'quantite_litres':
              double.parse(_qteCtrl.text.replaceAll(',', '.')),
          'prix_par_litre':
              double.parse(_prixCtrl.text.replaceAll(',', '.')),
          'kilometrage': int.tryParse(_kmCtrl.text),
          'date_plein': _dateCtrl.text,
          if (_stationCtrl.text.isNotEmpty) 'station': _stationCtrl.text.trim(),
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Plein enregistré'),
          backgroundColor: AppColors.secondary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur : $e'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculesAsync = ref.watch(vehiculesSimpleProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingPage),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHeader(
                  title: 'Enregistrer un plein',
                  onClose: () => Navigator.of(context).pop()),
              const SizedBox(height: AppSizes.md),
              vehiculesAsync.when(
                loading: () => const SizedBox(
                    height: 56,
                    child: Center(child: LinearProgressIndicator())),
                error: (_, __) => const Text('Véhicules indisponibles',
                    style: TextStyle(color: AppColors.danger)),
                data: (vehicules) => DropdownButtonFormField<int>(
                  initialValue: _vehiculeId,
                  decoration: const InputDecoration(
                      labelText: 'Véhicule *', border: OutlineInputBorder()),
                  items: vehicules
                      .map((v) => DropdownMenuItem(
                          value: v.id, child: Text(v.immatriculation)))
                      .toList(),
                  onChanged: (v) => setState(() => _vehiculeId = v),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              DropdownButtonFormField<String>(
                initialValue: _typeCarburant,
                decoration: const InputDecoration(
                    labelText: 'Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'gasoil', child: Text('Gasoil')),
                  DropdownMenuItem(value: 'essence', child: Text('Essence')),
                ],
                onChanged: (v) =>
                    setState(() => _typeCarburant = v ?? 'gasoil'),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qteCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Litres *', border: OutlineInputBorder()),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
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
                      controller: _prixCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Prix/L *', border: OutlineInputBorder()),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _kmCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Kilométrage *',
                          border: OutlineInputBorder()),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        if (int.tryParse(v.trim()) == null) return 'Invalide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _dateCtrl,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _stationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Station-service', border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSizes.lg),
              _SaveButton(isSaving: _isSaving, label: 'Enregistrer', onTap: _save),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DOCUMENTS VÉHICULE
// ══════════════════════════════════════════════════════════════════════════════

class _DocVehicule {
  final int id;
  final int vehiculeId;
  final String vehiculeImmat;
  final String typeDocument;
  final String typeLabel;
  final String? dateExpiration;
  final bool isExpire;
  final String? notes;

  const _DocVehicule({
    required this.id,
    required this.vehiculeId,
    required this.vehiculeImmat,
    required this.typeDocument,
    required this.typeLabel,
    this.dateExpiration,
    required this.isExpire,
    this.notes,
  });

  factory _DocVehicule.fromJson(Map<String, dynamic> j) => _DocVehicule(
        id: j['id'] as int,
        vehiculeId: j['vehicule'] as int? ?? 0,
        vehiculeImmat: j['vehicule_immat'] as String? ?? '',
        typeDocument: j['type_document'] as String? ?? '',
        typeLabel: j['type_label'] as String? ?? '',
        dateExpiration: j['date_expiration'] as String?,
        isExpire: j['is_expire'] as bool? ?? false,
        notes: j['notes'] as String?,
      );
}

class _DocState {
  final List<_DocVehicule> items;
  final int total;
  final int page;
  final bool isLoadingMore;

  const _DocState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
  });

  _DocState copyWith({
    List<_DocVehicule>? items,
    int? total,
    int? page,
    bool? isLoadingMore,
  }) =>
      _DocState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class _DocNotifier extends AutoDisposeAsyncNotifier<_DocState> {
  @override
  Future<_DocState> build() async => _fetch(1);

  Future<_DocState> _fetch(int page) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>(
      ApiEndpoints.documentsVehicule,
      queryParameters: {'page': page, 'page_size': 25},
    );
    final data = res.data!;
    final results = (data['results'] as List)
        .map((e) => _DocVehicule.fromJson(e as Map<String, dynamic>))
        .toList();
    return _DocState(
      items: results,
      total: data['count'] as int? ?? results.length,
      page: page,
    );
  }

  Future<void> refresh() async => state = AsyncData(await _fetch(1));

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || cur.isLoadingMore || cur.items.length >= cur.total) {
      return;
    }
    state = AsyncData(cur.copyWith(isLoadingMore: true));
    try {
      final next = await _fetch(cur.page + 1);
      state = AsyncData(next.copyWith(
        items: [...cur.items, ...next.items],
        page: cur.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(cur.copyWith(isLoadingMore: false));
    }
  }
}

final _docProvider =
    AutoDisposeAsyncNotifierProvider<_DocNotifier, _DocState>(
        _DocNotifier.new);

class DocumentsVehiculeScreen extends ConsumerStatefulWidget {
  const DocumentsVehiculeScreen({super.key});

  @override
  ConsumerState<DocumentsVehiculeScreen> createState() =>
      _DocumentsVehiculeScreenState();
}

class _DocumentsVehiculeScreenState
    extends ConsumerState<DocumentsVehiculeScreen> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()
      ..addListener(() {
        if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200) {
          ref.read(_docProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_docProvider);

    return AppScaffold(
      title: 'Documents véhicule',
      showBottomNav: false,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorRetry(
          message: 'Impossible de charger les documents',
          onRetry: () => ref.read(_docProvider.notifier).refresh(),
        ),
        data: (state) {
          final expired = state.items.where((d) => d.isExpire).length;
          return Column(
            children: [
              // Alerte documents expirés
              if (expired > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(
                      AppSizes.paddingPage, AppSizes.md,
                      AppSizes.paddingPage, 0),
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.danger, size: AppSizes.iconSm),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        '$expired document${expired > 1 ? 's' : ''} expiré${expired > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: AppSizes.fontXs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: state.items.isEmpty
                    ? const _EmptyState(
                        icon: Icons.folder_outlined,
                        label: 'Aucun document enregistré')
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(_docProvider.notifier).refresh(),
                        child: ListView.separated(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(
                              AppSizes.paddingPage, AppSizes.md,
                              AppSizes.paddingPage, AppSizes.xxl),
                          itemCount: state.items.length +
                              (state.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSizes.xs),
                          itemBuilder: (ctx, i) {
                            if (i == state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(AppSizes.md),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            }
                            final d = state.items[i];
                            return _InfoTile(
                              icon: Icons.description_outlined,
                              iconColor: d.isExpire
                                  ? AppColors.danger
                                  : AppColors.primary,
                              title: '${d.vehiculeImmat} — ${d.typeLabel}',
                              subtitle: d.notes,
                              trailing: d.dateExpiration != null
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          d.dateExpiration!,
                                          style: TextStyle(
                                            fontSize: AppSizes.fontXs,
                                            color: d.isExpire
                                                ? AppColors.danger
                                                : AppColors.gray500,
                                            fontWeight: d.isExpire
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (d.isExpire)
                                          const Text('EXPIRÉ',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: AppColors.danger,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              )),
                                      ],
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS PARTAGÉS (internes à ce fichier)
// ══════════════════════════════════════════════════════════════════════════════

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              )),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.close_rounded), onPressed: onClose),
        ],
      );
}

class _SaveButton extends StatelessWidget {
  const _SaveButton(
      {required this.isSaving, required this.label, required this.onTap});
  final bool isSaving;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSaving ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(label),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.detail,
    this.action,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppSizes.fontSm,
                        color: AppColors.gray900,
                      )),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(detail!,
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray400,
                        )),
                  ],
                  if (action != null) action!,
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSizes.sm),
              trailing!,
            ],
          ],
        ),
      );
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: AppSizes.iconXxl, color: AppColors.gray300),
            const SizedBox(height: AppSizes.md),
            Text(message,
                style: const TextStyle(color: AppColors.gray500)),
            const SizedBox(height: AppSizes.sm),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizes.iconXxl, color: AppColors.gray200),
            const SizedBox(height: AppSizes.md),
            Text(label,
                style: const TextStyle(color: AppColors.gray500)),
          ],
        ),
      );
}
