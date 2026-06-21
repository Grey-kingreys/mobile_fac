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
      montantTtc: _num(j['montant_ttc']),
      remise: _num(j['remise']),
      montantPaye: _num(j['montant_paye']),
      resteAPayer: _num(j['reste_a_payer']),
      modePaiement: j['mode_paiement'] as String?,
      nbLignes: j['nb_lignes'] as int?,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  // DRF renvoie les DecimalField en string → parsing robuste.
  static num _num(dynamic v) =>
      v is num ? v : (num.tryParse(v?.toString() ?? '') ?? 0);
}
