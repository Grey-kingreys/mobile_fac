import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:djoulagest_mobile/features/finance/domain/entities/caisse_entity.dart';

final _financeDsProvider = Provider<FinanceRemoteDatasource>(
  (ref) => FinanceRemoteDatasource(ref.read(apiClientProvider)),
);

// ─── Caisses physiques ────────────────────────────────────────────────────────

class CaissesState {
  const CaissesState({
    this.physiques = const [],
    this.zones = const [],
    this.entreprise,
  });
  final List<CaissePhysiqueEntity> physiques;
  final List<CaisseZoneEntity> zones;
  final CaisseEntrepriseEntity? entreprise;

  CaissesState copyWith({
    List<CaissePhysiqueEntity>? physiques,
    List<CaisseZoneEntity>? zones,
    CaisseEntrepriseEntity? entreprise,
  }) =>
      CaissesState(
        physiques: physiques ?? this.physiques,
        zones: zones ?? this.zones,
        entreprise: entreprise ?? this.entreprise,
      );
}

class CaissesNotifier extends AsyncNotifier<CaissesState> {
  @override
  Future<CaissesState> build() => _load();

  Future<CaissesState> _load() async {
    final ds = ref.read(_financeDsProvider);
    final results = await Future.wait([
      ds.getCaisses(),
      ds.getCaissesZone(),
      ds.getCaisseEntreprise(),
    ]);
    return CaissesState(
      physiques: results[0] as List<CaissePhysiqueEntity>,
      zones: results[1] as List<CaisseZoneEntity>,
      entreprise: results[2] as CaisseEntrepriseEntity?,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<String?> createCaisse({
    required String nom,
    required int depotId,
    String devise = 'GNF',
  }) async {
    try {
      final caisse = await ref.read(_financeDsProvider).createCaisse(
            nom: nom,
            depotId: depotId,
            devise: devise,
          );
      final current = state.valueOrNull ?? const CaissesState();
      state = AsyncData(current.copyWith(
        physiques: [...current.physiques, caisse],
      ));
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> fermerCaisse(int id) async {
    try {
      final updated = await ref.read(_financeDsProvider).fermerCaisse(id);
      final current = state.valueOrNull ?? const CaissesState();
      state = AsyncData(current.copyWith(
        physiques: current.physiques
            .map((c) => c.id == id ? updated : c)
            .toList(),
      ));
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> createCaisseZone({
    required String nom,
    required int zoneId,
    String devise = 'GNF',
  }) async {
    try {
      final caisse = await ref.read(_financeDsProvider).createCaisseZone(
            nom: nom,
            zoneId: zoneId,
            devise: devise,
          );
      final current = state.valueOrNull ?? const CaissesState();
      state = AsyncData(current.copyWith(
        zones: [...current.zones, caisse],
      ));
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> fermerCaisseZone(int id) async {
    try {
      final updated = await ref.read(_financeDsProvider).fermerCaisseZone(id);
      final current = state.valueOrNull ?? const CaissesState();
      state = AsyncData(current.copyWith(
        zones: current.zones.map((c) => c.id == id ? updated : c).toList(),
      ));
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}

final caissesProvider =
    AsyncNotifierProvider<CaissesNotifier, CaissesState>(CaissesNotifier.new);
