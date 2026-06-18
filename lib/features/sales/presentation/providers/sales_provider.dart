import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/sales/data/datasources/sales_remote_datasource.dart';
import 'package:djoulagest_mobile/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:djoulagest_mobile/features/sales/domain/entities/client_entity.dart';
import 'package:djoulagest_mobile/features/sales/domain/entities/sale_entity.dart';
import 'package:djoulagest_mobile/features/sales/domain/repositories/sales_repository.dart';

// ─── DI ──────────────────────────────────────────────────────────────────────

final _salesDatasourceProvider = Provider<SalesRemoteDatasource>(
  (ref) => SalesRemoteDatasource(ref.read(apiClientProvider)),
);

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepositoryImpl(ref.read(_salesDatasourceProvider)),
);

// ─── Commandes (ventes) ───────────────────────────────────────────────────────

class SalesState {
  const SalesState({
    this.sales = const [],
    this.total = 0,
    this.page = 1,
    this.filter = '',
    this.isLoadingMore = false,
  });

  final List<SaleEntity> sales;
  final int total;
  final int page;
  final String filter;
  final bool isLoadingMore;

  bool get hasMore => sales.length < total;

  SalesState copyWith({
    List<SaleEntity>? sales,
    int? total,
    int? page,
    String? filter,
    bool? isLoadingMore,
  }) {
    return SalesState(
      sales: sales ?? this.sales,
      total: total ?? this.total,
      page: page ?? this.page,
      filter: filter ?? this.filter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SalesNotifier extends AsyncNotifier<SalesState> {
  static const _pageSize = 25;

  @override
  Future<SalesState> build() => _load(page: 1, filter: '');

  Future<SalesState> _load({required int page, required String filter}) async {
    final repo = ref.read(salesRepositoryProvider);
    final result = await repo.getSales(
      page: page,
      pageSize: _pageSize,
      statut: filter.isEmpty ? null : filter,
    );
    final prev = page > 1 ? (state.valueOrNull?.sales ?? []) : <SaleEntity>[];
    return SalesState(
      sales: [...prev, ...result.sales],
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
      final result = await ref.read(salesRepositoryProvider).getSales(
            page: current.page + 1,
            pageSize: _pageSize,
            statut: current.filter.isEmpty ? null : current.filter,
          );
      state = AsyncData(current.copyWith(
        sales: [...current.sales, ...result.sales],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<String?> annuler(int id) async {
    try {
      final updated = await ref.read(_salesDatasourceProvider).annulerCommande(id);
      final cur = state.valueOrNull;
      if (cur != null) {
        state = AsyncData(cur.copyWith(
          sales: cur.sales.map((s) => s.id == id ? updated : s).toList(),
        ));
      }
      return null;
    } catch (e) {
      final s = e.toString();
      return s.startsWith('Exception: ') ? s.substring(11) : s;
    }
  }

  Future<String?> payer({
    required int id,
    required num montant,
    required String mode,
    String? reference,
  }) async {
    try {
      final updated = await ref.read(_salesDatasourceProvider).payerCommande(
            id: id,
            montant: montant,
            mode: mode,
            reference: reference,
          );
      final cur = state.valueOrNull;
      if (cur != null) {
        state = AsyncData(cur.copyWith(
          sales: cur.sales.map((s) => s.id == id ? updated : s).toList(),
        ));
      }
      return null;
    } catch (e) {
      final s = e.toString();
      return s.startsWith('Exception: ') ? s.substring(11) : s;
    }
  }
}

final salesProvider =
    AsyncNotifierProvider<SalesNotifier, SalesState>(SalesNotifier.new);

// ─── Clients (auto-dispose avec search) ──────────────────────────────────────

class ClientsState {
  const ClientsState({
    this.clients = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.isLoadingMore = false,
  });

  final List<ClientEntity> clients;
  final int total;
  final int page;
  final String search;
  final bool isLoadingMore;

  bool get hasMore => clients.length < total;

  ClientsState copyWith({
    List<ClientEntity>? clients,
    int? total,
    int? page,
    String? search,
    bool? isLoadingMore,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      total: total ?? this.total,
      page: page ?? this.page,
      search: search ?? this.search,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class ClientsNotifier extends AsyncNotifier<ClientsState> {
  static const _pageSize = 25;

  @override
  Future<ClientsState> build() => _load(page: 1, search: '');

  Future<ClientsState> _load({required int page, required String search}) async {
    final repo = ref.read(salesRepositoryProvider);
    final result = await repo.getClients(
      page: page,
      pageSize: _pageSize,
      search: search.isEmpty ? null : search,
    );
    final prev = page > 1 ? (state.valueOrNull?.clients ?? []) : <ClientEntity>[];
    return ClientsState(
      clients: [...prev, ...result.clients],
      total: result.count,
      page: page,
      search: search,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _load(page: 1, search: state.valueOrNull?.search ?? ''));
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1, search: query));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(salesRepositoryProvider).getClients(
            page: current.page + 1,
            pageSize: _pageSize,
            search: current.search.isEmpty ? null : current.search,
          );
      state = AsyncData(current.copyWith(
        clients: [...current.clients, ...result.clients],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final clientsProvider =
    AsyncNotifierProvider<ClientsNotifier, ClientsState>(ClientsNotifier.new);

// ─── Produits pour sélecteur (new sale) ──────────────────────────────────────

final productsSearchProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, search) async {
  final repo = ref.read(salesRepositoryProvider);
  final result = await repo.getProducts(pageSize: 50, search: search);
  return result.products;
});
