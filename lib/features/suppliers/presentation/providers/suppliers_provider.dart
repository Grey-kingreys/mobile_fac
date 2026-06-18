import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/suppliers/data/datasources/suppliers_remote_datasource.dart';
import 'package:djoulagest_mobile/features/suppliers/data/repositories/suppliers_repository_impl.dart';
import 'package:djoulagest_mobile/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:djoulagest_mobile/features/suppliers/domain/repositories/suppliers_repository.dart';

// ─── DI ──────────────────────────────────────────────────────────────────────

final _suppliersDatasourceProvider = Provider<SuppliersRemoteDatasource>(
  (ref) => SuppliersRemoteDatasource(ref.read(apiClientProvider)),
);

final suppliersRepositoryProvider = Provider<SuppliersRepository>(
  (ref) => SuppliersRepositoryImpl(ref.read(_suppliersDatasourceProvider)),
);

// ─── State ───────────────────────────────────────────────────────────────────

class SuppliersState {
  const SuppliersState({
    this.suppliers = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.isLoadingMore = false,
  });

  final List<SupplierEntity> suppliers;
  final int total;
  final int page;
  final String search;
  final bool isLoadingMore;

  bool get hasMore => suppliers.length < total;

  SuppliersState copyWith({
    List<SupplierEntity>? suppliers,
    int? total,
    int? page,
    String? search,
    bool? isLoadingMore,
  }) =>
      SuppliersState(
        suppliers: suppliers ?? this.suppliers,
        total: total ?? this.total,
        page: page ?? this.page,
        search: search ?? this.search,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SuppliersNotifier extends AsyncNotifier<SuppliersState> {
  static const _pageSize = 25;

  @override
  Future<SuppliersState> build() => _load(page: 1, search: '');

  Future<SuppliersState> _load({required int page, required String search}) async {
    final repo = ref.read(suppliersRepositoryProvider);
    final result = await repo.getSuppliers(
      page: page,
      pageSize: _pageSize,
      search: search.isEmpty ? null : search,
    );
    final prev = page > 1 ? (state.valueOrNull?.suppliers ?? []) : <SupplierEntity>[];
    return SuppliersState(
      suppliers: [...prev, ...result.suppliers],
      total: result.count,
      page: page,
      search: search,
    );
  }

  Future<void> refresh() async {
    final s = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1, search: s?.search ?? ''));
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
      final result = await ref.read(suppliersRepositoryProvider).getSuppliers(
            page: current.page + 1,
            pageSize: _pageSize,
            search: current.search.isEmpty ? null : current.search,
          );
      state = AsyncData(current.copyWith(
        suppliers: [...current.suppliers, ...result.suppliers],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> createSupplier(Map<String, dynamic> body) async {
    await ref.read(suppliersRepositoryProvider).createSupplier(body);
    await refresh();
  }
}

final suppliersProvider =
    AsyncNotifierProvider<SuppliersNotifier, SuppliersState>(SuppliersNotifier.new);

// ─── Detail ───────────────────────────────────────────────────────────────────

final supplierDetailProvider = FutureProvider.autoDispose.family<SupplierEntity, int>(
  (ref, id) => ref.read(suppliersRepositoryProvider).getSupplierDetail(id),
);

final supplierEvaluationsProvider =
    FutureProvider.autoDispose.family<List<SupplierEvaluationEntity>, int>(
  (ref, id) => ref.read(suppliersRepositoryProvider).getEvaluations(id),
);

final supplierOrdersProvider =
    FutureProvider.autoDispose.family<List<SupplierOrderEntity>, int>(
  (ref, id) => ref.read(suppliersRepositoryProvider).getCommandesFournisseur(id),
);
