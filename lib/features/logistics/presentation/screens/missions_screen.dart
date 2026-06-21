import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
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
  int? _clientId;
  int? _fournisseurId;
  String _typeMission = 'transfert';
  bool _loading = false;

  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _fournisseurs = [];

  static const _typeOptions = [
    ('transfert', 'Transfert inter-dépôt', 'Dépôt → Dépôt (marchandise interne)'),
    ('livraison', 'Livraison client', 'Dépôt → Client'),
    ('enlevement', 'Enlèvement fournisseur', 'Fournisseur → Dépôt'),
  ];

  @override
  void initState() {
    super.initState();
    _loadClientsFournisseurs();
  }

  Future<void> _loadClientsFournisseurs() async {
    try {
      final api = ref.read(apiClientProvider);
      final cRes = await api.get<Map<String, dynamic>>(
        ApiEndpoints.clients,
        queryParameters: {'page_size': 100, 'is_active': true},
      );
      final fRes = await api.get<Map<String, dynamic>>(
        ApiEndpoints.fournisseurs,
        queryParameters: {'page_size': 100, 'is_active': true},
      );
      if (!mounted) return;
      setState(() {
        _clients = List<Map<String, dynamic>>.from((cRes.data?['results'] ?? []) as List);
        _fournisseurs = List<Map<String, dynamic>>.from((fRes.data?['results'] ?? []) as List);
      });
    } catch (_) {/* listes vides → dropdowns vides, non bloquant */}
  }

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

              // Type de mission
              DropdownButtonFormField<String>(
                initialValue: _typeMission,
                isExpanded: true,
                decoration: _inputDecoration('Type de mission *'),
                items: _typeOptions
                    .map((t) => DropdownMenuItem(
                          value: t.$1,
                          child: Text('${t.$2} — ${t.$3}',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: _loading ? null : (v) => setState(() => _typeMission = v ?? 'transfert'),
              ),
              const SizedBox(height: AppSizes.md),

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

              // ── Champs selon le type de mission ────────────────────────────
              // Dépôt de départ / source : transfert + livraison
              if (_typeMission == 'transfert' || _typeMission == 'livraison') ...[
                _buildDropdownField<int>(
                  label: _typeMission == 'livraison' ? 'Dépôt source *' : 'Dépôt de départ *',
                  selectedValue: _depotDepartId,
                  items: depotsAsync.when(
                    data: (s) => s.depots
                        .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.nom, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    loading: () => [],
                    error: (_, __) => [],
                  ),
                  isLoading: depotsAsync.isLoading,
                  onChanged: (v) => setState(() => _depotDepartId = v),
                  validator: (v) => v == null ? 'Sélectionner le dépôt' : null,
                ),
                const SizedBox(height: AppSizes.md),
              ],

              // Client : livraison
              if (_typeMission == 'livraison') ...[
                _buildDropdownField<int>(
                  label: 'Client *',
                  selectedValue: _clientId,
                  items: _clients
                      .map((c) => DropdownMenuItem(
                          value: c['id'] as int,
                          child: Text(
                              (c['nom_complet'] ?? c['nom'] ?? '—').toString(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  isLoading: false,
                  onChanged: (v) => setState(() => _clientId = v),
                  validator: (v) => v == null ? 'Sélectionner un client' : null,
                ),
                const SizedBox(height: AppSizes.md),
              ],

              // Fournisseur : enlèvement
              if (_typeMission == 'enlevement') ...[
                _buildDropdownField<int>(
                  label: 'Fournisseur *',
                  selectedValue: _fournisseurId,
                  items: _fournisseurs
                      .map((f) => DropdownMenuItem(
                          value: f['id'] as int,
                          child: Text((f['nom'] ?? '—').toString(),
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  isLoading: false,
                  onChanged: (v) => setState(() => _fournisseurId = v),
                  validator: (v) => v == null ? 'Sélectionner un fournisseur' : null,
                ),
                const SizedBox(height: AppSizes.md),
              ],

              // Dépôt d'arrivée / destination : transfert + enlèvement
              if (_typeMission == 'transfert' || _typeMission == 'enlevement') ...[
                _buildDropdownField<int>(
                  label: _typeMission == 'enlevement' ? 'Dépôt de destination *' : 'Dépôt d\'arrivée *',
                  selectedValue: _depotArriveeId,
                  items: depotsAsync.when(
                    data: (s) => s.depots
                        .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.nom, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    loading: () => [],
                    error: (_, __) => [],
                  ),
                  isLoading: depotsAsync.isLoading,
                  onChanged: (v) => setState(() => _depotArriveeId = v),
                  validator: (v) => v == null ? 'Sélectionner le dépôt' : null,
                ),
                const SizedBox(height: AppSizes.md),
              ],

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
              Flexible(
                child: Text('Chargement…',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
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

    // On n'envoie que les champs pertinents au type (le backend valide le reste).
    final isTransfert = _typeMission == 'transfert';
    final isLivraison = _typeMission == 'livraison';
    final isEnlevement = _typeMission == 'enlevement';

    final error = await widget.parentRef.read(missionsProvider.notifier).createMission(
          vehiculeId: _vehiculeId!,
          chauffeurId: _chauffeurId!,
          typeMission: _typeMission,
          depotDepartId: (isTransfert || isLivraison) ? _depotDepartId : null,
          depotArriveeId: (isTransfert || isEnlevement) ? _depotArriveeId : null,
          clientId: isLivraison ? _clientId : null,
          fournisseurId: isEnlevement ? _fournisseurId : null,
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
