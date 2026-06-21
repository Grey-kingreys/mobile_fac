import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/depots/presentation/providers/depots_provider.dart';
import 'package:djoulagest_mobile/features/inventory/domain/entities/stock_entity.dart';
import 'package:djoulagest_mobile/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:djoulagest_mobile/features/products/presentation/providers/products_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

const _createRoles = {'admin', 'gestionnaire_stock'};
const _approveRoles = {'admin', 'superviseur'};

class AjustementsScreen extends ConsumerStatefulWidget {
  const AjustementsScreen({super.key});

  @override
  ConsumerState<AjustementsScreen> createState() => _AjustementsScreenState();
}

class _AjustementsScreenState extends ConsumerState<AjustementsScreen> {
  static const _filters = [
    ('Tous', ''),
    ('En attente', 'en_attente'),
    ('Approuvés', 'approuve'),
    ('Refusés', 'refuse'),
  ];

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          ref.read(ajustementsProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ajustementsAsync = ref.watch(ajustementsProvider);
    final currentFilter = ajustementsAsync.valueOrNull?.filter ?? '';
    final role = ref.watch(effectiveRoleProvider);
    final canCreate = _createRoles.contains(role);
    final canApprove = _approveRoles.contains(role);

    return AppScaffold(
      title: 'Ajustements de stock',
      showBottomNav: true,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateSheet(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Demander un ajustement',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Column(
        children: [
          // ─── Filtres ─────────────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingPage, vertical: 4),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.xs),
              itemBuilder: (ctx, i) {
                final (label, value) = _filters[i];
                final selected = currentFilter == value;
                return GestureDetector(
                  onTap: () =>
                      ref.read(ajustementsProvider.notifier).setFilter(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.xs),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.gray100,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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
                        color: selected ? AppColors.primary : AppColors.gray500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ─── Liste ───────────────────────────────────────────────────────
          Expanded(
            child: ajustementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    const Text('Impossible de charger les ajustements',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(ajustementsProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.ajustements.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tune_outlined,
                              size: AppSizes.iconXxl, color: AppColors.gray200),
                          SizedBox(height: AppSizes.md),
                          Text('Aucun ajustement',
                              style: TextStyle(color: AppColors.gray500)),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(ajustementsProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingPage, 0, AppSizes.paddingPage,
                        AppSizes.xxl),
                    itemCount: state.ajustements.length +
                        (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (ctx, i) {
                      if (i == state.ajustements.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _AjustementTile(
                        ajustement: state.ajustements[i],
                        canApprove: canApprove,
                        onApprouver: () => _approuver(state.ajustements[i].id),
                        onRefuser: () => _refuser(state.ajustements[i].id),
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

  Future<void> _approuver(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver l\'ajustement'),
        content: const Text('Confirmer l\'approbation de cet ajustement ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final error = await ref.read(ajustementsProvider.notifier).approuver(id);
    if (!mounted) return;
    _showSnack(error, 'Ajustement approuvé');
  }

  Future<void> _refuser(int id) async {
    final motifCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser l\'ajustement'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Motif du refus (obligatoire) :'),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: motifCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Saisir un motif…',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Motif obligatoire' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final error = await ref.read(ajustementsProvider.notifier).refuser(
          id,
          motif: motifCtrl.text.trim(),
        );
    if (!mounted) return;
    _showSnack(error, 'Ajustement refusé');
  }

  void _showSnack(String? error, String successMsg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? successMsg),
      backgroundColor: error != null ? AppColors.danger : AppColors.secondary,
    ));
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateAjustementSheet(parentRef: ref),
    );
  }
}

// ─── Tuile ajustement ─────────────────────────────────────────────────────────

class _AjustementTile extends StatelessWidget {
  const _AjustementTile({
    required this.ajustement,
    required this.canApprove,
    required this.onApprouver,
    required this.onRefuser,
  });

  final AjustementEntity ajustement;
  final bool canApprove;
  final VoidCallback onApprouver;
  final VoidCallback onRefuser;

  Color get _color => switch (ajustement.statut) {
        'approuve' => AppColors.secondary,
        'refuse' => AppColors.danger,
        _ => AppColors.accent,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ajustement.produitNom,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dépôt : ${ajustement.depotCode}  •  Qté : ${ajustement.quantite}',
                      style: const TextStyle(
                          fontSize: AppSizes.fontXs, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  ajustement.statutLabel,
                  style: TextStyle(
                    fontSize: AppSizes.fontXs,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (ajustement.motif != null && ajustement.motif!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              'Motif : ${ajustement.motif}',
              style: const TextStyle(
                  fontSize: AppSizes.fontXs, color: AppColors.gray500),
            ),
          ],
          const SizedBox(height: 4),
          // Métadonnées sur leur propre ligne — jamais en compétition avec les boutons.
          Text(
            'Par ${ajustement.demandeParNom}  •  ${AppFormatters.dateShort(ajustement.createdAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: AppSizes.fontXs, color: AppColors.gray400),
          ),
          // Actions sur une ligne dédiée, en pleine largeur et tactiles (≥ 44px).
          if (canApprove && ajustement.isEnAttente) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Approuver',
                    icon: Icons.check_rounded,
                    color: AppColors.secondary,
                    filled: true,
                    onPressed: onApprouver,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _ActionButton(
                    label: 'Refuser',
                    icon: Icons.close_rounded,
                    color: AppColors.danger,
                    onPressed: onRefuser,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Material(
      color: filled ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: filled
                ? null
                : Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconSm, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Formulaire demande d'ajustement ─────────────────────────────────────────

class _CreateAjustementSheet extends ConsumerStatefulWidget {
  const _CreateAjustementSheet({required this.parentRef});
  final WidgetRef parentRef;

  @override
  ConsumerState<_CreateAjustementSheet> createState() =>
      _CreateAjustementSheetState();
}

class _CreateAjustementSheetState
    extends ConsumerState<_CreateAjustementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();

  int? _depotId;
  int? _produitId;
  bool _loading = false;

  @override
  void dispose() {
    _quantiteCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final depotsAsync = ref.watch(depotsProvider);
    final produitsAsync = ref.watch(productsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSizes.paddingPage, AppSizes.md, AppSizes.paddingPage, bottom + AppSizes.lg),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Demander un ajustement',
                style: TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Dépôt
              _AjustDropdown<int>(
                label: 'Dépôt *',
                selectedValue: _depotId,
                items: depotsAsync.when(
                  data: (s) => s.depots
                      .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.nom, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  loading: () => [],
                  error: (_, __) => [],
                ),
                isLoading: depotsAsync.isLoading,
                onChanged: (v) => setState(() => _depotId = v),
                validator: (v) => v == null ? 'Sélectionner un dépôt' : null,
              ),
              const SizedBox(height: AppSizes.md),

              // Produit
              _AjustDropdown<int>(
                label: 'Produit *',
                selectedValue: _produitId,
                items: produitsAsync.when(
                  data: (s) => s.products
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.reference} — ${p.nom}',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  loading: () => [],
                  error: (_, __) => [],
                ),
                isLoading: produitsAsync.isLoading,
                onChanged: (v) => setState(() => _produitId = v),
                validator: (v) => v == null ? 'Sélectionner un produit' : null,
              ),
              const SizedBox(height: AppSizes.md),

              // Quantité
              TextFormField(
                controller: _quantiteCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _deco('Quantité *'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Obligatoire';
                  final n = num.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Quantité invalide';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),

              // Motif
              TextFormField(
                controller: _motifCtrl,
                maxLines: 2,
                decoration: _deco('Motif *'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Le motif est obligatoire (règle anti-fraude §2)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Soumettre la demande',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: AppSizes.fontMd),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await widget.parentRef
        .read(ajustementsProvider.notifier)
        .createAjustement(
          depot: _depotId!,
          produit: _produitId!,
          quantite: num.parse(_quantiteCtrl.text.trim()),
          motif: _motifCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande soumise avec succès'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }
}

// ─── Dropdown réutilisable interne ────────────────────────────────────────────

class _AjustDropdown<T> extends StatelessWidget {
  const _AjustDropdown({
    required this.label,
    required this.selectedValue,
    required this.items,
    required this.isLoading,
    required this.onChanged,
    required this.validator,
  });

  final String label;
  final T? selectedValue;
  final List<DropdownMenuItem<T>> items;
  final bool isLoading;
  final void Function(T?) onChanged;
  final String? Function(T?) validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      isExpanded: true,
      hint: isLoading
          ? const Row(children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Chargement…'),
            ])
          : null,
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
