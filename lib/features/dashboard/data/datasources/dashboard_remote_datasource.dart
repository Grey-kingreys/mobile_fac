import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:djoulagest_mobile/features/dashboard/domain/entities/kpi_entity.dart';

class DashboardRemoteDatasource {
  const DashboardRemoteDatasource(this._api);
  final ApiClient _api;

  Future<DashboardDataEntity> getDashboard(UserEntity user) {
    return switch (user.role) {
      'superadmin' => _superadminDashboard(),
      'admin' || 'superviseur' => _adminDashboard(),
      'gestionnaire_stock' => _stockDashboard(),
      'caissier' => _caissierDashboard(),
      'chauffeur' => _chauffeurDashboard(),
      'maintenancier' => _maintenancierDashboard(),
      'commercial' => _commercialDashboard(),
      _ => Future.value(const DashboardDataEntity()),
    };
  }

  // ─── Superadmin ─────────────────────────────────────────────────────────────

  Future<DashboardDataEntity> _superadminDashboard() async {
    try {
      final data = _unwrap(await _safeGet(ApiEndpoints.superadminDashboard));
      final companies = data['companies'] as Map<String, dynamic>? ?? {};
      final users = data['users'] as Map<String, dynamic>? ?? {};

      final total = _int(companies['total']);
      final actives = _int(companies['actives'] ?? companies['active']);
      final inactives = _int(companies['inactives'] ?? companies['inactive']);
      final totalUsers = _int(users['total'] ?? users['count']);
      final revenue = _num(data['revenue_month'] ?? data['chiffre_affaires_month']);

      return DashboardDataEntity(
        kpis: [
          KpiEntity(
            title: 'Entreprises actives',
            value: '$actives / $total',
            icon: Icons.business_rounded,
            color: const Color(0xFF1A56A0),
            subtitle: 'Sur $total au total',
            route: '/admin',
          ),
          KpiEntity(
            title: 'Utilisateurs',
            value: AppFormatters.number(totalUsers),
            icon: Icons.people_rounded,
            color: const Color(0xFF0E9F6E),
            subtitle: 'Toutes entreprises',
            route: '/hr',
          ),
          KpiEntity(
            title: 'Suspendues',
            value: '$inactives',
            icon: Icons.pause_circle_rounded,
            color: inactives > 0 ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
            subtitle: 'Entreprises inactives',
            higherIsBetter: false,
            route: '/admin',
          ),
          if (revenue > 0)
            KpiEntity(
              title: 'CA mensuel',
              value: AppFormatters.gnf(revenue),
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFF59E0B),
              subtitle: 'Toutes sociétés',
            ),
        ],
        alerts: [
          if (inactives > 0)
            AlertEntity(
              message:
                  '$inactives entreprise${inactives > 1 ? 's' : ''} suspendue${inactives > 1 ? 's' : ''}',
              level: AlertLevel.warning,
              icon: Icons.business_rounded,
              route: '/admin',
            ),
        ],
      );
    } catch (_) {
      return const DashboardDataEntity();
    }
  }

  // ─── Admin / Superviseur ────────────────────────────────────────────────────

  Future<DashboardDataEntity> _adminDashboard() async {
    final results = await Future.wait([
      _safeGet(ApiEndpoints.analyticsFinance),
      _safeGet(ApiEndpoints.analyticsStock),
      _safeGet(ApiEndpoints.users, params: {'page_size': '1'}),
    ]);

    final finance = _unwrap(results[0]);
    final stock = _unwrap(results[1]);
    final usersResp = results[2];

    final caJour = _num(finance['chiffre_affaires_jour'] ?? finance['ca_jour']);
    final sessions = _int(finance['sessions_ouvertes'] ?? finance['sessions_actives']);
    final alertes = _int(stock['produits_en_alerte'] ?? stock['alertes_stock']);
    final totalUsers = _int(usersResp['count']);

    return DashboardDataEntity(
      kpis: [
        KpiEntity(
          title: 'CA aujourd\'hui',
          value: caJour > 0 ? AppFormatters.gnf(caJour) : '—',
          icon: Icons.point_of_sale_rounded,
          color: const Color(0xFF1A56A0),
          subtitle: 'Chiffre d\'affaires',
          route: '/finance',
        ),
        KpiEntity(
          title: 'Sessions actives',
          value: '$sessions',
          icon: Icons.lock_open_rounded,
          color: const Color(0xFF0E9F6E),
          subtitle: 'Caisses ouvertes',
          route: '/finance',
        ),
        KpiEntity(
          title: 'Alertes stock',
          value: '$alertes',
          icon: Icons.inventory_2_rounded,
          color: alertes > 0 ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
          subtitle: 'Produits sous seuil',
          higherIsBetter: false,
          route: '/inventory',
        ),
        KpiEntity(
          title: 'Équipe',
          value: AppFormatters.number(totalUsers),
          icon: Icons.people_rounded,
          color: const Color(0xFF3B82F6),
          subtitle: 'Utilisateurs actifs',
          route: '/hr',
        ),
      ],
      alerts: [
        if (alertes > 0)
          AlertEntity(
            message: '$alertes produit${alertes > 1 ? 's' : ''} sous le seuil minimum',
            level: AlertLevel.warning,
            icon: Icons.inventory_2_rounded,
            route: '/inventory',
          ),
      ],
    );
  }

  // ─── Gestionnaire stock ─────────────────────────────────────────────────────

  Future<DashboardDataEntity> _stockDashboard() async {
    final stock = _unwrap(await _safeGet(ApiEndpoints.analyticsStock));

    final alertes = _int(stock['produits_en_alerte'] ?? stock['alertes_stock']);
    final mouvements = _int(stock['mouvements_jour'] ?? stock['mouvements_aujourd_hui']);
    final transferts = _int(stock['transferts_en_attente'] ?? stock['transferts_pending']);
    final valeur = _num(stock['valeur_stock_total'] ?? stock['valeur_total']);

    return DashboardDataEntity(
      kpis: [
        KpiEntity(
          title: 'Alertes stock',
          value: '$alertes',
          icon: Icons.warning_amber_rounded,
          color: alertes > 0 ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
          subtitle: 'Produits sous seuil',
          higherIsBetter: false,
          route: '/inventory',
        ),
        KpiEntity(
          title: 'Transferts en attente',
          value: '$transferts',
          icon: Icons.swap_horiz_rounded,
          color: transferts > 0 ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
          subtitle: 'À traiter',
          route: '/inventory/transfer',
        ),
        KpiEntity(
          title: 'Mouvements aujourd\'hui',
          value: '$mouvements',
          icon: Icons.compare_arrows_rounded,
          color: const Color(0xFF1A56A0),
          subtitle: 'Entrées + sorties',
          route: '/inventory/movements',
        ),
        if (valeur > 0)
          KpiEntity(
            title: 'Valeur du stock',
            value: AppFormatters.gnf(valeur),
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF0E9F6E),
            subtitle: 'Stock total',
          ),
      ],
      alerts: [
        if (alertes > 0)
          AlertEntity(
            message: '$alertes produit${alertes > 1 ? 's' : ''} sous le seuil minimum',
            level: AlertLevel.danger,
            icon: Icons.inventory_2_rounded,
            route: '/inventory',
          ),
        if (transferts > 0)
          AlertEntity(
            message: '$transferts transfert${transferts > 1 ? 's' : ''} en attente de traitement',
            level: AlertLevel.warning,
            icon: Icons.swap_horiz_rounded,
            route: '/inventory/transfer',
          ),
      ],
    );
  }

  // ─── Caissier ───────────────────────────────────────────────────────────────

  Future<DashboardDataEntity> _caissierDashboard() async {
    final results = await Future.wait([
      _safeGet(ApiEndpoints.analyticsFinance),
      _safeGet(ApiEndpoints.sessionsCaisse, params: {'statut': 'ouverte', 'page_size': '1'}),
    ]);

    final finance = _unwrap(results[0]);
    final sessionsResp = results[1];
    final sessions = sessionsResp['results'] as List<dynamic>? ?? [];

    final isOpen = sessions.isNotEmpty;
    final caJour = _num(finance['chiffre_affaires_jour'] ?? finance['ca_jour']);
    final nbTx = _int(finance['transactions_jour'] ?? finance['nb_transactions_aujourd_hui']);
    final solde = _num(finance['solde_caisse'] ?? finance['solde_estime']);

    return DashboardDataEntity(
      kpis: [
        KpiEntity(
          title: 'Session caisse',
          value: isOpen ? 'Ouverte' : 'Fermée',
          icon: isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
          color: isOpen ? const Color(0xFF0E9F6E) : const Color(0xFFEF4444),
          subtitle: isOpen ? 'Active en ce moment' : 'Aucune session ouverte',
          route: '/finance',
        ),
        KpiEntity(
          title: 'Ventes aujourd\'hui',
          value: caJour > 0 ? AppFormatters.gnf(caJour) : '—',
          icon: Icons.shopping_cart_rounded,
          color: const Color(0xFF1A56A0),
          subtitle: 'Chiffre d\'affaires',
          route: '/sales',
        ),
        KpiEntity(
          title: 'Transactions',
          value: '$nbTx',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF3B82F6),
          subtitle: 'Aujourd\'hui',
          route: '/finance/transactions',
        ),
        if (solde > 0)
          KpiEntity(
            title: 'Solde caisse',
            value: AppFormatters.gnf(solde),
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF0E9F6E),
            subtitle: 'Solde estimé',
          ),
      ],
      alerts: [
        if (!isOpen)
          const AlertEntity(
            message: 'Aucune session caisse ouverte',
            level: AlertLevel.warning,
            icon: Icons.lock_rounded,
            route: '/finance',
          ),
      ],
    );
  }

  // ─── Chauffeur ──────────────────────────────────────────────────────────────

  Future<DashboardDataEntity> _chauffeurDashboard() async {
    final missionsData =
        await _safeGet(ApiEndpoints.missions, params: {'page_size': '10', 'ordering': '-created_at'});

    final missions =
        (missionsData['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final total = _int(missionsData['count']);
    final enCours = missions
        .where((m) =>
            m['statut'] == 'en_transit' ||
            m['statut'] == 'chargement' ||
            m['statut'] == 'arrivee')
        .length;
    final planifiees = missions.where((m) => m['statut'] == 'planifiee').length;

    return DashboardDataEntity(
      kpis: [
        KpiEntity(
          title: 'Missions en cours',
          value: '$enCours',
          icon: Icons.local_shipping_rounded,
          color: enCours > 0 ? const Color(0xFFF97316) : const Color(0xFF9CA3AF),
          subtitle: enCours > 0 ? 'Transport actif' : 'Aucune mission active',
          route: '/logistics',
        ),
        KpiEntity(
          title: 'Planifiées',
          value: '$planifiees',
          icon: Icons.schedule_rounded,
          color: const Color(0xFF1A56A0),
          subtitle: 'À venir',
          route: '/logistics',
        ),
        KpiEntity(
          title: 'Total missions',
          value: AppFormatters.number(total),
          icon: Icons.route_rounded,
          color: const Color(0xFF0E9F6E),
          subtitle: 'Historique',
          route: '/logistics',
        ),
      ],
      alerts: [
        if (enCours > 0)
          AlertEntity(
            message: '$enCours mission${enCours > 1 ? 's' : ''} en cours — GPS actif',
            level: AlertLevel.info,
            icon: Icons.gps_fixed_rounded,
            route: '/logistics',
          ),
      ],
    );
  }

  // ─── Maintenancier ──────────────────────────────────────────────────────────

  Future<DashboardDataEntity> _maintenancierDashboard() async {
    final results = await Future.wait([
      _safeGet(ApiEndpoints.maintenances, params: {'statut': 'planifiee', 'page_size': '1'}),
      _safeGet(ApiEndpoints.pannes, params: {'statut': 'ouverte', 'page_size': '1'}),
    ]);

    final planifiees = _int(results[0]['count']);
    final pannes = _int(results[1]['count']);

    return DashboardDataEntity(
      kpis: [
        KpiEntity(
          title: 'Pannes ouvertes',
          value: '$pannes',
          icon: Icons.build_rounded,
          color: pannes > 0 ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
          subtitle: 'Véhicules en panne',
          higherIsBetter: false,
          route: '/logistics',
        ),
        KpiEntity(
          title: 'Maintenances planifiées',
          value: '$planifiees',
          icon: Icons.engineering_rounded,
          color: const Color(0xFF1A56A0),
          subtitle: 'À effectuer',
          route: '/logistics',
        ),
      ],
      alerts: [
        if (pannes > 0)
          AlertEntity(
            message:
                '$pannes véhicule${pannes > 1 ? 's' : ''} en panne non résolue${pannes > 1 ? 's' : ''}',
            level: AlertLevel.danger,
            icon: Icons.car_crash_rounded,
            route: '/logistics',
          ),
      ],
    );
  }

  // ─── Commercial ─────────────────────────────────────────────────────────────

  Future<DashboardDataEntity> _commercialDashboard() async {
    final results = await Future.wait([
      _safeGet(ApiEndpoints.analyticsVentes),
      _safeGet(ApiEndpoints.devis, params: {'statut': 'en_attente', 'page_size': '1'}),
    ]);

    final ventes = _unwrap(results[0]);
    final devisData = results[1];

    final caJour = _num(ventes['chiffre_affaires_jour'] ?? ventes['ca_jour']);
    final caMois = _num(ventes['chiffre_affaires_mois'] ?? ventes['ca_mois']);
    final devisAttente = _int(devisData['count']);
    final nouveauxClients = _int(ventes['nouveaux_clients_mois'] ?? ventes['clients_mois']);

    return DashboardDataEntity(
      kpis: [
        KpiEntity(
          title: 'CA aujourd\'hui',
          value: caJour > 0 ? AppFormatters.gnf(caJour) : '—',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF1A56A0),
          subtitle: 'Chiffre d\'affaires',
          route: '/sales',
        ),
        KpiEntity(
          title: 'CA ce mois',
          value: caMois > 0 ? AppFormatters.gnf(caMois) : '—',
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFF0E9F6E),
          subtitle: 'Mois en cours',
          route: '/sales',
        ),
        KpiEntity(
          title: 'Devis en attente',
          value: '$devisAttente',
          icon: Icons.description_rounded,
          color: devisAttente > 0 ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
          subtitle: 'À convertir',
          route: '/sales',
        ),
        KpiEntity(
          title: 'Nouveaux clients',
          value: '$nouveauxClients',
          icon: Icons.person_add_rounded,
          color: const Color(0xFF3B82F6),
          subtitle: 'Ce mois',
          route: '/sales/clients',
        ),
      ],
      alerts: [
        if (devisAttente > 0)
          AlertEntity(
            message: '$devisAttente devis en attente de réponse client',
            level: AlertLevel.info,
            icon: Icons.description_rounded,
            route: '/sales',
          ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _safeGet(
    String endpoint, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final resp = await _api.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: params,
      );
      return resp.data ?? {};
    } catch (_) {
      return {};
    }
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

  static num _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }
}
