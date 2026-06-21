import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/errors/app_exception.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_button.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';
import 'package:djoulagest_mobile/shared/widgets/app_text_field.dart';
import 'package:djoulagest_mobile/shared/widgets/confirm_dialog.dart';

// Flotte = actif de l'entreprise (pas de rattachement dépôt/zone).
// Écriture : admin + maintenancier (aligné sur LOG_WRITE_VEHICLE backend).
const _canWrite = ['admin', 'maintenancier'];

const _types = [
  ('camion', 'Camion'),
  ('camionnette', 'Camionnette'),
  ('moto', 'Moto'),
  ('voiture', 'Voiture'),
];
const _statuts = [
  ('disponible', 'Disponible'),
  ('en_mission', 'En mission'),
  ('maintenance', 'En maintenance'),
  ('hors_service', 'Hors service'),
];

// ─── État + Notifier ───────────────────────────────────────────────────────

class _Vehicule {
  const _Vehicule(this.raw);
  final Map<String, dynamic> raw;

  int get id => raw['id'] as int;
  String get immatriculation => raw['immatriculation'] as String? ?? '';
  String get typeVehicule => raw['type_vehicule'] as String? ?? '';
  String get typeLabel => raw['type_label'] as String? ?? typeVehicule;
  String get marque => raw['marque'] as String? ?? '';
  String get modele => raw['modele'] as String? ?? '';
  String get statut => raw['statut'] as String? ?? 'disponible';
  String get statutLabel => raw['statut_label'] as String? ?? statut;
  bool get isActive => raw['is_active'] as bool? ?? true;
}

class _VehState {
  const _VehState({this.items = const [], this.total = 0, this.page = 1, this.loadingMore = false});
  final List<_Vehicule> items;
  final int total;
  final int page;
  final bool loadingMore;
  bool get hasMore => items.length < total;
  _VehState copyWith({List<_Vehicule>? items, int? total, int? page, bool? loadingMore}) =>
      _VehState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class _VehiculesNotifier extends AsyncNotifier<_VehState> {
  static const _pageSize = 25;

  @override
  Future<_VehState> build() => _load(1);

  Future<_VehState> _load(int page) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>(
      ApiEndpoints.vehicules,
      queryParameters: {'page': '$page', 'page_size': '$_pageSize'},
    );
    final data = res.data ?? {};
    final raw = (data['results'] as List<dynamic>? ?? [])
        .map((e) => _Vehicule(e as Map<String, dynamic>))
        .toList();
    final prev = page > 1 ? (state.valueOrNull?.items ?? []) : <_Vehicule>[];
    return _VehState(items: [...prev, ...raw], total: data['count'] as int? ?? 0, page: page);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(1));
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || cur.loadingMore) return;
    state = AsyncData(cur.copyWith(loadingMore: true));
    try {
      final next = await _load(cur.page + 1);
      state = AsyncData(next.copyWith(loadingMore: false));
    } catch (_) {
      state = AsyncData(cur.copyWith(loadingMore: false));
    }
  }

  Future<String?> save(Map<String, dynamic> body, {int? id}) async {
    try {
      final api = ref.read(apiClientProvider);
      if (id == null) {
        await api.post<Map<String, dynamic>>(ApiEndpoints.vehicules, data: body);
      } else {
        await api.patch<Map<String, dynamic>>(ApiEndpoints.vehiculeDetail(id), data: body);
      }
      await refresh();
      return null;
    } catch (e) {
      return _err(e);
    }
  }

  Future<String?> delete(int id) async {
    try {
      await ref.read(apiClientProvider).delete<void>(ApiEndpoints.vehiculeDetail(id));
      await refresh();
      return null;
    } catch (e) {
      return _err(e);
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
    return 'Opération impossible. Réessayez.';
  }
}

final _vehiculesProvider =
    AsyncNotifierProvider<_VehiculesNotifier, _VehState>(_VehiculesNotifier.new);

// ─── Écran ────────────────────────────────────────────────────────────────

class VehiculesScreen extends ConsumerStatefulWidget {
  const VehiculesScreen({super.key});

