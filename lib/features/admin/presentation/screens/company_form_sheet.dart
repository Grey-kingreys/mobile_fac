import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/features/admin/domain/entities/company_entity.dart';
import 'package:djoulagest_mobile/shared/widgets/app_button.dart';
import 'package:djoulagest_mobile/shared/widgets/app_text_field.dart';

// ─── Plans disponibles ───────────────────────────────────────────────────────

const _plans = [
  _Plan('free', 'Gratuit'),
  _Plan('starter', 'Starter'),
  _Plan('pro', 'Pro'),
  _Plan('enterprise', 'Enterprise'),
];

class _Plan {
  const _Plan(this.value, this.label);
  final String value;
  final String label;
}

// ─── Sheet ───────────────────────────────────────────────────────────────────

/// Bottom sheet de création / édition d'une entreprise.
///
/// [company] == null → mode création.
/// [onSave] reçoit (name, emailAdmin, plan) ; emailAdmin est null en édition.
class CompanyFormSheet extends StatefulWidget {
  const CompanyFormSheet({
    super.key,
    this.company,
    required this.onSave,
    this.isLoading = false,
  });

  final CompanyEntity? company;
  final Future<void> Function(String name, String? emailAdmin, String plan) onSave;
  final bool isLoading;

  static Future<void> show(
    BuildContext context, {
    CompanyEntity? company,
    required Future<void> Function(String name, String? emailAdmin, String plan) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (_) => CompanyFormSheet(company: company, onSave: onSave),
    );
  }

  @override
  State<CompanyFormSheet> createState() => _CompanyFormSheetState();
}

class _CompanyFormSheetState extends State<CompanyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late String _plan;
  bool _saving = false;

  bool get _isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.company?.name ?? '');
    _emailCtrl = TextEditingController();
    _plan = widget.company?.subscriptionPlan ?? 'free';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await widget.onSave(
      _nameCtrl.text.trim(),
      _isEditing ? null : _emailCtrl.text.trim(),
      _plan,
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: AppSizes.sm),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(Icons.business_rounded, color: AppColors.primary, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  _isEditing ? 'Modifier l\'entreprise' : 'Nouvelle entreprise',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: AppSizes.fontLg,
                    color: AppColors.gray900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.gray500),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: AppSizes.lg),

          // Formulaire
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md, 0, AppSizes.md, AppSizes.lg,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _nameCtrl,
                    label: 'Nom de l\'entreprise',
                    hint: 'Ex : Société Alpha',
                    prefixIcon: Icons.business_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Le nom est requis'
                        : null,
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: AppSizes.md),
                    AppTextField(
                      controller: _emailCtrl,
                      label: 'Email de l\'administrateur',
                      hint: 'admin@entreprise.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'L\'email est requis';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: AppSizes.md),

                  // Plan selector
                  const Text(
                    'Plan d\'abonnement',
                    style: TextStyle(
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Wrap(
                    spacing: AppSizes.xs,
                    children: _plans.map((p) {
                      final selected = _plan == p.value;
                      return ChoiceChip(
                        label: Text(p.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _plan = p.value),
                        selectedColor: AppColors.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primary : AppColors.gray600,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: AppSizes.fontSm,
                        ),
                        side: BorderSide(
                          color: selected ? AppColors.primary : AppColors.gray200,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: _isEditing ? 'Enregistrer' : 'Créer l\'entreprise',
                      onPressed: _saving ? null : _submit,
                      isLoading: _saving,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
