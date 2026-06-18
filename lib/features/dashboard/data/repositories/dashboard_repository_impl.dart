import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:djoulagest_mobile/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:djoulagest_mobile/features/dashboard/domain/entities/kpi_entity.dart';
import 'package:djoulagest_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._datasource);
  final DashboardRemoteDatasource _datasource;

  @override
  Future<DashboardDataEntity> getDashboard(UserEntity user) =>
      _datasource.getDashboard(user);
}
