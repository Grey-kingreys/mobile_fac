import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/zones/data/models/zone_model.dart';
import 'package:djoulagest_mobile/features/zones/domain/entities/zone_entity.dart';

class ZonesRemoteDatasource {
  const ZonesRemoteDatasource(this._api);
  final ApiClient _api;

  Future<({int count, List<ZoneEntity> zones})> getZones({
    int page = 1,
    int pageSize = 25,
    String? search,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.zones,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    final count = inner['count'] as int? ?? 0;
    final raw = inner['results'] as List<dynamic>?
        ?? inner['zones'] as List<dynamic>?
        ?? [];
    final zones = raw
        .map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (count: count, zones: zones);
  }

  Future<ZoneEntity> createZone({
    required String name,
    required String code,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.zones,
      data: ZoneModel.toJson(
        name: name,
        code: code,
        latitude: latitude,
        longitude: longitude,
      ),
    );
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    return ZoneModel.fromJson(inner);
  }

  Future<ZoneEntity> updateZone({
    required int id,
    required String name,
    required String code,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      ApiEndpoints.zoneDetail(id),
      data: ZoneModel.toJson(
        name: name,
        code: code,
        latitude: latitude,
        longitude: longitude,
      ),
    );
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    return ZoneModel.fromJson(inner);
  }

  Future<void> deleteZone(int id) async {
    await _api.delete<void>(ApiEndpoints.zoneDetail(id));
  }
}
