import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/finance/domain/entities/cash_session_entity.dart';
import 'package:djoulagest_mobile/features/finance/presentation/providers/caisses_provider.dart';
import 'package:djoulagest_mobile/features/finance/presentation/providers/finance_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_button.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';
import 'package:djoulagest_mobile/shared/widgets/app_text_field.dart';

class CashSessionScreen extends ConsumerWidget {
  const CashSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(effectiveRoleProvider);
    final financeAsync = ref.watch(financeProvider);

    return AppScaffold(
      title: 'Finance',
      showBottomNav: true,
      body: RefreshIndicator(
        onRefresh: () => ref.read(financeProvider.notifier).refresh(),
        child: financeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: AppSizes.iconXxl, color: AppColors.gray300),
                const SizedBox(height: AppSizes.md),
                const Text('Impossible de charger les données',
                    style: TextStyle(color: AppColors.gray500)),
                const SizedBox(height: AppSizes.sm),
                TextButton(
                  onPressed: () => ref.read(financeProvider.notifier).refresh(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
          data: (state) => _FinanceBody(state: state, role: role),
        ),
      ),
    );
  }
}

// ─── Corps principal ──────────────────────────────────────────────────────────

class _FinanceBody extends ConsumerStatefulWidget {
  const _FinanceBody({required this.state, required this.role});

  final FinanceState state;
  final String role;

  @override
  ConsumerState<_FinanceBody> createState() => _FinanceBodyState();
}

class _FinanceBodyState extends ConsumerState<_FinanceBody> {
  late final ScrollController _scrollCtrl;

  bool get _isCaissier => widget.role == 'caissier';

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()
      ..addListener(() {
        if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200) {
          ref.read(financeProvider.notifier).loadMore();
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
    final state = widget.state;

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingPage,
        AppSizes.md,
        AppSizes.paddingPage,
        AppSizes.xxl,
      ),
      children: [
        // ─── Session active ───────────────────────────────────────────
        _ActiveSessionCard(
          session: state.activeSession,
          isCaissier: _isCaissier,
        ),
        const SizedBox(height: AppSizes.md),

        // ─── Historique sessions ──────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Historique sessions',
              style: TextStyle(
                fontSize: AppSizes.fontMd,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
            Text(
              '${state.total} au total',
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),

        if (state.sessions.isEmpty)
          const _EmptySessionState()
        else ...[
          ...state.sessions.map((s) => _SessionTile(session: s)),
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ],
    );
  }
}

// ─── Carte session active ─────────────────────────────────────────────────────

class _ActiveSessionCard extends ConsumerWidget {
  const _ActiveSessionCard({
    required this.session,
    required this.isCaissier,
  });

  final CashSessionEntity? session;
  final bool isCaissier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = session != null && session!.isOpen;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOpen
              ? [AppColors.secondaryDark, AppColors.secondary]
              : [AppColors.gray700, AppColors.gray600],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? AppColors.secondary : AppColors.gray600)
                .withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: Colors.white,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOpen ? 'Session ouverte' : 'Aucune session active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.fontMd,
                    ),
                  ),
                  if (session != null)
                    Text(
                      isOpen
                          ? 'Depuis ${AppFormatters.time(session!.dateOuverture)}'
                          : 'Fermée le ${AppFormatters.dateShort(session!.dateFermeture ?? session!.dateOuverture)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: AppSizes.fontXs,
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (session != null && isOpen) ...[
            const SizedBox(height: AppSizes.md),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: AppSizes.md),

            // KPIs session
            Row(
              children: [
                _SessionKpi(
                  label: 'Solde ouverture',
                  value: AppFormatters.gnf(session!.soldeOuverture),
                ),
                const SizedBox(width: AppSizes.md),
                _SessionKpi(
                  label: 'Entrées',
                  value: AppFormatters.gnf(session!.totalEntrees ?? 0),
                ),
                const SizedBox(width: AppSizes.md),
                _SessionKpi(
                  label: 'Sorties',
                  value: AppFormatters.gnf(session!.totalSorties ?? 0),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            _SessionKpi(
              label: 'Solde calculé',
              value: AppFormatters.gnf(session!.soldeCalcule),
              large: true,
              expand: false,
            ),
          ],

          const SizedBox(height: AppSizes.md),

          // CTA — caissier : fermer/ouvrir sa propre session (caisse auto-résolue).
          // Admin / superviseur : ouvrir une session en choisissant la caisse
          // (parité web — le bouton reste visible même sans session active).
          if (isCaissier)
            if (isOpen)
              AppButton(
                label: 'Fermer la session',
                icon: Icons.lock_rounded,
                onPressed: () => _showCloseSheet(context, ref, session!),
                variant: AppButtonVariant.outline,
              )
            else
              AppButton(
                label: 'Ouvrir une session',
                icon: Icons.lock_open_rounded,
                onPressed: () => _showOpenDialog(context, ref),
                gradient: true,
              )
          else
            AppButton(
              label: 'Ouvrir une session',
              icon: Icons.lock_open_rounded,
              onPressed: () => _showOpenDialog(context, ref),
              gradient: true,
            ),
        ],
      ),
    );
  }

  void _showOpenDialog(BuildContext context, WidgetRef ref) {
    _OpenSessionDialog.show(context, ref, isCaissier: isCaissier);
  }

  void _showCloseSheet(
      BuildContext context, WidgetRef ref, CashSessionEntity session) {
    _CloseSessionSheet.show(context, ref, session);
  }
}

