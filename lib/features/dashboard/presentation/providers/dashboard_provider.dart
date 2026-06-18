import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/role_simulation_provider.dart';
import 'package:djoulagest_mobile/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:djoulagest_mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:djoulagest_mobile/features/dashboard/domain/entities/kpi_entity.dart';
import 'package:djoulagest_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

// ─── DI ──────────────────────────────────────────────────────────────────────

final _dashboardDatasourceProvider = Provider<DashboardRemoteDatasource>(
  (ref) => DashboardRemoteDatasource(ref.read(apiClientProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(ref.read(_dashboardDatasourceProvider)),
);

// ─── Notifier ─────────────────────────────────────────────────────────────────

class DashboardNotifier extends AsyncNotifier<DashboardDataEntity> {
  @override
  Future<DashboardDataEntity> build() async {
    // Se recharge automatiquement quand le rôle effectif change (simulation).
    final user = ref.watch(effectiveUserProvider);
    if (user == null) return const DashboardDataEntity();
    return ref.read(dashboardRepositoryProvider).getDashboard(user);
  }

  Future<void> refresh() async {
    final user = ref.read(effectiveUserProvider);
    if (user == null) {
      state = const AsyncData(DashboardDataEntity());
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).getDashboard(user),
    );
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardDataEntity>(
        DashboardNotifier.new);
