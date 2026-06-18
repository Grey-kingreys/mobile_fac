import 'package:djoulagest_mobile/features/suppliers/domain/entities/supplier_entity.dart';

class SupplierModel extends SupplierEntity {
  const SupplierModel({
    required super.id,
    required super.code,
    required super.nom,
    super.telephone,
    super.email,
    super.adresse,
    required super.soldeDette,
    required super.isActive,
    super.notes,
    super.createdAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> j) => SupplierModel(
        id: j['id'] as int,
        code: j['code'] as String? ?? '',
        nom: j['nom'] as String? ?? '',
        telephone: j['telephone'] as String?,
        email: j['email'] as String?,
        adresse: j['adresse'] as String?,
        soldeDette: _d(j['solde_dette']),
        isActive: j['is_active'] as bool? ?? true,
        notes: j['notes'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class SupplierEvaluationModel extends SupplierEvaluationEntity {
  const SupplierEvaluationModel({
    required super.id,
    required super.noteGlobale,
    required super.noteQualite,
    required super.noteDelai,
    required super.noteService,
    super.commentaire,
    super.evaluePar,
    required super.createdAt,
  });

  factory SupplierEvaluationModel.fromJson(Map<String, dynamic> j) =>
      SupplierEvaluationModel(
        id: j['id'] as int,
        noteGlobale: _d(j['note_globale']),
        noteQualite: j['note_qualite'] as int? ?? 0,
        noteDelai: j['note_delai'] as int? ?? 0,
        noteService: j['note_service'] as int? ?? 0,
        commentaire: j['commentaire'] as String?,
        evaluePar: j['evalue_par_nom'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class SupplierOrderLineModel extends SupplierOrderLineEntity {
  const SupplierOrderLineModel({
    required super.id,
    required super.produit,
    required super.produitNom,
    required super.produitReference,
    required super.quantiteCommandee,
    required super.prixUnitaire,
    required super.quantiteRecue,
    required super.montantTotal,
  });

  factory SupplierOrderLineModel.fromJson(Map<String, dynamic> j) =>
      SupplierOrderLineModel(
        id: j['id'] as int,
        produit: j['produit'] as int? ?? 0,
        produitNom: j['produit_nom'] as String? ?? '',
        produitReference: j['produit_reference'] as String? ?? '',
        quantiteCommandee: _d(j['quantite_commandee']),
        prixUnitaire: _d(j['prix_unitaire']),
        quantiteRecue: _d(j['quantite_recue']),
        montantTotal: _d(j['montant_total']),
      );

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class SupplierOrderModel extends SupplierOrderEntity {
  const SupplierOrderModel({
    required super.id,
    required super.numero,
    required super.fournisseur,
    required super.fournisseurNom,
    required super.depotDestination,
    required super.statut,
    required super.statutLabel,
    super.depotNom,
    super.dateLivraisonPrevue,
    super.lignes,
    required super.createdAt,
  });

  factory SupplierOrderModel.fromJson(Map<String, dynamic> j) {
    final lignesRaw = j['lignes'];
    final lignes = lignesRaw is List
        ? lignesRaw
            .map((e) => SupplierOrderLineModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : null;
    return SupplierOrderModel(
      id: j['id'] as int,
      numero: j['numero'] as String? ?? '',
      fournisseur: j['fournisseur'] as int? ?? 0,
      fournisseurNom: j['fournisseur_nom'] as String? ?? '',
      depotDestination: j['depot_destination'] as int? ?? 0,
      statut: j['statut'] as String? ?? '',
      statutLabel: j['statut_label'] as String? ?? '',
      depotNom: j['depot_nom'] as String?,
      dateLivraisonPrevue: j['date_livraison_prevue'] != null
          ? DateTime.tryParse(j['date_livraison_prevue'] as String)
          : null,
      lignes: lignes,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
