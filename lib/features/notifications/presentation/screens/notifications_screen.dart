import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/notifications/domain/entities/notification_entity.dart';
import 'package:djoulagest_mobile/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:djoulagest_mobile/shared/layout/app_scaffold.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(notificationsProvider);
    final unread = asyncState.valueOrNull?.unreadCount ?? 0;

    return AppScaffold(
      title: 'Notifications${unread > 0 ? ' ($unread)' : ''}',
      showBottomNav: true,
      additionalActions: [
        if (unread > 0)
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllAsRead(),
            child: const Text('Tout lire',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
      ],
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: AppSizes.iconXxl, color: AppColors.gray300),
              const SizedBox(height: AppSizes.md),
              const Text('Impossible de charger les notifications',
                  style: TextStyle(color: AppColors.gray500)),
              const SizedBox(height: AppSizes.sm),
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (state) {
          if (state.notifications.isEmpty) {
            return const _EmptyState();
          }
          return _NotificationList(state: state);
        },
      ),
    );
  }
}

// ─── Liste ────────────────────────────────────────────────────────────────────

class _NotificationList extends ConsumerStatefulWidget {
  const _NotificationList({required this.state});
  final NotificationsState state;

  @override
  ConsumerState<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends ConsumerState<_NotificationList> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()
      ..addListener(() {
        if (_controller.position.pixels >=
            _controller.position.maxScrollExtent - 200) {
          ref.read(notificationsProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _controller,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.gray100),
        itemBuilder: (ctx, i) {
          if (i == state.notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _NotificationTile(notif: state.notifications[i]);
        },
      ),
    );
  }
}

// ─── Tuile ────────────────────────────────────────────────────────────────────

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notif});
  final NotificationEntity notif;

  IconData get _icon {
    return switch (notif.typeNotification) {
      'stock_alerte' => Icons.inventory_2_rounded,
      'caisse_ecart' => Icons.account_balance_wallet_rounded,
      'mission_litige' => Icons.warning_amber_rounded,
      'maintenance' => Icons.build_rounded,
      'conge' => Icons.event_available_rounded,
      'echance_client' => Icons.receipt_long_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color get _iconColor {
    return switch (notif.typeNotification) {
      'stock_alerte' => AppColors.accent,
      'caisse_ecart' => AppColors.danger,
      'mission_litige' => AppColors.danger,
      'maintenance' => AppColors.purple,
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notif.estLue;

    return InkWell(
      onTap: () {
        if (isUnread) {
          ref.read(notificationsProvider.notifier).markAsRead(notif.id);
        }
      },
      child: Container(
        color: isUnread
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingPage, vertical: AppSizes.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(_icon, color: _iconColor, size: AppSizes.iconMd),
            ),
            const SizedBox(width: AppSizes.sm),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.titre,
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.gray900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSizes.xs),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: AppColors.gray500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.timeAgo(notif.createdAt),
                    style: const TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── État vide ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: AppSizes.iconXxl, color: AppColors.gray200),
            SizedBox(height: AppSizes.md),
            Text(
              'Aucune notification',
              style: TextStyle(
                  color: AppColors.gray500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
