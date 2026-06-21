import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/errors/app_exception.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/hr/domain/entities/attendance_entity.dart';
import 'package:djoulagest_mobile/features/hr/presentation/providers/hr_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

String _apiError(dynamic e) {
  if (e is DioException && e.error is AppException) {
    final ex = e.error as AppException;
    if (ex is ValidationException && ex.fieldErrors.isNotEmpty) {
      final entry = ex.fieldErrors.entries.first;
      return '${entry.key} : ${entry.value.first}';
    }
    return ex.message;
  }
  return e.toString();
}

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

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
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (_, __) {
          // Présence = self-service (carte de pointage géolocalisée) → aucun FAB.
          // Seul l'onglet Congés a un bouton « Demander un congé ».
          if (_tabs.index != 1) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _showAddCongeSheet,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Congé'),
          );
        },
      ),
      // ⚠️ On N'UTILISE PAS `TabBarView` : son `PageView`/viewport horizontal
      // pouvait recevoir une largeur NON BORNÉE (infinie) lors de certaines passes
      // de layout (transition de route / overlay) → les pages (Row avec Expanded,
      // ListView…) plantaient avec « incoming width constraints are unbounded »
      // → écran blanc + ANR. `IndexedStack` passe directement les contraintes
      // bornées de la route à la page active, sans viewport horizontal.
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
            child: AnimatedBuilder(
              animation: _tabs,
              builder: (_, __) => IndexedStack(
                index: _tabs.index,
                children: [
                  _PresencesTab(canViewRecap: _canManageConge.contains(role)),
                  _CongesTab(canManage: _canManageConge.contains(role)),
                ],
              ),
            ),
          ),
        ],
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
  const _PresencesTab({required this.canViewRecap});
  final bool canViewRecap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const _PointageCard(),
        // La liste complète des présences est réservée aux managers (RH_READ backend).
        if (canViewRecap) ...[
          const _RecapBanner(),
          Expanded(child: _buildList(context, ref, ref.watch(presencesProvider))),
        ] else
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.xl),
                child: Text(
                  'Pointez votre présence ci-dessus.\n'
                  'Vos demandes de congé sont dans l\'onglet Congés.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.gray500, fontSize: AppSizes.fontSm),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, AsyncValue presencesAsync) {
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

// ─── Récap du jour : présents / absents (admin & superviseur) ──────────────────

class _RecapBanner extends ConsumerStatefulWidget {
  const _RecapBanner();

  @override
  ConsumerState<_RecapBanner> createState() => _RecapBannerState();
}

class _RecapBannerState extends ConsumerState<_RecapBanner> {
  bool _showAbsents = false;

  @override
  Widget build(BuildContext context) {
    final recap = ref.watch(presenceRecapProvider).valueOrNull;
    if (recap == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.paddingPage, 0, AppSizes.paddingPage, AppSizes.xs),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _stat(recap.nbPresents.toString(), 'Présents', AppColors.secondary),
              _divider(),
              _stat(recap.nbAbsents.toString(), 'Absents', AppColors.danger),
              _divider(),
              _stat(recap.effectif.toString(), 'Effectif', AppColors.gray700),
              const Spacer(),
              if (recap.nbAbsents > 0)
                TextButton(
                  onPressed: () => setState(() => _showAbsents = !_showAbsents),
                  child: Text(_showAbsents ? 'Masquer' : 'Absents'),
                ),
            ],
          ),
          if (_showAbsents && recap.absents.isNotEmpty) ...[
            const Divider(height: AppSizes.lg),
            Wrap(
              spacing: AppSizes.xs,
              runSpacing: AppSizes.xs,
              children: recap.absents
                  .map((a) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          a.depotNom != null
                              ? '${a.employeNom} · ${a.depotNom}'
                              : a.employeNom,
                          style: const TextStyle(
                              fontSize: AppSizes.fontXs,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray700),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: AppSizes.fontXs, color: AppColors.gray500)),
        ],
      );

  Widget _divider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        color: AppColors.gray200,
      );
}

// ─── Carte self-service : pointer ma présence du jour ──────────────────────────

class _PointageCard extends ConsumerStatefulWidget {
  const _PointageCard();

  @override
  ConsumerState<_PointageCard> createState() => _PointageCardState();
}

class _PointageCardState extends ConsumerState<_PointageCard> {
  bool _pointing = false;

