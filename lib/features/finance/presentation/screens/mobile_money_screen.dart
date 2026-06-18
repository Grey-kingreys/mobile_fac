import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/finance/domain/entities/compte_mobile_money_entity.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _comptesProvider =
    FutureProvider.autoDispose<List<CompteMobileMoneyEntity>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get<Map<String, dynamic>>(
    ApiEndpoints.comptesMobileMoney,
    queryParameters: {'page_size': '50'},
  );
  final data = resp.data ?? {};
  final results = data['results'];
  if (results is List) {
    return results
        .cast<Map<String, dynamic>>()
        .map(CompteMobileMoneyEntity.fromJson)
        .toList();
  }
  return [];
});

final _transactionsProvider = FutureProvider.autoDispose
    .family<List<TransactionMobileMoneyEntity>, int>((ref, compteId) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get<Map<String, dynamic>>(
    ApiEndpoints.compteMobileMoneyTransactions(compteId),
    queryParameters: {'ordering': '-created_at', 'page_size': '25'},
  );
  final data = resp.data ?? {};
  final results = data['results'];
  if (results is List) {
    return results
        .cast<Map<String, dynamic>>()
        .map(TransactionMobileMoneyEntity.fromJson)
        .toList();
  }
  return [];
});

// ─── Écran principal ──────────────────────────────────────────────────────────

class MobileMoneyScreen extends ConsumerWidget {
  const MobileMoneyScreen({super.key});

