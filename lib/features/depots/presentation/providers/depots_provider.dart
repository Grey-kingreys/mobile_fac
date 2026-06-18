import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/depots/data/datasources/depots_remote_datasource.dart';
import 'package:djoulagest_mobile/features/depots/domain/entities/depot_entity.dart';

// ─── DI ─────────────────────────────────────────────────────────────────────

final _depotsDatasourceProvider = Provider<DepotsRemoteDatasource>(
  (ref) => DepotsRemoteDatasource(ref.read(apiClientProvider)),
);

// ─── State ───────────────────────────────────────────────────────────────────

class DepotsState {
  const DepotsState({
    this.depots = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.filtreZoneId,
    this.isLoadingMore = false,
  });

  final List<DepotEntity> depots;
  final int total;
  final int page;
  final String search;
  final int? filtreZoneId;
  final bool isLoadingMore;

  bool get hasMore => depots.length < total;

  DepotsState copyWith({
    List<DepotEntity>? depots,
    int? total,
    int? page,
    String? search,
    int? filtreZoneId,
    bool clearFiltreZone = false,
    bool? isLoadingMore,
  }) {
    return DepotsState(
      depots: depots ?? this.depots,
      total: total ?? this.total,
      page: page ?? this.page,
      search: search ?? this.search,
      filtreZoneId: clearFiltreZone ? null : (filtreZoneId ?? this.filtreZoneId),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class DepotsNotifier extends AsyncNotifier<DepotsState> {
  static const _pageSize = 25;

  @override
  Future<DepotsState> build() => _fetch(page: 1, search: '', zoneId: null);

  Future<DepotsState> _fetch({
    required int page,
    required String search,
    required int? zoneId,
  }) async {
    final ds = ref.read(_depotsDatasourceProvider);
    final result = await ds.getDepots(
      page: page,
      pageSize: _pageSize,
      search: search.isEmpty ? null : search,
      zoneId: zoneId,
    );
    final prev = page > 1 ? (state.valueOrNull?.depots ?? []) : <DepotEntity>[];
    return DepotsState(
      depots: [...prev, ...result.depots],
      total: result.count,
      page: page,
      search: search,
      filtreZoneId: zoneId,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(page: 1, search: current?.search ?? '', zoneId: current?.filtreZoneId),
    );
  }

  Future<void> search(String query) async {
    final zoneId = state.valueOrNull?.filtreZoneId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, search: query, zoneId: zoneId));
  }

  Future<void> filtrerParZone(int? zoneId) async {
    final search = state.valueOrNull?.search ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, search: search, zoneId: zoneId));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(_depotsDatasourceProvider).getDepots(
            page: current.page + 1,
            pageSize: _pageSize,
            search: current.search.isEmpty ? null : current.search,
            zoneId: current.filtreZoneId,
          );
      state = AsyncData(current.copyWith(
        depots: [...current.depots, ...result.depots],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<String?> create({
    required String nom,
    required String code,
    required int zoneId,
    String? adresse,
  }) async {
    try {
      await ref.read(_depotsDatasourceProvider).createDepot(
            nom: nom,
            code: code,
            zoneId: zoneId,
            adresse: adresse,
          );
      await refresh();
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> edit({
    required int id,
    required String nom,
    required String code,
    required int zoneId,
    String? adresse,
  }) async {
    try {
      final updated = await ref.read(_depotsDatasourceProvider).updateDepot(
            id: id,
            nom: nom,
            code: code,
            zoneId: zoneId,
            adresse: adresse,
          );
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          depots: current.depots.map((d) => d.id == id ? updated : d).toList(),
        ));
      }
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> delete(int id) async {
    try {
      await ref.read(_depotsDatasourceProvider).deleteDepot(id);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          depots: current.depots.where((d) => d.id != id).toList(),
          total: current.total - 1,
        ));
      }
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}

final depotsProvider =
    AsyncNotifierProvider<DepotsNotifier, DepotsState>(DepotsNotifier.new);
