import 'package:equatable/equatable.dart';

class StockEntity extends Equatable {
  const StockEntity({
    required this.id,
    required this.depot,
    required this.depotCode,
    required this.depotNom,
    required this.produit,
    required this.produitReference,
    required this.produitNom,
    required this.quantite,
    required this.enAlerte,
    this.zoneNom,
    this.uniteSymbole,
    this.seuilAlerte,
    this.updatedAt,
  });

  final int id;
  final int depot;
  final String depotCode;
  final String depotNom;
  final String? zoneNom;
  final int produit;
  final String produitReference;
  final String produitNom;
  final String? uniteSymbole;
  final num quantite;
  final num? seuilAlerte;
  final bool enAlerte;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, depot, produit];
}

class MovementEntity extends Equatable {
  const MovementEntity({
    required this.id,
    required this.depot,
    required this.depotCode,
    required this.produit,
    required this.produitReference,
    required this.produitNom,
    required this.typeMouvement,
    required this.typeLabel,
    required this.quantite,
    required this.createdAt,
    this.quantiteAvant,
    this.quantiteApres,
    this.referenceDoc,
    this.motif,
    this.utilisateurNom,
  });

  final int id;
  final int depot;
  final String depotCode;
  final int produit;
  final String produitReference;
  final String produitNom;
  // 'entree' | 'sortie' | 'transfert' | 'inventaire' | 'ajustement'
  final String typeMouvement;
  final String typeLabel;
  final num quantite;
  final num? quantiteAvant;
  final num? quantiteApres;
  final String? referenceDoc;
  final String? motif;
  final String? utilisateurNom;
  final DateTime createdAt;

  bool get isEntree => typeMouvement == 'entree';
  bool get isSortie => typeMouvement == 'sortie';

  @override
  List<Object?> get props => [id, typeMouvement, createdAt];
}

class TransfertEntity extends Equatable {
  const TransfertEntity({
    required this.id,
    required this.numero,
    required this.depotSource,
    required this.depotSourceCode,
    required this.depotDestination,
    required this.depotDestinationCode,
    required this.statut,
    required this.statutLabel,
    required this.createdAt,
    this.nbLignes = 0,
    this.dateEnvoi,
    this.dateReception,
  });

  final int id;
  final String numero;
  final int depotSource;
  final String depotSourceCode;
  final int depotDestination;
  final String depotDestinationCode;
  // 'en_attente' | 'en_transit' | 'recu' | 'annule'
  final String statut;
  final String statutLabel;
  final int nbLignes;
  final DateTime? dateEnvoi;
  final DateTime? dateReception;
  final DateTime createdAt;

  bool get isPending => statut == 'en_attente';
  bool get isInTransit => statut == 'en_transit';
  bool get isReceived => statut == 'recu';
  bool get isCancelled => statut == 'annule';

  @override
  List<Object?> get props => [id, numero, statut];
}

class AjustementEntity extends Equatable {
  const AjustementEntity({
    required this.id,
    required this.depot,
    required this.depotCode,
    required this.produit,
    required this.produitNom,
    required this.quantite,
    required this.statut,
    required this.statutLabel,
    required this.demandeParNom,
    required this.createdAt,
    this.motif,
  });

  final int id;
  final int depot;
  final String depotCode;
  final int produit;
  final String produitNom;
  final num quantite;
  final String? motif;
  // 'en_attente' | 'approuve' | 'refuse'
  final String statut;
  final String statutLabel;
  final String demandeParNom;
  final DateTime createdAt;

  bool get isEnAttente => statut == 'en_attente';
  bool get isApprouve => statut == 'approuve';
  bool get isRefuse => statut == 'refuse';

  @override
  List<Object?> get props => [id, statut];
}
