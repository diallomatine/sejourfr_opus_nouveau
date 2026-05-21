import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/attempts_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/api/user_content_repository.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';

/// Taille d'un batch en entraînement infini.
const _kTrainingBatchSize = 30;

/// État du runner pour un attempt donné.
///
/// En mode entraînement, on agrège plusieurs `Attempt` (batches successifs de
/// 30 questions) dans une liste cumulée. Chaque question porte l'id de
/// l'attempt auquel elle appartient (pour `submitAnswer`). Côté UI, c'est
/// vécu comme une session infinie.
///
/// En mode examen blanc, on reste sur un unique attempt de taille fixe.
class RunnerState {
  RunnerState({
    required this.activeAttempt,
    required this.questions,
    required this.attemptIdByQuestionId,
    required this.currentIndex,
    required this.answersByQuestion,
    this.favoriteQuestionIds = const <String>{},
    this.lastResult,
    this.submitting = false,
    this.extending = false,
    this.noMoreQuestions = false,
    this.errorMessage,
    this.fixedBatch = false,
  });

  /// IDs des Questions (et non des AttemptQuestion) marquées en favori.
  final Set<String> favoriteQuestionIds;

  /// Le dernier attempt chargé (= batch courant en entraînement).
  final Attempt activeAttempt;

  /// Liste cumulée des questions (un seul batch en examen, plusieurs en
  /// entraînement infini).
  final List<AttemptQuestion> questions;

  /// Mapping `attemptQuestionId → attemptId` (pour router `submitAnswer`).
  final Map<String, String> attemptIdByQuestionId;

  final int currentIndex;

  /// Pour chaque attemptQuestion.id, les choices sélectionnés par l'utilisateur.
  final Map<String, List<String>> answersByQuestion;

  /// Résultat de la dernière réponse soumise (mode entraînement uniquement).
  final AnswerResult? lastResult;
  final bool submitting;
  final bool extending;

  /// Vrai si la dernière tentative d'extension a renvoyé un batch vide
  /// (réservoir épuisé pour le filtre courant).
  final bool noMoreQuestions;

  final String? errorMessage;

  /// Vrai quand le runner doit traiter le training comme un batch fixe
  /// (lot TCF avec taille déterminée par le backend) : pas d'auto-extend,
  /// "Question X / N" affiché, bouton "Terminer" à la dernière question.
  final bool fixedBatch;

  AttemptQuestion get current => questions[currentIndex];

  /// Mode entraînement infini : on continue à charger des batches.
  /// Désactivé quand `fixedBatch` est true (cas des lots TCF qui ont une
  /// taille fixe ; on s'arrête à la dernière question, on ne rallonge pas).
  bool get isInfiniteTraining =>
      !fixedBatch && activeAttempt.type == AttemptType.training;

  /// En examen, `isLast` signale la dernière question du batch.
  /// En entraînement infini, n'est vrai que si on a épuisé la base.
  bool get isLast {
    if (isInfiniteTraining) {
      return noMoreQuestions && currentIndex >= questions.length - 1;
    }
    return currentIndex >= questions.length - 1;
  }

  String get currentAttemptId => attemptIdByQuestionId[current.id]!;

  /// Nombre de réponses soumises (pour un compteur motivant).
  int get answeredCount =>
      answersByQuestion.values.where((v) => v.isNotEmpty).length;

  /// On affiche la correction pour la question courante.
  bool get hasResult =>
      lastResult != null &&
      answersByQuestion[current.id] != null &&
      answersByQuestion[current.id]!.isNotEmpty;

  RunnerState copyWith({
    Attempt? activeAttempt,
    List<AttemptQuestion>? questions,
    Map<String, String>? attemptIdByQuestionId,
    int? currentIndex,
    Map<String, List<String>>? answersByQuestion,
    Set<String>? favoriteQuestionIds,
    AnswerResult? lastResult,
    bool clearLastResult = false,
    bool? submitting,
    bool? extending,
    bool? noMoreQuestions,
    String? errorMessage,
    bool clearError = false,
    bool? fixedBatch,
  }) =>
      RunnerState(
        activeAttempt: activeAttempt ?? this.activeAttempt,
        questions: questions ?? this.questions,
        attemptIdByQuestionId:
            attemptIdByQuestionId ?? this.attemptIdByQuestionId,
        currentIndex: currentIndex ?? this.currentIndex,
        answersByQuestion: answersByQuestion ?? this.answersByQuestion,
        favoriteQuestionIds: favoriteQuestionIds ?? this.favoriteQuestionIds,
        lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
        submitting: submitting ?? this.submitting,
        extending: extending ?? this.extending,
        noMoreQuestions: noMoreQuestions ?? this.noMoreQuestions,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        fixedBatch: fixedBatch ?? this.fixedBatch,
      );
}

