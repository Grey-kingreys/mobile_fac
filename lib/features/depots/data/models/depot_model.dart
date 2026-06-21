import 'package:djoulagest_mobile/features/depots/domain/entities/depot_entity.dart';

abstract class DepotModel {
  static DepotEntity fromJson(Map<String, dynamic> json) {
    final zone = json['zone'];
    final zoneId = zone is Map ? zone['id'] as int? : json['zone_id'] as int?;
    final zoneName = zone is Map
        ? zone['name'] as String? ?? ''
        : json['zone_name'] as String? ?? '';

    double? coord(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());

    return DepotEntity(
      id: json['id'] as int,
      nom: json['name'] as String? ?? '',
      code: json['code'] as String?,
      zoneId: zoneId ?? 0,
      zoneName: zoneName,
      adresse: json['address'] as String?,
      latitude: coord(json['latitude']),
      longitude: coord(json['longitude']),
      gestionnaireId: json['gestionnaire'] is Map
          ? json['gestionnaire']['id'] as int?
          : json['gestionnaire_id'] as int?,
      gestionnaireName: json['gestionnaire'] is Map
          ? '${json['gestionnaire']['first_name'] ?? ''} ${json['gestionnaire']['last_name'] ?? ''}'.trim()
          : json['gestionnaire_nom'] as String?,
      companyId: (json['company_id'] ?? json['company'] ?? 0) as int,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> toJson({
    required String nom,
    required String code,
    required int zoneId,
    String? adresse,
    double? latitude,
    double? longitude,
  }) {
    return {
      'name': nom,
      'code': code,
      'zone_id': zoneId,
      if (adresse != null && adresse.isNotEmpty) 'address': adresse,
      // Backend = DecimalField(max_digits=9, decimal_places=6) → max 6 décimales.
      // Le sélecteur de carte renvoie un double haute précision : on arrondit
      // sinon le backend renvoie 400 (« pas plus de 6 chiffres après la virgule »).
      if (latitude != null) 'latitude': latitude.toStringAsFixed(6),
      if (longitude != null) 'longitude': longitude.toStringAsFixed(6),
    };
  }
}
