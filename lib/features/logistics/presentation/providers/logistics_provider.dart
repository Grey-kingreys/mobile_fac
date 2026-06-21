import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/logistics/data/datasources/logistics_remote_datasource.dart';
import 'package:djoulagest_mobile/features/logistics/data/models/vehicle_model.dart';
import 'package:djoulagest_mobile/features/logistics/data/repositories/logistics_repository_impl.dart';
import 'package:djoulagest_mobile/features/logistics/domain/entities/mission_entity.dart';
import 'package:djoulagest_mobile/features/logistics/domain/repositories/logistics_repository.dart';

// ─── DI ──────────────────────────────────────────────────────────────────────

final _logisticsDatasourceProvider = Provider<LogisticsRemoteDatasource>(
  (ref) => LogisticsRemoteDatasource(ref.read(apiClientProvider)),
);

final logisticsRepositoryProvider = Provider<LogisticsRepository>(
  (ref) => LogisticsRepositoryImpl(ref.read(_logisticsDatasourceProvider)),
);

// ─── Liste missions ───────────────────────────────────────────────────────────

class MissionsState {
  const MissionsState({
    this.missions = const [],
    this.total = 0,
    this.page = 1,
    this.filter = '',
    this.isLoadingMore = false,
  });

  final List<MissionEntity> missions;
  final int total;
  final int page;
  final String filter;
  final bool isLoadingMore;

  bool get hasMore => missions.length < total;

  MissionsState copyWith({
    List<MissionEntity>? missions,
    int? total,
    int? page,
    String? filter,
    bool? isLoadingMore,
  }) {
    return MissionsState(
      missions: missions ?? this.missions,
      total: total ?? this.total,
      page: page ?? this.page,
      filter: filter ?? this.filter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class MissionsNotifier extends AsyncNotifier<MissionsState> {
  static const _pageSize = 25;

  @override
  Future<MissionsState> build() => _load(page: 1, filter: '');

  Future<MissionsState> _load({required int page, required String filter}) async {
    final repo = ref.read(logisticsRepositoryProvider);
    final result = await repo.getMissions(
      page: page,
      pageSize: _pageSize,
      statut: filter.isEmpty ? null : filter,
    );
    final prev = page > 1 ? (state.valueOrNull?.missions ?? []) : <MissionEntity>[];
    return MissionsState(
      missions: [...prev, ...result.missions],
      total: result.count,
      page: page,
      filter: filter,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _load(page: 1, filter: state.valueOrNull?.filter ?? ''));
  }

  Future<void> setFilter(String filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1, filter: filter));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(logisticsRepositoryProvider).getMissions(
            page: current.page + 1,
            pageSize: _pageSize,
            statut: current.filter.isEmpty ? null : current.filter,
          );
      state = AsyncData(current.copyWith(
        missions: [...current.missions, ...result.missions],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> updateStatus(int missionId, String action) async {
    await ref.read(logisticsRepositoryProvider).updateStatus(missionId, action);
    await refresh();
  }

  /// Retourne null si succès, message d'erreur sinon.
  Future<String?> createMission({
    required int vehiculeId,
    required int chauffeurId,
    int? depotDepartId,
    int? depotArriveeId,
    int? clientId,
    int? fournisseurId,
    String typeMission = 'transfert',
    String? dateDepartPrevue,
    String? notes,
  }) async {
    try {
      await ref.read(logisticsRepositoryProvider).createMission(
            vehiculeId: vehiculeId,
            chauffeurId: chauffeurId,
            depotDepartId: depotDepartId,
            depotArriveeId: depotArriveeId,
            clientId: clientId,
            fournisseurId: fournisseurId,
            typeMission: typeMission,
            dateDepartPrevue: dateDepartPrevue,
            notes: notes,
          );
      await refresh();
      return null;
    } catch (e) {
      final s = e.toString();
      return s.startsWith('Exception: ') ? s.substring(11) : s;
    }
  }
}

final missionsProvider =
    AsyncNotifierProvider<MissionsNotifier, MissionsState>(MissionsNotifier.new);

// ─── Détail mission ───────────────────────────────────────────────────────────

final missionDetailProvider =
    FutureProvider.autoDispose.family<MissionEntity, int>((ref, id) async {
  return ref.read(logisticsRepositoryProvider).getMissionDetail(id);
});

// ─── QR de la mission (image base64 à afficher / faire scanner) ───────────────

final missionQrProvider =
    FutureProvider.autoDispose.family<String, int>((ref, id) async {
  return ref.read(logisticsRepositoryProvider).getMissionQr(id);
});

// ─── Scan QR → retourne l'id de la mission ────────────────────────────────────

final scanQrProvider =
    FutureProvider.autoDispose.family<int, String>((ref, qrCode) async {
  return ref.read(logisticsRepositoryProvider).scanQr(qrCode);
});

// ─── Listes pour le formulaire de création ───────────────────────────────────

final vehiculesSimpleProvider = FutureProvider.autoDispose<List<VehicleModel>>((ref) {
  final ds = ref.read(_logisticsDatasourceProvider);
  return ds.getVehiculesSimple();
});

final chauffeursSimpleProvider =
    FutureProvider.autoDispose<List<({int id, String fullName})>>((ref) {
  final ds = ref.read(_logisticsDatasourceProvider);
  return ds.getChauffeursSimple();
});
