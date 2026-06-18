import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:djoulagest_mobile/features/suppliers/presentation/providers/suppliers_provider.dart';

class SupplierDetailScreen extends ConsumerWidget {
  const SupplierDetailScreen({super.key, required this.supplierId});
  final int supplierId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(supplierDetailProvider(supplierId));
    final evalsAsync = ref.watch(supplierEvaluationsProvider(supplierId));
    final ordersAsync = ref.watch(supplierOrdersProvider(supplierId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.gray200,
        foregroundColor: AppColors.gray700,
        title: detailAsync.maybeWhen(
          data: (s) => Text(s.nom,
              style: const TextStyle(
                color: AppColors.gray900,
                fontWeight: FontWeight.w600,
                fontSize: AppSizes.fontLg,
              )),
          orElse: () => const Text('Fournisseur'),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (supplier) => _DetailBody(
          supplier: supplier,
          evalsAsync: evalsAsync,
          ordersAsync: ordersAsync,
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.supplier,
    required this.evalsAsync,
    required this.ordersAsync,
  });

  final SupplierEntity supplier;
  final AsyncValue<List<SupplierEvaluationEntity>> evalsAsync;
  final AsyncValue<List<SupplierOrderEntity>> ordersAsync;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingPage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── En-tête ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.nom,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppSizes.fontXl,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  supplier.code,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: AppSizes.fontSm),
                ),
                if (supplier.hasDette) ...[
                  const SizedBox(height: AppSizes.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm, vertical: AppSizes.xs),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Text(
                      'Dette : ${AppFormatters.gnf(supplier.soldeDette)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ─── Coordonnées ───────────────────────────────────────────────
          _card(
            title: 'Coordonnées',
            children: [
              if (supplier.telephone != null)
                _infoRow(Icons.phone_rounded, 'Téléphone', supplier.telephone!),
              if (supplier.email != null)
                _infoRow(Icons.email_rounded, 'Email', supplier.email!),
              if (supplier.adresse != null)
                _infoRow(
                    Icons.location_on_rounded, 'Adresse', supplier.adresse!),
              if (supplier.telephone == null &&
                  supplier.email == null &&
                  supplier.adresse == null)
                const Text('Aucune coordonnée renseignée',
                    style: TextStyle(
                        color: AppColors.gray400,
                        fontSize: AppSizes.fontSm)),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // ─── Notes ─────────────────────────────────────────────────────
          if (supplier.notes != null && supplier.notes!.isNotEmpty) ...[
            _card(
              title: 'Notes',
              children: [
                Text(supplier.notes!,
                    style: const TextStyle(
                        color: AppColors.gray700,
                        fontSize: AppSizes.fontSm,
                        height: 1.5)),
              ],
            ),
            const SizedBox(height: AppSizes.md),
          ],

          // ─── Commandes récentes ────────────────────────────────────────
          _card(
            title: 'Commandes récentes',
            children: [
              ordersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const Text('Impossible de charger',
                    style: TextStyle(color: AppColors.gray400)),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const Text('Aucune commande',
                        style: TextStyle(
                            color: AppColors.gray400,
                            fontSize: AppSizes.fontSm));
                  }
                  return Column(
                    children: orders.take(5).map((o) {
                      final color = _statutColor(o.statut);
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSizes.xs),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(o.numero,
                                      style: const TextStyle(
                                          fontSize: AppSizes.fontSm,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.gray900)),
                                  if (o.depotNom != null)
                                    Text(o.depotNom!,
                                        style: const TextStyle(
                                            fontSize: AppSizes.fontXs,
                                            color: AppColors.gray400)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusFull),
                              ),
                              child: Text(o.statutLabel,
                                  style: TextStyle(
                                      fontSize: AppSizes.fontXs,
                                      fontWeight: FontWeight.w600,
                                      color: color)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // ─── Évaluations ───────────────────────────────────────────────
          _card(
            title: 'Évaluations',
            children: [
              evalsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const Text('Impossible de charger',
                    style: TextStyle(color: AppColors.gray400)),
                data: (evals) {
                  if (evals.isEmpty) {
                    return const Text('Aucune évaluation',
                        style: TextStyle(
                            color: AppColors.gray400,
                            fontSize: AppSizes.fontSm));
                  }
                  final avg = evals
                          .map((e) => e.noteGlobale)
                          .reduce((a, b) => a + b) /
                      evals.length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.accent,
                              size: AppSizes.iconMd),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            avg.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: AppSizes.fontLg,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900),
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            '(${evals.length} éval.)',
                            style: const TextStyle(
                                fontSize: AppSizes.fontSm,
                                color: AppColors.gray400),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      ...evals.take(3).map((e) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSizes.xs),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  _starRow(e.noteQualite, 'Qualité'),
                                  const SizedBox(width: AppSizes.md),
                                  _starRow(e.noteDelai, 'Délai'),
                                  const SizedBox(width: AppSizes.md),
                                  _starRow(e.noteService, 'Service'),
                                ]),
                                if (e.commentaire != null &&
                                    e.commentaire!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: AppSizes.xs),
                                    child: Text(
                                      e.commentaire!,
                                      style: const TextStyle(
                                          fontSize: AppSizes.fontXs,
                                          color: AppColors.gray500,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                const Divider(
                                    color: AppColors.gray100,
                                    height: AppSizes.md),
                              ],
                            ),
                          )),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.gray400),
          const SizedBox(width: AppSizes.xs),
          Text(
            '$label : ',
            style: const TextStyle(
                fontSize: AppSizes.fontSm, color: AppColors.gray500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _starRow(int note, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: AppSizes.fontXs, color: AppColors.gray400)),
        Row(
          children: List.generate(
              5,
              (i) => Icon(
                    i < note ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 12,
                    color: AppColors.accent,
                  )),
        ),
      ],
    );
  }

  Color _statutColor(String statut) {
    return switch (statut) {
      'brouillon' => AppColors.gray400,
      'envoyee' => AppColors.accent,
      'recue_partielle' => AppColors.primaryLight,
      'recue' => AppColors.secondary,
      'annulee' => AppColors.danger,
      _ => AppColors.gray400,
    };
  }
}
