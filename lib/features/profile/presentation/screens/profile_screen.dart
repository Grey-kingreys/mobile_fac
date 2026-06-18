import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/router/app_routes.dart';
import 'package:djoulagest_mobile/core/utils/validators.dart';
import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';
import 'package:djoulagest_mobile/shared/widgets/app_button.dart';
import 'package:djoulagest_mobile/shared/widgets/app_snackbar.dart';
import 'package:djoulagest_mobile/shared/widgets/app_text_field.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(effectiveUserProvider);

    return AppScaffold(
      title: 'Mon profil',
      showBottomNav: true,
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UserCard(user: user),
                  const SizedBox(height: AppSizes.md),
                  const _ChangePasswordCard(),
                  const SizedBox(height: AppSizes.md),
                  _TwoFactorCard(user: user),
                  const SizedBox(height: AppSizes.md),
                  _DangerZone(ref: ref),
                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
    );
  }
}

// ─── Carte utilisateur (style front_fac) ────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final UserEntity user;

  static const _kBanner = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.secondary],
  );

  @override
  Widget build(BuildContext context) {
    final roleColor = roleColors[user.role] ?? AppColors.primary;
    final roleLabel = roleLabels[user.role] ?? user.role;
    const avatarSize = 80.0;
    const bannerH = 96.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bandeau gradient + avatar (overlap identique au web) ─────────
          SizedBox(
            height: bannerH + avatarSize / 2,
            child: Stack(
              children: [
                // Bandeau bleu→vert
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: bannerH,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(gradient: _kBanner),
                  ),
                ),
                // Avatar chevauchant le bas du bandeau
                Positioned(
                  bottom: 0,
                  left: AppSizes.lg,
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryLight, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: user.avatarUrl != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd - 4),
                            child: Image.network(user.avatarUrl!,
                                fit: BoxFit.cover),
                          )
                        : Center(
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                              ),
                            ),
                          ),
                  ),
                ),
                // Nom + badge rôle à droite de l'avatar (alignés au bas)
                Positioned(
                  bottom: 4,
                  left: AppSizes.lg + avatarSize + AppSizes.md,
                  right: AppSizes.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.fullName.isEmpty ? user.email : user.fullName,
                        style: const TextStyle(
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          border: Border.all(
                              color: roleColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: roleColor,
                            fontSize: AppSizes.fontXs,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Infos utilisateur ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.lg,
            ),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.email_outlined,
                  iconBg: AppColors.primaryLightBg,
                  iconColor: AppColors.primary,
                  label: 'Email',
                  value: user.email,
                ),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.sm),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    iconBg: AppColors.secondaryLightBg,
                    iconColor: AppColors.secondary,
                    label: 'Téléphone',
                    value: user.phone!,
                  ),
                ],
                if (user.companyName != null) ...[
                  const SizedBox(height: AppSizes.sm),
                  _InfoTile(
                    icon: Icons.business_outlined,
                    iconBg: AppColors.primaryLightBg,
                    iconColor: AppColors.primary,
                    label: 'Entreprise',
                    value: user.companyName!,
                  ),
                ],
                if (user.depotName != null) ...[
                  const SizedBox(height: AppSizes.sm),
                  _InfoTile(
                    icon: Icons.warehouse_outlined,
                    iconBg: AppColors.accentLightBg,
                    iconColor: AppColors.accent,
                    label: 'Dépôt',
                    value: user.depotName!,
                  ),
                ],
                const SizedBox(height: AppSizes.sm),
                _InfoTile(
                  icon: user.isActive
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  iconBg: user.isActive
                      ? AppColors.secondaryLightBg
                      : AppColors.dangerLightBg,
                  iconColor:
                      user.isActive ? AppColors.secondary : AppColors.danger,
                  label: 'Statut',
                  value: user.isActive ? 'Actif' : 'Inactif',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray400,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Changement de mot de passe ─────────────────────────────────────────────

class _ChangePasswordCard extends ConsumerStatefulWidget {
  const _ChangePasswordCard();

  @override
  ConsumerState<_ChangePasswordCard> createState() =>
      _ChangePasswordCardState();
}

class _ChangePasswordCardState extends ConsumerState<_ChangePasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _expanded = false;
  bool _loading = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final err = await ref.read(profileProvider.notifier).changePassword(
          currentPassword: _oldCtrl.text,
          newPassword: _newCtrl.text,
          newPasswordConfirm: _confirmCtrl.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      _oldCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      setState(() => _expanded = false);
      AppSnackbar.success(context, 'Mot de passe modifié avec succès.');
    } else {
      AppSnackbar.error(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: const BorderSide(color: AppColors.gray100),
      ),
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: AppColors.primary, size: 18),
            ),
            title: const Text(
              'Changer le mot de passe',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppSizes.fontSm,
                color: AppColors.gray900,
              ),
            ),
            trailing: Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.gray400,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _oldCtrl,
                      label: 'Mot de passe actuel',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureOld,
                      enabled: !_loading,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Requis'
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureOld
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: AppSizes.iconMd,
                          color: AppColors.gray400,
                        ),
                        onPressed: () =>
                            setState(() => _obscureOld = !_obscureOld),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    AppTextField(
                      controller: _newCtrl,
                      label: 'Nouveau mot de passe',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureNew,
                      enabled: !_loading,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: AppSizes.iconMd,
                          color: AppColors.gray400,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    AppTextField(
                      controller: _confirmCtrl,
                      label: 'Confirmer le nouveau mot de passe',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirm,
                      enabled: !_loading,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          AppValidators.confirmPassword(v, _newCtrl.text),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: AppSizes.iconMd,
                          color: AppColors.gray400,
                        ),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    AppButton(
                      label: 'Enregistrer',
                      onPressed: _loading ? null : _submit,
                      isLoading: _loading,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Carte 2FA ───────────────────────────────────────────────────────────────

class _TwoFactorCard extends ConsumerStatefulWidget {
  const _TwoFactorCard({required this.user});
  final UserEntity user;

  @override
  ConsumerState<_TwoFactorCard> createState() => _TwoFactorCardState();
}

class _TwoFactorCardState extends ConsumerState<_TwoFactorCard> {
  bool _loadingDisable = false;

  String get _methodLabel {
    return widget.user.twoFactorMethod == 'totp' ? 'Application Authy' : 'Code par email';
  }

  Future<void> _disable() async {
    final passwordCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver la 2FA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez votre mot de passe pour confirmer la désactivation de la double authentification.',
              style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.gray600),
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Désactiver', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loadingDisable = true);
    final error = await ref
        .read(authProvider.notifier)
        .disable2fa(passwordCtrl.text);
    passwordCtrl.dispose();
    if (!mounted) return;
    setState(() => _loadingDisable = false);

    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.success(context, '2FA désactivée.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.user.twoFactorEnabled;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(
          color: enabled
              ? AppColors.secondary.withValues(alpha: 0.3)
              : AppColors.gray100,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppColors.secondary.withValues(alpha: 0.1)
                        : AppColors.gray100,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: enabled ? AppColors.secondary : AppColors.gray400,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Double authentification (2FA)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppSizes.fontSm,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        enabled ? 'Activée — $_methodLabel' : 'Désactivée',
                        style: TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: enabled ? AppColors.secondary : AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppColors.secondary.withValues(alpha: 0.1)
                        : AppColors.gray100,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    enabled ? 'Activée' : 'Désactivée',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppColors.secondary : AppColors.gray500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            if (!enabled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.twoFactorSetup),
                  icon: const Icon(Icons.add_moderator_outlined, size: 16),
                  label: const Text('Activer la 2FA'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.twoFactorSetup),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Changer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.gray200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loadingDisable ? null : _disable,
                      icon: _loadingDisable
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.no_encryption_outlined, size: 16),
                      label: const Text('Désactiver'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Zone de déconnexion ────────────────────────────────────────────────────

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      color: Colors.white,
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: const Icon(Icons.logout_rounded,
              color: AppColors.danger, size: 18),
        ),
        title: const Text(
          'Déconnexion',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.fontSm,
            color: AppColors.danger,
          ),
        ),
        subtitle: const Text(
          'Quitter votre session en cours',
          style: TextStyle(fontSize: AppSizes.fontXs, color: AppColors.gray400),
        ),
        onTap: () => ref.read(authProvider.notifier).logout(),
      ),
    );
  }
}
