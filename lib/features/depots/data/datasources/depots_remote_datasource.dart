import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/depots/data/models/depot_model.dart';
import 'package:djoulagest_mobile/features/depots/domain/entities/depot_entity.dart';

class DepotsRemoteDatasource {
  const DepotsRemoteDatasource(this._api);
  final ApiClient _api;

  Future<({int count, List<DepotEntity> depots})> getDepots({
    int page = 1,
    int pageSize = 25,
    String? search,
    int? zoneId,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.depots,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (zoneId != null) 'zone': zoneId,
      },
    );
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    final count = inner['count'] as int? ?? 0;
    final raw = inner['results'] as List<dynamic>?
        ?? inner['depots'] as List<dynamic>?
        ?? [];
    final depots = raw
        .map((e) => DepotModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (count: count, depots: depots);
  }

  Future<DepotEntity> createDepot({
    required String nom,
    required String code,
    required int zoneId,
    String? adresse,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.depots,
      data: DepotModel.toJson(
        nom: nom,
        code: code,
        zoneId: zoneId,
        adresse: adresse,
        latitude: latitude,
        longitude: longitude,
      ),
    );
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    return DepotModel.fromJson(inner);
  }

  Future<DepotEntity> updateDepot({
    required int id,
    required String nom,
    required String code,
    required int zoneId,
    String? adresse,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      ApiEndpoints.depotDetail(id),
      data: DepotModel.toJson(
        nom: nom,
        code: code,
        zoneId: zoneId,
        adresse: adresse,
        latitude: latitude,
        longitude: longitude,
      ),
    );
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    return DepotModel.fromJson(inner);
  }

  Future<void> deleteDepot(int id) async {
    await _api.delete<void>(ApiEndpoints.depotDetail(id));
  }
}
