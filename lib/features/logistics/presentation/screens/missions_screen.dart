import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/depots/presentation/providers/depots_provider.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/providers/logistics_provider.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/widgets/mission_card.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

const _writeRoles = {'admin', 'superviseur', 'gestionnaire_stock'};

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  static const _filters = [
    ('Toutes', ''),
    ('Planifiées', 'planifiee'),
    ('Chargement', 'chargement'),
    ('En route', 'en_transit'),
    ('Arrivées', 'arrivee'),
    ('Terminées', 'terminee'),
    ('Litige', 'litige'),
  ];

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          ref.read(missionsProvider.notifier).loadMore();
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
    final missionsAsync = ref.watch(missionsProvider);
    final currentFilter = missionsAsync.valueOrNull?.filter ?? '';
    final role = ref.watch(effectiveRoleProvider);
    final canCreate = _writeRoles.contains(role);

    return AppScaffold(
      title: 'Missions logistiques',
      showBottomNav: true,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateSheet(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Créer une mission',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Column(
        children: [
          // ─── Filtres statut ──────────────────────────────────────────────
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
                  onTap: () => ref
                      .read(missionsProvider.notifier)
                      .setFilter(value),
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
                        color: selected
                            ? AppColors.primary
                            : AppColors.gray500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ─── Liste ──────────────────────────────────────────────────────
          Expanded(
            child: missionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    const Text('Impossible de charger les missions',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(missionsProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.missions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_rounded,
                              size: AppSizes.iconXxl,
                              color: AppColors.gray200),
                          SizedBox(height: AppSizes.md),
                          Text('Aucune mission trouvée',
                              style: TextStyle(color: AppColors.gray500)),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(missionsProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingPage,
                        0,
                        AppSizes.paddingPage,
                        AppSizes.xxl),
                    itemCount: state.missions.length +
                        (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.sm),
                    itemBuilder: (ctx, i) {
                      if (i == state.missions.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child: Center(
                              child: CircularProgressIndicator()),
                        );
                      }
                      return MissionCard(
                        mission: state.missions[i],
                        onTap: () => context
                            .push('/logistics/${state.missions[i].id}'),
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

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateMissionSheet(parentRef: ref),
    );
  }
}

// ─── Formulaire création mission ─────────────────────────────────────────────

class _CreateMissionSheet extends ConsumerStatefulWidget {
  const _CreateMissionSheet({required this.parentRef});
  final WidgetRef parentRef;

  @override
  ConsumerState<_CreateMissionSheet> createState() =>
      _CreateMissionSheetState();
}

class _CreateMissionSheetState extends ConsumerState<_CreateMissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  int? _vehiculeId;
  int? _chauffeurId;
  int? _depotDepartId;
  int? _depotArriveeId;
  bool _loading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehiculesAsync = ref.watch(vehiculesSimpleProvider);
    final chauffeursAsync = ref.watch(chauffeursSimpleProvider);
    final depotsAsync = ref.watch(depotsProvider);

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
              // Handle
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
                'Nouvelle mission',
                style: TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Véhicule
              _buildDropdownField<int>(
                label: 'Véhicule *',
                selectedValue: _vehiculeId,
                items: vehiculesAsync.when(
                  data: (list) => list
                      .map((v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(
                              v.marque != null
                                  ? '${v.immatriculation} — ${v.marque}'
                                  : v.immatriculation,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  loading: () => [],
                  error: (_, __) => [],
                ),
                isLoading: vehiculesAsync.isLoading,
                onChanged: (v) => setState(() => _vehiculeId = v),
                validator: (v) => v == null ? 'Sélectionner un véhicule' : null,
              ),
              const SizedBox(height: AppSizes.md),

              // Chauffeur
              _buildDropdownField<int>(
                label: 'Chauffeur *',
                selectedValue: _chauffeurId,
                items: chauffeursAsync.when(
                  data: (list) => list
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.fullName, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  loading: () => [],
                  error: (_, __) => [],
                ),
                isLoading: chauffeursAsync.isLoading,
                onChanged: (v) => setState(() => _chauffeurId = v),
                validator: (v) => v == null ? 'Sélectionner un chauffeur' : null,
              ),
              const SizedBox(height: AppSizes.md),

              // Dépôt départ
              _buildDropdownField<int>(
                label: 'Dépôt de départ *',
                selectedValue: _depotDepartId,
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
                onChanged: (v) => setState(() => _depotDepartId = v),
                validator: (v) => v == null ? 'Sélectionner le dépôt de départ' : null,
              ),
              const SizedBox(height: AppSizes.md),

              // Dépôt arrivée
              _buildDropdownField<int>(
                label: 'Dépôt d\'arrivée *',
                selectedValue: _depotArriveeId,
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
                onChanged: (v) => setState(() => _depotArriveeId = v),
                validator: (v) => v == null ? 'Sélectionner le dépôt d\'arrivée' : null,
              ),
              const SizedBox(height: AppSizes.md),

              // Notes (optionnel)
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: _inputDecoration('Notes (optionnel)'),
              ),
              const SizedBox(height: AppSizes.xl),

              // Bouton
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
                          'Créer la mission',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: AppSizes.fontMd),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? selectedValue,
    required List<DropdownMenuItem<T>> items,
    required bool isLoading,
    required void Function(T?) onChanged,
    required String? Function(T?) validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: selectedValue,
      decoration: _inputDecoration(label),
      isExpanded: true,
      hint: isLoading
          ? const Row(children: [
              SizedBox(
                  width: 16, height: 16,
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
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
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await widget.parentRef.read(missionsProvider.notifier).createMission(
          vehiculeId: _vehiculeId!,
          chauffeurId: _chauffeurId!,
          depotDepartId: _depotDepartId!,
          depotArriveeId: _depotArriveeId!,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
        ),
      );
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission créée avec succès'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }
}
