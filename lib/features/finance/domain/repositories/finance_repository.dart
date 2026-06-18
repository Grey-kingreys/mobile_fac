import 'package:djoulagest_mobile/features/finance/domain/entities/cash_session_entity.dart';

abstract class FinanceRepository {
  Future<CashSessionEntity?> getActiveSession();

  Future<({int count, List<CashSessionEntity> sessions})> getSessions({
    int page = 1,
    int pageSize = 20,
    String? statut,
  });

  Future<int?> getCaisseIdForDepot(int depotId);

  Future<CashSessionEntity> openSession({
    required int caisseId,
    required num soldeOuverture,
  });

  Future<CashSessionEntity> closeSession({
    required int id,
    required num soldeFermeture,
    String? motifEcart,
  });

  Future<({int count, List<TransactionEntity> transactions})> getTransactions({
    int page = 1,
    int pageSize = 20,
    int? sessionId,
  });

  Future<TransactionEntity> addTransaction({
    required int sessionId,
    required String type,
    required num montant,
    required String description,
  });
}
