import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/reports/domain/entities/report_entity.dart';
import 'package:djoulagest_mobile/features/reports/presentation/providers/reports_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

/// Rapports & Analyses — miroir mobile de la page web `/rapports`.
/// Consomme /analytics/ventes|stock|finance avec filtre de période.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportsProvider);

    return AppScaffold(
      title: 'Rapports & Analyses',
      body: RefreshIndicator(
        onRefresh: () => ref.read(reportsProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingPage,
            AppSizes.md,
            AppSizes.paddingPage,
            AppSizes.xxl,
          ),
          children: [
            Text(
              "Vue d'ensemble de l'activité de votre entreprise",
              style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.gray500),
            ),
            const SizedBox(height: AppSizes.md),
            const _PeriodFilter(),
            const SizedBox(height: AppSizes.lg),
            reportAsync.when(
              loading: () => const _LoadingView(),
              error: (_, __) => _ErrorView(
                onRetry: () => ref.read(reportsProvider.notifier).refresh(),
              ),
              data: (data) => _ReportBody(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filtre période ───────────────────────────────────────────────────────────

class _PeriodFilter extends ConsumerWidget {
  const _PeriodFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportPeriodProvider);
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: ReportPeriod.values.map((p) {
        final active = p == selected;
        return GestureDetector(
          onTap: () => ref.read(reportPeriodProvider.notifier).state = p,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm + 2,
            ),
            decoration: BoxDecoration(
              color: active ? AppColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: active ? AppColors.primaryLight : AppColors.borderLight,
              ),
            ),
            child: Text(
              p.label,
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.gray600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Corps ────────────────────────────────────────────────────────────────────

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.data});
  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final v = data.ventes;
    final s = data.stock;
    final f = data.finance;

    if (data.isEmpty) return const _EmptyView();

    final alertes = s?.nbProduitsEnAlerte ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── KPIs Ventes ──
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSizes.sm + 4,
          crossAxisSpacing: AppSizes.sm + 4,
          childAspectRatio: 1.45,
          children: [
            _KpiCard(
              icon: Icons.shopping_bag_outlined,
              color: AppColors.secondary,
              value: (v?.nbCommandes ?? 0) > 0 ? '${v!.nbCommandes}' : '—',
              label: 'Commandes',
            ),
            _KpiCard(
              icon: Icons.payments_outlined,
              color: AppColors.primary,
              value: AppFormatters.gnf(v?.caTtc ?? 0),
              label: 'CA TTC',
            ),
            _KpiCard(
              icon: Icons.check_circle_outline,
              color: AppColors.cyan,
              value: AppFormatters.gnf(v?.montantPaye ?? 0),
              label: 'Encaissé',
            ),
            _KpiCard(
              icon: Icons.warning_amber_rounded,
              color: alertes > 0 ? AppColors.danger : AppColors.accent,
              value: '$alertes',
              label: 'Alertes stock',
              highlight: alertes > 0,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),

        // ── Finance ──
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Recettes',
                value: AppFormatters.gnf(f?.recettes ?? 0),
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSizes.sm + 4),
            Expanded(
              child: _MiniStat(
                label: 'Dépenses',
                value: AppFormatters.gnf(f?.depenses ?? 0),
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm + 4),
        _SoldeCard(solde: f?.solde ?? 0),
        const SizedBox(height: AppSizes.lg),

        // ── CA par dépôt ──
        if ((v?.parDepot ?? const []).isNotEmpty)
          _CaParDepot(depots: v!.parDepot, totalCa: v.caTtc),

        // ── Top produits sortie ──
        if ((s?.topProduitsSortie ?? const []).isNotEmpty)
          _TopProduits(produits: s!.topProduitsSortie),

        // ── Produits en alerte ──
        if ((s?.produitsEnAlerte ?? const []).isNotEmpty)
          _ProduitsAlerte(produits: s!.produitsEnAlerte),
      ],
    );
  }
}

// ─── KPI card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: highlight ? AppColors.dangerLightBg : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: highlight ? AppColors.danger.withValues(alpha: 0.3) : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconMd),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppSizes.fontXl,
                  fontWeight: FontWeight.bold,
                  color: highlight ? AppColors.danger : AppColors.gray900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.gray500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Mini stat (recettes / dépenses) ─────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoldeCard extends StatelessWidget {
  const _SoldeCard({required this.solde});
  final num solde;

  @override
  Widget build(BuildContext context) {
    final positif = solde >= 0;
    final color = positif ? AppColors.secondary : AppColors.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOLDE NET',
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            AppFormatters.gnf(solde),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CA par dépôt ─────────────────────────────────────────────────────────────

class _CaParDepot extends StatelessWidget {
  const _CaParDepot({required this.depots, required this.totalCa});
  final List<DepotCa> depots;
  final num totalCa;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: "Chiffre d'affaires par dépôt",
      child: Column(
        children: depots.map((d) {
          final ratio = totalCa > 0 ? (d.caTtc / totalCa).clamp(0.0, 1.0).toDouble() : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.depotNom.isEmpty ? d.depotCode : d.depotNom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      AppFormatters.gnf(d.caTtc),
                      style: TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: AppColors.gray100,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${d.nbCommandes} cmd · ${d.depotCode}',
                  style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.gray400),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Top produits sortie ──────────────────────────────────────────────────────

class _TopProduits extends StatelessWidget {
  const _TopProduits({required this.produits});
  final List<ProduitSortie> produits;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Top produits — sorties de stock',
      child: Column(
        children: List.generate(produits.length, (i) {
          final p = produits[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray400,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                      if (p.reference.isNotEmpty)
                        Text(
                          p.reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.gray400),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  p.totalSortie,
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Produits en alerte ───────────────────────────────────────────────────────

class _ProduitsAlerte extends StatelessWidget {
  const _ProduitsAlerte({required this.produits});
  final List<ProduitAlerte> produits;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerLightBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: AppSizes.iconSm, color: AppColors.danger),
                const SizedBox(width: AppSizes.sm),
                Text(
                  'Produits en rupture / alerte',
                  style: TextStyle(
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          ...produits.map((p) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.md,
                  0,
                  AppSizes.md,
                  AppSizes.sm + 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.produitNom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppSizes.fontSm,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                          ),
                          Text(
                            '${p.produitReference} · Dépôt ${p.depotCode}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.gray400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          p.quantite,
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                        Text(
                          'seuil : ${p.seuil}',
                          style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.gray400),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Carte générique ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSizes.lg),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          child,
        ],
      ),
    );
  }
}

// ─── États ────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: AppSizes.iconXxl, color: AppColors.gray300),
          const SizedBox(height: AppSizes.md),
          Text(
            'Impossible de charger les rapports',
            style: TextStyle(fontSize: AppSizes.fontMd, color: AppColors.gray500),
          ),
          const SizedBox(height: AppSizes.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: AppSizes.iconXxl, color: AppColors.gray200),
          const SizedBox(height: AppSizes.md),
          Text(
            'Aucune donnée pour cette période',
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            "Les données s'afficheront dès que des ventes seront enregistrées.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }
}
