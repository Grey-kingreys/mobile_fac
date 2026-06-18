import 'package:equatable/equatable.dart';

class CashSessionEntity extends Equatable {
  const CashSessionEntity({
    required this.id,
    required this.statut,
    required this.dateOuverture,
    required this.soldeOuverture,
    required this.caissierId,
    required this.caissierNom,
    this.dateFermeture,
    this.soldeFermeture,
    this.soldeReel,
    this.ecart,
    this.motifEcart,
    this.caisseId,
    this.caisseNom,
    this.nombreTransactions,
    this.totalEntrees,
    this.totalSorties,
  });

  final int id;
  final String statut; // 'ouverte' | 'fermee'
  final DateTime dateOuverture;
  final DateTime? dateFermeture;
  final num soldeOuverture;
  final num? soldeFermeture;
  final num? soldeReel;
  final num? ecart;
  final String? motifEcart;
  final int caissierId;
  final String caissierNom;
  final int? caisseId;
  final String? caisseNom;
  final int? nombreTransactions;
  final num? totalEntrees;
  final num? totalSorties;

  bool get isOpen => statut == 'ouverte';

  // Solde calculé = ouverture + entrées - sorties
  num get soldeCalcule =>
      soldeOuverture + (totalEntrees ?? 0) - (totalSorties ?? 0);

  @override
  List<Object?> get props => [id, statut, dateOuverture];
}

class TransactionEntity extends Equatable {
  const TransactionEntity({
    required this.id,
    required this.type,
    required this.montant,
    required this.description,
    required this.createdAt,
    this.reference,
    this.sessionId,
  });

  final int id;
  final String type; // 'entree' | 'sortie'
  final num montant;
  final String description;
  final DateTime createdAt;
  final String? reference;
  final int? sessionId;

  bool get isEntree => type == 'entree';

  @override
  List<Object?> get props => [id, type, montant, createdAt];
}
