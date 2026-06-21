import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/audit/data/models/audit_log_model.dart';
import 'package:djoulagest_mobile/features/audit/domain/entities/audit_log_entity.dart';

/// Accès lecture seule aux journaux d'audit et de connexion.
/// Endpoints réservés Admin/SuperAdmin côté backend (403 sinon).
class AuditRemoteDatasource {
  const AuditRemoteDatasource(this._api);
  final ApiClient _api;

  Future<({int count, List<AuditLogEntity> logs})> getAuditLogs({
    int page = 1,
    int pageSize = 25,
    String? modelName,
    String? action,
    int? userId,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.auditLogs,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (modelName != null && modelName.isNotEmpty) 'model_name': modelName,
        if (action != null && action.isNotEmpty) 'action': action,
        if (userId != null) 'user_id': userId,
      },
    );
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    final count = inner['count'] as int? ?? 0;
    final raw = inner['results'] as List<dynamic>? ?? [];
    final logs = raw
        .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (count: count, logs: logs);
  }

  Future<({int count, List<LoginLogEntity> logs})> getLoginLogs({
    int page = 1,
    int pageSize = 25,
    int? userId,
    bool? success,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.loginLogs,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (userId != null) 'user_id': userId,
        if (success != null) 'success': success ? 'true' : 'false',
      },
    );
    final outer = res.data ?? {};
    final inner = outer['data'] as Map<String, dynamic>? ?? outer;
    final count = inner['count'] as int? ?? 0;
    final raw = inner['results'] as List<dynamic>? ?? [];
    final logs = raw
        .map((e) => LoginLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (count: count, logs: logs);
  }
}
