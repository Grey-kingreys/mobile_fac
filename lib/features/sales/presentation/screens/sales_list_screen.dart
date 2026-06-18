import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/sales/domain/entities/sale_entity.dart';
import 'package:djoulagest_mobile/features/sales/presentation/providers/sales_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';
import 'package:djoulagest_mobile/shared/widgets/confirm_dialog.dart';

class SalesListScreen extends ConsumerWidget {
  const SalesListScreen({super.key});

  static const _filters = [
    ('Toutes', ''),
    ('En cours', 'en_cours'),
    ('Livrées', 'livree'),
    ('Annulées', 'annulee'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesProvider);
    final currentFilter = salesAsync.valueOrNull?.filter ?? '';

    return AppScaffold(
      title: 'Commandes',
      showBottomNav: true,
      body: Column(
        children: [
          // ─── Filtres ──────────────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingPage, vertical: 4),
              itemCount: _filters.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSizes.xs),
              itemBuilder: (ctx, i) {
                final (label, value) = _filters[i];
                final selected = currentFilter == value;
                return GestureDetector(
                  onTap: () =>
                      ref.read(salesProvider.notifier).setFilter(value),
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
                        color:
                            selected ? AppColors.primary : AppColors.gray500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ─── Liste ────────────────────────────────────────────────────────
          Expanded(
            child: salesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    const Text('Impossible de charger les commandes',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(salesProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.sales.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: AppSizes.iconXxl,
                              color: AppColors.gray200),
                          SizedBox(height: AppSizes.md),
                          Text('Aucune commande',
                              style: TextStyle(color: AppColors.gray500)),
                        ],
                      ),
                    ),
                  );
                }

                final controller = ScrollController();
                controller.addListener(() {
                  if (controller.position.pixels >=
                      controller.position.maxScrollExtent - 200) {
                    ref.read(salesProvider.notifier).loadMore();
                  }
                });

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(salesProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingPage, 0, AppSizes.paddingPage,
                        AppSizes.xxl),
                    itemCount: state.sales.length +
                        (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (ctx, i) {
                      if (i == state.sales.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child: Center(
                              child: CircularProgressIndicator()),
                        );
                      }
                      final sale = state.sales[i];
                      return _SaleTile(
                        sale: sale,
                        onTap: () => _showSaleActions(context, ref, sale),
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

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale, this.onTap});
  final SaleEntity sale;
  final VoidCallback? onTap;

  Color get _statutColor {
    return switch (sale.statut) {
      'en_cours' => AppColors.primary,
      'livree' => AppColors.secondary,
      'annulee' => AppColors.gray400,
      _ => AppColors.gray500,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _statutColor;

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
          // Badge statut
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(Icons.receipt_long_rounded,
                color: color, size: AppSizes.iconMd),
          ),
          const SizedBox(width: AppSizes.sm),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sale.numero,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppFormatters.gnf(sale.montantTtc),
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sale.clientNom,
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        sale.statutLabel,
                        style: TextStyle(
                          fontSize: AppSizes.fontXs,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!sale.isSolde) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Reste : ${AppFormatters.gnf(sale.resteAPayer)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ─── Actions sur une vente ────────────────────────────────────────────────────

void _showSaleActions(BuildContext context, WidgetRef ref, SaleEntity sale) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SaleActionsSheet(sale: sale, salesRef: ref),
  );
}

class _SaleActionsSheet extends ConsumerStatefulWidget {
  const _SaleActionsSheet({required this.sale, required this.salesRef});
  final SaleEntity sale;
  final WidgetRef salesRef;

  @override
  ConsumerState<_SaleActionsSheet> createState() => _SaleActionsSheetState();
}

class _SaleActionsSheetState extends ConsumerState<_SaleActionsSheet> {
  static const _modes = [
    ('especes', 'Espèces'),
    ('carte', 'Carte'),
    ('mobile_money', 'Mobile Money'),
    ('virement', 'Virement'),
    ('cheque', 'Chèque'),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _montantCtrl;
  final TextEditingController _refCtrl = TextEditingController();
  String _mode = 'especes';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _montantCtrl = TextEditingController(
      text: widget.sale.resteAPayer.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _annuler() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Annuler la commande',
      message:
          'La commande ${widget.sale.numero} sera annulée. Cette action est irréversible.',
      confirmLabel: 'Annuler la commande',
      isDanger: true,
      icon: Icons.cancel_outlined,
    );
    if (!mounted) return;
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final err =
        await widget.salesRef.read(salesProvider.notifier).annuler(widget.sale.id);
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
    if (err != null) {
      AppSnackbar.error(context, err);
    } else {
      AppSnackbar.success(context, 'Commande annulée');
    }
  }

  Future<void> _payer() async {
    if (!_formKey.currentState!.validate()) return;
    final montant = num.tryParse(_montantCtrl.text.trim());
    if (montant == null || montant <= 0) return;

    setState(() => _isLoading = true);
    final err = await widget.salesRef.read(salesProvider.notifier).payer(
          id: widget.sale.id,
          montant: montant,
          mode: _mode,
          reference:
              _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
    if (err != null) {
      AppSnackbar.error(context, err);
    } else {
      AppSnackbar.success(context, 'Paiement enregistré');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(effectiveRoleProvider);
    final canAnnuler = !widget.sale.isAnnulee &&
        (role == 'admin' || role == 'superviseur');
    final canPayer = !widget.sale.isAnnulee &&
        !widget.sale.isSolde &&
        (role == 'caissier' || role == 'admin' || role == 'commercial');
    final showRef = _mode == 'mobile_money' || _mode == 'virement';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.paddingPage,
        AppSizes.md,
        AppSizes.paddingPage,
        AppSizes.paddingPage + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // En-tête vente
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sale.numero,
                        style: const TextStyle(
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.sale.clientNom,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSm,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  AppFormatters.gnf(widget.sale.montantTtc),
                  style: const TextStyle(
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
            if (!widget.sale.isSolde) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                'Reste : ${AppFormatters.gnf(widget.sale.resteAPayer)}',
                style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.md),
            const Divider(),
            const SizedBox(height: AppSizes.sm),

            if (!canAnnuler && !canPayer)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                child: Center(
                  child: Text(
                    'Aucune action disponible pour votre rôle.',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                ),
              ),

            // Paiement
            if (canPayer) ...[
              const Text(
                'Enregistrer un paiement',
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _montantCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant (GNF)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        final n = num.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Montant invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _mode,
                      decoration: const InputDecoration(
                        labelText: 'Mode de paiement',
                        border: OutlineInputBorder(),
                      ),
                      items: _modes
                          .map((e) => DropdownMenuItem(
                                value: e.$1,
                                child: Text(e.$2),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _mode = v);
                      },
                    ),
                    if (showRef) ...[
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _refCtrl,
                        decoration: InputDecoration(
                          labelText: _mode == 'mobile_money'
                              ? 'Référence opérateur'
                              : 'Référence virement',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ],
                    const SizedBox(height: AppSizes.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _payer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.md),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Valider le paiement'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],

            // Annulation
            if (canAnnuler)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _annuler,
                  icon: const Icon(Icons.cancel_outlined,
                      color: AppColors.danger),
                  label: const Text(
                    'Annuler la commande',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }
}
