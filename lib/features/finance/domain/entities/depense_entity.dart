class DepenseEntity {
  const DepenseEntity({
    required this.id,
    required this.categorie,
    required this.montant,
    required this.description,
    required this.dateDepense,
    this.depotNom,
    this.reference,
    this.enregistreParNom,
    required this.createdAt,
  });

  final int id;
  final String categorie;
  final double montant;
  final String description;
  final String dateDepense;
  final String? depotNom;
  final String? reference;
  final String? enregistreParNom;
  final DateTime createdAt;

  factory DepenseEntity.fromJson(Map<String, dynamic> j) => DepenseEntity(
        id: j['id'] as int,
        categorie: j['categorie'] as String? ?? '',
        montant: _d(j['montant']),
        description: j['description'] as String? ?? '',
        dateDepense: j['date_depense'] as String? ?? '',
        depotNom: j['depot_nom'] as String?,
        reference: j['reference'] as String?,
        enregistreParNom: j['enregistre_par_nom'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
