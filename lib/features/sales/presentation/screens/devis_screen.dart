import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/errors/app_exception.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';
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

// ─── Entités inline ───────────────────────────────────────────────────────────

class _LigneDevis {
  final int id;
  final int produitId;
  final String produitNom;
  final String produitReference;
  final double quantite;
  final double prixUnitaireHt;
  final double montantHt;

  const _LigneDevis({
    required this.id,
    required this.produitId,
    required this.produitNom,
    required this.produitReference,
    required this.quantite,
    required this.prixUnitaireHt,
    required this.montantHt,
  });

  factory _LigneDevis.fromJson(Map<String, dynamic> j) => _LigneDevis(
        id: j['id'] as int,
        produitId: j['produit'] as int,
        produitNom: j['produit_nom'] as String? ?? '',
        produitReference: j['produit_reference'] as String? ?? '',
        quantite: double.tryParse(j['quantite'].toString()) ?? 0,
        prixUnitaireHt:
            double.tryParse(j['prix_unitaire_ht'].toString()) ?? 0,
        montantHt: double.tryParse(j['montant_ht'].toString()) ?? 0,
      );
}

class _Devis {
  final int id;
  final String numero;
  final String statut;
  final String statutLabel;
  final int? clientId;
  final String clientNom;
  final int depotId;
  final String? dateExpiration;
  final int nbLignes;
  final String createdAt;

  const _Devis({
    required this.id,
    required this.numero,
    required this.statut,
    required this.statutLabel,
    this.clientId,
    required this.clientNom,
    required this.depotId,
    this.dateExpiration,
    required this.nbLignes,
    required this.createdAt,
  });

  factory _Devis.fromJson(Map<String, dynamic> j) => _Devis(
        id: j['id'] as int,
        numero: j['numero'] as String? ?? '',
        statut: j['statut'] as String? ?? '',
        statutLabel: j['statut_label'] as String? ?? '',
        clientId: j['client'] as int?,
        clientNom: j['client_nom'] as String? ?? 'Anonyme',
        depotId: j['depot'] as int? ?? 0,
        dateExpiration: j['date_expiration'] as String?,
        nbLignes: j['nb_lignes'] as int? ?? 0,
        createdAt: j['created_at'] as String? ?? '',
      );

  bool get canConvertir => statut == 'accepte';
  bool get isExpired => statut == 'expire';
  bool get isConverti => statut == 'converti';
}

// ─── State ────────────────────────────────────────────────────────────────────

class _DevisState {
  final List<_Devis> items;
  final int total;
  final int page;
  final bool isLoadingMore;
  final String? statutFilter;

  const _DevisState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
    this.statutFilter,
  });

  _DevisState copyWith({
    List<_Devis>? items,
    int? total,
    int? page,
    bool? isLoadingMore,
    Object? statutFilter = _sentinel,
  }) =>
      _DevisState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        statutFilter: statutFilter == _sentinel
            ? this.statutFilter
            : statutFilter as String?,
      );
}

const _sentinel = Object();

// ─── Notifier ─────────────────────────────────────────────────────────────────

class _DevisNotifier extends AutoDisposeAsyncNotifier<_DevisState> {
  @override
  Future<_DevisState> build() async => _fetch(page: 1, statut: null);

  Future<_DevisState> _fetch({required int page, String? statut}) async {
    final api = ref.read(apiClientProvider);
    final params = <String, dynamic>{'page': page, 'page_size': 25};
    if (statut != null) params['statut'] = statut;
    final res = await api.get<Map<String, dynamic>>(
      ApiEndpoints.devis,
      queryParameters: params,
    );
    final data = res.data!;
    final results = (data['results'] as List)
        .map((e) => _Devis.fromJson(e as Map<String, dynamic>))
        .toList();
    return _DevisState(
      items: results,
      total: data['count'] as int? ?? results.length,
      page: page,
      statutFilter: statut,
    );
  }