  static const _canTransact = ['caissier', 'admin', 'superviseur'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comptesAsync = ref.watch(_comptesProvider);
    final role = ref.watch(effectiveRoleProvider);
    final canTransact = _canTransact.contains(role);

    return AppScaffold(
      title: 'Mobile Money',
      showBottomNav: true,
      body: comptesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: AppSizes.iconXxl, color: AppColors.gray300),
              const SizedBox(height: AppSizes.md),
              const Text('Impossible de charger les comptes',
                  style: TextStyle(color: AppColors.gray500)),
              const SizedBox(height: AppSizes.sm),
              TextButton(
                onPressed: () => ref.invalidate(_comptesProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (comptes) {
          if (comptes.isEmpty) {
            return const Center(
              child: Text('Aucun compte Mobile Money',
                  style: TextStyle(color: AppColors.gray500)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_comptesProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.paddingPage),
              children: comptes
                  .map((c) => _CompteTile(
                        compte: c,
                        canTransact: canTransact,
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

// ─── Tuile compte ─────────────────────────────────────────────────────────────

class _CompteTile extends StatelessWidget {
  const _CompteTile({required this.compte, required this.canTransact});
  final CompteMobileMoneyEntity compte;
  final bool canTransact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
        ),
        builder: (_) => _CompteDetailSheet(
            compte: compte, canTransact: canTransact),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: compte.couleurOperateur.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  compte.operateur == 'orange_money' ? '🍊' : 'M',
                  style: TextStyle(
                    fontSize: compte.operateur == 'orange_money' ? 22 : 18,
                    fontWeight: FontWeight.w900,
                    color: compte.couleurOperateur,
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
                    compte.operateurLabel,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                  Text(
                    compte.numero,
                    style: const TextStyle(
                        fontSize: AppSizes.fontXs, color: AppColors.gray400),
                  ),
                  if (compte.depotNom != null)
                    Text(
                      compte.depotNom!,
                      style: const TextStyle(
                          fontSize: AppSizes.fontXs, color: AppColors.gray400),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.gnf(compte.solde),
                  style: TextStyle(
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.w700,
                    color: compte.solde >= 0
                        ? AppColors.secondary
                        : AppColors.danger,
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

// ─── Sheet détail + transactions ──────────────────────────────────────────────

class _CompteDetailSheet extends ConsumerWidget {
  const _CompteDetailSheet(
      {required this.compte, required this.canTransact});
  final CompteMobileMoneyEntity compte;
  final bool canTransact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(_transactionsProvider(compte.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // En-tête compte
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, 0, AppSizes.paddingPage, AppSizes.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compte.operateurLabel,
                        style: const TextStyle(
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(compte.numero,
                          style: const TextStyle(
                              fontSize: AppSizes.fontSm,
                              color: AppColors.gray400)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.gnf(compte.solde),
                      style: const TextStyle(
                        fontSize: AppSizes.fontXl,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text('Solde actuel',
                        style: TextStyle(
                            fontSize: AppSizes.fontXs,
                            color: AppColors.gray400)),
                  ],
                ),
              ],
            ),
          ),
          if (canTransact)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingPage, 0, AppSizes.paddingPage, AppSizes.md),
              child: ElevatedButton.icon(
                onPressed: () => _showTransactionSheet(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nouvelle transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                ),
              ),
            ),
          const Divider(height: 1),
          // Transactions
          Expanded(
            child: txAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                  child: Text('Impossible de charger les transactions')),
              data: (txs) {
                if (txs.isEmpty) {
                  return const Center(
                    child: Text('Aucune transaction',
                        style: TextStyle(color: AppColors.gray400)),
                  );
                }
                return ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(AppSizes.paddingPage,
                      AppSizes.sm, AppSizes.paddingPage, AppSizes.xxl),
                  itemCount: txs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.xs),
                  itemBuilder: (_, i) => _TxTile(tx: txs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionSheet(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _AddTransactionSheet(
        compteId: compte.id,
        onSaved: () => ref.invalidate(_transactionsProvider(compte.id)),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final TransactionMobileMoneyEntity tx;

  @override
  Widget build(BuildContext context) {
    final color = tx.isEntree ? AppColors.secondary : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              tx.isEntree ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.typeLabel,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                if (tx.description != null && tx.description!.isNotEmpty)
                  Text(tx.description!,
                      style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray400)),
                if (tx.referenceOperateur != null)
                  Text('Réf: ${tx.referenceOperateur}',
                      style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray400)),
              ],
            ),
          ),
          Text(
            '${tx.isEntree ? '+' : '-'}${AppFormatters.gnf(tx.montant)}',
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulaire transaction ───────────────────────────────────────────────────

class _AddTransactionSheet extends ConsumerStatefulWidget {
  const _AddTransactionSheet(
      {required this.compteId, required this.onSaved});
  final int compteId;
  final VoidCallback onSaved;

  @override
  ConsumerState<_AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState
    extends ConsumerState<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'entree';
  bool _isSaving = false;

  @override
  void dispose() {
    _montantCtrl.dispose();
    _refCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.compteMobileMoneyTransaction(widget.compteId),
        data: {
          'type_transaction': _type,
          'montant': double.parse(_montantCtrl.text.replaceAll(',', '.')),
          'reference_operateur': _refCtrl.text.trim(),
          if (_descCtrl.text.isNotEmpty)
            'description': _descCtrl.text.trim(),
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction enregistrée'),
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
                    'Nouvelle transaction',
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
              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'entree'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.sm),
                        decoration: BoxDecoration(
                          color: _type == 'entree'
                              ? AppColors.secondary.withValues(alpha: 0.1)
                              : AppColors.gray100,
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(AppSizes.radiusMd)),
                          border: Border.all(
                              color: _type == 'entree'
                                  ? AppColors.secondary
                                  : AppColors.gray200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward_rounded,
                                size: 14,
                                color: _type == 'entree'
                                    ? AppColors.secondary
                                    : AppColors.gray400),
                            const SizedBox(width: 4),
                            Text('Entrée',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _type == 'entree'
                                        ? AppColors.secondary
                                        : AppColors.gray400)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'sortie'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.sm),
                        decoration: BoxDecoration(
                          color: _type == 'sortie'
                              ? AppColors.danger.withValues(alpha: 0.1)
                              : AppColors.gray100,
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(AppSizes.radiusMd)),
                          border: Border.all(
                              color: _type == 'sortie'
                                  ? AppColors.danger
                                  : AppColors.gray200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward_rounded,
                                size: 14,
                                color: _type == 'sortie'
                                    ? AppColors.danger
                                    : AppColors.gray400),
                            const SizedBox(width: 4),
                            Text('Sortie',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _type == 'sortie'
                                        ? AppColors.danger
                                        : AppColors.gray400)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _montantCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant *',
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
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Référence opérateur *',
                  border: OutlineInputBorder(),
                  helperText: 'ID de transaction opérateur (ex: OM-123456)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Obligatoire — règle anti-fraude Mobile Money';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
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
