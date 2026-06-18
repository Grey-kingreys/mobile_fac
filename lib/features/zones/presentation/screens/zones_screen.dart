import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/zones/domain/entities/zone_entity.dart';
import 'package:djoulagest_mobile/features/zones/presentation/providers/zones_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_button.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';
import 'package:djoulagest_mobile/shared/widgets/app_text_field.dart';
import 'package:djoulagest_mobile/shared/widgets/confirm_dialog.dart';
import 'package:djoulagest_mobile/shared/widgets/map_picker_sheet.dart';

class ZonesScreen extends ConsumerStatefulWidget {
  const ZonesScreen({super.key});

  @override
  ConsumerState<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends ConsumerState<ZonesScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  static const _canWrite = ['admin'];

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
      ref.read(zonesProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(zonesProvider.notifier).search(query);
    });
  }

  Future<void> _openForm({ZoneEntity? zone}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ZoneFormSheet(zone: zone),
    );
  }

  Future<void> _delete(ZoneEntity zone) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Supprimer la zone',
      message: 'Supprimer « ${zone.name} » ? Cette action est irréversible.',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirmed != true || !mounted) return;
    final error = await ref.read(zonesProvider.notifier).delete(zone.id);
    if (!mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.success(context, 'Zone supprimée');
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(zonesProvider);
    final role = ref.watch(effectiveRoleProvider);
    final canWrite = _canWrite.contains(role);

    return AppScaffold(
      title: 'Zones géographiques',
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingPage, AppSizes.sm, AppSizes.paddingPage, AppSizes.sm,
            ),
            child: AppTextField(
              label: 'Rechercher',
              controller: _searchCtrl,
              hint: 'Rechercher une zone…',
              prefixIcon: Icons.search_rounded,
              onChanged: _onSearchChanged,
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: AppSizes.iconSm),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(zonesProvider.notifier).search('');
                      },
                    )
                  : null,
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
                      onPressed: () => ref.read(zonesProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.zones.isEmpty) {
                  return _EmptyState(
                    hasSearch: state.search.isNotEmpty,
                    canWrite: canWrite,
                    onAdd: () => _openForm(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(zonesProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingPage, 0, AppSizes.paddingPage, AppSizes.xxl,
                    ),
                    itemCount: state.zones.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                    itemBuilder: (context, i) {
                      if (i >= state.zones.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _ZoneTile(
                        zone: state.zones[i],
                        canWrite: canWrite,
                        onEdit: () => _openForm(zone: state.zones[i]),
                        onDelete: () => _delete(state.zones[i]),
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouvelle zone'),
            )
          : null,
    );
  }
}

// ─── Tuile zone ──────────────────────────────────────────────────────────────

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({required this.zone, required this.canWrite, required this.onEdit, required this.onDelete});
  final ZoneEntity zone;
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
            color: AppColors.primaryLightBg,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Center(
            child: Text(
              zone.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: AppSizes.fontSm,
              ),
            ),
          ),
        ),
        title: Text(
          zone.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
            fontSize: AppSizes.fontSm,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (zone.code != null && zone.code!.isNotEmpty)
              Text(
                zone.code!,
                style: const TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontXs),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.warehouse_outlined, size: 12, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(
                  '${zone.nombreDepots} dépôt${zone.nombreDepots > 1 ? 's' : ''}',
                  style: const TextStyle(color: AppColors.gray400, fontSize: AppSizes.fontXs),
                ),
                if (zone.latitude != null) ...[
                  const SizedBox(width: AppSizes.sm),
                  const Icon(Icons.location_on_outlined, size: 12, color: AppColors.gray400),
                  const SizedBox(width: 2),
                  Text(
                    '${zone.latitude!.toStringAsFixed(4)}, ${zone.longitude!.toStringAsFixed(4)}',
                    style: const TextStyle(color: AppColors.gray400, fontSize: AppSizes.fontXs),
                  ),
                ],
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
                color: zone.isActive
                    ? AppColors.secondary.withValues(alpha: 0.1)
                    : AppColors.gray200,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                zone.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: zone.isActive ? AppColors.secondary : AppColors.gray500,
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
              decoration: BoxDecoration(
                color: AppColors.primaryLightBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_outlined, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              hasSearch ? 'Aucune zone trouvée' : 'Aucune zone créée',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
                fontSize: AppSizes.fontMd,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              hasSearch
                  ? 'Essayez un autre terme de recherche.'
                  : 'Créez votre première zone géographique.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
            ),
            if (!hasSearch && canWrite) ...[
              const SizedBox(height: AppSizes.lg),
              AppButton(label: 'Créer une zone', onPressed: onAdd, gradient: true),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Formulaire zone (bottom sheet) ─────────────────────────────────────────

class _ZoneFormSheet extends ConsumerStatefulWidget {
  const _ZoneFormSheet({this.zone});
  final ZoneEntity? zone;

  @override
  ConsumerState<_ZoneFormSheet> createState() => _ZoneFormSheetState();
}

class _ZoneFormSheetState extends ConsumerState<_ZoneFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  LatLng? _position;
  bool _loading = false;

  bool get _isEditing => widget.zone != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.zone?.name ?? '');
    _codeCtrl = TextEditingController(text: widget.zone?.code ?? '');
    if (widget.zone?.latitude != null && widget.zone?.longitude != null) {
      _position = LatLng(widget.zone!.latitude!, widget.zone!.longitude!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPosition() async {
    final result = await MapPickerSheet.show(context, initial: _position);
    if (result != null) setState(() => _position = result);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim();

    final String? error;
    if (_isEditing) {
      error = await ref.read(zonesProvider.notifier).edit(
            id: widget.zone!.id,
            name: name,
            code: code,
            latitude: _position?.latitude,
            longitude: _position?.longitude,
          );
    } else {
      error = await ref.read(zonesProvider.notifier).create(
            name: name,
            code: code,
            latitude: _position?.latitude,
            longitude: _position?.longitude,
          );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      Navigator.of(context).pop();
      AppSnackbar.success(
        context,
        _isEditing ? 'Zone modifiée' : 'Zone créée',
      );
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
                // Handle
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
                  _isEditing ? 'Modifier la zone' : 'Nouvelle zone',
                  style: const TextStyle(
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                AppTextField(
                  controller: _nameCtrl,
                  label: 'Nom de la zone',
                  hint: 'Ex : Kaloum, Coyah…',
                  prefixIcon: Icons.location_on_outlined,
                  enabled: !_loading,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: AppSizes.md),

                AppTextField(
                  controller: _codeCtrl,
                  label: 'Code *',
                  hint: 'Code de la zone',
                  prefixIcon: Icons.notes_rounded,
                  enabled: !_loading,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Code requis' : null,
                ),
                const SizedBox(height: AppSizes.md),

                // ── Sélecteur de position ───────────────────────────────────
                _PositionPickerTile(
                  position: _position,
                  enabled: !_loading,
                  onTap: _pickPosition,
                  onClear: () => setState(() => _position = null),
                ),
                const SizedBox(height: AppSizes.xl),

                AppButton(
                  label: _isEditing ? 'Enregistrer' : 'Créer la zone',
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

// ── Tuile sélecteur de position ──────────────────────────────────────────────

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
          color: hasPosition
              ? AppColors.primaryLightBg
              : AppColors.gray50,
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
