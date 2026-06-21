import 'package:djoulagest_mobile/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:djoulagest_mobile/features/reports/domain/entities/report_entity.dart';
import 'package:djoulagest_mobile/features/reports/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl(this._datasource);
  final ReportsRemoteDatasource _datasource;

  @override
  Future<ReportData> getReport(ReportPeriod period) =>
      _datasource.getReport(period);
}
