import 'package:djoulagest_mobile/features/finance/domain/entities/caisse_entity.dart';

abstract class CaissePhysiqueModel {
  static CaissePhysiqueEntity fromJson(Map<String, dynamic> j) {
    return CaissePhysiqueEntity(
      id: j['id'] as int,
      nom: j['nom'] as String? ?? '',
      depot: j['depot'] as int,
      depotNom: j['depot_nom'] as String? ?? '',
      devise: j['devise'] as String? ?? 'GNF',
      soldeActuel: _d(j['solde_actuel']),
      statut: j['statut'] as String? ?? '',
      statutLabel: j['statut_label'] as String? ?? '',
      isActive: j['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      fermeeLe: j['fermee_le'] != null
          ? DateTime.tryParse(j['fermee_le'] as String)
          : null,
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

abstract class CaisseZoneModel {
  static CaisseZoneEntity fromJson(Map<String, dynamic> j) {
    return CaisseZoneEntity(
      id: j['id'] as int,
      nom: j['nom'] as String? ?? '',
      zone: j['zone'] as int,
      zoneNom: j['zone_nom'] as String? ?? '',
      devise: j['devise'] as String? ?? 'GNF',
      soldeActuel: _d(j['solde_actuel']),
      statut: j['statut'] as String? ?? '',
      statutLabel: j['statut_label'] as String? ?? '',
      isActive: j['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      fermeeLe: j['fermee_le'] != null
          ? DateTime.tryParse(j['fermee_le'] as String)
          : null,
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

abstract class CaisseEntrepriseModel {
  static CaisseEntrepriseEntity fromJson(Map<String, dynamic> j) {
    return CaisseEntrepriseEntity(
      id: j['id'] as int,
      nom: j['nom'] as String? ?? '',
      company: j['company'] as int,
      companyNom: j['company_nom'] as String? ?? '',
      devise: j['devise'] as String? ?? 'GNF',
      soldeActuel: _d(j['solde_actuel']),
      isActive: j['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
