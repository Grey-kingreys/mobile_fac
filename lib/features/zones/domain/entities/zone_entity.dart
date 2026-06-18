import 'package:equatable/equatable.dart';

class ZoneEntity extends Equatable {
  const ZoneEntity({
    required this.id,
    required this.name,
    this.code,
    this.latitude,
    this.longitude,
    required this.companyId,
    required this.nombreDepots,
    required this.isActive,
  });

  final int id;
  final String name;
  final String? code;
  final double? latitude;
  final double? longitude;
  final int companyId;
  final int nombreDepots;
  final bool isActive;

  String get initials => name.trim().isEmpty
      ? '?'
      : name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

  ZoneEntity copyWith({
    int? id,
    String? name,
    String? code,
    double? latitude,
    double? longitude,
    int? companyId,
    int? nombreDepots,
    bool? isActive,
  }) {
    return ZoneEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      companyId: companyId ?? this.companyId,
      nombreDepots: nombreDepots ?? this.nombreDepots,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, companyId, isActive];
}
