import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/features/depots/domain/entities/depot_entity.dart';
import 'package:djoulagest_mobile/features/depots/presentation/providers/depots_provider.dart';
import 'package:djoulagest_mobile/features/zones/domain/entities/zone_entity.dart';
import 'package:djoulagest_mobile/features/zones/presentation/providers/zones_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/map_picker_sheet.dart';
import 'package:djoulagest_mobile/shared/widgets/app_button.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';
import 'package:djoulagest_mobile/shared/widgets/app_text_field.dart';
import 'package:djoulagest_mobile/shared/widgets/confirm_dialog.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';

class DepotsScreen extends ConsumerStatefulWidget {
  const DepotsScreen({super.key});

  @override
  ConsumerState<DepotsScreen> createState() => _DepotsScreenState();
}

class _DepotsScreenState extends ConsumerState<DepotsScreen> {
  static const _canWrite = ['admin'];

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(depotsProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(depotsProvider.notifier).search(query);
    });
  }

  Future<void> _openForm({DepotEntity? depot}) async {
    final zonesAsync = ref.read(zonesProvider);
    if (zonesAsync.isLoading) {
      AppSnackbar.error(context, 'Chargement des zones en cours, veuillez patienter…');
      return;
    }
    final zones = zonesAsync.valueOrNull?.zones ?? [];
    if (zones.isEmpty) {
      AppSnackbar.error(context, 'Aucune zone disponible. Créez d\'abord une zone.');
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DepotFormSheet(depot: depot, zones: zones),
    );
  }

  Future<void> _delete(DepotEntity depot) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Supprimer le dépôt',
      message: 'Supprimer « ${depot.nom} » ? Cette action est irréversible.',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirmed != true || !mounted) return;
    final error = await ref.read(depotsProvider.notifier).delete(depot.id);
    if (!mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.success(context, 'Dépôt supprimé');
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(depotsProvider);
    final zonesAsync = ref.watch(zonesProvider);
    final zones = zonesAsync.valueOrNull?.zones ?? [];
    final filtreZoneId = asyncState.valueOrNull?.filtreZoneId;
    final canWrite = _canWrite.contains(ref.watch(effectiveRoleProvider));

    return AppScaffold(
      title: 'Dépôts',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingPage, AppSizes.sm, AppSizes.paddingPage, 0,
            ),
            child: Column(
              children: [
                // Recherche
                AppTextField(
                  label: 'Rechercher',
                  controller: _searchCtrl,
                  hint: 'Rechercher un dépôt…',
                  prefixIcon: Icons.search_rounded,
                  onChanged: _onSearchChanged,
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: AppSizes.iconSm),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(depotsProvider.notifier).search('');
                          },
                        )
                      : null,
                ),
                const SizedBox(height: AppSizes.sm),

                // Filtre par zone (chips défilables)
                if (zones.isNotEmpty)
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _ZoneChip(
                          label: 'Toutes',
                          selected: filtreZoneId == null,
                          onTap: () => ref.read(depotsProvider.notifier).filtrerParZone(null),
                        ),
                        ...zones.map((z) => _ZoneChip(
                              label: z.name,
                              selected: filtreZoneId == z.id,
                              onTap: () => ref.read(depotsProvider.notifier).filtrerParZone(z.id),
                            )),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSizes.sm),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: asyncState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    Text(e.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () => ref.read(depotsProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.depots.isEmpty) {
                  return _EmptyState(
                    hasSearch: state.search.isNotEmpty || state.filtreZoneId != null,
                    canWrite: canWrite,
                    onAdd: () => _openForm(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(depotsProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingPage, 0, AppSizes.paddingPage, AppSizes.xxl,
                    ),
                    itemCount: state.depots.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                    itemBuilder: (context, i) {
                      if (i >= state.depots.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _DepotTile(
                        depot: state.depots[i],
                        canWrite: canWrite,
                        onEdit: () => _openForm(depot: state.depots[i]),
                        onDelete: () => _delete(state.depots[i]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau dépôt'),
            )
          : null,
    );
  }
}

// ─── Chip filtre zone ─────────────────────────────────────────────────────────

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.xs),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.gray200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.gray600,
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tuile dépôt ─────────────────────────────────────────────────────────────

class _DepotTile extends StatelessWidget {
  const _DepotTile({required this.depot, required this.canWrite, required this.onEdit, required this.onDelete});
  final DepotEntity depot;
  final bool canWrite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.xs,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.secondaryLightBg,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Center(
            child: Text(
              depot.initials,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
                fontSize: AppSizes.fontSm,
              ),
            ),
          ),
        ),
        title: Text(
          depot.nom,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
            fontSize: AppSizes.fontSm,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  depot.zoneName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: AppSizes.fontXs,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (depot.adresse != null && depot.adresse!.isNotEmpty)
              Text(
                depot.adresse!,
                style: const TextStyle(color: AppColors.gray400, fontSize: AppSizes.fontXs),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (depot.gestionnaireName != null && depot.gestionnaireName!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 12, color: AppColors.gray400),
                  const SizedBox(width: 4),
                  Text(
                    depot.gestionnaireName!,
                    style: const TextStyle(color: AppColors.gray400, fontSize: AppSizes.fontXs),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: depot.isActive
                    ? AppColors.secondary.withValues(alpha: 0.1)
                    : AppColors.gray200,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                depot.isActive ? 'Actif' : 'Inactif',
                style: TextStyle(
                  color: depot.isActive ? AppColors.secondary : AppColors.gray500,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (canWrite)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: AppSizes.iconSm, color: AppColors.gray400),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer', style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─── État vide ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch, required this.canWrite, required this.onAdd});
  final bool hasSearch;
  final bool canWrite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.secondaryLightBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warehouse_outlined, size: 36, color: AppColors.secondary),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              hasSearch ? 'Aucun dépôt trouvé' : 'Aucun dépôt créé',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
                fontSize: AppSizes.fontMd,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              hasSearch
                  ? 'Essayez un autre terme ou filtre.'
                  : 'Créez votre premier dépôt.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
            ),
            if (!hasSearch && canWrite) ...[
              const SizedBox(height: AppSizes.lg),
              AppButton(label: 'Créer un dépôt', onPressed: onAdd, gradient: true),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Formulaire dépôt (bottom sheet) ─────────────────────────────────────────

class _DepotFormSheet extends ConsumerStatefulWidget {
  const _DepotFormSheet({this.depot, required this.zones});
  final DepotEntity? depot;
  final List<ZoneEntity> zones;

  @override
  ConsumerState<_DepotFormSheet> createState() => _DepotFormSheetState();
}

class _DepotFormSheetState extends ConsumerState<_DepotFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _adresseCtrl;
  LatLng? _position;
  int? _selectedZoneId;
  bool _loading = false;

  bool get _isEditing => widget.depot != null;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.depot?.nom ?? '');
    _codeCtrl = TextEditingController(text: widget.depot?.code ?? '');
    _adresseCtrl = TextEditingController(text: widget.depot?.adresse ?? '');
    if (widget.depot?.latitude != null && widget.depot?.longitude != null) {
      _position = LatLng(widget.depot!.latitude!, widget.depot!.longitude!);
    }
    // En édition : pré-remplir la zone existante. En création : forcer un choix explicite.
    _selectedZoneId = widget.depot?.zoneId;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _codeCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPosition() async {
    final result = await MapPickerSheet.show(context, initial: _position);
    if (result != null) setState(() => _position = result);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedZoneId == null) {
      AppSnackbar.error(context, 'Veuillez sélectionner une zone');
      return;
    }
    setState(() => _loading = true);

    final nom = _nomCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final adresse = _adresseCtrl.text.trim();
    final lat = _position?.latitude;
    final lng = _position?.longitude;

    final String? error;
    if (_isEditing) {
      error = await ref.read(depotsProvider.notifier).edit(
            id: widget.depot!.id,
            nom: nom,
            code: code,
            zoneId: _selectedZoneId!,
            adresse: adresse.isEmpty ? null : adresse,
            latitude: lat,
            longitude: lng,
          );
    } else {
      error = await ref.read(depotsProvider.notifier).create(
            nom: nom,
            code: code,
            zoneId: _selectedZoneId!,
            adresse: adresse.isEmpty ? null : adresse,
            latitude: lat,
            longitude: lng,
          );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      Navigator.of(context).pop();
      AppSnackbar.success(context, _isEditing ? 'Dépôt modifié' : 'Dépôt créé');
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
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  _isEditing ? 'Modifier le dépôt' : 'Nouveau dépôt',
                  style: const TextStyle(
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Sélecteur de zone (toujours visible — zones garanties non-vides par _openForm)
                const Text(
                  'Zone *',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                DropdownButtonFormField<int>(
                  initialValue: _selectedZoneId,
                  hint: const Text('Choisir une zone'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, size: AppSizes.iconMd),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: const BorderSide(color: AppColors.gray200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: AppSizes.sm,
                    ),
                  ),
                  items: widget.zones
                      .map((z) => DropdownMenuItem(value: z.id, child: Text(z.name)))
                      .toList(),
                  onChanged: _loading ? null : (v) => setState(() => _selectedZoneId = v),
                  validator: (v) => v == null ? 'Zone requise' : null,
                ),
                const SizedBox(height: AppSizes.md),

                AppTextField(
                  controller: _codeCtrl,
                  label: 'Code *',
                  hint: 'Ex : DEP-001',
                  prefixIcon: Icons.qr_code_outlined,
                  enabled: !_loading,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Code requis' : null,
                ),
                const SizedBox(height: AppSizes.md),

                AppTextField(
                  controller: _nomCtrl,
                  label: 'Nom du dépôt *',
                  hint: 'Ex : Dépôt Central Kaloum',
                  prefixIcon: Icons.warehouse_outlined,
                  enabled: !_loading,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: AppSizes.md),

                AppTextField(
                  controller: _adresseCtrl,
                  label: 'Adresse (optionnel)',
                  hint: 'Adresse physique du dépôt',
                  prefixIcon: Icons.place_outlined,
                  enabled: !_loading,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSizes.md),

                // Position GPS — sélection sur la carte (pas de saisie manuelle)
                const Text(
                  'Position GPS (optionnel)',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                _PositionPickerTile(
                  position: _position,
                  enabled: !_loading,
                  onTap: _pickPosition,
                  onClear: () => setState(() => _position = null),
                ),
                const SizedBox(height: AppSizes.xl),

                AppButton(
                  label: _isEditing ? 'Enregistrer' : 'Créer le dépôt',
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
}

// ── Tuile sélecteur de position (carte) ──────────────────────────────────────

class _PositionPickerTile extends StatelessWidget {
  const _PositionPickerTile({
    required this.position,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  final LatLng? position;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;

  String _fmt(double v, {required bool isLat}) {
    final dir = isLat ? (v >= 0 ? 'N' : 'S') : (v >= 0 ? 'E' : 'O');
    return '${v.abs().toStringAsFixed(5)}° $dir';
  }

  @override
  Widget build(BuildContext context) {
    final hasPosition = position != null;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 2,
        ),
        decoration: BoxDecoration(
          color: hasPosition ? AppColors.primaryLightBg : AppColors.gray50,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: hasPosition
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.gray200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hasPosition ? AppColors.primary : AppColors.gray200,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                hasPosition ? Icons.location_on_rounded : Icons.map_outlined,
                color: hasPosition ? Colors.white : AppColors.gray500,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: hasPosition
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Position sélectionnée',
                          style: TextStyle(
                            fontSize: AppSizes.fontXs,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_fmt(position!.latitude, isLat: true)}  •  ${_fmt(position!.longitude, isLat: false)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: AppSizes.fontXs,
                            color: AppColors.gray700,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Choisir la position sur la carte',
                      style: TextStyle(
                        fontSize: AppSizes.fontSm,
                        color: AppColors.gray500,
                      ),
                    ),
            ),
            if (hasPosition)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.gray400,
                onPressed: enabled ? onClear : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gray400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