  Future<void> _pointer() async {
    setState(() => _pointing = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Activez la localisation de votre téléphone pour pointer.';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'Autorisez la géolocalisation pour pointer votre présence.';
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final presence = await ref
          .read(presencesProvider.notifier)
          .pointer(pos.latitude, pos.longitude);
      if (!mounted) return;
      final ok = presence.dansPerimetre != false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Présence enregistrée. Bonne journée !'
            : 'Pointage enregistré, mais hors de votre lieu de travail.'),
        backgroundColor: ok ? AppColors.secondary : AppColors.accent,
      ));
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? (e.error is AppException
              ? (e.error as AppException).message
              : 'Erreur lors du pointage.')
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _pointing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(myPresenceProvider);
    final status = statusAsync.valueOrNull;

    // La carte de pointage est affichée à TOUT membre de l'entreprise : le backend
    // crée automatiquement la fiche employé au 1ᵉʳ pointage (modèle « employés =
    // utilisateurs »). On ne masque donc plus la carte selon `aFicheEmploye` ;
    // seul `dejaPointe` bascule le bouton vers l'état « Présence enregistrée ».
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.paddingPage, AppSizes.md, AppSizes.paddingPage, AppSizes.xs),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: status != null && status.dejaPointe
          ? _buildPointe(status.presence)
          : _buildBouton(),
    );
  }

  Widget _buildBouton() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pointer ma présence',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              SizedBox(height: 2),
              Text(
                'Cochez votre présence depuis votre lieu de travail.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        ElevatedButton.icon(
          onPressed: _pointing ? null : _pointer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
          ),
          icon: _pointing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              : const Icon(Icons.check_circle_rounded, size: 18),
          label: Text(_pointing ? 'Localisation…' : 'Présent'),
        ),
      ],
    );
  }

  Widget _buildPointe(PresenceEntity? p) {
    final horsZone = p?.dansPerimetre == false;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Présence enregistrée',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                [
                  if (p?.heureArrivee != null) 'Pointé à ${p!.heureArrivee}',
                  if (horsZone)
                    'hors de votre site'
                  else if (p?.distanceM != null)
                    'à ${p!.distanceM} m de votre site',
                  'Rendez-vous demain.',
                ].join(' · '),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
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
              if (presence.dansPerimetre != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        presence.dansPerimetre!
                            ? Icons.place_rounded
                            : Icons.wrong_location_rounded,
                        size: 12,
                        color: presence.dansPerimetre!
                            ? AppColors.secondary
                            : AppColors.accent,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        presence.dansPerimetre! ? 'Sur site' : 'Hors site',
                        style: TextStyle(
                            fontSize: AppSizes.fontXs,
                            fontWeight: FontWeight.w600,
                            color: presence.dansPerimetre!
                                ? AppColors.secondary
                                : AppColors.accent),
                      ),
                    ],
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

Future<void> _showRefuseDialog(BuildContext context, WidgetRef ref, int congeId) async {
  final ctrl = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Refuser la demande'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("L'employé sera notifié du refus et de son motif.",
              style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.gray500)),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Motif du refus (recommandé)…',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger, foregroundColor: Colors.white),
          child: const Text('Refuser'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref.read(congesProvider.notifier).refuser(congeId, motif: ctrl.text.trim());
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
          if (conge.isRefuse &&
              conge.motifTraitement != null &&
              conge.motifTraitement!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.xs),
              child: Text(
                'Motif du refus : ${conge.motifTraitement!}',
                style: const TextStyle(
                    fontSize: AppSizes.fontXs, color: AppColors.danger),
              ),
            ),

          // Boutons approuver/refuser pour les gestionnaires
          if (canManage && conge.isEnAttente) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRefuseDialog(context, ref, conge.id),
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

// ─── Formulaire congé ─────────────────────────────────────────────────────────

class _AddCongeSheet extends ConsumerStatefulWidget {
  const _AddCongeSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  ConsumerState<_AddCongeSheet> createState() => _AddCongeSheetState();
}

class _AddCongeSheetState extends ConsumerState<_AddCongeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _motifCtrl = TextEditingController();
  final _debutCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  // ⚠️ Valeurs EXACTES des choix backend `Conge.TypeConge` (source de vérité) :
  // annuel / maladie / maternite / sans_solde / autre. Envoyer 'conge_annuel'
  // (ancienne valeur) provoquait un 400 « is not a valid choice ».
  String _typeConge = 'annuel';
  bool _isSaving = false;

  static const _types = [
    ('Congé annuel', 'annuel'),
    ('Maladie', 'maladie'),
    ('Maternité', 'maternite'),
    ('Sans solde', 'sans_solde'),
    ('Autre', 'autre'),
  ];

  @override
  void dispose() {
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
      // Demande self-service : l'employé est déduit du compte connecté côté backend.
      await ref.read(congesProvider.notifier).create({
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
            content: Text('Demande de congé envoyée'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_apiError(e)),
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
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.primary),
                    SizedBox(width: AppSizes.xs),
                    Expanded(
                      child: Text(
                        'Votre demande sera transmise à votre responsable pour validation. '
                        'Vous serez notifié de la décision.',
                        style: TextStyle(
                            fontSize: AppSizes.fontXs, color: AppColors.gray700),
                      ),
                    ),
                  ],
                ),
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
