import 'package:djoulagest_mobile/features/products/domain/entities/product_entity.dart';

class ProductModel {
  const ProductModel({
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
  final String? categorieNom;
  final String? uniteSymbole;
  final num prixAchat;
  final num prixVente;
  final num marge;
  final num? seuilAlerte;
  final bool estPerimable;
  final bool isActive;
  final DateTime createdAt;
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

  factory ProductModel.fromJson(Map<String, dynamic> j) {
    return ProductModel(
      id: j['id'] as int,
      reference: j['reference'] as String? ?? '',
      nom: j['nom'] as String? ?? '',
      categorieNom: j['categorie_nom'] as String?,
      uniteSymbole: j['unite_symbole'] as String?,
      prixAchat: j['prix_achat'] as num? ?? 0,
      prixVente: j['prix_vente'] as num? ?? 0,
      marge: (j['marge'] as num?) ?? 0,
      seuilAlerte: j['seuil_alerte'] as num?,
      estPerimable: j['est_perimable'] as bool? ?? false,
      isActive: j['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(j['created_at'] as String),
      description: j['description'] as String?,
      imageUrl: j['image'] as String?,
      categorieId: j['categorie'] as int?,
      uniteId: j['unite'] as int?,
      uniteNom: j['unite_nom'] as String?,
      fournisseurId: j['fournisseur_principal'] as int?,
      fournisseurNom: j['fournisseur_nom'] as String?,
      tvaTaux: j['tva_taux'] as num?,
      seuilMax: j['seuil_max'] as num?,
      updatedAt: j['updated_at'] != null
          ? DateTime.parse(j['updated_at'] as String)
          : null,
    );
  }

  ProductEntity toEntity() => ProductEntity(
        id: id,
        reference: reference,
        nom: nom,
        categorieNom: categorieNom,
        uniteSymbole: uniteSymbole,
        prixAchat: prixAchat,
        prixVente: prixVente,
        marge: marge,
        seuilAlerte: seuilAlerte,
        estPerimable: estPerimable,
        isActive: isActive,
        createdAt: createdAt,
        description: description,
        imageUrl: imageUrl,
        categorieId: categorieId,
        uniteId: uniteId,
        uniteNom: uniteNom,
        fournisseurId: fournisseurId,
        fournisseurNom: fournisseurNom,
        tvaTaux: tvaTaux,
        seuilMax: seuilMax,
        updatedAt: updatedAt,
      );
}
