import 'package:djoulagest_mobile/features/sales/domain/entities/client_entity.dart';

class ClientModel extends ClientEntity {
  const ClientModel({
    required super.id,
    required super.code,
    required super.nom,
    super.prenom,
    required super.nomComplet,
    super.telephone,
    required super.pointsFidelite,
    required super.soldeCredit,
    required super.isActive,
    required super.createdAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> j) {
    return ClientModel(
      id: j['id'] as int,
      code: j['code'] as String? ?? '',
      nom: j['nom'] as String? ?? '',
      prenom: j['prenom'] as String?,
      nomComplet: j['nom_complet'] as String? ?? '${j['prenom'] ?? ''} ${j['nom'] ?? ''}',
      telephone: j['telephone'] as String?,
      // DRF renvoie les DecimalField en string → parsing robuste.
      pointsFidelite: _num(j['points_fidelite']),
      soldeCredit: _num(j['solde_credit']),
      isActive: j['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static num _num(dynamic v) =>
      v is num ? v : (num.tryParse(v?.toString() ?? '') ?? 0);
}
