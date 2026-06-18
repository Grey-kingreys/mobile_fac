import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache local pour les réponses API + queue d'opérations offline.
///
/// Usage :
///   // Sauvegarder une réponse API
///   await OfflineCacheService.instance.put('stocks_depot_1', jsonData);
///
///   // Lire le cache
///   final data = await OfflineCacheService.instance.get('stocks_depot_1');
///
///   // Ajouter une opération offline
///   await OfflineCacheService.instance.enqueue(PendingOperation(...));
class OfflineCacheService {
  OfflineCacheService._();
  static final instance = OfflineCacheService._();

  static const _cachePrefix = 'cache_';
  static const _queueKey = 'offline_queue';
  static const _ttlPrefix = 'ttl_';

  // ── Cache API ───────────────────────────────────────────────────────────────

  /// Stocke [value] (JSON encodé) sous la clé [key].
  /// [ttlMinutes] = durée de validité en minutes (null = pas d'expiration).
  Future<void> put(
    String key,
    dynamic value, {
    int? ttlMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachePrefix + key, jsonEncode(value));
    if (ttlMinutes != null) {
      final expiry = DateTime.now()
          .add(Duration(minutes: ttlMinutes))
          .millisecondsSinceEpoch;
      await prefs.setInt(_ttlPrefix + key, expiry);
    }
  }

  /// Retourne la valeur en cache ou null si absente / expirée.
  Future<dynamic> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ttl = prefs.getInt(_ttlPrefix + key);
    if (ttl != null && DateTime.now().millisecondsSinceEpoch > ttl) {
      await _remove(prefs, key);
      return null;
    }
    final raw = prefs.getString(_cachePrefix + key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  /// Supprime une entrée du cache.
  Future<void> invalidate(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await _remove(prefs, key);
  }

  /// Vide tout le cache (pas la queue).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  Future<void> _remove(SharedPreferences prefs, String key) async {
    await prefs.remove(_cachePrefix + key);
    await prefs.remove(_ttlPrefix + key);
  }

  // ── Queue offline ────────────────────────────────────────────────────────────
  // Les opérations créées sans connexion sont stockées ici et rejouées
  // à la prochaine synchronisation.

  Future<List<PendingOperation>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_queueKey) ?? [];
    return raw
        .map((e) => PendingOperation.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> enqueue(PendingOperation op) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode(op.toJson()));
    await prefs.setStringList(_queueKey, queue);
  }

  Future<void> dequeue(String operationId) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    queue.removeWhere((e) {
      final op = PendingOperation.fromJson(jsonDecode(e));
      return op.id == operationId;
    });
    await prefs.setStringList(_queueKey, queue);
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  /// Nombre d'opérations en attente de synchronisation.
  Future<int> pendingCount() async {
    final queue = await getQueue();
    return queue.length;
  }
}

// ── Clés de cache prédéfinies ─────────────────────────────────────────────────

abstract class CacheKeys {
  static String stocks(int depotId) => 'stocks_$depotId';
  static String missionList() => 'missions_list';
  static String mission(int id) => 'mission_$id';
  static String dashboard() => 'dashboard_kpis';
  static String products() => 'products_list';
  static String clients() => 'clients_list';
  static String notifications() => 'notifications';
  static String cashSession(int depotId) => 'cash_session_$depotId';
}

// ── Opération en attente de synchronisation ───────────────────────────────────

class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final PendingOperationType type;
  final String endpoint;
  final String method; // POST, PUT, PATCH
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  factory PendingOperation.fromJson(Map<String, dynamic> json) =>
      PendingOperation(
        id: json['id'] as String,
        type: PendingOperationType.values.byName(json['type'] as String),
        endpoint: json['endpoint'] as String,
        method: json['method'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}

enum PendingOperationType {
  createSale,
  createMovement,
  updateAttendance,
  sendGpsPosition,
  submitSignature,
}
