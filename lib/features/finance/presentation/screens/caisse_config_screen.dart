import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';

/// Configuration des durées de période des caisses (admin).
///
/// Hiérarchie : Caisse Entreprise (permanente) → Zone → Dépôt → Session caissier.
/// Règle métier : la durée d'un niveau inférieur doit être strictement plus
/// courte que celle du niveau supérieur (session < dépôt < zone).
class CaisseConfigScreen extends ConsumerStatefulWidget {
  const CaisseConfigScreen({super.key});

  @override
  ConsumerState<CaisseConfigScreen> createState() => _CaisseConfigScreenState();
}

class _CaisseConfigScreenState extends ConsumerState<CaisseConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sessionCtrl = TextEditingController();
  final _depotCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sessionCtrl.dispose();
    _depotCtrl.dispose();
    _zoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get<Map<String, dynamic>>(
        ApiEndpoints.configurationCaisses,
      );
      final d = res.data ?? {};
      _sessionCtrl.text = '${d['duree_session_jours'] ?? 1}';
      _depotCtrl.text = '${d['duree_caisse_depot_jours'] ?? 30}';
      _zoneCtrl.text = '${d['duree_caisse_zone_jours'] ?? 90}';
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final session = int.parse(_sessionCtrl.text.trim());
    final depot = int.parse(_depotCtrl.text.trim());
    final zone = int.parse(_zoneCtrl.text.trim());

    if (!(session < depot && depot < zone)) {
      AppSnackbar.error(
        context,
        'Les durées doivent être strictement croissantes : session < dépôt < zone.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch<Map<String, dynamic>>(
        ApiEndpoints.configurationCaisses,
        data: {
          'duree_session_jours': session,
          'duree_caisse_depot_jours': depot,
          'duree_caisse_zone_jours': zone,
        },
      );
      if (mounted) AppSnackbar.success(context, 'Configuration enregistrée');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _humanize(String raw) {
    final n = int.tryParse(raw.trim());
    if (n == null || n <= 0) return '';
    if (n % 365 == 0) return '≈ ${n ~/ 365} an(s)';
    if (n % 30 == 0) return '≈ ${n ~/ 30} mois';
    if (n % 7 == 0) return '≈ ${n ~/ 7} semaine(s)';
    return '$n jour(s)';
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(effectiveRoleProvider) == 'admin';

    return AppScaffold(
      title: 'Configuration des caisses',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSizes.paddingPage),
                    children: [
                      _InfoBanner(),
                      const SizedBox(height: AppSizes.lg),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _DureeField(
                              controller: _zoneCtrl,
                              label: 'Période caisse Zone',
                              icon: Icons.map_outlined,
                              color: const Color(0xFF7C3AED),
                              enabled: isAdmin && !_saving,
                              helper: _humanize(_zoneCtrl.text),
                              onChanged: () => setState(() {}),
                            ),
                            const _Connector(),
                            _DureeField(
                              controller: _depotCtrl,
                              label: 'Période caisse Dépôt',
                              icon: Icons.warehouse_outlined,
                              color: AppColors.primary,
                              enabled: isAdmin && !_saving,
                              helper: _humanize(_depotCtrl.text),
                              onChanged: () => setState(() {}),
                            ),
                            const _Connector(),
                            _DureeField(
                              controller: _sessionCtrl,
                              label: 'Période session Caissier',
                              icon: Icons.point_of_sale_outlined,
                              color: AppColors.accent,
                              enabled: isAdmin && !_saving,
                              helper: _humanize(_sessionCtrl.text),
                              onChanged: () => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: AppSizes.iconSm,
                                color: AppColors.secondary),
                            SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                'La caisse Entreprise est permanente : elle ne se ferme jamais et consolide les versements des caisses de zone.',
                                style: TextStyle(
                                    fontSize: AppSizes.fontXs,
                                    color: AppColors.gray700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                      if (isAdmin)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: const Text('Enregistrer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.md),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMd)),
                            ),
                          ),
                        )
                      else
                        const Text(
                          'Seul un administrateur peut modifier ces durées.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: AppSizes.fontXs,
                              color: AppColors.gray400),
                        ),
                    ],
                  ),
                ),
    );
  }
}

// ─── Sous-widgets ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: AppSizes.iconSm, color: AppColors.primary),
          SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'Définissez la durée de période de chaque niveau de caisse. '
              'Règle : la durée d\'un niveau inférieur doit être plus courte '
              'que celle du niveau supérieur (session < dépôt < zone).',
              style: TextStyle(
                  fontSize: AppSizes.fontXs, color: AppColors.gray700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 28),
      child: SizedBox(
        height: AppSizes.md,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.gray300, size: AppSizes.iconSm),
        ),
      ),
    );
  }
}

class _DureeField extends StatelessWidget {
  const _DureeField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.helper,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final String helper;
  final VoidCallback onChanged;

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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconMd),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900)),
                if (helper.isNotEmpty)
                  Text(helper,
                      style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray400)),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                isDense: true,
                suffixText: 'j',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return '> 0';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gray500)),
          ),
          const SizedBox(height: AppSizes.sm),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
