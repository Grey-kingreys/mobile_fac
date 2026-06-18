import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/notifications/data/models/notification_model.dart';
import 'package:djoulagest_mobile/features/notifications/domain/entities/notification_entity.dart';

class NotificationsRemoteDatasource {
  const NotificationsRemoteDatasource(this._api);
  final ApiClient _api;

  Future<({int count, List<NotificationEntity> notifications})> getNotifications({
    int page = 1,
    int pageSize = 25,
    bool? unreadOnly,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': '-created_at',
    };
    if (unreadOnly == true) params['est_lue'] = 'false';

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.notifications,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    final count = data['count'] as int? ?? 0;
    final results = _list(data);
    return (
      count: count,
      notifications: results.map(NotificationModel.fromJson).toList(),
    );
  }

  Future<void> markAsRead(int id) async {
    await _api.post<void>(ApiEndpoints.notificationLire(id), data: {});
  }

  Future<void> markAllAsRead() async {
    await _api.post<void>(ApiEndpoints.notificationsToutLire, data: {});
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic> data) {
    final r = data['results'];
    if (r is List) return r.cast<Map<String, dynamic>>();
    return [];
  }
}
