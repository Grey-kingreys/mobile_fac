import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/reports/domain/entities/report_entity.dart';

/// Consomme les 3 endpoints analytics du backend (mêmes routes que le front web) :
///   GET /analytics/ventes/?debut=YYYY-MM-DD&fin=YYYY-MM-DD
///   GET /analytics/stock/?debut=…&fin=…
///   GET /analytics/finance/?debut=…&fin=…
/// Chaque appel est isolé : un échec renvoie `null` pour ce bloc seulement
/// (parité avec le `catchError(() => of(null))` du front).
class ReportsRemoteDatasource {
  const ReportsRemoteDatasource(this._api);
  final ApiClient _api;

  Future<ReportData> getReport(ReportPeriod period) async {
    final range = _dateRange(period);
    final params = {'debut': range.$1, 'fin': range.$2};

    final results = await Future.wait([
      _safeGet(ApiEndpoints.analyticsVentes, params),
      _safeGet(ApiEndpoints.analyticsStock, params),
      _safeGet(ApiEndpoints.analyticsFinance, params),
    ]);

    return ReportData(
      ventes: _parseVentes(results[0]),
      stock: _parseStock(results[1]),
      finance: _parseFinance(results[2]),
    );
  }

  // ─── Parsing ────────────────────────────────────────────────────────────────

  VentesAnalytics? _parseVentes(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final data = _unwrap(raw);
    final totaux = data['totaux'] as Map<String, dynamic>? ?? const {};
    final depots = (data['par_depot'] as List?) ?? const [];

    return VentesAnalytics(
      nbCommandes: _int(totaux['nb_commandes']),
      caHt: _num(totaux['ca_ht']),
      caTtc: _num(totaux['ca_ttc']),
      tvaTotal: _num(totaux['tva_total']),
      montantPaye: _num(totaux['montant_paye']),
      parDepot: depots
          .whereType<Map<String, dynamic>>()
          .map((d) => DepotCa(
                depotCode: '${d['depot_code'] ?? ''}',
                depotNom: '${d['depot_nom'] ?? ''}',
                nbCommandes: _int(d['nb_commandes']),
                caTtc: _num(d['ca_ttc']),
              ))
          .toList(),
    );
  }

  StockAnalytics? _parseStock(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final data = _unwrap(raw);
    final alertes = (data['produits_en_alerte'] as List?) ?? const [];
    final tops = (data['top_produits_sortie'] as List?) ?? const [];

    return StockAnalytics(
      nbProduitsEnAlerte: _int(data['nb_produits_en_alerte']),
      produitsEnAlerte: alertes
          .whereType<Map<String, dynamic>>()
          .map((p) => ProduitAlerte(
                produitNom: '${p['produit_nom'] ?? ''}',
                produitReference: '${p['produit_reference'] ?? ''}',
                depotCode: '${p['depot_code'] ?? ''}',
                quantite: '${p['quantite'] ?? '0'}',
                seuil: '${p['seuil'] ?? '0'}',
              ))
          .toList(),
      topProduitsSortie: tops
          .whereType<Map<String, dynamic>>()
          .map((p) => ProduitSortie(
                reference: '${p['reference'] ?? ''}',
                nom: '${p['nom'] ?? ''}',
                totalSortie: '${p['total_sortie'] ?? '0'}',
              ))
          .toList(),
    );
  }

  FinanceAnalytics? _parseFinance(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final data = _unwrap(raw);
    return FinanceAnalytics(
      recettes: _num(data['recettes']),
      depenses: _num(data['depenses']),
      solde: _num(data['solde']),
      creancesClients: _num(data['creances_clients']),
      nbClientsEnRetard: _int(data['nb_clients_en_retard']),
    );
  }

  // ─── HTTP ─────────────────────────────────────────────────────────────────

  /// Renvoie `null` (et non `{}`) en cas d'échec pour distinguer
  /// « endpoint indisponible » de « données vides ».
  Future<Map<String, dynamic>?> _safeGet(
    String endpoint,
    Map<String, dynamic> params,
  ) async {
    try {
      final resp = await _api.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: params,
      );
      return resp.data;
    } catch (_) {
      return null;
    }
  }

  // ─── Helpers dates / parsing ─────────────────────────────────────────────────

  /// (debut, fin) au format YYYY-MM-DD — logique identique au front web.
  (String, String) _dateRange(ReportPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final fin = fmt(today);

    return switch (period) {
      ReportPeriod.today => (fin, fin),
      ReportPeriod.week => (fmt(today.subtract(const Duration(days: 6))), fin),
      ReportPeriod.month => (fmt(DateTime(today.year, today.month, 1)), fin),
      ReportPeriod.year => (fmt(DateTime(today.year, 1, 1)), fin),
    };
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    final d = raw['data'];
    return d is Map<String, dynamic> ? d : raw;
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // DRF renvoie les DecimalField en String → parsing robuste obligatoire.
  static num _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }
}