/// Family : un controller par attemptId.
final runnerControllerProvider = StateNotifierProvider.family
    .autoDispose<RunnerController, AsyncValue<RunnerState>, String>(
  (ref, attemptId) {
    final auth = ref.watch(authControllerProvider);
    final isPremium = auth is AuthAuthenticated && auth.user.isPremium;
    return RunnerController(
      ref.watch(attemptsRepositoryProvider),
      ref.watch(userContentRepositoryProvider),
      attemptId,
      isPremium: isPremium,
    );
  },
);

class RunnerController extends StateNotifier<AsyncValue<RunnerState>> {
  RunnerController(
    this._repo,
    this._userContentRepo,
    this._attemptId, {
    required bool isPremium,
  })  : _isPremium = isPremium,
        super(const AsyncValue.loading()) {
    _load();
  }

  final AttemptsRepository _repo;
  final UserContentRepository _userContentRepo;
  final String _attemptId;
  final bool _isPremium;

  /// Filtres déduits du premier batch, pour pouvoir étendre la session
  /// d'entraînement avec les mêmes critères.
  AppModule? _trainingModule;
  String? _trainingThemeId;

  /// Demandé par l'écran (cf. `RunnerScreen.initState`) quand le runner doit
  /// se comporter comme un batch fixe (lot TCF). On garde la valeur en local
  /// pour qu'elle soit appliquée même si `setFixedBatch` est appelée pendant
  /// que `_load` est encore en `loading`.
  bool _pendingFixedBatch = false;

