import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/attempts_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';

/// État du runner pour un attempt donné.
class RunnerState {
  RunnerState({
    required this.attempt,
    required this.currentIndex,
    required this.answersByQuestion,
    this.lastResult,
    this.submitting = false,
    this.errorMessage,
  });

  final Attempt attempt;
  final int currentIndex;

  /// Pour chaque attemptQuestion.id, les choices sélectionnés par l'utilisateur.
  final Map<String, List<String>> answersByQuestion;

  /// Résultat de la dernière réponse soumise (mode entraînement uniquement).
  final AnswerResult? lastResult;
  final bool submitting;
  final String? errorMessage;

  AttemptQuestion get current => attempt.questions[currentIndex];

  bool get isLast => currentIndex >= attempt.questions.length - 1;

  /// On affiche la correction pour la question courante.
  bool get hasResult =>
      lastResult != null &&
      answersByQuestion[current.id] != null &&
      answersByQuestion[current.id]!.isNotEmpty;

  RunnerState copyWith({
    Attempt? attempt,
    int? currentIndex,
    Map<String, List<String>>? answersByQuestion,
    AnswerResult? lastResult,
    bool clearLastResult = false,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RunnerState(
        attempt: attempt ?? this.attempt,
        currentIndex: currentIndex ?? this.currentIndex,
        answersByQuestion: answersByQuestion ?? this.answersByQuestion,
        lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
        submitting: submitting ?? this.submitting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

/// Family : un controller par attemptId.
final runnerControllerProvider =
    StateNotifierProvider.family.autoDispose<RunnerController, AsyncValue<RunnerState>, String>(
  (ref, attemptId) => RunnerController(ref.watch(attemptsRepositoryProvider), attemptId),
);

class RunnerController extends StateNotifier<AsyncValue<RunnerState>> {
  RunnerController(this._repo, this._attemptId) : super(const AsyncValue.loading()) {
    _load();
  }

  final AttemptsRepository _repo;
  final String _attemptId;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final attempt = await _repo.getById(_attemptId);
      // Réhydrate les réponses déjà soumises (si on revient sur l'attempt)
      final answers = <String, List<String>>{
        for (final q in attempt.questions)
          if (q.selectedChoiceIds.isNotEmpty) q.id: q.selectedChoiceIds,
      };
      // Calcule l'index à reprendre : 1re question non répondue, sinon dernière
      final firstUnanswered = attempt.questions.indexWhere((q) => !q.answered);
      final startIndex = firstUnanswered == -1 ? attempt.questions.length - 1 : firstUnanswered;

      state = AsyncValue.data(RunnerState(
        attempt: attempt,
        currentIndex: startIndex.clamp(0, attempt.questions.length - 1),
        answersByQuestion: answers,
      ));
    } catch (e, st) {
      state = AsyncValue.error(ApiClient.toApiException(e), st);
    }
  }

  Future<void> retry() => _load();

  void toggleChoice(String choiceId) {
    final cur = state.valueOrNull;
    if (cur == null || cur.hasResult || cur.submitting) return;

    final qId = cur.current.id;
    final selected = List<String>.from(cur.answersByQuestion[qId] ?? const []);

    if (selected.contains(choiceId)) {
      selected.remove(choiceId);
    } else {
      // Single-choice : on remplace (à passer en multi-select si on a un jour des QCM multiples)
      selected
        ..clear()
        ..add(choiceId);
    }

    state = AsyncValue.data(cur.copyWith(
      answersByQuestion: {...cur.answersByQuestion, qId: selected},
      clearError: true,
    ));
  }

  Future<void> submitCurrent() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final qId = cur.current.id;
    final selected = cur.answersByQuestion[qId] ?? const [];
    if (selected.isEmpty) return;

    state = AsyncValue.data(cur.copyWith(submitting: true, clearError: true));
    try {
      final result = await _repo.submitAnswer(
        attemptId: _attemptId,
        attemptQuestionId: qId,
        choiceIds: selected,
      );
      state = AsyncValue.data(cur.copyWith(
        submitting: false,
        lastResult: result,
      ));
    } catch (e) {
      state = AsyncValue.data(cur.copyWith(
        submitting: false,
        errorMessage: ApiClient.toApiException(e).message,
      ));
    }
  }

  void goNext() {
    final cur = state.valueOrNull;
    if (cur == null || cur.isLast) return;
    state = AsyncValue.data(cur.copyWith(
      currentIndex: cur.currentIndex + 1,
      clearLastResult: true,
      clearError: true,
    ));
  }

  void goPrevious() {
    final cur = state.valueOrNull;
    if (cur == null || cur.currentIndex == 0) return;
    state = AsyncValue.data(cur.copyWith(
      currentIndex: cur.currentIndex - 1,
      clearLastResult: true,
      clearError: true,
    ));
  }

  /// Finalise l'attempt et renvoie l'attempt avec score.
  Future<Attempt?> finish() async {
    final cur = state.valueOrNull;
    if (cur == null) return null;
    state = AsyncValue.data(cur.copyWith(submitting: true));
    try {
      final finished = await _repo.finish(_attemptId);
      state = AsyncValue.data(cur.copyWith(
        attempt: finished,
        submitting: false,
      ));
      return finished;
    } catch (e) {
      state = AsyncValue.data(cur.copyWith(
        submitting: false,
        errorMessage: ApiClient.toApiException(e).message,
      ));
      return null;
    }
  }
}
