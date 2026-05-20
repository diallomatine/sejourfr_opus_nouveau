import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/production_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';

/// Etat du hub d'entrainement EO/EE.
///
/// On charge en parallele :
///   - les 3 listes de taches (filtrees par tacheNumero=1/2/3) actives pour
///     le niveau de l'utilisateur ;
///   - la derniere submission de l'utilisateur par numero de tache.
///
/// Pour T1 (presentation) la liste contient en general une seule tache fixe.
/// Pour T2 et T3, on tire au hasard une consigne a chaque entree sur le hub.
/// L'utilisateur peut re-roller via [HubNotifier.rerollTask].
class ProductionHubState {
  const ProductionHubState({
    required this.niveau,
    required this.tasksByNumero,
    required this.picked,
    required this.lastByNumero,
  });

  const ProductionHubState.empty()
      : niveau = '',
        tasksByNumero = const {},
        picked = const {},
        lastByNumero = const {};

  /// Niveau cible pour lequel ces tasks ont ete chargees (A2/B1/B2).
  final String niveau;

  /// Toutes les tasks actives groupees par numero (1/2/3).
  final Map<int, List<ProductionTaskDto>> tasksByNumero;

  /// Task selectionnee a presenter sur chaque card.
  final Map<int, ProductionTaskDto> picked;

  /// Derniere submission de l'utilisateur par numero de tache (0..3 entries).
  final Map<int, ProductionSubmissionDto> lastByNumero;

  bool get isReady => picked.isNotEmpty;

  ProductionHubState copyWith({
    String? niveau,
    Map<int, List<ProductionTaskDto>>? tasksByNumero,
    Map<int, ProductionTaskDto>? picked,
    Map<int, ProductionSubmissionDto>? lastByNumero,
  }) =>
      ProductionHubState(
        niveau: niveau ?? this.niveau,
        tasksByNumero: tasksByNumero ?? this.tasksByNumero,
        picked: picked ?? this.picked,
        lastByNumero: lastByNumero ?? this.lastByNumero,
      );
}

class ProductionHubNotifier
    extends StateNotifier<AsyncValue<ProductionHubState>> {
  ProductionHubNotifier(this._repo, this._epreuve)
      : super(const AsyncData(ProductionHubState.empty()));

  final ProductionRepository _repo;
  final EpreuveType _epreuve;
  final _rng = Random();

  /// Charge les 3 listes de tasks + lastPerTask pour le niveau donne.
  /// Pour T1, on prend toujours la premiere consigne (ordre createdAt). Pour
  /// T2/T3, on pick au hasard.
  Future<void> load({required String niveau}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final results = await Future.wait<dynamic>([
        _repo.listTasks(epreuve: _epreuve, niveau: niveau, tacheNumero: 1),
        _repo.listTasks(epreuve: _epreuve, niveau: niveau, tacheNumero: 2),
        _repo.listTasks(epreuve: _epreuve, niveau: niveau, tacheNumero: 3),
        _repo.listLastPerTask(epreuve: _epreuve, niveau: niveau),
      ]);

      final t1 = results[0] as List<ProductionTaskDto>;
      final t2 = results[1] as List<ProductionTaskDto>;
      final t3 = results[2] as List<ProductionTaskDto>;
      final last = results[3] as List<ProductionSubmissionDto>;

      final tasks = <int, List<ProductionTaskDto>>{1: t1, 2: t2, 3: t3};

      final picked = <int, ProductionTaskDto>{};
      if (t1.isNotEmpty) picked[1] = t1.first;
      if (t2.isNotEmpty) picked[2] = t2[_rng.nextInt(t2.length)];
      if (t3.isNotEmpty) picked[3] = t3[_rng.nextInt(t3.length)];

      final lastMap = <int, ProductionSubmissionDto>{};
      for (final sub in last) {
        final n = sub.tacheNumero;
        if (n != null) lastMap[n] = sub;
      }

      return ProductionHubState(
        niveau: niveau,
        tasksByNumero: tasks,
        picked: picked,
        lastByNumero: lastMap,
      );
    });
  }

  /// Re-pick une tache au hasard pour [tacheNumero] (different de la courante
  /// si possible). Utilise depuis le bouton "Changer de sujet" sur la card.
  void rerollTask(int tacheNumero) {
    final current = state.value;
    if (current == null) return;
    final pool = current.tasksByNumero[tacheNumero] ?? const [];
    if (pool.length <= 1) return;
    final currentId = current.picked[tacheNumero]?.id;
    ProductionTaskDto next;
    var attempts = 0;
    do {
      next = pool[_rng.nextInt(pool.length)];
      attempts++;
    } while (next.id == currentId && attempts < 10);
    state = AsyncData(current.copyWith(
      picked: {...current.picked, tacheNumero: next},
    ));
  }

  /// Recharge lastPerTask seulement (utile au retour d'un flow tache pour
  /// rafraichir les badges de note sans re-roller les picks).
  Future<void> refreshLast() async {
    final current = state.value;
    if (current == null || current.niveau.isEmpty) return;
    try {
      final last = await _repo.listLastPerTask(
        epreuve: _epreuve,
        niveau: current.niveau,
      );
      final lastMap = <int, ProductionSubmissionDto>{};
      for (final sub in last) {
        final n = sub.tacheNumero;
        if (n != null) lastMap[n] = sub;
      }
      state = AsyncData(current.copyWith(lastByNumero: lastMap));
    } catch (_) {
      // silencieux : le hub reste utilisable meme si la requete echoue.
    }
  }
}

/// Family indexee par EpreuveType (un hub par epreuve).
final productionHubProvider = StateNotifierProvider.family<
    ProductionHubNotifier, AsyncValue<ProductionHubState>, EpreuveType>(
  (ref, epreuve) =>
      ProductionHubNotifier(ref.watch(productionRepositoryProvider), epreuve),
);
