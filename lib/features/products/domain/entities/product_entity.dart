import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.reference,
    required this.nom,
    required this.prixAchat,
    required this.prixVente,
    required this.marge,
    required this.estPerimable,
    required this.isActive,
    required this.createdAt,
    this.categorieNom,
    this.uniteSymbole,
    this.seuilAlerte,
    this.codeBarre,
    this.description,
    this.imageUrl,
    this.categorieId,
    this.uniteId,
    this.uniteNom,
    this.fournisseurId,
    this.fournisseurNom,
    this.tvaTaux,
    this.seuilMax,
    this.updatedAt,
  });

  final int id;
  final String reference;
  final String nom;
  final String? codeBarre;
  final String? categorieNom;
  final String? uniteSymbole;
  final num prixAchat;
  final num prixVente;
  final num marge;
  final num? seuilAlerte;
  final bool estPerimable;
  final bool isActive;
  final DateTime createdAt;

  // Champs détail uniquement
  final String? description;
  final String? imageUrl;
  final int? categorieId;
  final int? uniteId;
  final String? uniteNom;
  final int? fournisseurId;
  final String? fournisseurNom;
  final num? tvaTaux;
  final num? seuilMax;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, reference, nom, prixVente];
}
