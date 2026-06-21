import 'package:djoulagest_mobile/features/logistics/domain/entities/mission_entity.dart';

abstract class LogisticsRepository {
  Future<({int count, List<MissionEntity> missions})> getMissions({
    int page = 1,
    int pageSize = 25,
    String? statut,
  });

  Future<MissionEntity> getMissionDetail(int id);

  Future<MissionEntity> createMission({
    required int vehiculeId,
    required int chauffeurId,
    int? depotDepartId,
    int? depotArriveeId,
    int? clientId,
    int? fournisseurId,
    String typeMission,
    String? dateDepartPrevue,
    String? notes,
  });

  Future<void> updateStatus(int id, String action);

  Future<String> getMissionQr(int id);

  Future<int> scanQr(String qrCode);

  Future<void> sendPosition(int id, double latitude, double longitude,
      {double? vitesseKmh});

  Future<void> signatureArrivee(
    int id, {
    required bool refusSignature,
    String? signatureBase64,
    String? motifLitige,
    List<Map<String, dynamic>>? quantitesRecues,
  });
}
