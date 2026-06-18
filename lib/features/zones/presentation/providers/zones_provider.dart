import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/zones/data/datasources/zones_remote_datasource.dart';
import 'package:djoulagest_mobile/features/zones/domain/entities/zone_entity.dart';

// ─── DI ─────────────────────────────────────────────────────────────────────

final _zonesDatasourceProvider = Provider<ZonesRemoteDatasource>(
  (ref) => ZonesRemoteDatasource(ref.read(apiClientProvider)),
);

// ─── State ───────────────────────────────────────────────────────────────────

class ZonesState {
  const ZonesState({
    this.zones = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.isLoadingMore = false,
  });

  final List<ZoneEntity> zones;
  final int total;
  final int page;
  final String search;
  final bool isLoadingMore;

  bool get hasMore => zones.length < total;

  ZonesState copyWith({
    List<ZoneEntity>? zones,
    int? total,
    int? page,
    String? search,
    bool? isLoadingMore,
  }) {
    return ZonesState(
      zones: zones ?? this.zones,
      total: total ?? this.total,
      page: page ?? this.page,
      search: search ?? this.search,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class ZonesNotifier extends AsyncNotifier<ZonesState> {
  static const _pageSize = 25;

  @override
  Future<ZonesState> build() => _fetch(page: 1, search: '');

  Future<ZonesState> _fetch({required int page, required String search}) async {
    final ds = ref.read(_zonesDatasourceProvider);
    final result = await ds.getZones(
      page: page,
      pageSize: _pageSize,
      search: search.isEmpty ? null : search,
    );
    final prev = page > 1 ? (state.valueOrNull?.zones ?? []) : <ZoneEntity>[];
    return ZonesState(
      zones: [...prev, ...result.zones],
      total: result.count,
      page: page,
      search: search,
    );
  }

  Future<void> refresh() async {
    final search = state.valueOrNull?.search ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, search: search));
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, search: query));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(_zonesDatasourceProvider).getZones(
            page: current.page + 1,
            pageSize: _pageSize,
            search: current.search.isEmpty ? null : current.search,
          );
      state = AsyncData(current.copyWith(
        zones: [...current.zones, ...result.zones],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<String?> create({
    required String name,
    required String code,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await ref.read(_zonesDatasourceProvider).createZone(
            name: name,
            code: code,
            latitude: latitude,
            longitude: longitude,
          );
      await refresh();
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> edit({
    required int id,
    required String name,
    required String code,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final updated = await ref.read(_zonesDatasourceProvider).updateZone(
            id: id,
            name: name,
            code: code,
            latitude: latitude,
            longitude: longitude,
          );
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          zones: current.zones.map((z) => z.id == id ? updated : z).toList(),
        ));
      }
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> delete(int id) async {
    try {
      await ref.read(_zonesDatasourceProvider).deleteZone(id);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          zones: current.zones.where((z) => z.id != id).toList(),
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

final zonesProvider =
    AsyncNotifierProvider<ZonesNotifier, ZonesState>(ZonesNotifier.new);
