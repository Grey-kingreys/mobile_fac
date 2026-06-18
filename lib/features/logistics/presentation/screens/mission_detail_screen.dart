import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/core/services/gps_service.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/logistics/domain/entities/mission_entity.dart';
import 'package:djoulagest_mobile/features/logistics/presentation/providers/logistics_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

class MissionDetailScreen extends ConsumerWidget {
  const MissionDetailScreen({super.key, required this.missionId});
  final int missionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(missionDetailProvider(missionId));

    return AppScaffold(
      title: 'Détail mission',
      body: missionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: AppSizes.iconXxl, color: AppColors.gray300),
              const SizedBox(height: AppSizes.md),
              const Text('Mission introuvable',
                  style: TextStyle(color: AppColors.gray500)),
              const SizedBox(height: AppSizes.sm),
              TextButton(
                onPressed: () =>
                    ref.invalidate(missionDetailProvider(missionId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (mission) => _MissionDetailBody(mission: mission),
      ),
    );
  }
}

class _MissionDetailBody extends ConsumerStatefulWidget {
  const _MissionDetailBody({required this.mission});
  final MissionEntity mission;

  @override
  ConsumerState<_MissionDetailBody> createState() => _MissionDetailBodyState();
}

class _MissionDetailBodyState extends ConsumerState<_MissionDetailBody> {
  Timer? _gpsTimer;

  MissionEntity get mission => widget.mission;

  Color get _statutColor {
    // Slugs exacts retournés par Mission.Statut (back_fac/apps/logistique/models.py)
    return switch (mission.statut) {
      'planifiee' => AppColors.gray500,
      'chargement' => AppColors.accent,
      'en_transit' => AppColors.primary,
      'arrivee' => AppColors.secondary,
      'litige' => AppColors.danger,
      'terminee' => AppColors.secondary,
      'annulee' => AppColors.gray400,
      _ => AppColors.gray400,
    };
  }

