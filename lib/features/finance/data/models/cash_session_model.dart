import 'package:djoulagest_mobile/features/finance/domain/entities/cash_session_entity.dart';

abstract class CashSessionModel {
  static CashSessionEntity fromJson(Map<String, dynamic> json) {
    return CashSessionEntity(
      id: json['id'] as int,
      statut: json['statut'] as String? ?? 'ouverte',
      dateOuverture: DateTime.tryParse(
            json['ouvert_le'] as String? ?? '',
          ) ??
          DateTime.now(),
      dateFermeture: json['ferme_le'] != null
          ? DateTime.tryParse(json['ferme_le'] as String)
          : null,
      soldeOuverture: (json['solde_ouverture'] as num?) ?? 0,
      soldeFermeture: json['solde_fermeture_theorique'] as num?,
      soldeReel: json['solde_fermeture_reel'] as num?,
      ecart: json['ecart'] as num?,
      motifEcart:
          json['motif_ecart'] as String? ?? json['motif'] as String?,
      caissierId: json['caissier'] as int? ??
          (json['caissier_id'] as int?) ??
          0,
      caissierNom: json['caissier_nom'] as String? ??
          json['caissier_name'] as String? ??
          '',
      caisseId: json['caisse'] as int? ?? json['caisse_id'] as int?,
      caisseNom:
          json['caisse_nom'] as String? ?? json['caisse_name'] as String?,
      nombreTransactions:
          json['nombre_transactions'] as int? ?? json['nb_transactions'] as int?,
      totalEntrees:
          json['total_entrees'] as num? ?? json['montant_entrees'] as num?,
      totalSorties:
          json['total_sorties'] as num? ?? json['montant_sorties'] as num?,
    );
  }
}
