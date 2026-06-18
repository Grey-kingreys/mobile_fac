import 'package:equatable/equatable.dart';

class ClientEntity extends Equatable {
  const ClientEntity({
    required this.id,
    required this.code,
    required this.nom,
    this.prenom,
    required this.nomComplet,
    this.telephone,
    required this.pointsFidelite,
    required this.soldeCredit,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String code;
  final String nom;
  final String? prenom;
  final String nomComplet;
  final String? telephone;
  final num pointsFidelite;
  final num soldeCredit;
  final bool isActive;
  final DateTime createdAt;

  bool get hasCredit => soldeCredit > 0;

  @override
  List<Object?> get props => [id, code, nom, nomComplet];
}
