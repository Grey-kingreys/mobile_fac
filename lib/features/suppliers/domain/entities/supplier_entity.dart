import 'package:equatable/equatable.dart';

class SupplierEntity extends Equatable {
  const SupplierEntity({
    required this.id,
    required this.code,
    required this.nom,
    this.telephone,
    this.email,
    this.adresse,
    required this.soldeDette,
    required this.isActive,
    this.notes,
    this.createdAt,
  });

  final int id;
  final String code;
  final String nom;
  final String? telephone;
  final String? email;
  final String? adresse;
  final double soldeDette;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;

  bool get hasDette => soldeDette > 0;

  @override
  List<Object?> get props => [id, code, nom, soldeDette, isActive];
}

class SupplierEvaluationEntity extends Equatable {
  const SupplierEvaluationEntity({
    required this.id,
    required this.noteGlobale,
    required this.noteQualite,
    required this.noteDelai,
    required this.noteService,
    this.commentaire,
    this.evaluePar,
    required this.createdAt,
  });

  final int id;
  final double noteGlobale;
  final int noteQualite;
  final int noteDelai;
  final int noteService;
  final String? commentaire;
  final String? evaluePar;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, noteGlobale, createdAt];
}

class SupplierOrderLineEntity extends Equatable {
  const SupplierOrderLineEntity({
    required this.id,
    required this.produit,
    required this.produitNom,
    required this.produitReference,
    required this.quantiteCommandee,
    required this.prixUnitaire,
    required this.quantiteRecue,
    required this.montantTotal,
  });

  final int id;
  final int produit;
  final String produitNom;
  final String produitReference;
  final double quantiteCommandee;
  final double prixUnitaire;
  final double quantiteRecue;
  final double montantTotal;

  @override
  List<Object?> get props => [id, produit, quantiteCommandee];
}

class SupplierOrderEntity extends Equatable {
  const SupplierOrderEntity({
    required this.id,
    required this.numero,
    required this.fournisseur,
    required this.fournisseurNom,
    required this.depotDestination,
    required this.statut,
    required this.statutLabel,
    this.depotNom,
    this.dateLivraisonPrevue,
    this.lignes,
    required this.createdAt,
  });

  final int id;
  final int fournisseur;
  final String numero;
  final int depotDestination;
  final String fournisseurNom;
  final String statut;
  final String statutLabel;
  final String? depotNom;
  final DateTime? dateLivraisonPrevue;
  final List<SupplierOrderLineEntity>? lignes;
  final DateTime createdAt;

  bool get isPending => statut == 'en_attente';
  bool get isReceived => statut == 'recue' || statut == 'partiellement_recue';

  @override
  List<Object?> get props => [id, numero, statut];
}
