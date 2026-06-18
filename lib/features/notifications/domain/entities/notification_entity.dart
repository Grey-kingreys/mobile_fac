import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.typeNotification,
    required this.typeLabel,
    required this.titre,
    required this.message,
    this.lien,
    required this.estLue,
    required this.createdAt,
  });

  final int id;
  final String typeNotification;
  final String typeLabel;
  final String titre;
  final String message;
  final String? lien;
  final bool estLue;
  final DateTime createdAt;

  NotificationEntity copyWith({bool? estLue}) {
    return NotificationEntity(
      id: id,
      typeNotification: typeNotification,
      typeLabel: typeLabel,
      titre: titre,
      message: message,
      lien: lien,
      estLue: estLue ?? this.estLue,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, typeNotification, typeLabel, titre, message, lien, estLue, createdAt];
}
