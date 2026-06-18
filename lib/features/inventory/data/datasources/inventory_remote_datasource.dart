import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/inventory/data/models/movement_model.dart';
import 'package:djoulagest_mobile/features/inventory/data/models/stock_model.dart';
import 'package:djoulagest_mobile/features/inventory/domain/entities/stock_entity.dart';

class InventoryRemoteDatasource {
  const InventoryRemoteDatasource(this._api);
  final ApiClient _api;

  Future<({int count, List<StockEntity> stocks})> getStocks({
    int page = 1,
    int pageSize = 25,
    String? search,
    bool? alertsOnly,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': 'produit__nom',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (alertsOnly == true) params['en_alerte'] = 'true';

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.stocks,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    final count = data['count'] as int? ?? 0;
    final results = _list(data);
    return (
      count: count,
      stocks: results.map(StockModel.fromJson).toList(),
    );
  }

  Future<({int count, List<MovementEntity> movements})> getMovements({
    int page = 1,
    int pageSize = 25,
    String? typeMouvement,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': '-created_at',
    };
    if (typeMouvement != null && typeMouvement.isNotEmpty) {
      params['type_mouvement'] = typeMouvement;
    }

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.mouvementsStock,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    final count = data['count'] as int? ?? 0;
    final results = _list(data);
    return (
      count: count,
      movements: results.map(MovementModel.fromJson).toList(),
    );
  }

  Future<({int count, List<TransfertEntity> transferts})> getTransferts({
    int page = 1,
    int pageSize = 25,
    String? statut,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': '-created_at',
    };
    if (statut != null && statut.isNotEmpty) params['statut'] = statut;

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.transferts,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    final count = data['count'] as int? ?? 0;
    final results = _list(data);
    return (
      count: count,
      transferts: results.map(TransfertModel.fromJson).toList(),
    );
  }

  Future<void> createTransfert({
    required int depotSource,
    required int depotDestination,
    String? notes,
    required List<Map<String, dynamic>> lignes,
  }) async {
    await _api.post<Map<String, dynamic>>(
      ApiEndpoints.transferts,
      data: {
        'depot_source': depotSource,
        'depot_destination': depotDestination,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'lignes': lignes,
      },
    );
  }

  Future<({int count, List<AjustementEntity> ajustements})> getAjustements({
    int page = 1,
    int pageSize = 25,
    String? statut,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': '-created_at',
    };
    if (statut != null && statut.isNotEmpty) params['statut'] = statut;

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.ajustements,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    return (
      count: data['count'] as int? ?? 0,
      ajustements: _list(data).map(AjustementModel.fromJson).toList(),
    );
  }

  Future<void> createAjustement({
    required int depot,
    required int produit,
    required num quantite,
    required String motif,
  }) async {
    await _api.post<Map<String, dynamic>>(
      ApiEndpoints.ajustements,
      data: {
        'depot': depot,
        'produit': produit,
        'quantite': quantite,
        'motif': motif,
      },
    );
  }

  Future<void> approuverAjustement(int id) async {
    await _api.post<void>(ApiEndpoints.ajustementApprouver(id), data: {});
  }

  Future<void> refuserAjustement(int id, {String? motif}) async {
    await _api.post<void>(
      ApiEndpoints.ajustementRefuser(id),
      data: {if (motif != null && motif.isNotEmpty) 'motif': motif},
    );
  }

  Future<void> stockEntree({
    required int depot,
    required int produit,
    required num quantite,
    String? referenceDoc,
    String? motif,
  }) async {
    final body = <String, dynamic>{
      'depot': depot,
      'produit': produit,
      'quantite': quantite,
    };
    if (referenceDoc != null && referenceDoc.isNotEmpty) {
      body['reference_doc'] = referenceDoc;
    }
    if (motif != null && motif.isNotEmpty) body['motif'] = motif;

    await _api.post<Map<String, dynamic>>(
      ApiEndpoints.stockEntree,
      data: body,
    );
  }

  Future<void> stockSortie({
    required int depot,
    required int produit,
    required num quantite,
    String? referenceDoc,
    required String motif,
  }) async {
    final body = <String, dynamic>{
      'depot': depot,
      'produit': produit,
      'quantite': quantite,
      'motif': motif,
    };
    if (referenceDoc != null && referenceDoc.isNotEmpty) {
      body['reference_doc'] = referenceDoc;
    }

    await _api.post<Map<String, dynamic>>(
      ApiEndpoints.stockSortie,
      data: body,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _list(Map<String, dynamic> data) {
    final r = data['results'];
    if (r is List) return r.cast<Map<String, dynamic>>();
    return [];
  }
}
