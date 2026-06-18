import 'package:djoulagest_mobile/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:djoulagest_mobile/features/admin/domain/entities/company_entity.dart';
import 'package:djoulagest_mobile/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._datasource);
  final AdminRemoteDatasource _datasource;

  @override
  Future<({int count, List<CompanyEntity> companies})> getCompanies({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) =>
      _datasource.getCompanies(page: page, pageSize: pageSize, search: search);

  @override
  Future<CompanyEntity> createCompany({
    required String name,
    required String emailAdmin,
    required String subscriptionPlan,
  }) =>
      _datasource.createCompany(
        name: name,
        emailAdmin: emailAdmin,
        subscriptionPlan: subscriptionPlan,
      );

  @override
  Future<CompanyEntity> updateCompany({
    required int id,
    required String name,
    required String subscriptionPlan,
  }) =>
      _datasource.updateCompany(id: id, name: name, subscriptionPlan: subscriptionPlan);

  @override
  Future<CompanyEntity> toggleCompany(int id) => _datasource.toggleCompany(id);
}
