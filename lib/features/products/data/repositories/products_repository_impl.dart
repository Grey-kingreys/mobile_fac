import 'package:djoulagest_mobile/features/products/data/datasources/products_remote_datasource.dart';
import 'package:djoulagest_mobile/features/products/domain/entities/product_entity.dart';
import 'package:djoulagest_mobile/features/products/domain/repositories/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  const ProductsRepositoryImpl(this._datasource);
  final ProductsRemoteDatasource _datasource;

  @override
  Future<({int count, List<ProductEntity> products})> getProducts({
    int page = 1,
    int pageSize = 25,
    String? search,
    bool? isActive,
  }) async {
    final result = await _datasource.getProducts(
      page: page,
      pageSize: pageSize,
      search: search,
      isActive: isActive,
    );
    return (
      count: result.count,
      products: result.products.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<ProductEntity> getProductDetail(int id) async {
    final model = await _datasource.getProductDetail(id);
    return model.toEntity();
  }
}
