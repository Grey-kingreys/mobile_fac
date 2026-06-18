import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/products/data/datasources/products_remote_datasource.dart';
import 'package:djoulagest_mobile/features/products/data/repositories/products_repository_impl.dart';
import 'package:djoulagest_mobile/features/products/domain/entities/product_entity.dart';
import 'package:djoulagest_mobile/features/products/domain/repositories/products_repository.dart';

// ─── DI ──────────────────────────────────────────────────────────────────────

final _productsDatasourceProvider = Provider<ProductsRemoteDatasource>(
  (ref) => ProductsRemoteDatasource(ref.read(apiClientProvider)),
);

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepositoryImpl(ref.read(_productsDatasourceProvider)),
);

// ─── State ───────────────────────────────────────────────────────────────────

class ProductsState {
  const ProductsState({
    this.products = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.isLoadingMore = false,
  });

  final List<ProductEntity> products;
  final int total;
  final int page;
  final String search;
  final bool isLoadingMore;

  bool get hasMore => products.length < total;

  ProductsState copyWith({
    List<ProductEntity>? products,
    int? total,
    int? page,
    String? search,
    bool? isLoadingMore,
  }) {
    return ProductsState(
      products: products ?? this.products,
      total: total ?? this.total,
      page: page ?? this.page,
      search: search ?? this.search,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ─── Notifier liste ───────────────────────────────────────────────────────────

class ProductsNotifier extends AsyncNotifier<ProductsState> {
  static const _pageSize = 25;

  @override
  Future<ProductsState> build() => _load(page: 1, search: '');

  Future<ProductsState> _load({
    required int page,
    required String search,
  }) async {
    final repo = ref.read(productsRepositoryProvider);
    final result = await repo.getProducts(
      page: page,
      pageSize: _pageSize,
      search: search.isEmpty ? null : search,
      isActive: true,
    );
    final prev =
        page > 1 ? (state.valueOrNull?.products ?? []) : <ProductEntity>[];
    return ProductsState(
      products: [...prev, ...result.products],
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
      final result = await ref.read(productsRepositoryProvider).getProducts(
            page: current.page + 1,
            pageSize: _pageSize,
            search: current.search.isEmpty ? null : current.search,
            isActive: true,
          );
      state = AsyncData(current.copyWith(
        products: [...current.products, ...result.products],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, ProductsState>(
        ProductsNotifier.new);

// ─── Détail produit ───────────────────────────────────────────────────────────

final productDetailProvider =
    FutureProvider.autoDispose.family<ProductEntity, int>((ref, id) async {
  return ref.read(productsRepositoryProvider).getProductDetail(id);
});

// ─── Recherche produit par référence (code-barres) ───────────────────────────

final productByReferenceProvider =
    FutureProvider.autoDispose.family<ProductEntity?, String>((ref, reference) async {
  final result = await ref.read(productsRepositoryProvider).getProducts(
        search: reference,
        pageSize: 1,
      );
  return result.products.firstOrNull;
});
