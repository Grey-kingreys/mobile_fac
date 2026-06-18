class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.immatriculation,
    required this.typeVehicule,
    this.typeLabel,
    this.marque,
    this.modele,
    this.statut,
    this.statutLabel,
    this.chauffeurAttitreNom,
    required this.isActive,
  });

  final int id;
  final String immatriculation;
  final String typeVehicule;
  final String? typeLabel;
  final String? marque;
  final String? modele;
  final String? statut;
  final String? statutLabel;
  final String? chauffeurAttitreNom;
  final bool isActive;

  factory VehicleModel.fromJson(Map<String, dynamic> j) {
    return VehicleModel(
      id: j['id'] as int,
      immatriculation: j['immatriculation'] as String? ?? '',
      typeVehicule: j['type_vehicule'] as String? ?? '',
      typeLabel: j['type_label'] as String?,
      marque: j['marque'] as String?,
      modele: j['modele'] as String?,
      statut: j['statut'] as String?,
      statutLabel: j['statut_label'] as String?,
      chauffeurAttitreNom: j['chauffeur_nom'] as String?,
      isActive: j['is_active'] as bool? ?? true,
    );
  }
}
