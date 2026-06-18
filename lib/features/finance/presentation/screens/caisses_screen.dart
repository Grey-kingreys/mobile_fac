import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/depots/presentation/providers/depots_provider.dart';
import 'package:djoulagest_mobile/features/finance/domain/entities/caisse_entity.dart';
import 'package:djoulagest_mobile/features/finance/presentation/providers/caisses_provider.dart';
import 'package:djoulagest_mobile/features/zones/presentation/providers/zones_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';
import 'package:djoulagest_mobile/shared/widgets/confirm_dialog.dart';

class CaissesScreen extends ConsumerStatefulWidget {
  const CaissesScreen({super.key});

  @override
  ConsumerState<CaissesScreen> createState() => _CaissesScreenState();
}

class _CaissesScreenState extends ConsumerState<CaissesScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        title: 'Gestion des caisses',
        body: Column(
          children: [
            const ColoredBox(
              color: Colors.white,
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.gray400,
                indicatorColor: AppColors.primary,
                labelStyle: TextStyle(
                    fontSize: AppSizes.fontXs, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'Physiques'),
                  Tab(text: 'Zone'),
                  Tab(text: 'Entreprise'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _CaissesPhysiquesTab(),
                  _CaissesZoneTab(),
                  _CaisseEntrepriseTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Onglet Caisses Physiques ─────────────────────────────────────────────────

class _CaissesPhysiquesTab extends ConsumerWidget {
  const _CaissesPhysiquesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(caissesProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: e.toString(),
        onRetry: () => ref.read(caissesProvider.notifier).refresh(),
      ),
      data: (s) => _CaissesList<CaissePhysiqueEntity>(
        caisses: s.physiques,
        canManage: ref.watch(effectiveRoleProvider) == 'admin',
        onRefresh: () => ref.read(caissesProvider.notifier).refresh(),
        onAdd: () => _showCreatePhysiqueSheet(context, ref),
        onFermer: (id) => _fermerPhysique(context, ref, id),
        labelNom: (c) => c.nom,
        labelSub: (c) => c.depotNom,
        solde: (c) => c.soldeActuel,
        statut: (c) => c.statutLabel,
        isOuverte: (c) => c.isOuverte,
        emptyLabel: 'Aucune caisse physique',
      ),
    );
  }

  void _showCreatePhysiqueSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateCaissePhysiqueSheet(ref: ref),
    );
  }

  Future<void> _fermerPhysique(
      BuildContext context, WidgetRef ref, int id) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Fermer la caisse',
      message:
          'Cette action est IRRÉVERSIBLE. La caisse ne pourra plus jamais être réouverte.',
      confirmLabel: 'Fermer définitivement',
      isDanger: true,
    );
    if (ok != true || !context.mounted) return;
    final err = await ref.read(caissesProvider.notifier).fermerCaisse(id);
    if (!context.mounted) return;
    if (err != null) {
      AppSnackbar.error(context, err);
    } else {
      AppSnackbar.success(context, 'Caisse fermée définitivement');
    }
  }
}

// ─── Onglet Caisses Zone ──────────────────────────────────────────────────────

class _CaissesZoneTab extends ConsumerWidget {
  const _CaissesZoneTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(caissesProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: e.toString(),
        onRetry: () => ref.read(caissesProvider.notifier).refresh(),
      ),
      data: (s) => _CaissesList<CaisseZoneEntity>(
        caisses: s.zones,
        canManage: ref.watch(effectiveRoleProvider) == 'admin',
        onRefresh: () => ref.read(caissesProvider.notifier).refresh(),
        onAdd: () => _showCreateZoneSheet(context, ref),
        onFermer: (id) => _fermerZone(context, ref, id),
        labelNom: (c) => c.nom,
        labelSub: (c) => c.zoneNom,
        solde: (c) => c.soldeActuel,
        statut: (c) => c.statutLabel,
        isOuverte: (c) => c.isOuverte,
        emptyLabel: 'Aucune caisse de zone',
      ),
    );
  }

  void _showCreateZoneSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateCaisseZoneSheet(ref: ref),
    );
  }

  Future<void> _fermerZone(BuildContext context, WidgetRef ref, int id) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Fermer la caisse zone',
      message:
          'Action IRRÉVERSIBLE. Impossible si des caisses physiques de la zone sont encore ouvertes.',
      confirmLabel: 'Fermer définitivement',
      isDanger: true,
    );
    if (ok != true || !context.mounted) return;
    final err = await ref.read(caissesProvider.notifier).fermerCaisseZone(id);
    if (!context.mounted) return;
    if (err != null) {
      AppSnackbar.error(context, err);
    } else {
      AppSnackbar.success(context, 'Caisse zone fermée définitivement');
    }
  }
}