  Future<void> refresh() async {
    final cur = state.valueOrNull;
    state = AsyncData(await _fetch(page: 1, statut: cur?.statutFilter));
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || cur.isLoadingMore) return;
    if (cur.items.length >= cur.total) return;
    state = AsyncData(cur.copyWith(isLoadingMore: true));
    try {
      final next = await _fetch(page: cur.page + 1, statut: cur.statutFilter);
      state = AsyncData(next.copyWith(
        items: [...cur.items, ...next.items],
        page: cur.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(cur.copyWith(isLoadingMore: false));
    }
  }

  Future<void> filterByStatut(String? statut) async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch(page: 1, statut: statut));
  }
}

final _devisProvider =
    AutoDisposeAsyncNotifierProvider<_DevisNotifier, _DevisState>(
  _DevisNotifier.new,
);

// ─── Couleurs par statut ──────────────────────────────────────────────────────

Color _statutColor(String statut) {
  switch (statut) {
    case 'brouillon':
      return AppColors.gray400;
    case 'envoye':
      return AppColors.primary;
    case 'accepte':
      return AppColors.secondary;
    case 'refuse':
      return AppColors.danger;
    case 'expire':
      return AppColors.accent;
    case 'converti':
      return const Color(0xFF7C3AED);
    default:
      return AppColors.gray400;
  }
}

// ─── Écran principal ──────────────────────────────────────────────────────────

class DevisScreen extends ConsumerStatefulWidget {
  const DevisScreen({super.key});

  @override
  ConsumerState<DevisScreen> createState() => _DevisScreenState();
}

class _DevisScreenState extends ConsumerState<DevisScreen> {
  late final ScrollController _scrollController;
  static const _canCreate = ['commercial', 'admin', 'superviseur'];

  static const _filters = [
    (null, 'Tous'),
    ('brouillon', 'Brouillon'),
    ('envoye', 'Envoyé'),
    ('accepte', 'Accepté'),
    ('refuse', 'Refusé'),
    ('expire', 'Expiré'),
    ('converti', 'Converti'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          ref.read(_devisProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showCreate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _CreateDevisSheet(
        onCreated: () => ref.read(_devisProvider.notifier).refresh(),
      ),
    );
  }

  void _showDetail(_Devis dv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _DevisDetailSheet(
        devis: dv,
        onConverted: () => ref.read(_devisProvider.notifier).refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devisAsync = ref.watch(_devisProvider);
    final role = ref.watch(effectiveRoleProvider);
    final canCreate = _canCreate.contains(role);

    return AppScaffold(
      title: 'Devis',
      showBottomNav: true,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _showCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau devis'),
            )
          : null,
      body: Column(
        children: [
          // ── Filtres statut ────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, AppSizes.sm,
                AppSizes.paddingPage, AppSizes.sm),
            child: devisAsync.maybeWhen(
              data: (state) => Row(
                children: _filters
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: AppSizes.xs),
                          child: _FilterChip(
                            label: f.$2,
                            active: state.statutFilter == f.$1,
                            color: f.$1 != null
                                ? _statutColor(f.$1!)
                                : AppColors.primary,
                            onTap: () => ref
                                .read(_devisProvider.notifier)
                                .filterByStatut(f.$1),
                          ),
                        ))
                    .toList(),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),

          // ── Liste ─────────────────────────────────────────────────────────
          Expanded(
            child: devisAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: AppSizes.iconXxl, color: AppColors.gray300),
                    const SizedBox(height: AppSizes.md),
                    const Text('Impossible de charger les devis',
                        style: TextStyle(color: AppColors.gray500)),
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: () =>
                          ref.read(_devisProvider.notifier).refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined,
                            size: AppSizes.iconXxl, color: AppColors.gray200),
                        SizedBox(height: AppSizes.md),
                        Text('Aucun devis trouvé',
                            style: TextStyle(color: AppColors.gray500)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(_devisProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingPage, 0,
                        AppSizes.paddingPage, AppSizes.xxl),
                    itemCount:
                        state.items.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.xs),
                    itemBuilder: (ctx, i) {
                      if (i == state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSizes.md),
                          child:
                              Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _DevisTile(
                        dv: state.items[i],
                        onTap: () => _showDetail(state.items[i]),
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
}

// ─── Chip filtre ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm + 4, vertical: AppSizes.xs + 2),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.12) : AppColors.gray100,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
              color: active ? c : AppColors.gray200,
              width: active ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? c : AppColors.gray500,
            fontSize: AppSizes.fontXs,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Tuile devis ──────────────────────────────────────────────────────────────

class _DevisTile extends StatelessWidget {
  const _DevisTile({required this.dv, required this.onTap});
  final _Devis dv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statutColor(dv.statut);
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Icône
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                dv.isConverti
                    ? Icons.check_circle_outline_rounded
                    : Icons.description_outlined,
                color: color,
                size: AppSizes.iconMd,
              ),
            ),
            const SizedBox(width: AppSizes.sm),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dv.numero,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.fontSm,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dv.clientNom,
                    style: const TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        AppFormatters.dateShort(
                            DateTime.tryParse(dv.createdAt) ??
                                DateTime.now()),
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray400,
                        ),
                      ),
                      if (dv.dateExpiration != null) ...[
                        const Text(' · exp. ',
                            style: TextStyle(
                                color: AppColors.gray300,
                                fontSize: AppSizes.fontXs)),
                        Text(
                          dv.dateExpiration!,
                          style: TextStyle(
                            fontSize: AppSizes.fontXs,
                            color: dv.isExpired
                                ? AppColors.danger
                                : AppColors.gray400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Badge statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    dv.statutLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dv.nbLignes} ligne${dv.nbLignes > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSizes.xs),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.gray300, size: AppSizes.iconSm),
          ],
        ),
      ),
    );
  }
}

