import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:djoulagest_mobile/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:djoulagest_mobile/features/admin/domain/entities/company_entity.dart';
import 'package:djoulagest_mobile/features/admin/domain/repositories/admin_repository.dart';

// ─── DI ─────────────────────────────────────────────────────────────────────

final _adminDatasourceProvider = Provider<AdminRemoteDatasource>(
  (ref) => AdminRemoteDatasource(ref.read(apiClientProvider)),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(ref.read(_adminDatasourceProvider)),
);

// ─── State ───────────────────────────────────────────────────────────────────

class CompaniesState {
  const CompaniesState({
    this.companies = const [],
    this.total = 0,
    this.page = 1,
    this.search = '',
    this.isLoadingMore = false,
  });

  final List<CompanyEntity> companies;
  final int total;
  final int page;
  final String search;
  final bool isLoadingMore;

  bool get hasMore => companies.length < total;

  CompaniesState copyWith({
    List<CompanyEntity>? companies,
    int? total,
    int? page,
    String? search,
    bool? isLoadingMore,
  }) {
    return CompaniesState(
      companies: companies ?? this.companies,
      total: total ?? this.total,
      page: page ?? this.page,
      search: search ?? this.search,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class CompaniesNotifier extends AsyncNotifier<CompaniesState> {
  static const _pageSize = 20;

  @override
  Future<CompaniesState> build() => _fetch(page: 1, search: '');

  Future<CompaniesState> _fetch({required int page, required String search}) async {
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.getCompanies(
      page: page,
      pageSize: _pageSize,
      search: search.isEmpty ? null : search,
    );
    final prev = (page > 1) ? (state.valueOrNull?.companies ?? []) : <CompanyEntity>[];
    return CompaniesState(
      companies: [...prev, ...result.companies],
      total: result.count,
      page: page,
      search: search,
    );
  }

  Future<void> refresh() async {
    final search = state.valueOrNull?.search ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, search: search));
  }

  Future<void> searchCompanies(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1, search: query));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(adminRepositoryProvider).getCompanies(
            page: current.page + 1,
            pageSize: _pageSize,
            search: current.search.isEmpty ? null : current.search,
          );
      state = AsyncData(current.copyWith(
        companies: [...current.companies, ...result.companies],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  // Retourne null si succès, sinon le message d'erreur.
  Future<String?> create({
    required String name,
    required String emailAdmin,
    required String subscriptionPlan,
  }) async {
    try {
      await ref.read(adminRepositoryProvider).createCompany(
            name: name,
            emailAdmin: emailAdmin,
            subscriptionPlan: subscriptionPlan,
          );
      await refresh();
      return null;
    } catch (e) {
      return _extractMessage(e);
    }
  }

  Future<String?> updateCompany({
    required int id,
    required String name,
    required String subscriptionPlan,
  }) async {
    try {
      final updated = await ref.read(adminRepositoryProvider).updateCompany(
            id: id,
            name: name,
            subscriptionPlan: subscriptionPlan,
          );
      final current = state.valueOrNull;
      if (current != null) {
        final newList = current.companies.map((c) => c.id == id ? updated : c).toList();
        state = AsyncData(current.copyWith(companies: newList));
      }
      return null;
    } catch (e) {
      return _extractMessage(e);
    }
  }

  Future<String?> toggle(int id) async {
    try {
      final updated = await ref.read(adminRepositoryProvider).toggleCompany(id);
      final current = state.valueOrNull;
      if (current != null) {
        final newList = current.companies.map((c) => c.id == id ? updated : c).toList();
        state = AsyncData(current.copyWith(companies: newList));
      }
      return null;
    } catch (e) {
      return _extractMessage(e);
    }
  }

  String _extractMessage(Object e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    return msg;
  }
}

final companiesProvider =
    AsyncNotifierProvider<CompaniesNotifier, CompaniesState>(CompaniesNotifier.new);
