import 'package:djoulagest_mobile/features/reports/domain/entities/report_entity.dart';

abstract class ReportsRepository {
  Future<ReportData> getReport(ReportPeriod period);
}
