import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/attempts_repository.dart';
import '../../core/api/production_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../plan/learning_plan_provider.dart';
import '../../core/utils/submission_key.dart';

/// Une "session EE" = 3 taches consecutives partageant 1 meme attempt parent.
/// L'attempt est cree une seule fois (au start), les submissions s'y rattachent.
class EeSessionState {
  const EeSessionState({
    required this.attempt,
    required this.tasks,
    required this.submissions,
    required this.isExam,
    this.slotNumber,
  });

  const EeSessionState.empty()
      : attempt = null,
        tasks = const [],
        submissions = const {},
        isExam = false,
        slotNumber = null;

  final Attempt? attempt;
  final List<ProductionTaskDto> tasks;
  // taskIndex -> submission. Une entree quand l'utilisateur a soumis cette tache.
  final Map<int, ProductionSubmissionDto> submissions;

  /// True pour une session d'examen blanc (3 tâches enchaînées, chrono, pas de
  /// correction entre les tâches). False pour l'entraînement libre mono-tâche.
  final bool isExam;

  /// Slot d'examen blanc module (1-10) — null en full exam et en single-task.
  final int? slotNumber;

  bool get isStarted => attempt != null && tasks.isNotEmpty;
  int get totalTasks => tasks.length;
  bool get isCompleted => isStarted && submissions.length >= totalTasks;

  bool isTaskSubmitted(int index) => submissions.containsKey(index);

  ProductionTaskDto? taskAt(int index) =>
      (index >= 0 && index < tasks.length) ? tasks[index] : null;

  EeSessionState copyWith({
    Attempt? attempt,
    List<ProductionTaskDto>? tasks,
    Map<int, ProductionSubmissionDto>? submissions,
    bool? isExam,
    int? slotNumber,
  }) =>
      EeSessionState(
        attempt: attempt ?? this.attempt,
        tasks: tasks ?? this.tasks,
        submissions: submissions ?? this.submissions,
        isExam: isExam ?? this.isExam,
        slotNumber: slotNumber ?? this.slotNumber,
      );
}

class EeSessionNotifier extends StateNotifier<AsyncValue<EeSessionState>> {
  EeSessionNotifier(
    this._repo,
    this._attempts, {
    void Function()? onPlanChanged,
  })  : _onPlanChanged = onPlanChanged ?? _noop,
        super(const AsyncData(EeSessionState.empty()));

  final ProductionRepository _repo;

  /// Une cle par (session, tache) : renvoyer la meme tache apres une coupure ne
  /// doit ni facturer deux corrections ni consommer deux fois le quota.
  final SubmissionKeys _keys = SubmissionKeys();
  final AttemptsRepository _attempts;
  final void Function() _onPlanChanged;

  /// (Re)demarre une **session d'examen blanc module** sur le slot donné :
  /// - cree un attempt d'examen (`exam:true, slotNumber:N`) qui porte
  ///   `timeLimitSeconds` (30 min pour l'EE, servi par le backend) + `startedAt`,
  /// - charge les **3 tâches déterministes** du slot via `getExamTasks`.
  /// Si une session est deja en cours pour le meme slot et pas encore
  /// terminee, on la conserve telle quelle (pour ne pas perdre le progress
  /// quand l'utilisateur revient sur le briefing).
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
        epreuve: EpreuveType.tcfEe,
        exam: true,
        slotNumber: slotNumber,
      );
      final tasks = await _repo.getExamTasks(attempt.id);
      if (tasks.isEmpty) {
        throw StateError('Aucune tâche EE pour cet examen.');
      }
      return EeSessionState(
        attempt: attempt,
        tasks: tasks,
        submissions: const {},
        isExam: true,
        slotNumber: slotNumber,
      );
    });
  }

  /// Demarre une session "single-task" (mode entrainement libre depuis le hub).
  /// Voir EoSessionNotifier.startSingle pour le contrat detaille.
  Future<void> startSingle({required ProductionTaskDto task}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final attempt =
          await _repo.startProductionAttempt(epreuve: EpreuveType.tcfEe);
      return EeSessionState(
        attempt: attempt,
        tasks: [task],
        submissions: const {},
        isExam: false,
      );
    });
  }

  /// Démarre une session EE 3-tâches **dans le cadre d'un examen blanc TCF
  /// complet** : l'attempt parent est le sous-attempt `TCF_EE` déjà créé par
  /// `FullTcfExamService.start`. On ne POST pas un nouvel attempt, on reprend
  /// l'id fourni en paramètre.
  ///
  /// Si la session est déjà en cours pour ce même sous-attempt, on la garde
  /// pour ne pas perdre la progression entre T1/T2/T3.
  ///
  /// 🛑 **Le sous-attempt est LU sur le serveur**, il n'est pas fabriqué : son
  /// `startedAt` a été recalé sur le lancement réel de l'épreuve par
  /// `POST /api/full-tcf-exams/{id}/begin`, et il porte son `timeLimitSeconds`
  /// (30 min). Ancrer le chrono sur `DateTime.now()` côté front, comme avant,
  /// remettait 30 minutes au candidat à chaque réouverture — or quitter ne
  /// suspend rien.
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
      // Composition déterministe du sous-attempt EE (3 tâches selon le slot du
      // parent + niveau cible — géré backend, transparent ici).
      final tasks = await _repo.getExamTasks(subAttemptId);
      if (tasks.isEmpty) {
        throw StateError('Aucune tâche EE pour cet examen.');
      }
      final attempt = await _attempts.getById(subAttemptId);
      return EeSessionState(
        attempt: attempt,
        tasks: tasks,
        submissions: const {},
        isExam: true,
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
      clientSubmissionId: _keys.keyFor('$attemptId:${task.id}'),
    );
    final updated = {...current.submissions, taskIndex: submission};
    state = AsyncData(current.copyWith(submissions: updated));
    _onPlanChanged();
    return submission;
  }

  /// Re-fetch la submission de la tâche `taskIndex` depuis le backend et la
  /// remet à jour dans le state. Utilisé par le bilan de session 3-tâches
  /// pour poller l'évaluation IA (Claude) tant que la submission n'est pas
  /// dans un statut final (`EVALUATED` ou `FAILED`).
  Future<void> refreshSubmission(int taskIndex) async {
    final current = state.value;
    if (current == null) return;
    final existing = current.submissions[taskIndex];
    if (existing == null) return;
    final fresh = await _repo.getSubmission(existing.id);
    final updated = {...current.submissions, taskIndex: fresh};
    state = AsyncData(current.copyWith(submissions: updated));
    if (fresh.statut.isFinal) _onPlanChanged();
  }

  /// Finalise l'attempt d'examen courant (`POST /finish`). À appeler après la
  /// dernière soumission acquittée, à l'expiration du chrono ou à l'abandon
  /// confirmé. Best-effort : une erreur (déjà fini) est avalée. No-op hors
  /// examen module (full exam : finalisation via `markSubDone`).
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

  /// Reinitialise (apres avoir termine les 3 taches ou quand l'utilisateur
  /// veut recommencer depuis zero).
  void reset() {
    state = const AsyncData(EeSessionState.empty());
  }
}

final eeSessionProvider =
    StateNotifierProvider<EeSessionNotifier, AsyncValue<EeSessionState>>(
  (ref) => EeSessionNotifier(
    ref.watch(productionRepositoryProvider),
    ref.watch(attemptsRepositoryProvider),
    onPlanChanged: () =>
        ref.read(learningPlanRevisionProvider.notifier).state++,
  ),
);

void _noop() {}
