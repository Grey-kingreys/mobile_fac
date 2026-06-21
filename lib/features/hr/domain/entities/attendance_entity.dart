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
    this.distanceM,
    this.dansPerimetre,
    this.referenceGeo,
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
  final int? distanceM;
  final bool? dansPerimetre;
  final String? referenceGeo;

  @override
  List<Object?> get props => [id, employe, date, typePresence];
}

/// État du pointage du jour de l'utilisateur connecté (self-service).
class PresenceTodayStatus extends Equatable {
  const PresenceTodayStatus({
    required this.aFicheEmploye,
    required this.dejaPointe,
    this.presence,
  });

  final bool aFicheEmploye;
  final bool dejaPointe;
  final PresenceEntity? presence;

  @override
  List<Object?> get props => [aFicheEmploye, dejaPointe, presence];
}

/// Récapitulatif présences/absences d'une journée (admin/superviseur).
class PresenceRecap extends Equatable {
  const PresenceRecap({
    required this.date,
    required this.effectif,
    required this.nbPresents,
    required this.nbAbsents,
    required this.absents,
  });

  final String date;
  final int effectif;
  final int nbPresents;
  final int nbAbsents;
  final List<RecapAbsent> absents;

  @override
  List<Object?> get props => [date, effectif, nbPresents, nbAbsents];
}

class RecapAbsent extends Equatable {
  const RecapAbsent({
    required this.employe,
    required this.employeNom,
    required this.matricule,
    this.depotNom,
  });

  final int employe;
  final String employeNom;
  final String matricule;
  final String? depotNom;

  @override
  List<Object?> get props => [employe];
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
    this.motifTraitement,
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
  final String? motifTraitement;
  final DateTime? createdAt;

  bool get isApprouve => statut == 'approuve';
  bool get isEnAttente => statut == 'en_attente';
  bool get isRefuse => statut == 'refuse';

  @override
  List<Object?> get props => [id, employe, dateDebut, statut];
}
