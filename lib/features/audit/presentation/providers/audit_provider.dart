import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/audit/data/datasources/audit_remote_datasource.dart';
import 'package:djoulagest_mobile/features/audit/domain/entities/audit_log_entity.dart';

// ─── DI ─────────────────────────────────────────────────────────────────────

final _auditDatasourceProvider = Provider<AuditRemoteDatasource>(
  (ref) => AuditRemoteDatasource(ref.read(apiClientProvider)),
);

// ─── Journal d'audit ─────────────────────────────────────────────────────────

class AuditLogsState {
  const AuditLogsState({
    this.logs = const [],
    this.total = 0,
    this.page = 1,
    this.action,
    this.modelName,
    this.isLoadingMore = false,
  });

  final List<AuditLogEntity> logs;
  final int total;
  final int page;
  final String? action;
  final String? modelName;
  final bool isLoadingMore;

  bool get hasMore => logs.length < total;

  AuditLogsState copyWith({
    List<AuditLogEntity>? logs,
    int? total,
    int? page,
    Object? action = _sentinel,
    Object? modelName = _sentinel,
    bool? isLoadingMore,
  }) {
    return AuditLogsState(
      logs: logs ?? this.logs,
      total: total ?? this.total,
      page: page ?? this.page,
      action: action == _sentinel ? this.action : action as String?,
      modelName: modelName == _sentinel ? this.modelName : modelName as String?,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

const _sentinel = Object();

class AuditLogsNotifier extends AsyncNotifier<AuditLogsState> {
  static const _pageSize = 25;

  @override
  Future<AuditLogsState> build() => _fetch(const AuditLogsState());

  Future<AuditLogsState> _fetch(AuditLogsState base) async {
    final ds = ref.read(_auditDatasourceProvider);
    final result = await ds.getAuditLogs(
      page: 1,
      pageSize: _pageSize,
      action: base.action,
      modelName: base.modelName,
    );
    return AuditLogsState(
      logs: result.logs,
      total: result.count,
      page: 1,
      action: base.action,
      modelName: base.modelName,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? const AuditLogsState();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(current));
  }

  Future<void> setFilters({Object? action = _sentinel, Object? modelName = _sentinel}) async {
    final current = state.valueOrNull ?? const AuditLogsState();
    final next = current.copyWith(action: action, modelName: modelName);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(next));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(_auditDatasourceProvider).getAuditLogs(
            page: current.page + 1,
            pageSize: _pageSize,
            action: current.action,
            modelName: current.modelName,
          );
      state = AsyncData(current.copyWith(
        logs: [...current.logs, ...result.logs],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final auditLogsProvider =
    AsyncNotifierProvider<AuditLogsNotifier, AuditLogsState>(
        AuditLogsNotifier.new);

// ─── Journal de connexion ─────────────────────────────────────────────────────

class LoginLogsState {
  const LoginLogsState({
    this.logs = const [],
    this.total = 0,
    this.page = 1,
    this.success,
    this.isLoadingMore = false,
  });

  final List<LoginLogEntity> logs;
  final int total;
  final int page;
  final bool? success;
  final bool isLoadingMore;

  bool get hasMore => logs.length < total;

  LoginLogsState copyWith({
    List<LoginLogEntity>? logs,
    int? total,
    int? page,
    Object? success = _sentinel,
    bool? isLoadingMore,
  }) {
    return LoginLogsState(
      logs: logs ?? this.logs,
      total: total ?? this.total,
      page: page ?? this.page,
      success: success == _sentinel ? this.success : success as bool?,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class LoginLogsNotifier extends AsyncNotifier<LoginLogsState> {
  static const _pageSize = 25;

  @override
  Future<LoginLogsState> build() => _fetch(const LoginLogsState());

  Future<LoginLogsState> _fetch(LoginLogsState base) async {
    final ds = ref.read(_auditDatasourceProvider);
    final result = await ds.getLoginLogs(
      page: 1,
      pageSize: _pageSize,
      success: base.success,
    );
    return LoginLogsState(
      logs: result.logs,
      total: result.count,
      page: 1,
      success: base.success,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? const LoginLogsState();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(current));
  }

  Future<void> setSuccessFilter(bool? success) async {
    final current = state.valueOrNull ?? const LoginLogsState();
    final next = current.copyWith(success: success);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(next));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(_auditDatasourceProvider).getLoginLogs(
            page: current.page + 1,
            pageSize: _pageSize,
            success: current.success,
          );
      state = AsyncData(current.copyWith(
        logs: [...current.logs, ...result.logs],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final loginLogsProvider =
    AsyncNotifierProvider<LoginLogsNotifier, LoginLogsState>(
        LoginLogsNotifier.new);
