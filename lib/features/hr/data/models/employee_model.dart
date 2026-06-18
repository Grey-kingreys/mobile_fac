import 'package:djoulagest_mobile/features/hr/domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    required super.id,
    required super.matricule,
    required super.nom,
    required super.prenom,
    required super.nomComplet,
    required super.poste,
    super.depot,
    super.depotNom,
    required super.statut,
    required super.statutLabel,
    super.telephone,
    super.createdAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> j) {
    return EmployeeModel(
      id: j['id'] as int,
      matricule: j['matricule'] as String? ?? '',
      nom: j['nom'] as String? ?? '',
      prenom: j['prenom'] as String? ?? '',
      nomComplet: j['nom_complet'] as String? ?? '${j['prenom'] ?? ''} ${j['nom'] ?? ''}',
      poste: j['poste'] as String? ?? '',
      depot: j['depot'] as int?,
      depotNom: j['depot_nom'] as String?,
      statut: j['statut'] as String? ?? 'actif',
      statutLabel: j['statut_label'] as String? ?? '',
      telephone: j['telephone'] as String?,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'] as String)
          : null,
    );
  }
}
