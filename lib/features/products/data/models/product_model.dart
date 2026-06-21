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
      codeBarre: j['code_barre'] as String?,
      categorieNom: j['categorie_nom'] as String?,
      uniteSymbole: j['unite_symbole'] as String?,
      // DRF renvoie les DecimalField (prix, seuils, tva) en string ("5000.00") →
      // parsing robuste, un cast `as num` planterait toute la liste.
      prixAchat: _num(j['prix_achat']),
      prixVente: _num(j['prix_vente']),
      marge: _num(j['marge']),
      seuilAlerte: _numN(j['seuil_alerte']),
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
      tvaTaux: _numN(j['tva_taux']),
      seuilMax: _numN(j['seuil_max']),
      updatedAt: j['updated_at'] != null
          ? DateTime.parse(j['updated_at'] as String)
          : null,
    );
  }

  static num _num(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }

  static num? _numN(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  ProductEntity toEntity() => ProductEntity(
        id: id,
        reference: reference,
        nom: nom,
        codeBarre: codeBarre,
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