// ─── Onglet Caisse Entreprise ─────────────────────────────────────────────────

class _CaisseEntrepriseTab extends ConsumerWidget {
  const _CaisseEntrepriseTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(caissesProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: e.toString(),
        onRetry: () => ref.read(caissesProvider.notifier).refresh(),
      ),
      data: (s) {
        if (s.entreprise == null) {
          return const Center(
            child: Text(
              'Caisse entreprise non configurée',
              style: TextStyle(color: AppColors.gray500),
            ),
          );
        }
        final c = s.entreprise!;
        return RefreshIndicator(
          onRefresh: () => ref.read(caissesProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.paddingPage),
            children: [
              _SoldeCard(
                nom: c.nom,
                sub: c.companyNom,
                solde: c.soldeActuel,
                devise: c.devise,
                statut: 'Permanente',
                isOuverte: true,
              ),
              const SizedBox(height: AppSizes.md),
              const Text(
                'La caisse entreprise est en lecture seule.\nElle consolide automatiquement les versements des caisses de zone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.gray400, fontSize: AppSizes.fontXs),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Liste caisses générique ──────────────────────────────────────────────────

class _CaissesList<T> extends StatelessWidget {
  const _CaissesList({
    required this.caisses,
    required this.onRefresh,
    required this.onAdd,
    required this.onFermer,
    required this.labelNom,
    required this.labelSub,
    required this.solde,
    required this.statut,
    required this.isOuverte,
    required this.emptyLabel,
    required this.canManage,
  });

  final List<T> caisses;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final void Function(int id) onFermer;
  // Seul l'admin crée/ferme les caisses dépôt/zone (validation des caisses de zone = prérogative admin).
  final bool canManage;
  final String Function(T) labelNom;
  final String Function(T) labelSub;
  final double Function(T) solde;
  final String Function(T) statut;
  final bool Function(T) isOuverte;
  final String emptyLabel;

  int _id(T c) {
    if (c is CaissePhysiqueEntity) return c.id;
    if (c is CaisseZoneEntity) return c.id;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: onAdd,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer'),
            )
          : null,
      body: caisses.isEmpty
          ? Center(
              child: Text(
                emptyLabel,
                style: const TextStyle(color: AppColors.gray500),
              ),
            )
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingPage, AppSizes.sm,
                    AppSizes.paddingPage, AppSizes.xxl),
                itemCount: caisses.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSizes.sm),
                itemBuilder: (_, i) {
                  final c = caisses[i];
                  return _SoldeCard(
                    nom: labelNom(c),
                    sub: labelSub(c),
                    solde: solde(c),
                    devise: 'GNF',
                    statut: statut(c),
                    isOuverte: isOuverte(c),
                    trailing: (isOuverte(c) && canManage)
                        ? TextButton(
                            onPressed: () => onFermer(_id(c)),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger),
                            child: const Text('Fermer'),
                          )
                        : null,
                  );
                },
              ),
            ),
    );
  }
}

// ─── Carte solde ──────────────────────────────────────────────────────────────

class _SoldeCard extends StatelessWidget {
  const _SoldeCard({
    required this.nom,
    required this.sub,
    required this.solde,
    required this.devise,
    required this.statut,
    required this.isOuverte,
    this.trailing,
  });

