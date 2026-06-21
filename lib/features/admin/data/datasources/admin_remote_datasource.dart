import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/admin/data/models/company_model.dart';
import 'package:djoulagest_mobile/features/admin/domain/entities/company_entity.dart';

class AdminRemoteDatasource {
  const AdminRemoteDatasource(this._api);
  final ApiClient _api;

  Future<({int count, List<CompanyEntity> companies})> getCompanies({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.companies,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    // Format backend : {success, data: {count, companies: [...]}, message}
    // (le backend renvoie la clé `companies`, pas `results`).
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    final count = inner['count'] as int? ?? 0;
    final list = ((inner['companies'] ?? inner['results']) as List<dynamic>? ?? [])
        .map((e) => CompanyModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (count: count, companies: list);
  }

  Future<CompanyEntity> createCompany({
    required String name,
    required String emailAdmin,
    required String subscriptionPlan,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.companies,
      data: {
        'name': name,
        'email_admin': emailAdmin,
        'subscription_plan': subscriptionPlan,
      },
    );
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    return CompanyModel.fromJson(inner);
  }

  Future<CompanyEntity> updateCompany({
    required int id,
    required String name,
    required String subscriptionPlan,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      ApiEndpoints.companyDetail(id),
      data: {'name': name, 'subscription_plan': subscriptionPlan},
    );
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    return CompanyModel.fromJson(inner);
  }

  Future<CompanyEntity> toggleCompany(int id) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.companyToggle(id),
    );
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    return CompanyModel.fromJson(inner);
  }
}
