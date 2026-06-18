import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/finance/domain/entities/cash_session_entity.dart';
import 'package:djoulagest_mobile/features/finance/presentation/providers/finance_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_button.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';
import 'package:djoulagest_mobile/shared/widgets/app_text_field.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(effectiveRoleProvider);
    final financeAsync = ref.watch(financeProvider);

    return AppScaffold(
      title: 'Transactions',
      additionalActions: [
        if (role == 'caissier' || role == 'admin' || role == 'superviseur')
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rafraîchir',
            onPressed: () => ref.read(financeProvider.notifier).refresh(),
          ),
      ],
      body: financeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorView(
          onRetry: () => ref.read(financeProvider.notifier).refresh(),
        ),
        data: (state) => _TransactionsBody(
          session: state.activeSession,
          role: role,
        ),
      ),
    );
  }
}

// ─── Corps principal ──────────────────────────────────────────────────────────

class _TransactionsBody extends ConsumerWidget {
  const _TransactionsBody({required this.session, required this.role});

  final CashSessionEntity? session;
  final String role;

  bool get _isCaissier => role == 'caissier';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider(session?.id));

    return Column(
      children: [
        // Résumé session active
        if (session != null) _SessionSummaryCard(session: session!),

        if (session == null)
          Container(
            margin: const EdgeInsets.all(AppSizes.paddingPage),
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: AppSizes.iconMd, color: AppColors.accent),
                SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    'Aucune session caisse ouverte.',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        // Bouton ajouter transaction
        if (session != null && session!.isOpen && _isCaissier)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingPage, vertical: AppSizes.sm),
            child: AppButton(
              label: 'Ajouter une transaction',
              icon: Icons.add_rounded,
              onPressed: () => _AddTransactionSheet.show(
                context,
                ref,
                sessionId: session!.id,
              ),
              gradient: true,
            ),
          ),

        // Liste transactions
        Expanded(
          child: txAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text(
                'Impossible de charger les transactions',
                style: TextStyle(color: AppColors.gray400),
              ),
            ),
            data: (transactions) {
              if (transactions.isEmpty) {
                return const _EmptyState();
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingPage,
                  AppSizes.sm,
                  AppSizes.paddingPage,
                  AppSizes.xxl,
                ),
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.xs),
                itemBuilder: (ctx, i) => _TxTile(tx: transactions[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Carte résumé session ─────────────────────────────────────────────────────

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({required this.session});
  final CashSessionEntity session;

  @override
  Widget build(BuildContext context) {
    final isOpen = session.isOpen;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.paddingPage, AppSizes.md, AppSizes.paddingPage, 0),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.secondary.withValues(alpha: 0.06)
            : AppColors.gray100,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isOpen
              ? AppColors.secondary.withValues(alpha: 0.2)
              : AppColors.gray200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: isOpen ? AppColors.secondary : AppColors.gray400,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? 'Session ouverte' : 'Session fermée',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color:
                        isOpen ? AppColors.secondary : AppColors.gray500,
                  ),
                ),
                Text(
                  'Depuis ${AppFormatters.time(session.dateOuverture)}  ·  Solde calculé : ${AppFormatters.gnf(session.soldeCalcule)}',
                  style: const TextStyle(
                      fontSize: AppSizes.fontXs, color: AppColors.gray400),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniStat(
                  '↑ ${AppFormatters.gnf(session.totalEntrees ?? 0)}',
                  AppColors.secondary),
              const SizedBox(height: 2),
              _MiniStat(
                  '↓ ${AppFormatters.gnf(session.totalSorties ?? 0)}',
                  AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
          fontSize: AppSizes.fontXs,
          color: color,
          fontWeight: FontWeight.w600),
    );
  }
}

// ─── Tuile transaction ────────────────────────────────────────────────────────

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final TransactionEntity tx;

  @override
  Widget build(BuildContext context) {
    final isEntree = tx.isEntree;
    final color = isEntree ? AppColors.secondary : AppColors.danger;
    final sign = isEntree ? '+' : '-';

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
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
          // Icône type
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEntree ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color,
              size: AppSizes.iconSm + 2,
            ),
          ),
          const SizedBox(width: AppSizes.sm),

          // Description + référence
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty
                      ? tx.description
                      : isEntree ? 'Entrée caisse' : 'Sortie caisse',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppFormatters.timeAgo(tx.createdAt),
                  style: const TextStyle(
                      fontSize: AppSizes.fontXs, color: AppColors.gray400),
                ),
              ],
            ),
          ),

          // Montant
          Text(
            '$sign${AppFormatters.gnf(tx.montant)}',
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

// ─── Sheet ajout transaction ──────────────────────────────────────────────────

class _AddTransactionSheet extends ConsumerStatefulWidget {
  const _AddTransactionSheet({required this.sessionId});
  final int sessionId;

  static void show(BuildContext context, WidgetRef ref,
      {required int sessionId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTransactionSheet(sessionId: sessionId),
    );
  }

  @override
  ConsumerState<_AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'entree';
  bool _loading = false;

  @override
  void dispose() {
    _montantCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final text =
        _montantCtrl.text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    final montant = num.tryParse(text);
    if (montant == null || montant <= 0) {
      AppSnackbar.error(context, 'Montant invalide');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await ref.read(financeRepositoryProvider).addTransaction(
            sessionId: widget.sessionId,
            type: _type,
            montant: montant,
            description: _descCtrl.text.trim(),
          );
      // Rafraîchir les transactions
      ref.invalidate(transactionsProvider(widget.sessionId));
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackbar.success(context, 'Transaction enregistrée.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Nouvelle transaction',
              style: TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900),
            ),
            const SizedBox(height: AppSizes.md),

            // Type
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: 'Entrée',
                    icon: Icons.arrow_downward_rounded,
                    color: AppColors.secondary,
                    selected: _type == 'entree',
                    onTap: () => setState(() => _type = 'entree'),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _TypeChip(
                    label: 'Sortie',
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.danger,
                    selected: _type == 'sortie',
                    onTap: () => setState(() => _type = 'sortie'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            AppTextField(
              controller: _montantCtrl,
              label: 'Montant (GNF)',
              hint: '0',
              prefixIcon: Icons.account_balance_wallet_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
              ],
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: AppSizes.md),
            AppTextField(
              controller: _descCtrl,
              label: 'Description',
              hint: 'Ex : vente marchandises, dépense carburant…',
              prefixIcon: Icons.description_outlined,
              enabled: !_loading,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: AppSizes.lg),

            AppButton(
              label: 'Enregistrer',
              onPressed: _loading ? null : _submit,
              isLoading: _loading,
              gradient: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            vertical: AppSizes.sm + 2, horizontal: AppSizes.sm),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.gray50,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: selected ? color : AppColors.gray200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: AppSizes.iconSm,
                color: selected ? color : AppColors.gray400),
            const SizedBox(width: AppSizes.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── États vides / erreur ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_rounded,
                size: AppSizes.iconXxl, color: AppColors.gray200),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Aucune transaction',
              style: TextStyle(
                  color: AppColors.gray500, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSizes.xs),
            const Text(
              'Les transactions de la session active apparaîtront ici.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.gray400, fontSize: AppSizes.fontSm),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: AppSizes.iconXxl, color: AppColors.gray300),
          const SizedBox(height: AppSizes.md),
          const Text('Impossible de charger les données',
              style: TextStyle(color: AppColors.gray500)),
          const SizedBox(height: AppSizes.sm),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