  @override
  ConsumerState<VehiculesScreen> createState() => _VehiculesScreenState();
}

class _VehiculesScreenState extends ConsumerState<VehiculesScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        ref.read(_vehiculesProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({_Vehicule? vehicule}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VehiculeFormSheet(vehicule: vehicule),
    );
  }

  Future<void> _delete(_Vehicule v) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Désactiver le véhicule',
      message: 'Désactiver « ${v.immatriculation} » ? Il n\'apparaîtra plus dans les missions.',
      confirmLabel: 'Désactiver',
      isDanger: true,
    );
    if (ok != true || !mounted) return;
    final err = await ref.read(_vehiculesProvider.notifier).delete(v.id);
    if (!mounted) return;
    err != null ? AppSnackbar.error(context, err) : AppSnackbar.success(context, 'Véhicule désactivé');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_vehiculesProvider);
    final canWrite = _canWrite.contains(ref.watch(effectiveRoleProvider));

    return AppScaffold(
      title: 'Véhicules / Flotte',
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau véhicule'),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.gray300),
                const SizedBox(height: AppSizes.md),
                Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.gray500)),
                const SizedBox(height: AppSizes.sm),
                TextButton(
                  onPressed: () => ref.read(_vehiculesProvider.notifier).refresh(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: const BoxDecoration(color: AppColors.primaryLightBg, shape: BoxShape.circle),
                      child: const Icon(Icons.local_shipping_outlined, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSizes.md),
                    const Text('Aucun véhicule',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray800, fontSize: AppSizes.fontMd)),
                    const SizedBox(height: AppSizes.xs),
                    const Text('Ajoutez votre premier véhicule pour pouvoir créer des missions.',
                        textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm)),
                    if (canWrite) ...[
                      const SizedBox(height: AppSizes.lg),
                      AppButton(label: 'Ajouter un véhicule', onPressed: () => _openForm(), gradient: true),
                    ],
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(_vehiculesProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(AppSizes.paddingPage, AppSizes.sm, AppSizes.paddingPage, AppSizes.xxl),
              itemCount: state.items.length + (state.loadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
              itemBuilder: (context, i) {
                if (i >= state.items.length) {
                  return const Padding(padding: EdgeInsets.all(AppSizes.md), child: Center(child: CircularProgressIndicator()));
                }
                return _VehiculeTile(
                  v: state.items[i],
                  canWrite: canWrite,
                  onEdit: () => _openForm(vehicule: state.items[i]),
                  onDelete: () => _delete(state.items[i]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _VehiculeTile extends StatelessWidget {
  const _VehiculeTile({required this.v, required this.canWrite, required this.onEdit, required this.onDelete});
  final _Vehicule v;
  final bool canWrite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _statutColor => switch (v.statut) {
        'disponible' => AppColors.secondary,
        'en_mission' => AppColors.info,
        'maintenance' => AppColors.accent,
        _ => AppColors.gray400,
      };

  @override
  Widget build(BuildContext context) {
    final sub = [if (v.marque.isNotEmpty) v.marque, if (v.modele.isNotEmpty) v.modele].join(' ');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [BoxShadow(color: AppColors.gray900.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xs),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.primaryLightBg, borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
          child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
        ),
        title: Text(v.immatriculation,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900, fontSize: AppSizes.fontSm)),
        subtitle: Text(
          [v.typeLabel, if (sub.isNotEmpty) sub].join(' · '),
          style: const TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontXs),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: _statutColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
              child: Text(v.statutLabel, style: TextStyle(color: _statutColor, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            if (canWrite)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: AppSizes.iconSm, color: AppColors.gray400),
                onSelected: (x) => x == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Désactiver', style: TextStyle(color: AppColors.danger))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulaire ──────────────────────────────────────────────────────────

class _VehiculeFormSheet extends ConsumerStatefulWidget {
  const _VehiculeFormSheet({this.vehicule});
  final _Vehicule? vehicule;

  @override
  ConsumerState<_VehiculeFormSheet> createState() => _VehiculeFormSheetState();
}

class _VehiculeFormSheetState extends ConsumerState<_VehiculeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _immatCtrl;
  late final TextEditingController _marqueCtrl;
  late final TextEditingController _modeleCtrl;
  late final TextEditingController _anneeCtrl;
  late final TextEditingController _capaciteCtrl;
  String _type = 'camion';
  String _statut = 'disponible';
  bool _loading = false;

  bool get _isEditing => widget.vehicule != null;

  @override
  void initState() {
    super.initState();
    final r = widget.vehicule?.raw ?? const {};
    _immatCtrl = TextEditingController(text: r['immatriculation'] as String? ?? '');
    _marqueCtrl = TextEditingController(text: r['marque'] as String? ?? '');
    _modeleCtrl = TextEditingController(text: r['modele'] as String? ?? '');
    _anneeCtrl = TextEditingController(text: r['annee']?.toString() ?? '');
    _capaciteCtrl = TextEditingController(text: r['capacite_kg']?.toString() ?? '');
    _type = r['type_vehicule'] as String? ?? 'camion';
    _statut = r['statut'] as String? ?? 'disponible';
  }

  @override
  void dispose() {
    _immatCtrl.dispose();
    _marqueCtrl.dispose();
    _modeleCtrl.dispose();
    _anneeCtrl.dispose();
    _capaciteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final body = <String, dynamic>{
      'immatriculation': _immatCtrl.text.trim(),
      'type_vehicule': _type,
      'marque': _marqueCtrl.text.trim(),
      'modele': _modeleCtrl.text.trim(),
      'statut': _statut,
      if (_anneeCtrl.text.trim().isNotEmpty) 'annee': int.tryParse(_anneeCtrl.text.trim()),
      if (_capaciteCtrl.text.trim().isNotEmpty)
        'capacite_kg': num.tryParse(_capaciteCtrl.text.replaceAll(',', '.')),
    };
    final err = await ref
        .read(_vehiculesProvider.notifier)
        .save(body, id: widget.vehicule?.id);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      AppSnackbar.error(context, err);
    } else {
      Navigator.of(context).pop();
      AppSnackbar.success(context, _isEditing ? 'Véhicule modifié' : 'Véhicule créé');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Text(_isEditing ? 'Modifier le véhicule' : 'Nouveau véhicule',
                    style: const TextStyle(fontSize: AppSizes.fontLg, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  controller: _immatCtrl,
                  label: 'Immatriculation *',
                  hint: 'Ex : RC-1234-A',
                  prefixIcon: Icons.pin_outlined,
                  enabled: !_loading,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Immatriculation requise' : null,
                ),
                const SizedBox(height: AppSizes.md),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: _dec('Type *', Icons.category_outlined),
                  items: _types.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
                  onChanged: _loading ? null : (v) => setState(() => _type = v ?? 'camion'),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _marqueCtrl,
                        label: 'Marque',
                        prefixIcon: Icons.business_outlined,
                        enabled: !_loading,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: AppTextField(
                        controller: _modeleCtrl,
                        label: 'Modèle',
                        prefixIcon: Icons.directions_car_outlined,
                        enabled: !_loading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _anneeCtrl,
                        label: 'Année',
                        hint: 'Ex : 2020',
                        prefixIcon: Icons.event_outlined,
                        enabled: !_loading,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: AppTextField(
                        controller: _capaciteCtrl,
                        label: 'Capacité (kg)',
                        hint: 'Ex : 3500',
                        prefixIcon: Icons.scale_outlined,
                        enabled: !_loading,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                DropdownButtonFormField<String>(
                  initialValue: _statut,
                  decoration: _dec('Statut', Icons.flag_outlined),
                  items: _statuts.map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2))).toList(),
                  onChanged: _loading ? null : (v) => setState(() => _statut = v ?? 'disponible'),
                ),
                const SizedBox(height: AppSizes.xl),
                AppButton(
                  label: _isEditing ? 'Enregistrer' : 'Créer le véhicule',
                  onPressed: _loading ? null : _submit,
                  isLoading: _loading,
                  gradient: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: AppSizes.iconMd),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
      );
}
