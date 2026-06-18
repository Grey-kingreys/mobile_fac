import 'package:djoulagest_mobile/features/products/domain/entities/category_entity.dart';

abstract class CategoryModel {
  static CategoryEntity fromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      couleur: json['couleur'] as String? ?? '#1A56A0',
      tvaTaux: (json['tva_taux'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      nombreProduits: json['nombre_produits'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
