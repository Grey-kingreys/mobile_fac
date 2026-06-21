import 'package:djoulagest_mobile/features/zones/domain/entities/zone_entity.dart';

abstract class ZoneModel {
  static ZoneEntity fromJson(Map<String, dynamic> json) {
    double? coord(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());

    return ZoneEntity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      latitude: coord(json['latitude']),
      longitude: coord(json['longitude']),
      companyId: (json['company_id'] ?? json['company'] ?? 0) as int,
      nombreDepots: json['depot_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> toJson({
    required String name,
    required String code,
    double? latitude,
    double? longitude,
  }) {
    return {
      'name': name,
      'code': code,
      // Backend = DecimalField(max_digits=9, decimal_places=6) → max 6 décimales.
      // Le sélecteur de carte renvoie un double haute précision : on arrondit
      // sinon le backend renvoie 400 (« pas plus de 6 chiffres après la virgule »).
      if (latitude != null) 'latitude': latitude.toStringAsFixed(6),
      if (longitude != null) 'longitude': longitude.toStringAsFixed(6),
    };
  }
}