  @override
  void initState() {
    super.initState();
    if (mission.isTransport) _startGpsTracking();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  void _startGpsTracking() {
    _sendPosition();
    _gpsTimer = Timer.periodic(const Duration(seconds: 60), (_) => _sendPosition());
  }

  Future<void> _sendPosition() async {
    final position = await GpsService.getCurrentPosition();
    if (position == null || !mounted) return;
    try {
      await ref.read(logisticsRepositoryProvider).sendPosition(
            mission.id,
            position.latitude,
            position.longitude,
            vitesseKmh: position.speed >= 0 ? position.speed * 3.6 : null,
          );
    } catch (_) {
      // Échec silencieux — on réessaiera au prochain tick
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(effectiveUserProvider);
    final role = user?.role ?? '';
    final isChauffeur = role == 'chauffeur';
    // Terminer uniquement si arrivée confirmée (pas en litige — le litige exige
    // une résolution via signature avant toute clôture, règle universelle §7).
    final canTerminer =
        (role == 'admin' || role == 'superviseur') && mission.isArrive;

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(missionDetailProvider(mission.id)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingPage, AppSizes.md, AppSizes.paddingPage, AppSizes.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── En-tête ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    mission.numero,
                    style: const TextStyle(
                      fontSize: AppSizes.fontXl,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm + 4, vertical: AppSizes.xs + 2),
                  decoration: BoxDecoration(
                    color: _statutColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                        color: _statutColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    mission.statutLabel,
                    style: TextStyle(
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.w700,
                      color: _statutColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // ─── Trajet ───────────────────────────────────────────────────
            _Section(
              title: 'Trajet',
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.radio_button_checked_rounded,
                    label: 'Départ',
                    value: mission.depotDepartNom ?? '—',
                    iconColor: AppColors.gray500,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Destination',
                    value: mission.depotArriveeNom ?? '—',
                    iconColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ─── Ressources ───────────────────────────────────────────────
            _Section(
              title: 'Ressources',
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.local_shipping_rounded,
                    label: 'Véhicule',
                    value: mission.vehiculeImmat ?? '—',
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'Chauffeur',
                    value: mission.chauffeurNom ?? '—',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ─── Dates ────────────────────────────────────────────────────
            _Section(
              title: 'Dates',
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.event_rounded,
                    label: 'Départ prévu',
                    value: mission.dateDepartPrevue != null
                        ? AppFormatters.dateTime(mission.dateDepartPrevue!)
                        : '—',
                  ),
                  if (mission.dateDepartReelle != null) ...[
                    const SizedBox(height: AppSizes.sm),
                    _InfoRow(
                      icon: Icons.play_circle_rounded,
                      label: 'Départ réel',
                      value: AppFormatters.dateTime(mission.dateDepartReelle!),
                      iconColor: AppColors.secondary,
                    ),
                  ],
                  if (mission.dateArriveeReelle != null) ...[
                    const SizedBox(height: AppSizes.sm),
                    _InfoRow(
                      icon: Icons.flag_rounded,
                      label: 'Arrivée',
                      value: AppFormatters.dateTime(mission.dateArriveeReelle!),
                      iconColor: AppColors.secondary,
                    ),
                  ],
                ],
              ),
            ),

            // ─── Lignes marchandises ──────────────────────────────────────
            if (mission.lignes.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              _Section(
                title: 'Marchandises (${mission.lignes.length})',
                child: Column(
                  children: mission.lignes.map((l) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.xs),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_rounded,
                              size: AppSizes.iconSm, color: AppColors.gray400),
                          const SizedBox(width: AppSizes.xs),
                          Expanded(
                            child: Text(
                              l.produitNom,
                              style: const TextStyle(
                                  fontSize: AppSizes.fontSm,
                                  color: AppColors.gray700),
                            ),
                          ),
                          Text(
                            AppFormatters.number(l.quantite, decimals: 0),
                            style: const TextStyle(
                              fontSize: AppSizes.fontSm,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // ─── Notes ────────────────────────────────────────────────────
            if (mission.notes != null && mission.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              _Section(
                title: 'Notes',
                child: Text(
                  mission.notes!,
                  style: const TextStyle(
                      fontSize: AppSizes.fontSm, color: AppColors.gray600),
                ),
              ),
            ],

            // ─── Motif litige ─────────────────────────────────────────────
            if (mission.isLitige &&
                mission.motifLitige != null &&
                mission.motifLitige!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.danger, size: AppSizes.iconSm),
                        SizedBox(width: AppSizes.xs),
                        Text('Litige',
                            style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(mission.motifLitige!,
                        style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: AppSizes.fontSm)),
                  ],
                ),
              ),
            ],

            // ─── Actions chauffeur ────────────────────────────────────────
            if (isChauffeur) ...[
              const SizedBox(height: AppSizes.lg),
              _ActionButtons(mission: mission),
            ],

            // ─── Terminer la mission (admin / superviseur) ────────────────
            if (canTerminer) ...[
              const SizedBox(height: AppSizes.lg),
              _TerminerButton(mission: mission),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Boutons d'action chauffeur ───────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.mission});
  final MissionEntity mission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? action;
    String? label;
    Color? color;

    // Bouton "Signaler l'arrivée" → ouvre l'écran de signature
    if (mission.isTransport) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () =>
              context.push(AppRoutes.signaturePath(mission.id)),
          icon: const Icon(Icons.draw_rounded),
          label: const Text('Signaler l\'arrivée'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
          ),
        ),
      );
    }

    if (mission.isPlanifiee) {
      action = 'chargement';
      label = 'Démarrer le chargement';
      color = AppColors.accent;
    } else if (mission.isChargement) {
      action = 'transit';
      label = 'Partir en transit';
      color = AppColors.primary;
    }

    if (action == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Confirmation'),
              content: Text('Confirmer : $label ?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirmer')),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            await ref
                .read(missionsProvider.notifier)
                .updateStatus(mission.id, action!);
            ref.invalidate(missionDetailProvider(mission.id));
          }
        },
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(label!),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
      ),
    );
  }
}

// ─── Bouton Terminer (admin / superviseur) ────────────────────────────────────

class _TerminerButton extends ConsumerWidget {
  const _TerminerButton({required this.mission});
  final MissionEntity mission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Terminer la mission'),
              content: const Text(
                  'Confirmer la clôture définitive de cette mission ?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Terminer')),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            await ref
                .read(missionsProvider.notifier)
                .updateStatus(mission.id, 'terminer');
            ref.invalidate(missionDetailProvider(mission.id));
          }
        },
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text('Terminer la mission'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
      ),
    );
  }
}

// ─── Widgets helper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w700,
              color: AppColors.gray400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.gray500,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: iconColor),
        const SizedBox(width: AppSizes.xs),
        Text('$label : ',
            style: const TextStyle(
                fontSize: AppSizes.fontSm, color: AppColors.gray400)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
