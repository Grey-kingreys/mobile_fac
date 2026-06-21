import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/errors/app_exception.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
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

// ─── Entity inline ────────────────────────────────────────────────────────────

class _UniteItem {
  const _UniteItem({required this.id, required this.name, required this.symbole});
  final int id;
  final String name;
  final String symbole;

  static _UniteItem fromJson(Map<String, dynamic> j) => _UniteItem(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        symbole: j['symbole'] as String? ?? '',
      );
}

// ─── State ────────────────────────────────────────────────────────────────────

class _UnitesState {
  const _UnitesState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
  });

  final List<_UniteItem> items;
  final int total;
  final int page;
  final bool isLoadingMore;

  bool get hasMore => items.length < total;

  _UnitesState copyWith({
    List<_UniteItem>? items,
    int? total,
    int? page,
    bool? isLoadingMore,
  }) =>
      _UnitesState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class _UnitesNotifier extends AsyncNotifier<_UnitesState> {
  static const _pageSize = 25;

  @override
  Future<_UnitesState> build() => _load(page: 1);

  Future<_UnitesState> _load({required int page}) async {
    final api = ref.read(apiClientProvider);
    final resp = await api.get<Map<String, dynamic>>(
      '/unites/',
      queryParameters: {'page': '$page', 'page_size': '$_pageSize'},
    );
    final data = resp.data ?? {};
    final results = _list(data).map(_UniteItem.fromJson).toList();
    final prev =
        page > 1 ? (state.valueOrNull?.items ?? []) : <_UniteItem>[];
    return _UnitesState(
      items: [...prev, ...results],
      total: data['count'] as int? ?? 0,
      page: page,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get<Map<String, dynamic>>(
        '/unites/',
        queryParameters: {
          'page': '${current.page + 1}',
          'page_size': '$_pageSize',
        },
      );
      final data = resp.data ?? {};
      final results = _list(data).map(_UniteItem.fromJson).toList();
      state = AsyncData(current.copyWith(
        items: [...current.items, ...results],
        total: data['count'] as int? ?? 0,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> create(Map<String, dynamic> body) async {
    final api = ref.read(apiClientProvider);
    await api.post<Map<String, dynamic>>('/unites/', data: body);
    await refresh();
  }

  Future<void> updateUnite(int id, Map<String, dynamic> body) async {
    final api = ref.read(apiClientProvider);
    await api.patch<Map<String, dynamic>>('/unites/$id/', data: body);
    await refresh();
  }

  Future<void> deleteUnite(int id) async {
    final api = ref.read(apiClientProvider);
    await api.delete<void>('/unites/$id/');
    await refresh();
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic>? data) {
    if (data == null) return [];
    final r = data['results'];
    if (r is List) return r.cast<Map<String, dynamic>>();
    return [];
  }
}

final _unitesProvider =
    AsyncNotifierProvider<_UnitesNotifier, _UnitesState>(_UnitesNotifier.new);

// ─── Écran ────────────────────────────────────────────────────────────────────

class UnitesScreen extends ConsumerStatefulWidget {
  const UnitesScreen({super.key});

  @override
  ConsumerState<UnitesScreen> createState() => _UnitesScreenState();
}

class _UnitesScreenState extends ConsumerState<UnitesScreen> {
  late final ScrollController _scrollController;

  static const _canEdit = ['admin', 'gestionnaire_stock'];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          ref.read(_unitesProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      builder: (_) => _UniteFormSheet(
        onSaved: () => ref.read(_unitesProvider.notifier).refresh(),
      ),
    );
  }

  void _showEditSheet(_UniteItem unite) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _UniteFormSheet(
        unite: unite,
        onSaved: () => ref.read(_unitesProvider.notifier).refresh(),
        onDeleted: () => ref.read(_unitesProvider.notifier).refresh(),
      ),
    );
  }

  void _showDetailSheet(_UniteItem u) {
    final canEdit = _canEdit.contains(ref.read(effectiveRoleProvider));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _UniteDetailSheet(
        unite: u,
        canEdit: canEdit,
        onEdit: () {
          Navigator.of(context).pop();
          _showEditSheet(u);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(effectiveRoleProvider);
    final unitesAsync = ref.watch(_unitesProvider);
    final canEdit = _canEdit.contains(role);

    return AppScaffold(
      title: 'Unités de mesure',
      showBottomNav: true,
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: _showCreateSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter'),
            )
          : null,
      body: unitesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: AppSizes.iconXxl, color: AppColors.gray300),
              const SizedBox(height: AppSizes.md),
              const Text('Impossible de charger les unités',
                  style: TextStyle(color: AppColors.gray500)),
              const SizedBox(height: AppSizes.sm),
              TextButton(
                onPressed: () =>
                    ref.read(_unitesProvider.notifier).refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (s) {
          if (s.items.isEmpty) {
            return const Center(
              child: Text('Aucune unité enregistrée',
                  style: TextStyle(color: AppColors.gray500)),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(_unitesProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(AppSizes.paddingPage,
                  AppSizes.md, AppSizes.paddingPage, AppSizes.xxl),
              itemCount: s.items.length + (s.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSizes.xs),
              itemBuilder: (_, i) {
                if (i == s.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final u = s.items[i];
                return GestureDetector(
                  onTap: () => _showDetailSheet(u),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.gray100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Center(
                            child: Text(
                              u.symbole.isNotEmpty ? u.symbole : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            '${u.name} — ${u.symbole}',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSm,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.gray300, size: AppSizes.iconMd),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Formulaire création / édition ────────────────────────────────────────────

class _UniteFormSheet extends ConsumerStatefulWidget {
  const _UniteFormSheet({
    this.unite,
    required this.onSaved,
    this.onDeleted,
  });

  final _UniteItem? unite;
  final VoidCallback onSaved;
  final VoidCallback? onDeleted;

  @override
  ConsumerState<_UniteFormSheet> createState() => _UniteFormSheetState();
}

class _UniteFormSheetState extends ConsumerState<_UniteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _symboleCtrl;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEdit => widget.unite != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.unite?.name ?? '');
    _symboleCtrl = TextEditingController(text: widget.unite?.symbole ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _symboleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'symbole': _symboleCtrl.text.trim(),
      };
      if (_isEdit) {
        await ref
            .read(_unitesProvider.notifier)
            .updateUnite(widget.unite!.id, body);
      } else {
        await ref.read(_unitesProvider.notifier).create(body);
      }
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Unité mise à jour' : 'Unité créée'),
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'unité ?'),
        content:
            Text('Voulez-vous vraiment supprimer "${widget.unite!.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isDeleting = true);
    try {
      await ref
          .read(_unitesProvider.notifier)
          .deleteUnite(widget.unite!.id);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDeleted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unité supprimée'),
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
      if (mounted) setState(() => _isDeleting = false);
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
                  Text(
                    _isEdit ? 'Modifier l\'unité' : 'Nouvelle unité',
                    style: const TextStyle(
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
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _symboleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Symbole *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
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
                      : Text(_isEdit ? 'Enregistrer' : 'Créer'),
                ),
              ),
              if (_isEdit) ...[
                const SizedBox(height: AppSizes.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isDeleting ? null : _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSizes.md),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd)),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.danger),
                          )
                        : const Text('Supprimer'),
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Détail unité ─────────────────────────────────────────────────────────────

class _UniteDetailSheet extends StatelessWidget {
  const _UniteDetailSheet({
    required this.unite,
    required this.canEdit,
    required this.onEdit,
  });

  final _UniteItem unite;
  final bool canEdit;
  final VoidCallback onEdit;

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: AppSizes.fontSm,
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: AppSizes.fontSm,
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Détail unité',
                    style: TextStyle(
                        fontSize: AppSizes.fontLg,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Center(
                  child: Text(
                    unite.symbole.isNotEmpty ? unite.symbole : '?',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            const Divider(),
            const SizedBox(height: AppSizes.xs),
            _infoRow('Nom', unite.name),
            _infoRow('Symbole', unite.symbole),
            if (canEdit) ...[
              const SizedBox(height: AppSizes.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.md),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }
}
