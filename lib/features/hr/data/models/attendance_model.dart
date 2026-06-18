import 'package:djoulagest_mobile/features/hr/domain/entities/attendance_entity.dart';

class PresenceModel extends PresenceEntity {
  const PresenceModel({
    required super.id,
    required super.employe,
    required super.employeNom,
    required super.date,
    required super.typePresence,
    required super.typeLabel,
    super.heureArrivee,
    super.heureDepart,
    super.observations,
  });

  factory PresenceModel.fromJson(Map<String, dynamic> j) => PresenceModel(
        id: j['id'] as int,
        employe: j['employe'] as int? ?? 0,
        employeNom: j['employe_nom'] as String? ?? '',
        date: j['date'] as String? ?? '',
        typePresence: j['type_presence'] as String? ?? '',
        typeLabel: j['type_label'] as String? ?? '',
        heureArrivee: j['heure_arrivee'] as String?,
        heureDepart: j['heure_depart'] as String?,
        observations: j['observations'] as String?,
      );
}

class CongeModel extends CongeEntity {
  const CongeModel({
    required super.id,
    required super.employe,
    required super.employeNom,
    required super.typeConge,
    required super.typeLabel,
    required super.dateDebut,
    required super.dateFin,
    required super.nbJours,
    required super.statut,
    required super.statutLabel,
    super.motif,
    super.createdAt,
  });

  factory CongeModel.fromJson(Map<String, dynamic> j) => CongeModel(
        id: j['id'] as int,
        employe: j['employe'] as int? ?? 0,
        employeNom: j['employe_nom'] as String? ?? '',
        typeConge: j['type_conge'] as String? ?? '',
        typeLabel: j['type_label'] as String? ?? '',
        dateDebut: j['date_debut'] as String? ?? '',
        dateFin: j['date_fin'] as String? ?? '',
        nbJours: j['nb_jours'] as int? ?? 0,
        statut: j['statut'] as String? ?? '',
        statutLabel: j['statut_label'] as String? ?? '',
        motif: j['motif'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );
}
