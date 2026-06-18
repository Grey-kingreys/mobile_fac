import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';

class CompteMobileMoneyEntity {
  const CompteMobileMoneyEntity({
    required this.id,
    required this.operateur,
    required this.operateurLabel,
    required this.numero,
    required this.nomTitulaire,
    required this.solde,
    this.depotNom,
    required this.isActive,
  });

  final int id;
  final String operateur;
  final String operateurLabel;
  final String numero;
  final String nomTitulaire;
  final double solde;
  final String? depotNom;
  final bool isActive;

  factory CompteMobileMoneyEntity.fromJson(Map<String, dynamic> j) =>
      CompteMobileMoneyEntity(
        id: j['id'] as int,
        operateur: j['operateur'] as String? ?? '',
        operateurLabel: j['operateur_label'] as String? ?? '',
        numero: j['numero'] as String? ?? '',
        nomTitulaire: j['nom_titulaire'] as String? ?? '',
        solde: _d(j['solde']),
        depotNom: j['depot_nom'] as String?,
        isActive: j['is_active'] as bool? ?? true,
      );

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Color get couleurOperateur => switch (operateur) {
        'orange_money' => AppColors.orangeMoney,
        'mtn_money' => AppColors.mtnMoney,
        _ => AppColors.primary,
      };
}

class TransactionMobileMoneyEntity {
  const TransactionMobileMoneyEntity({
    required this.id,
    required this.typeTransaction,
    required this.typeLabel,
    required this.montant,
    this.referenceOperateur,
    this.description,
    this.createdByNom,
    required this.createdAt,
  });

  final int id;
  final String typeTransaction;
  final String typeLabel;
  final double montant;
  final String? referenceOperateur;
  final String? description;
  final String? createdByNom;
  final DateTime createdAt;

  bool get isEntree => typeTransaction == 'entree';

  factory TransactionMobileMoneyEntity.fromJson(Map<String, dynamic> j) =>
      TransactionMobileMoneyEntity(
        id: j['id'] as int,
        typeTransaction: j['type_transaction'] as String? ?? '',
        typeLabel: j['type_label'] as String? ?? '',
        montant: _d(j['montant']),
        referenceOperateur: j['reference_operateur'] as String?,
        description: j['description'] as String?,
        createdByNom: j['created_by_nom'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