  /// Bascule le runner en mode "batch fixe" (pas d'extension auto, affichage
  /// "Question X / N"). Idempotent. Appelée par `RunnerScreen` après lecture
  /// du query `from=tcfLot` dans l'URL.
  void setFixedBatch(bool value) {
    _pendingFixedBatch = value;
    final s = state.valueOrNull;
    if (s != null && s.fixedBatch != value) {
      state = AsyncValue.data(s.copyWith(fixedBatch: value));
    }
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final attempt = await _repo.getById(_attemptId);
      final answers = <String, List<String>>{
        for (final q in attempt.questions)
          if (q.selectedChoiceIds.isNotEmpty) q.id: q.selectedChoiceIds,
      };
      final firstUnanswered = attempt.questions.indexWhere((q) => !q.answered);
      final startIndex = firstUnanswered == -1
          ? attempt.questions.length - 1
          : firstUnanswered;

      if (attempt.type == AttemptType.training) {
        _trainingModule = attempt.module;
        // Si toutes les questions partagent le même thème → on retient le filtre.
        // Sinon on considère qu'il n'y avait pas de filtre thème.
        final firstThemeId = attempt.questions.isNotEmpty
            ? attempt.questions.first.question.themeId
            : null;
        final allSameTheme = firstThemeId != null &&
            attempt.questions.every(
              (q) => q.question.themeId == firstThemeId,
            );
        _trainingThemeId = allSameTheme ? firstThemeId : null;
      }

      // Charge les favoris pour le module actif. Si ça échoue, on continue
      // sans : c'est juste un état d'affichage du bouton bookmark.
      Set<String> favorites = const {};
      try {
        final favList = await _userContentRepo.favorites(module: attempt.module);
        favorites = favList.map((q) => q.id).toSet();
      } catch (_) {}

      // En training démo (non-premium), la session est figée à ce batch :
      // pas d'extension possible, le runner doit savoir qu'il est sur la
      // dernière fournée.
      final demoCap = attempt.type == AttemptType.training && !_isPremium;

      state = AsyncValue.data(RunnerState(
        activeAttempt: attempt,
        questions: attempt.questions,
        attemptIdByQuestionId: {
          for (final q in attempt.questions) q.id: attempt.id,
        },
        currentIndex: startIndex.clamp(0, attempt.questions.length - 1),
        answersByQuestion: answers,
        favoriteQuestionIds: favorites,
        noMoreQuestions: demoCap,
        fixedBatch: _pendingFixedBatch,
      ));
    } catch (e, st) {
      state = AsyncValue.error(ApiClient.toApiException(e), st);
    }
  }

  /// Bascule l'état favori de la question courante. Mise à jour optimiste,
  /// rollback silencieux en cas d'erreur réseau.
  Future<void> toggleFavoriteCurrent() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final questionId = cur.current.question.id;
    final wasFavorite = cur.favoriteQuestionIds.contains(questionId);

    final next = Set<String>.from(cur.favoriteQuestionIds);
    if (wasFavorite) {
      next.remove(questionId);
    } else {
      next.add(questionId);
    }
    state = AsyncValue.data(cur.copyWith(favoriteQuestionIds: next));

    try {
      if (wasFavorite) {
        await _userContentRepo.removeFavorite(questionId);
      } else {
        await _userContentRepo.addFavorite(questionId);
      }
    } catch (_) {
      final after = state.valueOrNull;
      if (after == null) return;
      final reverted = Set<String>.from(after.favoriteQuestionIds);
      if (wasFavorite) {
        reverted.add(questionId);
      } else {
        reverted.remove(questionId);
      }
      state = AsyncValue.data(after.copyWith(favoriteQuestionIds: reverted));
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

    final attemptIdForQ = cur.attemptIdByQuestionId[qId] ?? cur.activeAttempt.id;

    state = AsyncValue.data(cur.copyWith(submitting: true, clearError: true));
    try {
      final result = await _repo.submitAnswer(
        attemptId: attemptIdForQ,
        attemptQuestionId: qId,
        choiceIds: selected,
      );
      final after = state.valueOrNull!;
      state = AsyncValue.data(after.copyWith(
        submitting: false,
        lastResult: result,
      ));

      // En entraînement infini, on prefetch le batch suivant pendant que
      // l'utilisateur lit la correction.
      if (after.isInfiniteTraining &&
          !after.noMoreQuestions &&
          after.currentIndex >= after.questions.length - 1) {
        unawaited(_extend());
      }
    } catch (e) {
      state = AsyncValue.data(cur.copyWith(
        submitting: false,
        errorMessage: ApiClient.toApiException(e).message,
      ));
    }
  }

  /// Charge un nouveau batch d'entraînement et l'ajoute à la liste cumulée.
  Future<void> _extend() async {
    final cur = state.valueOrNull;
    if (cur == null ||
        !cur.isInfiniteTraining ||
        cur.extending ||
        cur.noMoreQuestions) {
      return;
    }
    if (_trainingModule == null) return;
    // Mode démo : pas d'extension automatique au-delà du pool fixe. Le runner
    // s'arrête à la dernière question chargée et propose le paywall.
    if (!_isPremium) {
      state = AsyncValue.data(cur.copyWith(noMoreQuestions: true));
      return;
    }

    state = AsyncValue.data(cur.copyWith(extending: true, clearError: true));
    try {
      final newAttempt = await _repo.start(StartAttemptRequest(
        type: AttemptType.training,
        module: _trainingModule!,
        themeId: _trainingThemeId,
        size: _kTrainingBatchSize,
      ));

      final cur2 = state.valueOrNull!;
      if (newAttempt.questions.isEmpty) {
        state = AsyncValue.data(cur2.copyWith(
          extending: false,
          noMoreQuestions: true,
        ));
        return;
      }

      final mergedQuestions = [...cur2.questions, ...newAttempt.questions];
      final mergedMapping = Map<String, String>.from(cur2.attemptIdByQuestionId);
      for (final q in newAttempt.questions) {
        mergedMapping[q.id] = newAttempt.id;
      }

      state = AsyncValue.data(cur2.copyWith(
        activeAttempt: newAttempt,
        questions: mergedQuestions,
        attemptIdByQuestionId: mergedMapping,
        extending: false,
      ));
    } catch (e) {
      final cur2 = state.valueOrNull;
      if (cur2 == null) return;
      state = AsyncValue.data(cur2.copyWith(
        extending: false,
        errorMessage: ApiClient.toApiException(e).message,
      ));
    }
  }

  /// Passe à la question suivante. En entraînement infini, attend (ou
  /// déclenche) un nouveau batch si on est au bout de la liste cumulée.
  Future<void> goNext() async {
    var cur = state.valueOrNull;
    if (cur == null) return;

    // Si on est sur la dernière question chargée :
    if (cur.currentIndex >= cur.questions.length - 1) {
      if (!cur.isInfiniteTraining) return;
      if (cur.noMoreQuestions) return;
      // Le prefetch peut être en cours — sinon on lance.
      if (!cur.extending) {
        await _extend();
      } else {
        // Attendre la fin du prefetch en cours
        while (state.valueOrNull?.extending == true) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
      cur = state.valueOrNull;
      if (cur == null) return;
      if (cur.currentIndex >= cur.questions.length - 1) return;
    }

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

  /// Finalise l'attempt actif et renvoie l'attempt avec score.
  /// En entraînement infini, ne finalise que le dernier batch (les batches
  /// précédents restent enregistrés tels quels côté backend).
  Future<Attempt?> finish() async {
    final cur = state.valueOrNull;
    if (cur == null) return null;
    state = AsyncValue.data(cur.copyWith(submitting: true));
    try {
      final finished = await _repo.finish(cur.activeAttempt.id);
      state = AsyncValue.data(cur.copyWith(
        activeAttempt: finished,
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
