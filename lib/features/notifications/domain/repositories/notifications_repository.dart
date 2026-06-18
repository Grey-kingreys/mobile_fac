import 'package:djoulagest_mobile/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationsRepository {
  Future<({int count, List<NotificationEntity> notifications})> getNotifications({
    int page = 1,
    int pageSize = 25,
    bool? unreadOnly,
  });

  Future<void> markAsRead(int id);
  Future<void> markAllAsRead();
}
