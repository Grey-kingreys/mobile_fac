import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/hr/data/models/attendance_model.dart';
import 'package:djoulagest_mobile/features/hr/data/models/employee_model.dart';
import 'package:djoulagest_mobile/features/hr/domain/entities/attendance_entity.dart';
import 'package:djoulagest_mobile/features/hr/domain/entities/employee_entity.dart';

class HrRemoteDatasource {
  const HrRemoteDatasource(this._api);
  final ApiClient _api;

  Future<({int count, List<EmployeeEntity> employees})> getEmployees({
    int page = 1,
    int pageSize = 25,
    String? search,
    String? statut,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': 'nom',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (statut != null && statut.isNotEmpty) params['statut'] = statut;

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.employes,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    return (
      count: data['count'] as int? ?? 0,
      employees: _list(data).map(EmployeeModel.fromJson).toList(),
    );
  }

  Future<EmployeeEntity> createEmployee(Map<String, dynamic> body) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.employes,
      data: body,
    );
    return EmployeeModel.fromJson(resp.data ?? {});
  }

  // ─── Présences ───────────────────────────────────────────────────────────────

  Future<({int count, List<PresenceEntity> presences})> getPresences({
    int page = 1,
    int pageSize = 25,
    String? employeId,
    String? date,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': '-date',
    };
    if (employeId != null) params['employe'] = employeId;
    if (date != null) params['date'] = date;

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.presences,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    return (
      count: data['count'] as int? ?? 0,
      presences: _list(data).map(PresenceModel.fromJson).toList(),
    );
  }

  Future<PresenceEntity> createPresence(Map<String, dynamic> body) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.presences,
      data: body,
    );
    return PresenceModel.fromJson(resp.data ?? {});
  }

  // ─── Congés ──────────────────────────────────────────────────────────────────

  Future<({int count, List<CongeEntity> conges})> getConges({
    int page = 1,
    int pageSize = 25,
    String? statut,
    String? employeId,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': '-created_at',
    };
    if (statut != null && statut.isNotEmpty) params['statut'] = statut;
    if (employeId != null) params['employe'] = employeId;

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.conges,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    return (
      count: data['count'] as int? ?? 0,
      conges: _list(data).map(CongeModel.fromJson).toList(),
    );
  }

  Future<CongeEntity> createConge(Map<String, dynamic> body) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.conges,
      data: body,
    );
    return CongeModel.fromJson(resp.data ?? {});
  }

  Future<CongeEntity> approuverConge(int id) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.congeApprouver(id),
    );
    return CongeModel.fromJson(resp.data ?? {});
  }

  Future<CongeEntity> refuserConge(int id) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.congeRefuser(id),
    );
    return CongeModel.fromJson(resp.data ?? {});
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic>? data) {
    if (data == null) return [];
    final r = data['results'];
    if (r is List) return r.cast<Map<String, dynamic>>();
    return [];
  }
}
