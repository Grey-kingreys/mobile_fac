import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/products/data/models/product_model.dart';

class ProductsRemoteDatasource {
  const ProductsRemoteDatasource(this._client);
  final ApiClient _client;

  Future<({int count, List<ProductModel> products})> getProducts({
    int page = 1,
    int pageSize = 25,
    String? search,
    bool? isActive,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (isActive != null) 'is_active': isActive,
    };
    final res = await _client.get(ApiEndpoints.produits, queryParameters: params);
    final data = res.data as Map<String, dynamic>;
    final results = (data['results'] as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (count: data['count'] as int, products: results);
  }

  Future<ProductModel> getProductDetail(int id) async {
    final res = await _client.get(ApiEndpoints.produitDetail(id));
    return ProductModel.fromJson(res.data as Map<String, dynamic>);
  }
}