class _SessionKpi extends StatelessWidget {
  const _SessionKpi({
    required this.label,
    required this.value,
    this.large = false,
    this.expand = true,
  });

  final String label;
  final String value;
  final bool large;

  /// `true` (défaut) → `Expanded` pour répartir dans une `Row`.
  /// `false` → KPI autonome (ne JAMAIS mettre un `Expanded` directement dans la
  /// `Column` de la carte : la carte est dans un `ListView` (hauteur non bornée)
  /// → « RenderBox was not laid out » → frame figé / ANR.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: AppSizes.fontXs,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: large ? AppSizes.fontMd : AppSizes.fontSm,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return expand
        ? Expanded(child: content)
        : SizedBox(width: double.infinity, child: content);
  }
}

// ─── Tuile session ────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final CashSessionEntity session;

  @override
  Widget build(BuildContext context) {
    final isOpen = session.isOpen;
    final statusColor = isOpen ? AppColors.secondary : AppColors.gray400;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Caissier initiales
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                child: Text(
                  session.caissierNom.isNotEmpty
                      ? session.caissierNom
                      .split(' ')
                      .where((w) => w.isNotEmpty)
                      .map((w) => w[0])
                      .take(2)
                      .join()
                      .toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: AppSizes.fontXs,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.caissierNom.isNotEmpty
                          ? session.caissierNom
                          : 'Caissier #${session.caissierId}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray800,
                      ),
                    ),
                    Text(
                      AppFormatters.dateTime(session.dateOuverture),
                      style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge statut
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  isOpen ? 'Ouverte' : 'Fermée',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: AppSizes.fontXs,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Soldes
          if (!isOpen) ...[
            const SizedBox(height: AppSizes.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                _MiniKpi('Ouverture', AppFormatters.gnf(session.soldeOuverture)),
                _MiniKpi(
                    'Fermeture',
                    AppFormatters.gnf(
                        session.soldeFermeture ?? session.soldeCalcule)),
                if (session.ecart != null && session.ecart != 0)
                  _MiniKpi(
                    'Écart',
                    AppFormatters.gnf(session.ecart!),
                    color: session.ecart! < 0
                        ? AppColors.danger
                        : AppColors.secondary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi(this.label, this.value, {this.color = AppColors.gray700});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: AppSizes.fontXs, color: AppColors.gray400)),
          Text(value,
              maxLines: 1,
              style: TextStyle(
                  fontSize: AppSizes.fontXs,
                  fontWeight: FontWeight.w600,
                  color: color),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Dialog ouverture session ─────────────────────────────────────────────────

class _OpenSessionDialog extends ConsumerStatefulWidget {
  const _OpenSessionDialog({required this.isCaissier});

  /// Caissier : caisse auto-résolue depuis son dépôt (pas de sélecteur).
  /// Non-caissier (admin/superviseur) : sélecteur de caisse obligatoire.
  final bool isCaissier;

  static void show(BuildContext context, WidgetRef ref,
      {required bool isCaissier}) {
    showDialog(
      context: context,
      builder: (_) => _OpenSessionDialog(isCaissier: isCaissier),
    );
  }

  @override
  ConsumerState<_OpenSessionDialog> createState() => _OpenSessionDialogState();
}

class _OpenSessionDialogState extends ConsumerState<_OpenSessionDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  int? _selectedCaisseId;

  bool get _needsCaisse => !widget.isCaissier;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    final amount = num.tryParse(text);
    if (amount == null || amount < 0) {
      AppSnackbar.error(context, 'Montant invalide');
      return;
    }
    if (_needsCaisse && _selectedCaisseId == null) {
      AppSnackbar.error(context, 'Sélectionnez une caisse.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final err = await ref.read(financeProvider.notifier).openSession(
          soldeOuverture: amount,
          caisseId: _needsCaisse ? _selectedCaisseId : null,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      Navigator.of(context).pop();
      AppSnackbar.success(context, 'Session ouverte avec succès.');
    } else {
      AppSnackbar.error(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ouvrir une session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _needsCaisse
                ? 'Vérifiez la caisse à ouvrir et indiquez le solde compté physiquement.'
                : 'Entrez le solde de caisse que vous avez compté physiquement avant d\'ouvrir la session.',
            style: const TextStyle(
                fontSize: AppSizes.fontSm, color: AppColors.gray500),
          ),
          const SizedBox(height: AppSizes.md),

          // Sélecteur de caisse (admin/superviseur uniquement)
          if (_needsCaisse) ...[
            _CaissePicker(
              enabled: !_loading,
              selectedId: _selectedCaisseId,
              onChanged: (id) => setState(() => _selectedCaisseId = id),
            ),
            const SizedBox(height: AppSizes.md),
          ],

          AppTextField(
            controller: _ctrl,
            label: 'Solde d\'ouverture (GNF)',
            hint: '0',
            prefixIcon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
            enabled: !_loading,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Requis' : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        AppButton(
          label: 'Ouvrir',
          onPressed: _loading ? null : _submit,
          isLoading: _loading,
          gradient: true,
        ),
      ],
    );
  }
}

// ─── Sélecteur de caisse physique (ouverture par admin/superviseur) ────────────

class _CaissePicker extends ConsumerWidget {
  const _CaissePicker({
    required this.enabled,
    required this.selectedId,
    required this.onChanged,
  });

  final bool enabled;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caissesAsync = ref.watch(caissesProvider);

    return caissesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSizes.sm),
            Text('Chargement des caisses…',
                style: TextStyle(
                    fontSize: AppSizes.fontSm, color: AppColors.gray500)),
          ],
        ),
      ),
      error: (_, __) => const Text(
        'Impossible de charger les caisses.',
        style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.danger),
      ),
      data: (state) {
        // Une session ne peut s'ouvrir que sur une caisse physique OUVERTE
        // (contrainte backend : au plus une caisse ouverte par dépôt). On ne
        // propose donc que les caisses actives ET ouvertes.
        final caisses = state.physiques
            .where((c) => c.isActive && c.isOuverte)
            .toList(growable: false);

        if (caisses.isEmpty) {
          return const Text(
            'Aucune caisse ouverte. Ouvrez-en une dans « Gestion des caisses » '
            'avant de démarrer une session.',
            style:
                TextStyle(fontSize: AppSizes.fontSm, color: AppColors.danger),
          );
        }

        // Cas mono-dépôt : une seule caisse ouverte → on la prend d'office.
        if (caisses.length == 1) {
          final only = caisses.first;
          if (selectedId != only.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onChanged(only.id);
            });
          }
          return _SelectedCaisseTile(nom: only.nom, depotNom: only.depotNom);
        }

        // Plusieurs caisses ouvertes (multi-dépôts) → choix explicite.
        return DropdownButtonFormField<int>(
          initialValue: selectedId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Caisse',
            prefixIcon: Icon(Icons.point_of_sale_outlined),
            border: OutlineInputBorder(),
          ),
          hint: const Text('Sélectionnez une caisse'),
          items: caisses
              .map((c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(
                      '${c.nom} · ${c.depotNom}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: enabled ? onChanged : null,
        );
      },
    );
  }
}

