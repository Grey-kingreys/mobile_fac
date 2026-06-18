import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/suppliers/data/models/supplier_model.dart';
import 'package:djoulagest_mobile/features/suppliers/domain/entities/supplier_entity.dart';

class SuppliersRemoteDatasource {
  const SuppliersRemoteDatasource(this._api);
  final ApiClient _api;

  Future<({int count, List<SupplierEntity> suppliers})> getSuppliers({
    int page = 1,
    int pageSize = 25,
    String? search,
    bool? isActive,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': 'nom',
      if (search != null && search.isNotEmpty) 'search': search,
      if (isActive != null) 'is_active': isActive,
    };
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.fournisseurs,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    return (
      count: data['count'] as int? ?? 0,
      suppliers: _list(data).map(SupplierModel.fromJson).toList(),
    );
  }

  Future<SupplierEntity> getSupplierDetail(int id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.fournisseurDetail(id),
    );
    return SupplierModel.fromJson(resp.data ?? {});
  }

  Future<SupplierEntity> createSupplier(Map<String, dynamic> body) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.fournisseurs,
      data: body,
    );
    return SupplierModel.fromJson(resp.data ?? {});
  }

  Future<List<SupplierEvaluationEntity>> getEvaluations(int id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.fournisseurEvaluations(id),
    );
    final data = resp.data ?? {};
    return _list(data).map(SupplierEvaluationModel.fromJson).toList();
  }

  Future<List<SupplierOrderEntity>> getCommandesFournisseur(int id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.commandesFournisseurs,
      queryParameters: {'fournisseur': '$id', 'ordering': '-created_at'},
    );
    final data = resp.data ?? {};
    return _list(data).map(SupplierOrderModel.fromJson).toList();
  }

  Future<({int count, List<SupplierOrderEntity> orders})> getAllCommandesFournisseurs({
    int page = 1,
    int pageSize = 25,
    String? statut,
    int? fournisseurId,
  }) async {
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.commandesFournisseurs,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        'ordering': '-created_at',
        if (statut != null) 'statut': statut,
        if (fournisseurId != null) 'fournisseur': fournisseurId,
      },
    );
    final data = resp.data ?? {};
    return (
      count: data['count'] as int? ?? 0,
      orders: _list(data).map(SupplierOrderModel.fromJson).toList(),
    );
  }

  Future<SupplierOrderEntity> getCommandeFournisseurDetail(int id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.commandeFournisseurDetail(id),
    );
    return SupplierOrderModel.fromJson(resp.data ?? {});
  }

  Future<SupplierOrderEntity> createCommandeFournisseur({
    required int fournisseur,
    required int depotDestination,
    required List<Map<String, dynamic>> lignes,
    String? dateLivraisonPrevue,
    String? notes,
  }) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.commandesFournisseurs,
      data: {
        'fournisseur': fournisseur,
        'depot_destination': depotDestination,
        'lignes': lignes,
        if (dateLivraisonPrevue != null) 'date_livraison_prevue': dateLivraisonPrevue,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return SupplierOrderModel.fromJson(resp.data ?? {});
  }

  Future<SupplierOrderEntity> recevoirCommandeFournisseur({
    required int id,
    required List<Map<String, dynamic>> lignes,
  }) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.commandeFournisseurRecevoir(id),
      data: {'lignes': lignes},
    );
    return SupplierOrderModel.fromJson(resp.data ?? {});
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic>? data) {
    if (data == null) return [];
    final r = data['results'];
    if (r is List) return r.cast<Map<String, dynamic>>();
    return [];
  }
}
