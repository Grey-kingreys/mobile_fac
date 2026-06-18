import 'package:equatable/equatable.dart';

class LigneMissionEntity extends Equatable {
  const LigneMissionEntity({
    required this.id,
    required this.produit,
    required this.produitNom,
    required this.produitReference,
    required this.quantite,
    this.quantiteRecue,
    this.observations,
  });

  final int id;
  final int produit;
  final String produitNom;
  final String produitReference;
  final num quantite;
  final num? quantiteRecue;
  final String? observations;

  @override
  List<Object?> get props => [id, produit, quantite];
}

class MissionEntity extends Equatable {
  const MissionEntity({
    required this.id,
    required this.numero,
    required this.statut,
    required this.statutLabel,
    this.vehicule,
    this.vehiculeImmat,
    this.chauffeur,
    this.chauffeurNom,
    this.depotDepart,
    this.depotDepartNom,
    this.depotArrivee,
    this.depotArriveeNom,
    this.transfertStock,
    this.dateDepartPrevue,
    this.dateDepartReelle,
    this.dateArriveeReelle,
    this.notes,
    this.motifLitige,
    this.lignes = const [],
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String numero;
  final String statut;
  final String statutLabel;
  final int? vehicule;
  final String? vehiculeImmat;
  final int? chauffeur;
  final String? chauffeurNom;
  final int? depotDepart;
  final String? depotDepartNom;
  final int? depotArrivee;
  final String? depotArriveeNom;
  final int? transfertStock;
  final DateTime? dateDepartPrevue;
  final DateTime? dateDepartReelle;
  final DateTime? dateArriveeReelle;
  final String? notes;
  final String? motifLitige;
  final List<LigneMissionEntity> lignes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Slugs exacts retournés par Mission.Statut (back_fac/apps/logistique/models.py)
  bool get isPlanifiee => statut == 'planifiee';
  bool get isChargement => statut == 'chargement';
  bool get isTransport => statut == 'en_transit';
  bool get isArrive => statut == 'arrivee';
  bool get isLitige => statut == 'litige';
  bool get isTerminee => statut == 'terminee';
  bool get isAnnulee => statut == 'annulee';

  @override
  List<Object?> get props => [id, numero, statut, createdAt];
}
