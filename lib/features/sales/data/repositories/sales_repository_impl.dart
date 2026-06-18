import 'package:djoulagest_mobile/features/sales/data/datasources/sales_remote_datasource.dart';
import 'package:djoulagest_mobile/features/sales/domain/entities/client_entity.dart';
import 'package:djoulagest_mobile/features/sales/domain/entities/sale_entity.dart';
import 'package:djoulagest_mobile/features/sales/domain/repositories/sales_repository.dart';

class SalesRepositoryImpl implements SalesRepository {
  const SalesRepositoryImpl(this._datasource);
  final SalesRemoteDatasource _datasource;

  @override
  Future<({int count, List<SaleEntity> sales})> getSales({
    int page = 1,
    int pageSize = 25,
    String? statut,
  }) =>
      _datasource.getSales(page: page, pageSize: pageSize, statut: statut);

  @override
  Future<({int count, List<ClientEntity> clients})> getClients({
    int page = 1,
    int pageSize = 25,
    String? search,
  }) =>
      _datasource.getClients(page: page, pageSize: pageSize, search: search);

  @override
  Future<({int count, List<Map<String, dynamic>> products})> getProducts({
    int page = 1,
    int pageSize = 25,
    String? search,
  }) =>
      _datasource.getProducts(page: page, pageSize: pageSize, search: search);

  @override
  Future<SaleEntity> createSale({
    required int depot,
    int? client,
    required String modePaiement,
    required List<Map<String, dynamic>> lignes,
    num remise = 0,
    num montantPaye = 0,
    String? modePaiementInitial,
    String? referencePaiement,
    String? notes,
  }) =>
      _datasource.createSale(
        depot: depot,
        client: client,
        modePaiement: modePaiement,
        lignes: lignes,
        remise: remise,
        montantPaye: montantPaye,
        modePaiementInitial: modePaiementInitial,
        referencePaiement: referencePaiement,
        notes: notes,
      );
}
