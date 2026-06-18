import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:djoulagest_mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:djoulagest_mobile/features/notifications/domain/entities/notification_entity.dart';
import 'package:djoulagest_mobile/features/notifications/domain/repositories/notifications_repository.dart';

// ─── DI ──────────────────────────────────────────────────────────────────────

final _notificationsDatasourceProvider =
    Provider<NotificationsRemoteDatasource>(
  (ref) => NotificationsRemoteDatasource(ref.read(apiClientProvider)),
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(ref.read(_notificationsDatasourceProvider)),
);

// ─── State ───────────────────────────────────────────────────────────────────

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
  });

  final List<NotificationEntity> notifications;
  final int total;
  final int page;
  final bool isLoadingMore;

  int get unreadCount => notifications.where((n) => !n.estLue).length;
  bool get hasMore => notifications.length < total;

  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    int? total,
    int? page,
    bool? isLoadingMore,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  static const _pageSize = 25;

  @override
  Future<NotificationsState> build() => _load(page: 1);

  Future<NotificationsState> _load({required int page}) async {
    final repo = ref.read(notificationsRepositoryProvider);
    final result = await repo.getNotifications(page: page, pageSize: _pageSize);
    final prev = page > 1
        ? (state.valueOrNull?.notifications ?? [])
        : <NotificationEntity>[];
    return NotificationsState(
      notifications: [...prev, ...result.notifications],
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
      final result = await ref
          .read(notificationsRepositoryProvider)
          .getNotifications(page: current.page + 1, pageSize: _pageSize);
      state = AsyncData(current.copyWith(
        notifications: [...current.notifications, ...result.notifications],
        total: result.count,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> markAsRead(int id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      await ref.read(notificationsRepositoryProvider).markAsRead(id);
      final updated = current.notifications
          .map((n) => n.id == id ? n.copyWith(estLue: true) : n)
          .toList();
      state = AsyncData(current.copyWith(notifications: updated));
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      await ref.read(notificationsRepositoryProvider).markAllAsRead();
      final updated = current.notifications
          .map((n) => n.copyWith(estLue: true))
          .toList();
      state = AsyncData(current.copyWith(notifications: updated));
    } catch (_) {}
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsState>(
        NotificationsNotifier.new);
