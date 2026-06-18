import 'package:djoulagest_mobile/features/inventory/domain/entities/stock_entity.dart';

abstract class StockModel {
  static StockEntity fromJson(Map<String, dynamic> json) {
    return StockEntity(
      id: json['id'] as int,
      depot: json['depot'] as int? ?? 0,
      depotCode: json['depot_code'] as String? ?? '',
      depotNom: json['depot_nom'] as String? ?? '',
      zoneNom: json['zone_nom'] as String?,
      produit: json['produit'] as int? ?? 0,
      produitReference: json['produit_reference'] as String? ?? '',
      produitNom: json['produit_nom'] as String? ?? '',
      uniteSymbole: json['unite_symbole'] as String?,
      quantite: (json['quantite'] as num?) ?? 0,
      seuilAlerte: json['seuil_alerte'] as num?,
      enAlerte: json['en_alerte'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
