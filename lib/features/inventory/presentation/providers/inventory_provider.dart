import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:djoulagest_mobile/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:djoulagest_mobile/features/inventory/domain/entities/stock_entity.dart';
import 'package:djoulagest_mobile/features/inventory/domain/repositories/inventory_repository.dart';

// ─── DI ──────────────────────────────────────────────────────────────────────

final _inventoryDatasourceProvider = Provider<InventoryRemoteDatasource>(
  (ref) => InventoryRemoteDatasource(ref.read(apiClientProvider)),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepositoryImpl(ref.read(_inventoryDatasourceProvider)),
);

// ─── State ───────────────────────────────────────────────────────────────────

class InventoryState {
  const InventoryState({
    this.stocks = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.alertsOnly = false,
    this.isLoadingMore = false,
  });

  final List<StockEntity> stocks;
  final int total;
  final int page;
  final String search;
  final bool alertsOnly;
  final bool isLoadingMore;

  bool get hasMore => stocks.length < total;

  InventoryState copyWith({
    List<StockEntity>? stocks,
    int? total,
    int? page,
    String? search,
    bool? alertsOnly,
    bool? isLoadingMore,
  }) {
    return InventoryState(
      stocks: stocks ?? this.stocks,
      total: total ?? this.total,
      page: page ?? this.page,
      search: search ?? this.search,
      alertsOnly: alertsOnly ?? this.alertsOnly,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ─── Notifier principal (stocks) ─────────────────────────────────────────────

class InventoryNotifier extends AsyncNotifier<InventoryState> {
  static const _pageSize = 25;

  @override
  Future<InventoryState> build() => _load(page: 1, search: '', alertsOnly: false);

  Future<InventoryState> _load({
    required int page,
    required String search,
    required bool alertsOnly,
  }) async {
    final repo = ref.read(inventoryRepositoryProvider);
    final result = await repo.getStocks(
      page: page,
      pageSize: _pageSize,
      search: search.isEmpty ? null : search,
      alertsOnly: alertsOnly ? true : null,
    );
    final prev = page > 1 ? (state.valueOrNull?.stocks ?? []) : <StockEntity>[];
    return InventoryState(
      stocks: [...prev, ...result.stocks],
      total: result.count,
      page: page,
      search: search,
      alertsOnly: alertsOnly,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(
          page: 1,
          search: current?.search ?? '',
          alertsOnly: current?.alertsOnly ?? false,
        ));
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _load(page: 1, search: query, alertsOnly: false));
  }

  Future<void> filterAlerts(bool alertsOnly) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _load(page: 1, search: '', alertsOnly: alertsOnly));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(inventoryRepositoryProvider).getStocks(
            page: current.page + 1,
            pageSize: _pageSize,
            search: current.search.isEmpty ? null : current.search,
            alertsOnly: current.alertsOnly ? true : null,
          );
      state = AsyncData(current.copyWith(
        stocks: [...current.stocks, ...result.stocks],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, InventoryState>(
        InventoryNotifier.new);

// ─── Mouvements (auto-dispose) ────────────────────────────────────────────────

class MovementsState {
  const MovementsState({
    this.movements = const [],
    this.total = 0,
    this.page = 1,
    this.filter = '',
    this.isLoadingMore = false,
  });

  final List<MovementEntity> movements;
  final int total;
  final int page;
  final String filter;
  final bool isLoadingMore;

  bool get hasMore => movements.length < total;

  MovementsState copyWith({
    List<MovementEntity>? movements,
    int? total,
    int? page,
    String? filter,
    bool? isLoadingMore,
  }) {
    return MovementsState(
      movements: movements ?? this.movements,
      total: total ?? this.total,
      page: page ?? this.page,
      filter: filter ?? this.filter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class MovementsNotifier extends AsyncNotifier<MovementsState> {
  static const _pageSize = 25;

  @override
  Future<MovementsState> build() => _load(page: 1, filter: '');

  Future<MovementsState> _load({required int page, required String filter}) async {
    final repo = ref.read(inventoryRepositoryProvider);
    final result = await repo.getMovements(
      page: page,
      pageSize: _pageSize,
      typeMouvement: filter.isEmpty ? null : filter,
    );
    final prev = page > 1 ? (state.valueOrNull?.movements ?? []) : <MovementEntity>[];
    return MovementsState(
      movements: [...prev, ...result.movements],
      total: result.count,
      page: page,
      filter: filter,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _load(page: 1, filter: state.valueOrNull?.filter ?? ''));
  }

  Future<void> setFilter(String filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1, filter: filter));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(inventoryRepositoryProvider).getMovements(
            page: current.page + 1,
            pageSize: _pageSize,
            typeMouvement: current.filter.isEmpty ? null : current.filter,
          );
      state = AsyncData(current.copyWith(
        movements: [...current.movements, ...result.movements],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final movementsProvider =
    AsyncNotifierProvider<MovementsNotifier, MovementsState>(
        MovementsNotifier.new);

// ─── Transferts (FutureProvider simple) ──────────────────────────────────────

final transfertsProvider = FutureProvider.autoDispose
    .family<List<TransfertEntity>, String?>((ref, statut) async {
  final repo = ref.read(inventoryRepositoryProvider);
  final result = await repo.getTransferts(
    pageSize: 50,
    statut: statut,
  );
  return result.transferts;
});

// ─── Ajustements ──────────────────────────────────────────────────────────────

class AjustementsState {
  const AjustementsState({
    this.ajustements = const [],
    this.total = 0,
    this.page = 1,
    this.filter = '',
    this.isLoadingMore = false,
  });

  final List<AjustementEntity> ajustements;
  final int total;
  final int page;
  final String filter;
  final bool isLoadingMore;

  bool get hasMore => ajustements.length < total;

  AjustementsState copyWith({
    List<AjustementEntity>? ajustements,
    int? total,
    int? page,
    String? filter,
    bool? isLoadingMore,
  }) =>
      AjustementsState(
        ajustements: ajustements ?? this.ajustements,
        total: total ?? this.total,
        page: page ?? this.page,
        filter: filter ?? this.filter,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class AjustementsNotifier extends AsyncNotifier<AjustementsState> {
  static const _pageSize = 25;

  @override
  Future<AjustementsState> build() => _load(page: 1, filter: '');

  Future<AjustementsState> _load({required int page, required String filter}) async {
    final repo = ref.read(inventoryRepositoryProvider);
    final result = await repo.getAjustements(
      page: page,
      pageSize: _pageSize,
      statut: filter.isEmpty ? null : filter,
    );
    final prev = page > 1 ? (state.valueOrNull?.ajustements ?? []) : <AjustementEntity>[];
    return AjustementsState(
      ajustements: [...prev, ...result.ajustements],
      total: result.count,
      page: page,
      filter: filter,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _load(page: 1, filter: state.valueOrNull?.filter ?? ''));
  }

  Future<void> setFilter(String filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1, filter: filter));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(inventoryRepositoryProvider).getAjustements(
            page: current.page + 1,
            pageSize: _pageSize,
            statut: current.filter.isEmpty ? null : current.filter,
          );
      state = AsyncData(current.copyWith(
        ajustements: [...current.ajustements, ...result.ajustements],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Retourne null si succès, message d'erreur sinon.
  Future<String?> createAjustement({
    required int depot,
    required int produit,
    required num quantite,
    String? motif,
  }) async {
    try {
      await ref.read(inventoryRepositoryProvider).createAjustement(
            depot: depot,
            produit: produit,
            quantite: quantite,
            motif: motif,
          );
      await refresh();
      return null;
    } catch (e) {
      final s = e.toString();
      return s.startsWith('Exception: ') ? s.substring(11) : s;
    }
  }

  Future<String?> approuver(int id) async {
    try {
      await ref.read(inventoryRepositoryProvider).approuverAjustement(id);
      await refresh();
      return null;
    } catch (e) {
      final s = e.toString();
      return s.startsWith('Exception: ') ? s.substring(11) : s;
    }
  }

  Future<String?> refuser(int id, {String? motif}) async {
    try {
      await ref
          .read(inventoryRepositoryProvider)
          .refuserAjustement(id, motif: motif);
      await refresh();
      return null;
    } catch (e) {
      final s = e.toString();
      return s.startsWith('Exception: ') ? s.substring(11) : s;
    }
  }
}

final ajustementsProvider =
    AsyncNotifierProvider<AjustementsNotifier, AjustementsState>(
        AjustementsNotifier.new);
