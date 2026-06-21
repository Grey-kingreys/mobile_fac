import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:djoulagest_mobile/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:djoulagest_mobile/features/reports/domain/entities/report_entity.dart';
import 'package:djoulagest_mobile/features/reports/domain/repositories/reports_repository.dart';

// ─── DI ──────────────────────────────────────────────────────────────────────

final _reportsDatasourceProvider = Provider<ReportsRemoteDatasource>(
  (ref) => ReportsRemoteDatasource(ref.read(apiClientProvider)),
);

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(ref.read(_reportsDatasourceProvider)),
);

// ─── Période sélectionnée ─────────────────────────────────────────────────────

final reportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.month);

// ─── Données ──────────────────────────────────────────────────────────────────

class ReportsNotifier extends AutoDisposeAsyncNotifier<ReportData> {
  @override
  Future<ReportData> build() {
    final period = ref.watch(reportPeriodProvider);
    return ref.read(reportsRepositoryProvider).getReport(period);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reportsRepositoryProvider).getReport(
            ref.read(reportPeriodProvider),
          ),
    );
  }
}

final reportsProvider =
    AutoDisposeAsyncNotifierProvider<ReportsNotifier, ReportData>(
  ReportsNotifier.new,
);
