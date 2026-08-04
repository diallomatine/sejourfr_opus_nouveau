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
    required this.attempt,
    required this.tasks,
    required this.submissions,
    required this.isExam,
    this.slotNumber,
  });

  const EoSessionState.empty()
      : attempt = null,
        tasks = const [],
        submissions = const {},
        isExam = false,
        slotNumber = null;

  final Attempt? attempt;
  final List<ProductionTaskDto> tasks;
  final Map<int, ProductionSubmissionDto> submissions;

  /// True pour une session d'examen blanc (3 tâches enchaînées, décompte par
  /// tâche, soumission immédiate au stop). False pour l'entraînement libre.
  final bool isExam;

  /// Slot d'examen blanc module (1-10) — null en full exam et en single-task.
  final int? slotNumber;

  bool get isStarted => attempt != null && tasks.isNotEmpty;
  int get totalTasks => tasks.length;
  bool get isCompleted => isStarted && submissions.length >= totalTasks;

  ProductionTaskDto? taskAt(int index) =>
      (index >= 0 && index < tasks.length) ? tasks[index] : null;

  EoSessionState copyWith({
    Attempt? attempt,
    List<ProductionTaskDto>? tasks,
    Map<int, ProductionSubmissionDto>? submissions,
    bool? isExam,
    int? slotNumber,
  }) =>
      EoSessionState(
        attempt: attempt ?? this.attempt,
        tasks: tasks ?? this.tasks,
        submissions: submissions ?? this.submissions,
        isExam: isExam ?? this.isExam,
        slotNumber: slotNumber ?? this.slotNumber,
      );
}

class EoSessionNotifier extends StateNotifier<AsyncValue<EoSessionState>> {
  EoSessionNotifier(this._repo) : super(const AsyncData(EoSessionState.empty()));

  final ProductionRepository _repo;

  /// (Re)demarre une **session d'examen blanc module EO** sur le slot donné :
  /// crée un attempt d'examen (`exam:true, slotNumber:N`) puis charge les 3
  /// tâches déterministes du slot. L'`AttemptResponse` porte `timeLimitSeconds`
  /// (900 s pour l'EO, 1800 pour l'EE) : le briefing en fait un chrono global
  /// qui court à travers les 3 tâches, en plus du décompte par tâche basé sur
  /// `dureeMaxSec`.
  Future<void> startExam({required int slotNumber}) async {
    final current = state.value;
    if (current != null &&
        current.isStarted &&
        current.isExam &&
        current.slotNumber == slotNumber &&
        !current.isCompleted) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final attempt = await _repo.startProductionAttempt(
        epreuve: EpreuveType.tcfEo,
        exam: true,
        slotNumber: slotNumber,
      );
      final tasks = await _repo.getExamTasks(attempt.id);
      if (tasks.isEmpty) {
        throw StateError('Aucune tâche EO pour cet examen.');
      }
      return EoSessionState(
        attempt: attempt,
        tasks: tasks,
        submissions: const {},
        isExam: true,
        slotNumber: slotNumber,
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
        attempt: attempt,
        tasks: [task],
        submissions: const {},
        isExam: false,
      );
    });
  }

  /// Démarre une session EO 3-tâches **dans le cadre d'un examen blanc TCF
  /// complet** : on reprend le sous-attempt `TCF_EO` déjà créé par
  /// `FullTcfExamService.start` au lieu de POST un nouvel attempt, et on charge
  /// les 3 tâches déterministes via `getExamTasks`.
  Future<void> startInFullExam({required String subAttemptId}) async {
    final current = state.value;
    if (current != null &&
        current.attempt?.id == subAttemptId &&
        current.isStarted &&
        !current.isCompleted) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final tasks = await _repo.getExamTasks(subAttemptId);
      if (tasks.isEmpty) {
        throw StateError('Aucune tâche EO pour cet examen.');
      }
      final attempt = Attempt(
        id: subAttemptId,
        type: AttemptType.training,
        module: AppModule.tcf,
        totalQuestions: 0,
        startedAt: DateTime.now(),
        questions: const [],
      );
      return EoSessionState(
        attempt: attempt,
        tasks: tasks,
        submissions: const {},
        isExam: true,
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

  /// Re-fetch la submission de la tâche `taskIndex` depuis le backend et la
  /// remet à jour dans le state. Utilisé par le bilan de session 3-tâches
  /// pour poller l'évaluation IA (Whisper + Claude) tant que la submission
  /// n'est pas dans un statut final (`EVALUATED` ou `FAILED`).
  Future<void> refreshSubmission(int taskIndex) async {
    final current = state.value;
    if (current == null) return;
    final existing = current.submissions[taskIndex];
    if (existing == null) return;
    final fresh = await _repo.getSubmission(existing.id);
    final updated = {...current.submissions, taskIndex: fresh};
    state = AsyncData(current.copyWith(submissions: updated));
  }

  /// Finalise l'attempt d'examen courant (`POST /finish`). À appeler après la
  /// dernière soumission acquittée ou à l'abandon confirmé. Best-effort. No-op
  /// hors examen module (full exam : finalisation via `markSubDone`).
  Future<void> finishAttemptIfExam() async {
    final current = state.value;
    final attemptId = current?.attempt?.id;
    if (current == null || !current.isExam || attemptId == null) return;
    try {
      await _repo.finishAttempt(attemptId);
    } catch (_) {
      /* déjà fini / réseau : le bilan lira l'état réel */
    }
  }

  void reset() {
    state = const AsyncData(EoSessionState.empty());
  }
}

final eoSessionProvider =
    StateNotifierProvider<EoSessionNotifier, AsyncValue<EoSessionState>>(
  (ref) => EoSessionNotifier(ref.watch(productionRepositoryProvider)),
);
