import 'package:djoulagest_mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:djoulagest_mobile/features/notifications/domain/entities/notification_entity.dart';
import 'package:djoulagest_mobile/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._datasource);
  final NotificationsRemoteDatasource _datasource;

  @override
  Future<({int count, List<NotificationEntity> notifications})> getNotifications({
    int page = 1,
    int pageSize = 25,
    bool? unreadOnly,
  }) =>
      _datasource.getNotifications(
          page: page, pageSize: pageSize, unreadOnly: unreadOnly);

  @override
  Future<void> markAsRead(int id) => _datasource.markAsRead(id);

  @override
  Future<void> markAllAsRead() => _datasource.markAllAsRead();
}
