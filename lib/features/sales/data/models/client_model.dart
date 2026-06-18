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
      pointsFidelite: j['points_fidelite'] as num? ?? 0,
      soldeCredit: j['solde_credit'] as num? ?? 0,
      isActive: j['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
