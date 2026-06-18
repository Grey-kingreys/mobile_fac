import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:djoulagest_mobile/features/dashboard/domain/entities/kpi_entity.dart';

abstract class DashboardRepository {
  Future<DashboardDataEntity> getDashboard(UserEntity user);
}
