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
    super.distanceM,
    super.dansPerimetre,
    super.referenceGeo,
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
        distanceM: (j['distance_m'] as num?)?.toInt(),
        dansPerimetre: j['dans_perimetre'] as bool?,
        referenceGeo: j['reference_geo'] as String?,
      );
}

class PresenceTodayStatusModel extends PresenceTodayStatus {
  const PresenceTodayStatusModel({
    required super.aFicheEmploye,
    required super.dejaPointe,
    super.presence,
  });

  factory PresenceTodayStatusModel.fromJson(Map<String, dynamic> j) =>
      PresenceTodayStatusModel(
        aFicheEmploye: j['a_fiche_employe'] as bool? ?? false,
        dejaPointe: j['deja_pointe'] as bool? ?? false,
        presence: j['presence'] != null
            ? PresenceModel.fromJson(j['presence'] as Map<String, dynamic>)
            : null,
      );
}

class PresenceRecapModel extends PresenceRecap {
  const PresenceRecapModel({
    required super.date,
    required super.effectif,
    required super.nbPresents,
    required super.nbAbsents,
    required super.absents,
  });

  factory PresenceRecapModel.fromJson(Map<String, dynamic> j) {
    final list = (j['absents'] as List?) ?? const [];
    return PresenceRecapModel(
      date: j['date'] as String? ?? '',
      effectif: j['effectif'] as int? ?? 0,
      nbPresents: j['nb_presents'] as int? ?? 0,
      nbAbsents: j['nb_absents'] as int? ?? 0,
      absents: list
          .map((e) => RecapAbsent(
                employe: (e['employe'] as num?)?.toInt() ?? 0,
                employeNom: e['employe_nom'] as String? ?? '',
                matricule: e['matricule'] as String? ?? '',
                depotNom: e['depot_nom'] as String?,
              ))
          .toList(),
    );
  }
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
    super.motifTraitement,
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
        motifTraitement: j['motif_traitement'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );
}
