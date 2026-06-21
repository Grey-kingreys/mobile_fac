import 'package:djoulagest_mobile/features/audit/domain/entities/audit_log_entity.dart';

/// Mapping JSON → entités. Noms de champs alignés sur les serializers Django
/// (`AuditLogSerializer` / `LoginLogSerializer`) — source de vérité.
abstract class AuditLogModel {
  static AuditLogEntity fromJson(Map<String, dynamic> json) {
    return AuditLogEntity(
      id: json['id'] as int,
      userId: json['user'] as int?,
      userEmail: json['user_email'] as String?,
      action: json['action'] as String? ?? '',
      actionDisplay: json['action_display'] as String? ?? '',
      modelName: json['model_name'] as String? ?? '',
      objectId: json['object_id'] as int? ?? 0,
      dataBefore: json['data_before'] as Map<String, dynamic>?,
      dataAfter: json['data_after'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String?,
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

abstract class LoginLogModel {
  static LoginLogEntity fromJson(Map<String, dynamic> json) {
    return LoginLogEntity(
      id: json['id'] as int,
      userId: json['user'] as int?,
      userEmail: json['user_email'] as String?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
