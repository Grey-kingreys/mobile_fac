import 'package:djoulagest_mobile/features/sales/domain/entities/sale_entity.dart';

class SaleModel extends SaleEntity {
  const SaleModel({
    required super.id,
    required super.numero,
    required super.statut,
    required super.statutLabel,
    super.client,
    required super.clientNom,
    super.depot,
    required super.montantTtc,
    required super.remise,
    required super.montantPaye,
    required super.resteAPayer,
    super.modePaiement,
    super.nbLignes,
    required super.createdAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> j) {
    return SaleModel(
      id: j['id'] as int,
      numero: j['numero'] as String? ?? '',
      statut: j['statut'] as String? ?? '',
      statutLabel: j['statut_label'] as String? ?? '',
      client: j['client'] as int?,
      clientNom: j['client_nom'] as String? ?? 'Anonyme',
      depot: j['depot'] as int?,
      montantTtc: j['montant_ttc'] as num? ?? 0,
      remise: j['remise'] as num? ?? 0,
      montantPaye: j['montant_paye'] as num? ?? 0,
      resteAPayer: j['reste_a_payer'] as num? ?? 0,
      modePaiement: j['mode_paiement'] as String?,
      nbLignes: j['nb_lignes'] as int?,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
