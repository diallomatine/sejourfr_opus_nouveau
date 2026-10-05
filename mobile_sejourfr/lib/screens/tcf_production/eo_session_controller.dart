import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/attempts_repository.dart';
import '../../core/api/production_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../plan/learning_plan_provider.dart';
import 'production_exam_corrections.dart';
import '../../core/utils/submission_key.dart';

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

  /// True pour une session d'examen blanc (3 tâches enchaînées, **décompte par
  /// tâche déclenché au « Je suis prêt »**, soumission immédiate au stop).
  /// False pour l'entraînement libre.
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
  EoSessionNotifier(
    this._repo,
    this._attempts, {
    void Function()? onPlanChanged,
  })  : _onPlanChanged = onPlanChanged ?? _noop,
        super(const AsyncData(EoSessionState.empty()));

  final ProductionRepository _repo;

  /// Une cle par PRISE (session, tache, numero de prise) : renvoyer le meme
  /// enregistrement apres une coupure ne doit ni repayer Whisper puis le
  /// correcteur, ni consommer deux fois le quota — mais « Recommencer » est une
  /// AUTRE production, donc une autre cle.
  final SubmissionKeys _keys = SubmissionKeys();

  /// Numero de la prise en cours, par index de tache : +1 a chaque demarrage
  /// d'enregistrement ([beginTake]).
  final Map<int, int> _takes = <int, int>{};

  /// Une nouvelle prise commence sur la tache [taskIndex] : la prochaine
  /// soumission de cette tache portera une nouvelle cle.
  void beginTake(int taskIndex) {
    _takes[taskIndex] = (_takes[taskIndex] ?? 0) + 1;
  }
  final AttemptsRepository _attempts;
  final void Function() _onPlanChanged;

  /// (Re)demarre une **session d'examen blanc module EO** sur le slot donné :
  /// crée un attempt d'examen (`exam:true, slotNumber:N`) puis charge les 3
  /// tâches déterministes du slot.
  ///
  /// ⚠️ **L'épreuve orale n'a pas de chrono d'épreuve** — `timeLimitSeconds` est
  /// désormais `null` (il valait 900 s). Le temps se compte **par tâche** et ne
  /// démarre qu'au moment où le candidat lance la tâche (« Je suis prêt ») ; la
  /// borne est `ProductionTaskDto.dureeMaxSec` (180 / 210 / 210 s).
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
      final attempt =
          await _repo.startProductionAttempt(epreuve: EpreuveType.tcfEo);
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
      // Sous-attempt LU sur le serveur, jamais fabriqué : c'est lui qui porte
      // l'état réel de l'épreuve (et son absence de chrono d'épreuve).
      final attempt = await _attempts.getById(subAttemptId);
      return EoSessionState(
        attempt: attempt,
        tasks: tasks,
        // 🛑 LES TÂCHES DÉJÀ RENDUES sont relues, plus supposées vides.
        // L'oral se chronomètre PAR TÂCHE : arrêter une tâche la termine, et
        // rouvrir l'épreuve ne doit reproposer que la SUIVANTE (arbitrage du
        // propriétaire, 2026-09-13). Sans ce relevé, on revenait toujours sur
        // la tâche 1 et le serveur la refusait (une tâche ne se soumet qu'une
        // fois par session).
        submissions: await _rendues(subAttemptId, tasks),
        isExam: true,
      );
    });
  }

  /// Les tâches **déjà rendues** de ce sous-attempt, indexées comme
  /// [EoSessionState.submissions] — par index de tâche dans la session.
  ///
  /// Une requête, à l'entrée de l'épreuve seulement. **Best-effort** : son
  /// échec rend une session vierge plutôt que d'empêcher d'enregistrer — le
  /// serveur reste l'arbitre (il refuse une tâche déjà soumise).
  Future<Map<int, ProductionSubmissionDto>> _rendues(
      String subAttemptId, List<ProductionTaskDto> tasks) async {
    try {
      final toutes = await _repo.listMine(limit: 60);
      final parTache = <int, ProductionSubmissionDto>{};
      for (final s in toutes) {
        if (s.attemptId != subAttemptId) continue;
        final index = tasks.indexWhere((t) => t.id == s.productionTaskId);
        if (index >= 0) parTache[index] = s;
      }
      return parTache;
    } catch (_) {
      return const {};
    }
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
    final attemptId = current.attempt!.id;
    final submission = await _repo.submitAudio(
      productionTaskId: task.id,
      attemptId: attemptId,
      audioFile: audioFile,
      mimeType: mimeType,
      clientSubmissionId:
          _keys.keyFor('$attemptId:${task.id}:${_takes[taskIndex] ?? 0}'),
    );
    final updated = {...current.submissions, taskIndex: submission};
    state = AsyncData(current.copyWith(submissions: updated));
    _onPlanChanged();
    return submission;
  }

  /// Après un échec d'envoi : relit les soumissions de la session. Une coupure
  /// APRÈS la réception serveur laisse la tâche rendue alors que l'écran croit
  /// à un échec — dans ce cas on l'inscrit et on rend la soumission, sinon
  /// `null` (l'enregistrement reste sur l'appareil, le candidat réessaie).
  Future<ProductionSubmissionDto?> syncTaskIfRendered(int taskIndex) async {
    final current = state.value;
    final attemptId = current?.attempt?.id;
    final task = current?.taskAt(taskIndex);
    if (current == null || attemptId == null || task == null) return null;
    try {
      final toutes = await _repo.listMine(limit: 60);
      final rendue = toutes
          .where((s) => s.attemptId == attemptId && s.productionTaskId == task.id)
          .firstOrNull;
      if (rendue == null) return null;
      final updated = {...current.submissions, taskIndex: rendue};
      state = AsyncData(current.copyWith(submissions: updated));
      _onPlanChanged();
      return rendue;
    } catch (_) {
      return null;
    }
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
      // 🛑 La clôture est une mesure : la relecture émise à la dernière
      // soumission partait AVANT elle, et rendait le Plan d'avant l'examen.
      _onPlanChanged();
    } catch (_) {
      /* déjà fini / réseau : le bilan lira l'état réel */
    }
    // 🛑 Les priorités de l'examen arrivent avec ses corrections, après le
    // `finish` : ce suivi relit le compte quand elles ont atterri.
    unawaited(relireApresLesCorrections(
      repo: _repo,
      attemptId: attemptId,
      epreuve: EpreuveType.tcfEo,
      onPlanChanged: _onPlanChanged,
    ));
  }

  void reset() {
    _takes.clear();
    state = const AsyncData(EoSessionState.empty());
  }
}

final eoSessionProvider =
    StateNotifierProvider<EoSessionNotifier, AsyncValue<EoSessionState>>(
  (ref) => EoSessionNotifier(
    ref.watch(productionRepositoryProvider),
    ref.watch(attemptsRepositoryProvider),
    onPlanChanged: () =>
        ref.read(learningPlanRevisionProvider.notifier).state++,
  ),
);

void _noop() {}
