import 'package:djoulagest_mobile/features/hr/domain/entities/attendance_entity.dart';
import 'package:djoulagest_mobile/features/hr/domain/entities/employee_entity.dart';

abstract class HrRepository {
  Future<({int count, List<EmployeeEntity> employees})> getEmployees({
    int page = 1,
    int pageSize = 25,
    String? search,
    String? statut,
  });

  Future<EmployeeEntity> createEmployee(Map<String, dynamic> body);

  Future<({int count, List<PresenceEntity> presences})> getPresences({
    int page = 1,
    int pageSize = 25,
    String? employeId,
    String? date,
  });

  Future<PresenceEntity> createPresence(Map<String, dynamic> body);

  Future<PresenceEntity> pointerPresence(Map<String, dynamic> body);

  Future<PresenceTodayStatus> getPresenceAujourdhui();

  Future<PresenceRecap> getPresenceRecap({String? date});

  Future<({int count, List<CongeEntity> conges})> getConges({
    int page = 1,
    int pageSize = 25,
    String? statut,
    String? employeId,
  });

  Future<CongeEntity> createConge(Map<String, dynamic> body);

  Future<CongeEntity> approuverConge(int id);

  Future<CongeEntity> refuserConge(int id, {String? motif});
}
