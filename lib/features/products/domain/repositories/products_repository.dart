import 'package:djoulagest_mobile/features/products/domain/entities/product_entity.dart';

abstract class ProductsRepository {
  Future<({int count, List<ProductEntity> products})> getProducts({
    int page = 1,
    int pageSize = 25,
    String? search,
    bool? isActive,
  });

  Future<ProductEntity> getProductDetail(int id);
}