  final String nom;
  final String sub;
  final double solde;
  final String devise;
  final String statut;
  final bool isOuverte;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = isOuverte ? AppColors.secondary : AppColors.gray400;
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(Icons.account_balance_wallet_outlined,
                color: color, size: AppSizes.iconMd),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppSizes.fontSm,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                      fontSize: AppSizes.fontXs, color: AppColors.gray400),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.gnf(solde),
                  style: TextStyle(
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.w700,
                    color: solde < 0 ? AppColors.danger : AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  statut,
                  style: TextStyle(
                      fontSize: AppSizes.fontXs,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Formulaire création caisse physique ──────────────────────────────────────

class _CreateCaissePhysiqueSheet extends ConsumerStatefulWidget {
  const _CreateCaissePhysiqueSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_CreateCaissePhysiqueSheet> createState() =>
      _CreateCaissePhysiqueSheetState();
}

class _CreateCaissePhysiqueSheetState
    extends ConsumerState<_CreateCaissePhysiqueSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  int? _depotId;
  String _devise = 'GNF';
  bool _loading = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_depotId == null) return;
    setState(() => _loading = true);
    final err = await widget.ref.read(caissesProvider.notifier).createCaisse(
          nom: _nomCtrl.text.trim(),
          depotId: _depotId!,
          devise: _devise,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      AppSnackbar.error(context, err);
    } else {
      Navigator.of(context).pop();
      AppSnackbar.success(context, 'Caisse créée');
    }
  }

  @override
  Widget build(BuildContext context) {
    final depotsAsync = ref.watch(depotsProvider);
    final depots = depotsAsync.valueOrNull?.depots ?? [];
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSizes.paddingPage, AppSizes.lg, AppSizes.paddingPage, bottom + AppSizes.xl),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Nouvelle caisse physique',
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: AppSizes.md),
            DropdownButtonFormField<int>(
              hint: const Text('Dépôt *'),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: depots
                  .map((d) => DropdownMenuItem(value: d.id, child: Text(d.nom)))
                  .toList(),
              onChanged: (v) => setState(() => _depotId = v),
              validator: (v) => v == null ? 'Sélectionner un dépôt' : null,
            ),
            const SizedBox(height: AppSizes.md),
            DropdownButtonFormField<String>(
              initialValue: _devise,
              decoration: const InputDecoration(
                  labelText: 'Devise', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'GNF', child: Text('GNF (Franc Guinéen)')),
                DropdownMenuItem(value: 'USD', child: Text('USD (Dollar US)')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR (Euro)')),
              ],
              onChanged: (v) => _devise = v ?? 'GNF',
            ),
            const SizedBox(height: AppSizes.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Créer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulaire création caisse zone ─────────────────────────────────────────

class _CreateCaisseZoneSheet extends ConsumerStatefulWidget {
  const _CreateCaisseZoneSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_CreateCaisseZoneSheet> createState() =>
      _CreateCaisseZoneSheetState();
}

class _CreateCaisseZoneSheetState
    extends ConsumerState<_CreateCaisseZoneSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  int? _zoneId;
  String _devise = 'GNF';
  bool _loading = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_zoneId == null) return;
    setState(() => _loading = true);
    final err =
        await widget.ref.read(caissesProvider.notifier).createCaisseZone(
              nom: _nomCtrl.text.trim(),
              zoneId: _zoneId!,
              devise: _devise,
            );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      AppSnackbar.error(context, err);
    } else {
      Navigator.of(context).pop();
      AppSnackbar.success(context, 'Caisse zone créée');
    }
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(zonesProvider);
    final zones = zonesAsync.valueOrNull?.zones ?? [];
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSizes.paddingPage, AppSizes.lg, AppSizes.paddingPage, bottom + AppSizes.xl),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Nouvelle caisse zone',
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: AppSizes.md),
            DropdownButtonFormField<int>(
              hint: const Text('Zone *'),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: zones
                  .map((z) =>
                      DropdownMenuItem(value: z.id, child: Text(z.name)))
                  .toList(),
              onChanged: (v) => setState(() => _zoneId = v),
              validator: (v) => v == null ? 'Sélectionner une zone' : null,
            ),
            const SizedBox(height: AppSizes.md),
            DropdownButtonFormField<String>(
              initialValue: _devise,
              decoration: const InputDecoration(
                  labelText: 'Devise', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'GNF', child: Text('GNF (Franc Guinéen)')),
                DropdownMenuItem(value: 'USD', child: Text('USD (Dollar US)')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR (Euro)')),
              ],
              onChanged: (v) => _devise = v ?? 'GNF',
            ),
            const SizedBox(height: AppSizes.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Créer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers UI ───────────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
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
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray500)),
          const SizedBox(height: AppSizes.sm),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
