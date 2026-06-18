import 'package:equatable/equatable.dart';

class SaleEntity extends Equatable {
  const SaleEntity({
    required this.id,
    required this.numero,
    required this.statut,
    required this.statutLabel,
    this.client,
    required this.clientNom,
    this.depot,
    required this.montantTtc,
    required this.remise,
    required this.montantPaye,
    required this.resteAPayer,
    this.modePaiement,
    this.nbLignes,
    required this.createdAt,
  });

  final int id;
  final String numero;
  final String statut;
  final String statutLabel;
  final int? client;
  final String clientNom;
  final int? depot;
  final num montantTtc;
  final num remise;
  final num montantPaye;
  final num resteAPayer;
  final String? modePaiement;
  final int? nbLignes;
  final DateTime createdAt;

  bool get isEnCours => statut == 'en_cours';
  bool get isLivree => statut == 'livree';
  bool get isAnnulee => statut == 'annulee';
  bool get isSolde => resteAPayer <= 0;

  @override
  List<Object?> get props => [id, numero, statut, montantTtc, createdAt];
}
