import 'package:djoulagest_mobile/features/finance/domain/entities/cash_session_entity.dart';

abstract class TransactionModel {
  static TransactionEntity fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'] as int,
      type: json['type_transaction'] as String? ?? 'entree',
      // DecimalField DRF → string → parsing robuste.
      montant: _num(json['montant']),
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(
            json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
      reference: json['reference_doc'] as String?,
      sessionId: null,
    );
  }

  static num _num(dynamic v) =>
      v is num ? v : (num.tryParse(v?.toString() ?? '') ?? 0);
}
