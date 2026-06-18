import 'package:djoulagest_mobile/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:djoulagest_mobile/features/finance/domain/entities/cash_session_entity.dart';
import 'package:djoulagest_mobile/features/finance/domain/repositories/finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  const FinanceRepositoryImpl(this._datasource);
  final FinanceRemoteDatasource _datasource;

  @override
  Future<CashSessionEntity?> getActiveSession() =>
      _datasource.getActiveSession();

  @override
  Future<({int count, List<CashSessionEntity> sessions})> getSessions({
    int page = 1,
    int pageSize = 20,
    String? statut,
  }) =>
      _datasource.getSessions(page: page, pageSize: pageSize, statut: statut);

  @override
  Future<int?> getCaisseIdForDepot(int depotId) =>
      _datasource.getCaisseIdForDepot(depotId);

  @override
  Future<CashSessionEntity> openSession({
    required int caisseId,
    required num soldeOuverture,
  }) =>
      _datasource.openSession(caisseId: caisseId, soldeOuverture: soldeOuverture);

  @override
  Future<CashSessionEntity> closeSession({
    required int id,
    required num soldeFermeture,
    String? motifEcart,
  }) =>
      _datasource.closeSession(
        id: id,
        soldeFermeture: soldeFermeture,
        motifEcart: motifEcart,
      );

  @override
  Future<({int count, List<TransactionEntity> transactions})> getTransactions({
    int page = 1,
    int pageSize = 20,
    int? sessionId,
  }) =>
      _datasource.getTransactions(
        page: page,
        pageSize: pageSize,
        sessionId: sessionId,
      );

  @override
  Future<TransactionEntity> addTransaction({
    required int sessionId,
    required String type,
    required num montant,
    required String description,
  }) =>
      _datasource.addTransaction(
        sessionId: sessionId,
        type: type,
        montant: montant,
        description: description,
      );
}
