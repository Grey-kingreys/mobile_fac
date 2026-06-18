import 'package:djoulagest_mobile/features/logistics/domain/entities/mission_entity.dart';

class LigneMissionModel extends LigneMissionEntity {
  const LigneMissionModel({
    required super.id,
    required super.produit,
    required super.produitNom,
    required super.produitReference,
    required super.quantite,
    super.quantiteRecue,
    super.observations,
  });

  factory LigneMissionModel.fromJson(Map<String, dynamic> j) {
    return LigneMissionModel(
      id: j['id'] as int,
      produit: j['produit'] as int,
      produitNom: j['produit_nom'] as String? ?? '',
      produitReference: j['produit_reference'] as String? ?? '',
      quantite: j['quantite'] as num? ?? 0,
      quantiteRecue: j['quantite_recue'] as num?,
      observations: j['observations'] as String?,
    );
  }
}

class MissionModel extends MissionEntity {
  const MissionModel({
    required super.id,
    required super.numero,
    required super.statut,
    required super.statutLabel,
    super.vehicule,
    super.vehiculeImmat,
    super.chauffeur,
    super.chauffeurNom,
    super.depotDepart,
    super.depotDepartNom,
    super.depotArrivee,
    super.depotArriveeNom,
    super.transfertStock,
    super.dateDepartPrevue,
    super.dateDepartReelle,
    super.dateArriveeReelle,
    super.notes,
    super.motifLitige,
    super.lignes,
    required super.createdAt,
    super.updatedAt,
  });

  factory MissionModel.fromJson(Map<String, dynamic> j) {
    final lignesRaw = j['lignes'];
    final lignes = lignesRaw is List
        ? lignesRaw
            .map((l) => LigneMissionModel.fromJson(l as Map<String, dynamic>))
            .toList()
        : <LigneMissionEntity>[];

    return MissionModel(
      id: j['id'] as int,
      numero: j['numero'] as String? ?? '',
      statut: j['statut'] as String? ?? '',
      statutLabel: j['statut_label'] as String? ?? '',
      vehicule: j['vehicule'] as int?,
      vehiculeImmat: j['vehicule_immat'] as String?,
      chauffeur: j['chauffeur'] as int?,
      chauffeurNom: j['chauffeur_nom'] as String?,
      depotDepart: j['depot_depart'] as int?,
      depotDepartNom: j['depot_depart_nom'] as String?,
      depotArrivee: j['depot_arrivee'] as int?,
      depotArriveeNom: j['depot_arrivee_nom'] as String?,
      transfertStock: j['transfert_stock'] as int?,
      dateDepartPrevue: _dt(j['date_depart_prevue']),
      dateDepartReelle: _dt(j['date_depart_reelle']),
      dateArriveeReelle: _dt(j['date_arrivee_reelle']),
      notes: j['notes'] as String?,
      motifLitige: j['motif_litige'] as String?,
      lignes: lignes,
      createdAt: _dt(j['created_at']) ?? DateTime.now(),
      updatedAt: _dt(j['updated_at']),
    );
  }

  static DateTime? _dt(dynamic v) =>
      v != null ? DateTime.tryParse(v as String) : null;
}
