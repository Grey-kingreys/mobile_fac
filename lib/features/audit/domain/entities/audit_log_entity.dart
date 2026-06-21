import 'package:equatable/equatable.dart';

/// Une entrée du journal d'audit (create/update/delete sur modèles sensibles).
/// Immuable côté backend — lecture seule.
class AuditLogEntity extends Equatable {
  const AuditLogEntity({
    required this.id,
    this.userId,
    this.userEmail,
    required this.action,
    required this.actionDisplay,
    required this.modelName,
    required this.objectId,
    this.dataBefore,
    this.dataAfter,
    this.ipAddress,
    required this.timestamp,
  });

  final int id;
  final int? userId;
  final String? userEmail;

  /// `create` | `update` | `delete`
  final String action;

  /// Libellé humain renvoyé par le backend (« Création », « Modification »…).
  final String actionDisplay;

  /// Nom du modèle concerné (CustomUser, Zone, Depot…).
  final String modelName;
  final int objectId;

  final Map<String, dynamic>? dataBefore;
  final Map<String, dynamic>? dataAfter;
  final String? ipAddress;
  final DateTime timestamp;

  String get author => (userEmail != null && userEmail!.isNotEmpty)
      ? userEmail!
      : 'Système';

  @override
  List<Object?> get props => [id];
}

/// Une tentative de connexion (succès ou échec), avec IP et user-agent.
class LoginLogEntity extends Equatable {
  const LoginLogEntity({
    required this.id,
    this.userId,
    this.userEmail,
    this.ipAddress,
    this.userAgent = '',
    required this.success,
    required this.timestamp,
  });

  final int id;
  final int? userId;
  final String? userEmail;
  final String? ipAddress;
  final String userAgent;
  final bool success;
  final DateTime timestamp;

  String get author => (userEmail != null && userEmail!.isNotEmpty)
      ? userEmail!
      : 'Email inconnu';

  @override
  List<Object?> get props => [id];
}
