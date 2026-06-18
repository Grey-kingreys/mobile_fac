import 'package:equatable/equatable.dart';

class EmployeeEntity extends Equatable {
  const EmployeeEntity({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.nomComplet,
    required this.poste,
    this.depot,
    this.depotNom,
    required this.statut,
    required this.statutLabel,
    this.telephone,
    this.createdAt,
  });

  final int id;
  final String matricule;
  final String nom;
  final String prenom;
  final String nomComplet;
  final String poste;
  final int? depot;
  final String? depotNom;
  final String statut;
  final String statutLabel;
  final String? telephone;
  final DateTime? createdAt;

  bool get isActif => statut == 'actif';

  @override
  List<Object?> get props =>
      [id, matricule, nom, prenom, poste, statut, depot];
}
