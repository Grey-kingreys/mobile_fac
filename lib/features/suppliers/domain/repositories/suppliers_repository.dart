import 'package:djoulagest_mobile/features/suppliers/domain/entities/supplier_entity.dart';

abstract class SuppliersRepository {
  Future<({int count, List<SupplierEntity> suppliers})> getSuppliers({
    int page = 1,
    int pageSize = 25,
    String? search,
    bool? isActive,
  });

  Future<SupplierEntity> getSupplierDetail(int id);

  Future<SupplierEntity> createSupplier(Map<String, dynamic> body);

  Future<List<SupplierEvaluationEntity>> getEvaluations(int id);

  Future<List<SupplierOrderEntity>> getCommandesFournisseur(int id);
}
