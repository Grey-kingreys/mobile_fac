import 'package:equatable/equatable.dart';

/// Période de filtrage des rapports (miroir du front web).
enum ReportPeriod {
  today('today', "Aujourd'hui"),
  week('week', 'Cette semaine'),
  month('month', 'Ce mois'),
  year('year', 'Cette année');

  const ReportPeriod(this.value, this.label);
  final String value;
  final String label;
}

/// Données agrégées des 3 endpoints analytics : ventes, stock, finance.
/// Chaque bloc est nullable (l'endpoint correspondant peut échouer
/// indépendamment, exactement comme côté web avec `catchError(() => of(null))`).
class ReportData extends Equatable {
  const ReportData({this.ventes, this.stock, this.finance});

  final VentesAnalytics? ventes;
  final StockAnalytics? stock;
  final FinanceAnalytics? finance;

  bool get isEmpty =>
      (ventes?.nbCommandes ?? 0) == 0 &&
      (stock?.nbProduitsEnAlerte ?? 0) == 0 &&
      (finance?.solde ?? 0) == 0;

  @override
  List<Object?> get props => [ventes, stock, finance];
}

// ─── Ventes ───────────────────────────────────────────────────────────────────

class VentesAnalytics extends Equatable {
  const VentesAnalytics({
    required this.nbCommandes,
    required this.caHt,
    required this.caTtc,
    required this.tvaTotal,
    required this.montantPaye,
    required this.parDepot,
  });

  final int nbCommandes;
  final num caHt;
  final num caTtc;
  final num tvaTotal;
  final num montantPaye;
  final List<DepotCa> parDepot;

  @override
  List<Object?> get props =>
      [nbCommandes, caHt, caTtc, tvaTotal, montantPaye, parDepot];
}

class DepotCa extends Equatable {
  const DepotCa({
    required this.depotCode,
    required this.depotNom,
    required this.nbCommandes,
    required this.caTtc,
  });

  final String depotCode;
  final String depotNom;
  final int nbCommandes;
  final num caTtc;

  @override
  List<Object?> get props => [depotCode, depotNom, nbCommandes, caTtc];
}

// ─── Stock ──────────────────────────────────────────────────────────────────

class StockAnalytics extends Equatable {
  const StockAnalytics({
    required this.nbProduitsEnAlerte,
    required this.produitsEnAlerte,
    required this.topProduitsSortie,
  });

  final int nbProduitsEnAlerte;
  final List<ProduitAlerte> produitsEnAlerte;
  final List<ProduitSortie> topProduitsSortie;

  @override
  List<Object?> get props =>
      [nbProduitsEnAlerte, produitsEnAlerte, topProduitsSortie];
}

class ProduitAlerte extends Equatable {
  const ProduitAlerte({
    required this.produitNom,
    required this.produitReference,
    required this.depotCode,
    required this.quantite,
    required this.seuil,
  });

  final String produitNom;
  final String produitReference;
  final String depotCode;
  final String quantite;
  final String seuil;

  @override
  List<Object?> get props =>
      [produitNom, produitReference, depotCode, quantite, seuil];
}

class ProduitSortie extends Equatable {
  const ProduitSortie({
    required this.reference,
    required this.nom,
    required this.totalSortie,
  });

  final String reference;
  final String nom;
  final String totalSortie;

  @override
  List<Object?> get props => [reference, nom, totalSortie];
}

// ─── Finance ──────────────────────────────────────────────────────────────────

class FinanceAnalytics extends Equatable {
  const FinanceAnalytics({
    required this.recettes,
    required this.depenses,
    required this.solde,
    required this.creancesClients,
    required this.nbClientsEnRetard,
  });

  final num recettes;
  final num depenses;
  final num solde;
  final num creancesClients;
  final int nbClientsEnRetard;

  @override
  List<Object?> get props =>
      [recettes, depenses, solde, creancesClients, nbClientsEnRetard];
}
