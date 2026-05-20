import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/production_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';

/// Une "session EE" = 3 taches consecutives partageant 1 meme attempt parent.
/// L'attempt est cree une seule fois (au start), les submissions s'y rattachent.
class EeSessionState {
  const EeSessionState({
    required this.niveau,
    required this.attempt,
    required this.tasks,
    required this.submissions,
  });

  const EeSessionState.empty()
      : niveau = null,
        attempt = null,
        tasks = const [],
        submissions = const {};

  final String? niveau;
  final Attempt? attempt;
  final List<ProductionTaskDto> tasks;
  // taskIndex -> submission. Une entree quand l'utilisateur a soumis cette tache.
  final Map<int, ProductionSubmissionDto> submissions;

  bool get isStarted => attempt != null && tasks.isNotEmpty;
  int get totalTasks => tasks.length;
  bool get isCompleted => isStarted && submissions.length >= totalTasks;

  bool isTaskSubmitted(int index) => submissions.containsKey(index);

  ProductionTaskDto? taskAt(int index) =>
      (index >= 0 && index < tasks.length) ? tasks[index] : null;

  EeSessionState copyWith({
    String? niveau,
    Attempt? attempt,
    List<ProductionTaskDto>? tasks,
    Map<int, ProductionSubmissionDto>? submissions,
  }) =>
      EeSessionState(
        niveau: niveau ?? this.niveau,
        attempt: attempt ?? this.attempt,
        tasks: tasks ?? this.tasks,
        submissions: submissions ?? this.submissions,
      );
}

class EeSessionNotifier extends StateNotifier<AsyncValue<EeSessionState>> {
  EeSessionNotifier(this._repo) : super(const AsyncData(EeSessionState.empty()));

  final ProductionRepository _repo;

  /// (Re)demarre une session :
  /// - charge le catalogue de taches pour le niveau,
  /// - cree un attempt vide.
  /// Si une session est deja en cours pour le meme niveau et pas encore
  /// terminee, on la conserve telle quelle (pour ne pas perdre le progress
  /// quand l'utilisateur revient sur le briefing).
  Future<void> start({required String niveau}) async {
    final current = state.value;
    if (current != null &&
        current.isStarted &&
        current.niveau == niveau &&
        !current.isCompleted) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final tasks = await _repo.listTasks(epreuve: EpreuveType.tcfEe, niveau: niveau);
      if (tasks.isEmpty) {
        throw StateError('Aucune tache EE disponible pour le niveau $niveau.');
      }
      final attempt = await _repo.startProductionAttempt(epreuve: EpreuveType.tcfEe);
      return EeSessionState(
        niveau: niveau,
        attempt: attempt,
        tasks: tasks,
        submissions: const {},
      );
    });
  }

  /// Soumet la tache courante et enregistre la submission dans le state.
  /// Retourne la submission (le caller peut naviguer vers les resultats avec son id).
  Future<ProductionSubmissionDto> submitTask({
    required int taskIndex,
    required String texte,
  }) async {
    final current = state.value;
    if (current == null || !current.isStarted) {
      throw StateError('La session n\'est pas demarree.');
    }
    final task = current.taskAt(taskIndex);
    if (task == null) {
      throw StateError('Tache $taskIndex introuvable.');
    }
    final attemptId = current.attempt!.id;
    final submission = await _repo.submitText(
      productionTaskId: task.id,
      attemptId: attemptId,
      texte: texte,
    );
    final updated = {...current.submissions, taskIndex: submission};
    state = AsyncData(current.copyWith(submissions: updated));
    return submission;
  }

  /// Reinitialise (apres avoir termine les 3 taches ou quand l'utilisateur
  /// veut recommencer depuis zero).
  void reset() {
    state = const AsyncData(EeSessionState.empty());
  }
}

final eeSessionProvider =
    StateNotifierProvider<EeSessionNotifier, AsyncValue<EeSessionState>>(
  (ref) => EeSessionNotifier(ref.watch(productionRepositoryProvider)),
);
