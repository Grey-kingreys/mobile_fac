import 'package:djoulagest_mobile/features/inventory/domain/entities/stock_entity.dart';

abstract class InventoryRepository {
  Future<({int count, List<StockEntity> stocks})> getStocks({
    int page = 1,
    int pageSize = 25,
    String? search,
    bool? alertsOnly,
  });

  Future<({int count, List<MovementEntity> movements})> getMovements({
    int page = 1,
    int pageSize = 25,
    String? typeMouvement,
  });

  Future<({int count, List<TransfertEntity> transferts})> getTransferts({
    int page = 1,
    int pageSize = 25,
    String? statut,
  });

  Future<void> createTransfert({
    required int depotSource,
    required int depotDestination,
    String? notes,
    required List<Map<String, dynamic>> lignes,
  });

  Future<({int count, List<AjustementEntity> ajustements})> getAjustements({
    int page = 1,
    int pageSize = 25,
    String? statut,
  });

  Future<void> createAjustement({
    required int depot,
    required int produit,
    required num quantite,
    String? motif,
  });

  Future<void> approuverAjustement(int id);

  Future<void> refuserAjustement(int id, {String? motif});

  Future<void> stockEntree({
    required int depot,
    required int produit,
    required num quantite,
    String? referenceDoc,
    String? motif,
    String? numeroLot,
    String? dateExpiration,
  });

  Future<void> stockSortie({
    required int depot,
    required int produit,
    required num quantite,
    String? referenceDoc,
    String? motif,
  });
}
