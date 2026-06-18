import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:djoulagest_mobile/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:djoulagest_mobile/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:djoulagest_mobile/features/finance/domain/entities/cash_session_entity.dart';
import 'package:djoulagest_mobile/features/finance/domain/repositories/finance_repository.dart';

// ─── DI ──────────────────────────────────────────────────────────────────────

final _financeDatasourceProvider = Provider<FinanceRemoteDatasource>(
  (ref) => FinanceRemoteDatasource(ref.read(apiClientProvider)),
);

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepositoryImpl(ref.read(_financeDatasourceProvider)),
);

// ─── State ───────────────────────────────────────────────────────────────────

class FinanceState {
  const FinanceState({
    this.activeSession,
    this.sessions = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
  });

  final CashSessionEntity? activeSession;
  final List<CashSessionEntity> sessions;
  final int total;
  final int page;
  final bool isLoadingMore;

  bool get hasMore => sessions.length < total;

  FinanceState copyWith({
    Object? activeSession = _sentinel,
    List<CashSessionEntity>? sessions,
    int? total,
    int? page,
    bool? isLoadingMore,
  }) {
    return FinanceState(
      activeSession: activeSession == _sentinel
          ? this.activeSession
          : activeSession as CashSessionEntity?,
      sessions: sessions ?? this.sessions,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

const _sentinel = Object();

// ─── Notifier ─────────────────────────────────────────────────────────────────

class FinanceNotifier extends AsyncNotifier<FinanceState> {
  static const _pageSize = 20;

  @override
  Future<FinanceState> build() => _load(page: 1);

  Future<FinanceState> _load({required int page}) async {
    final repo = ref.read(financeRepositoryProvider);
    final results = await Future.wait([
      repo.getActiveSession(),
      repo.getSessions(page: page, pageSize: _pageSize),
    ]);
    final active = results[0] as CashSessionEntity?;
    final sessionsResult =
        results[1] as ({int count, List<CashSessionEntity> sessions});
    final prev = page > 1 ? (state.valueOrNull?.sessions ?? []) : <CashSessionEntity>[];
    return FinanceState(
      activeSession: active,
      sessions: [...prev, ...sessionsResult.sessions],
      total: sessionsResult.count,
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
      final result = await ref.read(financeRepositoryProvider).getSessions(
            page: current.page + 1,
            pageSize: _pageSize,
          );
      state = AsyncData(current.copyWith(
        sessions: [...current.sessions, ...result.sessions],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Retourne null si succès, sinon le message d'erreur.
  Future<String?> openSession({required num soldeOuverture}) async {
    try {
      final repo = ref.read(financeRepositoryProvider);
      // Résoudre l'ID de la caisse physique liée au dépôt de l'utilisateur connecté.
      final depotId = ref.read(authProvider).valueOrNull?.depotId;
      if (depotId == null) {
        return 'Aucun dépôt associé à votre compte. Contactez votre administrateur.';
      }
      final caisseId = await repo.getCaisseIdForDepot(depotId);
      if (caisseId == null) {
        return 'Aucune caisse physique trouvée pour ce dépôt. Contactez votre administrateur.';
      }
      final session = await repo.openSession(
        caisseId: caisseId,
        soldeOuverture: soldeOuverture,
      );
      final current = state.valueOrNull ?? const FinanceState();
      state = AsyncData(current.copyWith(
        activeSession: session,
        sessions: [session, ...current.sessions],
        total: current.total + 1,
      ));
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  /// Retourne null si succès, sinon le message d'erreur.
  Future<String?> closeSession({
    required int id,
    required num soldeFermeture,
    String? motifEcart,
  }) async {
    try {
      final updated = await ref.read(financeRepositoryProvider).closeSession(
            id: id,
            soldeFermeture: soldeFermeture,
            motifEcart: motifEcart,
          );
      final current = state.valueOrNull ?? const FinanceState();
      final newList = current.sessions
          .map((s) => s.id == id ? updated : s)
          .toList();
      state = AsyncData(current.copyWith(
        activeSession: null,
        sessions: newList,
      ));
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}

final financeProvider =
    AsyncNotifierProvider<FinanceNotifier, FinanceState>(FinanceNotifier.new);

// ─── Transactions (auto-dispose, lié à la session active) ────────────────────

final transactionsProvider = FutureProvider.autoDispose
    .family<List<TransactionEntity>, int?>((ref, sessionId) async {
  if (sessionId == null) return [];
  final repo = ref.read(financeRepositoryProvider);
  final result = await repo.getTransactions(sessionId: sessionId, pageSize: 50);
  return result.transactions;
});
