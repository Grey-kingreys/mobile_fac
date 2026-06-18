import 'package:equatable/equatable.dart';

const Map<String, String> planLabels = {
  'free': 'Gratuit',
  'starter': 'Starter',
  'pro': 'Pro',
  'enterprise': 'Enterprise',
};

class CompanyEntity extends Equatable {
  const CompanyEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    required this.isActive,
    required this.statut,
    required this.subscriptionPlan,
    required this.nombreUtilisateurs,
    required this.nombreZones,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String slug;
  final String? logo;
  final bool isActive;
  final String statut;
  final String subscriptionPlan;
  final int nombreUtilisateurs;
  final int nombreZones;
  final DateTime createdAt;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0])
      .take(2)
      .join()
      .toUpperCase();

  String get planLabel => planLabels[subscriptionPlan] ?? subscriptionPlan;

  CompanyEntity copyWith({
    int? id,
    String? name,
    String? slug,
    String? logo,
    bool? isActive,
    String? statut,
    String? subscriptionPlan,
    int? nombreUtilisateurs,
    int? nombreZones,
    DateTime? createdAt,
  }) {
    return CompanyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      logo: logo ?? this.logo,
      isActive: isActive ?? this.isActive,
      statut: statut ?? this.statut,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      nombreUtilisateurs: nombreUtilisateurs ?? this.nombreUtilisateurs,
      nombreZones: nombreZones ?? this.nombreZones,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, name, slug, logo, isActive, statut,
        subscriptionPlan, nombreUtilisateurs, nombreZones, createdAt,
      ];
}
