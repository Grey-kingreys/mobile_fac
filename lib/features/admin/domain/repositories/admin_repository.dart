import 'package:djoulagest_mobile/features/admin/domain/entities/company_entity.dart';

abstract class AdminRepository {
  Future<({int count, List<CompanyEntity> companies})> getCompanies({
    int page = 1,
    int pageSize = 20,
    String? search,
  });

  Future<CompanyEntity> createCompany({
    required String name,
    required String emailAdmin,
    required String subscriptionPlan,
  });

  Future<CompanyEntity> updateCompany({
    required int id,
    required String name,
    required String subscriptionPlan,
  });

  Future<CompanyEntity> toggleCompany(int id);
}
