import 'package:djoulagest_mobile/features/products/domain/entities/category_entity.dart';

abstract class CategoryModel {
  static CategoryEntity fromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      couleur: json['couleur'] as String? ?? '#1A56A0',
      // tva_taux : DRF renvoie les DecimalField en string ("20.00") → parsing
      // robuste (un cast `as num` planterait et ferait échouer toute la liste).
      tvaTaux: _toDouble(json['tva_taux']),
      isActive: json['is_active'] as bool? ?? true,
      nombreProduits: json['nombre_produits'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
