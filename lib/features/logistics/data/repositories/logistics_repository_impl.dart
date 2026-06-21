import 'package:djoulagest_mobile/features/logistics/data/datasources/logistics_remote_datasource.dart';
import 'package:djoulagest_mobile/features/logistics/domain/entities/mission_entity.dart';
import 'package:djoulagest_mobile/features/logistics/domain/repositories/logistics_repository.dart';

class LogisticsRepositoryImpl implements LogisticsRepository {
  const LogisticsRepositoryImpl(this._datasource);
  final LogisticsRemoteDatasource _datasource;

  @override
  Future<({int count, List<MissionEntity> missions})> getMissions({
    int page = 1,
    int pageSize = 25,
    String? statut,
  }) =>
      _datasource.getMissions(page: page, pageSize: pageSize, statut: statut);

  @override
  Future<MissionEntity> getMissionDetail(int id) =>
      _datasource.getMissionDetail(id);

  @override
  Future<MissionEntity> createMission({
    required int vehiculeId,
    required int chauffeurId,
    int? depotDepartId,
    int? depotArriveeId,
    int? clientId,
    int? fournisseurId,
    String typeMission = 'transfert',
    String? dateDepartPrevue,
    String? notes,
  }) =>
      _datasource.createMission(
        vehiculeId: vehiculeId,
        chauffeurId: chauffeurId,
        depotDepartId: depotDepartId,
        depotArriveeId: depotArriveeId,
        clientId: clientId,
        fournisseurId: fournisseurId,
        typeMission: typeMission,
        dateDepartPrevue: dateDepartPrevue,
        notes: notes,
      );

  @override
  Future<void> updateStatus(int id, String action) =>
      _datasource.updateStatus(id, action);

  @override
  Future<String> getMissionQr(int id) => _datasource.getMissionQr(id);

  @override
  Future<int> scanQr(String qrCode) => _datasource.scanQr(qrCode);

  @override
  Future<void> sendPosition(int id, double latitude, double longitude,
          {double? vitesseKmh}) =>
      _datasource.sendPosition(id, latitude, longitude,
          vitesseKmh: vitesseKmh);

  @override
  Future<void> signatureArrivee(
    int id, {
    required bool refusSignature,
    String? signatureBase64,
    String? motifLitige,
    List<Map<String, dynamic>>? quantitesRecues,
  }) =>
      _datasource.signatureArrivee(
        id,
        refusSignature: refusSignature,
        signatureBase64: signatureBase64,
        motifLitige: motifLitige,
        quantitesRecues: quantitesRecues,
      );
}
