import 'package:equatable/equatable.dart';

class PresenceEntity extends Equatable {
  const PresenceEntity({
    required this.id,
    required this.employe,
    required this.employeNom,
    required this.date,
    required this.typePresence,
    required this.typeLabel,
    this.heureArrivee,
    this.heureDepart,
    this.observations,
  });

  final int id;
  final int employe;
  final String employeNom;
  final String date;
  final String typePresence;
  final String typeLabel;
  final String? heureArrivee;
  final String? heureDepart;
  final String? observations;

  @override
  List<Object?> get props => [id, employe, date, typePresence];
}

class CongeEntity extends Equatable {
  const CongeEntity({
    required this.id,
    required this.employe,
    required this.employeNom,
    required this.typeConge,
    required this.typeLabel,
    required this.dateDebut,
    required this.dateFin,
    required this.nbJours,
    required this.statut,
    required this.statutLabel,
    this.motif,
    this.createdAt,
  });

  final int id;
  final int employe;
  final String employeNom;
  final String typeConge;
  final String typeLabel;
  final String dateDebut;
  final String dateFin;
  final int nbJours;
  final String statut;
  final String statutLabel;
  final String? motif;
  final DateTime? createdAt;

  bool get isApprouve => statut == 'approuve';
  bool get isEnAttente => statut == 'en_attente';
  bool get isRefuse => statut == 'refuse';

  @override
  List<Object?> get props => [id, employe, dateDebut, statut];
}
