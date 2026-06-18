import 'package:equatable/equatable.dart';

class DepotEntity extends Equatable {
  const DepotEntity({
    required this.id,
    required this.nom,
    this.code,
    required this.zoneId,
    required this.zoneName,
    this.adresse,
    this.latitude,
    this.longitude,
    this.gestionnaireId,
    this.gestionnaireName,
    required this.companyId,
    required this.isActive,
  });

  final int id;
  final String nom;
  final String? code;
  final int zoneId;
  final String zoneName;
  final String? adresse;
  final double? latitude;
  final double? longitude;
  final int? gestionnaireId;
  final String? gestionnaireName;
  final int companyId;
  final bool isActive;

  String get initials => nom.trim().isEmpty
      ? '?'
      : nom.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

  DepotEntity copyWith({
    int? id,
    String? nom,
    String? code,
    int? zoneId,
    String? zoneName,
    String? adresse,
    double? latitude,
    double? longitude,
    int? gestionnaireId,
    String? gestionnaireName,
    int? companyId,
    bool? isActive,
  }) {
    return DepotEntity(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      code: code ?? this.code,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      adresse: adresse ?? this.adresse,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gestionnaireId: gestionnaireId ?? this.gestionnaireId,
      gestionnaireName: gestionnaireName ?? this.gestionnaireName,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, nom, code, zoneId, companyId, isActive];
}
