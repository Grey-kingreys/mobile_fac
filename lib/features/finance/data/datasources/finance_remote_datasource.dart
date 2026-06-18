import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/finance/data/models/caisse_model.dart';
import 'package:djoulagest_mobile/features/finance/data/models/cash_session_model.dart';
import 'package:djoulagest_mobile/features/finance/data/models/transaction_model.dart';
import 'package:djoulagest_mobile/features/finance/domain/entities/caisse_entity.dart';
import 'package:djoulagest_mobile/features/finance/domain/entities/cash_session_entity.dart';

class FinanceRemoteDatasource {
  const FinanceRemoteDatasource(this._api);
  final ApiClient _api;

  Future<CashSessionEntity?> getActiveSession() async {
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.sessionsCaisse,
      queryParameters: {'statut': 'ouverte', 'page_size': '1'},
    );
    final results = _results(resp.data);
    if (results.isEmpty) return null;
    return CashSessionModel.fromJson(results.first);
  }

  Future<({int count, List<CashSessionEntity> sessions})> getSessions({
    int page = 1,
    int pageSize = 20,
    String? statut,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': '-ouvert_le',
    };
    if (statut != null) params['statut'] = statut;

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.sessionsCaisse,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    final count = data['count'] as int? ?? 0;
    final results = _results(resp.data);
    return (
      count: count,
      sessions: results.map(CashSessionModel.fromJson).toList(),
    );
  }

  Future<int?> getCaisseIdForDepot(int depotId) async {
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.caisses,
      queryParameters: {'depot': depotId, 'page_size': '1'},
    );
    final results = _results(resp.data);
    if (results.isEmpty) return null;
    return results.first['id'] as int?;
  }

  Future<CashSessionEntity> openSession({
    required int caisseId,
    required num soldeOuverture,
  }) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.sessionCaisseOuvrir,
      data: {'caisse': caisseId, 'solde_ouverture': soldeOuverture},
    );
    return CashSessionModel.fromJson(_unwrap(resp.data));
  }

  Future<CashSessionEntity> closeSession({
    required int id,
    required num soldeFermeture,
    String? motifEcart,
  }) async {
    final body = <String, dynamic>{'solde_reel': soldeFermeture};
    if (motifEcart != null && motifEcart.isNotEmpty) {
      body['motif_ecart'] = motifEcart;
    }
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.sessionCaisseFermer(id),
      data: body,
    );
    return CashSessionModel.fromJson(_unwrap(resp.data));
  }

  Future<({int count, List<TransactionEntity> transactions})> getTransactions({
    int page = 1,
    int pageSize = 20,
    int? sessionId,
  }) async {
    // Les transactions sont imbriquées dans la session ou dans un endpoint dédié.
    // On tente d'abord de lister depuis l'endpoint de session si on a un sessionId.
    if (sessionId != null) {
      try {
        final resp = await _api.get<Map<String, dynamic>>(
          ApiEndpoints.sessionCaisseDetail(sessionId),
        );
        final data = _unwrap(resp.data);
        final txList = data['transactions'] as List<dynamic>? ?? [];
        final parsed = txList
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return (count: parsed.length, transactions: parsed);
      } catch (_) {}
    }
    // Fallback : liste toutes les sessions récentes sans transactions détaillées
    return (count: 0, transactions: <TransactionEntity>[]);
  }

  Future<TransactionEntity> addTransaction({
    required int sessionId,
    required String type,
    required num montant,
    required String description,
  }) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.sessionCaisseTransaction(sessionId),
      data: {
        'type_transaction': type,
        'montant': montant,
        'reference_doc': description,
      },
    );
    return TransactionModel.fromJson(_unwrap(resp.data));
  }

  // ─── Caisses physiques ────────────────────────────────────────────────────────

  Future<List<CaissePhysiqueEntity>> getCaisses({int? depotId}) async {
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.caisses,
      queryParameters: {
        'page_size': '100',
        if (depotId != null) 'depot': depotId,
      },
    );
    return _results(resp.data).map(CaissePhysiqueModel.fromJson).toList();
  }

  Future<CaissePhysiqueEntity> createCaisse({
    required String nom,
    required int depotId,
    String devise = 'GNF',
  }) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.caisses,
      data: {'nom': nom, 'depot': depotId, 'devise': devise},
    );
    return CaissePhysiqueModel.fromJson(_unwrap(resp.data));
  }

  Future<CaissePhysiqueEntity> fermerCaisse(int id) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.caisseFermer(id),
      data: {},
    );
    return CaissePhysiqueModel.fromJson(_unwrap(resp.data));
  }

  // ─── Caisses zone ─────────────────────────────────────────────────────────────

  Future<List<CaisseZoneEntity>> getCaissesZone({int? zoneId}) async {
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.caissesZone,
      queryParameters: {
        'page_size': '100',
        if (zoneId != null) 'zone': zoneId,
      },
    );
    return _results(resp.data).map(CaisseZoneModel.fromJson).toList();
  }

  Future<CaisseZoneEntity> createCaisseZone({
    required String nom,
    required int zoneId,
    String devise = 'GNF',
  }) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.caissesZone,
      data: {'nom': nom, 'zone': zoneId, 'devise': devise},
    );
    return CaisseZoneModel.fromJson(_unwrap(resp.data));
  }

  Future<CaisseZoneEntity> fermerCaisseZone(int id) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.caisseZoneFermer(id),
      data: {},
    );
    return CaisseZoneModel.fromJson(_unwrap(resp.data));
  }

  // ─── Caisse entreprise ────────────────────────────────────────────────────────

  Future<CaisseEntrepriseEntity?> getCaisseEntreprise() async {
    try {
      final resp = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.caisseEntrepriseMe,
      );
      final data = _unwrap(resp.data);
      return CaisseEntrepriseModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _results(Map<String, dynamic>? raw) {
    if (raw == null) return [];
    final d = raw['data'];
    final src = d is Map<String, dynamic> ? d : raw;
    final r = src['results'] ?? src;
    if (r is List) return r.cast<Map<String, dynamic>>();
    return [];
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    final d = raw['data'];
    return d is Map<String, dynamic> ? d : raw;
  }
}
