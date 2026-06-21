import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/hr/data/datasources/hr_remote_datasource.dart';
import 'package:djoulagest_mobile/features/hr/data/repositories/hr_repository_impl.dart';
import 'package:djoulagest_mobile/features/hr/domain/entities/attendance_entity.dart';
import 'package:djoulagest_mobile/features/hr/domain/entities/employee_entity.dart';
import 'package:djoulagest_mobile/features/hr/domain/repositories/hr_repository.dart';

// ─── DI ──────────────────────────────────────────────────────────────────────

final _hrDatasourceProvider = Provider<HrRemoteDatasource>(
  (ref) => HrRemoteDatasource(ref.read(apiClientProvider)),
);

final hrRepositoryProvider = Provider<HrRepository>(
  (ref) => HrRepositoryImpl(ref.read(_hrDatasourceProvider)),
);

// ─── State ───────────────────────────────────────────────────────────────────

class HrState {
  const HrState({
    this.employees = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.statut = '',
    this.isLoadingMore = false,
  });

  final List<EmployeeEntity> employees;
  final int total;
  final int page;
  final String search;
  final String statut;
  final bool isLoadingMore;

  bool get hasMore => employees.length < total;

  HrState copyWith({
    List<EmployeeEntity>? employees,
    int? total,
    int? page,
    String? search,
    String? statut,
    bool? isLoadingMore,
  }) {
    return HrState(
      employees: employees ?? this.employees,
      total: total ?? this.total,
      page: page ?? this.page,
      search: search ?? this.search,
      statut: statut ?? this.statut,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class HrNotifier extends AsyncNotifier<HrState> {
  static const _pageSize = 25;

  @override
  Future<HrState> build() => _load(page: 1, search: '', statut: '');

  Future<HrState> _load({
    required int page,
    required String search,
    required String statut,
  }) async {
    final repo = ref.read(hrRepositoryProvider);
    final result = await repo.getEmployees(
      page: page,
      pageSize: _pageSize,
      search: search.isEmpty ? null : search,
      statut: statut.isEmpty ? null : statut,
    );
    final prev = page > 1 ? (state.valueOrNull?.employees ?? []) : <EmployeeEntity>[];
    return HrState(
      employees: [...prev, ...result.employees],
      total: result.count,
      page: page,
      search: search,
      statut: statut,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(
          page: 1,
          search: current?.search ?? '',
          statut: current?.statut ?? '',
        ));
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _load(page: 1, search: query, statut: state.valueOrNull?.statut ?? ''));
  }

  Future<void> filterStatut(String statut) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _load(page: 1, search: '', statut: statut));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(hrRepositoryProvider).getEmployees(
            page: current.page + 1,
            pageSize: _pageSize,
            search: current.search.isEmpty ? null : current.search,
            statut: current.statut.isEmpty ? null : current.statut,
          );
      state = AsyncData(current.copyWith(
        employees: [...current.employees, ...result.employees],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final hrProvider =
    AsyncNotifierProvider<HrNotifier, HrState>(HrNotifier.new);

// ─── Présences ────────────────────────────────────────────────────────────────

class PresencesState {
  const PresencesState({
    this.presences = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
  });

  final List<PresenceEntity> presences;
  final int total;
  final int page;
  final bool isLoadingMore;

  bool get hasMore => presences.length < total;

  PresencesState copyWith({
    List<PresenceEntity>? presences,
    int? total,
    int? page,
    bool? isLoadingMore,
  }) =>
      PresencesState(
        presences: presences ?? this.presences,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class PresencesNotifier extends AsyncNotifier<PresencesState> {
  static const _pageSize = 25;

  @override
  Future<PresencesState> build() => _load(page: 1);

  Future<PresencesState> _load({required int page}) async {
    final repo = ref.read(hrRepositoryProvider);
    final result = await repo.getPresences(page: page, pageSize: _pageSize);
    final prev = page > 1
        ? (state.valueOrNull?.presences ?? [])
        : <PresenceEntity>[];
    return PresencesState(
      presences: [...prev, ...result.presences],
      total: result.count,
      page: page,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(hrRepositoryProvider).getPresences(
            page: current.page + 1,
            pageSize: _pageSize,
          );
      state = AsyncData(current.copyWith(
        presences: [...current.presences, ...result.presences],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(hrRepositoryProvider).createPresence(body);
    await refresh();
  }

  /// Pointage self-service géolocalisé. Retourne la présence créée.
  /// Le pointage HTTP a déjà réussi quand on rafraîchit ; un échec de refresh
  /// (liste/statut) ne doit pas être confondu avec un échec de pointage.
  Future<PresenceEntity> pointer(double latitude, double longitude) async {
    final presence = await ref.read(hrRepositoryProvider).pointerPresence({
      'latitude': latitude,
      'longitude': longitude,
    });
    try {
      ref.invalidate(myPresenceProvider);
      await refresh();
    } catch (_) {/* le pointage a réussi ; on ignore un éventuel échec de refresh */}
    return presence;
  }
}

final presencesProvider =
    AsyncNotifierProvider<PresencesNotifier, PresencesState>(
        PresencesNotifier.new);

/// État du pointage du jour de l'utilisateur connecté (pilote la carte self-service).
final myPresenceProvider = FutureProvider.autoDispose<PresenceTodayStatus>(
  (ref) => ref.read(hrRepositoryProvider).getPresenceAujourdhui(),
);

/// Récap présences/absences du jour (admin/superviseur).
final presenceRecapProvider = FutureProvider.autoDispose<PresenceRecap>(
  (ref) => ref.read(hrRepositoryProvider).getPresenceRecap(),
);

// ─── Congés ───────────────────────────────────────────────────────────────────

class CongesState {
  const CongesState({
    this.conges = const [],
    this.total = 0,
    this.page = 1,
    this.statut = '',
    this.isLoadingMore = false,
  });

  final List<CongeEntity> conges;
  final int total;
  final int page;
  final String statut;
  final bool isLoadingMore;

  bool get hasMore => conges.length < total;

  CongesState copyWith({
    List<CongeEntity>? conges,
    int? total,
    int? page,
    String? statut,
    bool? isLoadingMore,
  }) =>
      CongesState(
        conges: conges ?? this.conges,
        total: total ?? this.total,
        page: page ?? this.page,
        statut: statut ?? this.statut,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class CongesNotifier extends AsyncNotifier<CongesState> {
  static const _pageSize = 25;

  @override
  Future<CongesState> build() => _load(page: 1, statut: '');

  Future<CongesState> _load({required int page, required String statut}) async {
    final repo = ref.read(hrRepositoryProvider);
    final result = await repo.getConges(
      page: page,
      pageSize: _pageSize,
      statut: statut.isEmpty ? null : statut,
    );
    final prev =
        page > 1 ? (state.valueOrNull?.conges ?? []) : <CongeEntity>[];
    return CongesState(
      conges: [...prev, ...result.conges],
      total: result.count,
      page: page,
      statut: statut,
    );
  }

  Future<void> refresh() async {
    final s = state.valueOrNull?.statut ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1, statut: s));
  }

  Future<void> filterStatut(String statut) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(page: 1, statut: statut));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(hrRepositoryProvider).getConges(
            page: current.page + 1,
            pageSize: _pageSize,
            statut: current.statut.isEmpty ? null : current.statut,
          );
      state = AsyncData(current.copyWith(
        conges: [...current.conges, ...result.conges],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(hrRepositoryProvider).createConge(body);
    await refresh();
  }

  Future<void> approuver(int id) async {
    await ref.read(hrRepositoryProvider).approuverConge(id);
    await refresh();
  }

  Future<void> refuser(int id, {String? motif}) async {
    await ref.read(hrRepositoryProvider).refuserConge(id, motif: motif);
    await refresh();
  }
}

final congesProvider =
    AsyncNotifierProvider<CongesNotifier, CongesState>(CongesNotifier.new);
