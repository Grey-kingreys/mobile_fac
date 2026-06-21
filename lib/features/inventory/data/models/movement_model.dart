import 'package:djoulagest_mobile/features/inventory/domain/entities/stock_entity.dart';

// DRF renvoie les DecimalField en string → parsing robuste (un cast `as num`
// planterait toute la liste : « impossible de charger »).
num _num(dynamic v) => v is num ? v : (num.tryParse(v?.toString() ?? '') ?? 0);
num? _numN(dynamic v) =>
    v == null ? null : (v is num ? v : num.tryParse(v.toString()));

abstract class MovementModel {
  static MovementEntity fromJson(Map<String, dynamic> json) {
    return MovementEntity(
      id: json['id'] as int,
      depot: json['depot'] as int? ?? 0,
      depotCode: json['depot_code'] as String? ?? '',
      produit: json['produit'] as int? ?? 0,
      produitReference: json['produit_reference'] as String? ?? '',
      produitNom: json['produit_nom'] as String? ?? '',
      typeMouvement: json['type_mouvement'] as String? ?? 'entree',
      typeLabel: json['type_label'] as String? ?? '',
      quantite: _num(json['quantite']),
      quantiteAvant: _numN(json['quantite_avant']),
      quantiteApres: _numN(json['quantite_apres']),
      referenceDoc: json['reference_doc'] as String?,
      motif: json['motif'] as String?,
      utilisateurNom: json['utilisateur_nom'] as String?,
      createdAt: DateTime.tryParse(
            json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

abstract class AjustementModel {
  static AjustementEntity fromJson(Map<String, dynamic> json) {
    return AjustementEntity(
      id: json['id'] as int,
      depot: json['depot'] as int? ?? 0,
      depotCode: json['depot_code'] as String? ?? '',
      produit: json['produit'] as int? ?? 0,
      produitNom: json['produit_nom'] as String? ?? '',
      quantite: _num(json['quantite']),
      motif: json['motif'] as String?,
      statut: json['statut'] as String? ?? 'en_attente',
      statutLabel: json['statut_label'] as String? ?? '',
      demandeParNom: json['demande_par_nom'] as String? ?? '',
      createdAt: DateTime.tryParse(
            json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

abstract class TransfertModel {
  static TransfertEntity fromJson(Map<String, dynamic> json) {
    return TransfertEntity(
      id: json['id'] as int,
      numero: json['numero'] as String? ?? '',
      depotSource: json['depot_source'] as int? ?? 0,
      depotSourceCode: json['depot_source_code'] as String? ?? '',
      depotDestination: json['depot_destination'] as int? ?? 0,
      depotDestinationCode: json['depot_destination_code'] as String? ?? '',
      statut: json['statut'] as String? ?? 'en_attente',
      statutLabel: json['statut_label'] as String? ?? '',
      nbLignes: json['nb_lignes'] as int? ?? 0,
      dateEnvoi: json['date_envoi'] != null
          ? DateTime.tryParse(json['date_envoi'] as String)
          : null,
      dateReception: json['date_reception'] != null
          ? DateTime.tryParse(json['date_reception'] as String)
          : null,
      createdAt: DateTime.tryParse(
            json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
