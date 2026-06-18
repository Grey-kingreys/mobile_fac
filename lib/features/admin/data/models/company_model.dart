import 'package:djoulagest_mobile/features/admin/domain/entities/company_entity.dart';

abstract class CompanyModel {
  static CompanyEntity fromJson(Map<String, dynamic> json) {
    return CompanyEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      logo: json['logo'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      statut: (json['is_active'] as bool? ?? true) ? 'actif' : 'suspendu',
      subscriptionPlan: json['subscription_plan'] as String? ?? 'free',
      nombreUtilisateurs: json['user_count'] as int? ?? json['nombre_utilisateurs'] as int? ?? 0,
      nombreZones: json['zone_count'] as int? ?? json['nombre_zones'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
