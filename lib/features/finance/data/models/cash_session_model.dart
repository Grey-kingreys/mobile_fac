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
      soldeOuverture: _num(json['solde_ouverture']),
      soldeFermeture: _numN(json['solde_fermeture_theorique']),
      soldeReel: _numN(json['solde_fermeture_reel']),
      ecart: _numN(json['ecart']),
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
          _numN(json['total_entrees'] ?? json['montant_entrees']),
      totalSorties:
          _numN(json['total_sorties'] ?? json['montant_sorties']),
    );
  }

  // DecimalField DRF → string → parsing robuste.
  static num _num(dynamic v) =>
      v is num ? v : (num.tryParse(v?.toString() ?? '') ?? 0);
  static num? _numN(dynamic v) =>
      v == null ? null : (v is num ? v : num.tryParse(v.toString()));
}
