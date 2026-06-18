import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/features/admin/domain/entities/company_entity.dart';
import 'package:djoulagest_mobile/features/admin/presentation/providers/companies_provider.dart';
import 'package:djoulagest_mobile/features/admin/presentation/screens/company_form_sheet.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';
import 'package:djoulagest_mobile/shared/widgets/confirm_dialog.dart';
import 'package:djoulagest_mobile/shared/widgets/empty_state.dart';

// ─── Couleurs par plan ────────────────────────────────────────────────────────

const _planColors = <String, Color>{
  'free': AppColors.gray500,
  'starter': AppColors.primary,
  'pro': Color(0xFF7C3AED),
  'enterprise': AppColors.accent,
};

Color _planColor(String plan) => _planColors[plan] ?? AppColors.gray500;

// ─── Écran ───────────────────────────────────────────────────────────────────

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

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
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(companiesProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(companiesProvider.notifier).searchCompanies(q);
    });
  }

  Future<void> _openCreate() async {
    await CompanyFormSheet.show(
      context,
      onSave: (name, emailAdmin, plan) async {
        final err = await ref.read(companiesProvider.notifier).create(
              name: name,
              emailAdmin: emailAdmin!,
              subscriptionPlan: plan,
            );
        if (!mounted) return;
        if (err == null) {
          Navigator.of(context).pop();
          AppSnackbar.success(context, 'Entreprise créée avec succès.');
        } else {
          AppSnackbar.error(context, err);
        }
      },
    );
  }

  Future<void> _openEdit(CompanyEntity company) async {
    await CompanyFormSheet.show(
      context,
      company: company,
      onSave: (name, _, plan) async {
        final err = await ref.read(companiesProvider.notifier).updateCompany(
              id: company.id,
              name: name,
              subscriptionPlan: plan,
            );
        if (!mounted) return;
        if (err == null) {
          Navigator.of(context).pop();
          AppSnackbar.success(context, 'Entreprise mise à jour.');
        } else {
          AppSnackbar.error(context, err);
        }
      },
    );
  }

  Future<void> _confirmToggle(CompanyEntity company) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: company.isActive ? 'Suspendre l\'entreprise' : 'Réactiver l\'entreprise',
      message: company.isActive
          ? 'Les utilisateurs de "${company.name}" ne pourront plus se connecter.'
          : 'Les utilisateurs de "${company.name}" pourront à nouveau se connecter.',
      confirmLabel: company.isActive ? 'Suspendre' : 'Réactiver',
      isDanger: company.isActive,
      icon: company.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
    );
    if (confirmed != true || !mounted) return;
    final err = await ref.read(companiesProvider.notifier).toggle(company.id);
    if (!mounted) return;
    if (err == null) {
      AppSnackbar.success(
        context,
        company.isActive ? 'Entreprise suspendue.' : 'Entreprise réactivée.',
      );
    } else {
      AppSnackbar.error(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);

    return AppScaffold(
      title: 'Entreprises',
      additionalActions: [
        IconButton(
          icon: const Icon(Icons.add_business_rounded, color: AppColors.primary),
          tooltip: 'Nouvelle entreprise',
          onPressed: _openCreate,
        ),
      ],
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md, AppSizes.md, AppSizes.md, 0,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher une entreprise…',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray400),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.gray400),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(companiesProvider.notifier)
                              .searchCompanies('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Compteur
          companiesAsync.whenData((s) => s.total > 0
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, AppSizes.sm, AppSizes.md, 0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${s.total} entreprise${s.total > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink()).valueOrNull ?? const SizedBox.shrink(),

          // Liste
          Expanded(
            child: companiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                title: 'Erreur de chargement',
                subtitle: e.toString(),
                icon: Icons.cloud_off_rounded,
                action: () => ref.read(companiesProvider.notifier).refresh(),
                actionLabel: 'Réessayer',
              ),
              data: (s) {
                if (s.companies.isEmpty) {
                  return EmptyState(
                    title: _searchCtrl.text.isNotEmpty
                        ? 'Aucun résultat'
                        : 'Aucune entreprise',
                    subtitle: _searchCtrl.text.isNotEmpty
                        ? 'Essayez un autre terme de recherche.'
                        : 'Créez la première entreprise cliente.',
                    icon: Icons.business_outlined,
                    action: _searchCtrl.text.isEmpty ? _openCreate : null,
                    actionLabel: 'Créer une entreprise',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(companiesProvider.notifier).refresh(),
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.lg,
                    ),
                    itemCount:
                        s.companies.length + (s.isLoadingMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == s.companies.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.lg),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final company = s.companies[i];
                      return _CompanyCard(
                        key: ValueKey(company.id),
                        company: company,
                        onEdit: () => _openEdit(company),
                        onToggle: () => _confirmToggle(company),
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

// ─── Carte entreprise ────────────────────────────────────────────────────────

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    super.key,
    required this.company,
    required this.onEdit,
    required this.onToggle,
  });

  final CompanyEntity company;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = _planColor(company.subscriptionPlan);
    final createdLabel = _formatDate(company.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: const BorderSide(color: AppColors.gray100),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              backgroundImage: company.logo != null
                  ? NetworkImage(company.logo!)
                  : null,
              child: company.logo == null
                  ? Text(
                      company.initials,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSizes.md),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.fontMd,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _PlanBadge(plan: company.subscriptionPlan, color: color),
                      const SizedBox(width: AppSizes.xs),
                      _StatusChip(isActive: company.isActive),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 12, color: AppColors.gray400),
                      const SizedBox(width: 3),
                      Text(
                        '${company.nombreUtilisateurs}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.gray400),
                      const SizedBox(width: 3),
                      Text(
                        '${company.nombreZones} zone${company.nombreZones != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        createdLabel,
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.gray400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'toggle') onToggle();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppColors.gray600),
                      SizedBox(width: AppSizes.sm),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        company.isActive
                            ? Icons.block_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                        color: company.isActive ? AppColors.danger : AppColors.secondary,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        company.isActive ? 'Suspendre' : 'Réactiver',
                        style: TextStyle(
                          color: company.isActive ? AppColors.danger : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc',
    ];
    return '${dt.day} ${months[dt.month - 1]}. ${dt.year}';
  }
}

// ─── Badge plan ──────────────────────────────────────────────────────────────

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.plan, required this.color});
  final String plan;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = planLabels[plan] ?? plan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppSizes.fontXs,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Chip statut ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.secondary : AppColors.gray400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Suspendue',
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