/// Affichage en lecture seule de la caisse retenue d'office (cas unique caisse).
class _SelectedCaisseTile extends StatelessWidget {
  const _SelectedCaisseTile({required this.nom, required this.depotNom});

  final String nom;
  final String depotNom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.point_of_sale_outlined,
              size: AppSizes.iconSm, color: AppColors.primary),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray800,
                  ),
                ),
                Text(
                  depotNom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: AppSizes.fontXs, color: AppColors.gray500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet fermeture session ──────────────────────────────────────────────────

class _CloseSessionSheet extends ConsumerStatefulWidget {
  const _CloseSessionSheet({required this.session});
  final CashSessionEntity session;

  static void show(
      BuildContext context, WidgetRef ref, CashSessionEntity session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CloseSessionSheet(session: session),
    );
  }

  @override
  ConsumerState<_CloseSessionSheet> createState() => _CloseSessionSheetState();
}

class _CloseSessionSheetState extends ConsumerState<_CloseSessionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _soldeCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();
  bool _loading = false;
  num? _ecart;

  CashSessionEntity get _s => widget.session;

  void _updateEcart(String val) {
    final text = val.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    final amount = num.tryParse(text);
    setState(() {
      _ecart = amount != null ? amount - _s.soldeCalcule : null;
    });
  }

  bool get _ecartNonNul => _ecart != null && _ecart!.abs() > 0;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final text =
    _soldeCtrl.text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    final soldeFermeture = num.tryParse(text)!;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final err = await ref.read(financeProvider.notifier).closeSession(
      id: _s.id,
      soldeFermeture: soldeFermeture,
      motifEcart:
      _ecartNonNul ? _motifCtrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      Navigator.of(context).pop();
      AppSnackbar.success(context, 'Session fermée avec succès.');
    } else {
      AppSnackbar.error(context, err);
    }
  }

  @override
  void dispose() {
    _soldeCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
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
            // Handle
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
              'Fermer la session',
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            const Text(
              'Comptez physiquement votre caisse et saisissez le montant réel.',
              style: TextStyle(
                  fontSize: AppSizes.fontSm, color: AppColors.gray500),
            ),
            const SizedBox(height: AppSizes.md),

            // Solde calculé (informatif)
            _InfoRow(
              label: 'Solde calculé (système)',
              value: AppFormatters.gnf(_s.soldeCalcule),
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSizes.sm),

            // Solde compté par le caissier
            AppTextField(
              controller: _soldeCtrl,
              label: 'Solde compté (ce que vous avez en caisse)',
              hint: '0',
              prefixIcon: Icons.calculate_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
              ],
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              onChanged: _updateEcart,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requis';
                final t = v.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
                if (num.tryParse(t) == null) return 'Montant invalide';
                return null;
              },
            ),

            // Écart affiché dynamiquement
            if (_ecart != null) ...[
              const SizedBox(height: AppSizes.sm),
              _InfoRow(
                label: 'Écart',
                value: AppFormatters.gnf(_ecart!),
                color: _ecartNonNul ? AppColors.danger : AppColors.secondary,
                icon: _ecartNonNul
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
              ),
            ],

            // Motif requis si écart non nul
            if (_ecartNonNul) ...[
              const SizedBox(height: AppSizes.sm),
              AppTextField(
                controller: _motifCtrl,
                label: 'Motif de l\'écart (obligatoire)',
                hint: 'Ex : erreur de rendu de monnaie, dépense non enregistrée…',
                prefixIcon: Icons.edit_note_rounded,
                enabled: !_loading,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Motif obligatoire si écart' : null,
              ),
            ],

            const SizedBox(height: AppSizes.lg),

            AppButton(
              label: 'Confirmer la fermeture',
              onPressed: _loading ? null : _submit,
              isLoading: _loading,
              variant: AppButtonVariant.danger,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconSm, color: color),
            const SizedBox(width: AppSizes.xs),
          ],
          Text(
            label,
            style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: color,
                fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: color,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─── État vide ────────────────────────────────────────────────────────────────

class _EmptySessionState extends StatelessWidget {
  const _EmptySessionState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl),
      child: Column(
        children: [
          const Icon(Icons.point_of_sale_rounded,
              size: AppSizes.iconXxl, color: AppColors.gray200),
          const SizedBox(height: AppSizes.md),
          const Text(
            'Aucune session enregistrée',
            style: TextStyle(
                color: AppColors.gray400, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSizes.xs),
          const Text(
            'Les sessions ouvertes apparaîtront ici.',
            style:
            TextStyle(color: AppColors.gray400, fontSize: AppSizes.fontSm),
          ),
        ],
      ),
    );
  }
}
