import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:djoulagest_mobile/features/suppliers/presentation/providers/suppliers_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final _searchCtrl = TextEditingController();

  static const _canCreate = ['gestionnaire_stock', 'admin', 'superviseur'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _CreateSupplierSheet(
        onCreated: () => ref.read(suppliersProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(effectiveRoleProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final canCreate = _canCreate.contains(role);

    return AppScaffold(
      title: 'Fournisseurs',
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
          // ─── Recherche ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, AppSizes.md, AppSizes.paddingPage, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(suppliersProvider.notifier).search(v),
              decoration: InputDecoration(
                hintText: 'Rechercher un fournisseur…',
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
                          ref.read(suppliersProvider.notifier).search('');
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
          const SizedBox(height: AppSizes.sm),

          // ─── Compteur ───────────────────────────────────────────────────
          if (suppliersAsync.valueOrNull != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.paddingPage),
              child: Row(
                children: [
                  Text(
                    '${suppliersAsync.value!.total} fournisseur(s)',
                    style: const TextStyle(
                        fontSize: AppSizes.fontXs, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSizes.xs),

          // ─── Liste ─────────────────────────────────────────────────────
          Expanded(
            child: suppliersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    const Text('Impossible de charger les fournisseurs',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(suppliersProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.suppliers.isEmpty) {
                  return const Center(
                    child: Text('Aucun fournisseur trouvé',
                        style: TextStyle(color: AppColors.gray500)),
                  );
                }
                return _SupplierList(state: state);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Liste ────────────────────────────────────────────────────────────────────

class _SupplierList extends ConsumerWidget {
  const _SupplierList({required this.state});
  final SuppliersState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ScrollController();
    controller.addListener(() {
      if (controller.position.pixels >=
          controller.position.maxScrollExtent - 200) {
        ref.read(suppliersProvider.notifier).loadMore();
      }
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(suppliersProvider.notifier).refresh(),
      child: ListView.separated(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingPage, 0, AppSizes.paddingPage, AppSizes.xxl),
        itemCount: state.suppliers.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.xs),
        itemBuilder: (ctx, i) {
          if (i == state.suppliers.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _SupplierTile(supplier: state.suppliers[i]);
        },
      ),
    );
  }
}

// ─── Tuile fournisseur ────────────────────────────────────────────────────────

class _SupplierTile extends StatelessWidget {
  const _SupplierTile({required this.supplier});
  final SupplierEntity supplier;

  String get _initials {
    final parts = supplier.nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (supplier.nom.length >= 2) {
      return supplier.nom.substring(0, 2).toUpperCase();
    }
    return supplier.nom.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.supplierDetailPath(supplier.id)),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: AppSizes.fontSm,
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
                    supplier.nom,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    supplier.code,
                    style: const TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (supplier.hasDette)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      AppFormatters.gnf(supplier.soldeDette),
                      style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                if (!supplier.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: const Text(
                      'Inactif',
                      style: TextStyle(
                        fontSize: AppSizes.fontXs,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                const Icon(Icons.chevron_right_rounded,
                    size: AppSizes.iconMd, color: AppColors.gray300),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulaire création ──────────────────────────────────────────────────────

class _CreateSupplierSheet extends ConsumerStatefulWidget {
  const _CreateSupplierSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateSupplierSheet> createState() =>
      _CreateSupplierSheetState();
}

class _CreateSupplierSheetState extends ConsumerState<_CreateSupplierSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(suppliersProvider.notifier).createSupplier({
        'code': _codeCtrl.text.trim(),
        'nom': _nomCtrl.text.trim(),
        if (_telCtrl.text.isNotEmpty) 'telephone': _telCtrl.text.trim(),
        if (_emailCtrl.text.isNotEmpty) 'email': _emailCtrl.text.trim(),
        if (_adresseCtrl.text.isNotEmpty) 'adresse': _adresseCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fournisseur créé avec succès'),
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                    'Ajouter un fournisseur',
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
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code *',
                  hintText: 'Ex : FOUR-001',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _adresseCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
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
