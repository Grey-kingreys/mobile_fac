import 'package:djoulagest_mobile/features/hr/data/datasources/hr_remote_datasource.dart';
import 'package:djoulagest_mobile/features/hr/domain/entities/attendance_entity.dart';
import 'package:djoulagest_mobile/features/hr/domain/entities/employee_entity.dart';
import 'package:djoulagest_mobile/features/hr/domain/repositories/hr_repository.dart';

class HrRepositoryImpl implements HrRepository {
  const HrRepositoryImpl(this._datasource);
  final HrRemoteDatasource _datasource;

  @override
  Future<({int count, List<EmployeeEntity> employees})> getEmployees({
    int page = 1,
    int pageSize = 25,
    String? search,
    String? statut,
  }) =>
      _datasource.getEmployees(
          page: page, pageSize: pageSize, search: search, statut: statut);

  @override
  Future<EmployeeEntity> createEmployee(Map<String, dynamic> body) =>
      _datasource.createEmployee(body);

  @override
  Future<({int count, List<PresenceEntity> presences})> getPresences({
    int page = 1,
    int pageSize = 25,
    String? employeId,
    String? date,
  }) =>
      _datasource.getPresences(
          page: page, pageSize: pageSize, employeId: employeId, date: date);

  @override
  Future<PresenceEntity> createPresence(Map<String, dynamic> body) =>
      _datasource.createPresence(body);

  @override
  Future<({int count, List<CongeEntity> conges})> getConges({
    int page = 1,
    int pageSize = 25,
    String? statut,
    String? employeId,
  }) =>
      _datasource.getConges(
          page: page, pageSize: pageSize, statut: statut, employeId: employeId);

  @override
  Future<CongeEntity> createConge(Map<String, dynamic> body) =>
      _datasource.createConge(body);

  @override
  Future<CongeEntity> approuverConge(int id) => _datasource.approuverConge(id);

  @override
  Future<CongeEntity> refuserConge(int id) => _datasource.refuserConge(id);
}