// ─── Détail devis ─────────────────────────────────────────────────────────────

class _DevisDetailSheet extends ConsumerStatefulWidget {
  const _DevisDetailSheet({
    required this.devis,
    required this.onConverted,
  });
  final _Devis devis;
  final VoidCallback onConverted;

  @override
  ConsumerState<_DevisDetailSheet> createState() =>
      _DevisDetailSheetState();
}

class _DevisDetailSheetState extends ConsumerState<_DevisDetailSheet> {
  List<_LigneDevis> _lignes = [];
  bool _loading = true;
  bool _isConverting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get<Map<String, dynamic>>(
        ApiEndpoints.devisDetail(widget.devis.id),
      );
      final data = res.data!;
      final lignes = (data['lignes'] as List)
          .map((e) => _LigneDevis.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _lignes = lignes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _convertir() async {
    setState(() => _isConverting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.devisConvertir(widget.devis.id),
        data: {},
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onConverted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devis converti en commande'),
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
        setState(() => _isConverting = false);
      }
    }
  }

  double get _totalHt =>
      _lignes.fold(0.0, (sum, l) => sum + l.montantHt);

  @override
  Widget build(BuildContext context) {
    final dv = widget.devis;
    final color = _statutColor(dv.statut);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSizes.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingPage, AppSizes.md,
                AppSizes.paddingPage, AppSizes.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dv.numero,
                        style: const TextStyle(
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        dv.clientNom,
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    dv.statutLabel,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lignes
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppColors.danger)))
                    : ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.all(AppSizes.paddingPage),
                        children: [
                          ...(_lignes.map((l) => _LigneTile(ligne: l))),
                          const Divider(height: AppSizes.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total HT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppSizes.fontSm,
                                  color: AppColors.gray900,
                                ),
                              ),
                              Text(
                                AppFormatters.gnf(_totalHt),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppSizes.fontMd,
                                  color: AppColors.gray900,
                                ),
                              ),
                            ],
                          ),
                          if (dv.dateExpiration != null) ...[
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              'Expire le : ${dv.dateExpiration}',
                              style: TextStyle(
                                fontSize: AppSizes.fontXs,
                                color: dv.isExpired
                                    ? AppColors.danger
                                    : AppColors.gray400,
                              ),
                            ),
                          ],
                        ],
                      ),
          ),

          // Bouton convertir (statut accepté uniquement)
          if (dv.canConvertir)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingPage),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isConverting ? null : _convertir,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.md),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd)),
                    ),
                    icon: _isConverting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.shopping_cart_checkout_rounded),
                    label: const Text('Convertir en commande'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tuile ligne devis ────────────────────────────────────────────────────────

class _LigneTile extends StatelessWidget {
  const _LigneTile({required this.ligne});
  final _LigneDevis ligne;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ligne.produitNom,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  '${ligne.produitReference} · ${ligne.quantite} × ${AppFormatters.gnf(ligne.prixUnitaireHt)}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.gnf(ligne.montantHt),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppSizes.fontSm,
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulaire création devis ────────────────────────────────────────────────

class _LigneFormData {
  int? produitId;
  String produitNom = '';
  double quantite = 1;
  double prixUnitaireHt = 0;
}

class _CreateDevisSheet extends ConsumerStatefulWidget {
  const _CreateDevisSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateDevisSheet> createState() =>
      _CreateDevisSheetState();
}

class _CreateDevisSheetState extends ConsumerState<_CreateDevisSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _dateExpirationCtrl = TextEditingController();

  List<Map<String, dynamic>> _depots = [];
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _produits = [];
  int? _depotId;
  int? _clientId;
  bool _loadingDropdowns = true;
  bool _isSaving = false;

  final List<_LigneFormData> _lignes = [_LigneFormData()];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _dateExpirationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get<Map<String, dynamic>>('/depots/',
            queryParameters: {'page_size': 100}),
        api.get<Map<String, dynamic>>(ApiEndpoints.clients,
            queryParameters: {'page_size': 100}),
        api.get<Map<String, dynamic>>(ApiEndpoints.produits,
            queryParameters: {'page_size': 100}),
      ]);
      if (mounted) {
        setState(() {
          _depots = List<Map<String, dynamic>>.from(
              (results[0].data?['results'] ?? []) as List);
          _clients = List<Map<String, dynamic>>.from(
              (results[1].data?['results'] ?? []) as List);
          _produits = List<Map<String, dynamic>>.from(
              (results[2].data?['results'] ?? []) as List);

          final userDepotId =
              ref.read(authProvider).valueOrNull?.depotId;
          if (userDepotId != null &&
              _depots.any((d) => d['id'] == userDepotId)) {
            _depotId = userDepotId;
          }
          _loadingDropdowns = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDropdowns = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      _dateExpirationCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier que chaque ligne a un produit sélectionné
    for (final ligne in _lignes) {
      if (ligne.produitId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sélectionnez un produit pour chaque ligne'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.devis,
        data: {
          'depot': _depotId,
          if (_clientId != null) 'client': _clientId,
          if (_dateExpirationCtrl.text.isNotEmpty)
            'date_expiration': _dateExpirationCtrl.text,
          if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
          'lignes': _lignes
              .map((l) => {
                    'produit': l.produitId,
                    'quantite': l.quantite,
                    'prix_unitaire_ht': l.prixUnitaireHt,
                  })
              .toList(),
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devis créé avec succès'),
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
              // Header
              Row(
                children: [
                  const Text(
                    'Nouveau devis',
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

              if (_loadingDropdowns)
                const SizedBox(
                    height: 56,
                    child: Center(child: LinearProgressIndicator()))
              else ...[
                // ── Dépôt ─────────────────────────────────────────────────
                DropdownButtonFormField<int>(
                  initialValue: _depotId,
                  decoration: const InputDecoration(
                    labelText: 'Dépôt *',
                    border: OutlineInputBorder(),
                  ),
                  items: _depots
                      .map((d) => DropdownMenuItem<int>(
                            value: d['id'] as int,
                            child: Text('${d['name']} (${d['code']})'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _depotId = v),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                const SizedBox(height: AppSizes.sm),

                // ── Client (optionnel) ────────────────────────────────────
                DropdownButtonFormField<int>(
                  initialValue: _clientId,
                  decoration: const InputDecoration(
                    labelText: 'Client (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                        value: null, child: Text('Aucun (anonyme)')),
                    ..._clients.map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['nom_complet'] as String? ??
                              c['nom'] as String? ??
                              '—'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _clientId = v),
                ),
                const SizedBox(height: AppSizes.sm),

                // ── Date expiration ────────────────────────────────────────
                TextFormField(
                  controller: _dateExpirationCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Date d\'expiration (optionnel)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // ── Lignes ────────────────────────────────────────────────
                const Text(
                  'Lignes du devis *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppSizes.fontSm,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                ..._lignes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ligne = entry.value;
                  return _LigneFormRow(
                    index: i,
                    ligne: ligne,
                    produits: _produits,
                    canDelete: _lignes.length > 1,
                    onDelete: () => setState(() => _lignes.removeAt(i)),
                    onChanged: () => setState(() {}),
                  );
                }),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _lignes.add(_LigneFormData())),
                  icon: const Icon(Icons.add_rounded, size: AppSizes.iconSm),
                  label: const Text('Ajouter une ligne'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary),
                ),
                const SizedBox(height: AppSizes.sm),

                // ── Notes ─────────────────────────────────────────────────
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
              ],

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
                      : const Text('Créer le devis'),
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

// ─── Ligne de formulaire devis ────────────────────────────────────────────────

class _LigneFormRow extends StatefulWidget {
  const _LigneFormRow({
    required this.index,
    required this.ligne,
    required this.produits,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });
  final int index;
  final _LigneFormData ligne;
  final List<Map<String, dynamic>> produits;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  @override
  State<_LigneFormRow> createState() => _LigneFormRowState();
}

class _LigneFormRowState extends State<_LigneFormRow> {
  late final TextEditingController _qteCtrl;
  late final TextEditingController _prixCtrl;

  @override
  void initState() {
    super.initState();
    _qteCtrl = TextEditingController(
        text: widget.ligne.quantite == 1 ? '' : '${widget.ligne.quantite}');
    _prixCtrl = TextEditingController(
        text: widget.ligne.prixUnitaireHt == 0
            ? ''
            : '${widget.ligne.prixUnitaireHt}');
  }

  @override
  void dispose() {
    _qteCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.gray100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Ligne ${widget.index + 1}',
                style: const TextStyle(
                  fontSize: AppSizes.fontXs,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray500,
                ),
              ),
              const Spacer(),
              if (widget.canDelete)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.danger),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          // Produit
          DropdownButtonFormField<int>(
            initialValue: widget.ligne.produitId,
            decoration: const InputDecoration(
              labelText: 'Produit *',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              isDense: true,
            ),
            isExpanded: true,
            items: widget.produits
                .map((p) => DropdownMenuItem<int>(
                      value: p['id'] as int,
                      child: Text(
                        '${p['nom']} (${p['reference'] ?? '—'})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              widget.ligne.produitId = v;
              if (v != null) {
                final prod = widget.produits.firstWhere(
                    (p) => p['id'] == v,
                    orElse: () => {});
                if (prod.isNotEmpty) {
                  widget.ligne.prixUnitaireHt =
                      double.tryParse(prod['prix_vente'].toString()) ?? 0;
                  _prixCtrl.text = widget.ligne.prixUnitaireHt.toString();
                }
              }
              widget.onChanged();
            },
            validator: (v) => v == null ? 'Requis' : null,
          ),
          const SizedBox(height: AppSizes.xs),
          // Quantité + Prix
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qteCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Qté *',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    widget.ligne.quantite =
                        double.tryParse(v.replaceAll(',', '.')) ?? 1;
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) {
                      return 'Invalide';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _prixCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Prix unit. HT *',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    widget.ligne.prixUnitaireHt =
                        double.tryParse(v.replaceAll(',', '.')) ?? 0;
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) {
                      return 'Invalide';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
