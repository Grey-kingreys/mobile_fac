import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/hr/domain/entities/attendance_entity.dart';
import 'package:djoulagest_mobile/features/hr/presentation/providers/hr_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _canCreatePresence = [
    'admin', 'superviseur', 'gestionnaire_stock'
  ];
  static const _canManageConge = ['admin', 'superviseur'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(effectiveRoleProvider);

    return AppScaffold(
      title: 'Présences & Congés',
      showBottomNav: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabs.index == 0 && _canCreatePresence.contains(role)) {
            _showAddPresenceSheet();
          } else if (_tabs.index == 1) {
            _showAddCongeSheet();
          } else if (_tabs.index == 0 && !_canCreatePresence.contains(role)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vous n\'avez pas les droits pour enregistrer une présence'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: AnimatedBuilder(
          animation: _tabs,
          builder: (_, __) => Text(_tabs.index == 0 ? 'Présence' : 'Congé'),
        ),
      ),
      body: Column(
        children: [
          // ─── Tabs ───────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.gray400,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Présences'),
                Tab(text: 'Congés'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PresencesTab(canCreate: _canCreatePresence.contains(role)),
                _CongesTab(canManage: _canManageConge.contains(role)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPresenceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _AddPresenceSheet(
        onSaved: () => ref.read(presencesProvider.notifier).refresh(),
      ),
    );
  }

  void _showAddCongeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _AddCongeSheet(
        onSaved: () => ref.read(congesProvider.notifier).refresh(),
      ),
    );
  }
}

// ─── Tab Présences ────────────────────────────────────────────────────────────

class _PresencesTab extends ConsumerWidget {
  const _PresencesTab({required this.canCreate});
  final bool canCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presencesAsync = ref.watch(presencesProvider);

    return presencesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: AppSizes.iconXxl, color: AppColors.gray300),
            const SizedBox(height: AppSizes.md),
            const Text('Impossible de charger les présences',
                style: TextStyle(color: AppColors.gray500)),
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: () =>
                  ref.read(presencesProvider.notifier).refresh(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (state) {
        if (state.presences.isEmpty) {
          return const Center(
            child: Text('Aucune présence enregistrée',
                style: TextStyle(color: AppColors.gray500)),
          );
        }

        final controller = ScrollController();
        controller.addListener(() {
          if (controller.position.pixels >=
              controller.position.maxScrollExtent - 200) {
            ref.read(presencesProvider.notifier).loadMore();
          }
        });

        return RefreshIndicator(
          onRefresh: () => ref.read(presencesProvider.notifier).refresh(),
          child: ListView.separated(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage,
                AppSizes.sm,
                AppSizes.paddingPage,
                AppSizes.xxl),
            itemCount:
                state.presences.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSizes.xs),
            itemBuilder: (_, i) {
              if (i == state.presences.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppSizes.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _PresenceTile(presence: state.presences[i]);
            },
          ),
        );
      },
    );
  }
}

class _PresenceTile extends StatelessWidget {
  const _PresenceTile({required this.presence});
  final PresenceEntity presence;

  Color get _typeColor => switch (presence.typePresence) {
        'present' => AppColors.secondary,
        'absent' => AppColors.danger,
        'retard' => AppColors.accent,
        'mission' => AppColors.primaryLight,
        _ => AppColors.gray400,
      };

  IconData get _typeIcon => switch (presence.typePresence) {
        'present' => Icons.check_circle_rounded,
        'absent' => Icons.cancel_rounded,
        'retard' => Icons.schedule_rounded,
        'mission' => Icons.directions_car_rounded,
        _ => Icons.help_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: AppSizes.iconSm),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presence.employeNom,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  presence.date,
                  style: const TextStyle(
                      fontSize: AppSizes.fontXs, color: AppColors.gray400),
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
                  color: _typeColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  presence.typeLabel,
                  style: TextStyle(
                      fontSize: AppSizes.fontXs,
                      fontWeight: FontWeight.w600,
                      color: _typeColor),
                ),
              ),
              if (presence.heureArrivee != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${presence.heureArrivee}${presence.heureDepart != null ? ' → ${presence.heureDepart}' : ''}',
                    style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.gray400),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tab Congés ───────────────────────────────────────────────────────────────

