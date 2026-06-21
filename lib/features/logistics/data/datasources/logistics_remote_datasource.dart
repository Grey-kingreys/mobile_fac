import 'package:djoulagest_mobile/core/network/api_client.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/features/logistics/data/models/mission_model.dart';
import 'package:djoulagest_mobile/features/logistics/data/models/vehicle_model.dart';
import 'package:djoulagest_mobile/features/logistics/domain/entities/mission_entity.dart';

class LogisticsRemoteDatasource {
  const LogisticsRemoteDatasource(this._api);
  final ApiClient _api;

  Future<({int count, List<MissionEntity> missions})> getMissions({
    int page = 1,
    int pageSize = 25,
    String? statut,
  }) async {
    final params = <String, dynamic>{
      'page': '$page',
      'page_size': '$pageSize',
      'ordering': '-created_at',
    };
    if (statut != null && statut.isNotEmpty) params['statut'] = statut;

    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.missions,
      queryParameters: params,
    );
    final data = resp.data ?? {};
    final count = data['count'] as int? ?? 0;
    final results = _list(data);
    return (
      count: count,
      missions: results.map(MissionModel.fromJson).toList(),
    );
  }

  Future<MissionEntity> getMissionDetail(int id) async {
    final resp = await _api.get<Map<String, dynamic>>(ApiEndpoints.missionDetail(id));
    final data = resp.data ?? {};
    return MissionModel.fromJson(data);
  }

  Future<void> updateStatus(int id, String action) async {
    final endpoint = switch (action) {
      'chargement' => ApiEndpoints.missionChargement(id),
      'transit' => ApiEndpoints.missionTransit(id),
      'arrivee' => ApiEndpoints.missionArrivee(id),
      'terminer' => ApiEndpoints.missionTerminer(id),
      'annuler' => ApiEndpoints.missionAnnuler(id),
      _ => throw ArgumentError('Action inconnue: $action'),
    };
    await _api.post<void>(endpoint, data: {});
  }

  /// Récupère l'image PNG (base64) du QR code de la mission, à afficher/imprimer.
  /// Le backend renvoie `{ qr_code, image_base64 }` (uuid + png base64).
  Future<String> getMissionQr(int id) async {
    final resp = await _api.get<Map<String, dynamic>>(ApiEndpoints.missionQr(id));
    final data = resp.data ?? {};
    return data['image_base64'] as String? ?? '';
  }

  /// Retourne l'id de la mission correspondant au QR code scanné.
  Future<int> scanQr(String qrCode) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.missionsScannerQr,
      data: {'qr_code': qrCode},
    );
    final data = resp.data ?? {};
    return data['id'] as int;
  }

  /// Envoie la position GPS courante de la mission en transit.
  Future<void> sendPosition(int id, double latitude, double longitude,
      {double? vitesseKmh}) async {
    await _api.post<void>(
      ApiEndpoints.missionPosition(id),
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (vitesseKmh != null) 'vitesse_kmh': vitesseKmh,
      },
    );
  }

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
  }) async {
    final resp = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.missions,
      data: {
        'vehicule': vehiculeId,
        'chauffeur': chauffeurId,
        'type_mission': typeMission,
        // Champs conditionnels selon le type (validés côté backend).
        if (depotDepartId != null) 'depot_depart': depotDepartId,
        if (depotArriveeId != null) 'depot_arrivee': depotArriveeId,
        if (clientId != null) 'client': clientId,
        if (fournisseurId != null) 'fournisseur': fournisseurId,
        if (dateDepartPrevue != null) 'date_depart_prevue': dateDepartPrevue,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return MissionModel.fromJson(resp.data ?? {});
  }

  Future<List<VehicleModel>> getVehiculesSimple() async {
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.vehicules,
      queryParameters: {'page_size': '200', 'is_active': 'true'},
    );
    final results = _list(resp.data ?? {});
    return results.map(VehicleModel.fromJson).toList();
  }

  Future<List<({int id, String fullName})>> getChauffeursSimple() async {
    final resp = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.users,
      queryParameters: {'role': 'chauffeur', 'is_active': 'true', 'page_size': '200'},
    );
    final results = _list(resp.data ?? {});
    return results.map((u) {
      final firstName = u['first_name'] as String? ?? '';
      final lastName = u['last_name'] as String? ?? '';
      final full = '$firstName $lastName'.trim();
      return (
        id: u['id'] as int,
        fullName: full.isEmpty ? (u['email'] as String? ?? '?') : full,
      );
    }).toList();
  }

  /// Soumet la signature d'arrivée.
  ///
  /// - [refusSignature]=false (défaut) : signature canvas obligatoire → statut ARRIVEE
  /// - [refusSignature]=true : pas de canvas requis → statut LITIGE, [motifLitige] optionnel
  Future<void> signatureArrivee(
    int id, {
    required bool refusSignature,
    String? signatureBase64,
    String? motifLitige,
    List<Map<String, dynamic>>? quantitesRecues,
  }) async {
    await _api.post<void>(
      ApiEndpoints.missionArrivee(id),
      data: {
        'refus_signature': refusSignature,
        if (!refusSignature && signatureBase64 != null)
          'signature': signatureBase64,
        if (motifLitige != null && motifLitige.isNotEmpty)
          'motif_litige': motifLitige,
        if (quantitesRecues != null) 'quantites_recues': quantitesRecues,
      },
    );
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic> data) {
    final r = data['results'];
    if (r is List) return r.cast<Map<String, dynamic>>();
    return [];
  }
}
