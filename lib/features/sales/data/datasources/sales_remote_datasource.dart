import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/sales/data/models/client_model.dart';
import 'package:djoulagest_mobile/features/sales/data/models/sale_model.dart';
import 'package:djoulagest_mobile/features/sales/domain/entities/client_entity.dart';
import 'package:djoulagest_mobile/features/sales/domain/entities/sale_entity.dart';

class SalesRemoteDatasource {
  const SalesRemoteDatasource(this._api);
  final ApiClient _api;

  Future<({int count, List<SaleEntity> sales})> getSales({
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
      ApiEndpoints.commandes,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    final count = data['count'] as int? ?? 0;
    return (
      count: count,
      sales: _list(data).map(SaleModel.fromJson).toList(),
    );
  }

  Future<({int count, List<ClientEntity> clients})> getClients({
    int page = 1,
    int pageSize = 25,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': 'nom',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.clients,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    final count = data['count'] as int? ?? 0;
    return (
      count: count,
      clients: _list(data).map(ClientModel.fromJson).toList(),
    );
  }

  Future<({int count, List<Map<String, dynamic>> products})> getProducts({
    int page = 1,
    int pageSize = 25,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'is_active': 'true',
      'ordering': 'nom',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.produits,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    final count = data['count'] as int? ?? 0;
    return (count: count, products: _list(data));
  }

  Future<SaleEntity> createSale({
    required int depot,
    int? client,
    required String modePaiement,
    required List<Map<String, dynamic>> lignes,
    num remise = 0,
    num montantPaye = 0,
    String? modePaiementInitial,
    String? referencePaiement,
    int? compteMobileMoney,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'depot': depot,
      'mode_paiement': modePaiement,
      'lignes': lignes,
      'remise': remise,
      'montant_paye': montantPaye,
    };
    if (client != null) body['client'] = client;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    if (modePaiementInitial != null) {
      body['mode_paiement_initial'] = modePaiementInitial;
    }
    if (referencePaiement != null && referencePaiement.isNotEmpty) {
      body['reference_paiement'] = referencePaiement;
    }
    if (compteMobileMoney != null) {
      body['compte_mobile_money'] = compteMobileMoney;
    }

    final resp =
        await _api.post<Map<String, dynamic>>(ApiEndpoints.commandes, data: body);
    return SaleModel.fromJson(resp.data ?? {});
  }

  Future<SaleEntity> annulerCommande(int id) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.commandeAnnuler(id),
      data: {},
    );
    return SaleModel.fromJson(resp.data ?? {});
  }

  Future<SaleEntity> payerCommande({
    required int id,
    required num montant,
    required String mode,
    String? reference,
  }) async {
    final body = <String, dynamic>{
      'montant': montant.toString(),
      'mode': mode,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
    };
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.commandePaiement(id),
      data: body,
    );
    return SaleModel.fromJson(resp.data ?? {});
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic> data) {
    final r = data['results'];
    if (r is List) return r.cast<Map<String, dynamic>>();
    return [];
  }
}
