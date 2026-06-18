import 'package:djoulagest_mobile/features/finance/domain/entities/cash_session_entity.dart';

abstract class TransactionModel {
  static TransactionEntity fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'] as int,
      type: json['type_transaction'] as String? ?? 'entree',
      montant: (json['montant'] as num?) ?? 0,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(
            json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
      reference: json['reference_doc'] as String?,
      sessionId: null,
    );
  }
}
