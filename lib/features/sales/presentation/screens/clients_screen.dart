import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/sales/domain/entities/client_entity.dart';
import 'package:djoulagest_mobile/features/sales/presentation/providers/sales_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchCtrl = TextEditingController();

  static const _canCreate = ['commercial', 'caissier', 'admin', 'superviseur'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _CreateClientSheet(
        onCreated: () => ref.read(clientsProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final role = ref.watch(effectiveRoleProvider);
    final canCreate = _canCreate.contains(role);

    return AppScaffold(
      title: 'Clients',
      showBottomNav: true,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _showCreateSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Ajouter un client'),
            )
          : null,
      body: Column(
        children: [
          // ─── Recherche ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, AppSizes.md, AppSizes.paddingPage, AppSizes.sm),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(clientsProvider.notifier).search(v),
              decoration: InputDecoration(
                hintText: 'Rechercher un client…',
                hintStyle: const TextStyle(
                    color: AppColors.gray400, fontSize: AppSizes.fontSm),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.gray400, size: AppSizes.iconMd),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: AppSizes.iconSm),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(clientsProvider.notifier).search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(color: AppColors.gray200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(color: AppColors.gray200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ),

          // ─── Liste ────────────────────────────────────────────────────────
          Expanded(
            child: clientsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    const Text('Impossible de charger les clients',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(clientsProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.clients.isEmpty) {
                  return const Center(
                    child: Text('Aucun client trouvé',
                        style: TextStyle(color: AppColors.gray500)),
                  );
                }

                final controller = ScrollController();
                controller.addListener(() {
                  if (controller.position.pixels >=
                      controller.position.maxScrollExtent - 200) {
                    ref.read(clientsProvider.notifier).loadMore();
                  }
                });

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(clientsProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingPage, 0, AppSizes.paddingPage,
                        AppSizes.xxl),
                    itemCount: state.clients.length +
                        (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (ctx, i) {
                      if (i == state.clients.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child: Center(
                              child: CircularProgressIndicator()),
                        );
                      }
                      return _ClientTile(client: state.clients[i]);
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

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client});
  final ClientEntity client;

  String get _initials {
    final parts = client.nomComplet.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return client.nomComplet.isNotEmpty
        ? client.nomComplet.substring(0, 2).toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.fontSm,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.nomComplet,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      client.code,
                      style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.gray400,
                      ),
                    ),
                    if (client.telephone != null) ...[
                      const Text(' · ',
                          style: TextStyle(color: AppColors.gray300)),
                      Text(
                        client.telephone!,
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Points / crédit
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (client.pointsFidelite > 0)
                Text(
                  '${client.pointsFidelite.toInt()} pts',
                  style: const TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (client.hasCredit)
                Text(
                  AppFormatters.gnf(client.soldeCredit),
                  style: const TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Formulaire création client ───────────────────────────────────────────────

class _CreateClientSheet extends ConsumerStatefulWidget {
  const _CreateClientSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateClientSheet> createState() =>
      _CreateClientSheetState();
}

class _CreateClientSheetState extends ConsumerState<_CreateClientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.clients,
        data: {
          'code': _codeCtrl.text.trim(),
          'nom': _nomCtrl.text.trim(),
          if (_prenomCtrl.text.isNotEmpty) 'prenom': _prenomCtrl.text.trim(),
          if (_telCtrl.text.isNotEmpty) 'telephone': _telCtrl.text.trim(),
          if (_emailCtrl.text.isNotEmpty) 'email': _emailCtrl.text.trim(),
        },
      );
      await ref.read(clientsProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client créé avec succès'),
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
                    'Ajouter un client',
                    style: TextStyle(
                      fontSize: AppSizes.fontLg,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
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
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code *',
                  hintText: 'Ex : CLI-001',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _prenomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
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
                      : const Text('Créer le client'),
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
