import 'package:equatable/equatable.dart';

class CaissePhysiqueEntity extends Equatable {
  const CaissePhysiqueEntity({
    required this.id,
    required this.nom,
    required this.depot,
    required this.depotNom,
    this.devise = 'GNF',
    required this.soldeActuel,
    required this.statut,
    required this.statutLabel,
    required this.isActive,
    required this.createdAt,
    this.fermeeLe,
  });

  final int id;
  final String nom;
  final int depot;
  final String depotNom;
  final String devise;
  final double soldeActuel;
  final String statut;
  final String statutLabel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? fermeeLe;

  bool get isOuverte => statut == 'ouverte';

  @override
  List<Object?> get props => [id];
}

class CaisseZoneEntity extends Equatable {
  const CaisseZoneEntity({
    required this.id,
    required this.nom,
    required this.zone,
    required this.zoneNom,
    this.devise = 'GNF',
    required this.soldeActuel,
    required this.statut,
    required this.statutLabel,
    required this.isActive,
    required this.createdAt,
    this.fermeeLe,
  });

  final int id;
  final String nom;
  final int zone;
  final String zoneNom;
  final String devise;
  final double soldeActuel;
  final String statut;
  final String statutLabel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? fermeeLe;

  bool get isOuverte => statut == 'ouverte';

  @override
  List<Object?> get props => [id];
}

class CaisseEntrepriseEntity extends Equatable {
  const CaisseEntrepriseEntity({
    required this.id,
    required this.nom,
    required this.company,
    required this.companyNom,
    this.devise = 'GNF',
    required this.soldeActuel,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String nom;
  final int company;
  final String companyNom;
  final String devise;
  final double soldeActuel;
  final bool isActive;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id];
}
