import 'package:djoulagest_mobile/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:djoulagest_mobile/features/inventory/domain/entities/stock_entity.dart';
import 'package:djoulagest_mobile/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._datasource);
  final InventoryRemoteDatasource _datasource;

  @override
  Future<({int count, List<StockEntity> stocks})> getStocks({
    int page = 1,
    int pageSize = 25,
    String? search,
    bool? alertsOnly,
  }) =>
      _datasource.getStocks(
          page: page, pageSize: pageSize, search: search, alertsOnly: alertsOnly);

  @override
  Future<({int count, List<MovementEntity> movements})> getMovements({
    int page = 1,
    int pageSize = 25,
    String? typeMouvement,
  }) =>
      _datasource.getMovements(
          page: page, pageSize: pageSize, typeMouvement: typeMouvement);

  @override
  Future<({int count, List<TransfertEntity> transferts})> getTransferts({
    int page = 1,
    int pageSize = 25,
    String? statut,
  }) =>
      _datasource.getTransferts(
          page: page, pageSize: pageSize, statut: statut);

  @override
  Future<void> createTransfert({
    required int depotSource,
    required int depotDestination,
    String? notes,
    required List<Map<String, dynamic>> lignes,
  }) =>
      _datasource.createTransfert(
        depotSource: depotSource,
        depotDestination: depotDestination,
        notes: notes,
        lignes: lignes,
      );

  @override
  Future<({int count, List<AjustementEntity> ajustements})> getAjustements({
    int page = 1,
    int pageSize = 25,
    String? statut,
  }) =>
      _datasource.getAjustements(page: page, pageSize: pageSize, statut: statut);

  @override
  Future<void> createAjustement({
    required int depot,
    required int produit,
    required num quantite,
    String? motif,
  }) =>
      _datasource.createAjustement(
          depot: depot, produit: produit, quantite: quantite, motif: motif!);

  @override
  Future<void> approuverAjustement(int id) =>
      _datasource.approuverAjustement(id);

  @override
  Future<void> refuserAjustement(int id, {String? motif}) =>
      _datasource.refuserAjustement(id, motif: motif);

  @override
  Future<void> stockEntree({
    required int depot,
    required int produit,
    required num quantite,
    String? referenceDoc,
    String? motif,
  }) =>
      _datasource.stockEntree(
        depot: depot,
        produit: produit,
        quantite: quantite,
        referenceDoc: referenceDoc,
        motif: motif,
      );

  @override
  Future<void> stockSortie({
    required int depot,
    required int produit,
    required num quantite,
    String? referenceDoc,
    String? motif,
  }) =>
      _datasource.stockSortie(
        depot: depot,
        produit: produit,
        quantite: quantite,
        referenceDoc: referenceDoc,
        motif: motif!,
      );
}
