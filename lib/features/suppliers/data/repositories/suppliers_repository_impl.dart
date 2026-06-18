import 'package:djoulagest_mobile/features/suppliers/data/datasources/suppliers_remote_datasource.dart';
import 'package:djoulagest_mobile/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:djoulagest_mobile/features/suppliers/domain/repositories/suppliers_repository.dart';

class SuppliersRepositoryImpl implements SuppliersRepository {
  const SuppliersRepositoryImpl(this._datasource);
  final SuppliersRemoteDatasource _datasource;

  @override
  Future<({int count, List<SupplierEntity> suppliers})> getSuppliers({
    int page = 1,
    int pageSize = 25,
    String? search,
    bool? isActive,
  }) =>
      _datasource.getSuppliers(
          page: page, pageSize: pageSize, search: search, isActive: isActive);

  @override
  Future<SupplierEntity> getSupplierDetail(int id) =>
      _datasource.getSupplierDetail(id);

  @override
  Future<SupplierEntity> createSupplier(Map<String, dynamic> body) =>
      _datasource.createSupplier(body);

  @override
  Future<List<SupplierEvaluationEntity>> getEvaluations(int id) =>
      _datasource.getEvaluations(id);

  @override
  Future<List<SupplierOrderEntity>> getCommandesFournisseur(int id) =>
      _datasource.getCommandesFournisseur(id);
}
