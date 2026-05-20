import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/production_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';

/// Une "session EO" = 3 taches consecutives partageant 1 meme attempt parent.
/// Similaire a EeSessionController mais pour l'oral.
class EoSessionState {
  const EoSessionState({
    required this.niveau,
    required this.attempt,
    required this.tasks,
    required this.submissions,
  });

  const EoSessionState.empty()
      : niveau = null,
        attempt = null,
        tasks = const [],
        submissions = const {};

  final String? niveau;
  final Attempt? attempt;
  final List<ProductionTaskDto> tasks;
  final Map<int, ProductionSubmissionDto> submissions;

  bool get isStarted => attempt != null && tasks.isNotEmpty;
  int get totalTasks => tasks.length;
  bool get isCompleted => isStarted && submissions.length >= totalTasks;

  ProductionTaskDto? taskAt(int index) =>
      (index >= 0 && index < tasks.length) ? tasks[index] : null;

  EoSessionState copyWith({
    String? niveau,
    Attempt? attempt,
    List<ProductionTaskDto>? tasks,
    Map<int, ProductionSubmissionDto>? submissions,
  }) =>
      EoSessionState(
        niveau: niveau ?? this.niveau,
        attempt: attempt ?? this.attempt,
        tasks: tasks ?? this.tasks,
        submissions: submissions ?? this.submissions,
      );
}

class EoSessionNotifier extends StateNotifier<AsyncValue<EoSessionState>> {
  EoSessionNotifier(this._repo) : super(const AsyncData(EoSessionState.empty()));

  final ProductionRepository _repo;

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
      final tasks = await _repo.listTasks(epreuve: EpreuveType.tcfEo, niveau: niveau);
      if (tasks.isEmpty) {
        throw StateError("Aucune tache EO disponible pour le niveau $niveau.");
      }
      final attempt = await _repo.startProductionAttempt(epreuve: EpreuveType.tcfEo);
      return EoSessionState(
        niveau: niveau,
        attempt: attempt,
        tasks: tasks,
        submissions: const {},
      );
    });
  }

  /// Demarre une session "single-task" (mode entrainement libre depuis le hub).
  /// La liste tasks ne contient qu'une seule entree → totalTasks = 1, pas de
  /// chainage T+1, les ecrans existants (briefing/recording/finished/results)
  /// fonctionnent en mode degrade et le results screen detecte totalTasks==1
  /// pour proposer "Retour aux taches" au lieu de "Voir mon bilan".
  Future<void> startSingle({required ProductionTaskDto task}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final attempt = await _repo.startProductionAttempt(epreuve: EpreuveType.tcfEo);
      return EoSessionState(
        niveau: task.niveauCible,
        attempt: attempt,
        tasks: [task],
        submissions: const {},
      );
    });
  }

  /// Envoie l'audio enregistre au backend et stocke la submission dans le state.
  Future<ProductionSubmissionDto> submitTask({
    required int taskIndex,
    required File audioFile,
    String? mimeType,
  }) async {
    final current = state.value;
    if (current == null || !current.isStarted) {
      throw StateError("La session n'est pas demarree.");
    }
    final task = current.taskAt(taskIndex);
    if (task == null) {
      throw StateError('Tache $taskIndex introuvable.');
    }
    final submission = await _repo.submitAudio(
      productionTaskId: task.id,
      attemptId: current.attempt!.id,
      audioFile: audioFile,
      mimeType: mimeType,
    );
    final updated = {...current.submissions, taskIndex: submission};
    state = AsyncData(current.copyWith(submissions: updated));
    return submission;
  }

  void reset() {
    state = const AsyncData(EoSessionState.empty());
  }
}

final eoSessionProvider =
    StateNotifierProvider<EoSessionNotifier, AsyncValue<EoSessionState>>(
  (ref) => EoSessionNotifier(ref.watch(productionRepositoryProvider)),
);
