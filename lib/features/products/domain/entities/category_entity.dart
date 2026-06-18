import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.couleur,
    required this.tvaTaux,
    required this.isActive,
    required this.nombreProduits,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String description;
  final String couleur;
  final double tvaTaux;
  final bool isActive;
  final int nombreProduits;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, couleur, tvaTaux, isActive];
}
