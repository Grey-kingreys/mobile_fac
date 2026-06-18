import 'package:djoulagest_mobile/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.typeNotification,
    required super.typeLabel,
    required super.titre,
    required super.message,
    super.lien,
    required super.estLue,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) {
    return NotificationModel(
      id: j['id'] as int,
      typeNotification: j['type_notification'] as String? ?? '',
      typeLabel: j['type_label'] as String? ?? '',
      titre: j['titre'] as String? ?? '',
      message: j['message'] as String? ?? '',
      lien: j['lien'] as String?,
      estLue: j['est_lue'] as bool? ?? false,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