class _CongesTab extends ConsumerStatefulWidget {
  const _CongesTab({required this.canManage});
  final bool canManage;

  @override
  ConsumerState<_CongesTab> createState() => _CongesTabState();
}

class _CongesTabState extends ConsumerState<_CongesTab> {
  String _statut = '';

  static const _filters = [
    ('Tous', ''),
    ('En attente', 'en_attente'),
    ('Approuvés', 'approuve'),
    ('Refusés', 'refuse'),
  ];

  @override
  Widget build(BuildContext context) {
    final congesAsync = ref.watch(congesProvider);

    return Column(
      children: [
        // Filtres
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingPage, AppSizes.sm, AppSizes.paddingPage, 0),
          child: SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.map((f) {
                final (label, value) = f;
                final selected = _statut == value;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSizes.xs),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _statut = value);
                      ref.read(congesProvider.notifier).filterStatut(value);
                    },
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
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xs),

        Expanded(
          child: congesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: AppSizes.iconXxl, color: AppColors.gray300),
                  const SizedBox(height: AppSizes.md),
                  const Text('Impossible de charger les congés',
                      style: TextStyle(color: AppColors.gray500)),
                  const SizedBox(height: AppSizes.sm),
                  TextButton(
                    onPressed: () =>
                        ref.read(congesProvider.notifier).refresh(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
            data: (state) {
              if (state.conges.isEmpty) {
                return const Center(
                  child: Text('Aucun congé trouvé',
                      style: TextStyle(color: AppColors.gray500)),
                );
              }

              final controller = ScrollController();
              controller.addListener(() {
                if (controller.position.pixels >=
                    controller.position.maxScrollExtent - 200) {
                  ref.read(congesProvider.notifier).loadMore();
                }
              });

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(congesProvider.notifier).refresh(),
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingPage,
                      AppSizes.sm,
                      AppSizes.paddingPage,
                      AppSizes.xxl),
                  itemCount:
                      state.conges.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.xs),
                  itemBuilder: (_, i) {
                    if (i == state.conges.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSizes.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _CongeTile(
                      conge: state.conges[i],
                      canManage: widget.canManage,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CongeTile extends ConsumerWidget {
  const _CongeTile({required this.conge, required this.canManage});
  final CongeEntity conge;
  final bool canManage;

  Color get _statutColor => switch (conge.statut) {
        'approuve' => AppColors.secondary,
        'refuse' => AppColors.danger,
        'en_attente' => AppColors.accent,
        _ => AppColors.gray400,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  conge.employeNom,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statutColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  conge.statutLabel,
                  style: TextStyle(
                      fontSize: AppSizes.fontXs,
                      fontWeight: FontWeight.w600,
                      color: _statutColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text(
                '${conge.dateDebut} → ${conge.dateFin} (${conge.nbJours} j.)',
                style: const TextStyle(
                    fontSize: AppSizes.fontXs, color: AppColors.gray500),
              ),
            ],
          ),
          if (conge.typeLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                conge.typeLabel,
                style: const TextStyle(
                    fontSize: AppSizes.fontXs, color: AppColors.gray400),
              ),
            ),
          if (conge.motif != null && conge.motif!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.xs),
              child: Text(
                conge.motif!,
                style: const TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.gray500,
                    fontStyle: FontStyle.italic),
              ),
            ),

          // Boutons approuver/refuser pour les gestionnaires
          if (canManage && conge.isEnAttente) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(congesProvider.notifier)
                        .refuser(conge.id),
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.xs),
                      textStyle: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(congesProvider.notifier)
                        .approuver(conge.id),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text('Approuver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.xs),
                      textStyle: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Formulaire présence ─────────────────────────────────────────────────────

class _AddPresenceSheet extends ConsumerStatefulWidget {
  const _AddPresenceSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  ConsumerState<_AddPresenceSheet> createState() => _AddPresenceSheetState();
}

class _AddPresenceSheetState extends ConsumerState<_AddPresenceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _employeCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  String _typePresence = 'present';
  bool _isSaving = false;

  static const _types = [
    ('Présent', 'present'),
    ('Absent', 'absent'),
    ('Retard', 'retard'),
    ('Mission', 'mission'),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _employeCtrl.dispose();
    _dateCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(presencesProvider.notifier).create({
        'employe': int.parse(_employeCtrl.text.trim()),
        'date': _dateCtrl.text,
        'type_presence': _typePresence,
        if (_obsCtrl.text.isNotEmpty) 'observations': _obsCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Présence enregistrée'),
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
                    'Enregistrer une présence',
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
              TextFormField(
                controller: _employeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ID Employé *',
                  border: OutlineInputBorder(),
                  helperText: 'Saisir l\'identifiant numérique de l\'employé',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  if (int.tryParse(v.trim()) == null) return 'Nombre entier';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_rounded),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        _dateCtrl.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                'Type de présence',
                style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700),
              ),
              const SizedBox(height: AppSizes.xs),
              Wrap(
                spacing: AppSizes.xs,
                children: _types.map((t) {
                  final (label, value) = t;
                  final sel = _typePresence == value;
                  return GestureDetector(
                    onTap: () => setState(() => _typePresence = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.xs),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.gray100,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(
                            color: sel
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.gray200),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                            fontSize: AppSizes.fontXs,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? AppColors.primary
                                : AppColors.gray500),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _obsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observations',
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

// ─── Formulaire congé ─────────────────────────────────────────────────────────

class _AddCongeSheet extends ConsumerStatefulWidget {
  const _AddCongeSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  ConsumerState<_AddCongeSheet> createState() => _AddCongeSheetState();
}

class _AddCongeSheetState extends ConsumerState<_AddCongeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _employeCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();
  final _debutCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  String _typeConge = 'conge_annuel';
  bool _isSaving = false;

  static const _types = [
    ('Congé annuel', 'conge_annuel'),
    ('Maladie', 'maladie'),
    ('Maternité', 'maternite'),
    ('Sans solde', 'sans_solde'),
    ('Autre', 'autre'),
  ];

  @override
  void dispose() {
    _employeCtrl.dispose();
    _motifCtrl.dispose();
    _debutCtrl.dispose();
    _finCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) ctrl.text = _fmtDate(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(congesProvider.notifier).create({
        'employe': int.parse(_employeCtrl.text.trim()),
        'type_conge': _typeConge,
        'date_debut': _debutCtrl.text,
        'date_fin': _finCtrl.text,
        if (_motifCtrl.text.isNotEmpty) 'motif': _motifCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de congé soumise'),
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
                    'Demande de congé',
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
              TextFormField(
                controller: _employeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ID Employé *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  if (int.tryParse(v.trim()) == null) return 'Nombre entier';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                'Type de congé',
                style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700),
              ),
              const SizedBox(height: AppSizes.xs),
              Wrap(
                spacing: AppSizes.xs,
                runSpacing: AppSizes.xs,
                children: _types.map((t) {
                  final (label, value) = t;
                  final sel = _typeConge == value;
                  return GestureDetector(
                    onTap: () => setState(() => _typeConge = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.xs),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.gray100,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(
                            color: sel
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.gray200),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                            fontSize: AppSizes.fontXs,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? AppColors.primary
                                : AppColors.gray500),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _debutCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Début *',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18),
                          onPressed: () => _pickDate(_debutCtrl),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _finCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Fin *',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18),
                          onPressed: () => _pickDate(_finCtrl),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _motifCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motif',
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
                      : const Text('Soumettre la demande'),
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
