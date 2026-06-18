import 'package:djoulagest_mobile/features/sales/domain/entities/client_entity.dart';
import 'package:djoulagest_mobile/features/sales/domain/entities/sale_entity.dart';

abstract class SalesRepository {
  Future<({int count, List<SaleEntity> sales})> getSales({
    int page = 1,
    int pageSize = 25,
    String? statut,
  });

  Future<({int count, List<ClientEntity> clients})> getClients({
    int page = 1,
    int pageSize = 25,
    String? search,
  });

  Future<({int count, List<Map<String, dynamic>> products})> getProducts({
    int page = 1,
    int pageSize = 25,
    String? search,
  });

  Future<SaleEntity> createSale({
    required int depot,
    int? client,
    required String modePaiement,
    required List<Map<String, dynamic>> lignes,
    num remise,
    num montantPaye,
    String? modePaiementInitial,
    String? referencePaiement,
    String? notes,
  });
}
